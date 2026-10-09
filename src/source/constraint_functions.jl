"""
    constraints_opex_var(m, n::PayAsProducedPPA, 𝒯ᴵⁿᵛ, ::EnergyModel)

Function for creating the constraint on the variable OPEX of a `PayAsProducedPPA` node.
"""
function EMB.constraints_opex_var(m, n::PayAsProducedPPA, 𝒯ᴵⁿᵛ, ::EnergyModel)
    @constraint(
        m,
        [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_var][n, t_inv] == sum(
            (m[:cap_use][n, t] + m[:curtailment][n, t]) *
            opex_var(n, t) * EMB.scale_op_sp(t_inv, t) for t ∈ t_inv
        )
    )
end

"""
    constraints_capacity(m, n::InflexibleSource, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for fixing the capacity usage of an `InflexibleSource` to the installed capacity.
"""
function EMB.constraints_capacity(
    m,
    n::InflexibleSource,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    ## Custom constraint for inflexibility
    @constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] == m[:cap_inst][n, t])

    constraints_capacity_installed(m, n, 𝒯, modeltype)
end
