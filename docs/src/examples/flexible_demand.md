```@meta
EditURL = "../../../examples/flexible_demand.jl"
```

# [Flexible demand](@id examples-flexible_demand)
This example uses the following two nodes from `EnergyModelsFlex`:
 - [`PeriodDemandSink`](@ref nodes-perioddemandsink) to set a demand per day
   instead of per operational period and
 - [`MinUpDownTimeNode`](@ref nodes-minupdowntimenode) to force the production
   to run for a minimum number of hours if it has first started, and be shut off
   for a minimum number of hours if it has first stopped.

````@example flexible_demand
using EnergyModelsBase
using EnergyModelsFlex
using TimeStruct

using HiGHS
using JuMP
using PrettyTables
````

Declare the required resources.

````@example flexible_demand
Power = ResourceCarrier("Power", 0)
Product = ResourceCarrier("Product", 0)
CO2 = ResourceEmit("CO2", 0)
````

Define a timestructure for a single week.

````@example flexible_demand
T = TwoLevel(1, 1, SimpleTimes(7 * 24, 1))
````

Some arbitrary electricity prices. Note we let the energy be free in the weekend.
This would be a huge incentive to produce during the weekend, if we allowed the
`PeriodDemandSink` capacity during the weekend.

````@example flexible_demand
day = [1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 2]
el_cost = [repeat(day, 5)..., fill(0, 2 * 24)...]

grid = RefSource(
    "grid",
    FixedProfile(1e12), # kW - virtually infinite
    OperationalProfile(el_cost),
    FixedProfile(0),
    Dict(Power => 1),
)
````

The production can only run between 6-20 on weekdays, with a capacity of 300 kW.
First, define the maximum capacity for a regular weekday (24 hours).
The capacity is 0 between 0 am and 6 am, 300 kW between 6 am and 8 pm, and 0 again between 8 pm and midnight.

````@example flexible_demand
weekday_prod = [fill(0, 6)..., fill(300, 14)..., fill(0, 4)...]
@assert length(weekday_prod) == 24
````

Repeat a weekday 5 times, for a workweek, then no production on the weekends.

````@example flexible_demand
week_prod = [repeat(weekday_prod, 5)..., fill(0, 2 * 24)...]

demand = PeriodDemandSink(
    "demand_product",
    24, # 24 hours per day.
    [fill(1500, 5)..., 0, 0], # Demand of 1500 units per day, and nothing (0) in the weekend.
    OperationalProfile(week_prod), # kW - installed capacity
    Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e8)), # € / Demand - Price for not delivering products
    Dict(Product => 1),
)
````

Define the production line using [`MinUpDownTimeNode`](@ref)

````@example flexible_demand
min_up_time = 8
min_down_time = 5
line = MinUpDownTimeNode(
    "line",
    FixedProfile(300), # kW - installed capacity for both lines
    FixedProfile(0),
    FixedProfile(0),
    Dict(Power => 1),
    Dict(Product => 1),
    min_up_time, # minUpTime
    min_down_time, # minDownTime
    50, # minCapacity
    300, # maxCapacity
    [],
)
````

Define the simple energy system

````@example flexible_demand
nodes = [grid, line, demand]
links = [Direct("grid-line", grid, line), Direct("line-demand", line, demand)]
case = Dict(:T => T, :nodes => nodes, :products => [Power, Product], :links => links)
````

Define as operational energy model

````@example flexible_demand
modeltype = OperationalModel(
    Dict(CO2 => FixedProfile(1e6)),
    Dict(CO2 => FixedProfile(100)),
    CO2,
)
````

Optimize the model

````@example flexible_demand
m = run_model(case, modeltype, HiGHS.Optimizer)
````

Show status, should be optimal

````@example flexible_demand
@show termination_status(m)
````

Get the full row table

````@example flexible_demand
table = JuMP.Containers.rowtable(value, m[:cap_use]; header = [:Node, :TimePeriod, :CapUse])
````

Filter only for `Node == line`

````@example flexible_demand
line = case[:nodes][2]
filtered = filter(row -> row.Node == line, table)
````

Display the filtered table with the resulting optimal production.
- Note that the demand is only satisfied during the set workhours (6-20) on
  weekdays. This is cause by the restrictions put on `PeriodDemandSink` with
  the capacity limited to these time periods. This is also the reason that
  there is no production during the weekend, even though the electricity
  is free.
- Also note that the production is always run for at least 8 hours, even
  though the daily demand of 1500 units could be reached in 5 hours running at
  full capacity. This can be explained by the constraint for minimum run time of 8
  hours on the `MinUpDownTimeNode`. To maximize production at low prices, it
  runs at the minimum capacity of 50 when the electricity is more expensive.

````@example flexible_demand
pretty_table(filtered; crop = :none)
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

