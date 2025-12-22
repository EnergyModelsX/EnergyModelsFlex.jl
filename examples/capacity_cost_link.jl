# # [Capacity cost link](@id examples-capacity_cost_link)
# This example illustrates the usage of [`CapacityCostLink`](@ref links-CapacityCostLink)
# from `EnergyModelsFlex`.
# The example consists of a cheap source, an expensive source, and a sink. Two links connect
# these nodes: a `Direct` link from the expensive source and a `CapacityCostLink` from the cheap source.
# The model compares the operational costs and capacity utilization of these two routing options
# across three strategic periods with varying capacity costs. There is a peak demand in the
# first two operational periods (at 10 and 9 MW) that must be covered followed by low demand (1 MW)
# for the remaining operational periods. Two sub periods are defined for the `CapacityCostLink`,
# allowing it to optimize its capacity usage based on the varying capacity costs over the year.

# Start by importing the required packages
using TimeStruct
using EnergyModelsBase
using EnergyModelsFlex

using HiGHS
using JuMP
using PrettyTables

const EMF = EnergyModelsFlex

# Define the different resources
power = ResourceCarrier("Power", 0.0)
co2 = ResourceEmit("CO₂", 0.0)
𝒫 = [power, co2]

# Creation of the time structure and global data
op_number = 24
𝒯 = TwoLevel([1, 2, 10], SimpleTimes(op_number, 1); op_per_strat = 8760)
modeltype = OperationalModel(
    Dict(co2 => FixedProfile(10)),
    Dict(co2 => FixedProfile(0)),
    co2,
)

# Create the nodes
src_cheap = RefSource(
    "cheap source",
    FixedProfile(10),
    FixedProfile(100),
    FixedProfile(0),
    Dict(power => 1),
)
src_exp = RefSource(
    "expensive source",
    FixedProfile(10),
    FixedProfile(400),
    FixedProfile(0),
    Dict(power => 1),
)
sink = RefSink(
    "sink",
    OperationalProfile([10, 9, fill(1, op_number-2)...]),
    Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(1e4)),
    Dict(power => 1),
)

# Collect the nodes
𝒩 = [src_cheap, src_exp, sink]

# Connect the nodes
l_direct = Direct("Direct link", src_exp, sink, Linear())
l_capacity = CapacityCostLink(
    "Capacity cost link",
    src_cheap,                          # from
    sink,                               # to
    FixedProfile(10),                   # capacity
    StrategicProfile([5e5, 1e6, 2e6]),  # capacity price
    2,                                  # capacity price period
    power,                              # capacity constrained resource
)
ℒ = [l_direct, l_capacity]

# Input data structure and modeltype creation
case = Case(𝒯, 𝒫, [𝒩, ℒ])

# Create and optimize the model
optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
m = create_model(case, modeltype)
set_optimizer(m, optimizer)
optimize!(m)

# Extract data
demand = value.(m[:cap_use][sink, :])
direct_flow = [value(m[:link_in][l_direct, t, power]) for t ∈ 𝒯]
capacitycostlink_flow = [value(m[:link_in][l_capacity, t, power]) for t ∈ 𝒯]
periods = collect(𝒯)

opex_var_cheap = value.(m[:opex_var][src_cheap, :])
opex_var_expensive = value.(m[:opex_var][src_exp, :])
link_opex_var = value.(m[:link_opex_var][l_capacity, :])

𝒯ⁱⁿᵛ = collect(strategic_periods(𝒯))
cap_price = [EMF.cap_price(l_capacity)[t] for t ∈ 𝒯ⁱⁿᵛ]

# ## Display link usage

# From the table below we see that the `Direct` link is used more
# when the `CapacityCostLink` has a high capacity price, e.g., in strategic periods
# 3. In contrast, when the capacity price is low, e.g., in periods
# 1 and 2, the `CapacityCostLink` is used, but not more than 1 MW as any higher amount would
# result in higher `max_cap_use_sub_period` cost just to be able to cover the two first
# operational periods
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

# ## Display operational expenditures

# From the table below we see that the `CapacityCostLink` is used (has OPEX) only when
# the capacity price is sufficiently low (strategic periods 1 and 2). When the capacity
# price is high (strategic period 3), the `CapacityCostLink` is not used, and the `Direct`
# link (from the expensive source) covers the demand instead.
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
