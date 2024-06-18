import EnergyModelsBase as EMB
import EnergyModelsInvestments: AbstractInvestmentModel, has_investment
import TimeStruct: TimeStructure


function EMB.constraints_capacity_installed(m, n::BatteryStorage, 𝒯::TimeStructure, modeltype::AbstractInvestmentModel)
    if has_investment(n)
        error("Investment model not implemented for EnergyModelsFlex.BatteryStorage")
        return
    end

    # Set the same constraints as for the operational model if there are no investments
    # to the battery storage.
    op_model = EMB.OperationalModel(modeltype.emission_limit, modeltype.emission_price, modeltype.co2_instance)
    EMB.constraints_capacity_installed(m, n, 𝒯, op_model)
end
