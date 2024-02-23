using EnergyModelsSDDP

function EMB.constraints_capacity(m, n::RyeMicrogrid.BatteryStorage, 𝒯::TimeStructure, modeltype::Union{SDDPOpModel, SDDPInvModel})

    basemodel = EnergyModelsSDDP.base_modeltype(modeltype)
    EMB.constraints_capacity(m, n, 𝒯, basemodel)
end

function EMB.constraints_capacity_installed(m, n::RyeMicrogrid.BatteryStorage, 𝒯::TimeStructure, modeltype::SDDPOpModel)
    if EnergyModelsSDDP.pure_operational_model(modeltype)
        # If a pure operational model is running, the state variable cap_inst_st
        # is not needed.
        basemodel = EnergyModelsSDDP.base_modeltype(modeltype)
        EMB.constraints_capacity_installed(m, n, 𝒯, basemodel)
        return
    end
    throw("Investments is not implemented for SDDP.")
end

function EMB.constraints_level_sp(
    m,
    n::RyeMicrogrid.BatteryStorage{S},
    t_inv::TS.StrategicPeriod{T, U},
    𝒫,
    modeltype::Union{SDDPOpModel, SDDPInvModel}
) where {S<:ResourceCarrier, T, U<:SimpleTimes}
    @info "== stor_level sddp"

    # Check if the current stage corresponds to a stage where investment will happen.
    is_inv_stage = EnergyModelsSDDP._is_investment_stage(modeltype)

    # Mass/energy balance constraints for stored energy carrier.
    for (t_prev, t) ∈ withprev(t_inv)
        if isnothing(t_prev)
            # TODO this is not the same as in EMB, when we have more than one
            # investment period. This is because this constraint leads to that
            # the stor_level will accumulate across investment periods, but this
            # is not the case in EMB. There the stor_level resets to 0 in each
            # investment period.

            if is_inv_stage
                # For the first operational period.
                @constraint(m,
                    m[:stor_level][n, t] ==
                    m[:stor_level_Δ_op][n, t] * duration(t)
                )
            else
                # For the first operational period.
                @constraint(m,
                    m[:stor_level][n, t] ==
                    m[:stor_level_st][n].in +
                    m[:stor_level_Δ_op][n, t] * duration(t)
                )
            end
        else
            @constraint(m,
                m[:stor_level][n, t] ==
                    m[:stor_level][n, t_prev] +
                    m[:stor_level_Δ_op][n, t] * duration(t)
            )
        end
    end

    # Set the outgoing value of the state variable :stor_level_st to the the
    # final value of :stor_level.
    @constraint(m, m[:stor_level_st][n].out == m[:stor_level][n, last(t_inv)])
end
