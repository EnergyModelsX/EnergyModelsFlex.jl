"""
This file can be used for writing the constraints of new technology nodes or transmission
modes.
If you are only using the standard `types`, then this file can remain empty or be removed.
"""

function EMB.variables_capacity(m, 𝒩, 𝒯, modeltype::EnergyModel)

    𝒩ⁿᵒᵗ = EMB.nodes_not_sub(𝒩, Union{Storage, Availability})
    𝒩ˢᵗᵒʳ = filter(EMB.is_storage, 𝒩)

    @variable(m, cap_use[𝒩ⁿᵒᵗ, 𝒯] >= 0)
    @variable(m, cap_inst[𝒩ⁿᵒᵗ, 𝒯] >= 0)

    @variable(m, stor_level[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_level_Δ_op[𝒩ˢᵗᵒʳ, 𝒯])
    if 𝒯 isa TwoLevel{S,T,U} where {S,T,U<:RepresentativePeriods}
        𝒯ʳᵖ = repr_periods(𝒯)
        @variable(m, stor_level_Δ_rp[𝒩ˢᵗᵒʳ, 𝒯ʳᵖ])
    end
    @variable(m, stor_rate_use[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_rate_receive[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_cap_inst[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_rate_inst[𝒩ˢᵗᵒʳ, 𝒯] >= 0)
    @variable(m, stor_rate_inst_charge[𝒩ˢᵗᵒʳ, 𝒯] >= 0)

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