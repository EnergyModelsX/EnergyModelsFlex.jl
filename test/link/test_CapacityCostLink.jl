# Declare all resources of the case
power = ResourceCarrier("Power", 0.0)
co2 = ResourceEmit("CO₂", 0.0)

function capacity_cost_link_case(;
    cap = FixedProfile(10),
    capacity_price = StrategicProfile([5e5, 1e6, 2e6]),
    capacity_price_period = 2,
)
    # Define the different resources
    𝒫 = [power, co2]

    # Creation of the time structure
    op_number = 24
    𝒯 = TwoLevel([1, 2, 10], SimpleTimes(op_number, 1); op_per_strat = 8760)

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

    # Test that the number of sub periods is positive
    @test_throws AssertionError capacity_cost_link_case(capacity_price_period = 0)
    @test_throws AssertionError capacity_cost_link_case(capacity_price_period = -1)

    # Test that operational periods can accumulate into cap_price_periods sub periods
    # (8760 is not divisible by 7 sub periods)
    @test_throws AssertionError capacity_cost_link_case(capacity_price_period = 7)

    # Set the global to true to suppress the error message
    EMB.TEST_ENV = false
end

@testset "Utility functions" begin
    # Create the case and modeltype
    m, case, modeltype = capacity_cost_link_case()
    cc_link = get_links(case)[2]
    𝒯 = get_time_struct(case)
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
        @test EMF.cap_price_periods(cc_link) == 2
        @test EMF.cap_resource(cc_link) == power
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

@testset "Constraint implementation" begin
    # Create the case and modeltype
    m, case, modeltype = capacity_cost_link_case()

    # Optimize the model and conduct the general tests
    set_optimizer(m, OPTIMIZER)
    optimize!(m)
    general_tests(m)

    # Extract the individual elements
    src_cheap, src_exp, sink = get_nodes(case)
    direct_link, cc_link = get_links(case)

    𝒯 = get_time_struct(case)
    𝒯ˢᵘᵇ = EMF.create_sub_periods(cc_link, 𝒯)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

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
            value(m[:ccl_cap_use_max][cc_link, t_sub[end]])
            for t ∈ t_sub
        )
        for t_sub ∈ 𝒯ˢᵘᵇ
    )

    # Capacity cost at end of sub-period: cap_cost == max_cap_use * avg_cap_price
    @test all(
        value(m[:ccl_cap_use_cost][cc_link, t_sub[end]]) ≈
        value(m[:ccl_cap_use_max][cc_link, t_sub[end]]) * EMF.avg_cap_price(cc_link, t_sub)
        for t_sub ∈ 𝒯ˢᵘᵇ
    )

    # Strategic-period sum: link_opex_var == sum(ccl_cap_use_cost over t_inv)
    @test all(
        value(m[:link_opex_var][cc_link, t_inv]) ≈
            sum(value(m[:ccl_cap_use_cost][cc_link, t]) for t ∈ t_inv)
        for t_inv ∈ 𝒯ᴵⁿᵛ
    )

    # Check that there is no sink deficit or surplus
    @test all(value.(m[:sink_deficit][sink, t]) ≈ 0.0 for t ∈ 𝒯)
    @test all(value.(m[:sink_surplus][sink, t]) ≈ 0.0 for t ∈ 𝒯)

    # Check that the `CapacityCostLink` is only used up to a capacity of 1.0 to limit
    # the opex on the line (the remaining demand is covered by the `Direct` link)
    @test all(value.(m[:link_out][direct_link, t, power]) ≈ 0.0 for t ∈ 𝒯ˢᵘᵇ[2])
    @test all(value.(m[:link_out][cc_link, t, power]) ≈ 1.0 for t ∈ 𝒯ˢᵘᵇ[1])

    # Check that the opex is correct
    @test value.(m[:link_opex_var][cc_link, 𝒯ᴵⁿᵛ[1]]) ≈ 2 * 5e5 * 1.0 # A capacity of 1.0 is used over both sub periods (having a opex of 5e5 each)
    @test value.(m[:link_opex_var][cc_link, 𝒯ᴵⁿᵛ[2]]) ≈ 2 * 1e6 * 1.0 # A capacity of 1.0 is used over both sub periods (having a opex of 1e6 each)
    @test value.(m[:link_opex_var][cc_link, 𝒯ᴵⁿᵛ[3]]) ≈ 0.0 # Due to a high capacity cost of 2e6, the link is not used

    # For the first two operational periods with demand 10 and 9 respectively, the
    # Direct link covers the remaining demand (with `1.0` being provided by `cc_link`), which
    # with a cost of 400 EUR/MW and scaled with the operational period duration gives:
    @test value.(m[:opex_var][src_exp, 𝒯ᴵⁿᵛ[1]]) ≈ ((10-1) + (9-1)) * 400 * (8760/24)
    @test value.(m[:opex_var][src_exp, 𝒯ᴵⁿᵛ[2]]) ≈ ((10-1) + (9-1)) * 400 * (8760/24)
    @test value.(m[:opex_var][src_exp, 𝒯ᴵⁿᵛ[3]]) ≈ (10 + 9 + (24-2)*1) * 400 * (8760/24)
end
