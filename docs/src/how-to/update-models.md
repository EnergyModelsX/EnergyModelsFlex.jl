# [Update your model to the latest versions](@id how_to-update)

`EnergyModelsFlex` is still in a pre-release version.
Hence, there are frequently breaking changes occuring, although we plan to keep backwards compatibility.
This document is designed to provide users with information regarding how they have to adjust their nodes to keep compatibility to the latest changes.

## [Adjustments from 0.3.0](@id how_to-update-03)

### [Changed `PeriodDemandSink`](@id how_to-update-03-PeriodDemandSink)

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

### [Changed `CapacityCostLink`](@id how_to-update-03-CapacityCostLink)

The introduction of `PartitionProfile` in *[`TimeStruct` v0.9.12](https://github.com/sintefore/TimeStruct.jl/releases/tag/v0.9.12)* allowed a rewrite of `CapacityCostLink` which changed the model behavior:

The meaning of the field `cap_period_duration` was changed when moving from 0.3 to 0.4:

1. When specifying a number, the previous meaning of the number of operational periods was changed to the sum of the durations of the operational periods.
   The reason for this change is to make the link behavior less dependent on the operational resolution.
   The following change is hence required if you have operational durations differing from 1:

   ```julia
   # time structure
   ts = SimpleTimes(10, 2)

   # old behavior, corresponding to 2 periods
   cap_period_duration = 2

   # new behavior, corresponding to periods whocse duration sums to at least 4
   cap_period_duration = 4
   ```

2. When specifying a vector, the previous scaling based on the chosen value of `op_per_strat` was removed as it is in our opinion more straightforward to base it on the actual operational time structure.
   The following change is hence required:

   ```julia
   # time structure
   ts = Twolevel(2, 1, SimpleTimes(10, 2); op_per_strat=8760.0)

   # old behavior, corresponding to 5 periods a 1752 duration based on `op_per_strat`
   cap_period_duration = [1752, 1752, 1752, 1752, 1752]

   # new behavior, corresponding to 5 periods a 4 duration based on `SimpleTimes`
   cap_period_duration = [4, 4, 4, 4, 4]
   ```
