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

!!! note "`period_length` meaning"
    The meaning of `period_length` has changed in addition to its name.
    While it previously defined the number of periods, it defines in the new implementation the total duration of the operational periods that are within a single demand period.
    Consider the following example in which we want three demand periods consisting of two operational periods each:

    ```julia
    # Time structure with 1 strategic period of duration 1 and 6 operational periods of duration 2
    𝒯 = TwoLevel(1, 1, SimpleTimes(6, 2))

    # OLD: Previously, we had to specify
    period_length = 2
    # implying 2 operational periods

    # NEW: Now, we have to specify
    period_length = 4
    # implying a total duration of 4 for the 2 periods
    ```

    THis is reflected by the renaming from `period_length` to `period_duration`.

### [Changed `CapacityCostLink`](@id how_to-update-03-CapacityCostLink)

The introduction of `PartitionProfile` in *[`TimeStruct` v0.9.12](https://github.com/sintefore/TimeStruct.jl/releases/tag/v0.9.12)* allowed a rewrite of `CapacityCostLink` which changed the model behavior:

The field `cap_price_periods` was renamed to `cap_period_duration` and its meaning was changed when moving from 0.3 to 0.4.
The reason for this change is to make the link behavior less dependent on the operational resolution.
The following updated must hence be performed as it is not possible to create respective constructor methods:

1. When specifying a number, the previous meaning of the number of operational periods was changed to the sum of the durations of the operational periods.
   The following change is hence required if you have operational durations differing from `1`:

   ```julia
   # time structure
   ts = TwoLevel(2, 1, SimpleTimes(10, 2); op_per_strat=8760.0)

   # old behavior, corresponding to 5 periods
   cap_price_periods = 5

   # new behavior, corresponding to periods whose duration sums to at least 4
   cap_period_duration = 4
   ```

   Both cases create five price periods with a duration of `4`, but instead of specifying the number of periods periods, we now define the duration of each price period.

2. When specifying a vector, the previous scaling based on the chosen value of `op_per_strat` was removed as it is in our opinion more straightforward to base it on the actual operational time structure.
   The following change is hence required:

   ```julia
   # time structure
   ts = TwoLevel(2, 1, SimpleTimes(10, 2); op_per_strat=8760.0)

   # old behavior, corresponding to 5 periods of a total duration of duration based on `op_per_strat`
   cap_period_duration = [1752, 1752, 1752, 1752, 1752]

   # new behavior, corresponding to 5 periods of a total duration of 4 based on `SimpleTimes`
   cap_period_duration = [4, 4, 4, 4, 4]
   ```

   With the scaling factor ``8760 / (10 * 2) = 438``, each new value of 4 corresponds to the previously used value of ``4 * 438 = 1752``, *i.e.*, the same five partitions of two time periods each.

!!! note
    Both examples above result in exactly the same behavior.
    They illustrate the different approaches that could and can be used for defining a [`CapacityCostLink`](@ref).
