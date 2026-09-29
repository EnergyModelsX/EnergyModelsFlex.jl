# Resources used in the tests
power = ResourceCarrier("Power", 0.0)
aux = ResourceCarrier("Auxiliary", 0.0)
co2 = ResourceEmit("CO₂", 1.0)

function stor_eff_case(;
    input = Dict(power => 0.98, aux => 0.05),
    output = Dict(power => 0.98),
    stor_res = power,
    charge_cap = FixedProfile(2),
    level_cap = FixedProfile(5),
    charge_opex_fixed = FixedProfile(1e3),
    level_opex_fixed = FixedProfile(4e3),
)
    # Declare the resources and the time structure
    𝒫 = [power, aux, co2]
    𝒯 = TwoLevel(2, 2, SimpleTimes(5, 1))

    # Create the nodes
    src_power = RefSource(
        "source_power",
        OperationalProfile([2, 4, 1, 0, 0]),
        StrategicProfile([200, 5]),
        FixedProfile(0),
        Dict(power => 1),
    )
    src_aux = RefSource(
        "source_auxiliary",
        FixedProfile(100),
        FixedProfile(0),
        FixedProfile(0),
        Dict(aux => 1),
    )
    stor = StorageEfficiency{CyclicStrategic}(
        "storage",
        StorCapOpex(charge_cap, FixedProfile(1e-4), charge_opex_fixed),
        StorCapOpex(level_cap, FixedProfile(0), level_opex_fixed),
        stor_res,
        input,
        output,
    )
    snk = RefSink(
        "sink",
        StrategicProfile([1, 2]),
        Dict(:surplus => FixedProfile(1), :deficit => FixedProfile(1e6)),
        Dict(power => 1),
    )
    𝒩 = [src_power, src_aux, stor, snk]

    # Create the links
    ℒ = [
        Direct("source_power-storage", src_power, stor),
        Direct("source_auxiliary-storage", src_aux, stor),
        Direct("source_power-sink", src_power, snk),
        Direct("storage-sink", stor, snk),
    ]

    # Create the EMB case, the modeltype and the JuMP model
    modeltype = OperationalModel(
        Dict(co2 => FixedProfile(100)),
        Dict(co2 => FixedProfile(100)),
        co2,
    )
    case = Case(𝒯, 𝒫, [𝒩, ℒ])
    m = create_model(case, modeltype)
    set_optimizer(m, OPTIMIZER)
    return m, case, modeltype
end


# Test that the fields of a `StorageEfficiency` are correctly checked
# - EMB.check_node(n::StorageEfficiency, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
@testset "StorageEfficiency | Test checks" begin
    # Set the global to true to suppress the error message
    EMB.TEST_ENV = true
    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError stor_eff_case(; charge_cap = FixedProfile(-25))
    @test_throws AssertionError stor_eff_case(; level_cap = FixedProfile(-25))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError stor_eff_case(; charge_opex_fixed = FixedProfile(-100))
    @test_throws AssertionError stor_eff_case(; level_opex_fixed = FixedProfile(-100))

    # Test that a wrong input dictionary is caught by the checks
    @test_throws AssertionError stor_eff_case(; input = Dict(power => -1.0))

    # Test that a wrong output dictionary is caught by the checks
    @test_throws AssertionError stor_eff_case(; output = Dict(power => -1.0))
    @test_throws AssertionError stor_eff_case(; output = Dict(power => 0.98, aux => 0.02))

    # Set the global again to false
    EMB.TEST_ENV = false
end

# Test that the utility functions are working
@testset "StorageEfficiency | Utility functions" begin
    # Create the model
    m, case, modeltype = stor_eff_case()

    # Extract the sets and variables
    stor = get_nodes(case)[3]

    # Test the EMB utility functions
    @test charge(stor) == StorCapOpex(FixedProfile(2), FixedProfile(1e-4), FixedProfile(1e3))
    @test level(stor) == StorCapOpex(FixedProfile(5), FixedProfile(0), FixedProfile(4e3))
    @test storage_resource(stor) == power
    @test inputs(stor) == [power, aux] || inputs(stor) == [aux, power]
    @test inputs(stor, power) == 0.98
    @test inputs(stor, aux) == 0.05
    @test outputs(stor) == [power]
    @test outputs(stor, power) == 0.98
    @test node_data(stor) == ExtensionData[]
end


# Test that the constraint implementation is working correctly
@testset "StorageEfficiency | Constraint implementation" begin
    # Create and optimize the model
    m, case, modeltype = stor_eff_case()
    optimize!(m)

    # Extract the sets and variables
    stor, snk = get_nodes(case)[[3, 4]]
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    snk_deficit = value.(m[:sink_deficit][snk, :])
    stor_lvl = value.(m[:stor_level][stor, :])
    stor_charge = value.(m[:stor_charge_use][stor, :])
    stor_discharge = value.(m[:stor_discharge_use][stor, :])
    stor_in = value.(m[:flow_in][stor, :, :])
    stor_out = value.(m[:flow_out][stor, :, :])

    # Test that the capacity constraints are not violated
    @test all(stor_charge[t] ⪅ capacity(charge(stor), t) for t ∈ 𝒯)

    # Test that the input flows are correctly calculated
    # - EMB.constraints_flow_in(m, n::StorageEfficiency, 𝒯::TimeStructure, ::EnergyModel)
    @test all(stor_charge[t] ≈ stor_in[t, power] * inputs(stor, power) for t ∈ 𝒯)
    @test all(
        stor_charge[t] ≈ stor_in[t, aux] * inputs(stor, power) / inputs(stor, aux)
    for t ∈ 𝒯)
    @test all(stor_in[t, aux] ≈ stor_in[t, power] * inputs(stor, aux) for t ∈ 𝒯)

    # Test that the output flows are correctly calculated
    # - EMB.constraints_flow_out(m, n::StorageEfficiency, 𝒯::TimeStructure, ::EnergyModel)
    @test all(stor_discharge[t] * outputs(stor, power) ≈ stor_out[t, power] for t ∈ 𝒯)

    # Test that there is a deficit in the sink in the second strategic period due to the
    # increased demand and that this deficit incorporates the charging loss
    @test all(snk_deficit[t] ≈ 0 for t ∈ 𝒯ᴵⁿᵛ[1], atol ∈ TEST_ATOL)
    @test sum(snk_deficit[t] for t ∈ 𝒯ᴵⁿᵛ[2]) ≈ 2 * 5 - 5 - 2 * 0.98^2 atol = TEST_ATOL
end
