"""
    check_node(n::AbstractMultipleInputSink, 𝒯, ::EnergyModel)

This method checks that a `AbstractMultipleInputSink` node is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `input` are required to be positive.
 - The values of the dictionary `input` are required to not be larger than 1.
 - The values of the dictionary `output` are required to be non-negative.
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
"""
function EMB.check_node(
    n::AbstractMultipleInputSink,
    𝒯,
    ::EnergyModel,
    check_timeprofiles::Bool,
)
    @assert_or_log(
        all(EMB.capacity(n, t) ≥ 0 for t ∈ 𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        all(inputs(n, p) > 0 for p ∈ inputs(n)),
        "The values for the Dictionary `input` must be positive."
    )
    @assert_or_log(
        :surplus ∈ keys(n.penalty) && :deficit ∈ keys(n.penalty),
        "The entries :surplus and :deficit are required in the field `penalty`"
    )

    if :surplus ∈ keys(n.penalty) && :deficit ∈ keys(n.penalty)
        # The if-condition was checked above.
        @assert_or_log(
            all(surplus_penalty(n, t) + deficit_penalty(n, t) ≥ 0 for t ∈ 𝒯),
            "An inconsistent combination of `:surplus` and `:deficit` leads to an infeasible model."
        )
    end
end
