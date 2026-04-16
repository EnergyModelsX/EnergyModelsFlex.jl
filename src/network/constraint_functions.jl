"""
    constraints_capacity(m, n::MinUpDownTimeNode, 𝒯::TimeStructure, modeltype::EnergyModel)


Add capacity constraints to the optimization model `m` for a node `n` with
minimum up/down time requirements over the time structure `𝒯`. The constraints
ensure that the node's capacity usage respects its operational limits and
switching constraints.

# Arguments
- `m`: The optimization model.
- `n`: The node with minimum up/down time requirements.
- `𝒯`: The time structure.
- `modeltype`: The type of energy model.

# Constraints
- Ensures minimum up/down time requirements are met.
- Enforces capacity usage within specified limits.
- Adds switching constraints to prevent simultaneous on/off switching.
"""
function EMB.constraints_capacity(
    m,
    n::MinUpDownTimeNode,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    # Extract the strategic time structure
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    for t_inv ∈ 𝒯ᴵⁿᵛ
        ops = collect(t_inv) #array of al operational periodes

        N_h = n.min_time_down #min down time in the tinme unit used in the case
        M_h = n.min_time_up
        durations = [duration(t) for t ∈ t_inv]

        N_arr = zeros(length(t_inv))
        M_arr = zeros(length(t_inv))

        for (j, t) ∈ enumerate(t_inv)
            sum_duration_N = duration(t)
            count = 1
            while sum_duration_N < N_h
                sum_duration_N += circshift(durations, -count)[j]
                count += 1
            end
            N_arr[j] = count
            count = 1
            sum_duration_M = duration(t)
            while sum_duration_M < M_h
                sum_duration_M += circshift(durations, -count)[j]
                count += 1
            end
            M_arr[j] = count
        end

        min_cap = n.load_min
        max_cap = n.load_max
        for (i, t) ∈ enumerate(t_inv) # i from 1 to number of operational periodes
            M = Int(M_arr[i])
            N = Int(N_arr[i])

            @constraint(
                m,
                m[:on_off][n, t] ==
                m[:on_off][n, circshift(ops, 1)[i]] - m[:offswitch][n, t] +
                m[:onswitch][n, t]
            )

            @constraint(m, m[:onswitch][n, t] + m[:offswitch][n, t] <= 1)

            @constraint(m, sum(m[:onswitch][n, circshift(ops, -i + M)[1:(M-1)]]) <= 1)
            @constraint(
                m,
                m[:offswitch][n, t] <=
                1 - sum(m[:onswitch][n, circshift(ops, -i + M)[1:(M-1)]])
            )

            @constraint(m, sum(m[:offswitch][n, circshift(ops, -i + N)[1:(N-1)]]) <= 1)
            @constraint(
                m,
                m[:onswitch][n, t] <=
                1 - sum(m[:offswitch][n, circshift(ops, -i + N)[1:(N-1)]])
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

Add capacity constraints to the optimization model `m` for a node `n` with
activation cost considerations over the time structure `𝒯`. The constraints
ensure that the node's capacity usage respects its operational limits and
switching constraints.

# Constraints
- Ensures proper on/off switching behavior.
- Enforces capacity usage within specified limits.
- Adds constraints to prevent simultaneous on/off switching.

# Arguments
- `m`: The optimization model.
- `n`: The node with activation cost considerations.
- `𝒯`: The time structure.
- `modeltype`: The type of energy model.
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
    @constraint(m, [t ∈ 𝒯], m[:onswitch][n, t] + m[:offswitch][n, t] ≤ 1)
    @constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] == m[:on_off][n, t] * capacity(n, t))
    @constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] ≤ m[:cap_inst][n, t])
    @constraint(m, [t ∈ 𝒯], m[:cap_inst][n, t] == capacity(n, t))
end

