module FlexInvestmentsExt

using EnergyModelsFlex

# TODO BatteryStorage needs to be updated to EnergyModelsBase@v0.8.0.
# include("src/constraints_functions_battery_inv.jl")
@warn "BatteryStorage from EnergyModelsFlex is not updated to EnergyModelsBase@v0.8.0 and was therefore removed from this package."

end
