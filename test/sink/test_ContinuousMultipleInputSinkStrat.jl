
NG = ResourceCarrier("NG", 0.2)
H2 = ResourceCarrier("H2", 0.0)
CO2 = ResourceEmit("CO2", 1.0)

source_1 = RefSource(
    1,
    StrategicProfile([10, 5]),
    StrategicProfile([5, 10]),
    FixedProfile(0),
    Dict(NG => 1),
)
source_2 = RefSource(
    2,
    FixedProfile(4),
    StrategicProfile([10, 5]),
    FixedProfile(0),
    Dict(H2 => 1),
)

sink = ContinuousMultipleInputSinkStrat(
    3,
    FixedProfile(8),
    Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(100)),
    Dict(NG => 1.2, H2 => 1.1),
)

# Creating and solving the model
𝒫 = [NG, H2, CO2]
𝒯 = TwoLevel(2, 2, SimpleTimes(5, 2))
𝒯ᴵⁿᵛ = strategic_periods(𝒯)
𝒩 = [source_1, source_2, sink]
ℒ = [Direct(13, source_1, sink), Direct(23, source_2, sink)]
model = OperationalModel(
    Dict(CO2 => FixedProfile(100)),
    Dict(CO2 => FixedProfile(100)),
    CO2,
)

case = Dict(:T => 𝒯, :nodes => 𝒩, :links => ℒ, :products => 𝒫)
m = EMB.run_model(case, model, HiGHS.Optimizer)

# Testing the correct source usage
𝒫ⁱⁿ = inputs(sink)
for t_inv ∈ 𝒯ᴵⁿᵛ
    if t_inv.sp == 1
        @test all(value.(m[:flow_out][source_1, t, NG]) > 0 for t ∈ t_inv)
        @test all(value.(m[:flow_out][source_2, t, H2]) == 0 for t ∈ t_inv)
    else
        @test all(value.(m[:flow_out][source_1, t, NG]) > 0 for t ∈ t_inv)
        @test all(value.(m[:flow_out][source_2, t, H2]) > 0 for t ∈ t_inv)
    end
end
@test all(
    sum(value.(m[:flow_in][sink, t, p])/inputs(sink, p) for p ∈ 𝒫ⁱⁿ) ≈
    value.(m[:cap_use][sink, t]) for t ∈ 𝒯, atol ∈ TEST_ATOL
)

# Test that the sum constraint in all investment periods is fulfilled
@test all(
    sum(value.(m[:input_frac_strat][sink, t_inv, p]) for p ∈ 𝒫ⁱⁿ) == 1 for
    t_inv ∈ 𝒯ᴵⁿᵛ
)
