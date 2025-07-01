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
- The sum of the values `:deficit` and `:surplus` in the dictionary `penalty` has to be
  non-negative to avoid an infeasible model.
- The remainder of the divison of the lowest time structure by the period length must be 0.
- The length of the period demand must equal the length of the lowest period times the
  parameter period length.
"""
function EMB.check_node(
    n::PeriodDemandSink,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)

    # Check that the period length and demad is working with the time structure
    # The check will only be activated in 0.3
    # for (idx_sp, ts_oper) ∈ enumerate(𝒯.operational)
    #     sub_msg = "the operational time structure in strategic period $(idx_sp)"
    #     check_period_ts(ts_oper, n, sub_msg)
    # end
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
