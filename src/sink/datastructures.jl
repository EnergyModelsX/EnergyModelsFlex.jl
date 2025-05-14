""" `AbstractPeriodDemandSink` as supertypes for period demand sinks."""
abstract type AbstractPeriodDemandSink <: EMB.Sink end

"""
    abstract type AbstractMultipleInputSink <: Sink

Abstract supertype for `Sink` nodes in which the demand can be satisfied by multiple
resources.
"""
abstract type AbstractMultipleInputSink <: Sink end

"""
    abstract type AbstractMultipleInputSinkStrat <: AbstractMultipleInputSink

Abstract supertype for [`AbstractMultipleInputSink`](@ref) nodes in which the ratio between
the different resources must be constant within a strategic period.
"""
abstract type AbstractMultipleInputSinkStrat <: AbstractMultipleInputSink end

"""
    PeriodDemandSink <: AbstractPeriodDemandSink

A `PeriodDemandSink` is a sink that has a demand that can be fulfulled any time dyring a
period of defined length. If the timestructure has operational periods of 1 hour, then
the demand should be fulfilled daily, `period_length` should be 24. The field the demand
for each day is then set as an array as the `period_demand` field. The `cap` field is the
maximum capacity that can be fulfilled in each operational period.
"""
struct PeriodDemandSink <: AbstractPeriodDemandSink
    id::Any
    # Number of operational periods in each demand period. E.g. 24 for daily, 168 for
    # weekly, given that the operational period is 1 hour.
    period_length::Int
    # The demand in each period, given as a vector with the same length as the number of
    # periods (e.g. days) in the time structure.
    period_demand::Array{<:Real}
    # Max capacity of the demand in each operational period
    cap::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Array{Data}
end
function PeriodDemandSink(
    id,
    period_length::Int,
    period_demand::Vector{<:Real},
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    PeriodDemandSink(id, period_length, period_demand, cap, penalty, input, Data[])
end

""" Returns the number of periods for a `PeriodDemandSink`. """
number_of_periods(n::AbstractPeriodDemandSink) = length(n.period_demand)
""" Returns the number of periods for a `PeriodDemandSink` given a `TimeStructure`
"""
number_of_periods(n::AbstractPeriodDemandSink, 𝒯::TimeStructure) =
    Int(length(𝒯) / n.period_length)

""" Returns the index of the period (e.g. day) that a operational period `t` belongs to. """
period_index(n::AbstractPeriodDemandSink, t) = Int(ceil(t.period.op / n.period_length))

"""
    MultipleInputSink <: Sink

A `Sink` node with multiple inputs for satsifying the demand.

This type of node corresponds to an energy service demand where several different energy
carriers can satisfy the demand after the supplied energy.
Process emissions can be included, but if the field is not added, then no
process emissions are assumed through the usage of a constructor.
Energy use related CO2 emissions are however included.

# Fields
- **`id::Any`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the Demand.
- **`penalty::Dict{Symbol, <:TimeProfile}`** are penalties for surplus or deficits.
  Requires the fields `:surplus` and `:deficit`.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`data::Vector{<:Data}`** is the additional data (e.g. for investments).
"""
struct MultipleInputSink <: AbstractMultipleInputSink
    id::Any
    cap::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function MultipleInputSink(
    id,
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return MultipleInputSink(id, cap, penalty, input, Data[])
end

"""
    struct BinaryMultipleInputSinkStrat <: AbstractMultipleInputSinkStrat

A `Sink` node with multiple inputs for satisfying the demand.

This type of node corresponds to an energy service demand where several different energy
carriers can satisfy the demand, but only one resource at the time (for each strategic period).

# Fields
- **`id::Any`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the Demand.
- **`penalty::Dict{Symbol, <:TimeProfile}`** are penalties for surplus or deficits.
  Requires the fields `:surplus` and `:deficit`.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`data::Vector{<:Data}`** is the additional data (*e.g.*,for investments).
"""
struct BinaryMultipleInputSinkStrat <: AbstractMultipleInputSinkStrat
    id::Any
    cap::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function BinaryMultipleInputSinkStrat(
    id,
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return BinaryMultipleInputSinkStrat(id, cap, penalty, input, Data[])
end

"""
    struct ContinuousMultipleInputSinkStrat <: AbstractMultipleInputSinkStrat

A `Sink` node with multiple inputs for satisfying the demand.

This type of node corresponds to an energy service demand where several different energy
carriers can satisfy the demand after the supplied energy. The fraction of the input resources
are given as a variable to be optimized (for each strategic period).

# Fields
- **`id::Any`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the Demand.
- **`penalty::Dict{Symbol, <:TimeProfile}`** are penalties for surplus or deficits.
  Requires the fields `:surplus` and `:deficit`.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`data::Vector{<:Data}`** is the additional data (*e.g.*,for investments).
"""
struct ContinuousMultipleInputSinkStrat <: AbstractMultipleInputSinkStrat
    id::Any
    cap::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function ContinuousMultipleInputSinkStrat(
    id,
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return ContinuousMultipleInputSinkStrat(id, cap, penalty, input, Data[])
end

"""
    LoadShiftingNode <: EMB.Sink

A `Sink` node where the demand can be altered by load shifting. The load
shifting is based on the assumption that the production happens in discrete
batches. A representative batch is defined with a magnitude and a duration. A
load shift will in this case mean subtracting the consumption of a representative
batch from the original consumption at one time slot and adding it on another
timeslot. The node is furthermore build for a case where the working shifts
dictates when the batches may be initiated. Thus the timesteps where such a
batch is allowed to be added/subtracted is defined by the `load_shift_times` field.
The `load_shift_times` is further grouped together in groups of
`load_shift_times_per_period`, for which the representative batches can only be
shifted within this group.

!!! warning
    The node uses indexing of the time steps and is as of now not made to handle
    timesteps of different durations.

# Fields
- **`id::Any`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the original Demand (before load shifting).
- **`penalty::Dict{Symbol, <:TimeProfile}`** (not used) are penalties for surplus or deficits.
  Requires the fields `:surplus` and `:deficit`.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`load_shift_times::Vector{<:Int}`** are the indices of the time structure that bulks of loads
  may be shifted from/to.
- **`load_shifts_per_period::Int`** the upper limit of the number of load shifts within the period defined by `load_shift_times_per_period`
  that can be performed for a given period (defined by the number of timeslots that can be shifted - `n_loadshift`).
- **`load_shift_duration::Int`** the number of operational periods in each load shift.
- **`load_shift_magnitude::Real`** the magnitude for each operational period that is load shifted.
- **`load_shift_times_per_period::Int`** the number of timeslots (from the loadshifttimes) that can be shifted.
- **`data::Vector{<:Data}`** is the additional data (e.g. for investments).
"""
struct LoadShiftingNode <: EMB.Sink
    id::Any
    cap::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    load_shift_times::Vector{<:Int}
    load_shifts_per_period::Int
    load_shift_duration::Int
    load_shift_magnitude::Real
    load_shift_times_per_period::Int
    data::Vector{Data}
end
function LoadShiftingNode(
    id::Any,
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
    load_shift_times::Vector{<:Int},
    load_shifts_per_period::Int,
    load_shift_duration::Int,
    load_shift_magnitude::Real,
    load_shift_times_per_period::Int,
)
    return LoadShiftingNode(
        id,
        cap,
        penalty,
        input,
        load_shift_times,
        load_shifts_per_period,
        load_shift_duration,
        load_shift_magnitude,
        load_shift_times_per_period,
        Data[],
    )
end
