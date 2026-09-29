"""
    EMB.check_node(n::StorageEfficiency, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that a [`StorageEfficiency`](@ref) node is valid. It utilizes the default
checks introduced in the function [`check_node_default`](@extref EnergyModelsBase.check_node_default).

## Additional Checks

- The dictionary `output` can only contain the resource `stor_res`, that is the specified
  storage [`Resource`](@extref EnergyModelsBase.Resource).

## Checks (default)
- The `TimeProfile` of the field `capacity` in the type in the field `charge` is required
  to be non-negative if the chosen composite type has the field `capacity`.
- The `TimeProfile` of the field `capacity` in the type in the field `level` is required
  to be non-negative.
- The `TimeProfile` of the field `capacity` in the type in the field `discharge` is required
  to be non-negative if the chosen composite type has the field `capacity`.
- The `TimeProfile` of the field `fixed_opex` is required to be non-negative and
  accessible through a `StrategicPeriod` as outlined in the function
  [`check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`](@extref EnergyModelsBase.check_fixed_opex)
  for the chosen composite type.
- The values of the dictionary `input` are required to be non-negative.
- The specified storage [`Resource`](@extref EnergyModelsBase.Resource) must be included in
  the dictionary `input`.
- The values of the dictionary `output` are required to be non-negative.
- The specified storage [`Resource`](@extref EnergyModelsBase.Resource) must be included in
  the dictionary `output`.
"""
function EMB.check_node(
    n::StorageEfficiency,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    # Check the default resource
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)

    # Check that only the stored resource is present in the dictionary `output`
    @assert_or_log(
        isempty(setdiff(outputs(n), [storage_resource(n)])),
        "It is not feasible to specify additional `output` resources in addition to " *
        "the resource `storage_resource`."
    )
end
