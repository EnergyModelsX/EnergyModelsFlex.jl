""" `UnitCommitmentNode` is an abstract type for unit commitment nodes."""
abstract type UnitCommitmentNode{} <: EMB.NetworkNode end

"""
    MinUpDownTimeNode{} <: UnitCommitmentNode

Write docstring here...
"""
struct MinUpDownTimeNode{} <: UnitCommitmentNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{Resource,Real}
    output::Dict{Resource,Real}
    minUpTime::Real #number of operational periodes
    minDownTime::Real  #number of operational periodes
    minCapacity::Real
    maxCapacity::Real
    data::Array{Data}
end

"""
    ActivationCostNode{} <: UnitCommitmentNode

Write docstring here...
"""
struct ActivationCostNode{} <: UnitCommitmentNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{Resource,Real}
    output::Dict{Resource,Real}
    activation_time::Real
    activation_consumption::Dict{Resource,Real}
    data::Array{Data}
end

"""
    LimitedFlexibleInput <: NetworkNode

A `LimitedFlexibleInput` node.
The `LimitedFlexibleInput` utilizes a linear, time independent conversion rate of the `input`
[`Resource`](@ref)s to the output [`Resource`](@ref)s, subject to the available capacity and
limitation of the [`Resource`](@ref)s given by the limit field.

As opposed to the `RefNetworkNode` in `EnergyModelsBase`, the `LimitedFlexibleInput` node introduces
a `limit` on the fraction a given resource can contribute to the total inflow.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`limit::Dict{<:Resource, <:Real}`** are the limits for each [`Resource`](@ref)s of the total input.
- **`input::Dict{<:Resource, <:Real}`** are the input [`Resource`](@ref)s with conversion
  value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated [`Resource`](@ref)s with
  conversion value `Real`.
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct LimitedFlexibleInput <: NetworkNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    limit::Dict{<:Resource,<:Real}
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function LimitedFlexibleInput(
    id,
    cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    limit::Dict{<:Resource,<:Real},
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
)
    return LimitedFlexibleInput(id, cap, opex_var, opex_fixed, limit, input, output, Data[])
end
limits(n::LimitedFlexibleInput, p::Resource) = n.limit[p]
limits(n::LimitedFlexibleInput) = collect(keys(n.limit))

"""
    Combustion <: NetworkNode

A `Combustion` node.
The `Combustion` is similar to [`LimitedFlexibleInput`](@ref)s but requires energy balances
in the sense that the output `heat_res` captures the lost energy.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`limit::Dict{<:Resource, <:Real}`** are the limits for each [`Resource`](@ref)s of the total input.
- **`heat_res::Resource`** the residual heat resource.
- **`input::Dict{<:Resource, <:Real}`** are the input [`Resource`](@ref)s with conversion
  value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated [`Resource`](@ref)s with
  conversion value `Real`.
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct Combustion <: NetworkNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    limit::Dict{<:Resource,<:Real}
    heat_res::Resource
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function Combustion(
    id,
    cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    limit::Dict{<:Resource,<:Real},
    heat_res::Resource,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
)
    return Combustion(id, cap, opex_var, opex_fixed, limit, heat_res, input, output, Data[])
end
limits(n::Combustion, p::Resource) = n.limit[p]
limits(n::Combustion) = collect(keys(n.limit))
heat_resource(n::Combustion) = n.heat_res
