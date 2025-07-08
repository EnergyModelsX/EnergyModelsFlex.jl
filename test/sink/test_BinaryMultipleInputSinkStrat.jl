
NG = ResourceCarrier("NG", 0.2)
H2 = ResourceCarrier("H2", 0.0)
power = ResourceCarrier("Power", 0.0)
CO2 = ResourceEmit("CO2", 1.0)

source_1 = RefSource(
    1,
    FixedProfile(10),
    StrategicProfile([5, 8]),
    FixedProfile(0),
    Dict(NG => 1),
)
source_2 = RefSource(
    2,
    FixedProfile(5),
    StrategicProfile([10, 5]),
    FixedProfile(0),
    Dict(H2 => 1),
)
source_3 = RefSource(
    3,
    FixedProfile(5),
    StrategicProfile([10, 5]),
    FixedProfile(0),
    Dict(power => 1),
)

sink_1 = BinaryMultipleInputSinkStrat(
    4,
    FixedProfile(8),
    Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(10)),
    Dict(NG => 1.2, H2 => 1.1),
)
sink_2 = BinaryMultipleInputSinkStrat(
    5,
    FixedProfile(8),
    Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(10)),
    Dict(NG => 1.2, power => 1.0),
)

# Creating and solving the model
𝒫 = [NG, H2, CO2, power]
𝒯 = TwoLevel(2, 2, SimpleTimes(5, 2))
𝒯ᴵⁿᵛ = strategic_periods(𝒯)

𝒩 = [source_1, source_2, source_3, sink_1, sink_2]
ℒ = [
    Direct(13, source_1, sink_1), Direct(23, source_2, sink_1),
    Direct(13, source_1, sink_2), Direct(23, source_3, sink_2),
]
model = OperationalModel(
    Dict(CO2 => FixedProfile(100)),
    Dict(CO2 => FixedProfile(100)),
    CO2,
)
case = Dict(:T => 𝒯, :nodes => 𝒩, :links => ℒ, :products => 𝒫)
m = EMB.run_model(case, model, OPTIMIZER)

# Test the correct variable definition and that the variable is a sparse axis array
for var ∈ [:input_frac_strat, :sink_surplus_p, :sink_deficit_p]
    if var == :input_frac_strat
        t = first(𝒯ᴵⁿᵛ)
    else
        t = first(𝒯)
    end
    @test haskey(m[var][sink_1, t, :], NG)
    @test haskey(m[var][sink_1, t, :], H2)
    @test !haskey(m[var][sink_1, t, :], power)
    @test haskey(m[var][sink_2, t, :], NG)
    @test !haskey(m[var][sink_2, t, :], H2)
    @test haskey(m[var][sink_2, t, :], power)
end

# Testing the correct source usage
𝒫ⁱⁿ = inputs(sink_1)
for t_inv ∈ 𝒯ᴵⁿᵛ
    if t_inv.sp == 1
        @test all(value.(m[:flow_out][source_1, t, NG]) > 0 for t ∈ t_inv)
        @test all(value.(m[:flow_out][source_2, t, H2]) == 0 for t ∈ t_inv)
    else
        @test all(value.(m[:flow_out][source_1, t, NG]) == 0 for t ∈ t_inv)
        @test all(value.(m[:flow_out][source_2, t, H2]) > 0 for t ∈ t_inv)
        @test all(value.(m[:sink_deficit][sink_1, t]) > 0 for t ∈ t_inv)
    end
end
@test all(
    sum(value.(m[:flow_in][sink_1, t, p])/inputs(sink_1, p) for p ∈ 𝒫ⁱⁿ) ≈
    value.(m[:cap_use][sink_1, t]) for t ∈ 𝒯, atol ∈ TEST_ATOL
)

# Test that the binary declaration is working
@test all(
    is_binary(m[:input_frac_strat][sink_1, t_inv, p]) for
    t_inv ∈ 𝒯ᴵⁿᵛ, p ∈ 𝒫ⁱⁿ
)

# Test that the sum constraint in all investment periods is fulfilled
@test all(
    sum(value.(m[:input_frac_strat][sink_1, t_inv, p]) for p ∈ 𝒫ⁱⁿ) == 1 for
    t_inv ∈ 𝒯ᴵⁿᵛ
)
