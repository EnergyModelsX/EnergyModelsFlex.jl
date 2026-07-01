## Sinks

function PeriodDemandSink(
    id::Any,
    period_length::Int,
    period_demand::Array{<:Real},
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
    data::Vector{<:ExtensionData} = ExtensionData[],
)
    @warn(
        "The used implementation of a `PeriodDemandSink` will be discontinued in the near " *
        "future. The new implementation uses the approach of `PeriodPartition` with " *
        "a change in the field positions.\n" *
        "In practice, three changes have to be incorporated: \n 1. the capacity is moved to " *
        "the 2ⁿᵈ position, \n 2. `period_length` is renamed `period_duration`, moved to the " *
        "3ʳᵈ position, and can accept as well a `Vector` or `TimeProfile`s as input, and\n" *
        " 3. `period_demand` is moved to the 4ᵗʰ position and requires as input a " *
        "`PartitionProfile` of the previously provided `Vector`.\n" *
        "See the documentation (https://energymodelsx.github.io/EnergyModelsFlex.jl/stable/how-to/update-models/03/PeriodDemandSink) " *
        "on how to update your model to the latest version.",
        maxlog = 1
    )

    return PeriodDemandSink(
        id,
        cap,
        FixedProfile(period_length),
        PartitionProfile(period_demand),
        penalty,
        input,
        data
    )
end
