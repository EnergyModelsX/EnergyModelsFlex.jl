
Power = ResourceCarrier("Power", 0.0)
CO2 = ResourceEmit("CO2", 1.0)

source_1 = RefSource(
    1,
    OperationalProfile([2, 4, 1, 0, 0]),
    StrategicProfile([200, 5]),
    FixedProfile(0),
    Dict(Power => 1),
)
av = GenAvailability(
    2,
    [Power],
)
battery = StorageEfficiency{CyclicStrategic}(
    #battery = RefStorage{CyclicStrategic}(
    3,                   # Node id
    StorCapOpex(
        FixedProfile(2),                  # Charge capacity in MWh/h
        FixedProfile(1e-4),               # Storage variable OPEX for the charging in €/MWh
        FixedProfile(1e3) # Storage fixed OPEX for the charging in €/MWh
    ),
    StorCapOpex(
        FixedProfile(5),         # Storage level capacity in MWh
        FixedProfile(0),         # Storage variable OPEX in €/MWh
        FixedProfile(4e3) # Storage fixed OPEX in €/MWh (Must be changed to €/MW)
    ),
    Power,                                # Stored resource
    Dict(Power => 0.98),      # Input resource with input ratio
    Dict(Power => 0.98),   # Output from the node with output ratio
)
sink = RefSink(
    4,
    StrategicProfile([1, 2]),
    Dict(:surplus => FixedProfile(1), :deficit => FixedProfile(1e6)),
    Dict(Power => 1),
)

# Creating and solving the model
resources = [Power, CO2]
𝒯 = TwoLevel(2, 2, SimpleTimes(5, 1))
𝒯ᴵⁿᵛ = strategic_periods(𝒯)

nodes = [source_1, av, battery, sink]
links = [
    Direct(12, source_1, av),
    Direct(23, av, battery),
    Direct(32, battery, av),
    Direct(24, av, sink),
]
model = OperationalModel(
    Dict(CO2 => FixedProfile(100)),
    Dict(CO2 => FixedProfile(100)),
    CO2,
)
case = Dict(:T => 𝒯, :nodes => nodes, :links => links, :products => resources)
m = EMB.run_model(case, model, HiGHS.Optimizer)

# Testing the deficit
for t_inv ∈ 𝒯ᴵⁿᵛ
    if t_inv.sp == 1
        @test all(value.(m[:sink_deficit][sink, t]) ≈ 0 for t ∈ t_inv, atol ∈ TEST_ATOL)
    else
        @test sum(value.(m[:sink_deficit][sink, t]) for t ∈ t_inv) ≈ 2 * 5 - 5 - 2 * 0.98^2 atol =
            TEST_ATOL
    end
end
