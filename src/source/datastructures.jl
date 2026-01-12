"""
    PayAsProducedPPA <: AbstractNonDisRES

A pay-as-produced ppa energy source. It extends the existing `AbstractNonDisRES` node through
including a constraint on the opex_var such that curtailed energy is also included in the opex.

# Fields
- **`id`** is the name/identifyer of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`profile::TimeProfile`** is the power production in each operational period as a ratio
  of the installed capacity at that time.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`output::Dict{Resource, Real}`** are the generated `Resource`s, normally Power.
- **`data::Vector{Data}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct PayAsProducedPPA <: AbstractNonDisRES
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
    struct InflexibleSource <: EMB.Source

An inflexible [`Source`](@extref EnergyModelsBase.Source) node with fixed capacity.
The inflexible [`Source`](@extref EnergyModelsBase.Source) node represents a source with a 
fixed capacity usage.
Note, that if you include investments, you can only use `cap` as `TimeProfile` a 
`FixedProfile` or `StrategicProfile`.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per per capacity usage
  through the variable `:cap_use`.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity
  through the variable `:cap_inst`.
- **`output::Dict{<:Resource,<:Real}`** are the generated 
  [`Resource`](@extref EnergyModelsBase.Resource)s with conversion value `Real`.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
"""
struct InflexibleSource <: EMB.Source
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    output::Dict{<:Resource,<:Real}
    data::Vector{<:ExtensionData}
end
function InflexibleSource(
    id::Any,
    cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    output::Dict{<:Resource,<:Real},
)
    return InflexibleSource(id, cap, opex_var, opex_fixed, output, ExtensionData[])
end
