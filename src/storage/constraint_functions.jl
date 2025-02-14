"""
    constraints_level_aux(m, n::ElectricBattery, 𝒯, 𝒫, ::EnergyModel)

Write docstring here...
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

Write docstring here...
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

Write docstring here...
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

#"""
#    constraints_capacity(m, n::Storage, 𝒯::TimeStructure, modeltype::EnergyModel)
#
#Function for creating the constraint on the maximum level of a generic `Storage`.
#This function serves as fallback option if no other function is specified for a `Storage`.
#"""
#function EMB.constraints_capacity(
#    m,
#    n::BatteryStorage,
#    𝒯::TimeStructure,
#    modeltype::EnergyModel,
#)
#    @constraint(m, [t ∈ 𝒯], m[:stor_level][n, t] <= m[:stor_cap_inst][n, t])
#
#    @constraint(m, [t ∈ 𝒯], m[:stor_rate_ch][n, t] <= m[:stor_rate_inst_ch][n, t])
#
#    @constraint(m, [t ∈ 𝒯], m[:stor_rate_dch][n, t] <= m[:stor_rate_inst_dch][n, t])
#
#    EMB.constraints_capacity_installed(m, n, 𝒯, modeltype)
#end
#
#function EMB.constraints_capacity_installed(
#    m,
#    n::BatteryStorage,
#    𝒯::TimeStructure,
#    ::EnergyModel,
#)
#    cap = capacity(n)
#    @constraint(m, [t ∈ 𝒯], m[:stor_cap_inst][n, t] == cap.level[t])
#
#    # Limits the actual discharge capacity to the technical max limit minus the reserve up capability
#    @constraint(m, [t ∈ 𝒯], m[:stor_rate_inst_dch][n, t] == n.discharge_cap[t])
#
#    # Limits the actual charge capacity to the technical max limit minus the reserve down capability
#    @constraint(m, [t ∈ 𝒯], m[:stor_rate_inst_ch][n, t] == n.charge_cap[t])
#
#    @constraint(
#        m,
#        [t ∈ 𝒯],
#        m[:stor_rate_dch][n, t] - m[:stor_rate_ch][n, t] - m[:stor_rate_inst_dch][n, t] +
#        m[:stor_res_up][n, t] <= 0
#    )
#
#    @constraint(
#        m,
#        [t ∈ 𝒯],
#        -m[:stor_rate_dch][n, t] + m[:stor_rate_ch][n, t] - m[:stor_rate_inst_ch][n, t] +
#        m[:stor_res_down][n, t] <= 0
#    )
#end
#
#function constraints_equal_reserve(m, n, 𝒯::TimeStructure, modeltype::EnergyModel) end
#
#function constraints_equal_reserve(
#    m,
#    n::BatteryStorage,
#    𝒯::TimeStructure,
#    ::EnergyModel,
#)
#    for (t_prev, t) ∈ withprev(𝒯)
#        if !isnothing(t_prev)
#            @constraints(m, begin
#                m[:stor_res_up][n, t] - m[:stor_res_up][n, t_prev] == 0
#                m[:stor_res_down][n, t] - m[:stor_res_down][n, t_prev] == 0
#            end)
#        end
#    end
#end
#
#function EMB.constraints_level_aux(m, n::BatteryStorage, 𝒯, 𝒫, modeltype::EnergyModel)
#    # Declaration of the required subsets
#    p_stor = storage_resource(n)
#
#    # Constraint for the change in the level in a given operational period
#    @constraint(
#        m,
#        [t ∈ 𝒯],
#        m[:stor_level_Δ_op][n, t] ==
#        n.charge_eff * m[:flow_in][n, t, p_stor] -
#        (1 / n.discharge_eff) * m[:flow_out][n, t, p_stor]
#    )
#end
#
#function EMB.constraints_level_sp(
#    m,
#    n::BatteryStorage{S},
#    t_inv::TS.StrategicPeriod{T,U},
#    𝒫,
#    ::EnergyModel,
#) where {S<:ResourceCarrier,T,U<:SimpleTimes}
#
#    # Mass/energy balance constraints for stored energy carrier.
#    for (t_prev, t) ∈ withprev(t_inv)
#        if isnothing(t_prev)
#            @constraint(
#                m,
#                m[:stor_level][n, t] ==
#                m[:stor_level][n, last(t_inv)] + m[:stor_level_Δ_op][n, t] * duration(t)
#            )
#        else
#            @constraint(
#                m,
#                m[:stor_level][n, t] ==
#                m[:stor_level][n, t_prev] + m[:stor_level_Δ_op][n, t] * duration(t)
#            )
#        end
#    end
#end
#
#function EMB.constraints_flow_in(
#    m,
#    n::BatteryStorage,
#    𝒯::TimeStructure,
#    ::EnergyModel,
#)
#    # Declaration of the required subsets
#    p_stor = storage_resource(n)
#    𝒫ᵃᵈᵈ = setdiff(inputs(n), [p_stor])
#
#    # Constraint for additional required input
#    @constraint(
#        m,
#        [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ],
#        m[:flow_in][n, t, p] == m[:flow_in][n, t, p_stor] * inputs(n, p)
#    )
#
#    # Constraint for storage rate use
#    @constraint(m, [t ∈ 𝒯], m[:stor_rate_ch][n, t] == m[:flow_in][n, t, p_stor])
#end
#
#function EMB.constraints_flow_out(
#    m,
#    n::BatteryStorage,
#    𝒯::TimeStructure,
#    ::EnergyModel,
#)
#    p_stor = storage_resource(n)
#    𝒫ᵃᵈᵈ = setdiff(inputs(n), [p_stor])
#
#    # Constraint for the individual output stream connections
#    @constraint(
#        m,
#        [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ],
#        m[:flow_out][n, t, p] == m[:cap_use][n, t] * outputs(n, p)
#    )
#
#    # Constraint for storage rate use
#    @constraint(m, [t ∈ 𝒯], m[:stor_rate_dch][n, t] == m[:flow_out][n, t, p_stor])
#
#    # Constraint for storage reserve up delivery
#    @constraint(
#        m,
#        [t ∈ 𝒯],
#        m[:stor_res_up][n, t] == sum(m[:flow_out][n, t, p] for p ∈ n.reserve_res_up)
#    )
#
#    # Constraint for storage reserve down delivery
#    @constraint(
#        m,
#        [t ∈ 𝒯],
#        m[:stor_res_down][n, t] == sum(m[:flow_out][n, t, p] for p ∈ n.reserve_res_down)
#    )
#end
#
