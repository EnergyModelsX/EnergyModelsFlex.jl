"""
    EMB.variables_node(m, 𝒩ˢⁱⁿᵏ::Vector{<:PeriodDemandSink}, 𝒯, ::EnergyModel)

Creates the following additional variables for **ALL** [`PeriodDemandSink`](@ref) nodes:
- `demand_sink_surplus[n, i]` is a non-negative variable indicating a surplus in demand in
  each period `i`.
- `demand_sink_deficit[n, i]` is a non-negative variable indicating a deficit in demand for
  each period `i`.

!!! note "Definition of period"
    The period in the description above does not correspond to an operational period as known
    from `TimeStruct`. Instead, it is a period in which the demand must be satisfied. A period
    can consist of multiple operational periods.
"""
function EMB.variables_node(m, 𝒩ˢⁱⁿᵏ::Vector{<:PeriodDemandSink}, 𝒯, ::EnergyModel)
    @variable(m, demand_sink_surplus[n ∈ 𝒩ˢⁱⁿᵏ, i=1:number_of_periods(n, 𝒯)] >= 0)
    @variable(m, demand_sink_deficit[n ∈ 𝒩ˢⁱⁿᵏ, i=1:number_of_periods(n, 𝒯)] >= 0)
end

"""
    EMB.variables_node(m, 𝒩::Vector{ContinuousMultipleInputSinkStrat}, 𝒯, ::EnergyModel)

Create the optimization variable `:input_frac_strat` for every [`ContinuousMultipleInputSinkStrat`](@ref) node.
This method is called from `EnergyModelsBase.jl`.
"""
function EMB.variables_node(
    m,
    𝒩::Vector{ContinuousMultipleInputSinkStrat},
    𝒯,
    ::EnergyModel,
)

    # Declaration of the required subsets.
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    𝒫 = unique([p for n ∈ 𝒩 for p ∈ inputs(n)])

    @variable(m, 0 ≤ input_frac_strat[𝒩, 𝒯ᴵⁿᵛ, 𝒫] ≤ 1)
    @variable(m, sink_surplus_p[𝒩, 𝒯, 𝒫] >= 0)
    @variable(m, sink_deficit_p[𝒩, 𝒯, 𝒫] >= 0)
end

"""
    EMB.variables_node(m, 𝒩::Vector{ContinuousMultipleInputSinkStrat}, 𝒯, ::EnergyModel)

Create the optimization variable `:input_frac_strat` for every [`BinaryMultipleInputSinkStrat`](@ref) node.
This method is called from `EnergyModelsBase.jl`.
"""
function EMB.variables_node(m, 𝒩::Vector{BinaryMultipleInputSinkStrat}, 𝒯, ::EnergyModel)

    # Declaration of the required subsets.
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    𝒫 = unique([p for n ∈ 𝒩 for p ∈ inputs(n)])

    @variable(m, input_frac_strat[𝒩, 𝒯ᴵⁿᵛ, 𝒫], Bin)
    @variable(m, sink_surplus_p[𝒩, 𝒯, 𝒫] >= 0)
    @variable(m, sink_deficit_p[𝒩, 𝒯, 𝒫] >= 0)
end

"""
    EMB.variables_node(m, 𝒩ᴸˢ::Vector{<:LoadShiftingNode}, 𝒯, ::EnergyModel)

Creates the following additional variables for **ALL** [`LoadShiftingNode`](@ref) nodes.
- `load_shift_from[n, t]` is an integer variable for how many batches are shifted away from
  time period `t`.
- `load_shift_to[n, t]` is an integer variable for how many batches are shifted to the time
  period `t`.
- `:load_shifted[n ,t]` is a continous variable for the total capacity load shifted in
  time period `t`. The variable can also be negative indicating a load shifted from this
  time period.

The individual time periods which allow for load shifting are declared by the parameter
`load_shift_times`.
"""
function EMB.variables_node(m, 𝒩ᴸˢ::Vector{<:LoadShiftingNode}, 𝒯, ::EnergyModel)
    ops = collect(𝒯)
    @variable(m, load_shift_from[n ∈ 𝒩ᴸˢ, ops[n.load_shift_times]] >= 0, Int)
    @variable(m, load_shift_to[n ∈ 𝒩ᴸˢ, ops[n.load_shift_times]] >= 0, Int)
    @variable(m, load_shifted[𝒩ᴸˢ, 𝒯])
end
