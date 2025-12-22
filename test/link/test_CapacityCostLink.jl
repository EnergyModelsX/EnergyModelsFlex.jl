function capacity_cost_link_test_case(;
    cap = FixedProfile(10),
    capacity_price = StrategicProfile([5e5, 1e6, 2e6]),
    capacity_price_period = 2,
)
    # Define the different resources
    power = ResourceCarrier("Power", 0.0)
    co2 = ResourceEmit("CO₂", 0.0)
    𝒫 = [power, co2]

    # Creation of the time structure and global data
    op_number = 24
    𝒯 = TwoLevel([1, 2, 10], SimpleTimes(op_number, 1); op_per_strat = 8760)
    modeltype = OperationalModel(
        Dict(co2 => FixedProfile(10)),
        Dict(co2 => FixedProfile(0)),
        co2,
    )

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
            capacity_price_period,
            power,
        ),
    ]

    # Input data structure and modeltype creation
    case = Case(𝒯, 𝒫, [𝒩, ℒ])

    return case, modeltype
end

@testset "Checks" begin
    with_logger(NullLogger()) do
        # Test that capacity is non-negative
        case, modeltype = capacity_cost_link_test_case(cap = FixedProfile(-5))
        @test_throws AssertionError create_model(case, modeltype)

        # Test that capacity price is non-negative
        case, modeltype =
            capacity_cost_link_test_case(
                capacity_price = StrategicProfile([-1e5, 1e6, 2e6]),
            )
        @test_throws AssertionError create_model(case, modeltype)

        # Test that the number of sub periods is positive
        case, modeltype = capacity_cost_link_test_case(capacity_price_period = 0)
        @test_throws AssertionError create_model(case, modeltype)

        case, modeltype = capacity_cost_link_test_case(capacity_price_period = -1)
        @test_throws AssertionError create_model(case, modeltype)

        # Test that operational periods can accumulate into cap_price_periods sub periods
        # (8760 is not divisible by 7 sub periods)
        case, modeltype = capacity_cost_link_test_case(capacity_price_period = 7)
        @test_throws AssertionError create_model(case, modeltype)
    end
end

# Create the case and modeltype
case, modeltype = capacity_cost_link_test_case()

# Create and optimize the model
optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
m = create_model(case, modeltype)
set_optimizer(m, optimizer)
optimize!(m)

general_tests(m)

# Extract the individual elements and resources
src_cheap, src_exp, sink = get_nodes(case)
direct_link = get_links(case)[1]
l = get_links(case)[2]
power = get_products(case)[1]
𝒯 = get_time_struct(case)
𝒯ˢᵘᵇ = EMF.create_sub_periods(𝒯, l)
𝒯ᴵⁿᵛ = strategic_periods(𝒯)

@testset "Utility functions" begin
    @testset "EMX functions" begin
        # Test the identification functions
        @test has_capacity(l)
        @test has_opex(l)

        # Test the extraction functions
        @test capacity(l) == FixedProfile(10)
        @test all(capacity(l, t) == 10 for t ∈ 𝒯)
        @test inputs(l) == [power]
        @test outputs(l) == [power]
    end

    @testset "EMF functions" begin
        # Test the extraction functions
        capacity_prices = StrategicProfile([5e5, 1e6, 2e6])
        @test all(EMF.cap_price(l)[t_inv] == capacity_prices[t_inv] for t_inv ∈ 𝒯ᴵⁿᵛ)
        @test all(
            all(EMF.cap_price(l, t) == capacity_prices[t_inv] for t ∈ t_inv) for
            t_inv ∈ 𝒯ᴵⁿᵛ
        )
        @test EMF.cap_price_periods(l) == 2
        @test EMF.cap_resource(l) == power
    end
end

