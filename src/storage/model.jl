"""
    EMB.variables_node(m, 𝒩ˢᵗᵒʳ::Vector{<:BatteryStorage}, 𝒯, ::EnergyModel)

Write docstring here...
"""
function EMB.variables_node(m, 𝒩ˢᵗᵒʳ::Vector{<:BatteryStorage}, 𝒯, ::EnergyModel)
    @variable(m, stor_rate_ch[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_rate_dch[𝒩ˢᵗᵒʳ, 𝒯] >= 0)

    @variable(m, stor_rate_inst_dch[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_rate_inst_ch[𝒩ˢᵗᵒʳ, 𝒯] >= 0)

    @variable(m, stor_res_up[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_res_down[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
end

"""
    EMB.variables_node(m, 𝒩ˢᵗᵒʳ::Vector{<:BatteryStorage}, 𝒯, modeltype::EnergyModel)

Write docstring here...
"""
function EMB.create_node(m, n::BatteryStorage, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets.
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    EMB.constraints_level(m, n, 𝒯, 𝒫, modeltype)

    # Call of the function for the inlet flow to the `Storage` node
    EMB.constraints_flow_in(m, n, 𝒯, modeltype)
    EMB.constraints_flow_out(m, n, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    EMB.constraints_capacity(m, n, 𝒯, modeltype)
    constraints_equal_reserve(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    EMB.constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    EMB.constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end
