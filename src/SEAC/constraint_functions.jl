
function EMB.constraints_capacity(m, n::MinUpDownTimeNode, 𝒯::TimeStructure, modeltype::EnergyModel)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    sps = collect(𝒯ᴵⁿᵛ)

    for sp in sps
        ops = collect(sp) #array of al operational periodes

        N_h = n.minDownTime #min down time in the tinme unit used in the case
        M_h = n.minUpTime
        durations = [duration(t) for t in ops]

        N_arr = zeros(length(ops))
        M_arr = zeros(length(ops))

        for j in 1:length(ops)
            sum_duration_N = durations[j]
            count = 1
            while sum_duration_N < N_h
                sum_duration_N += circshift(durations,-count)[j]
                count += 1
            end
            N_arr[j] = count
            count = 1
            sum_duration_M = durations[j]
            while sum_duration_M < M_h
                sum_duration_M += circshift(durations,-count)[j]
                count += 1
            end
            M_arr[j] = count
        end

        min_cap = n.minCapacity
        max_cap = n.maxCapacity
        for i in 1:length(ops) # i from 1 to number of operational periodes
            M = Int(M_arr[i])
            N = Int(N_arr[i])
            t = ops[i]

            @constraint(m, m[:on_off][n,t] == m[:on_off][n,circshift(ops,1)[i]] - m[:offswitch][n,t] + m[:onswitch][n,t])

            @constraint(m, m[:onswitch][n,t] + m[:offswitch][n,t] <= 1)

            @constraint(m,  sum(m[:onswitch][n,  circshift(ops, -i + M )[1:M-1]] )    <= 1    )
            @constraint(m, m[:offswitch][n,t] <= 1 - sum(m[:onswitch][n,  circshift(ops, -i + M )[1:M-1]] ) )


            @constraint(m, sum(  m[:offswitch][n,   circshift(ops, -i + N )[1:N-1]    ]) <= 1)
            @constraint(m, m[:onswitch][n,t] <= 1 - sum(  m[:offswitch][n,   circshift(ops, -i + N )[1:N-1]    ]) )

            @constraint(m, m[:cap_use][n,t] <= m[:on_off][n,t]*max_cap)
            @constraint(m, m[:cap_use][n,t] >= m[:on_off][n,t]*min_cap)

            @constraint(m, m[:cap_use][n, t] <= m[:cap_inst][n, t])
        end
    end
    constraints_capacity_installed(m, n, 𝒯, modeltype)
end

function EMB.constraints_capacity(m, n::ActivationCostNode, 𝒯::TimeStructure, modeltype::EnergyModel)
    𝒯ᴵⁿᵛ   = strategic_periods(𝒯)
    for t_inv ∈ 𝒯ᴵⁿᵛ
        for (t_prev, t) in withprev(t_inv)
            if isnothing(t_prev)
                @constraint(m, m[:on_off][n,t] == m[:on_off][n,last(t_inv)] - m[:offswitch][n,t] + m[:onswitch][n,t])
            else
                @constraint(m, m[:on_off][n,t] == m[:on_off][n,t_prev] - m[:offswitch][n,t] + m[:onswitch][n,t])
            end
        end
    end
    @constraint(m, [t ∈ 𝒯] ,m[:cap_use][n,t] == m[:on_off][n,t]*capacity(n,t))
    @constraint(m, [t ∈ 𝒯] ,m[:cap_use][n, t] <= m[:cap_inst][n, t])
end




function EMB.constraints_flow_in(m, n::ActivationCostNode, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Declaration of the required subsets
    𝒫ⁱⁿ  = inputs(n)

    # Constraint for the individual input stream connections
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ⁱⁿ],
        m[:flow_in][n, t, p] == m[:cap_use][n, t] * inputs(n, p)
        + m[:onswitch][n,t] * activation_consumption(n, p)
    )
end


# function EMB.constraints_capacity(m, n::ElectricBattery, 𝒯::TimeStructure, modeltype::EnergyModel)
#     @constraint(m, [t ∈ 𝒯], m[:stor_level][n, t] <= m[:stor_level_inst][n, t])

#     @constraint(m, [t ∈ 𝒯],m[:stor_charge_use][n, t] <= m[:stor_charge_inst][n, t])

#     @constraint(m, [t ∈ 𝒯],m[:stor_discharge_use][n, t] <= m[:stor_charge_inst][n, t])

#     # Including c_rate as a constraint for the charging and discharging 
#     @constraint( m, [t ∈  𝒯],m[:stor_charge_use][n, t] <= m[:stor_level_inst][n, t] * n.c_rate ) 
#     @constraint( m, [t ∈  𝒯],m[:stor_discharge_use][n, t] <= m[:stor_level_inst][n, t] * n.c_rate ) 

#     constraints_capacity_installed(m, n, 𝒯, modeltype)
# end

