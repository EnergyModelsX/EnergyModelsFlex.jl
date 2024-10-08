using EnergyModelsFlex
using EnergyModelsBase
using HiGHS
using JuMP
using Test
using TimeStruct

const EMB = EnergyModelsBase
const TS = TimeStruct

const TEST_ATOL = 1e-6

@testset "EnergyModelsFlex" begin
    include("test_minupdowntimenode.jl")
end
