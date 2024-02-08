"""
    constraints_capacity(m, n::Storage, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the maximum level of a generic `Storage`.
This function serves as fallback option if no other function is specified for a `Storage`.
"""
function EMB.constraints_capacity(m, n::RyeMicrogrid.BatteryStorage, 𝒯::TimeStructure, modeltype::EnergyModel)

    @constraint(m, [t ∈ 𝒯],
        m[:stor_level][n, t] <= m[:stor_cap_inst][n, t]
    )

    @constraint(m, [t ∈ 𝒯],
        m[:stor_rate_use][n, t] <= m[:stor_rate_inst][n, t]
    )

    @constraint(m, [t ∈ 𝒯],
        m[:stor_rate_receive][n, t] <= m[:stor_rate_inst_charge][n, t]
    )

    constraints_capacity_installed(m, n, 𝒯, modeltype)
end
function constraints_capacity_installed(m, n::RyeMicrogrid.BatteryStorage, 𝒯::TimeStructure, modeltype::EnergyModel)

    cap = RyeMicrogrid.capacity(n)
    @constraint(m, [t ∈ 𝒯],
        m[:stor_cap_inst][n, t] == cap.level[t]
    )

    @constraint(m, [t ∈ 𝒯],
        m[:stor_rate_inst][n, t] + m[:stor_res_up][n, t] == n.discharge_cap[t]
    )

    @constraint(m, [t ∈ 𝒯],
        m[:stor_rate_inst_charge][n, t] + m[:stor_res_down][n, t] == n.charge_cap[t]
    )
end

function EMB.constraints_level_aux(m, n::RyeMicrogrid.BatteryStorage, 𝒯, 𝒫, modeltype::EnergyModel)
    # Declaration of the required subsets
    p_stor = storage_resource(n)

    # Constraint for the change in the level in a given operational period
    @constraint(m, [t ∈ 𝒯],
        m[:stor_level_Δ_op][n, t] == n.charge_eff * m[:flow_in][n, t, p_stor] - (1/n.discharge_eff) * m[:flow_out][n, t, p_stor]
    )
end

function EMB.constraints_level_sp(
    m,
    n::RyeMicrogrid.BatteryStorage{S},
    t_inv::TS.StrategicPeriod{T, U},
    𝒫,
    modeltype::EnergyModel
) where {S<:ResourceCarrier, T, U<:SimpleTimes}

    # Mass/energy balance constraints for stored energy carrier.
    for (t_prev, t) ∈ withprev(t_inv)
        if isnothing(t_prev)
            @constraint(m,
                m[:stor_level][n, t] ==
                    m[:stor_level][n, last(t_inv)] +
                    m[:stor_level_Δ_op][n, t] * duration(t)
            )
        else
            @constraint(m,
                m[:stor_level][n, t] ==
                    m[:stor_level][n, t_prev] +
                    m[:stor_level_Δ_op][n, t] * duration(t)
            )
        end
    end
end

function EMB.constraints_flow_out(m, n::RyeMicrogrid.BatteryStorage, 𝒯::TimeStructure, modeltype::EnergyModel)
    p_stor = storage_resource(n)
    𝒫ᵃᵈᵈ   = setdiff(inputs(n), [p_stor])

    # Constraint for the individual output stream connections
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ],
        m[:flow_out][n, t, p] == m[:cap_use][n, t] * outputs(n, p)
    )

    # Constraint for storage rate use
    @constraint(m, [t ∈ 𝒯],
        m[:stor_rate_receive][n, t] == m[:flow_out][n, t, p_stor]
    )

    # Constraint for storage reserve up delivery
    @constraint(m, [t ∈ 𝒯],
        m[:stor_res_up][n, t] == sum(m[:flow_out][n, t, p] for p in n.reserve_res_up)
    )

    # Constraint for storage reserve down delivery
    @constraint(m, [t ∈ 𝒯],
        m[:stor_res_down][n, t] == sum(m[:flow_out][n, t, p] for p in n.reserve_res_down)
    )
end