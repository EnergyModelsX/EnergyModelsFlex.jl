
function EMB.variables_node(m, 𝒩ˢⁱⁿᵏ::Vector{<:PeriodDemandSink}, 𝒯, modeltype::EnergyModel)
    n = first(𝒩ˢⁱⁿᵏ)
    num_periods = number_of_periods(n, 𝒯)
    @variable(m, demand_sink_surplus[𝒩ˢⁱⁿᵏ, i = 1:num_periods] >= 0)
    @variable(m, demand_sink_deficit[𝒩ˢⁱⁿᵏ, i = 1:num_periods] >= 0)
end
