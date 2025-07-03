"""
    EMB.check_node(n::MinUpDownTimeNode, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a `MinUpDownTimeNode` node is valid.

## Checks
 - The minimum capacity must be greater than zero.
 - The minimum capacity must not be larger than maximum capacity.
"""
function EMB.check_node(
    n::MinUpDownTimeNode,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    # EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)

    # We need the minimum capacity to be greater than zero.
    @assert_or_log(
        n.minCapacity > 0,
        "The minimum capacity must be greater than zero."
    )

    @assert_or_log(
        n.minCapacity <= n.maxCapacity,
        "The minimum capacity must not be larger than maximum capacity."
    )
end

"""
    EMB.check_node(n::ActivationCostNode, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a `ActivationCostNode` node is valid.

## Checks
 - Investments are not supported for this node.
"""
function EMB.check_node(
    n::ActivationCostNode,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    # EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)

    @assert_or_log(
        !EnergyModelsInvestments.has_investment(n),
        "The node ActivationsCostNode does not support investments.")
end

"""
    EMB.check_node(
        n::LimitedFlexibleInput,
        𝒯,
        modeltype::EnergyModel,
        check_timeprofiles::Bool,
    )

This method checks that a `LimitedFlexibleInput` or a `Combustion` node is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `input` are required to be non-negative.
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
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
    check_limits_default(n)
end

"""
    EMB.check_node(n::Combustion, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a `LimitedFlexibleInput` or a `Combustion` node is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The values of the dictionary `input` are required to be non-negative.
 - The values of the dictionary `output` are required to be non-negative.
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
 - The values of the dictionary `limit` are required to be non-negative.
 - The values of the dictionary `limit` are required to not be larger than 1.
 - The resource in the `heat_res` field must be in the dictionary `output`.
"""
function EMB.check_node(n::Combustion, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
    check_limits_default(n)

    @assert_or_log(
        heat_resource(n) ∈ outputs(n),
        "The resource in the `heat_res` field must be in the dictionary `output`.",
    )
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
