# [Update your model to the latest versions](@id how_to-update)

`EnergyModelsFlex` is still in a pre-release version.
Hence, there are frequently breaking changes occuring, although we plan to keep backwards compatibility.
This document is designed to provide users with information regarding how they have to adjust their nodes to keep compatibility to the latest changes.

## [Adjustments from 0.3.0](@id how_to-update-03)

The introduction of `PartitionProfile` in *[`TimeStruct` v0.9.12](https://github.com/sintefore/TimeStruct.jl/releases/tag/v0.9.12)* allowed a rewrite of `PeriodDemandSink`:

```julia
# The previous nodal description for a `PeriodDemandSink` was given by:
PeriodDemandSink(
    id::Any,
    period_length::Int,
    period_demand::Array{<:Real},
    cap::TimeProfile,
    penalty::Dict{Symbol,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
    data::Vector{<:ExtensionData} = ExtensionData[],
)

# This translates to the following new version
PeriodDemandSink(
    id,
    cap,
    FixedProfile(period_length),
    PartitionProfile(period_demand),
    penalty,
    input,
    data
)
```
