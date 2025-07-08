
Power = ResourceCarrier("Power", 0.0)
CO2 = ResourceEmit("CO2", 1.0)
𝒫 = [Power, CO2]

source_1 = PayAsProducedPPA(
    1,
    FixedProfile(5),
    OperationalProfile([1, 3, 4, 5, 0] / 5),
    StrategicProfile([200, 5]),
    FixedProfile(0),
    Dict(Power => 1),
)
source_2 = RefSource(
    2,
    FixedProfile(4),
    StrategicProfile([200, 5]),
    FixedProfile(0),
    Dict(Power => 1),
)
sink = RefSink(
    3,
    StrategicProfile([1, 5]),
    Dict(:surplus => FixedProfile(1), :deficit => FixedProfile(1e4)),
    Dict(Power => 1),
)

# Creating and solving the model
𝒯 = TwoLevel(2, 2, SimpleTimes(5, 2))
𝒯ᴵⁿᵛ = strategic_periods(𝒯)

𝒩 = [source_1, source_2, sink]
ℒ = [
    Direct(13, source_1, sink),
    Direct(23, source_2, sink),
]
model = OperationalModel(
    Dict(CO2 => FixedProfile(100)),
    Dict(CO2 => FixedProfile(100)),
    CO2,
)
case = Case(𝒯, 𝒫, [𝒩, ℒ])
m = EMB.run_model(case, model, OPTIMIZER)

# We only have curtailment in the first strategic period
@test sum(value.(m[:curtailment][source_1, t]) > 0 for t ∈ 𝒯) == 3
@test all(
    value.(m[:cap_use][source_1, t]) + value.(m[:curtailment][source_1, t]) ≈
    EMR.profile(source_1, t) * value.(m[:cap_inst][source_1, t]) for t ∈ 𝒯, atol ∈ TEST_ATOL
)

@test all(
    value(m[:opex_var][source_1, t_inv]) ≈ sum(
        (value(m[:cap_use][source_1, t]) + value(m[:curtailment][source_1, t])) *
        EMB.opex_var(source_1, t) *
        EMB.scale_op_sp(t_inv, t) for t ∈ t_inv
    ) for t_inv ∈ 𝒯ᴵⁿᵛ, atol ∈ TEST_ATOL
)
