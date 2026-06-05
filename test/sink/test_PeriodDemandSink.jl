# Resources used in the tests
Power = ResourceCarrier("Power", 0)
CO2 = ResourceEmit("CO₂", 0)

function per_dem_snk_case(; 𝒯=TwoLevel(1, 1, SimpleTimes(7 * 24, 1), op_per_strat=8760.))
    day = [1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 6.5, 6, 5, 4, 3, 2]
    el_cost = vcat(repeat(day, 4), fill(1e9, 24), fill(0, 2 * 24))

    src = RefSource(
        "grid",
        FixedProfile(500), # kW
        OperationalProfile(el_cost),
        FixedProfile(0),
        Dict(Power => 1),
    )

    # The production can only run between 6-20 on weekdays, with capacity of 200.
    # No production on weekends.
    weekday_prod = vcat(zeros(6), ones(14)*200, zeros(4))
    week_prod = vcat(repeat(weekday_prod, 5), zeros(48))

     # Demand for 1500 units per day, and nothing (0) in the weekend with a maximum production
     # of 200 per hour in between 6:00 and 20:00
    snk = PeriodDemandSink(
        "demand_product",
        24,
        [fill(1500, 5)..., 0, 0],
        OperationalProfile(week_prod),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e4)), # € / Demand - Price for not delivering products
        Dict(Power => 1),
    )

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
# @testset "Utility - Check functions" begin
#     function create_check_case(;
#         cap = FixedProfile(10),
#         per_len = 24,
#         per_demand = [fill(1500, 5)..., 0, 0],
#         T = TwoLevel(1, 1, SimpleTimes(7 * 24, 1)),
#     )
#         snk = PeriodDemandSink(
#             "demand_product",
#             per_len,
#             per_demand,
#             cap,
#             Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e8)),
#             Dict(Power => 1),
#         )

#         return per_dem_snk_case(snk; T)
#     end
#     # Test that a wrong capacity is caught by the checks
#     # this implies that the default checks are working
#     @test_throws AssertionError create_check_case(cap=FixedProfile(-25))

#     # Test that a wrong period length is caught by the checks., including in other time
#     # structures
#     @test_throws AssertionError create_check_case(per_len=25)
#     week = SimpleTimes(168, 1);
#     opscen = OperationalScenarios(2, [week, week], [0.5, 0.5]);
#     T = TwoLevel(1, 1, opscen; op_per_strat=8760.);
#     @test_throws AssertionError create_check_case(;per_len=25, T)
#     rep = RepresentativePeriods(2, 8760., [.5, .5], [week, week]);
#     T = TwoLevel(1, 1, rep; op_per_strat=8760.);
#     @test_throws AssertionError create_check_case(;per_len=25, T)

#     # Test that a wrong period demand is caught by the checks
#     @test_throws AssertionError create_check_case(per_demand=[25])

#     # Test that larger period demands are caught by the checks and print a warning
#     msg =
#         "The vector `period_demand` is longer than required in " *
#         "the operational time structure in strategic period 1. " *
#         "The last 23 values will be omitted."
#     @test_logs (:warn, msg) create_check_case(per_demand=ones(30));
# end

@testset "Utility functions" begin
    # Create the node and time structure
    cap = FixedProfile(10)
    per_len = 24
    per_demand = [fill(1500, 5)..., 0, 0]
    snk = PeriodDemandSink(
        "demand_product",
        per_len,
        per_demand,
        cap,
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
        @test all(EMF.period_demand(snk, k) == per_demand[k] for k ∈ eachindex(per_demand))
        @test EMF.period_length(snk) == 24
    end

    @testset "Utility - Other functions" begin
        # Test that all other functions required for a PeriodDemandSink are working
        @test EMF.number_of_periods(snk) == 7
        @test EMF.number_of_periods(snk, 𝒯) == 7
    end
end

@testset "Constraint implementation" begin
    # Create and optimize the model
    𝒯 = TwoLevel(2, 1, SimpleTimes(7 * 24, 1), op_per_strat=8760.)
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
    per_len = EMF.period_length(snk)
    per_demand = EMF.period_demand(snk)
    per_num = EMF.number_of_periods(snk, t_inv)
    val_cap_use = Array(value.(m[:cap_use][snk, :]))
    val_sink_deficit = Array(value.(m[:sink_deficit][snk, :]))

    # Test the variable generation
    @test length(m[:demand_sink_surplus][snk, :, :]) == 14
    @test length(m[:demand_sink_deficit][snk, :, :]) == 14

    # Tests for the capacity function
    # EMB.constraints_capacity(m, n::AbstractPeriodDemandSink, 𝒯::TimeStructure, modeltype::EnergyModel)v

    # Test that the individual deficits and surpluses are correctly calculated
    @test all(
        value.(m[:sink_deficit][snk, t]) + value.(m[:cap_use][snk, t]) ≈
        value.(m[:sink_surplus][snk, t]) + value.(m[:cap_inst][snk, t]) for t ∈ 𝒯,
        atol = TEST_ATOL
    )

    # Test that the production is as planned based on the cost with no production in period
    # 5 due to the prohibitive costs
    cap = vcat(zeros(6), ones(14)*200, zeros(4))
    prod = vcat(zeros(6), ones(6)*200, zeros(6), [100, 200], zeros(4))
    deficit = cap - prod
    @test all(val_cap_use[24*(k-1)+1:24*k] ≈ prod for k ∈ 1:4)
    @test all(val_cap_use[24*(k-1)+1:24*k] ≈ zeros(24) for k ∈ 5:7)
    @test all(val_sink_deficit[24*(k-1)+1:24*k] ≈ deficit for k ∈ 1:4)
    @test val_sink_deficit[97:120] ≈ cap
    @test all(val_sink_deficit[24*(k-1)+1:24*k] ≈ zeros(24) for k ∈ 6:7)

    # Test that the demand is fulfilled for the first 4 periods and the last 2
    for k ∈ [1, 2, 3, 4, 6, 7]
        period_values = val_cap_use[((k-1)*per_len+1):(k*per_len)]
        period_total = sum(val for val ∈ period_values)
        @test period_total ≈ per_demand[k]
        @test value.(m[:demand_sink_deficit][snk, t_inv, k]) ≈ 0 atol=TEST_ATOL
    end
    @test value.(m[:demand_sink_deficit][snk, t_inv, 5]) ≈ 1500

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
                value.(m[:demand_sink_deficit][snk, t_inv, EMF.period_index(snk, t)]) *
                 deficit_penalty(snk, t) * scale_op_sp(t_inv, t)
            for t ∈ t_inv)
    for t_inv ∈ 𝒯ᴵⁿᵛ)
end