"""
    constraints_flow_in(m, n::ActivationCostNode, 𝒯::TimeStructure, ::EnergyModel)

Add flow input constraints to the optimization model `m` for a node `n` with
activation cost considerations over the time structure `𝒯`. The constraints
ensure that the node's input flows respect its capacity usage and activation
consumption.

# Arguments
- `m`: The optimization model.
- `n`: The node with activation cost considerations.
- `𝒯`: The time structure.
- `modeltype`: The type of energy model.

# Constraints
- Ensures input flow respects capacity usage.
- Accounts for activation consumption in input flows.
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
    𝒫ˡⁱᵐ = limits(n)

    # Constraint for the input stream connections
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:flow_in][n, t, p] / inputs(n, p) for p ∈ 𝒫ⁱⁿ) == m[:cap_use][n, t]
    )

    # Limit the fraction of an input resource relative to the total output
    tot_flow_in = @expression(m, [t ∈ 𝒯], sum(m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ))
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ˡⁱᵐ], m[:flow_in][n, t, p] ≤ tot_flow_in[t] * limits(n, p))
end

"""
    constraints_flow_in(m, n::Combustion, 𝒯::TimeStructure, ::EnergyModel)

Function for creating the constraint on the inlet flow to a `Combustion` node. The input
resources are limited by the `limit` field in the node `n` as for the `LimitedFlexibleInput` node,
but additionally, it is balance requirement for the input and output flows controlled by the
`heat_resource` field in the node `n`. If `outputs(n, p_heat)` == 1, then there is flow balance.
"""
function EMB.constraints_flow_in(
    m,
    n::Combustion,
    𝒯::TimeStructure,
    ::EnergyModel,
)
    # Declaration of the required subsets
    𝒫ⁱⁿ = inputs(n)
    𝒫ˡⁱᵐ = limits(n)
    p_heat = heat_resource(n)

    # Constraint for the input stream connections
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:flow_in][n, t, p] / inputs(n, p) for p ∈ 𝒫ⁱⁿ) == m[:cap_use][n, t]
    )

    # Limit the fraction of an input resource relative to the total output
    tot_flow_in = @expression(m, [t ∈ 𝒯], sum(m[:flow_in][n, t, p] for p ∈ 𝒫ⁱⁿ))
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ˡⁱᵐ], m[:flow_in][n, t, p] ≤ tot_flow_in[t] * limits(n, p))

    # Balance constraint for the combustion node
    @constraint(
        m,
        [t ∈ 𝒯],
        tot_flow_in[t] ==
        m[:cap_use][n, t] + m[:flow_out][n, t, p_heat] / outputs(n, p_heat)
    )
end

"""
    constraints_flow_out(m, n::Combustion, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the outlet flow from a `Combustion` node.
"""
function EMB.constraints_flow_out(
    m,
    n::Combustion,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    # Declaration of the required subsets, excluding CO2, if specified
    𝒫ᵒᵘᵗ = EMB.res_not(outputs(n), co2_instance(modeltype))
    p_heat = heat_resource(n)
    𝒫ᵐⁱˣ = setdiff(𝒫ᵒᵘᵗ, [p_heat])

    # Constraint for the individual output stream connections
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵐⁱˣ],
        m[:flow_out][n, t, p] == m[:cap_use][n, t] * outputs(n, p)
    )
end

"""
    constraints_flow_out(m, n::FlexibleOutput, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the outlet flow from a `FlexibleOutput`.
"""
function EMB.constraints_flow_out(
    m,
    n::FlexibleOutput,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    # Declaration of the required subsets, excluding CO2, if specified
    𝒫ᵒᵘᵗ = EMB.res_not(outputs(n), co2_instance(modeltype))

    # Definition of custom constraint: node can output multiple resources, but the overall
    # output (sum of all resources) cannot be higher than the available capacity
    # Constraint for the sum of all output flows to equal `:cap_use`
    @constraint(m, [t ∈ 𝒯],
        sum(m[:flow_out][n, t, p] / outputs(n, p) for p ∈ 𝒫ᵒᵘᵗ) == m[:cap_use][n, t]
    )
end
