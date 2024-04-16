module EnergyModelsFlex

using JuMP
using TimeStruct
using EnergyModelsBase
using EnergyModelsSDDP

const TS = TimeStruct
const EMB = EnergyModelsBase


# General functions
include("datastructures.jl")
include("model.jl")
include("model_sddp.jl")
include("constraint_functions.jl")
include("constraint_functions_sddp.jl")
include("checks.jl")


export BatteryStorage

end
