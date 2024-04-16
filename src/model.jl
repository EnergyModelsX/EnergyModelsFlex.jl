
function EMB.variables_node(m, 𝒩ˢᵗᵒʳ::Vector{<:BatteryStorage}, 𝒯, modeltype::EnergyModel)
    @variable(m, stor_rate_ch[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_rate_dch[𝒩ˢᵗᵒʳ, 𝒯] >= 0)

    @variable(m, stor_rate_inst_dch[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_rate_inst_ch[𝒩ˢᵗᵒʳ, 𝒯] >= 0)

    @variable(m, stor_res_up[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_res_down[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
end

function EMB.create_node(m, n::RyeMicrogrid.BatteryStorage, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets.
    𝒯ᴵⁿᵛ   = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    constraints_level(m, n, 𝒯, 𝒫, modeltype)

    # Call of the function for the inlet flow to the `Storage` node
    constraints_flow_in(m, n, 𝒯, modeltype)
    constraints_flow_out(m, n, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end
