"""
    check_node(n::PeriodDemandSink, 𝒯, ::EnergyModel)

This method checks that a [`PeriodDemandSink`](@ref) node is valid.

It reuses the standard checks of a `Sink` node through calling the function
[`EMB.check_node_default`](@extref EnergyModelsBase.check_node_default), but adds
additional checks on the data.

## Checks
- The field `cap` is required to be non-negative.
- The values of the dictionary `input` are required to be non-negative.
- The dictionary `penalty` is required to have the keys `:deficit` and `:surplus`.
- The values `:deficit` and `:surplus` of the dictionary `penalty` are required to be
  indexable by a `PartitionDuration`.
- The sum of the values `:deficit` and `:surplus` in the dictionary `penalty` has to be
  non-negative to avoid an infeasible model.
- The individual periods must all satisfy the specified duration(s).
- The field `period_demand` is required to be non-negative and indexable by a
  `PartitionDuration`.
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
        bool *= EMB.check_scenario_profile(surplus_penalty(n), message)
    else
        bool = false
    end
    if :deficit ∈ keys(n.penalty)
        message = "are not allowed for the key `:deficit` in the dictionary `penalty`."
        bool *= EMB.check_scenario_profile(deficit_penalty(n), message)
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
    bool = EMB.check_scenario_profile(period_duration(n), message)
    if bool
        @assert_or_log(
            all(sum(duration(t) for t ∈ t_pd) ≥ per_dur[t_pd] for t_pd ∈ 𝒯ᵖᵈ),
            "The duration of the last period on the `SimpleTimes` level is shorter than " *
            "specified. This is caused by inconsistently specified `period_duration` and" *
            "time structure."
        )
    end

    message = "are not allowed for the field `:period_demand`."
    bool = EMB.check_scenario_profile(period_demand(n), message)
    if bool
        @assert_or_log(
            all(period_demand(n, t_pd) ≥ 0 for t_pd ∈ 𝒯ᵖᵈ),
            "The period demand must be non-negative."
        )
    end
end


"""
    check_period_ts(ts::RepresentativePeriods, n::PeriodDemandSink, msg::String)
    check_period_ts(ts::OperationalScenarios, n::PeriodDemandSink, msg::String)
    check_period_ts(ts::SimpleTimes, n::PeriodDemandSink, msg::String)

Function for checking that the timestructure is valid in combination with the chosen period
structure in a [`PeriodDemandSink`(@ref).
"""
function check_period_ts(ts::RepresentativePeriods, n::PeriodDemandSink, msg::String)
    for (idx, ts_oper) ∈ enumerate(ts.rep_periods)
        sub_msg = msg * " in representative period $(idx)"
        check_period_ts(ts_oper, n, sub_msg)
    end
end
function check_period_ts(ts::OperationalScenarios, n::PeriodDemandSink, msg::String)
    for (idx, ts_oper) ∈ enumerate(ts.scenarios)
        sub_msg = msg * " in operational scenario $(idx)"
        check_period_ts(ts_oper, n, sub_msg)
    end
end
function check_period_ts(ts::SimpleTimes, n::PeriodDemandSink, msg::String)
    len = period_length(n)
    n_per = number_of_periods(n)
    @assert_or_log(
        length(ts)%len == 0,
        "The specified period length does not work with $(msg)."
    )
    @assert_or_log(
        length(ts)/len ≤ n_per,
        "The vector `period_demand` is shorter than the $(msg)."
    )
    if length(ts)%len == 0 & length(ts)/len < n_per
        @warn(
            "The vector `period_demand` is longer than required in $(msg). " *
            "The last $(Int(n_per-length(ts)/len)) values will be omitted.",
            maxlog=1,
        )
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
