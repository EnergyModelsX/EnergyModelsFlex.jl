"""
    abstract type AbstractPeriodDemandSink <: EMB.Sink

Supertypes for period demand sinks in which the demand must be satisifed within a given period.
"""
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
    struct PeriodDemandSink <: AbstractPeriodDemandSink

A `PeriodDemandSink` is a [`Sink`](@extref EnergyModelsBase.Sink) that has a demand that can
be satisfied any time during a period of defined length. If the chosen time structure has
operational periods of a duration of 1 hour and the  demand should be fulfilled daily,
`period_duration` should be 24. The demand for each day is then set as a time profile in the
`period_demand` field. The `cap` field is the maximum capacity that can be fulfilled in
each operational period.

# Fields
- **`id::Any`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`period_duration::TimeProfile`** is the sum of the durations of the individual
  operational periods within a given demand period. Due to a constructor, it can either be
  specified as number (the same duration in all demand periods), as a vector (varying
  duration of each demand period), or as a time profile (*e.g.*, varying period durations
  due to varying operational time structures). It cannot be specified as `OperationalProfile`.
- **`period_demand::TimeProfile`** is the demand within each of the periods as time profile.
  It cannot be specified as `OperationalProfile`.
- **`penalty::Dict{Symbol,<:TimeProfile}`** are penalties for surplus or deficits. The
  dictionary requires the fields `:surplus` and `:deficit`.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments). The
  field `data` is conditional through usage of a constructor.

!!! note "Changed behavior"
    The field `period_length` was replaced with the field `period_duration` with a
    change in meaning. In addition, the position was changed. This is explained in the
    *[documentation](https://energymodelsx.github.io/EnergyModelsFlex.jl/stable/how-to/update-models/03/PeriodDemandSink)*.
"""
struct PeriodDemandSink <: AbstractPeriodDemandSink
    id::Any
    cap::TimeProfile
    period_duration::TimeProfile
    period_demand::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:ExtensionData}
end
function PeriodDemandSink(
    id,
    cap::TimeProfile,
    period_duration::Union{Number, Vector{<:Number}},
    period_demand::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
    data::Vector{<:ExtensionData},
)
    if isa(period_duration, Number)
        per_dur = FixedProfile(period_duration)
    elseif isa(period_duration, Vector{<:Number})
        per_dur = PartitionProfile(period_duration)
    end
    return PeriodDemandSink(id, cap, per_dur, period_demand, penalty, input, data)
end
function PeriodDemandSink(
    id,
    cap::TimeProfile,
    period_duration::Union{Number, Vector{<:Number}, TimeProfile},
    period_demand::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return PeriodDemandSink(id, cap, period_duration, period_demand, penalty, input, ExtensionData[])
end

"""
    period_duration(n::AbstractPeriodDemandSink)

Returns the demand periods of `AbstractPeriodDemandSink` `n` as `TimeProfile` or in demand
period `t_pd`.
"""
period_duration(n::AbstractPeriodDemandSink) = n.period_duration
period_duration(n::AbstractPeriodDemandSink, t_pd::TS.PeriodPartition) =
    n.period_duration[t_pd]

"""
    periods(n::AbstractPeriodDemandSink, ts::TS.TimeStructure)

Returns the demand periods for a `PeriodDemandSink` `n` for the given time structure.
"""
periods(n::AbstractPeriodDemandSink, ts::TS.TimeStructure) =
    partition_duration(ts, period_duration(n))

"""
    number_of_periods(n::AbstractPeriodDemandSink, ts::TS.TimeStructure)

Returns the number of demand periods for a `PeriodDemandSink` `n` for the given time structure.
"""
number_of_periods(n::AbstractPeriodDemandSink, ts::TS.TimeStructure) =
    length(periods(n, ts))

"""
    period_demand(n::AbstractPeriodDemandSink)
    period_demand(n::AbstractPeriodDemandSink, t_pd::TS.PeriodPartition)

Returns the period demands of `AbstractPeriodDemandSink` `n` as a `TimeProfile` or in
demand period `t_pd`.
"""
period_demand(n::AbstractPeriodDemandSink) = n.period_demand
period_demand(n::AbstractPeriodDemandSink, t_pd::TS.PeriodPartition) =
    n.period_demand[t_pd]

"""
    struct StratPeriodDemandSink <: AbstractPeriodDemandSink

A `StratPeriodDemandSink` is a [`Sink`](@extref EnergyModelsBase.Sink) that has a total
demand that can specified for each strategic period through the field `strat_demand`. In
addition, you can specify multiple demand periods, each with a minimum and maximum fraction
of the total demand that can be satisified within the demand period.

# Fields
- **`id::Any`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`strat_demand::TimeProfile`** is the demand within each strategic period that must be
  satisfied. It **must** be specified as either a `FixedProfile` or `StrategicProfile` as
  it is indexed over strategic periods
- **`period_duration::TimeProfile`** is the sum of the durations of the individual
  operational periods within a given demand period. Due to a constructor, it can either be
  specified as number (the same duration in all demand periods), as a vector (varying
  duration of each demand period), or as a time profile (*e.g.*, varying period durations
  due to varying operational time structures). It cannot be specified as `OperationalProfile`.
- **`period_min::TimeProfile`** is the relative fraction of the strategic demand that must
  be at least satisifed in each demand period.
- **`period_max::TimeProfile`** is the relative fraction of the strategic demand that can at
  most be satisifed in each demand period.
- **`penalty::Dict{Symbol,<:TimeProfile}`** are penalties for surplus or deficits. The
  dictionary requires the fields `:surplus` and `:deficit`. The same penalty is utilized for
  the strategic surplus/deficit and period surplus/deficit.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments). The
  field `data` is conditional through usage of a constructor.
