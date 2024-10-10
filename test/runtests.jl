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
    @testset "MinUpDownTimeNode" begin
        include("test_minupdowntimenode.jl")
    end
    @testset "PeriodDemandSink" begin
        include("test_perioddemandsink.jl")
    end
end
