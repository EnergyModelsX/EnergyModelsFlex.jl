"""
    struct CapacityCostLink <: Link

A link between two nodes with costs on the link usage for the resource `cap_resource`. All
other resources have no costs associated with their usage (follows the
[`Direct`](@extref EnergyModelsBase.Direct)).

# Fields
- **`id`** is the name/identifier of the link.
- **`from::Node`** is the node from which there is flow into the link.
- **`to::Node`** is the node to which there is flow out of the link.
- **`cap::TimeProfile`** is the capacity of the link for the `cap_resource`.
- **`cap_price::TimeProfile`** is the price of capacity usage for the `cap_resource`.
- **`cap_price_periods::Union{Int64, Vector{<:Number}}`** is either the number of sub periods
  within a strategic period (if specified as `Int64`) or the minimum durations of the
  individual sub periods within a strategic period (if specified as `Vector{<:Number}`).
- **`cap_resource::Resource`** is the resource used by `CapacityCostLink`
- **`formulation::Formulation`** is the used formulation of links. The field `formulation`
  is conditional through usage of a constructor.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments). The
  field `data` is conditional through usage of a constructor.

!!! note "Sub periods"
    You can specify either the total number of sub periods within a `CapacityCostLink` as
    `Int64` or the durations of each sub period if using a `Vector{<:Number}`. The latter
    requires you to be careful when considering the durations of the individual sub periods
    and the total duration of sub periods within the operational time structure.
"""
struct CapacityCostLink <: EMB.Link
    id::Any
    from::EMB.Node
    to::EMB.Node
    cap::TimeProfile
    cap_price::TimeProfile
    cap_price_periods::Union{Int64, Vector{<:Number}}
    cap_resource::Resource
    formulation::EMB.Formulation
    data::Vector{<:ExtensionData}
end

function CapacityCostLink(
    id::Any,
    from::EMB.Node,
    to::EMB.Node,
    cap::TimeProfile,
    cap_price::TimeProfile,
    cap_price_periods::Union{Int64, Vector{<:Number}},
    cap_resource::Resource,
    formulation::EMB.Formulation,
)
    return CapacityCostLink(
        id,
        from,
        to,
        cap,
        cap_price,
        cap_price_periods,
        cap_resource,
        formulation,
        ExtensionData[],
    )
end
function CapacityCostLink(
    id::Any,
    from::EMB.Node,
    to::EMB.Node,
    cap::TimeProfile,
    cap_price::TimeProfile,
    cap_price_periods::Union{Int64, Vector{<:Number}},
    cap_resource::Resource,
    data::Vector{<:ExtensionData},
)
    return CapacityCostLink(
        id,
        from,
        to,
        cap,
        cap_price,
        cap_price_periods,
        cap_resource,
        Linear(),
        data,
    )
end
function CapacityCostLink(
    id::Any,
    from::EMB.Node,
    to::EMB.Node,
    cap::TimeProfile,
    cap_price::TimeProfile,
    cap_price_periods::Union{Int64, Vector{<:Number}},
    cap_resource::Resource,
)
    return CapacityCostLink(
        id,
        from,
        to,
        cap,
        cap_price,
        cap_price_periods,
        cap_resource,
        Linear(),
        ExtensionData[],
    )
end

"""
    EMB.has_capacity(l::CapacityCostLink)

The [`CapacityCostLink`](@ref) has a capacity, and hence, requires the declaration of capacity
variables.
"""
EMB.has_capacity(l::CapacityCostLink) = true

"""
    EMB.capacity(l::CapacityCostLink)
    EMB.capacity(l::CapacityCostLink, t)

Returns the capacity of a capacity cost link `l` as `TimeProfile` or in operational period `t`.
"""
EMB.capacity(l::CapacityCostLink) = l.cap
EMB.capacity(l::CapacityCostLink, t) = l.cap[t]

"""
    EMB.has_opex(l::CapacityCostLink)

A `CapacityCostLink` `l` has operational expenses.
"""
EMB.has_opex(l::CapacityCostLink) = true

"""
    EMB.inputs(l::CapacityCostLink)

Returns the input resources of a capacity cost link `l`, corresponding to its
[`cap_resource`](@ref).
"""
EMB.inputs(l::CapacityCostLink) = [cap_resource(l)]

"""
    EMB.outputs(l::CapacityCostLink)

Returns the output resources of a capacity cost link `l`, corresponding to its
[`cap_resource`](@ref).
"""
EMB.outputs(l::CapacityCostLink) = [cap_resource(l)]

"""
    cap_price(l::CapacityCostLink)

Returns the price per unit of maximum capacity usage of a capacity cost link `l`.
"""
cap_price(l::CapacityCostLink) = l.cap_price
cap_price(l::CapacityCostLink, t) = l.cap_price[t]

"""
    cap_price_periods(l::CapacityCostLink)

Returns either the number of sub-periods within a strategic period for which a price is
calculated or the vector of the durations of the sub-periods of a capacity cost link `l`.
"""
cap_price_periods(l::CapacityCostLink) = l.cap_price_periods

"""
    cap_resource(l::CapacityCostLink)

Returns the resource for which the capacity is limited and has a price of a capacity cost
link `l`.
"""
cap_resource(l::CapacityCostLink) = l.cap_resource
