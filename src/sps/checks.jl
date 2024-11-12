"""
    EMB.check_node(n::PayAsProducedPPA, 𝒯, ::EMB.EnergyModel, check_timeprofiles::Bool)

This method checks that the *[`PayAsProducedPPA`](@ref)* node is valid.

## Checks
 - The field `cap` is required to be non-negative (similar to the `Source` check).
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
 - The values of the dictionary `output` are required to be non-negative
   (similar to the `Source` check).
 - The field `profile` is required to be in the range ``[0, 1]`` for all time steps
   ``t ∈ \\mathcal{T}``.
"""
function EMB.check_node(n::PayAsProducedPPA, 𝒯, ::EMB.EnergyModel, check_timeprofiles::Bool)

    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @assert_or_log(
        sum(capacity(n, t) ≥ 0 for t ∈ 𝒯) == length(𝒯),
        "The capacity must be non-negative."
    )
    EMB.check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)
    @assert_or_log(
        sum(outputs(n, p) ≥ 0 for p ∈ outputs(n)) == length(outputs(n)),
        "The values for the Dictionary `output` must be non-negative."
    )
    @assert_or_log(
        sum(profile(n, t) ≤ 1 for t ∈ 𝒯) == length(𝒯),
        "The profile field must be less or equal to 1."
    )
    @assert_or_log(
        sum(profile(n, t) ≥ 0 for t ∈ 𝒯) == length(𝒯),
        "The profile field must be non-negative."
    )
end

"""
    check_node(n::Combustion, 𝒯, ::EnergyModel)

This method checks that a `Combustion` node is valid.

These checks are always performed, if the user is not creating a new method. Hence, it is
important that a new `Combustion` type includes at least the same fields as in the
`Combustion` node or that a new `Combustion` type receives a new method for `check_node`.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `input` are required to be non-negative.
 - The values of the dictionary `input` are required to not be larger than 1.
 - The values of the dictionary `output` are required to be non-negative.
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
"""
function EMB.check_node(n::Combustion, 𝒯, ::EnergyModel, check_timeprofiles::Bool)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @assert_or_log(
        sum(capacity(n, t) ≥ 0 for t ∈ 𝒯) == length(𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        sum(inputs(n, p) ≥ 0 for p ∈ inputs(n)) == length(inputs(n)),
        "The values for the Dictionary `input` must be non-negative."
    )
    @assert_or_log(
        sum(inputs(n, p) ≤ 1 for p ∈ limits(n)) == length(inputs(n)),
        "The values for the Dictionary `limit` must not be larger than 1."
    )
    @assert_or_log(
        sum(inputs(n, p) ≥ 0 for p ∈ limits(n)) == length(inputs(n)),
        "The values for the Dictionary `limit` must not be larger than 1."
    )
    @assert_or_log(
        sum(outputs(n, p) ≥ 0 for p ∈ outputs(n)) == length(outputs(n)),
        "The values for the Dictionary `output` must be non-negative."
    )
    EMB.check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)
end
