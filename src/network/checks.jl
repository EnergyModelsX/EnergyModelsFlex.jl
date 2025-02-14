"""
    EMB.check_node(n::MinUpDownTimeNode, 𝒯, ::EnergyModel, ::Bool)

This method checks that a `MinUpDownTimeNode` node is valid.
"""
function EMB.check_node(n::MinUpDownTimeNode, 𝒯, ::EnergyModel, ::Bool)
    # We need the minimum capacity to be greater than zero.
    @assert n.minCapacity > 0

    @assert n.minCapacity <= n.maxCapacity
end

"""
    check_node(n::LimitedFlexibleInput, 𝒯, ::EnergyModel)

This method checks that a `LimitedFlexibleInput` node is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `input` are required to be non-negative.
 - The values of the dictionary `input` are required to not be larger than 1.
 - The values of the dictionary `output` are required to be non-negative.
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
"""
function EMB.check_node(n::LimitedFlexibleInput, 𝒯, ::EnergyModel, check_timeprofiles::Bool)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @assert_or_log(
        sum(EMB.capacity(n, t) ≥ 0 for t ∈ 𝒯) == length(𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        sum(inputs(n, p) ≥ 0 for p ∈ inputs(n)) == length(inputs(n)),
        "The values for the Dictionary `input` must be non-negative."
    )
    @assert_or_log(
        sum(limits(n, p) ≤ 1 for p ∈ limits(n)) == length(inputs(n)),
        "The values for the Dictionary `limit` must not be larger than 1."
    )
    @assert_or_log(
        sum(limits(n, p) ≥ 0 for p ∈ limits(n)) == length(inputs(n)),
        "The values for the Dictionary `limit` must not be larger than 1."
    )
    @assert_or_log(
        sum(outputs(n, p) ≥ 0 for p ∈ outputs(n)) == length(outputs(n)),
        "The values for the Dictionary `output` must be non-negative."
    )
    EMB.check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)
end
