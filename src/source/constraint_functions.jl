"""
    EMB.constraints_opex_var(m, n::PayAsProducedPPA, 𝒯ᴵⁿᵛ, ::EnergyModel)

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
