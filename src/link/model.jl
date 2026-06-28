"""
    EMB.variables_element(m, ℒˢᵘᵇ::Vector{<:CapacityCostLink}, 𝒯, modeltype::EnergyModel)

Creates the following additional variable for **ALL** capacity cost links:
- `ccl_cap_use_max[l, t_pd]` is a continuous variable describing the maximum capacity
  usage of [`CapacityCostLink`](@ref) `l` in cost period `t_pd`.
- `ccl_cap_use_cost[l, t_pd]` is a continuous variable describing the cost
  of a [`CapacityCostLink`](@ref) `l` in cost period `t_pd`.
"""
function EMB.variables_element(m, ℒˢᵘᵇ::Vector{<:CapacityCostLink}, 𝒯, ::EnergyModel)
    @variable(m, ccl_cap_use_max[l ∈ ℒˢᵘᵇ, periods(l, 𝒯)] ≥ 0)
    @variable(m, ccl_cap_use_cost[l ∈ ℒˢᵘᵇ, periods(l, 𝒯)] ≥ 0)
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
    𝒯ᵖᵈ = periods(l, 𝒯)

    # Capacity cost link where output equals input (no losses)
    @constraint(m, [t ∈ 𝒯],
        m[:link_out][l, t, p_cap] == m[:link_in][l, t, p_cap]
    )

    # Add the capacity constraints
    @constraint(m, [t ∈ 𝒯], m[:link_in][l, t, p_cap] ≤ m[:link_cap_inst][l, t])
    constraints_capacity_installed(m, l, 𝒯, modeltype)

    # Max capacity use constraints
    @constraint(m, [t_pd ∈ 𝒯ᵖᵈ, t ∈ t_pd],
        m[:link_in][l, t, p_cap] .≤ m[:ccl_cap_use_max][l, t_pd]
    )

    # Capacity cost constraint
    @constraint(m, [t_pd ∈ 𝒯ᵖᵈ],
        m[:ccl_cap_use_cost][l, t_pd] ==
        m[:ccl_cap_use_max][l, t_pd] * get_avg_cap_price(l, t_pd)
    )

    # Sum up costs for each sub_period into the strategic period cost
    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:link_opex_var][l, t_inv] ==
            sum(m[:ccl_cap_use_cost][l, t_pd] for t_pd ∈ periods(l, t_inv))
    )

    # Fix the fixed OPEX to avoid unconstrained variables
    for t_inv ∈ 𝒯ᴵⁿᵛ
        fix(m[:link_opex_fixed][l, t_inv], 0; force = true)
    end
end

"""
    get_avg_cap_price(l::CapacityCostLink, t_pd::TS.PeriodPartition)

Return the average capacity price over the sub period `t_pd` for the
[`CapacityCostLink`](@ref) `l`.
"""
function get_avg_cap_price(l::CapacityCostLink, t_pd::TS.PeriodPartition)
    return sum(cap_price(l, t) * duration(t) for t ∈ t_pd) / sum(duration(t) for t ∈ t_pd)
end
