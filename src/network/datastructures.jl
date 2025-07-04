"""
    UnitCommitmentNode{} <: EMB.NetworkNode

Abstract type for unit commitment nodes.
"""
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
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per per capacity usage
  through the variable `:cap_use`.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity
  through the variable `:cap_inst`.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`output::Dict{<:Resource,<:Real}`** are the generated [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`minUpTime::Real`** is the minimum number of operational periods the unit must remain on
  after being started.
- **`minDownTime::Real`** is the minimum number of operational periods the unit must remain
  off after being stopped.
- **`minCapacity::Real`** is the minimum power output when the unit is on.
- **`maxCapacity::Real`** is the maximum power output when the unit is on
  (usually aligned with `cap`).
- **`data::Vector{Data}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
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
function MinUpDownTimeNode(
    id,
    cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    minUpTime::Real,
    minDownTime::Real,
    minCapacity::Real,
    maxCapacity::Real,
)
    return MinUpDownTimeNode(
        id,
        cap,
        opex_var,
        opex_fixed,
        input,
        output,
        minUpTime,
        minDownTime,
        minCapacity,
        maxCapacity,
        Data[],
    )
end

"""
    ActivationCostNode{} <: UnitCommitmentNode

`ActivationCostNode` is a specialized [`NetworkNode`](@extref EnergyModelsBase
nodes-network_node) that introduces unit commitment logic with additional fuel
or resource costs incurred upon startup.  It models technologies that consume
extra input when switching on, such as combustion turbines or thermal boilers.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per per capacity usage
  through the variable `:cap_use`.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity
  through the variable `:cap_inst`.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`output::Dict{<:Resource,<:Real}`** are the generated [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`activation_time::Real`**: Duration of activation effect (currently used to inform
  activation logic in customized formulations).
- **`activation_consumption::Dict{<:Resource,<:Real}`** are the additional input resources
  required when the unit switches on with their absolute demand.
- **`data::Vector{Data}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
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
function ActivationCostNode(
    id,
    cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    activation_time::Real,
    activation_consumption::Dict{<:Resource,<:Real},
)
    return ActivationCostNode(
        id,
        cap,
        opex_var,
        opex_fixed,
        input,
        output,
        activation_time,
        activation_consumption,
        Data[],
    )
end

"""
    activation_consumption(n::ActivationCostNode)
    activation_consumption(n::ActivationCostNode, p::Resource)

Returns the demand during activation of `ActivationCostNode` `n` as dictionary or for
input `Resource` `p`. If `p` is not included in the dictionary, it returns a value of 0.
"""
activation_consumption(n::ActivationCostNode) = n.activation_consumption
function activation_consumption(n::ActivationCostNode, p::Resource)
    con_dict = activation_consumption(n)
    return haskey(con_dict, p) ? con_dict[p] : 0
end

"""
    LimitedFlexibleInput <: NetworkNode

A `LimitedFlexibleInput` node.
The `LimitedFlexibleInput` utilizes a linear, time independent conversion rate of the `input`
[`Resource`](@extref EnergyModelsBase.Resource)s to the output
[`Resource`](@extref EnergyModelsBase.Resource)s, subject to the available capacity and
limitation of the [`Resource`](@extref EnergyModelsBase.Resource)s given by the limit field.

As opposed to the `RefNetworkNode` in `EnergyModelsBase`, the `LimitedFlexibleInput` node
introduces a `limit` on the fraction a given resource can contribute to the total inflow.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per per capacity usage
  through the variable `:cap_use`.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity
  through the variable `:cap_inst`.
- **`limit::Dict{<:Resource, <:Real}`** are the limits for each
  [`Resource`](@extref EnergyModelsBase.Resource)s of the total input.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`output::Dict{<:Resource,<:Real}`** are the generated [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`data::Vector{Data}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
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
- **`opex_var::TimeProfile`** is the variable operating expense per per capacity usage
  through the variable `:cap_use`.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity
  through the variable `:cap_inst`.
- **`limit::Dict{<:Resource, <:Real}`** are the limits for each
  [`Resource`](@extref EnergyModelsBase.Resource)s of the total input.
- **`heat_res::Resource`** the residual heat resource.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`output::Dict{<:Resource,<:Real}`** are the generated [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`data::Vector{Data}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
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
