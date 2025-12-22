"""
    CapacityCostLink

A link between two nodes with costs on the link usage for the resource `cap_resource`. All
other resources have no costs associated with their usage (follows the 
[`Direct`](@extref EnergyModelsBase.Direct)).

# Fields
- **`id`** is the name/identifier of the link.
- **`from::Node`** is the node from which there is flow into the link.
- **`to::Node`** is the node to which there is flow out of the link.
- **`cap::TimeProfile`** is the capacity of the link for the `cap_resource`.
- **`cap_price::TimeProfile`** is the price of capacity usage for the `cap_resource`.
- **`cap_price_periods::Int64`** is the number of sub periods of a year.
- **`cap_resource::Resource`** is the resource used by `CapacityCostLink`
- **`formulation::Formulation`** is the used formulation of links. The field
  `formulation` is conditional through usage of a constructor.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments). The
  field `data` is conditional through usage of a constructor.
"""
struct CapacityCostLink <: EMB.Link
    id::Any
    from::EMB.Node
    to::EMB.Node
    cap::TimeProfile
    cap_price::TimeProfile
    cap_price_periods::Int64
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
    cap_price_periods::Int64,
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
    cap_price_periods::Int64,
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
    cap_price_periods::Int64,
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
    has_capacity(l::CapacityCostLink)

The [`CapacityCostLink`](@ref) has a capacity, and hence, requires the declaration of capacity
variables.
"""
EMB.has_capacity(l::CapacityCostLink) = true

"""
    capacity(l::CapacityCostLink)
    capacity(l::CapacityCostLink, t)

Returns the capacity of a CapacityCostLink `l` as `TimeProfile` or in operational period `t`.
"""
EMB.capacity(l::CapacityCostLink) = l.cap
EMB.capacity(l::CapacityCostLink, t) = l.cap[t]

"""
    has_opex(l::CapacityCostLink)

A `CapacityCostLink` `l` has operational expenses.
"""
EMB.has_opex(l::CapacityCostLink) = true

"""
    cap_price(l::CapacityCostLink)

Returns the cap_price of a CapacityCostLink `l`.
"""
cap_price(l::CapacityCostLink) = l.cap_price
cap_price(l::CapacityCostLink, t) = l.cap_price[t]

"""
    cap_price_periods(l::CapacityCostLink)

Returns the cap_price_periods of a CapacityCostLink `l`.
"""
cap_price_periods(l::CapacityCostLink) = l.cap_price_periods

"""
    cap_resource(l::CapacityCostLink)

Returns the cap_resource of a CapacityCostLink `l`.
"""
cap_resource(l::CapacityCostLink) = l.cap_resource
