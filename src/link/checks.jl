"""
    EMB.check_link(l::CapacityCostLink, 𝒯,  ::EnergyModel, ::Bool)

This method checks that the *[`CapacityCostLink`](@ref)* link is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The field `cap_price` is required to be non-negative.
 - The field `cap_price_period` is required to be positive.
"""
function EMB.check_link(l::CapacityCostLink, 𝒯, ::EnergyModel, ::Bool)
    @assert_or_log(
        all(capacity(l, t) ≥ 0 for t ∈ 𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        all(cap_price(l)[t] ≥ 0 for t ∈ 𝒯),
        "The capacity price must be non-negative."
    )
    @assert_or_log(
        cap_price_periods(l) > 0,
        "The the number of sub periods of a year must be positive."
    )
    sub_periods = create_sub_periods(𝒯, l)
    @assert_or_log(
        vcat(sub_periods...) == collect(𝒯),
        "The operational period durations could not accumulate into cap_price_periods =
        $(cap_price_periods(l)) sub periods of each strategic period."
    )
end