"""
struct StratPeriodDemandSink <: AbstractPeriodDemandSink
    id::Any
    cap::TimeProfile
    strat_demand::TimeProfile
    period_duration::TimeProfile
    period_min::TimeProfile
    period_max::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:ExtensionData}
end
function StratPeriodDemandSink(
    id,
    cap::TimeProfile,
    strat_dem::TimeProfile,
    period_duration::Union{Number, Vector{<:Number}},
    per_min::TimeProfile,
    per_max::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
    data::Vector{<:ExtensionData},
)
    if isa(period_duration, Number)
        per_dur = FixedProfile(period_duration)
    elseif isa(period_duration, Vector{<:Number})
        per_dur = PartitionProfile(period_duration)
    end
    return StratPeriodDemandSink(
        id,
        cap,
        strat_dem,
        per_dur,
        per_min,
        per_max,
        penalty,
        input,
        data,
    )
end
function StratPeriodDemandSink(
    id,
    cap::TimeProfile,
    strat_demand::TimeProfile,
    period_duration::Union{Number, Vector{<:Number}, TimeProfile},
    per_min::TimeProfile,
    per_max::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return StratPeriodDemandSink(
        id,
        cap,
        strat_demand,
        period_duration,
        per_min,
        per_max,
        penalty,
        input,
        ExtensionData[],
    )
end

"""
    strategic_demand(n::StratPeriodDemandSink)
    strategic_demand(n::StratPeriodDemandSink, t_inv::TS.AbstractStrategicPeriod)

Returns the strategic demands of `StratPeriodDemandSink` `n` as a `TimeProfile` or in
strategic period `t_inv`.
"""
strategic_demand(n::StratPeriodDemandSink) = n.strat_demand
strategic_demand(n::StratPeriodDemandSink, t_inv::TS.AbstractStrategicPeriod) =
    n.strat_demand[t_inv]

"""
    period_demand_min(n::StratPeriodDemandSink)
    period_demand_min(n::StratPeriodDemandSink, t_pd::TS.PeriodPartition)

Returns the minimum period demands of `StratPeriodDemandSink` `n` as a `TimeProfile` or
in demand period `t_pd`.
"""
period_demand_min(n::StratPeriodDemandSink) = n.period_min
period_demand_min(n::StratPeriodDemandSink, t_pd::TS.PeriodPartition) =
    n.period_min[t_pd]

"""
    period_demand_max(n::StratPeriodDemandSink)
    period_demand_max(n::StratPeriodDemandSink, t_pd::TS.PeriodPartition)

