""" `UnitCommitmentNode` is an abstract type for unit commitment nodes."""
abstract type UnitCommitmentNode{} <: EMB.NetworkNode end

"""
    MinUpDownTimeNode{} <: UnitCommitmentNode

`MinUpDownTimeNode` is a specialized [`NetworkNode`](@extref EnergyModelsBase
nodes-network_node) type that introduces unit commitment logic including minimum
up and down time constraints.  It is useful for modeling dispatchable power
plants or technologies where operation must adhere to minimum runtime
constraints.

# Fields
- **`id`**: Identifier or name for the node.
- **`cap::TimeProfile`**: The upper bound on installed capacity over time.
  This field constrains the operational capacity and is required.
- **`opex_var::TimeProfile`**: Variable operating expenses per unit of utilized capacity, enforced through the `cap_use` variable.
- **`opex_fixed::TimeProfile`**: Fixed operating expenses applied per installed capacity unit and investment period.
- **`input::Dict{<:Resource,<:Real}`**: Resource definitions with conversion factors for input flows.
- **`output::Dict{<:Resource,<:Real}`**: Resource definitions with conversion factors for output flows.
- **`minUpTime::Real`**: Minimum number of operational periods the unit must remain on after being started.
- **`minDownTime::Real`**: Minimum number of operational periods the unit must remain off after being stopped.
- **`minCapacity::Real`**: Minimum power output when the unit is on.
- **`maxCapacity::Real`**: Maximum power output when the unit is on (usually aligned with `cap`).
- **`data::Vector{<:Data}`**: Optional metadata (e.g., emissions or investment data). This is initialized to an empty array by default.

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

`ActivationCostNode` is a specialized [`NetworkNode`](@extref EnergyModelsBase
nodes-network_node) that introduces unit commitment logic with additional fuel
or resource costs incurred upon startup.  It models technologies that consume
extra input when switching on, such as combustion turbines or thermal boilers.

# Fields
- **`id`**: Identifier or name of the node.
- **`cap::TimeProfile`**: The available operational capacity over time.
- **`opex_var::TimeProfile`**: Variable operating expenses applied per unit of used capacity.
- **`opex_fixed::TimeProfile`**: Fixed operating expenses applied per unit of installed capacity during each investment period.
- **`input::Dict{<:Resource,<:Real}`**: Energy or material inputs with conversion ratios.
- **`output::Dict{<:Resource,<:Real}`**: Energy or material outputs with conversion ratios.
- **`activation_time::Real`**: Duration of activation effect (currently used to inform activation logic in customized formulations).
- **`activation_consumption::Dict{<:Resource,<:Real}`** Additional input resources required when the unit switches on.
- **`data::Vector{<:Data}`**: Optional metadata (e.g., for emissions or investment logic). Defaults to an empty array if not specified.
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
