# # [Capacity cost link](@id examples-capacity_cost_link)
#
# This example illustrates the usage of [`CapacityCostLink`](@ref links-CapacityCostLink)
# from `EnergyModelsFlex`.
# The example consists of a cheap source, an expensive source, and a sink. Two links connect
# these nodes: a `Direct` link from the expensive source and a `CapacityCostLink` from the
# cheap source. The model compares the operational costs and capacity utilization of these
# two routing options across three strategic periods with varying capacity costs. There is a
# peak demand in the first two operational periods (at 10 and 9 MW) that must be covered,
# followed by a low demand (1 MW) for the remaining operational periods. Two capacity price
# periods of 12 hours each are defined for the `CapacityCostLink`, so that the peak only
# affects the capacity cost of the first price period in each strategic period.
#
# ## [Prerequisites](@id examples-capacity_cost_link-prereq)
#
# The example requires `EnergyModelsBase`, `EnergyModelsFlex`, and `TimeStruct` for building
# the model, `JuMP` and the solver `HiGHS` for solving it, and `PrettyTables` for displaying
# the results. All packages are included in the environment of the `examples` folder.
using TimeStruct
using EnergyModelsBase
using EnergyModelsFlex

using HiGHS
using JuMP
using PrettyTables

const EMF = EnergyModelsFlex

# ## [Construction of the model](@id examples-capacity_cost_link-model)
#
# Define the different resources
power = ResourceCarrier("Power", 0.0)
co2 = ResourceEmit("CO₂", 0.0)
𝒫 = [power, co2]

# Creation of the time structure and global data
op_number = 24
𝒯 = TwoLevel([1, 2, 10], SimpleTimes(op_number, 1); op_per_strat = 8760)
modeltype = OperationalModel(
    Dict(co2 => FixedProfile(10)),  # Emission cap for CO₂ in t/a
    Dict(co2 => FixedProfile(0)),   # Emission price for CO₂ in EUR/t
    co2,                            # CO₂ instance
)

# Create the nodes
src_cheap = RefSource(
    "cheap source",                 # Node id
    FixedProfile(10),               # Capacity in MW
    FixedProfile(100),              # Variable OPEX in EUR/MWh
    FixedProfile(0),                # Fixed OPEX in EUR/MW/a
    Dict(power => 1),               # Output from the node with output ratio
)
src_exp = RefSource(
    "expensive source",             # Node id
    FixedProfile(10),               # Capacity in MW
    FixedProfile(400),              # Variable OPEX in EUR/MWh
    FixedProfile(0),                # Fixed OPEX in EUR/MW/a
    Dict(power => 1),               # Output from the node with output ratio
)
sink = RefSink(
    "sink",                         # Node id
    OperationalProfile([10, 9, fill(1, op_number-2)...]), # Demand in MW
    Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(1e4)),
    ## Line above: Surplus and deficit penalty for the node in EUR/MWh
    Dict(power => 1),               # Energy demand and corresponding ratio
)

# Collect the nodes
𝒩 = [src_cheap, src_exp, sink]

# Connect the nodes
l_direct = Direct("Direct link", src_exp, sink, Linear())
l_capacity = CapacityCostLink(
    "Capacity cost link",               # Link id
    src_cheap,                          # Node from which the link originates
    sink,                               # Node to which the link connects
    FixedProfile(10),                   # Capacity in MW
    StrategicProfile([5e5, 1e6, 2e6]),  # Capacity price in EUR/MW per capacity price period
    12,                                 # Duration of the capacity price periods in hours
    power,                              # Resource with capacity limit and price
)
ℒ = [l_direct, l_capacity]

# Input data structure
case = Case(𝒯, 𝒫, [𝒩, ℒ])

# ## [Solving of the model](@id examples-capacity_cost_link-solve)
#
# Create and optimize the model with HiGHS as solver
optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
m = create_model(case, modeltype)
set_optimizer(m, optimizer)
optimize!(m)

# Show the status, which should be optimal
@show termination_status(m)

# ## [Result presentation](@id examples-capacity_cost_link-results)
#
# Extract the data
demand = value.(m[:cap_use][sink, :])
direct_flow = [value(m[:link_in][l_direct, t, power]) for t ∈ 𝒯]
capacitycostlink_flow = [value(m[:link_in][l_capacity, t, power]) for t ∈ 𝒯]
periods = collect(𝒯)

opex_var_cheap = value.(m[:opex_var][src_cheap, :])
opex_var_expensive = value.(m[:opex_var][src_exp, :])
link_opex_var = value.(m[:link_opex_var][l_capacity, :])

𝒯ⁱⁿᵛ = collect(strategic_periods(𝒯))
cap_price = [EMF.cap_price(l_capacity)[t] for t ∈ 𝒯ⁱⁿᵛ];

# ### [Link usage](@id examples-capacity_cost_link-results-link)
#
# From the table below we see that the `Direct` link is used more when the
# `CapacityCostLink` has a high capacity price, e.g., in strategic period 3. In contrast,
# when the capacity price is low, e.g., in strategic periods 1 and 2, the `CapacityCostLink`
# is used, but not with more than 1 MW as any higher amount would result in a higher
# `ccl_cap_use_max` cost just to be able to cover the first two operational periods.
pretty_table(
    hcat(periods, demand, direct_flow, capacitycostlink_flow);
    column_labels                     = [
    ["Period", "Demand", "Flow", "Flow"],
    ["", "Sink", "Direct", "CapacityCostLink"]],
    fit_table_in_display_horizontally = false,
    fit_table_in_display_vertically   = false,
    maximum_number_of_rows            = -1,
    maximum_number_of_columns         = -1,
)

# ### [Operational expenditures](@id examples-capacity_cost_link-results-opex)
#
# From the table below we see that the `CapacityCostLink` is used (has OPEX) only when the
# capacity price is sufficiently low (strategic periods 1 and 2). When the capacity price is
# high (strategic period 3), the `CapacityCostLink` is not used, and the `Direct` link (from
# the expensive source) covers the demand instead.
pretty_table(
    hcat(𝒯ⁱⁿᵛ, cap_price, link_opex_var, opex_var_cheap, opex_var_expensive);
    column_labels                     = [
    ["Period", "Capacity Price", "OPEX (link)", "OPEX (cheap node)", "OPEX (expensive node)"],
    ["", "CapacityCostLink", "CapacityCostLink", "RefSource", "RefSource"]],
    formatters                        = [fmt__printf("%5.3g")],
    fit_table_in_display_horizontally = false,
    fit_table_in_display_vertically   = false,
    maximum_number_of_rows            = -1,
    maximum_number_of_columns         = -1,
)
