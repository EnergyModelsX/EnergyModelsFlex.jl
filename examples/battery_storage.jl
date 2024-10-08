using Pkg
# Activate the local environment including EnergyModelsBase, HiGHS, PrettyTables
Pkg.activate(@__DIR__)
# Install the dependencies.
Pkg.instantiate()

import EnergyModelsBase as EMB
import EnergyModelsRenewableProducers: NonDisRES
import EnergyModelsFlex: BatteryStorage
import HiGHS
import JuMP
import PrettyTables: pretty_table
import TimeStruct: FixedProfile, TwoLevel, SimpleTimes

@warn "BatteryStorage from EnergyModelsFlex is not updated to EnergyModelsBase@v0.8.0 and was therefore removed from this package."

function create_system()

	T = TwoLevel(1, 5, SimpleTimes(168, 1))

	power = EMB.ResourceCarrier("Power", 0)
	power_reserve_up = EMB.ResourceCarrier("PowerReserveUp", 0)
	power_reserve_down = EMB.ResourceCarrier("PowerReserveDown", 0)
	co2 = EMB.ResourceEmit("CO2", 1)

	products = [power, power_reserve_up, power_reserve_down, co2]

	model = EMB.OperationalModel(
		Dict(co2 => FixedProfile(100.0)),
		Dict(co2 => FixedProfile(100.0)), co2)


	av = EMB.GenAvailability("av", products)

	SolarPv = NonDisRES(
		"SolarPv",
		FixedProfile(86), # kW
		FixedProfile(0.9),
		FixedProfile(0.0),
		FixedProfile(0),
		Dict(power => 1.0))

	WindTurbine = NonDisRES(
		"WindTurbine",
		FixedProfile(135), # kW
		FixedProfile(0.9),
		FixedProfile(0.0),
		FixedProfile(0),
		Dict(power => 1))

	Load = EMB.RefSink(
		"Load",
		FixedProfile(100),
		Dict(:surplus => FixedProfile(0),
			:deficit => FixedProfile(50)),
		Dict(power => 1.0))

	ReserveUp = EMB.RefSink(
		"ReserveUp",
		FixedProfile(40), # kW - maximum up regulation capacity
		Dict(:surplus => FixedProfile(0),
			:deficit => FixedProfile(0.12)), # NOK / kW / h - Price for not delivering maximum reserve capcity / price for providing reserve up
		Dict(power_reserve_up => 1))

	ReserveDown = EMB.RefSink(
		"ReserveDown",
		FixedProfile(40), # kW - maximum down regulation capacity
		Dict(:surplus => FixedProfile(0),
			:deficit => FixedProfile(0.12)), # NOK / kW / h - Price for not delivering maximum reserve capcity / price for providing reserve down
		Dict(power_reserve_down => 1))

	Diesel = EMB.RefSource(
		"Diesel",
		FixedProfile(20), # kW
		FixedProfile(2), # NOK / kWh - cost of using diesel generator
		FixedProfile(0),
		Dict(power => 1.0))

	battery = BatteryStorage(
		"Battery",
		FixedProfile(40), # charge capacity [kW]
		FixedProfile(40), # discharge cap [kW]
		FixedProfile(500), # storage capacity [kWh]
		FixedProfile(0),  # variable opex
		FixedProfile(0), # fixed opex
		0.95, # charge efficiency
		0.95, # discharge efficiency
		power, # storage resource
		[power_reserve_up], # reserve resource up
		[power_reserve_down], # reserve resource down
		Dict(power => 1),
		Dict(power => 1,
		power_reserve_up => 1,
		power_reserve_down => 1),
		EMB.Data[])

	nodes = [av, SolarPv, WindTurbine, Load, ReserveUp, ReserveDown, Diesel, battery]
	links = [
		EMB.Direct("solar-av", SolarPv, av),
		EMB.Direct("wind-av", WindTurbine, av),
		EMB.Direct("av-load", av, Load),
		EMB.Direct("av-reserve-up", av, ReserveUp),
		EMB.Direct("av-reserve-down", av, ReserveDown),
		EMB.Direct("diesel-av", Diesel, av),
		EMB.Direct("battery-av", battery, av),
		EMB.Direct("av-battery", av, battery),
	]

	case = Dict(
		:nodes => nodes,
		:links => links,
		:products => products,
		:T => T
	)
	return case, model
end


case, model = create_system()

opt = JuMP.optimizer_with_attributes(HiGHS.Optimizer, JuMP.MOI.Silent() => true)

m = EMB.run_model(case, model, opt)

battery = case[:nodes][end]

pretty_table(
    JuMP.Containers.rowtable(
        JuMP.value,
        m[:stor_res_up][battery, :];
        header=[:t, :Value]
    ),
)
pretty_table(
    JuMP.Containers.rowtable(
        JuMP.value,
        m[:stor_res_down][battery, :];
        header=[:t, :Value]
    ),
)
