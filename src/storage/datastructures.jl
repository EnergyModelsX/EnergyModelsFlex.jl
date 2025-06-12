"""
    ElectricBattery <: EMB.Storage

Electric battery node
- c_rate:
- coloumbic_eff:
"""
struct ElectricBattery{T<:EMB.StorageBehavior} <: EMB.Storage{T}
    id::Any
    charge::EMB.AbstractStorageParameters
    level::EMB.UnionCapacity
    c_rate::Real #
    coloumbic_eff::Real  # efficency, typically 0.98
    stor_res::Resource
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}

    function ElectricBattery{T}(
        id,
        charge::EMB.AbstractStorageParameters,
        level::EMB.UnionCapacity,
        c_rate::Real, #
        coloumbic_eff::Real, # efficency, typically 0.98
        stor_res::Resource,
        input::Dict{<:Resource,<:Real},
        output::Dict{<:Resource,<:Real},
        data::Vector{<:Data}) where {T<:EMB.StorageBehavior}
        @warn "Depcrecation note: the development of ElectricBattery node is " *
              "discontinued, and the node will be removed in the next release v0.3.0."
        new{T}(id, charge, level, c_rate, coloumbic_eff, stor_res, input, output, data)
    end
end
function ElectricBattery{T}(
    id,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    c_rate::Real, #
    coloumbic_eff::Real, # efficency, typically 0.98
    stor_res::Resource,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
) where {T<:EMB.StorageBehavior}
    return ElectricBattery{T}(
        id,
        charge,
        level,
        c_rate,
        coloumbic_eff,
        stor_res,
        input,
        output,
        Data[],
    )
end

"""
    StorageEfficiency{T} <: EMB.Storage{T}

A StorageEfficiency node which enables storage efficiency control compared to RefStorage{T}.

It is designed as a parametric type through the type parameter `T` to differentiate between
different cyclic behaviours. Note that the parameter `T` is only used for dispatching, but
does not carry any other information. Hence, it is simple to fast switch between different
[`StorageBehavior`](@extref EnergyModelsBase.StorageBehavior)s.

The current implemented cyclic behaviours are [`CyclicRepresentative`](@extref
EnergyModelsBase.CyclicRepresentative) and [`CyclicStrategic`](@extref
EnergyModelsBase.CyclicStrategic).

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
