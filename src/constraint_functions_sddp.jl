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
    throw("Investments is not implemented for SDDP+RyeMicrogrid.")
end


function constraints_equal_reserve(m, n::RyeMicrogrid.BatteryStorage, 𝒯::TimeStructure, modeltype::Union{SDDPOpModel, SDDPInvModel} )
    # Set the constraints requireing stor_res_up and stor_res_down to be equal
    # throughout a stage.
    constraints_equal_reserve(m, n, 𝒯, EnergyModelsSDDP.base_modeltype(modeltype))

    # Make sure that the stor_res_up and stor_res_down are equal in all stages.
    if modeltype.node > 1
        # Since the initial value of the state variable is 0, we dont set the
        # constraint for this case. If we did the value of stor_res_up and
        # stor_res_down would be fixed to 0 in all stages.
        @constraint(m, m[:stor_res_up_st][n].in == m[:stor_res_up][n, first(𝒯)])
        @constraint(m, m[:stor_res_down_st][n].in == m[:stor_res_down][n, first(𝒯)])
    end

    @constraint(m, m[:stor_res_up_st][n].out == m[:stor_res_up][n, last(𝒯)])
    @constraint(m, m[:stor_res_down_st][n].out == m[:stor_res_down][n, last(𝒯)])
end


function EMB.constraints_level_sp(
    m,
    n::RyeMicrogrid.BatteryStorage{S},
    t_inv::TS.StrategicPeriod{T, U},
    𝒫,
    modeltype::Union{SDDPOpModel, SDDPInvModel}
) where {S<:ResourceCarrier, T, U<:SimpleTimes}
    # TODO this is not the same as the standard implementation of this method,
    # since there the storage level in the first and last operational period
    # within a strategic period is the same. This challenge is discussed in
    # EnergyModelsSDDP issue #5:
    # https://gitlab.sintef.no/clean_export/EnergyModelsSDDP.jl/-/issues/5

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
