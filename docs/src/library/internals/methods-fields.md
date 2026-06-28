
# [Methods - Accessing fields](@id lib-int-met_field)

## [Index](@id lib-int-met_field-idx)

```@index
Pages = ["methods-fields.md"]
```

## [`PeriodDemandSink` types](@id lib-int-met_field-PeriodDemandSink)

```@docs
EMF.period_demand
EMF.period_duration(n::EMF.AbstractPeriodDemandSink)
EMF.periods(n::EMF.AbstractPeriodDemandSink, ts::TS.TimeStructure)
EMF.number_of_periods
```

## [`ActivationCostNode` types](@id lib-int-met_field-ActivationCostNode)

```@docs
EMF.activation_consumption
```

## [`CapacityCostLink` types](@id lib-int-met_field-CapacityCostLink)

```@docs
EMF.cap_price
EMF.period_duration(l::CapacityCostLink)
EMF.periods(l::CapacityCostLink, ts::TS.TimeStructure)
EMF.cap_resource
```

## [`Combustion` types](@id lib-int-met_field-Combustion)

```@docs
EMF.limits
EMF.heat_resource
```
