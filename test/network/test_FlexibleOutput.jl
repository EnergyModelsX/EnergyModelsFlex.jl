# Resources used in the analysis
## Input resources
ng = ResourceCarrier("NG", 0.2)
power = ResourceCarrier("Power", 0.0)
CO2 = ResourceEmit("CO₂", 1.0)

## Output resources: Two products produced by the factory
prod1 = ResourceCarrier("Product 1", 0.0)
prod2 = ResourceCarrier("Product 2", 0.1)

function flexible_factory_case(; cap=FixedProfile(10))
    # Define sources
    src_ng = RefSource(
        "src_ng",
        FixedProfile(200),
        FixedProfile(60),
        FixedProfile(0.0),
        Dict(ng => 1),
    )

    src_power = RefSource(
        "src_power",
        FixedProfile(200),
        FixedProfile(90),
        FixedProfile(0.0),
        Dict(power => 1),
    )

    # Define FlexibleOutput
    # Interpretation:
    # - Factory has cap = 10
    # - It can produce either prod1 or prod2 (or both)
    # - prod2 is "less intensive": needs half as much capacity per unit (2 units produced
    #   per capacity usage)
    # Constraint enforced:
    #   prod1/1 + prod2/2 = cap_use
    factory = FlexibleOutput(
        "factory",
        cap,
        FixedProfile(0.2),
        FixedProfile(0.1),
        Dict(ng => 1, power => 1),
        Dict(prod1 => 1, prod2 => 2),
        [EmissionsEnergy()],
    )

    # Define the sinks (an "external market" for the products)
    prod_1_marketprice = 1e3 * OperationalProfile([5, 6, 7, 9, 6])
    prod_2_marketprice = 1e3 * OperationalProfile([9, 2, 7, 8, 5])
    sink_prod1 = RefSink(
        "sink_prod1",
        FixedProfile(1e5),
        Dict(:surplus => -1.0 * prod_1_marketprice, :deficit => prod_1_marketprice),
        Dict(prod1 => 1),
    )

    sink_prod2 = RefSink(
        "sink_prod2",
        FixedProfile(1e5),
        Dict(:surplus => -1.0 * prod_2_marketprice, :deficit => prod_2_marketprice),
        Dict(prod2 => 1),
        [EmissionsEnergy()],
    )

    nodes = [
        src_ng,
        src_power,
        factory,
        sink_prod1,
        sink_prod2,
    ]

    # Define time structure
    ops = SimpleTimes(5, 2)
    op_per_strat = 10
    T = TwoLevel(3, 2, ops; op_per_strat)

    # Define links
    links = [
        Direct(1, src_ng, factory),
        Direct(2, src_power, factory),
        Direct(3, factory, sink_prod1),
        Direct(4, factory, sink_prod2),
    ]

    resources = [ng, power, prod1, prod2, CO2]

    # Define model
    modeltype = OperationalModel(
        Dict(CO2 => FixedProfile(100)),
        Dict(CO2 => StrategicProfile([0, 2e4, 1e5])),
        CO2,
    )

    case = Case(T, resources, [nodes, links], [[get_nodes, get_links]])
    return create_model(case, modeltype), case, modeltype
end


@testset "Check functions" begin
    # Set the global to true to suppress the error message
    EMB.TEST_ENV = true

    # Capacity violation
    @test_throws AssertionError flexible_factory_case(; cap=FixedProfile(-5))

    # Set the global to true to suppress the error message
    EMB.TEST_ENV = false
end


@testset "Extraction functions" begin
    # Create the model and extract the parameters
    m, case, modeltype = flexible_factory_case()
    factory = get_nodes(case)[3]
    𝒯 = get_time_struct(case)

    # Test the EMB extraction functions
    @test capacity(factory) == FixedProfile(10)
    @test opex_var(factory) == FixedProfile(0.2)
    @test opex_fixed(factory) == FixedProfile(0.1)
    @test inputs(factory) == [ng, power] || inputs(factory) == [power, ng]
    @test outputs(factory) == [prod1, prod2] || outputs(factory) == [prod2, prod1]
    @test node_data(factory) == ExtensionData[EmissionsEnergy()]
end

@testset "Constraint implementation" begin
    # Create the case and modeltype
    m, case, modeltype = flexible_factory_case()

    # Optimize the model and conduct the general tests
    set_optimizer(m, OPTIMIZER)
    optimize!(m)
    general_tests(m)

    # Extract the time structure and elements
    𝒯 = get_time_struct(case)
    𝒩 = get_nodes(case)
    factory = 𝒩[3]
    sink_prod_1 = 𝒩[4]
    sink_prod_2 = 𝒩[5]

    # Test that prod1/1 + prod2/2 = cap_use
    @test all(
        value(m[:cap_use][factory, t]) ≈ sum(
            value(m[:flow_out][factory, t, p]) / outputs(factory, p) for
            p ∈ outputs(factory)
        ) for t ∈ 𝒯
    )

    # Test that the production matches expected values (no production in sp3 due to high CO2
    # prices and more prod1 production in sp2 due to emissions and higher CO2 prices for prod 2)
    expected_prod1 = StrategicProfile([
        OperationalProfile([0, 10, 0, 0, 0]),
        OperationalProfile([0, 10, 0, 0, 10]),
        OperationalProfile([0, 0, 0, 0, 0]),
    ])
    expected_prod2 = StrategicProfile([
        OperationalProfile([20, 0, 20, 20, 20]),
        OperationalProfile([20, 0, 20, 20, 0]),
        OperationalProfile([0, 0, 0, 0, 0]),
    ])

    @test all(value(m[:cap_use][sink_prod_1, t]) ≈ expected_prod1[t] for t ∈ 𝒯)
    @test all(value(m[:cap_use][sink_prod_2, t]) ≈ expected_prod2[t] for t ∈ 𝒯)
end
