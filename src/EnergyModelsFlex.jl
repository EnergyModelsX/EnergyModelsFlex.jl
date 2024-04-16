module EnergyModelsFlex

using JuMP
using TimeStruct
using EnergyModelsBase
using EnergyModelsSDDP

const TS = TimeStruct
const EMB = EnergyModelsBase


# General functions
include("battery_storage/datastructures.jl")
include("battery_storage/model.jl")
include("battery_storage/model_sddp.jl")
include("battery_storage/constraint_functions.jl")
include("battery_storage/constraint_functions_sddp.jl")
include("battery_storage/checks.jl")


export BatteryStorage

end
