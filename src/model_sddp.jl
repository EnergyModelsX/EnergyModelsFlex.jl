using EnergyModelsSDDP

function EMB.variables_node(m, 𝒩ˢᵗᵒʳ::Vector{<:BatteryStorage}, 𝒯, modeltype::Union{SDDPOpModel, SDDPInvModel})
    EMB.variables_node(m, 𝒩ˢᵗᵒʳ, 𝒯, EnergyModelsSDDP.base_modeltype(modeltype))
end
