using EnergyModelsBase
using EnergyModelsFlex

using HiGHS
using JuMP
using Test
using TimeStruct

function create_system(line)
    𝒯 = TwoLevel(1, 1, SimpleTimes(7 * 24, 1))

    Power = ResourceCarrier("Power", 0)
    Product = ResourceCarrier("Product", 0)
    CO2 = ResourceEmit("CO2", 0)
    𝒫 = [Power, Product, CO2]

    day = [1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 2]
    el_cost = [repeat(day, 5)..., fill(0, 2 * 24)...]

    grid = RefSource(
        "grid",
        FixedProfile(1e12), # kW - virtually infinite
        OperationalProfile(el_cost),
        FixedProfile(0),
        Dict(Power => 1),
    )

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
        Dict(Product => 1),
    )

    𝒩 = [grid, line, demand]
    ℒ = [Direct("grid-line", grid, line), Direct("line-demand", line, demand)]

    case = Case(𝒯, 𝒫, [𝒩, ℒ])

    modeltype = OperationalModel(
        Dict(CO2 => FixedProfile(1e6)),
        Dict(CO2 => FixedProfile(100)),
        CO2,
    )
    return case, modeltype
end

function create_line(min_up, min_down)
    Power = ResourceCarrier("Power", 0)
    Product = ResourceCarrier("Product", 0)
    line = MinUpDownTimeNode(
        "line",
        FixedProfile(200), # kW - installed capacity for both lines
        FixedProfile(0),
        FixedProfile(0),
        Dict(Power => 1),
        Dict(Product => 1),
        min_up, # minUpTime
        min_down, # minDownTime
        50, # minCapacity
        200, # maxCapacity
        [],
    )
    return line
end

@testset "check-cyclic-sequence" begin
    # Test the MinUpDownTimeNode with different values of min_up_time and min_down_time.
    for min_up_time ∈ 2:8
        for min_down_time ∈ 2:8
            line = create_line(min_up_time, min_down_time)
            case, model = create_system(line)

            m = EnergyModelsBase.run_model(case, model, OPTIMIZER)

            # Test optimal solution
            @test termination_status(m) == MOI.OPTIMAL

            line = get_nodes(case)[2]

            # Test that the minimum up time and minimum down time are at least
            # min_up_time and min_down_time.
            cap_use = get_values(m, :cap_use, line, get_time_struct(case))
            check = check_cyclic_sequence(cap_use, min_up_time, min_down_time)
            @test check
            msg = "check-min_up_time=$min_up_time, min_down_time=$min_down_time"
            if !check
                @warn "Failed for: $msg"
            end
        end
    end
end
