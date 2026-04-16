# Declare the products
power = ResourceCarrier("power", 0)
product = ResourceCarrier("product", 0)
CO2 = ResourceEmit("CO2", 0)

function test_case_minupdown(
    min_up = 2,
    min_down = 2 ;
    cap = FixedProfile(200),
    tp_opex_var = FixedProfile(0),
    tp_opex_fixed = FixedProfile(0),
    inp_val = 1,
    out_val = 1,
    min_cap = 20,
    max_cap = 200,
)
    𝒯 = TwoLevel(1, 1, SimpleTimes(7 * 24, 1))
    𝒫 = [power, product, CO2]

    day = [1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 2]
    el_cost = [repeat(day, 5)..., fill(0, 2 * 24)...]

    src = RefSource(
        "src",
        FixedProfile(1e12), # kW - virtually infinite
        OperationalProfile(el_cost),
        FixedProfile(0),
        Dict(power => 1),
    )

    line = MinUpDownTimeNode(
        "line",
        cap, # kW - installed capacity for both lines
        tp_opex_var,
        tp_opex_fixed,
        Dict(power => inp_val),
        Dict(product => out_val),
        min_up, # min_up_time
        min_down, # min_down_time
        min_cap, # min_capacity
        max_cap, # max_capacity
    )

    # The demand can only be satisfied between 6-20 on weekdays, with a capacity of 200.
    # No production on weekends.
    weekday_prod = [fill(0, 6)..., fill(200, 14)..., fill(0, 4)...]
    week_prod = [repeat(weekday_prod, 5)..., fill(0, 2 * 24)...]

    snk = PeriodDemandSink(
        "demand_product",
        24,                         # 24 hours per day
        [fill(1500, 5)..., 0, 0],   # Demand 1500 units per day, and nothing (0) in the weekend.
        OperationalProfile(week_prod), # kW - installed capacity
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e8)), # € / Demand - Price for not delivering products
        Dict(product => 1),
    )

    𝒩 = [src, line, snk]
    ℒ = [Direct("src-line", src, line), Direct("line-snk", line, snk)]

    case = Case(𝒯, 𝒫, [𝒩, ℒ])

    modeltype = OperationalModel(
        Dict(CO2 => FixedProfile(1e6)),
        Dict(CO2 => FixedProfile(100)),
        CO2,
    )
    m = create_model(case, modeltype)

    return m, case, modeltype
end

@testset "Check functions" begin
    # Set the global to true to suppress the error message
    EMB.TEST_ENV = true

    # Default checks
    # - EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
    @test_throws AssertionError test_case_minupdown(; cap=FixedProfile(-5))
    @test_throws AssertionError test_case_minupdown(; inp_val=-1)
    @test_throws AssertionError test_case_minupdown(; out_val=-1)
    @test_throws AssertionError test_case_minupdown(; tp_opex_fixed = OperationalProfile([1]))

    # Introduced checks
    # - EMB.check_node(n::MinUpDownTimeNode, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    @test_throws AssertionError test_case_minupdown(; min_cap = 0)
    @test_throws AssertionError test_case_minupdown(; max_cap = 0)

    # Set the global to true to suppress the error message
    EMB.TEST_ENV = false
end

@testset "Extraction functions" begin
    # Create the model and extract the parameters
    tp_opex_fixed = FixedProfile(10)
    tp_opex_var = FixedProfile(5)
    m, case, modeltype = test_case_minupdown(; tp_opex_fixed, tp_opex_var);
    line = get_nodes(case)[2]
    𝒯 = get_time_struct(case)

    # Test the capacity extraction functions
    @test capacity(line) == FixedProfile(200)
    @test all(capacity(line, t) == 200 for t ∈ 𝒯)

    # Test the opex extraction functions
    @test opex_var(line) == FixedProfile(5)
    @test all(opex_var(line, t) == 5 for t ∈ 𝒯)
    @test opex_fixed(line) == FixedProfile(10)
    @test all(opex_fixed(line, t) == 10 for t ∈ 𝒯)

    # Test the input and output extraction functions
    @test inputs(line) == [power]
    @test inputs(line, power) == 1
    @test outputs(line) == [product]
    @test outputs(line, product) == 1

    # Test the data extraction function
    @test node_data(line) == ExtensionData[]
end

@testset "Cyclic sequence" begin
    # Test the MinUpDownTimeNode with different values of min_up and min_down.
    for min_up ∈ 2:8, min_down ∈ 2:8
        # Create the case and model
        m, case, model = test_case_minupdown(min_up, min_down)
        set_optimizer(m, OPTIMIZER)
        optimize!(m)

        # Test optimal solution
        general_tests(m)
        line = get_nodes(case)[2]

        # Test that the minimum up time and minimum down time are at least
        # min_up and min_down.
        cap_use = get_values(m, :cap_use, line, get_time_struct(case))
        check = check_cyclic_sequence(cap_use, min_up, min_down)
        @test check
        msg = "check-min_up=$min_up, min_down=$min_down"
        if !check
            @warn "Failed for: $msg"
        end
    end
end
