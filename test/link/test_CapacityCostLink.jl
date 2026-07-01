# Declare all resources of the case
power = ResourceCarrier("Power", 0.0)
co2 = ResourceEmit("CO₂", 0.0)

function capacity_cost_link_case(;
    cap = FixedProfile(10),
    capacity_price = StrategicProfile([5e5, 1e6, 2e6]),
    cap_per_dur = 24,
)
    # Define the different resources
    𝒫 = [power, co2]

    # Creation of the time structure
    op_number = 24
    𝒯 = TwoLevel([1, 2, 10], SimpleTimes(op_number, 2); op_per_strat = 8760)

    # Create the nodes
    𝒩 = [
        RefSource(
            "cheap source",
            FixedProfile(10),
            FixedProfile(100),
            FixedProfile(0),
            Dict(power => 1),
        ),
        RefSource(
            "expensive source",
            FixedProfile(10),
            FixedProfile(400),
            FixedProfile(0),
            Dict(power => 1),
        ),
        RefSink(
            "sink",
            OperationalProfile([10, 9, fill(1, op_number-2)...]),
            Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(1e4)),
            Dict(power => 1),
        ),
    ]

    # Connect the nodes
    ℒ = [
        Direct("Direct link", 𝒩[2], 𝒩[3], Linear()),
        CapacityCostLink(
            "Capacity cost link",
            𝒩[1],
            𝒩[3],
            cap,
            capacity_price,
            cap_per_dur,
            power,
        ),
    ]

    # Input data structure and modeltype creation
    case = Case(𝒯, 𝒫, [𝒩, ℒ])
    modeltype = OperationalModel(
        Dict(co2 => FixedProfile(10)),
        Dict(co2 => FixedProfile(0)),
        co2,
    )
    m = create_model(case, modeltype)

    return m, case, modeltype
end

# Test that the fields of a `CapacityCostLink` are correctly checked
# - EMB.check_link(l::CapacityCostLink, 𝒯, ::EnergyModel, ::Bool)
@testset "Check functions" begin
    # Set the global to true to suppress the error message
    EMB.TEST_ENV = true

    # Test that capacity is non-negative
    @test_throws AssertionError capacity_cost_link_case(; cap = FixedProfile(-5))

    # Test that capacity price is non-negative
    capacity_price = StrategicProfile([-1e5, 1e6, 2e6])
    @test_throws AssertionError capacity_cost_link_case(; capacity_price)

    # Test that operational time structure can can be represented by `period_duration`
    @test_throws AssertionError capacity_cost_link_case(; cap_per_dur = 9)

    # Test that none of the durations of the sub periods is not positive
    cap_per_dur = [0.0, 8.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 8.0, 4.0, 4.0]
    @test_throws AssertionError capacity_cost_link_case(; cap_per_dur)

    # Set the global to true to suppress the error message
    EMB.TEST_ENV = false
end

