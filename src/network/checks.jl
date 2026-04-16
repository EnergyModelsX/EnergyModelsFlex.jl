"""
    EMB.check_node(n::MinUpDownTimeNode, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a [`MinUpDownTimeNode`](@ref) node is valid.

It reuses the standard checks of a `NetworkNode` node through calling the function
[`EMB.check_node_default`](@extref EnergyModelsBase.check_node_default), but adds an
additional check on the data.

## Checks
- The field `cap` is required to be non-negative.
- The value of the field `fixed_opex` is required to be non-negative and
  accessible through a `StrategicPeriod` as outlined in the function
  [`EMB.check_fixed_opex()`](@extref EnergyModelsBase.check_fixed_opex).
- The values of the dictionary `input` are required to be non-negative.
- The values of the dictionary `output` are required to be non-negative.

 - The field `load_min` is required to be greater than zero.
 - The field `load_min` is required to be not larger than the field `load_max`.
"""
function EMB.check_node(
    n::MinUpDownTimeNode,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)

    # We need the minimum capacity to be greater than zero.
    @assert_or_log(
        n.load_min > 0,
        "The minimum capacity must be greater than zero."
    )

    @assert_or_log(
        n.load_min ≤ n.load_max,
        "The minimum capacity must not be larger than maximum capacity."
    )
end

"""
    EMB.check_node(
        n::LimitedFlexibleInput,
        𝒯,
        modeltype::EnergyModel,
        check_timeprofiles::Bool,
    )

This method checks that a `LimitedFlexibleInput` node is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `input` are required to be positive.
 - The values of the dictionary `output` are required to be non-negative.
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
 - The values of the dictionary `limit` are required to be non-negative.
 - The values of the dictionary `limit` are required to not be larger than 1.
"""
function EMB.check_node(
    n::LimitedFlexibleInput,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    check_input(n)
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
    check_limits_default(n)
end

"""
    EMB.check_node(n::Combustion, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a `Combustion` node is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `input` are required to be positive.
 - The values of the dictionary `output` are required to be non-negative.
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
 - The values of the dictionary `limit` are required to be non-negative.
 - The values of the dictionary `limit` are required to not be larger than 1.
 - The resource in the `heat_res` field must be in the dictionary `output`.
"""
function EMB.check_node(n::Combustion, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    check_input(n)
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
    check_limits_default(n)

    @assert_or_log(
        heat_resource(n) ∈ outputs(n),
        "The resource in the `heat_res` field must be in the dictionary `output`.",
    )
end

"""
    EMB.check_node(n::FlexibleOutput, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a `FlexibleOutput` node is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `input` are required to be non-negative.
 - The values of the dictionary `output` are required to be positive.
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
"""
function EMB.check_node(
    n::FlexibleOutput,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    @assert_or_log(
        all(outputs(n, p) > 0 for p ∈ outputs(n)),
        "The values for the Dictionary `output` must be positive (as they appear in a denominator)."
    )
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
end

"""
    check_limits_default(n::Union{LimitedFlexibleInput, Combustion})

This function checks that the limits of a `LimitedFlexibleInput` or `Combustion` node are valid.
"""
function check_limits_default(n::Union{LimitedFlexibleInput,Combustion})
    @assert_or_log(
        all(limits(n, p) ≤ 1 for p ∈ limits(n)),
        "The values for the Dictionary `limit` must not be larger than 1."
    )
    @assert_or_log(
        all(limits(n, p) ≥ 0 for p ∈ limits(n)),
        "The values for the Dictionary `limit` must be non-negative."
    )
end

"""
    check_input(n::Union{LimitedFlexibleInput, Combustion})

This function checks that the input of a `LimitedFlexibleInput` or `Combustion` node are valid.
"""
function check_input(n::Union{LimitedFlexibleInput,Combustion})
    @assert_or_log(
        all(inputs(n, p) > 0 for p ∈ inputs(n)),
        "The values for the Dictionary `input` must be positive (as they appear in a denominator)."
    )
end
