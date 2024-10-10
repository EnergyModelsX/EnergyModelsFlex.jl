"""
EMB.constraints_capacity(m, n::PeriodDemandSink, 𝒯::TimeStructure, modeltype::EnergyModel)

"""
function EMB.constraints_capacity(m, n::PeriodDemandSink, 𝒯::TimeStructure, modeltype::EnergyModel)

    @constraint(m, [t ∈ 𝒯],
        m[:cap_use][n, t] + m[:sink_deficit][n,t] ==
            m[:cap_inst][n, t] + m[:sink_surplus][n,t]
    )

    # Create a list mapping the demand period i to the operational periods it contains.
    num_periods = number_of_periods(n, 𝒯)
    period2op = [[] for i in 1:num_periods]
    for t ∈ 𝒯
        period_id = period_index(n, t)
        push!(period2op[period_id], t)
    end

    for i in 1:num_periods
        # Sum all values inside period i.
        period_total = sum(m[:cap_use][n, t] for t in period2op[i])
        # Define the demand_sink_deficit as the difference between the period demand and
        # the total capacity used.
        @constraint(m, period_total + m[:demand_sink_deficit][n, i] ==
                    n.period_demand[i] + m[:demand_sink_surplus][n, i])
    end

    EMB.constraints_capacity_installed(m, n, 𝒯, modeltype)
end


"""
constraints_opex_var(m, n::PeriodDemandSink, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)

"""
function EMB.constraints_opex_var(m, n::PeriodDemandSink, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
    # Only penalise the total surplus and deficit in each period, not in the
    # operational periods.
    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_var][n, t_inv] ==
            sum((m[:demand_sink_surplus][n, period_index(n, t)] * surplus_penalty(n, t) +
                m[:demand_sink_deficit][n, period_index(n, t)] * deficit_penalty(n, t)) *
                multiple(t_inv, t)
            for t ∈ t_inv)
    )
end

function EMB.constraints_opex_fixed(m, n::PeriodDemandSink, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
    # Fix the fixed OPEX
    for t_inv ∈ 𝒯ᴵⁿᵛ
        fix(m[:opex_fixed][n, t_inv], 0, ; force = true)
    end
end
