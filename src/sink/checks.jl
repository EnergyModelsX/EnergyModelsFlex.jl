"""
    check_node(n::PeriodDemandSink, 𝒯, ::EnergyModel)

This method checks that a [`PeriodDemandSink`](@ref) node is valid.

## Checks
- The field `cap` is required to be non-negative.
- The values of the dictionary `input` are required to be non-negative.
- The dictionary `penalty` is required to have the keys `:deficit` and `:surplus`.
- The values `:deficit` and `:surplus` of the dictionary `penalty` are required to be
  indexable by a `PeriodPartition`.
- The sum of the values `:deficit` and `:surplus` in the dictionary `penalty` has to be
  non-negative to avoid an infeasible model.
- The individual periods must all satisfy the specified duration(s).
- The field `period_demand` is required to be non-negative and indexable by a
  `PeriodPartition`.
"""
function EMB.check_node(
    n::PeriodDemandSink,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    𝒯ᵖᵈ = periods(n, 𝒯)
    per_dur = period_duration(n)
    bool = true

    @assert_or_log(
        all(capacity(n, t) ≥ 0 for t ∈ 𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        all(inputs(n, p) ≥ 0 for p ∈ inputs(n)),
        "The values for the Dictionary `input` must be non-negative."
    )
    @assert_or_log(
        :surplus ∈ keys(n.penalty) && :deficit ∈ keys(n.penalty),
        "The entries `:surplus` and `:deficit` are required in the dictionary `penalty`."
    )
    if :surplus ∈ keys(n.penalty)
        message = "are not allowed for the key `:surplus` in the dictionary `penalty`."
        bool *= EMB.check_partition_profile(surplus_penalty(n), message)
    else
        bool = false
    end
    if :deficit ∈ keys(n.penalty)
        message = "are not allowed for the key `:deficit` in the dictionary `penalty`."
        bool *= EMB.check_partition_profile(deficit_penalty(n), message)
    else
        bool = false
    end

    if bool
        @assert_or_log(
            all(surplus_penalty(n, t_pd) + deficit_penalty(n, t_pd) ≥ 0 for t_pd ∈ 𝒯ᵖᵈ),
            "An inconsistent combination of `:surplus` and `:deficit` leads to an infeasible model."
        )
    end

    message = "are not allowed for the field `:period_duration`."
    bool = EMB.check_partition_profile(period_duration(n), message)
    if bool
        @assert_or_log(
            all(sum(duration(t) for t ∈ t_pd) ≥ per_dur[t_pd] for t_pd ∈ 𝒯ᵖᵈ),
            "The duration of the last period on the `SimpleTimes` level is shorter than " *
            "specified. This is caused by inconsistently specified `period_duration` and" *
            "time structure."
        )
    end

    message = "are not allowed for the field `:period_demand`."
    bool = EMB.check_partition_profile(period_demand(n), message)
    if bool
        @assert_or_log(
            all(period_demand(n, t_pd) ≥ 0 for t_pd ∈ 𝒯ᵖᵈ),
            "The period demand must be non-negative."
        )
    end
end
"""
    check_node(n::StratPeriodDemandSink, 𝒯, ::EnergyModel)

This method checks that a [`StratPeriodDemandSink`](@ref) node is valid.

## Checks
- The field `cap` is required to be non-negative.
- The values of the dictionary `input` are required to be non-negative.
- The dictionary `penalty` is required to have the keys `:deficit` and `:surplus`.
- The values `:deficit` and `:surplus` of the dictionary `penalty` are required to be
  indexable by a `StrategicPeriod`.
- The sum of the values `:deficit` and `:surplus` in the dictionary `penalty` has to be
  non-negative to avoid an infeasible model.
- The strategic demand must be positive and indexable by a strategic period.
- The maximum capacity per operational period must be sufficient to satisfy the annual demand
  A warning is printed if this is not the case.
- The individual periods must all satisfy the specified duration(s).
- The field `period_min` is required to be in the range [0, 1], indexable by a
  `PeriodPartition`. The sum within a strategic period should be smaller than or equal to 1
  (only a warning is thrown, as the model is still solvable).
- The field `period_max` is required to be in the range [0, 1] and indexable by a
  `PeriodPartition`. The sum within a strategic period should be larger than or equal to 1
  (only a warning is thrown, as the model is still solvable).
- A warning is thrown if the field `period_min` is larger than the field `period_max` in any
  demand period.
"""
function EMB.check_node(
    n::StratPeriodDemandSink,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    𝒯ᵖᵈ = periods(n, 𝒯)
    per_dur = period_duration(n)
    bool = true

    bool_cap = all(capacity(n, t) ≥ 0 for t ∈ 𝒯)
    @assert_or_log(bool_cap, "The capacity must be non-negative.")
    @assert_or_log(
        all(inputs(n, p) ≥ 0 for p ∈ inputs(n)),
        "The values for the Dictionary `input` must be non-negative."
    )
    @assert_or_log(
        :surplus ∈ keys(n.penalty) && :deficit ∈ keys(n.penalty),
        "The entries `:surplus` and `:deficit` are required in the dictionary `penalty`."
    )
    if :surplus ∈ keys(n.penalty)
        message = "are not allowed for the key `:surplus` in the dictionary `penalty`."
        bool *= EMB.check_strategic_profile(surplus_penalty(n), message)
    else
        bool = false
    end
    if :deficit ∈ keys(n.penalty)
        message = "are not allowed for the key `:deficit` in the dictionary `penalty`."
        bool *= EMB.check_strategic_profile(deficit_penalty(n), message)
    else
        bool = false
    end

    if bool
        @assert_or_log(
            all(surplus_penalty(n, t_pd) + deficit_penalty(n, t_pd) ≥ 0 for t_pd ∈ 𝒯ᵖᵈ),
            "An inconsistent combination of `:surplus` and `:deficit` leads to an infeasible model."
        )
    end

    message = "are not allowed for the field `:strat_demand`."
    bool = EMB.check_strategic_profile(strategic_demand(n), message)
    if bool
        bool_strat = all(strategic_demand(n, t_inv) ≥ 0 for t_inv ∈ 𝒯ᴵⁿᵛ)
        @assert_or_log(bool_strat, "The strategic demand must be non-negative." )
        bool_strat *= any(
                sum(capacity(n, t) * scale_op_sp(t_inv, t) for t ∈ t_inv) ≤
                    strategic_demand(n, t_inv)
            for t_inv ∈ 𝒯ᴵⁿᵛ) * all(capacity(n, t) ≥ 0 for t ∈ 𝒯)
        if bool_strat
            @warn(
                "The scaled summation of the capacity in each operational period is " *
                "smaller than the strategic demand in at least one strategic period. As a " *
                "consequence, a deficit for `demand_sink_strat_deficit` is guaranteed.",
                maxlog=1
            )
        end
    end

    @assert_or_log(
        all(sum(duration(t) for t ∈ t_pd) ≥ per_dur[t_pd] for t_pd ∈ 𝒯ᵖᵈ),
        "The duration of the last period on the `SimpleTimes` level is shorther than " *
        "specified. This is caused by inconsistently specified `period_duration` and" *
        "time structure."
    )

    message = "are not allowed for the field `:period_min`."
    bool = EMB.check_partition_profile(period_demand_min(n), message)
    if bool
        bool_min = all(0 ≤ period_demand_min(n, t_pd) ≤ 1 for t_pd ∈ 𝒯ᵖᵈ)
        @assert_or_log(
            bool_min,
            "The minimum demand to be satisfied in a period must be in the range [0, 1]."
        )
        bool_min *= any(
            sum(period_demand_min(n, t_pd) for t_pd ∈ periods(n, t_inv)) > 1
        for t_inv ∈ 𝒯ᴵⁿᵛ)
        if bool_min
            @warn(
                "The sum of the minimum period demands is in at least one strategic period " *
                "larger than 1. As a consequence, a deficit for `demand_sink_deficit` is " *
                "guaranteed.",
                maxlog=1
            )
        end
    end

    message = "are not allowed for the field `:period_max`."
    bool *= EMB.check_partition_profile(period_demand_max(n), message)
    if bool
        bool_max = all(0 ≤ period_demand_max(n, t_pd) ≤ 1 for t_pd ∈ 𝒯ᵖᵈ)
        @assert_or_log(
            bool_max,
            "The maximum demand to be satisfied in a period must be in the range [0, 1]."
        )
        bool_max *= any(
            sum(period_demand_max(n, t_pd) for t_pd ∈ periods(n, t_inv)) < 1
        for t_inv ∈ 𝒯ᴵⁿᵛ)
        if bool_max
            @warn(
                "The sum of the maximum period demands is in at least one strategic period " *
                "smaller than 1. As a consequence, a surplus for `demand_sink_surplus` is " *
                "guaranteed.",
                maxlog=1
            )
        end
    end

    if bool
        if any(period_demand_min(n, t_pd) > period_demand_max(n, t_pd) for t_pd ∈ 𝒯ᵖᵈ)
            @warn(
                "The minimum demand through the field `period_min` is larger than the " *
                "maximum demand through the field `period_max` in at least one demand " *
                "period resulting in a guranteed penalty",
                maxlog=1
            )
        end
    end
end

"""
    EMB.check_node(n::LoadShiftingNode, 𝒯, ::EnergyModel, check_timeprofiles::Bool)

This method checks that the `LoadShiftingNode` node is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `input` are required to be positive.
 - The values of load_shift_times are required to be larger than 0.
 - The values of load_shift_times are required to be less than the length of 𝒯.
 - The values of load_shift_magnitude are required to be non-negative.
 - The values of load_shift_duration are required to be positive.
 - The values of load_shifts_per_period are required to be non-negative.
"""
function EMB.check_node(n::LoadShiftingNode, 𝒯, ::EnergyModel, check_timeprofiles::Bool)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @assert_or_log(
        all(EMB.capacity(n, t) ≥ 0 for t ∈ 𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        all(inputs(n, p) > 0 for p ∈ inputs(n)),
        "The values for the Dictionary `input` must be positive."
    )
    @assert_or_log(
        all(n.load_shift_times .≤ length(𝒯)),
        "The values of load_shift_times must be less than the length of 𝒯."
    )
    @assert_or_log(
        all(n.load_shift_magnitude ≥ 0),
        "The values of load_shift_magnitude must be non-negative."
    )
    @assert_or_log(
        all(n.load_shift_duration > 0),
        "The values of load_shift_duration must be positive."
    )
    @assert_or_log(
        all(n.load_shifts_per_period ≥ 0),
        "The values of load_shifts_per_period must be non-negative."
    )
end
