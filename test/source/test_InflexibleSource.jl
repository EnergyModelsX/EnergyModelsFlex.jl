# Note: No tests for checks are defined for InflexibleSource nodes in EnergyModelsFlex.jl
# since their checks are fully inherited from EnergyModelsBase.jl.

# Resources used in the analysis
Power = ResourceCarrier("Power", 0.0)
CO2 = ResourceEmit("CO2", 1.0)

# Function for setting up the system
function simple_graph(source::InflexibleSource, sink::Sink)
    resources = [Power, CO2]
    ops = SimpleTimes(5, 2)
    op_per_strat = 10
    T = TwoLevel(2, 2, ops; op_per_strat)

    nodes = [source, sink]
    links = [Direct(12, source, sink)]
    model = OperationalModel(
        Dict(CO2 => FixedProfile(100)),
        Dict(CO2 => FixedProfile(0)),
        CO2,
    )
    case = Case(T, resources, [nodes, links], [[get_nodes, get_links]])
    return run_model(case, model, HiGHS.Optimizer), case, model
end

@testset "Constraints" begin
    source = InflexibleSource(
        "source",
        StrategicProfile([
            OperationalProfile([8, 5, 7, 11, 6]),
            OperationalProfile([6, 3, 5, 9, 5]),
        ]),
        FixedProfile(2),
        FixedProfile(10),
        Dict(Power => 1),
    )
    sink = RefSink(
        "sink",
        OperationalProfile([6, 8, 10, 6, 8]),
        Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(10)),
        Dict(Power => 1),
    )

    m, case, model = simple_graph(source, sink)
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    general_tests(m)

    # Test that the capacity is properly utilized
    # - constraints_capacity(m, n::InflexibleSource, 𝒯::TimeStructure, modeltype::EnergyModel)
    @test all(
        value.(m[:cap_use][source, t]) ≈ value.(m[:cap_inst][source, t]) for t ∈ 𝒯,
        atol ∈ TEST_ATOL
    )

    # Test that sink deficit and surplus values match expected calculations
    deficit = StrategicProfile([
        OperationalProfile([0, 3, 3, 0, 2]),
        OperationalProfile([0, 5, 5, 0, 3]),
    ])
    surplus = StrategicProfile([
        OperationalProfile([2, 0, 0, 5, 0]),
        OperationalProfile([0, 0, 0, 3, 0]),
    ])
    @test all(
        value.(m[:sink_deficit][sink, t]) ≈ deficit[t] for t ∈ 𝒯, atol ∈ TEST_ATOL
    )
    @test all(
        value.(m[:sink_surplus][sink, t]) ≈ surplus[t] for t ∈ 𝒯, atol ∈ TEST_ATOL
    )
end
