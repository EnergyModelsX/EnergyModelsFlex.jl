# [Nodes](@id lib-pub-nodes)

## Index

```@index
Pages = ["public.md"]
```

## [Sink `Node` types](@id lib-pub-sink-node)

The following sink node types are implemented in the `EnergyModelsFlex`.

```@docs
PeriodDemandSink
MultipleInputSink
BinaryMultipleInputSinkStrat
ContinuousMultipleInputSinkStrat
LoadShiftingNode
```

## [Source `Node` types](@id lib-pub-source-node)

The following source node type is implemented in the `EnergyModelsFlex`.

```@docs
PayAsProducedPPA
InflexibleSource
```

## [Network `Node` types](@id lib-pub-network-node)

The following network node types are implemented in the `EnergyModelsFlex`.

```@docs
MinUpDownTimeNode
ActivationCostNode
LimitedFlexibleInput
Combustion
FlexibleOutput
```

## [Storage `Node` types](@id lib-pub-storage-node)

The following storage node types are implemented in the `EnergyModelsFlex`.

```@docs
ElectricBattery
StorageEfficiency
```

## [`Link` types](@id lib-pub-link)

The following link types are implemented in the `EnergyModelsFlex`.

```@docs
CapacityCostLink
```