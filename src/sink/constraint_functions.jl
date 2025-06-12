"""
    constraints_capacity(m, n::PeriodDemandSink, 𝒯::TimeStructure, modeltype::EnergyModel)

Add capacity constraints to the optimization model `m` for a node `n`
representing a period demand sink over the time structure `𝒯`. The constraints
ensure that the node's capacity usage respects its operational limits and
accounts for surplus and deficit over periods.

# Arguments
- `m`: The optimization model.
- `n`: The node representing a period demand sink.
- `𝒯`: The time structure.
- `modeltype`: The type of energy model.

# Constraints
- Ensures capacity usage matches installed capacity plus any surplus or deficit.
- Limits capacity usage to installed capacity per operational period.
- Accounts the total deficit and surplus over each period.

"""
function EMB.constraints_capacity(
    m,
    n::PeriodDemandSink,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:cap_use][n, t] + m[:sink_deficit][n, t] ==
        m[:cap_inst][n, t] + m[:sink_surplus][n, t]
    )

    # Need to constraint the used capacity to the installed capacity per
    # operational period. Instead, the node may get input in operational periods
    # when the cap field is 0. This is ok for regular sink nodes, but this node
    # only penalizes surplus or deficit over a period.
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:cap_use][n, t] <= m[:cap_inst][n, t]
    )

    # Create a list mapping the demand period i to the operational periods it contains.
    num_periods = number_of_periods(n, 𝒯)
    period2op = [[] for i ∈ 1:num_periods]
    for t ∈ 𝒯
        period_id = period_index(n, t)
        push!(period2op[period_id], t)
    end

    for i ∈ 1:num_periods
        # Sum all values inside period i.
        period_total = sum(m[:cap_use][n, t] for t ∈ period2op[i])
        # Define the demand_sink_deficit as the difference between the period demand and
        # the total capacity used.
        @constraint(
            m,
            period_total + m[:demand_sink_deficit][n, i] ==
            n.period_demand[i] + m[:demand_sink_surplus][n, i]
        )
    end

    EMB.constraints_capacity_installed(m, n, 𝒯, modeltype)
end

"""
    constraints_opex_var(m, n::PeriodDemandSink, 𝒯ᴵⁿᵛ, ::EnergyModel)

Add operational expenditure (opex) variable constraints to the optimization
model `m` for a node `n` representing a period demand sink over the time
structure `𝒯ᴵⁿᵛ`. The constraints ensure that the node's surplus and deficit
penalties are properly accounted for in each period.

# Arguments
- `m`: The optimization model.
- `n`: The node representing a period demand sink.
- `𝒯ᴵⁿᵛ`: The time structure for strategic periods.
- `modeltype`: The type of energy model.

# Constraints
- Penalizes total surplus and deficit in each period.
- Accounts for surplus and deficit penalties scaled by operational periods.

"""
function EMB.constraints_opex_var(m, n::PeriodDemandSink, 𝒯ᴵⁿᵛ, ::EnergyModel)
    # Only penalise the total surplus and deficit in each period, not in the
    # operational periods.
    @constraint(
        m,
        [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_var][n, t_inv] == sum(
            (
                m[:demand_sink_surplus][n, period_index(n, t)] * surplus_penalty(n, t) +
                m[:demand_sink_deficit][n, period_index(n, t)] * deficit_penalty(n, t)
            ) * scale_op_sp(t_inv, t) for t ∈ t_inv
        )
    )
end

"""
    EMB.constraints_flow_in(m, n::MultipleInputSink, 𝒯::TimeStructure)

Function for creating the constraint on the inlet flow to a `MultipleInputSink`.
The difference to the standard flow is that the MultipleInputSink allows for
several different resources to be equivalent
"""
function EMB.constraints_flow_in(m, n::MultipleInputSink, 𝒯::TimeStructure, ::EnergyModel)
    # Declaration of the required subsets
    𝒫ⁱⁿ = inputs(n)

    # Constraint for the individual input stream connections
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:flow_in][n, t, p] / inputs(n, p) for p ∈ 𝒫ⁱⁿ) == m[:cap_use][n, t]
    )
end