Returns the minimum period demands of `StratPeriodDemandSink` `n` as a `TimeProfile` or
in demand period `t_pd`.
"""
period_demand_max(n::StratPeriodDemandSink) = n.period_max
period_demand_max(n::StratPeriodDemandSink, t_pd::TS.PeriodPartition) =
    n.period_max[t_pd]

"""
    struct MultipleInputSink <: AbstractMultipleInputSink

A [`Sink`](@extref EnergyModelsBase.Sink) node with multiple inputs for satisfying the demand.

Contrary to a standard sink, it is possible to utilize the individual input resources
independent of each other.

# Fields
- **`id::Any`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the demand.
- **`penalty::Dict{Symbol,<:TimeProfile}`** are penalties for surplus or deficits. The
  dictionary requires the  fields `:surplus` and `:deficit`.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
"""
struct MultipleInputSink <: AbstractMultipleInputSink
    id::Any
    cap::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:ExtensionData}
end
function MultipleInputSink(
    id,
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return MultipleInputSink(id, cap, penalty, input, ExtensionData[])
end

"""
    struct BinaryMultipleInputSinkStrat <: AbstractMultipleInputSinkStrat

A [`Sink`](@extref EnergyModelsBase.Sink) node with multiple inputs for satisfying the demand.

This type of node corresponds to an energy service demand where several different energy
carriers can satisfy the demand, but only one resource at the time (for each strategic period).

# Fields
- **`id::Any`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the demand.
- **`penalty::Dict{Symbol,<:TimeProfile}`** are penalties for surplus or deficits. The
  dictionary requires the  fields `:surplus` and `:deficit`.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.

!!! warning "Investment options"
    It is not possible to utilize investments for a `BinaryMultipleInputSinkStrat` as this
    would introduce bilinear constraints.
"""
struct BinaryMultipleInputSinkStrat <: AbstractMultipleInputSinkStrat
    id::Any
    cap::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:ExtensionData}
end
function BinaryMultipleInputSinkStrat(
    id,
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return BinaryMultipleInputSinkStrat(id, cap, penalty, input, ExtensionData[])
end

"""
    struct ContinuousMultipleInputSinkStrat <: AbstractMultipleInputSinkStrat

A [`Sink`](@extref EnergyModelsBase.Sink) node with multiple inputs for satisfying the demand.

This type of node corresponds to an energy service demand where several different energy
carriers can satisfy the demand after the supplied energy. The fraction of the input resources
are given as a variable to be optimized (for each strategic period).

# Fields
- **`id::Any`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the demand.
- **`penalty::Dict{Symbol,<:TimeProfile}`** are penalties for surplus or deficits. The
  dictionary requires the  fields `:surplus` and `:deficit`.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.

!!! warning "Investment options"
    It is not possible to utilize investments for a `BinaryMultipleInputSinkStrat` as this
    would introduce bilinear constraints.
"""
struct ContinuousMultipleInputSinkStrat <: AbstractMultipleInputSinkStrat
    id::Any
    cap::TimeProfile
    penalty::Dict{Symbol,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:ExtensionData}
end
function ContinuousMultipleInputSinkStrat(
    id,
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return ContinuousMultipleInputSinkStrat(id, cap, penalty, input, ExtensionData[])
end

"""
    struct LoadShiftingNode <: EMB.Sink

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
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`load_shift_times::Vector{<:Int}`** are the indices of the time structure that bulks of loads
  may be shifted from/to.
- **`load_shifts_per_period::Int`** the upper limit of the number of load shifts within the period defined by `load_shift_times_per_period`
  that can be performed for a given period (defined by the number of timeslots that can be shifted - `n_loadshift`).
- **`load_shift_duration::Int`** the number of operational periods in each load shift.
- **`load_shift_magnitude::Real`** the magnitude for each operational period that is load shifted.
- **`load_shift_times_per_period::Int`** the number of timeslots (from the loadshifttimes) that can be shifted.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.
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
    data::Vector{<:ExtensionData}
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
        ExtensionData[],
    )
end
