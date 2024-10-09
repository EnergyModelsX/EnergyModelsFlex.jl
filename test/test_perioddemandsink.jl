using EnergyModelsBase
using EnergyModelsFlex

using HiGHS
using JuMP
using Test
using TimeStruct

include("utils.jl")

function create_system(demand)
    T = TwoLevel(1, 1, SimpleTimes(7 * 24, 1))

    Power = ResourceCarrier("Power", 0)
    # Product = ResourceCarrier("Product", 0)
    CO2 = ResourceEmit("CO2", 0)

    day = [1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 2]
    el_cost = [repeat(day, 5)..., fill(0, 2 * 24)...]

    grid = RefSource("grid",
        FixedProfile(500), # kW
        OperationalProfile(el_cost),
        FixedProfile(0),
        Dict(Power=> 1))



    nodes = [grid, demand]
    links = [
        Direct("grid-demand", grid, demand),
    ]
    case = Dict(:T => T, :nodes => nodes, :products => [Power, CO2],
        :links => links)

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

    Power = ResourceCarrier("Power", 0)
    demand = PeriodDemandSink("demand_product",
        # 24 hours per day.
        24,
        # Produce 1500 units per day, and nothing (0) in the weekend.
        [fill(1500, 5)..., 0, 0],
        OperationalProfile(week_prod), # kW - installed capacity
        Dict(:surplus => FixedProfile(0),
            :deficit => FixedProfile(1e8)), # € / Demand - Price for not delivering products
        Dict(Power => 1),
    )
    return demand
end


@testset "force-max-production" begin
    demand = create_demand_node()
    case, model, m = create_system(demand)

    # Force the grid node to produce at max capacity.
    source = case[:nodes][1]
    @constraint(m, [t in case[:T]],
        m[:cap_use][source, t] == m[:cap_inst][source, t]
    )

    # m = EnergyModelsBase.run_model(case, model, HiGHS.Optimizer)
    set_optimizer(m, HiGHS.Optimizer)
    # set_optimizer_attribute(m, MOI.Silent(), true)
    optimize!(m)

    # Test optimal solution
    @test termination_status(m) == MOI.OPTIMAL
end


@testset "test-daily-demand-fulfilled" begin
    demand = create_demand_node()
    case, model, m = create_system(demand)

    set_optimizer(m, HiGHS.Optimizer)
    optimize!(m)

    # Test optimal solution
    @test termination_status(m) == MOI.OPTIMAL

    demand = case[:nodes][2]
    vals = get_values(m, :cap_use, demand, case[:T])

    period_length = demand.period_length
    num_periods = EnergyModelsFlex.number_of_periods(demand, case[:T])

    # Test that the demand is fulfilled for each period.
    for i in 1:num_periods
        period_values = vals[(i - 1) * period_length + 1:i * period_length]
        period_total = sum(val for val in period_values)
        @test period_total == demand.period_demand[i]
    end
end
