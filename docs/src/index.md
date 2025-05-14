# EnergyModelsFlex

```@docs
EnergyModelsFlex
```

## What is flexibility in energy systems?

Flexibility in energy systems refers to the ability to adapt generation, consumption, or conversion in response to variability in supply and demand—especially with growing shares of intermittent renewable sources like wind and solar. Flexibility can be implemented in several forms:

 - **Temporal flexibility:** shifting electricity consumption or production across time (e.g. demand response, storage).

 - **Input flexibility:** using different fuels or resources to meet the same service (e.g. fuel-switching boilers).

 - **Operational flexibility:** including start-up/shutdown constraints, minimum running times, or part-load efficiency.

 - **Network and conversion flexibility:** controlling flows across interconnected energy carriers (e.g. heat and electricity).

**`EnergyModelsFlex`** introduces custom nodes that allow modelers to represent these dimensions of flexibility in a structured, modular way.

---

## Implemented flexible node types

This package provides several node types that extend the EnergyModelsX interface:

### Source Nodes

- [`PayAsProducedPPA`](@ref nodes-payasproducedppa): A source with contractual constraints typical for renewable power purchase agreements (PPA).

### Sink Nodes

- [`PeriodDemandSink`](@ref nodes-perioddemandsink): Allows demand to be met flexibly within a defined time period (e.g. daily energy use).
- [`LoadShiftingNode`](@ref nodes-loadshiftingnode): Supports discrete batch shifting across time within allowed work shifts.
- [`MultipleInputSink`](@ref nodes-multipleinputsink): Enables flexible use of multiple input resources to meet demand.
- [`BinaryMultipleInputSinkStrat`](@ref nodes-mul_in_sink_strat): Input choice from multiple fuels using binary (exclusive) decisions per period.
- [`ContinuousMultipleInputSinkStrat`](@ref nodes-mul_in_sink_strat): Allows input blending over strategic periods using continuous fractions.

### Network Nodes

- [`MinUpDownTimeNode`](@ref nodes-minupdowntimenode): Models units with startup/shutdown constraints and minimum uptime/downtime.
- [`ActivationCostNode`](@ref nodes-activationcostnode): Includes additional input costs on startup (e.g. ignition fuel).
- [`LimitedFlexibleInput`](@ref nodes-limitedflexibleinput): Restricts the share of individual input fuels in a multi-input conversion process.
- [`Combustion`](@ref nodes-combustion): Enforces full energy balances including residual heat losses.

### Storage

- [`StorageEfficiency`](@ref): Allows modeling of time- and state-dependent storage efficiency losses.

---

## Manual outline

```@contents
Pages = [
    "manual/quick-start.md",
    "examples/flexible_demand.md",
    "manual/NEWS.md",
]
Depth = 1
```

## How to guides

```@contents
Pages = [
    "how-to/contribute.md",
    "how-to/utilize.md",
]
Depth = 1
```

## Library outline

```@contents
Pages = [
    "library/public.md",
    "library/internals/types.md",
    "library/internals/methods-fields.md",
    "library/internals/methods-EMB.md",
]
Depth = 1
```
