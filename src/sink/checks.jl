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
- The individual periods must all satisfy the specified duration(s).
- The field `period_min` is required to be in the range [0, 1], indexable by a
  `PeriodPartition`, and the sum within a strategic period must be smaller than 1
  (only a warning is thrown, as the model is still solvable).
- The field `period_max` is required to be in the range [0, 1] and indexable by a
  `PeriodPartition`, and the sum within a strategic period must be larger than 1
  (only a warning is thrown, as the model is still solvable).
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
        @assert_or_log(
            all(strategic_demand(n, t_inv) ≥ 0 for t_inv ∈ 𝒯ᴵⁿᵛ),
            "The strategic demand must be non-negative."
        )
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
        @assert_or_log(
            all(0 ≤ period_demand_min(n, t_pd) ≤ 1 for t_pd ∈ 𝒯ᵖᵈ),
            "The minimum demand to be satisfied in a period must be in the range [0, 1]."
        )
        bool = any(
            sum(period_demand_min(n, t_pd) for t_pd ∈ periods(n, t_inv)) > 1
        for t_inv ∈ 𝒯ᴵⁿᵛ)
        if bool
            @warn(
                "The sum of the minimum period demands is in at least one strategic period " *
                "larger than 1. As a consequence, a deficit for `demand_sink_deficit` is " *
                "guaranteed.",
                maxlog=1
            )
        end
    end

    message = "are not allowed for the field `:period_max`."
    bool = EMB.check_partition_profile(period_demand_max(n), message)
    if bool
        @assert_or_log(
            all(0 ≤ period_demand_max(n, t_pd) ≤ 1 for t_pd ∈ 𝒯ᵖᵈ),
            "The maximum demand to be satisfied in a period must be in the range [0, 1]."
        )
        bool = any(
            sum(period_demand_max(n, t_pd) for t_pd ∈ periods(n, t_inv)) < 1
        for t_inv ∈ 𝒯ᴵⁿᵛ)
        if bool
            @warn(
                "The sum of the maximum period demands is in at least one strategic period " *
                "smaller than 1. As a consequence, a surplus for `demand_sink_surplus` is " *
                "guaranteed.",
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
