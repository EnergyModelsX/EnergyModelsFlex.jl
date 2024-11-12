"""
    EMB.constraints_flow_in(m, n::StorageEfficiency, 𝒯::TimeStructure, ::EnergyModel)

Function for creating the constraint on the inlet flow to a generic `StorageEfficiency`.
This function serves as fallback option if no other function is specified for a `StorageEfficiency`.
"""
function EMB.constraints_flow_in(m, n::StorageEfficiency, 𝒯::TimeStructure, ::EnergyModel)
    # Declaration of the required subsets
    p_stor = storage_resource(n)
    𝒫ᵃᵈᵈ = setdiff(inputs(n), [p_stor])

    # Constraint for additional required input
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ],
        m[:flow_in][n, t, p] == m[:flow_in][n, t, p_stor] * inputs(n, p)
    )

    # Constraint for StorageEfficiency rate usage for charging and discharging
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_charge_use][n, t] == m[:flow_in][n, t, p_stor] * inputs(n, p_stor)
    )
end

"""
    EMB.constraints_flow_out(m, n::StorageEfficiency, 𝒯::TimeStructure, ::EnergyModel)

Function for creating the constraint on the outlet flow from a generic `StorageEfficiency`.
This function serves as fallback option if no other function is specified for a `StorageEfficiency`.
"""
function EMB.constraints_flow_out(m, n::StorageEfficiency, 𝒯::TimeStructure, ::EnergyModel)
    # Declaration of the required subsets
    p_stor = storage_resource(n)

    # Constraint for the individual output stream connections
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_discharge_use][n, t] * outputs(n, p_stor) == m[:flow_out][n, t, p_stor]
    )
end

"""
    EMB.constraints_capacity(m, n::PayAsProducedPPA, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the maximum capacity of a `PayAsProducedPPA`.
Also sets the constraint defining curtailment.
"""
function EMB.constraints_capacity(
    m,
    n::PayAsProducedPPA,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    @constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] ≤ m[:cap_inst][n, t])

    # Non dispatchable renewable energy sources operate at their max
    # capacity with repsect to the current profile (e.g. wind) at every time.
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:cap_use][n, t] + m[:curtailment][n, t] == profile(n, t) * m[:cap_inst][n, t]
    )

    constraints_capacity_installed(m, n, 𝒯, modeltype)
end

"""
    EMB.constraints_opex_var(m, n::PayAsProducedPPA, 𝒯ᴵⁿᵛ, ::EnergyModel)

Function for creating the constraint on the variable OPEX of a PayAsProducedPPA node.
"""
function EMB.constraints_opex_var(m, n::PayAsProducedPPA, 𝒯ᴵⁿᵛ, ::EnergyModel)
    @constraint(
        m,
        [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_var][n, t_inv] == sum(
            (m[:cap_use][n, t] + m[:curtailment][n, t]) *
            opex_var(n, t) *
            EMB.scale_op_sp(t_inv, t) for t ∈ t_inv
        )
    )
end

"""
    constraints_flow_in(m, n::Combustion, 𝒯::TimeStructure, ::EnergyModel)

Function for creating the constraint on the inlet flow to a generic `Node`.
This function serves as fallback option if no other function is specified for a `Node`.
"""
function EMB.constraints_flow_in(m, n::Combustion, 𝒯::TimeStructure, ::EnergyModel)
    # Declaration of the required subsets
    𝒫ⁱⁿ = inputs(n)

    # Constraint for the input stream connections
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:flow_in][n, t, p] * inputs(n, p) for p ∈ 𝒫ⁱⁿ) == m[:cap_use][n, t]
    )

    # Limit the fraction of an input resource relative to the total output
    tot_flow_in = @expression(m, [t ∈ 𝒯], sum(m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ))
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ⁱⁿ], m[:flow_in][n, t, p] ≤ tot_flow_in[t] * limits(n, p))
end
