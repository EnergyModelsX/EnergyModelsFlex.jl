"""
EnergyModelsFlex is a Julia package that extends the
[`EnergyModelsX`](https://github.com/EnergyModelsX) energy system modeling
framework with additional node types that capture different aspects of
flexibility in energy systems.

This package provides a series of technology node types for `EnergyModelsX`
enabling energy and process flexibility modeling.
"""
module EnergyModelsFlex

using JuMP
using TimeStruct
using EnergyModelsBase
using EnergyModelsRenewableProducers

const TS = TimeStruct
const EMB = EnergyModelsBase
const EMR = EnergyModelsRenewableProducers

for node_type ∈ ["source", "sink", "network", "storage", "link"]
    include("$node_type/datastructures.jl")
    include("$node_type/model.jl")
    include("$node_type/constraint_functions.jl")
    include("$node_type/checks.jl")
end

export MinUpDownTimeNode, ActivationCostNode, ElectricBattery, LoadShiftingNode
export PeriodDemandSink, MultipleInputSink
export PayAsProducedPPA, StorageEfficiency, LimitedFlexibleInput, Combustion
export ContinuousMultipleInputSinkStrat, BinaryMultipleInputSinkStrat
export CapacityCostLink, HighTempProdNode, ExcessHeat

end
