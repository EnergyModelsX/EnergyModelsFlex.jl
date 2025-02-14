using EnergyModelsSDDP
using SDDP

function EMB.variables_node(
    m,
    𝒩ˢᵗᵒʳ::Vector{<:BatteryStorage},
    𝒯,
    modeltype::Union{SDDPOpModel,SDDPInvModel},
)
    # Declare the variables for the charge and discharge rates.
    EMB.variables_node(m, 𝒩ˢᵗᵒʳ, 𝒯, EnergyModelsSDDP.base_modeltype(modeltype))

    # Declare state variables for the stor_res_up and stor_res_down.
    @variable(m, stor_res_up_st[n ∈ 𝒩ˢᵗᵒʳ] >= 0, SDDP.State, initial_value = 0)
    @variable(m, stor_res_down_st[n ∈ 𝒩ˢᵗᵒʳ] >= 0, SDDP.State, initial_value = 0)
end
