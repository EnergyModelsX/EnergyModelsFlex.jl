"""
    EMB.variables_node(m, 𝒩ˢⁱⁿᵏ::Vector{<:PeriodDemandSink}, 𝒯, ::EnergyModel)

Write docstring here...
"""
function EMB.variables_node(m, 𝒩ˢⁱⁿᵏ::Vector{<:PeriodDemandSink}, 𝒯, ::EnergyModel)
    n = first(𝒩ˢⁱⁿᵏ)
    num_periods = number_of_periods(n, 𝒯)
    @variable(m, demand_sink_surplus[𝒩ˢⁱⁿᵏ, i = 1:num_periods] >= 0)
    @variable(m, demand_sink_deficit[𝒩ˢⁱⁿᵏ, i = 1:num_periods] >= 0)
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

Create the optimization variables for every time slots indicated by `load_shift_times`
    - :load_shift_from, integer variable for how many batches shifted away from the this time slot
    - :load_shift_to, integer variable for how many batches shifted to this time slot
for every timestep in: 
    - :load_shifted, continous variable for the total capacity load shifted from the time step 
"""
function EMB.variables_node(m, 𝒩ᴸˢ::Vector{<:LoadShiftingNode}, 𝒯, ::EnergyModel)
    times = collect(𝒯)
    𝒯ᴸˢ = times[𝒩ᴸˢ[1].load_shift_times]
    # Creating a variable for every time step where load shifting is allowed
    @variable(m, load_shift_from[𝒩ᴸˢ, 𝒯ᴸˢ] >= 0, Int)
    @variable(m, load_shift_to[𝒩ᴸˢ, 𝒯ᴸˢ] >= 0, Int)
    # Creating a variable for every timestep saying how much load is shifted
    @variable(m, load_shifted[𝒩ᴸˢ, 𝒯]) # can also be negative which will mean load shifted from
end
