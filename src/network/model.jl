"""
    EMB.variables_element(m, 𝒩uc::Vector{UnitCommitmentNode}, 𝒯, ::EnergyModel)

# Arguments
- `m`: The optimization model.
- `𝒩uc`: A vector of unit commitment nodes.
- `𝒯`: The time structure.
- `modeltype`: The type of energy model.

# Variables
- `onswitch[n, t]`: Binary variable indicating the node is switched on.
- `offswitch[n, t]`: Binary variable indicating the node is switched off.
- `on_off[n, t]`: Binary variable indicating the node's on/off state.
"""
function EMB.variables_element(m, 𝒩uc::Vector{UnitCommitmentNode}, 𝒯, ::EnergyModel)
    @variable(m, onswitch[𝒩uc, 𝒯], Bin)
    @variable(m, offswitch[𝒩uc, 𝒯], Bin)
    @variable(m, on_off[𝒩uc, 𝒯], Bin)
end
