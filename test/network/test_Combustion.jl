
NG = ResourceCarrier("NG", 0.2)
H2 = ResourceCarrier("H2", 0.0)
gas_LHV = ResourceCarrier("gas LHV", 0)
Heat = ResourceCarrier("Reusable excess heat", 0)
CO2 = ResourceEmit("CO2", 1.0)
𝒫 = [NG, H2, gas_LHV, Heat, CO2]

source_1 = RefSource(
    1,
    FixedProfile(4),
    StrategicProfile([5, 200]),
    FixedProfile(0),
    Dict(NG => 1),
)
source_2 = RefSource(
    2,
    FixedProfile(4),
    StrategicProfile([200, 5]),
    FixedProfile(0),
    Dict(H2 => 1),
)
h2_limit_factor = 0.0701
Heat_factor_h2 = 0.845
Heat_factor_ng = 0.901
share_excess_heat = 0.065
combustion = Combustion(
    3,                                  # id
    FixedProfile(8),                    # capacity
    FixedProfile(0),                    # variable operating expenses
    FixedProfile(0),                    # fixed operating expenses
    Dict(NG => 1.0, H2 => h2_limit_factor),      # The limits for each resources relative to the total inflow
    Heat,                               # The residual heat resource
    Dict(NG => 1 / Heat_factor_ng, H2 => 1 / Heat_factor_h2), # input and conversion factor
    Dict(gas_LHV => 1, Heat => share_excess_heat),                 # output and conversion factor
    [EmissionsEnergy()],
)
sink = RefSink(
    4,
    FixedProfile(1),
    Dict(:surplus => FixedProfile(1), :deficit => FixedProfile(1e4)),
    Dict(gas_LHV => 1),
)
reusable_excess_heat = RefSink(
    5,
    FixedProfile(1),
    Dict(:surplus => FixedProfile(1), :deficit => FixedProfile(1e4)),
    Dict(Heat => 1),
)

# Creating and solving the model
𝒯 = TwoLevel(2, 2, SimpleTimes(5, 2))
𝒯ᴵⁿᵛ = strategic_periods(𝒯)

𝒩 = [source_1, source_2, combustion, sink, reusable_excess_heat]
ℒ = [
    Direct(13, source_1, combustion),
    Direct(23, source_2, combustion),
    Direct(34, combustion, sink),
    Direct(35, combustion, reusable_excess_heat),
]
model = OperationalModel(
    Dict(CO2 => FixedProfile(100)),
    Dict(CO2 => FixedProfile(100)),
    CO2,
)
case = Case(𝒯, 𝒫, [𝒩, ℒ])
m = EMB.run_model(case, model, OPTIMIZER)

general_tests(m)

# Testing the correct source usage
for t_inv ∈ 𝒯ᴵⁿᵛ
    if t_inv.sp == 1
        @test all(
            value.(m[:flow_in][combustion, t, NG]) +
            value.(m[:flow_in][combustion, t, H2]) ≈
            value.(m[:flow_out][combustion, t, gas_LHV]) +
            value.(m[:flow_out][combustion, t, Heat]) / share_excess_heat for t ∈ t_inv,
            atol ∈ TEST_ATOL
        )
    else
        @test all(
            value.(m[:flow_in][combustion, t, H2]) ≈
            sum(value.(m[:flow_in][combustion, t, :])) * h2_limit_factor for t ∈ t_inv,
            atol ∈ TEST_ATOL
        )
    end
end
@test all(
    sum(
        value.(m[:flow_in][combustion, t, p]) / EMB.inputs(combustion, p) for
        p ∈ keys(combustion.input)
    ) ≈ value.(m[:cap_use][sink, t]) for t ∈ 𝒯, atol ∈ TEST_ATOL
)