# function EMB.constraints_flow_in(m, n::ElectricBattery, 𝒯::TimeStructure, modeltype::EnergyModel)
#     # Declaration of the required subsets
#     p_stor = storage_resource(n)
#     𝒫ᵃᵈᵈ   = setdiff(inputs(n), [p_stor])

#     # Constraint for additional required input
#     @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ],
#         m[:flow_in][n, t, p] == m[:flow_in][n, t, p_stor] * inputs(n, p)
#     )

#     # Constraint for storage rate usage for charging and discharging with efficency
#     @constraint(m, [t ∈ 𝒯],
#         m[:stor_charge_use][n, t] == m[:flow_in][n, t, p_stor] * n.coloumbic_eff
#     )
# end

function EMB.constraints_level_aux(m, n::ElectricBattery, 𝒯, 𝒫, modeltype::EnergyModel)
    # Declaration of the required subsets
    p_stor = storage_resource(n)

    # Constraint for the change in the level in a given operational period
    @constraint(m, [t ∈ 𝒯],
        m[:stor_level_Δ_op][n, t] ==
            m[:stor_charge_use][n, t] - m[:stor_discharge_use][n, t]
    )
end


function EMB.constraints_capacity(m, n::ElectricBattery, 𝒯::TimeStructure, modeltype::EnergyModel)
    @constraint(m, [t ∈ 𝒯], m[:stor_level][n, t] <= m[:stor_level_inst][n, t])

    @constraint(m, [t ∈ 𝒯],m[:stor_charge_use][n, t] <= m[:stor_charge_inst][n, t])

    @constraint(m, [t ∈ 𝒯],m[:stor_discharge_use][n, t] <= m[:stor_charge_inst][n, t])

    # Including c_rate as a constraint for the charging and discharging
    @constraint( m, [t ∈  𝒯],m[:stor_charge_use][n, t] <= m[:stor_level_inst][n, t] * n.c_rate )
    @constraint( m, [t ∈  𝒯],m[:stor_discharge_use][n, t] <= m[:stor_level_inst][n, t] * n.c_rate )

    constraints_capacity_installed(m, n, 𝒯, modeltype)
end

function EMB.constraints_flow_in(m, n::ElectricBattery, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Declaration of the required subsets
    p_stor = storage_resource(n)
    𝒫ᵃᵈᵈ   = setdiff(inputs(n), [p_stor])

    # Constraint for additional required input
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵃᵈᵈ],
        m[:flow_in][n, t, p] == m[:flow_in][n, t, p_stor] * inputs(n, p)
    )

    # Constraint for storage rate usage for charging and discharging with efficency
    @constraint(m, [t ∈ 𝒯],
        m[:stor_charge_use][n, t] == m[:flow_in][n, t, p_stor] * n.coloumbic_eff
    )
end

function EMB.constraints_capacity(m, n::LoadShiftingNode, 𝒯::TimeStructure, modeltype::EnergyModel)
    constraints_capacity_installed(m, n, 𝒯, modeltype)
    load_shifts_per_periode = n.load_shifts_per_periode
    # Extra constraints
    times = collect(𝒯) # all operational times
    ls_times = times[n.loadshifttimes]
    n_loadshift = n.n_loadshift # number of timeslots we are allowed to shift a load, NB! timeslot does not mean timesteps, but number of slots allowed for load shifitng
    for i in 1:n_loadshift:length(ls_times)
        @constraint(m, sum(m[:load_shift_to][n,ls_times[i:(i + n_loadshift -1)]])   <= load_shifts_per_periode )
        @constraint(m, sum(m[:load_shift_from][n,ls_times[i:(i + n_loadshift -1)]]) <= load_shifts_per_periode )
        @constraint(m, sum(m[:load_shift_from][n,ls_times[i:(i + n_loadshift -1)]])  - sum(m[:load_shift_to][n,ls_times[i:(i + n_loadshift -1)]]) == 0 )
    end
    for t in ls_times
        @constraint(m, m[:load_shift_from][n,t] + m[:load_shift_to][n,t]  <= 1 )
    end
    all_in_shifting_times = []
    for t in n.loadshifttimes
        for i in 0:(n.load_shift_duration-1)
            ti = times[t + i]
            tls = times[t]
            @constraint(m,m[:load_shifted][n,ti] == - n.load_shift_magnitude*m[:load_shift_from][n,tls] + n.load_shift_magnitude*m[:load_shift_to][n,tls])
            append!(all_in_shifting_times,t+i)
        end
    end
    for i in 1:length(times)
        if i ∉ all_in_shifting_times
            @constraint(m ,m[:load_shifted][n, times[i]] == 0)
        end
    end
    # Constrain the capacity to be the original demand pluss the shifted load
    @constraint(m, [t ∈ 𝒯] , m[:cap_use][n,t] == m[:cap_inst][n,t] + m[:load_shifted][n,t])
end