"""
    EMB.constraints_flow_in(m, n::AbstractMultipleInputSinkStrat, 𝒯::TimeStructure)

Function for creating the constraint on the inlet flow to a `AbstractMultipleInputSinkStrat`.
The difference to the standard flow is that the AbstractMultipleInputSinkStrat uses the input resources
in a ratio specified by the input_frac_strat variable for each strategic period.
"""
function EMB.constraints_flow_in(
    m,
    n::AbstractMultipleInputSinkStrat,
    𝒯::TimeStructure,
    ::EnergyModel,
)

    # Declaration of the required subsets.
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    𝒫ⁱⁿ = inputs(n)

    # Constraint for the individual input stream connections
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:flow_in][n, t, p] / inputs(n, p) for p ∈ 𝒫ⁱⁿ) == m[:cap_use][n, t]
    )

    # Constraint for the individual input stream connections
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ 𝒫ⁱⁿ],
        m[:flow_in][n, t, p] / inputs(n, p) + m[:sink_deficit_p][n, t, p] ==
        EMB.capacity(n, t) * m[:input_frac_strat][n, 𝒯ᴵⁿᵛ[t.sp], p] +
        m[:sink_surplus_p][n, t, p]
    )

    # The input fractions for each resources must sum to 1
    @constraint(m, [t ∈ 𝒯ᴵⁿᵛ], sum(m[:input_frac_strat][n, t, p] for p ∈ 𝒫ⁱⁿ) == 1)

    # Define sink_deficit and sink_surplus
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:sink_deficit_p][n, t, p] for p ∈ 𝒫ⁱⁿ) == m[:sink_deficit][n, t]
    )
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:sink_surplus_p][n, t, p] for p ∈ 𝒫ⁱⁿ) == m[:sink_surplus][n, t]
    )
end

"""
    EMB.constraints_capacity(m, n::AbstractMultipleInputSinkStrat, 𝒯::TimeStructure, modeltype::EnergyModel)

Define the cap_inst variable to be the input capacity(n,t).

!!! note "Implicity surplus and deficit constraints"
    The following constraint for surplus and deficit are implicitly defined in the constraints_flow_in function.

    `m[:cap_use][n, t] + m[:sink_deficit][n, t] == m[:cap_inst][n, t] + m[:sink_surplus][n, t]`
"""
function EMB.constraints_capacity(
    m,
    n::AbstractMultipleInputSinkStrat,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    EMB.constraints_capacity_installed(m, n, 𝒯, modeltype)
end

"""
    EMB.constraints_capacity(m, n::LoadShiftingNode, 𝒯::TimeStructure, modeltype::EnergyModel)

Add capacity constraints to the optimization model `m` for a node `n`
representing a load-shifting node over the time structure `𝒯`. The constraints
ensure that the node's capacity usage respects its operational limits and
accounts for load shifting.

# Arguments
- `m`: The optimization model.
- `n`: The node representing a load-shifting node.
- `𝒯`: The time structure.
- `modeltype`: The type of energy model.

# Constraints
- Ensures capacity usage matches installed capacity plus any shifted load.
- Limits the number of load shifts per period.
- Balances load shifts from and to operational periods.
- Sets the `load_shifted` variable to the actual load shifted during load-shifting periods.
- Fixes `load_shifted` to zero for non-load-shifting periods.
"""
function EMB.constraints_capacity(
    m,
    n::LoadShiftingNode,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    constraints_capacity_installed(m, n, 𝒯, modeltype)

    # Extra constraints
    load_shifts_per_period = n.load_shifts_per_period
    times = collect(𝒯) # all operational times
    ls_times = times[n.load_shift_times]
    load_shift_times_per_period = n.load_shift_times_per_period # number of timeslots we are allowed to shift a load, NB! timeslot does not mean timesteps, but number of slots allowed for load shifitng

    # Constraint for the number of load shifts and a balance of `load_shift_from` and `load_shift_to`
    for i ∈ 1:load_shift_times_per_period:(length(ls_times)-load_shift_times_per_period+1)
        @constraint(
            m,
            sum(m[:load_shift_to][n, ls_times[i:(i+load_shift_times_per_period-1)]]) <=
            load_shifts_per_period
        )
        @constraint(
            m,
            sum(m[:load_shift_from][n, ls_times[i:(i+load_shift_times_per_period-1)]]) <=
            load_shifts_per_period
        )
        @constraint(
            m,
            sum(m[:load_shift_from][n, ls_times[i:(i+load_shift_times_per_period-1)]]) -
            sum(m[:load_shift_to][n, ls_times[i:(i+load_shift_times_per_period-1)]]) == 0
        )
    end

    # Set the variable `load_shifted` to be the actual load that is shifted at the given
    # operational period that is available for load shifting
    all_in_shifting_times = []
    for t ∈ n.load_shift_times
        for i ∈ 0:(n.load_shift_duration-1)
            ti = times[t+i]
            tls = times[t]
            @constraint(
                m,
                m[:load_shifted][n, ti] ==
                n.load_shift_magnitude *
                (m[:load_shift_to][n, tls] - m[:load_shift_from][n, tls])
            )
            append!(all_in_shifting_times, t + i)
        end
    end

    # ... and for all other times, set `load_shifted` to zero
    for i ∈ 1:length(times)
        if i ∉ all_in_shifting_times
            fix(m[:load_shifted][n, times[i]], 0; force = true)
        end
    end
    # Constrain the capacity to be the original demand pluss the shifted load
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:cap_use][n, t] == m[:cap_inst][n, t] + m[:load_shifted][n, t]
    )
end
