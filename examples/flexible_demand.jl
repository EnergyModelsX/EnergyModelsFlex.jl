# # [Flexible demand](@id examples-flexible_demand)
#
# This example uses the following two nodes from `EnergyModelsFlex`:
#
# - [`PeriodDemandSink`](@ref nodes-perioddemandsink) to set a demand per day instead of per
#   operational period and
# - [`MinUpDownTimeNode`](@ref nodes-minupdowntimenode) to force the production to run for a
#   minimum number of hours once it has started, and to be shut off for a minimum number of
#   hours once it has stopped.
#
# ## [Prerequisites](@id examples-flexible_demand-prereq)
#
# The example requires `EnergyModelsBase`, `EnergyModelsFlex`, and `TimeStruct` for building
# the model, `JuMP` and the solver `HiGHS` for solving it, and `PrettyTables` for displaying
# the results. All packages are included in the environment of the `examples` folder.
using EnergyModelsBase
using EnergyModelsFlex
using TimeStruct

using HiGHS
using JuMP
using PrettyTables

# ## [Construction of the model](@id examples-flexible_demand-model)
#
# Declare the required resources
power = ResourceCarrier("Power", 0)
product = ResourceCarrier("Product", 0)
co2 = ResourceEmit("CO₂", 0)
𝒫 = [power, product, co2]

# Define a time structure for a single week, modelled with hourly resolution
𝒯 = TwoLevel(1, 1, SimpleTimes(7 * 24, 1))

# Some arbitrary electricity prices. Note that we let the electricity be free during the
# weekend. This would be a huge incentive to produce during the weekend, if we allowed the
# `PeriodDemandSink` to have capacity during the weekend.
day = [1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 2]
el_cost = vcat(repeat(day, 5), zeros(48))

grid = RefSource(
    "grid",                         # Node id
    FixedProfile(1e12),             # Capacity in kW, virtually infinite
    OperationalProfile(el_cost),    # Variable OPEX in EUR/kWh
    FixedProfile(0),                # Fixed OPEX in EUR/kW/week
    Dict(power => 1),               # Output from the node with output ratio
)

# The production can only run between 6-20 on weekdays, with a capacity of 300 unit/h.
# First, define the maximum capacity for a regular weekday (24 hours). The capacity is 0
# between midnight and 6 am, 300 unit/h between 6 am and 8 pm, and 0 again between 8 pm and
# midnight.
weekday_prod = vcat(zeros(6), fill(300, 14), zeros(4))

# Repeat the weekday 5 times for a workweek, followed by no production during the weekend
week_prod = vcat(repeat(weekday_prod, 5), fill(0, 2 * 24))

demand = PeriodDemandSink(
    "demand_product",               # Node id
    OperationalProfile(week_prod),  # Capacity in unit/h
    24,                             # Duration of a demand period in hours (one day)
    PartitionProfile(vcat(ones(5)*1500, [0, 0])), # Demand in each demand period in unit
    ## Line above: Demand of 1500 unit per weekday and no demand (0) during the weekend
    Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e8)),
    ## Line above: Surplus and deficit penalty for each demand period in EUR/unit
    Dict(product => 1),             # Energy demand and corresponding ratio
)

# Define the production line using [`MinUpDownTimeNode`](@ref)
min_up_time = 8
min_down_time = 5
line = MinUpDownTimeNode(
    "line",                         # Node id
    FixedProfile(300),              # Capacity in unit/h
    FixedProfile(0),                # Variable OPEX in EUR/unit
    FixedProfile(0),                # Fixed OPEX in EUR/(unit/h)/week
    Dict(power => 1),               # Input to the node with input ratio
    Dict(product => 1),             # Output from the node with output ratio
    min_up_time,                    # Minimum up time in hours
    min_down_time,                  # Minimum down time in hours
    50,                             # Minimum load when the line is running in unit/h
    300,                            # Maximum load when the line is running in unit/h
)

# Define the simple energy system
𝒩 = [grid, line, demand]
ℒ = [Direct("grid-line", grid, line), Direct("line-demand", line, demand)]
case = Case(𝒯, 𝒫, [𝒩, ℒ])

# Define an operational energy model
modeltype = OperationalModel(
    Dict(co2 => FixedProfile(1e6)), # Emission cap for CO₂ in t/week
    Dict(co2 => FixedProfile(100)), # Emission price for CO₂ in EUR/t
    co2,                            # CO₂ instance
)

# ## [Solving of the model](@id examples-flexible_demand-solve)
#
# Create and optimize the model using the function `run_model` with HiGHS as solver
m = run_model(case, modeltype, HiGHS.Optimizer)

# Show the status, which should be optimal
@show termination_status(m)

# ## [Result presentation](@id examples-flexible_demand-results)
#
# Get the full row table of the capacity usage of all nodes
table = JuMP.Containers.rowtable(value, m[:cap_use]; header = [:Node, :TimePeriod, :CapUse]);

# Filter only for `Node == line`
line = get_nodes(case)[2]
filtered = filter(row -> row.Node == line, table);

# Display the filtered table with the resulting optimal production.
#
# - Note that the demand is only satisfied during the set work hours (6-20) on weekdays.
#   This is caused by the restrictions put on `PeriodDemandSink` with the capacity limited
#   to these time periods. This is also the reason that there is no production during the
#   weekend, even though the electricity is free.
# - Also note that the production always runs for at least 8 hours, even though the daily
#   demand of 1500 units could be reached in 5 hours running at full capacity. This can be
#   explained by the constraint for a minimum run time of 8 hours on the
#   `MinUpDownTimeNode`. To maximize production at low prices, it runs at the minimum
#   capacity of 50 when the electricity is more expensive.
pretty_table(
    filtered;
    fit_table_in_display_horizontally = false,
    fit_table_in_display_vertically   = false,
    maximum_number_of_rows            = -1,
    maximum_number_of_columns         = -1,
)
