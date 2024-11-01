"""
    PayAsProducedPPA <: EMB.Source

Written by Jon Vegard in the case study SPS.

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
