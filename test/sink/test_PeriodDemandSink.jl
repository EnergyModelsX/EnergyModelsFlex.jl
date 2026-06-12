# Resources used in the tests
Power = ResourceCarrier("Power", 0)
CO2 = ResourceEmit("CO₂", 0)

function per_dem_snk_case(;
    snk = nothing,
    𝒯 = TwoLevel(
        1, 1,
        SimpleTimes(repeat(vcat([2, 2, 2], ones(14), [4]), 7)),
        op_per_strat=8760.
    ),
)
    day = [1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 6.5, 6, 3.5]
    el_cost = vcat(repeat(day, 4), fill(1e9, 18), zeros(36))

    src = RefSource(
        "grid",
        FixedProfile(500), # kW
        OperationalProfile(el_cost),
        FixedProfile(0),
        Dict(Power => 1),
    )

    # The production can only run between 6-20 on weekdays, with capacity of 200.
    # No production on weekends.
    weekday_prod = vcat(zeros(3), ones(14)*200, [0])
    week_prod = vcat(repeat(weekday_prod, 5), zeros(36))

    # Demand for 1500 units per day, and nothing (0) in the weekend with a maximum production
    # of 200 per hour in between 6:00 and 20:00
    if isnothing(snk)
        snk = PeriodDemandSink(
            "demand_product",
            OperationalProfile(week_prod),
            24,
            PartitionProfile([fill(1500, 5)..., 0, 0]),
            Dict(
                :surplus => PartitionProfile(vcat([-8], zeros(6))),
                :deficit => FixedProfile(1e4),
            ),
            Dict(Power => 1),
        )
    end

    𝒫 = [Power, CO2]
    𝒩 = [src, snk]
    ℒ = [Direct("grid-snk", src, snk)]
    case = Case(𝒯, 𝒫, [𝒩, ℒ])

    modeltype = OperationalModel(
        Dict(CO2 => FixedProfile(1e6)),
        Dict(CO2 => FixedProfile(100)),
        CO2,
    )
    m = create_model(case, modeltype)
    return m, case, modeltype
end

# Test that the fields of a `PeriodDemandSink` are correctly checked
# - EMB.check_node(n::PeriodDemandSink, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
@testset "Check functions" begin
    # Set the global to true to suppress the error message
    EMB.TEST_ENV = true

    function check_per_dem_sink(;
        cap = FixedProfile(10),
        per_len = 24,
        per_demand = PartitionProfile([fill(1500, 5)..., 0, 0]),
        penalty = Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e4)),
        input = Dict(Power => 1),
        𝒯 = TwoLevel(1, 1, SimpleTimes(repeat(vcat([2, 2, 2], ones(14), [4]), 7))),
    )
        snk = PeriodDemandSink(
            "demand_product",
            cap,
            per_len,
            per_demand,
            penalty,
            input,
        )

        return per_dem_snk_case(; snk, 𝒯)
    end
    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError check_per_dem_sink(; cap=FixedProfile(-25))

    # Test that a wrong input is caught by the checks
    @test_throws AssertionError check_per_dem_sink(; input = Dict(Power => -1))

    # Test that a wrong penalty dictionary is caught
    penalties = [
        Dict(:surplus => FixedProfile(0)),
        Dict(:deficit => FixedProfile(0)),
        Dict(:surplus => OperationalProfile([0]), :deficit => FixedProfile(1e4)),
        Dict(:surplus => FixedProfile(0), :deficit => OperationalProfile([1e4])),
        Dict(:surplus => FixedProfile(-1e5), :deficit => FixedProfile(1e4)),
    ]
    for penalty ∈ penalties
        @test_throws AssertionError check_per_dem_sink(; penalty)
    end

    # Test that a wrong period length is caught by the checks, including in other time
    # structures
    @test_throws AssertionError check_per_dem_sink(; per_len=25)
    week = SimpleTimes(repeat(vcat([2, 2, 2], ones(14), [4]), 7))
    opscen = OperationalScenarios(2, [week, week], [0.5, 0.5])
    𝒯 = TwoLevel(1, 1, opscen; op_per_strat=8760.)
    @test_throws AssertionError check_per_dem_sink(; per_len=25, 𝒯)
    rep = RepresentativePeriods(2, 8760., [.5, .5], [week, week])
    𝒯 = TwoLevel(1, 1, rep; op_per_strat=8760.)
    @test_throws AssertionError check_per_dem_sink(; per_len=25, 𝒯)

    # Test that a wrong period demand is caught by the checks
    @test_throws AssertionError check_per_dem_sink(; per_demand=OperationalProfile([25]))
    @test_throws AssertionError check_per_dem_sink(; per_demand=FixedProfile(-10))

    # Set the global again to false
    EMB.TEST_ENV = false
end

@testset "Utility functions" begin
    # Create the node and time structure
    cap = FixedProfile(10)
    per_len = 24
    per_demand = PartitionProfile([fill(1500, 5)..., 0, 0])
    snk = PeriodDemandSink(
        "demand_product",
        cap,
        per_len,
        per_demand,
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e4)),
        Dict(Power => 0.5),
    )
    𝒯 = TwoLevel(1, 1, SimpleTimes(7 * 24, 1))

    @testset "Utility - Identification functions" begin
        # Test that all identification functions are working
        @test EMB.has_input(snk)
        @test !EMB.has_emissions(snk)
        @test !EMB.has_output(snk)
    end

    @testset "Utility - Extraction functions" begin
        # Test that all EMB extraction functions are working
        @test capacity(snk) == FixedProfile(10)
        @test all(capacity(snk, t) == 10 for t ∈ 𝒯)
        @test inputs(snk) == [Power]
        @test inputs(snk, Power) == 0.5
        @test surplus_penalty(snk) == FixedProfile(0)
        @test all(surplus_penalty(snk, t) == 0 for t ∈ 𝒯)
        @test deficit_penalty(snk) == FixedProfile(1e4)
        @test all(deficit_penalty(snk, t) == 1e4 for t ∈ 𝒯)
        @test node_data(snk) == ExtensionData[]

        # Test that all EMF extraction functions are working
        @test EMF.period_demand(snk) == per_demand
        @test EMF.periods(snk, 𝒯) == partition_duration(𝒯, per_len)
        @test all(
            EMF.period_demand(snk, t_dp) == per_demand[t_dp] for t_dp ∈ EMF.periods(snk, 𝒯)
        )
    end

    @testset "Utility - Other functions" begin
        # Test that all other functions required for a PeriodDemandSink are working
        @test EMF.number_of_periods(snk, 𝒯) == 7
    end
