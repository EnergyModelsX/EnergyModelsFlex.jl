"""
    constraints_level_aux(m, n::ElectricBattery, 𝒯, 𝒫, ::EnergyModel)

Add auxiliary level constraints to the optimization model `m` for a node `n`
representing an electric battery over the time structure `𝒯` and subset `𝒫`.
The constraints ensure that the change in storage level is correctly accounted
for in each operational period.

# Arguments
- `m`: The optimization model.
- `n`: The node representing an electric battery.
- `𝒯`: The time structure.
- `𝒫`: The subset of periods.
- `modeltype`: The type of energy model.

# Constraints
- Ensures the change in storage level is equal to the difference between charge and discharge usage.

"""
function EMB.constraints_level_aux(m, n::ElectricBattery, 𝒯, 𝒫, ::EnergyModel)
    # Declaration of the required subsets
    p_stor = storage_resource(n)

    # Constraint for the change in the level in a given operational period
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_level_Δ_op][n, t] ==
        m[:stor_charge_use][n, t] - m[:stor_discharge_use][n, t]
    )
end

"""
    constraints_capacity(m, n::ElectricBattery, 𝒯::TimeStructure, modeltype::EnergyModel)

Add capacity constraints to the optimization model `m` for a node `n`
representing an electric battery over the time structure `𝒯`. The constraints
ensure that the node's capacity usage respects its operational limits, including
charging and discharging rates.

# Arguments
- `m`: The optimization model.
- `n`: The node representing an electric battery.
- `𝒯`: The time structure.
- `modeltype`: The type of energy model.

# Constraints
- Ensures storage level does not exceed installed capacity.
- Limits charge and discharge usage to installed capacity.
- Enforces charging and discharging rates based on the battery's c_rate.

"""
function EMB.constraints_capacity(
    m,
    n::ElectricBattery,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    @constraint(m, [t ∈ 𝒯], m[:stor_level][n, t] <= m[:stor_level_inst][n, t])

    @constraint(m, [t ∈ 𝒯], m[:stor_charge_use][n, t] <= m[:stor_charge_inst][n, t])

    @constraint(m, [t ∈ 𝒯], m[:stor_discharge_use][n, t] <= m[:stor_charge_inst][n, t])

    # Including c_rate as a constraint for the charging and discharging
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_charge_use][n, t] <= m[:stor_level_inst][n, t] * n.c_rate
    )
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_discharge_use][n, t] <= m[:stor_level_inst][n, t] * n.c_rate
    )

    constraints_capacity_installed(m, n, 𝒯, modeltype)
end

"""
    constraints_flow_in(m, n::ElectricBattery, 𝒯::TimeStructure, ::EnergyModel)

Add flow input constraints to the optimization model `m` for a node `n`
representing an electric battery over the time structure `𝒯`. The constraints
ensure that the node's input flows respect its storage requirements and
efficiency.

# Arguments
- `m`: The optimization model.
- `n`: The node representing an electric battery.
- `𝒯`: The time structure.
- `modeltype`: The type of energy model.

# Constraints
- Ensures additional required input flows are proportional to storage input.
- Accounts for storage rate usage for charging with efficiency.
"""
function EMB.constraints_flow_in(
    m,
    n::ElectricBattery,
    𝒯::TimeStructure,
    ::EnergyModel,
)
    # Declaration of the required subsets
    p_stor = storage_resource(n)
    𝒫ᵃᵈᵈ = setdiff(inputs(n), [p_stor])

    # Constraint for additional required input
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ],
        m[:flow_in][n, t, p] == m[:flow_in][n, t, p_stor] * inputs(n, p)
    )

    # Constraint for storage rate usage for charging and discharging with efficency
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_charge_use][n, t] == m[:flow_in][n, t, p_stor] * n.coloumbic_eff
    )
end

"""
    EMB.constraints_flow_in(m, n::StorageEfficiency, 𝒯::TimeStructure, ::EnergyModel)

Function for creating the constraint on the inlet flow to a `StorageEfficiency`.
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

Function for creating the constraint on the outlet flow from a `StorageEfficiency`.
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
