using EnergyModelsBase
using EnergyModelsRenewableProducers
using EnergyModelsFlex
using HiGHS
using JuMP
using Test
using TimeStruct
using Logging

const EMB = EnergyModelsBase
const EMF = EnergyModelsFlex
const EMR = EnergyModelsRenewableProducers
const TS = TimeStruct

const TEST_ATOL = 1e-6
const OPTIMIZER = optimizer_with_attributes(
    HiGHS.Optimizer,
    MOI.Silent() => true,
)

test_dir = joinpath(pkgdir(EMF), "test")

"""
    run_node_test(node_supertype::String, node_type::String)

Run the tests for a specific node type.
"""
function run_node_test(node_supertype::String, node_type::String)
    @testset "$node_type" begin
        include(joinpath(test_dir, "$node_supertype/test_$(node_type).jl"))
    end
end

include(joinpath(test_dir, "utils.jl"))

@testset "Flex" begin
    # Run all Aqua tests
    include(joinpath(test_dir, "Aqua.jl"))

    # Check if there is need for formatting
    include(joinpath(test_dir, "JuliaFormatter.jl"))

    @testset "Flex | links" begin
        for link_type ∈ ["CapacityCostLink"]
            run_node_test("link", link_type)
        end
    end

    @testset "Flex | Sink nodes" begin
        for node_type ∈
            [
            "MultipleInputSink",
            "BinaryMultipleInputSinkStrat",
            "ContinuousMultipleInputSinkStrat",
            "PeriodDemandSink",
            "LoadShiftingNode",
        ]
            run_node_test("sink", node_type)
        end
    end

    @testset "Flex | Source nodes" begin
        for node_type ∈ ["PayAsProducedPPA"]
            run_node_test("source", node_type)
        end
    end

    @testset "Flex | Network nodes" begin
        for node_type ∈ [
            "LimitedFlexibleInput",
            "MinUpDownTimeNode",
            "Combustion",
            "ActivationCostNode",
        ]
            run_node_test("network", node_type)
        end
    end

    @testset "Flex | Storage nodes" begin
        for node_type ∈ ["StorageEfficiency"]
            run_node_test("storage", node_type)
        end
    end
end