end

@testset "Constraint implementation" begin
    # Create and optimize the model
    𝒯 = TwoLevel(2, 1, SimpleTimes(repeat(vcat([2, 2, 2], ones(14), [4]), 7)), op_per_strat=8760.)
    m, case, modeltype = per_dem_snk_case(; 𝒯)
    set_optimizer(m, OPTIMIZER)
    optimize!(m)

    # Test optimal solution
    general_tests(m)

    # Extract the required values from the case and node
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    t_inv = first(𝒯ᴵⁿᵛ)
    src = get_nodes(case)[1]
    snk = get_nodes(case)[2]
    per_demand = EMF.period_demand(snk)
    pers = EMF.periods(snk, 𝒯)

    # Test the variable generation
    @test length(m[:demand_sink_surplus][snk, :]) == 14
    @test length(m[:demand_sink_deficit][snk, :]) == 14

    # Tests for the capacity function
    # EMB.constraints_capacity(m, n::AbstractPeriodDemandSink, 𝒯::TimeStructure, modeltype::EnergyModel)

    # Test that the individual deficits and surpluses are correctly calculated
    @test all(
        value.(m[:sink_deficit][snk, t]) + value.(m[:cap_use][snk, t]) ≈
        value.(m[:cap_inst][snk, t]) for t ∈ 𝒯,
        atol = TEST_ATOL
    )
    # Test that the surplus is fixed to 0
    @test all(is_fixed.(m[:sink_surplus][snk, t]) for t ∈ 𝒯)
    @test all(value.(m[:sink_surplus][snk, t]) ≈ 0 for t ∈ 𝒯)

    # Test that the production is as planned based on the cost with no production in period
    # 5 due to the prohibitive costs
    cap = capacity(snk)
    prod = OperationalProfile(vcat(
        vcat(zeros(3), ones(8)*200, zeros(3), ones(3)*200, [0]),
        repeat(vcat(zeros(3), ones(6)*200, zeros(6), [100, 200], [0]), 3),
        zeros(54),
    ))
    deficit = cap - prod
    @test all(value.(m[:cap_use][snk, t]) ≈ prod[t] for t ∈ 𝒯)
    @test all(value.(m[:sink_deficit][snk, t]) ≈ deficit[t] for t ∈ 𝒯)

    # Test that the demand is fulfilled for the first 4 periods and the last 2
    demand = PartitionProfile([2200, fill(1500, 3)..., 0, 0, 0])
    @test all(sum(value.(m[:cap_use][snk, t]) for t ∈ t_pd) ≈ demand[t_pd] for t_pd ∈ pers)
    deficit = PartitionProfile([0, 0, 0, 0, 1500, 0, 0])
    @test all(value.(m[:demand_sink_deficit][snk, t_pd]) ≈ deficit[t_pd] for t_pd ∈ pers)
    surplus = PartitionProfile([700, 0, 0, 0, 0, 0, 0])
    @test all(value.(m[:demand_sink_surplus][snk, t_pd]) ≈ surplus[t_pd] for t_pd ∈ pers)

    # Test the upper bound on the installed capacity and the value for the capacity
    @test all(value.(m[:cap_use][snk, t]) ≲ value.(m[:cap_inst][snk, t]) for t ∈ 𝒯)
    @test all(is_fixed.(m[:cap_inst][snk, t]) for t ∈ 𝒯)
    @test all(value.(m[:cap_inst][snk, t]) ≈ capacity(snk, t) for t ∈ 𝒯)

    # Test that the fixed OPEX is set to 0
    # - EMB.constraints_opex_fixed(m, n::Sink, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
    @test all(is_fixed.(m[:opex_fixed][snk, t_inv]) for t_inv ∈ 𝒯ᴵⁿᵛ)
    @test all(value.(m[:opex_fixed][snk, t_inv]) ≈ 0 for t_inv ∈ 𝒯ᴵⁿᵛ)

    # Test that the variable OPEX is correctly calculated
    # - EMB.constraints_opex_fixed(m, n::AbstractPeriodDemandSink, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
    @test all(
        value.(m[:opex_var][snk, t_inv]) ≈
            sum(
                (value.(m[:demand_sink_deficit][snk, t_pd]) * deficit_penalty(snk, t_pd) +
                value.(m[:demand_sink_surplus][snk, t_pd]) * surplus_penalty(snk, t_pd)) *
                multiple_strat(t_inv, first(t_pd)) * probability(first(t_pd))
            for t_pd ∈ EMF.periods(snk, t_inv))
    for t_inv ∈ 𝒯ᴵⁿᵛ)
    @test all(
        value.(m[:opex_var][snk, t_inv]) ≈ 8760/24/7 * (1e4*1500 - 8 * 700)
    for t_inv ∈ 𝒯ᴵⁿᵛ)
end
