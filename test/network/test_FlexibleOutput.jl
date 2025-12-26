# Resources used in the analysis
## Input resources
ng = ResourceCarrier("NG", 0.2)
power = ResourceCarrier("Power", 0.0)
CO2 = ResourceEmit("CO₂", 1.0)

## Output resources: Two products produced by the factory
prod1 = ResourceCarrier("Product 1", 0.0)
prod2 = ResourceCarrier("Product 2", 0.1)

function flexible_factory_graph()
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
    # - prod2 is "more intensive": needs twice as much capacity per unit
    #
    # Constraint enforced:
    #   prod1/1 + prod2/2 = cap_use
    factory = FlexibleOutput(
        "factory",
        FixedProfile(10),
        FixedProfile(0.0),
        FixedProfile(0.0),
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
    model = OperationalModel(
        Dict(CO2 => FixedProfile(100)),
        Dict(CO2 => StrategicProfile([0, 2e4, 1e5])),
        CO2,
    )

    case = Case(T, resources, [nodes, links], [[get_nodes, get_links]])
    return run_model(case, model, HiGHS.Optimizer), case, model
end

m, case, model = flexible_factory_graph()
𝒯 = get_time_struct(case)
𝒩 = get_nodes(case)

factory = 𝒩[3]
sink_prod_1 = 𝒩[4]
sink_prod_2 = 𝒩[5]
𝒫ᵒᵘᵗ = EMB.res_not(outputs(factory), co2_instance(model))

general_tests(m)

@testset "Constraints" begin
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
