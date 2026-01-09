# Resources used in the analysis
power = ResourceCarrier("Power", 0.0)
co2 = ResourceEmit("CO₂", 1.0)

# Function for setting up the system
function inflexible_source_case(; output=Dict(power => 1))

    source = InflexibleSource(
        "source",
        StrategicProfile([
            OperationalProfile([8, 5, 7, 11, 6]),
            OperationalProfile([6, 3, 5, 9, 5]),
        ]),
        FixedProfile(2),
        FixedProfile(10),
        output,
    )
    sink = RefSink(
        "sink",
        OperationalProfile([6, 8, 10, 6, 8]),
        Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(10)),
        Dict(power => 1),
    )

    resources = [power, co2]
    ops = SimpleTimes(5, 2)
    op_per_strat = 10
    T = TwoLevel(2, 2, ops; op_per_strat)

    nodes = [source, sink]
    links = [Direct(12, source, sink)]
    modeltype = OperationalModel(
        Dict(co2 => FixedProfile(100)),
        Dict(co2 => FixedProfile(0)),
        co2,
    )
    case = Case(T, resources, [nodes, links])
    return create_model(case, modeltype), case, modeltype
end

@testset "Check functions" begin
    # Set the global to true to suppress the error message
    EMB.TEST_ENV = true

    # Capacity violation
    @test_throws AssertionError inflexible_source_case(; output=Dict(power => -1))

    # Set the global to true to suppress the error message
    EMB.TEST_ENV = false
end

@testset "Extraction functions" begin
    # Create the model and extract the parameters
    m, case, modeltype = inflexible_source_case()
    src = get_nodes(case)[1]
    𝒯 = get_time_struct(case)

    # Test the capacity extraction functions
    cap = StrategicProfile([
        OperationalProfile([8, 5, 7, 11, 6]),
        OperationalProfile([6, 3, 5, 9, 5]),
    ])
    @test all(capacity(src)[t] == cap[t] for t ∈ 𝒯)
    @test all(capacity(src, t) == cap[t] for t ∈ 𝒯)

    # Test the output extraction functions
    @test outputs(src) == [power]
    @test outputs(src, power) == 1

    # Test the data extraction functions
    @test node_data(src) == ExtensionData[]
end

@testset "Constraint implementation" begin
    # Create the case and modeltype
    m, case, model = inflexible_source_case()

    # Optimize the model and conduct the general tests
    set_optimizer(m, OPTIMIZER)
    optimize!(m)
    general_tests(m)

    # Extract the time structure and elements
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    src, snk = get_nodes(case)

    # Test that the capacity is properly utilized
    # - constraints_capacity(m, n::InflexibleSource, 𝒯::TimeStructure, modeltype::EnergyModel)
    @test all(
        value.(m[:cap_use][src, t]) ≈ value.(m[:cap_inst][src, t]) for t ∈ 𝒯,
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
        value.(m[:sink_deficit][snk, t]) ≈ deficit[t] for t ∈ 𝒯, atol ∈ TEST_ATOL
    )
    @test all(
        value.(m[:sink_surplus][snk, t]) ≈ surplus[t] for t ∈ 𝒯, atol ∈ TEST_ATOL
    )
end
