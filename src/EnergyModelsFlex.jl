"""
The EnergyModelsFlex extension provides a series of technology node types for EMX enabling
energy and process flexibility modeling.
"""
module EnergyModelsFlex

using JuMP
using TimeStruct
using EnergyModelsBase
using EnergyModelsRenewableProducers

const TS = TimeStruct
const EMB = EnergyModelsBase
const EMR = EnergyModelsRenewableProducers

for node_type ∈ ["source", "sink", "network", "storage"]
    include("$node_type/datastructures.jl")
    include("$node_type/model.jl")
    include("$node_type/constraint_functions.jl")
    include("$node_type/checks.jl")
end

#export BatteryStorage
export MinUpDownTimeNode, ActivationCostNode, ElectricBattery, LoadShiftingNode
export PeriodDemandSink, MultipleInputSink
export PayAsProducedPPA, StorageEfficiency, LimitedFlexibleInput, Combustion
export ContinuousMultipleInputSinkStrat, BinaryMultipleInputSinkStrat

end
