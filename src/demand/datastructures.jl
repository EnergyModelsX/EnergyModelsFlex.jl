abstract type AbstractPeriodDemandSink <: Sink end

"""
A `PeriodDemandSink` is a sink that has a demand that can be fulfulled any time dyring a
period of defined length. If the timestructure has operational periods of 1 hour, then
the demand should be fulfilled daily, `period_length` should be 24. The field the demand
for each day is then set as an array as the `period_demand` field. The `cap` field is the
maximum capacity that can be fulfilled in each operational period.
"""
struct PeriodDemandSink <: AbstractPeriodDemandSink
    id
    # Number of operational periods in each demand period. E.g. 24 for daily, 168 for
    # weekly, given that the operational period is 1 hour.
    period_length::Int
    # The demand in each period, given as a vector with the same length as the number of
    # periods (e.g. days) in the time structure.
    period_demand::Array{<:Real}
    # Max capacity of the demand in each operational period
    cap::TimeProfile
    penalty::Dict{Symbol, <:TimeProfile}
    input::Dict{<:Resource, <:Real}
    data::Array{Data}
end
function PeriodDemandSink(
    id,
    period_length::Int,
    period_demand::Vector{<:Real},
    cap::TimeProfile,
    penalty::Dict{Symbol, <:TimeProfile},
    input::Dict{<:Resource, <:Real},
)
    PeriodDemandSink(id, period_length, period_demand, cap, penalty, input, Data[])
end

""" Returns the number of periods for a `PeriodDemandSink`. """
number_of_periods(n::AbstractPeriodDemandSink) = length(n.period_demand)
""" Returns the number of periods for a `PeriodDemandSink` given a `TimeStructure`
"""
number_of_periods(n::AbstractPeriodDemandSink, 𝒯::TimeStructure) = Int(length(𝒯) / n.period_length)

""" Returns the index of the period (e.g. day) that a operational period `t` belongs to. """
period_index(n::AbstractPeriodDemandSink, t) = Int(ceil(t.period.op / n.period_length))
