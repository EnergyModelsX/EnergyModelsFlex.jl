
function EMB.variables_node(m, 𝒩ᴸˢ::Vector{<:LoadShiftingNode}, 𝒯, modeltype::EnergyModel)
    times = collect(𝒯)
    𝒯ᴸˢ = times[𝒩ᴸˢ[1].loadshifttimes] 
    # Creating a variable for every time step where load shifting is allowed
    @variable(m, load_shift_from[𝒩ᴸˢ,𝒯ᴸˢ], Bin )
    @variable(m, load_shift_to[𝒩ᴸˢ,𝒯ᴸˢ], Bin )
    # Creating a variable for every timestep saying how much load is shifted
    @variable(m, load_shifted[𝒩ᴸˢ,𝒯]) # can also be negative which will mean load shifted from
end



function EMB.variables_node(m, 𝒩uc::Vector{UnitCommitmentNode}, 𝒯, modeltype::EnergyModel)
    @variable(m, onswitch[𝒩uc, 𝒯], Bin)
    @variable(m, offswitch[𝒩uc, 𝒯], Bin)
    @variable(m, on_off[𝒩uc, 𝒯], Bin)
end