@testset "Constructor" begin
    # Test that the individual constructors are working
    l_def = CapacityCostLink(
        "Capacity cost link",
        src_cheap,
        sink,
        FixedProfile(10),
        FixedProfile(1e6),
        2,
        power,
    )
    l_data = CapacityCostLink(
        "Capacity cost link",
        src_cheap,
        sink,
        FixedProfile(10),
        FixedProfile(1e6),
        2,
        power,
        ExtensionData[],
    )
    l_form = CapacityCostLink(
        "Capacity cost link",
        src_cheap,
        sink,
        FixedProfile(10),
        FixedProfile(1e6),
        2,
        power,
        Linear(),
    )
    l_all = CapacityCostLink(
        "Capacity cost link",
        src_cheap,
        sink,
        FixedProfile(10),
        FixedProfile(1e6),
        2,
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

@testset "Constraints" begin
    # No losses: link_out == link_in
    @test all(
        value(m[:link_out][l, t, p]) ≈ value(m[:link_in][l, t, p])
        for t ∈ 𝒯, p ∈ inputs(l)
    )

    # Capacity constraint: link_in ≤ link_cap_inst
    @test all(
        value(m[:link_in][l, t, power]) ≲ value(m[:link_cap_inst][l, t])
        for t ∈ 𝒯
    )

    # Max capacity use per sub-period:
    #    link_in[t] ≤ max_cap_use_sub_period[t_sub_end]
    @test all(
        all(
            value(m[:link_in][l, t, power]) ≲
            value(m[:max_cap_use_sub_period][l, t_sub[end]])
            for t ∈ t_sub
        )
        for t_sub ∈ 𝒯ˢᵘᵇ
    )

    # Capacity cost at end of sub-period: cap_cost == max_cap_use * avg_cap_price
    @test all(
        value(m[:cap_cost_sub_period][l, t_sub[end]]) ≈
        value(m[:max_cap_use_sub_period][l, t_sub[end]]) * EMF.avg_cap_price(l, t_sub)
        for t_sub ∈ 𝒯ˢᵘᵇ
    )

    # Strategic-period sum: link_opex_var == sum(cap_cost_sub_period over t_inv)
    @test all(
        value(m[:link_opex_var][l, t_inv]) ≈
        sum(value(m[:cap_cost_sub_period][l, t]) for t ∈ t_inv)
        for t_inv ∈ 𝒯ᴵⁿᵛ
    )

    # Check that there is no sink deficit or surplus
    @test all(value.(m[:sink_deficit][sink, t]) ≈ 0.0 for t ∈ 𝒯)
    @test all(value.(m[:sink_surplus][sink, t]) ≈ 0.0 for t ∈ 𝒯)

    # Check that the `CapacityCostLink` is only used up to a capacity of 1.0 to limit
    # the opex on the line (the remaining demand is covered by the `Direct` link)
    @test all(value.(m[:link_out][direct_link, t, power]) ≈ 0.0 for t ∈ 𝒯ˢᵘᵇ[2])
    @test all(value.(m[:link_out][l, t, power]) ≈ 1.0 for t ∈ 𝒯ˢᵘᵇ[1])

    # Check that the opex is correct
    @test value.(m[:link_opex_var][l, 𝒯ᴵⁿᵛ[1]]) ≈ 2 * 5e5 * 1.0 # A capacity of 1.0 is used over both sub periods (having a opex of 5e5 each)
    @test value.(m[:link_opex_var][l, 𝒯ᴵⁿᵛ[2]]) ≈ 2 * 1e6 * 1.0 # A capacity of 1.0 is used over both sub periods (having a opex of 1e6 each)
    @test value.(m[:link_opex_var][l, 𝒯ᴵⁿᵛ[3]]) ≈ 0.0 # Due to a high capacity cost of 2e6, the link is not used

    # For the first two operational periods with demand 10 and 9 respectively, the
    # Direct link covers the remaining demand (with `1.0` being provided by `l`), which
    # with a cost of 400 EUR/MW and scaled with the operational period duration gives:
    @test value.(m[:opex_var][src_exp, 𝒯ᴵⁿᵛ[1]]) ≈ ((10-1) + (9-1)) * 400 * (8760/24)
    @test value.(m[:opex_var][src_exp, 𝒯ᴵⁿᵛ[2]]) ≈ ((10-1) + (9-1)) * 400 * (8760/24)
    @test value.(m[:opex_var][src_exp, 𝒯ᴵⁿᵛ[3]]) ≈ (10 + 9 + (24-2)*1) * 400 * (8760/24)
end
