𝒯 = TwoLevel(1, 1, SimpleTimes(30, 1))

power_prices = [
    1,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    2,
    2,
    2,
    2,
    2,
    1,
    1,
    1,
    1,
    1,
]
demand = [
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    15,
    15,
    15,
    15,
    15,
    15,
    15,
    15,
    15,
    15,
    15,
    15,
    15,
    15,
    15,
]
load_shift_times = [1, 6, 11, 16, 21, 26]

desired_cap_use = OperationalProfile([
    45,
    45,
    45,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    5,
    5,
    5,
    25,
    25,
    5,
    5,
    5,
    15,
    15,
    5,
    5,
    5,
    15,
    15,
    35,
    35,
    35,
    15,
    15,
])

CO2 = ResourceEmit("CO2", 1.0)
Power = ResourceCarrier("Power", 0.0)
products = [Power, CO2]

power_source = RefSource(
    1,
    FixedProfile(100),
    OperationalProfile(power_prices), # opex var = power prices
    FixedProfile(0),
    Dict(Power => 1),
)

load_shift_demand = LoadShiftingNode(
    2,
    OperationalProfile(demand), # cap
    Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(10)), # penalty
    Dict(Power => 1), # input
    load_shift_times,
    2, # load_shifts_per_period
    3, # load_shift_duration
    10, # load_shift_magnitude
    3, # load_shift_times_per_period
)

ℒ = [Direct(12, power_source, load_shift_demand)]
𝒩 = [power_source, load_shift_demand]
case = Case(𝒯, 𝒫, [𝒩, ℒ])
model = OperationalModel(
    Dict(CO2 => FixedProfile(100)),
    Dict(CO2 => FixedProfile(100)),
    CO2,
)
m = EMB.run_model(case, model, OPTIMIZER)

𝒯ᴵⁿᵛ = strategic_periods(𝒯)
for t_inv ∈ 𝒯ᴵⁿᵛ
    @test all(
        value.(m[:cap_use][load_shift_demand, t]) ≈ desired_cap_use[t]
        for t ∈ t_inv, atol ∈ TEST_ATOL
    )
end
