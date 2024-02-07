"""
This file can be used for introducing new `types` that are required in the case study.
If you are only using the standard `types`, then this file can remain empty or be removed.
"""

""" A battery storage including reserve capabilities.

Includes addional types for reserves up and down.
"""

struct BatteryStorage{T<:Resource} <: EMB.Storage
    id
    charge_cap::TimeProfile
    discharge_cap::TimeProfile
    stor_cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    stor_res::T
    input::Dict{<:Resource, <:Real}
    output::Dict{<:Resource, <:Real}
    data::Vector{<:Data}
end
function BatteryStorage(
    id,
    charge_cap::TimeProfile,
    discharge_cap::TimeProfile,
    stor_cap::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    stor_res::T,
    input::Dict{<:Resource, <:Real},
    output::Dict{<:Resource, <:Real},
) where {T<:Resource}
    return BatteryStorage(
        id,
        charge_cap,
        discharge_cap,
        stor_cap,
        opex_var,
        opex_fixed,
        stor_res,
        input,
        output,
        Data[],
    )
end

has_emissions(n::RefStorage{<:ResourceEmit}) = false

capacity(n::BatteryStorage) = (level=n.stor_cap, charge=n.charge_cap, discharge=n.discharge_cap)
