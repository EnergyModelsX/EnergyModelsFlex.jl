
function EMB.check_node(n::MinUpDownTimeNode, 𝒯, modeltype::EnergyModel, check_timeprofiels::Bool)
    # We need the minimum capacity to be greater than zero.
    @assert n.minCapacity > 0

    @assert n.minCapacity <= n.maxCapacity
end
