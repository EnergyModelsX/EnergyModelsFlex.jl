module EnergyModelsFlex

using JuMP
using TimeStruct
using EnergyModelsBase

const TS = TimeStruct
const EMB = EnergyModelsBase


# BatteryStorage
# TODO needs to be updated to EnergyModelsBase@v0.8.0.
# include("battery_storage/datastructures.jl")
# include("battery_storage/model.jl")
# include("battery_storage/constraint_functions.jl")
# include("battery_storage/checks.jl")

# export BatteryStorage

include("SEAC/datastructures.jl")
include("SEAC/model.jl")
include("SEAC/constraint_functions.jl")
include("SEAC/checks.jl")

export MinUpDownTimeNode, ActivationCostNode, ElectricBattery, LoadShiftingNode

include("demand/datastructures.jl")
include("demand/model.jl")
include("demand/constraint_functions.jl")

export PeriodDemandSink

include("sps/datastructures.jl")
include("sps/constraint_functions.jl")
include("sps/checks.jl")

export PayAsProducedPPA, StorageEfficiency, Combustion

end
