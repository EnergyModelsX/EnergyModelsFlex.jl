"""
    ElectricBattery{T} <: EMB.Storage{T}

Electric battery node
- c_rate:
- coloumbic_eff:
"""
struct ElectricBattery{T} <: EMB.Storage{T}
    id::Any
    charge::EMB.AbstractStorageParameters
    level::EMB.UnionCapacity
    c_rate::Real #
    coloumbic_eff::Real  # efficency, typically 0.98
    stor_res::Resource
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
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
    BatteryStorage{T} <: EMB.Storage{T}

A battery storage including reserve capabilities.

Includes addional types for reserves up and down.
"""

struct BatteryStorage{T} <: EMB.Storage{T}
    id::Any
    charge_cap::TimeProfile
    discharge_cap::TimeProfile
    stor_cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    charge_eff::Real
    discharge_eff::Real
    stor_res::T
    reserve_res_up::Vector{<:Resource}
    reserve_res_down::Vector{<:Resource}
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function BatteryStorage(
    id,
    charge_cap::TimeProfile,
    discharge_cap::TimeProfile,
    stor_cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    charge_eff::Real,
    discharge_eff::Real,
    stor_res::T,
    reserve_res_up::Vector{<:Resource},
    reserve_res_down::Vector{<:Resource},
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
) where {T<:Resource}
    return BatteryStorage(
        id,
        charge_cap,
        discharge_cap,
        stor_cap,
        opex_var,
        opex_fixed,
        charge_eff,
        discharge_eff,
        stor_res,
        reserve_res_up,
        reserve_res_down,
        input,
        output,
        Data[],
    )
end

has_emissions(n::RefStorage{<:ResourceEmit}) = false

capacity(n::BatteryStorage) =
    (level = n.stor_cap, charge = n.charge_cap, discharge = n.discharge_cap)

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
