
"""
Unit commitment nodes
"""
abstract type UnitCommitmentNode{} <: EMB.NetworkNode end
struct MinUpDownTimeNode{} <: UnitCommitmentNode
    id
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{Resource, Real}
    output::Dict{Resource, Real}
    minUpTime::Real #number of operational periodes
    minDownTime::Real  #number of operational periodes
    minCapacity::Real
    maxCapacity::Real
    data::Array{Data}
end
struct ActivationCostNode{} <: UnitCommitmentNode
    id
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{Resource, Real}
    output::Dict{Resource, Real}
    activation_time::Real
    activation_consumption::Dict{Resource, Real}
    data::Array{Data}
end

"""
Electric battery node
- c_rate:
- coloumbic_eff:
"""
struct ElectricBattery{T} <: EMB.Storage{T}
    id
    charge::EMB.AbstractStorageParameters
    level::EMB.UnionCapacity
    c_rate::Real #
    coloumbic_eff::Real  # efficency, typically 0.98
    stor_res::Resource
    input::Dict{<:Resource, <:Real}
    output::Dict{<:Resource, <:Real}
    data::Vector{<:Data}
end

struct LoadShiftingNode <: EMB.Sink
    id
    cap::TimeProfile
    penalty::Dict{Symbol, <:TimeProfile}
    input::Dict{<:Resource, <:Real}
    loadshifttimes::Vector{<:Real}
    load_shifts_per_periode::Real
    load_shift_duration::Real # in number
    load_shift_magnitude::Real
    n_loadshift::Real
    data::Vector{Data}
end
