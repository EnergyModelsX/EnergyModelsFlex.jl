"""
    EMB.variables_element(m, ℒˢᵘᵇ::Vector{<:CapacityCostLink}, 𝒯, modeltype::EnergyModel)

Creates the following additional variable for **ALL** capacity cost links:
- `ccl_max_cap_use[l, t]` is a continuous variable describing the maximum capacity
  usage over sub periods for a [`CapacityCostLink`](@ref) `l` in operational period `t`.
- `ccl_cap_cost[l, t]` is a continuous variable describing the cost over sub periods
  for a [`CapacityCostLink`](@ref) `l` in operational period `t`.
"""
function EMB.variables_element(m, ℒˢᵘᵇ::Vector{<:CapacityCostLink}, 𝒯, ::EnergyModel)
    @variable(m, ccl_max_cap_use[ℒˢᵘᵇ, 𝒯] >= 0)
    @variable(m, ccl_cap_cost[ℒˢᵘᵇ, 𝒯] >= 0)
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
    p_cap = cap_resource(l)

    # Create sub-periods based on the user-defined number of sub periods of a year
    𝒯ˢᵘᵇ = create_sub_periods(l, 𝒯)

    # Capacity cost link where output equals input (no losses)
    @constraint(m, [t ∈ 𝒯],
        m[:link_out][l, t, p_cap] == m[:link_in][l, t, p_cap]
    )

    # Add the capacity constraints
    @constraint(m, [t ∈ 𝒯], m[:link_in][l, t, p_cap] ≤ m[:link_cap_inst][l, t])
    constraints_capacity_installed(m, l, 𝒯, modeltype)

    # Max capacity use constraints
    @constraint(m, [t_sub ∈ 𝒯ˢᵘᵇ, t ∈ t_sub],
        m[:link_in][l, t, p_cap] .≤ m[:ccl_max_cap_use][l, t_sub]
    )

    # Capacity cost constraint
    @constraint(m, [t_sub ∈ 𝒯ˢᵘᵇ],
        m[:ccl_cap_cost][l, t_sub[end]] ==
        m[:ccl_max_cap_use][l, t_sub[end]] * avg_cap_price(l, t_sub)
    )

    # Sum up costs for each sub_period into the strategic period cost
    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:link_opex_var][l, t_inv] ==
            sum(m[:ccl_cap_cost][l, t] for t ∈ t_inv)
    )
end

"""
    avg_cap_price(l::CapacityCostLink, t_sub::Vector{TS.TimePeriod})

Return the average capacity price over the sub period `t_sub` for the [`CapacityCostLink`](@ref) `l`.
"""
function avg_cap_price(l::CapacityCostLink, t_sub::Vector{<:TS.TimePeriod})
    return sum(cap_price(l, t) * duration(t) for t ∈ t_sub) / sum(duration(t) for t ∈ t_sub)
end

"""
    create_sub_periods(l::CapacityCostLink, 𝒯)

Extract sub periods of the [`CapacityCostLink`](@ref) `l`.
"""
function create_sub_periods(l::CapacityCostLink, 𝒯)
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