@testset "Utility functions" begin
    # Create the case and modeltype
    m, case, modeltype = capacity_cost_link_case()
    cc_link = get_links(case)[2]
    𝒯 = get_time_struct(case)
    𝒯ᵖᵈ = EMF.periods(cc_link, 𝒯)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @testset "EMX functions" begin
        # Test the identification functions
        @test has_capacity(cc_link)
        @test has_opex(cc_link)

        # Test the extraction functions
        @test capacity(cc_link) == FixedProfile(10)
        @test all(capacity(cc_link, t) == 10 for t ∈ 𝒯)
        @test inputs(cc_link) == [power]
        @test outputs(cc_link) == [power]
    end

    @testset "EMF functions" begin
        # Test the extraction functions
        capacity_prices = StrategicProfile([5e5, 1e6, 2e6])
        @test all(EMF.cap_price(cc_link)[t_inv] == capacity_prices[t_inv] for t_inv ∈ 𝒯ᴵⁿᵛ)
        @test EMF.cap_price(cc_link).vals == capacity_prices.vals
        @test EMF.period_duration(cc_link) == FixedProfile(24)
        @test EMF.cap_resource(cc_link) == power

        @test all(collect(𝒯ᵖᵈ[k]) ==
            collect(𝒯)[1+12*(k-1):12*k] for k ∈ 1:6)
        @test all(EMF.get_avg_cap_price(cc_link, 𝒯ᵖᵈ[k]) ≈ 5e5 for k ∈ 1:2)
        @test all(EMF.get_avg_cap_price(cc_link, 𝒯ᵖᵈ[k]) ≈ 1e6 for k ∈ 3:4)
        @test all(EMF.get_avg_cap_price(cc_link, 𝒯ᵖᵈ[k]) ≈ 2e6 for k ∈ 5:6)

        # Test that the new functions are also working based on specified durations
        cap_per_dur = PartitionProfile([20, 28])
        capacity_price = StrategicProfile([
            OperationalProfile(vcat(ones(12) * 5e5, ones(12) * 2e5)),
            OperationalProfile(vcat(ones(12) * 1e6, ones(12) * 5e5)),
            OperationalProfile(vcat(ones(12) * 2e6, ones(12) * 1e6)),
        ])

        m, case, modeltype = capacity_cost_link_case(; cap_per_dur, capacity_price)
        cc_link = get_links(case)[2]
        𝒯 = get_time_struct(case)
        𝒯ᵖᵈ = EMF.periods(cc_link, 𝒯)

        @test all(
            EMF.period_duration(cc_link, t_pd) == cap_per_dur[t_pd]
        for t_pd ∈ 𝒯ᵖᵈ)
        @test all(collect(𝒯ᵖᵈ[1+2*(k-1)]) ==
            collect(𝒯)[1+24*(k-1):10*k+14*(k-1)] for k ∈ 1:3)
        @test all(collect(𝒯ᵖᵈ[2*k]) ==
            collect(𝒯)[11+24*(k-1):24*k] for k ∈ 1:3)
        @test EMF.get_avg_cap_price(cc_link, 𝒯ᵖᵈ[1]) ≈ 5e5
        @test EMF.get_avg_cap_price(cc_link, 𝒯ᵖᵈ[2]) ≈ (5e5*2 + 2e5*12)/14
    end
end

@testset "Constructor methods" begin
    # Create the case and modeltype
    m, case, modeltype = capacity_cost_link_case()

    # Extract the individual elements and resources
    src_cheap, src_exp, sink = get_nodes(case)

    # Test that the individual constructors are working
    l_def = CapacityCostLink(
        "Capacity cost link",
        src_cheap,
        sink,
        FixedProfile(10),
        FixedProfile(1e6),
        24,
        power,
    )
    l_data = CapacityCostLink(
        "Capacity cost link",
        src_cheap,
        sink,
        FixedProfile(10),
        FixedProfile(1e6),
        24,
        power,
        ExtensionData[],
    )
    l_form = CapacityCostLink(
        "Capacity cost link",
        src_cheap,
        sink,
        FixedProfile(10),
        FixedProfile(1e6),
        24,
        power,
        Linear(),
    )
    l_all = CapacityCostLink(
        "Capacity cost link",
        src_cheap,
        sink,
        FixedProfile(10),
        FixedProfile(1e6),
        24,
        power,
        Linear(),
        ExtensionData[],
    )
    l_new = CapacityCostLink(
        "Capacity cost link",
        src_cheap,
        sink,
        FixedProfile(10),
        FixedProfile(1e6),
        FixedProfile(24),
        power,
        Linear(),
        ExtensionData[],
    )
    for field ∈ fieldnames(CapacityCostLink)
        @test getproperty(l_def, field) == getproperty(l_data, field)
        @test getproperty(l_def, field) == getproperty(l_form, field)
        @test getproperty(l_def, field) == getproperty(l_all, field)
    end
end

