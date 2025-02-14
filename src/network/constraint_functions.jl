"""
    constraints_capacity(m, n::MinUpDownTimeNode, 𝒯::TimeStructure, modeltype::EnergyModel)

Write docstring here...
"""
function EMB.constraints_capacity(
    m,
    n::MinUpDownTimeNode,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    sps = collect(𝒯ᴵⁿᵛ)

    for sp ∈ sps
        ops = collect(sp) #array of al operational periodes

        N_h = n.minDownTime #min down time in the tinme unit used in the case
        M_h = n.minUpTime
        durations = [duration(t) for t ∈ ops]

        N_arr = zeros(length(ops))
        M_arr = zeros(length(ops))

        for j ∈ 1:length(ops)
            sum_duration_N = durations[j]
            count = 1
            while sum_duration_N < N_h
                sum_duration_N += circshift(durations, -count)[j]
                count += 1
            end
            N_arr[j] = count
            count = 1
            sum_duration_M = durations[j]
            while sum_duration_M < M_h
                sum_duration_M += circshift(durations, -count)[j]
                count += 1
            end
            M_arr[j] = count
        end

        min_cap = n.minCapacity
        max_cap = n.maxCapacity
        for i ∈ 1:length(ops) # i from 1 to number of operational periodes
            M = Int(M_arr[i])
            N = Int(N_arr[i])
            t = ops[i]

            @constraint(
                m,
                m[:on_off][n, t] ==
                m[:on_off][n, circshift(ops, 1)[i]] - m[:offswitch][n, t] +
                m[:onswitch][n, t]
            )

            @constraint(m, m[:onswitch][n, t] + m[:offswitch][n, t] <= 1)

            @constraint(m, sum(m[:onswitch][n, circshift(ops, -i + M)[1:M-1]]) <= 1)
            @constraint(
                m,
                m[:offswitch][n, t] <=
                1 - sum(m[:onswitch][n, circshift(ops, -i + M)[1:M-1]])
            )

            @constraint(m, sum(m[:offswitch][n, circshift(ops, -i + N)[1:N-1]]) <= 1)
            @constraint(
                m,
                m[:onswitch][n, t] <=
                1 - sum(m[:offswitch][n, circshift(ops, -i + N)[1:N-1]])
            )

            @constraint(m, m[:cap_use][n, t] <= m[:on_off][n, t] * max_cap)
            @constraint(m, m[:cap_use][n, t] >= m[:on_off][n, t] * min_cap)

            @constraint(m, m[:cap_use][n, t] <= m[:cap_inst][n, t])
        end
    end
    constraints_capacity_installed(m, n, 𝒯, modeltype)
end

"""
    constraints_capacity(m, n::ActivationCostNode, 𝒯::TimeStructure, ::EnergyModel)

Write docstring here...
"""
function EMB.constraints_capacity(
    m,
    n::ActivationCostNode,
    𝒯::TimeStructure,
    ::EnergyModel,
)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    for t_inv ∈ 𝒯ᴵⁿᵛ
        for (t_prev, t) ∈ withprev(t_inv)
            if isnothing(t_prev)
                @constraint(
                    m,
                    m[:on_off][n, t] ==
                    m[:on_off][n, last(t_inv)] - m[:offswitch][n, t] + m[:onswitch][n, t]
                )
            else
                @constraint(
                    m,
                    m[:on_off][n, t] ==
                    m[:on_off][n, t_prev] - m[:offswitch][n, t] + m[:onswitch][n, t]
                )
            end
        end
    end
    @constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] == m[:on_off][n, t] * capacity(n, t))
    @constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] <= m[:cap_inst][n, t])
end

"""
    constraints_flow_in(m, n::ActivationCostNode, 𝒯::TimeStructure, ::EnergyModel)

Write docstring here...
"""
function EMB.constraints_flow_in(
    m,
    n::ActivationCostNode,
    𝒯::TimeStructure,
    ::EnergyModel,
)
    # Declaration of the required subsets
    𝒫ⁱⁿ = inputs(n)

    # Constraint for the individual input stream connections
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ 𝒫ⁱⁿ],
        m[:flow_in][n, t, p] ==
        m[:cap_use][n, t] * inputs(n, p) +
        m[:onswitch][n, t] * activation_consumption(n, p)
    )
end

"""
    constraints_flow_in(m, n::LimitedFlexibleInput, 𝒯::TimeStructure, ::EnergyModel)

Function for creating the constraint on the inlet flow to a `LimitedFlexibleInput` node. The input
resources are limited by the `limit` field in the node `n`.
"""
function EMB.constraints_flow_in(
    m,
    n::LimitedFlexibleInput,
    𝒯::TimeStructure,
    ::EnergyModel,
)
    # Declaration of the required subsets
    𝒫ⁱⁿ = inputs(n)

    # Constraint for the input stream connections
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:flow_in][n, t, p] / inputs(n, p) for p ∈ 𝒫ⁱⁿ) == m[:cap_use][n, t]
    )

    # Limit the fraction of an input resource relative to the total output
    tot_flow_in = @expression(m, [t ∈ 𝒯], sum(m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ))
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ⁱⁿ], m[:flow_in][n, t, p] ≤ tot_flow_in[t] * limits(n, p))
end
