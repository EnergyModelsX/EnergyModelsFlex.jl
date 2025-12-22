"""
    EMB.variables_link(m, ℒˢᵘᵇ::Vector{<:CapacityCostLink}, 𝒯, modeltype::EnergyModel)

Creates the following additional variable for **ALL** capacity cost links:
- `max_cap_use_sub_period[l, t]` is a continuous variable describing the maximum capacity
  usage over sub periods for a [`CapacityCostLink`](@ref) `l` in operational period `t`.
- `cap_cost_sub_period[l, t]` is a continuous variable describing the cost over sub periods 
  for a [`CapacityCostLink`](@ref) `l` in operational period `t`.
"""
function EMB.variables_link(m, ℒˢᵘᵇ::Vector{<:CapacityCostLink}, 𝒯, ::EnergyModel)
    @variable(m, max_cap_use_sub_period[ℒˢᵘᵇ, 𝒯] >= 0)
    @variable(m, cap_cost_sub_period[ℒˢᵘᵇ, 𝒯] >= 0)
end

"""
    EMB.create_link(m, l::CapacityCostLink, 𝒯, 𝒫, modeltype::EnergyModel)

When the link is a [`CapacityCostLink`](@ref), the constraints for a link include 
capacity-based cost constraints.

In addition, a [`CapacityCostLink`](@ref) includes a capacity with the potential for 
investments.
"""
function EMB.create_link(
    m,
    l::CapacityCostLink,
    𝒯,
    𝒫,
    modeltype::EnergyModel,
)
    # Declaration of the required subsets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    power = cap_resource(l)

    # Capacity cost link where output equals input (no losses)
    @constraint(m, [t ∈ 𝒯, p ∈ inputs(l)],
        m[:link_out][l, t, p] == m[:link_in][l, t, p]
    )

    # Add the capacity constraints
    @constraint(m, [t ∈ 𝒯], m[:link_in][l, t, power] ≤ m[:link_cap_inst][l, t])
    constraints_capacity_installed(m, l, 𝒯, modeltype)

    # Create sub-periods based on the user-defined number of sub periods of a year
    𝒯ˢᵘᵇ = create_sub_periods(𝒯, l)

    # Max capacity use constraints
    @constraint(
        m,
        [t_sub ∈ 𝒯ˢᵘᵇ, t ∈ t_sub],
        m[:link_in][l, t, power] .<= m[:max_cap_use_sub_period][l, t_sub]
    )

    # Capacity cost constraint
    @constraint(
        m,
        [t_sub ∈ 𝒯ˢᵘᵇ],
        m[:cap_cost_sub_period][l, t_sub[end]] ==
        m[:max_cap_use_sub_period][l, t_sub[end]] * avg_cap_price(l, t_sub)
    )

    # Sum up costs for each sub_period into the strategic period cost
    @constraint(
        m,
        [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:link_opex_var][l, t_inv] == sum(m[:cap_cost_sub_period][l, t] for t ∈ t_inv)
    )
end

"""
    avg_cap_price(l::CapacityCostLink, t_sub::Vector{TS.TimePeriod})

Return the average capacity price over the sub period `t_sub` for the [`CapacityCostLink`](@ref) `l`.
"""
function avg_cap_price(l::CapacityCostLink, t_sub::Vector{<:TS.TimePeriod})
    return sum([cap_price(l, t) for t ∈ t_sub])/length(t_sub)
end

"""
    create_sub_periods(𝒯, l::CapacityCostLink)

Extract sub periods from the [`CapacityCostLink`](@ref) `l`.
"""
function create_sub_periods(𝒯, l::CapacityCostLink)
    # Calculate the length of each sub period
    sub_period_duration::Float64 = 𝒯.op_per_strat / cap_price_periods(l)

    # Create a vector collecting all `TimePeriod`s of each sub period into a vector for each
    # sub period
    sub_periods = Vector{TS.TimePeriod}[]
    for t_inv ∈ strategic_periods(𝒯)
        accumulated_duration::Float64 = 0.0
        sub_period = TS.TimePeriod[]
        for t ∈ t_inv
            push!(sub_period, t)
            accumulated_duration += duration(t) * multiple_strat(t_inv, t)

            # Check if the accumulated time of the periods in `sub_period` fills up a sub
            # period duration
            if accumulated_duration ≈ sub_period_duration
                push!(sub_periods, sub_period)
                sub_period = TS.TimePeriod[]
                accumulated_duration = 0
            end
        end
    end

    return sub_periods
end