@testset "Constraint implementation" begin

    function ccl_standard_test(cc_link::CapacityCostLink, 𝒯, 𝒯ᵖᵈ)
        # No losses: link_out == link_in
        @test all(
            value(m[:link_out][cc_link, t, p]) ≈ value(m[:link_in][cc_link, t, p])
            for t ∈ 𝒯, p ∈ inputs(cc_link)
        )

        # Capacity constraint: link_in ≤ link_cap_inst
        @test all(
            value(m[:link_in][cc_link, t, power]) ≲ value(m[:link_cap_inst][cc_link, t])
            for t ∈ 𝒯
        )
        @test all(
            value(m[:link_cap_inst][cc_link, t]) ≈ capacity(cc_link, t)
            for t ∈ 𝒯
        )

        # Max capacity use per sub-period:
        #    link_in[t] ≤ ccl_cap_use_max[t_sub_end]
        @test all(
            all(
                value(m[:link_in][cc_link, t, power]) ≲
                value(m[:ccl_cap_use_max][cc_link, t_pd])
                for t ∈ t_pd
            )
            for t_pd ∈ 𝒯ᵖᵈ
        )

        # Capacity cost at end of sub-period: cap_cost == max_cap_use * get_avg_cap_price
        @test all(
            value(m[:ccl_cap_use_cost][cc_link, t_pd]) ≈
            value(m[:ccl_cap_use_max][cc_link, t_pd]) * EMF.get_avg_cap_price(cc_link, t_pd)
            for t_pd ∈ 𝒯ᵖᵈ
        )

        # Strategic-period sum: link_opex_var == sum(ccl_cap_use_cost over t_inv)
        @test all(
            value(m[:link_opex_var][cc_link, t_inv]) ≈
                sum(value(m[:ccl_cap_use_cost][cc_link, t_pd]) for t_pd ∈ EMF.periods(cc_link, t_inv))
            for t_inv ∈ 𝒯ᴵⁿᵛ
        )

        # Check that there is no sink deficit or surplus
        @test all(value.(m[:sink_deficit][sink, t]) ≈ 0.0 for t ∈ 𝒯)
        @test all(value.(m[:sink_surplus][sink, t]) ≈ 0.0 for t ∈ 𝒯)
    end

    # Create the case and modeltype when specifiying the number of periods
    m, case, modeltype = capacity_cost_link_case()

    # Optimize the model and conduct the general tests
    set_optimizer(m, OPTIMIZER)
    optimize!(m)
    general_tests(m)

    # Extract the individual elements
    src_cheap, src_exp, sink = get_nodes(case)
    direct_link, cc_link = get_links(case)
    𝒯 = get_time_struct(case)
    𝒯ᵖᵈ = EMF.periods(cc_link, 𝒯)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Perform the standard tests
    ccl_standard_test(cc_link, 𝒯, 𝒯ᵖᵈ)

    # Test that the variables are created correctly
    @test length(m[:ccl_cap_use_max][cc_link, :]) == 6
    @test length(m[:ccl_cap_use_cost][cc_link, :]) == 6

    # Check that the `CapacityCostLink` is only used up to a capacity of 1.0 to limit
    # the opex on the line (the remaining demand is covered by the `Direct` link)
    @test all(value.(m[:link_out][direct_link, t, power]) ≈ 0.0 for t ∈ 𝒯ᵖᵈ[2])
    @test all(value.(m[:link_out][cc_link, t, power]) ≈ 1.0 for t ∈ 𝒯ᵖᵈ[1])

    # Check that the opex of the CapacityCostLink is correct
    # Sp1: A capacity of 1.0 is used over both sub periods (having an opex of 5e5 each)
    # Sp2: A capacity of 1.0 is used over both sub periods (having an opex of 1e6 each)
    # Sp3: A capacity of 1.0 is used over both sub periods (having an opex of 1e6 each)
    exp_val = StrategicProfile(2 * [5e5, 1e6, 0])
    @test all(value.(m[:link_opex_var][cc_link, t_inv]) ≈ exp_val[t_inv] for t_inv ∈ 𝒯ᴵⁿᵛ)

    # Check that the opex of the expensive source is correct
    # Sp1 and sp2: Only used to account for the peak additional demand (10-1 and 9-1)
    # Sp3: Cover all demand
    exp_val = StrategicProfile([
        ((10-1) + (9-1)) * 400 * (8760/24),
        ((10-1) + (9-1)) * 400 * (8760/24),
        (10 + 9 + (24-2) * 1) * 400 * (8760/24),
    ])
    @test all(value.(m[:opex_var][src_exp, t_inv]) ≈ exp_val[t_inv] for t_inv ∈ 𝒯ᴵⁿᵛ)

    # Create the case and modeltype when specifiying the duration of the periods
        cap_per_dur = PartitionProfile([20, 28])
    capacity_price = StrategicProfile([
        OperationalProfile(vcat(ones(12) * 1e5, ones(12) * 2e5)),
        OperationalProfile(vcat(ones(12) * 1e6, ones(12) * 5e5)),
        OperationalProfile(vcat(ones(12) * 2e6, ones(12) * 1e6)),
    ])

    m, case, modeltype = capacity_cost_link_case(; cap_per_dur, capacity_price)

    # Optimize the model and conduct the general tests
    set_optimizer(m, OPTIMIZER)
    optimize!(m)
    general_tests(m)

    # Extract the individual elements
    src_cheap, src_exp, sink = get_nodes(case)
    direct_link, cc_link = get_links(case)
    𝒯 = get_time_struct(case)
    𝒯ᵖᵈ = EMF.periods(cc_link, 𝒯)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Perform the standard tests
    ccl_standard_test(cc_link, 𝒯, 𝒯ᵖᵈ)

    # Check that the `CapacityCostLink` is only used up to a capacity of 1.0 in sp3, sub
    # periods 1 to limit the opex on the line (the remaining demand is covered by the `Direct` link)
    # The direct link is not used in sp1 due to the reduced costs
    @test all(value.(m[:link_out][direct_link, t, power]) ≈ 0.0 for k ∈ [1,2,4] for t ∈ 𝒯ᵖᵈ[k])
    @test all(value.(m[:link_out][cc_link, t, power]) ≈ 1.0 for t ∈ 𝒯ᵖᵈ[3])

    # Check that the opex of the expensive source is correct
    # Sp1: A capacity of 9.0 is used in the first sub period (having an opex of 1e5) and A
    #      a capacity of 1.0 in the second sub period (having an opex of (1e5*2 + 2e5*12)/14)
    # Sp2: A capacity of 1.0 is used over both sub periods (having an opex of 1e6 and
    #      (1e6*2 + 5e5*12)/14, respectively)
    # Sp3: A capacity of 0.0 is used in the first sub periods and a capacity of 1 in the
    #      second sub period (with a cost of (2e6*2 + 1e6*12)/14)
    exp_val = StrategicProfile([
        FixedProfile(10 * 1e5  + 1 * (1e5*2 + 2e5*12)/14),
        FixedProfile(1 * 1e6  + 1 * (1e6*2 + 5e5*12)/14),
        FixedProfile(0 * 2e6  + 1 * (2e6*2 + 1e6*12)/14),
    ])
    @test all(value.(m[:link_opex_var][cc_link, t_inv]) ≈ exp_val[t_inv] for t_inv ∈ 𝒯ᴵⁿᵛ)

    # Check that the opex of the expensive source is correct
    # Sp1 and sp2: Only used to account for the peak additional demand
    # Sp3: Cover all demand in the first sub period, but not in the second sub period
    exp_val = StrategicProfile([
        FixedProfile(0),
        FixedProfile(((10-1) + (9-1)) * 400 * (8760/24)),
        FixedProfile((10 + 9 + (10-2) * 1) * 400 * (8760/24)),
    ])
    @test all(value.(m[:opex_var][src_exp, t_inv]) ≈ exp_val[t_inv] for t_inv ∈ 𝒯ᴵⁿᵛ)
end
