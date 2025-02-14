"""
    EMB.variables_node(m, 𝒩uc::Vector{UnitCommitmentNode}, 𝒯, ::EnergyModel)

Write docstring here...
"""
function EMB.variables_node(m, 𝒩uc::Vector{UnitCommitmentNode}, 𝒯, ::EnergyModel)
    @variable(m, onswitch[𝒩uc, 𝒯], Bin)
    @variable(m, offswitch[𝒩uc, 𝒯], Bin)
    @variable(m, on_off[𝒩uc, 𝒯], Bin)
end
