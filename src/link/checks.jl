"""
    EMB.check_link(l::CapacityCostLink, 𝒯,  ::EnergyModel, ::Bool)

This method checks that the *[`CapacityCostLink`](@ref)* link is valid.

## Checks
- The field `cap` is required to be non-negative.
- The field `cap_price` is required to be non-negative.
- The individual `period_duration`s must all satisfy the specified duration(s) and be
  positive.
"""
function EMB.check_link(l::CapacityCostLink, 𝒯, ::EnergyModel, ::Bool)
    𝒯ᵖᵈ = periods(l, 𝒯)

    @assert_or_log(
        all(capacity(l, t) ≥ 0 for t ∈ 𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        all(cap_price(l)[t] ≥ 0 for t ∈ 𝒯),
        "The capacity prices must be non-negative."
    )

    message = "are not allowed for the field `:period_duration`."
    bool = EMB.check_partition_profile(period_duration(l), message)
    if bool
        @assert_or_log(
            all(sum(duration(t) for t ∈ t_pd) ≥ period_duration(l, t_pd) for t_pd ∈ 𝒯ᵖᵈ),
            "The duration of the last period on the `SimpleTimes` level is shorter than " *
            "specified. This is caused by inconsistently specified `period_duration` and" *
            "time structure."
        )
        @assert_or_log(
            all(period_duration(l, t_pd) > 0 for t_pd ∈ 𝒯ᵖᵈ),
            "Each value in the field `period_duration` must be positive."
        )
    end
end
