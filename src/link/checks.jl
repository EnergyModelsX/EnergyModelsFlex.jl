"""
    EMB.check_link(l::CapacityCostLink, 𝒯,  ::EnergyModel, ::Bool)

This method checks that the *[`CapacityCostLink`](@ref)* link is valid.

## Checks
- The field `cap` is required to be non-negative.
- The field `cap_price` is required to be non-negative.
- The field `check_cap_price_periods` must follow the rules oulined in the subfunction
  [`check_cap_price_periods`](@ref), that is it must either be a positive number or the
  durations must sum up to the value `op_per_strat` of the time structure.
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
    check_cap_price_periods(l, 𝒯, cap_price_periods(l))
end

"""
    check_cap_price_periods(l::CapacityCostLink, 𝒯, price_pers::Int64)
    check_cap_price_periods(l::CapacityCostLink, 𝒯, price_pers::Vector{<:Number})

This method checks that the field `check_cap_price_periods` is correct.

## Checks
- If the field is an `Int64`, the field `check_cap_price_periods` is required to be positive.
- If the field is an `Vector{<:Number}`, the field `check_cap_price_periods` is required to sum
  up to the value `op_per_strat` and each value in the `Vector` must be positive.
- The individual capacity price periods must be able to represent the operational time
  structure
"""
function check_cap_price_periods(l::CapacityCostLink, 𝒯, price_pers::Int64)
    @assert_or_log(
        price_pers > 0,
        "The number of sub periods of a strategic period must be positive."
    )
    price_pers > 0 && @assert_or_log(
        vcat(get_sub_periods(l, 𝒯)...) == collect(𝒯),
        "The operational period durations could not accumulate into `cap_price_periods =
        $(price_pers)` sub periods of each strategic period."
    )
end
function check_cap_price_periods(l::CapacityCostLink, 𝒯, price_pers::Vector{<:Number})
    @assert_or_log(
        sum(price_pers) ≈ 𝒯.op_per_strat,
        "The duration of all sub periods must be equal to the value `op_per_strat` of the " *
        "time structure."
    )
    @assert_or_log(
        all(price_pers .> 0),
        "Each sub period must have a positive duration."
    )
    @assert_or_log(
        vcat(get_sub_periods(l, 𝒯)...) == collect(𝒯),
        "The operational period durations could not accumulate into `cap_price_periods =
        $(length(price_pers))` sub periods of each strategic period."
    )
end
