using EnergyModelsBase
using EnergyModelsFlex

using HiGHS
using JuMP
using Test
using TimeStruct

include("../utils.jl")

# Resources used in the tests
Power = ResourceCarrier("Power", 0)
CO2 = ResourceEmit("CO2", 0)

function create_system(demand; T = TwoLevel(1, 1, SimpleTimes(7 * 24, 1)))
    day = [1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 2]
    el_cost = [repeat(day, 5)..., fill(0, 2 * 24)...]

    grid = RefSource(
        "grid",
        FixedProfile(500), # kW
        OperationalProfile(el_cost),
        FixedProfile(0),
        Dict(Power => 1),
    )

    nodes = [grid, demand]
    links = [Direct("grid-demand", grid, demand)]
    case = Dict(:T => T, :nodes => nodes, :products => [Power, CO2], :links => links)

    modeltype = OperationalModel(
        Dict(CO2 => FixedProfile(1e6)),
        Dict(CO2 => FixedProfile(100)),
        CO2,
    )
    m = create_model(case, modeltype)
    return case, modeltype, m
end

function create_demand_node()
    # The production can only run between 6-20 on weekdays, with capacity of 200.
    # No production on weekends.
    weekday_prod = [fill(0, 6)..., fill(200, 14)..., fill(0, 4)...]
    @assert length(weekday_prod) == 24
    week_prod = [repeat(weekday_prod, 5)..., fill(0, 2 * 24)...]

    demand = PeriodDemandSink(
        "demand_product",
        # 24 hours per day.
        24,
        # Produce 1500 units per day, and nothing (0) in the weekend.
        [fill(1500, 5)..., 0, 0],
        OperationalProfile(week_prod), # kW - installed capacity
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e8)), # € / Demand - Price for not delivering products
        Dict(Power => 1),
    )
    return demand
end

function test_max_grid_production(force_max_production::Bool)
    demand = create_demand_node()
    case, model, m = create_system(demand)

    # Force the grid node to produce at max capacity.
    source = case[:nodes][1]
    @show source

    set_optimizer(m, OPTIMIZER)
    set_optimizer_attribute(m, MOI.Silent(), true)
    optimize!(m)

    # Test optimal solution
    @test termination_status(m) == MOI.OPTIMAL
end

# Test that the fields of a `PeriodDemandSink` are correctly checked
# - EMB.check_node(n::PeriodDemandSink, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
# @testset "Checks" begin
#     function create_check_case(;
#         cap = FixedProfile(10),
#         period_length = 24,
#         period_demand = [fill(1500, 5)..., 0, 0],
#         T = TwoLevel(1, 1, SimpleTimes(7 * 24, 1)),
#     )
#         demand = PeriodDemandSink(
#             "demand_product",
#             period_length,
#             period_demand,
#             cap,
#             Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e8)),
#             Dict(Power => 1),
#         )

#         return create_system(demand; T)
#     end
#     # Test that a wrong capacity is caught by the checks
#     # this implies that the default checks are working
#     @test_throws AssertionError create_check_case(cap=FixedProfile(-25))

#     # Test that a wrong period length is caught by the checks., including in other time
#     # structures
#     @test_throws AssertionError create_check_case(period_length=25)
#     week = SimpleTimes(168, 1);
#     opscen = OperationalScenarios(2, [week, week], [0.5, 0.5]);
#     T = TwoLevel(1, 1, opscen; op_per_strat=8760.);
#     @test_throws AssertionError create_check_case(;period_length=25, T)
#     rep = RepresentativePeriods(2, 8760., [.5, .5], [week, week]);
#     T = TwoLevel(1, 1, rep; op_per_strat=8760.);
#     @test_throws AssertionError create_check_case(;period_length=25, T)

#     # Test that a wrong period demand is caught by the checks
#     @test_throws AssertionError create_check_case(period_demand=[25])

#     # Test that larger period demands are caught by the checks and print a warning
#     msg =
#         "The vector `period_demand` is longer than required in " *
#         "the operational time structure in strategic period 1. " *
#         "The last 23 values will be omitted."
#     @test_logs (:warn, msg) create_check_case(period_demand=ones(30));
# end

@testset "run-production" begin
    test_max_grid_production(false)
end

@testset "test-daily-demand-fulfilled" begin
    demand = create_demand_node()
    case, model, m = create_system(demand)

    set_optimizer(m, OPTIMIZER)
    optimize!(m)

    # Test optimal solution
    @test termination_status(m) == MOI.OPTIMAL

    demand = case[:nodes][2]
    vals = get_values(m, :cap_use, demand, case[:T])

    period_length = demand.period_length
    num_periods = EnergyModelsFlex.number_of_periods(demand, case[:T])

    # Test that the demand is fulfilled for each period.
    for i ∈ 1:num_periods
        period_values = vals[((i-1)*period_length+1):(i*period_length)]
        period_total = sum(val for val ∈ period_values)
        @test period_total == demand.period_demand[i]
    end
end
