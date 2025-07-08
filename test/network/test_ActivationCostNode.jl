# Declare all resources of the case
power = ResourceCarrier("Power", 0.0)
h2 = ResourceCarrier("H₂", 0.0)
co2 = ResourceEmit("CO₂", 1.0)

"""
    act_node_test_case(𝒯; kwargs)

Simple test case for testing the activation cost node type.
"""
function act_node_test_case(
    𝒯;
    supply = FixedProfile(50),
    demand = FixedProfile(50),
)
    # Declaration of the resources
    𝒫 = [power, h2, co2]

    # Declaration of the nodes
    h2_source = RefSource(
        "H₂ source",
        supply,
        FixedProfile(9),
        FixedProfile(0),
        Dict(h2 => 1),
    )
    el_source = RefSource(
        "El source",
        FixedProfile(15),
        FixedProfile(30),
        FixedProfile(0),
        Dict(power => 1),
    )
    act_cost_node = ActivationCostNode(
        "act_cost_node",
        FixedProfile(20),
        FixedProfile(10),
        FixedProfile(2),
        Dict(power => 0.1, h2 => 1.1),
        Dict(h2 => 1),
        1,
        Dict(power => 10),
    )
    h2_sink = RefSink(
        "h2_demand",
        demand,
        Dict(:surplus => FixedProfile(100), :deficit => FixedProfile(20000)),
        Dict(h2 => 1),
    )
    𝒩 = [h2_source, el_source, act_cost_node, h2_sink]

    # Declaration of the links
    ℒ = [
        Direct("h2_source-act_cost_node", h2_source, act_cost_node)
        Direct("el_source-act_cost_node", el_source, act_cost_node)
        Direct("act_cost_node-h2_sink", act_cost_node, h2_sink)
    ]

    # Create the case and modeltype
    case = Case(𝒯, 𝒫, [𝒩, ℒ])
    modeltype = OperationalModel(
        Dict(co2 => FixedProfile(10)),
        Dict(co2 => FixedProfile(0)),
        co2,
    )

    # Create and run the model
    m = create_model(case, modeltype)
    set_optimizer(m, OPTIMIZER)
    optimize!(m)

    return m, case, modeltype
end

@testset "Utilities" begin
    # Create the general data for the activation cost node
    𝒯 = TwoLevel(2, 1, SimpleTimes(5, 1))
    t = first(𝒯)
    act_cost_node = ActivationCostNode(
        "act_cost_node",
        FixedProfile(50),
        FixedProfile(5),
        FixedProfile(0),
        Dict(power => 0.1, h2 => 1.1),
        Dict(h2 => 1),
        1,
        Dict(power => 10),
    )

    # Test the EMB utility functions
    @test capacity(act_cost_node) == FixedProfile(50)
    @test opex_var(act_cost_node) == FixedProfile(5)
    @test opex_fixed(act_cost_node) == FixedProfile(0)
    @test inputs(act_cost_node) == [h2, power] || inputs(act_cost_node) == [power, h2]
    @test outputs(act_cost_node) == [h2]
    @test node_data(act_cost_node) == Data[]

    # Test the EMF utility functions
    @test EMF.activation_consumption(act_cost_node) == Dict(power => 10)
    @test EMF.activation_consumption(act_cost_node, power) == 10
    @test EMF.activation_consumption(act_cost_node, h2) == 0
end

@testset "Mathematical formulation" begin
    # Create the test case
    𝒯 = TwoLevel(1, 1, SimpleTimes(6, 1))
    demand = OperationalProfile([10, 20, 30, 0, 30, 0])
    m, case, modeltype = act_node_test_case(𝒯; demand)

    # Extract the values
    𝒯 = get_time_struct(case)
    𝒩 = get_nodes(case)
    acn = 𝒩[3]

    # Test that the capacity is limited
    # - constraints_capacity(m, n::ActivationCostNode, 𝒯::TimeStructure, ::EnergyModel)
    prof = OperationalProfile([20, 20, 20, 0, 20, 0])
    @test all(value.(m[:cap_use][acn, t]) ≤ 20 for t ∈ 𝒯)
    @test all(value.(m[:cap_inst][acn, t]) ≈ 20 for t ∈ 𝒯)
    @test all(value.(m[:cap_use][acn, t]) ≈ prof[t] for t ∈ 𝒯)

    # Test that on-off and the switches are correct
    # - constraints_capacity(m, n::ActivationCostNode, 𝒯::TimeStructure, ::EnergyModel)
    prof = OperationalProfile([1, 1, 1, 0, 1, 0])
    @test all(value.(m[:on_off][acn, t]) == prof[t] for t ∈ 𝒯)
    @test all(value.(m[:onswitch][acn, t]) + value.(m[:offswitch][acn, t]) ≤ 1 for t ∈ 𝒯)

    # Test that the cyclic constraints are correct
    # - constraints_capacity(m, n::ActivationCostNode, 𝒯::TimeStructure, ::EnergyModel)
    @test all(
        value.(m[:on_off][acn, t]) ==
        value.(m[:on_off][acn, t_prev] - m[:offswitch][acn, t] + m[:onswitch][acn, t])
        for (t_prev, t) ∈ withprev(𝒯) if !isnothing(t_prev)
    )
    t_1 = first(𝒯)
    t_last = last(𝒯)
    @test value.(m[:on_off][acn, t_1]) ==
          value.(m[:on_off][acn, t_last] - m[:offswitch][acn, t_1] + m[:onswitch][acn, t_1])

    # Test that the additional demand is correct
    # - constraints_flow_in(m, n::ActivationCostNode, 𝒯::TimeStructure, ::EnergyModel)
    prof_1 = OperationalProfile([22, 22, 22, 0, 22, 0])
    prof_2 = OperationalProfile([10, 0, 0, 0, 10, 0])
    @test all(value.(m[:flow_in][acn, t, h2]) ≈ prof_1[t] for t ∈ 𝒯)
    @test all(value.(m[:flow_in][acn, t, power]) ≈ prof_1[t]/11 + prof_2[t] for t ∈ 𝒯)
end
