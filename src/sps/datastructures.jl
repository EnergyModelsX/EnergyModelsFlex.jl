# Written by Jon Vegard in the case study SPS.

"""
    StorageEfficiency{T} <: EMB.Storage{T}

A StorageEfficiency node which enables storage efficiency control compared to RefStorage{T}.

It is designed as a parametric type through the type parameter `T` to differentiate between
different cyclic behaviours. Note that the parameter `T` is only used for dispatching, but
does not carry any other information. Hence, it is simple to fast switch between different
[`StorageBehavior`](@ref)s.

The current implemented cyclic behaviours are [`CyclicRepresentative`](@ref),
[`CyclicStrategic`](@ref), and [`AccumulatingEmissions`](@ref).

# Fields
- **`id`** is the name/identifier of the node.
- **`charge::AbstractStorageParameters`** are the charging parameters of the `Storage` node.
  Depending on the chosen type, the charge parameters can include variable OPEX, fixed OPEX,
  and/or a capacity.
- **`level::AbstractStorageParameters`** are the level parameters of the `Storage` node.
  Depending on the chosen type, the charge parameters can include variable OPEX and/or fixed OPEX.
- **`stor_res::Resource`** is the stored [`Resource`](@ref).
- **`input::Dict{<:Resource, <:Real}`** are the input [`Resource`](@ref)s with conversion
  value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated [`Resource`](@ref)s with conversion
  value `Real`. Only relevant for linking and the stored [`Resource`](@ref) as the output
  value is not utilized in the calculations.
- **`data::Vector{<:Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct StorageEfficiency{T} <: EMB.Storage{T}
    id::Any
    charge::EMB.UnionCapacity
    level::EMB.UnionCapacity
    stor_res::Resource
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function StorageEfficiency{T}(
    id,
    charge::EMB.UnionCapacity,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
) where {T<:EMB.StorageBehavior}
    return StorageEfficiency{T}(id, charge, level, stor_res, input, output, Data[])
end

"""
    PayAsProducedPPA <: EMB.Source

A pay-as-produced ppa energy source. It extends the existing `PayAsProducedPPA` node through
including a constraint on the opex_var such that curtailed energy is also included in the opex.

# Fields
- **`id`** is the name/identifyer of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`profile::TimeProfile`** is the power production in each operational period as a ratio
  of the installed capacity at that time.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`output::Dict{Resource, Real}`** are the generated `Resource`s, normally Power.
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct PayAsProducedPPA <: Source
    id::Any
    cap::TimeProfile
    profile::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end
function PayAsProducedPPA(
    id::Any,
    cap::TimeProfile,
    profile::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    output::Dict{<:Resource,<:Real},
)
    return PayAsProducedPPA(id, cap, profile, opex_var, opex_fixed, output, Data[])
end

"""
    profile(n::PayAsProducedPPA)
    profile(n::PayAsProducedPPA, t)

Returns the profile of a node `n` of type `PayAsProducedPPA` either as `TimeProfile` or at
operational period `t`.
"""
profile(n::PayAsProducedPPA) = n.profile
profile(n::PayAsProducedPPA, t) = n.profile[t]

"""
    Combustion <: NetworkNode

A `Combustion` node.
The `Combustion` utilizes a linear, time independent conversion rate of the `input`
[`Resource`](@ref)s to the output [`Resource`](@ref)s, subject to the available capacity.
The capacity is hereby normalized to a conversion value of 1 in the fields `input` and
`output`.

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
struct Combustion <: NetworkNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    limit::Dict{<:Resource,<:Real}
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
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
)
    return Combustion(id, cap, opex_var, opex_fixed, limit, input, output, Data[])
end
limits(n::Combustion, p::Resource) = n.limit[p]
limits(n::Combustion) = collect(keys(n.limit))
