"""
    EMB.constraints_capacity(m, n::AbstractPeriodDemandSink, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the maximum capacity utilization of an
[`AbstractPeriodDemandSink`](@ref).

The method is changed from the standard approach through calculating the demand period
surplus or deficit in addition to the operational period surplus or deficit.
"""
function EMB.constraints_capacity(
    m,
    n::AbstractPeriodDemandSink,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    # Declaration of the required subsets.
    𝒯ᵖᵈ = periods(n, 𝒯)

    @constraint(
        m,
        [t ∈ 𝒯],
        m[:cap_use][n, t] + m[:sink_deficit][n, t] == m[:cap_inst][n, t]
    )

    # Fix the surplus to 0
    for t ∈ 𝒯
        fix(m[:sink_surplus][n, t], 0; force = true)
    end

    # Set the energy balance for the partition duration
    @constraint(
        m,
        [t_pd ∈ 𝒯ᵖᵈ],
        m[:demand_sink_deficit][n, t_pd] +
        sum(m[:cap_use][n, t] * duration(t) for t ∈ t_pd) ==
            m[:demand_sink_surplus][n, t_pd] + period_demand(n, t_pd)
    )

    EMB.constraints_capacity_installed(m, n, 𝒯, modeltype)
end

"""
    EMB.constraints_opex_var(m, n::AbstractPeriodDemandSink, 𝒯ᴵⁿᵛ, ::EnergyModel)

Function for creating the constraint on the variable OPEX of an [`AbstractPeriodDemandSink`](@ref).

The method is adjusted from the default method through utilizing the period demand surplus
and deficit instead of the operational period deficit or surplus.
"""
function EMB.constraints_opex_var(m, n::AbstractPeriodDemandSink, 𝒯ᴵⁿᵛ, ::EnergyModel)
    # Only penalise the total surplus and deficit in each period, not in the
    # operational periods.
    @constraint(
        m,
        [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_var][n, t_inv] == sum(
                (
                    m[:demand_sink_surplus][n, t_pd] * surplus_penalty(n, t_pd) +
                    m[:demand_sink_deficit][n, t_pd] * deficit_penalty(n, t_pd)
                ) * scale_op_sp(t_inv, first(t_pd)) / duration(first(t_pd))
            for t_pd ∈ periods(n, t_inv)
        )
    )
end

"""
    EMB.constraints_flow_in(m, n::MultipleInputSink, 𝒯::TimeStructure)

Function for creating the constraint on the inlet flow of a `MultipleInputSink`.

The difference to the standard constraint is that the `MultipleInputSink` allows for
several different resources can be used interchangably and the ratio is not enforced.
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

Function for creating the constraint on the inlet flow to a [`AbstractMultipleInputSinkStrat`](@ref).

The difference to the standard method is that the [`AbstractMultipleInputSinkStrat`](@ref)
allows for satisfying the demand with multiple resources as specified through the variable
`input_frac_strat`.

As a consequence, the method includes the constraints for:

1. the capacity utilization (replacing `constraints_capacity`),
2. the bounds on the individual flows into the node based on the variable `input_frac_strat`,
3. the summation limit of `input_frac_strat`, and
4. the calculation of the total deficit in the `Sink` node.
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
        [t_inv ∈ 𝒯ᴵⁿᵛ, t ∈ t_inv, p ∈ 𝒫ⁱⁿ],
        m[:flow_in][n, t, p] / inputs(n, p) + m[:sink_deficit_p][n, t, p] ==
        capacity(n, t) * m[:input_frac_strat][n, t_inv, p] +
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

Function for creating the constraint on the capacity of a [`AbstractMultipleInputSinkStrat`](@ref).

It differs from the standard method as it does not include the capacity constraint as this
is included in `constraints_flow_in`. Instead, it only calls the subfunction
`constraints_capacity_installed`.
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
