# [CapacityCostLink](@id links-CapacityCostLink)

[`CapacityCostLink`](@ref) links model the transport of energy between two nodes with capacity-dependent operational costs applied to a specified resource.
Unlike standard [`Direct`](@extref EnergyModelsBase.Direct) links, they enable cost modeling based on maximum capacity utilization over defined time periods.
This is useful for applications such as transmission networks, pipelines, or interconnectors where usage fees scale with peak capacity demands.

## [Introduced type and its fields](@id links-CapacityCostLink-fields)

[`CapacityCostLink`](@ref) is implemented as equivalent to an abstract type [`Link`](@extref EnergyModelsBase.Link).
Hence, it utilizes the same functions declared in `EnergyModelsBase`.

### [Standard fields](@id links-CapacityCostLink-fields-stand)

[`CapacityCostLink`](@ref) has the following standard fields, equivalent to a [`Direct`](@extref EnergyModelsBase.Direct) link:

- **`id`** :\
  The field `id` is only used for providing a name to the link.
- **`from::Node`** :\
  The node from which there is flow into the link.
- **`to::Node`** :\
  The node to which there is flow out of the link.
- **`formulation::Formulation`** :\
  The used formulation of links.
  If not specified, a `Linear` link is assumed.

### [Additional fields](@id links-CapacityCostLink-fields-new)

The following additional fields are included for [`CapacityCostLink`](@ref) links:

- **`cap::TimeProfile`** :\
  The maximum capacity of the link for the `cap_resource`.
  If the link should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`cap_price::TimeProfile`** :\
  The price per unit of maximum capacity usage over the sub-periods.
  This value is averaged over sub-periods as defined by `cap_price_periods`.
- **`cap_price_periods::Int64`** :\
  The number of sub-periods within a year for which the capacity cost is calculated.
  This allows modeling of varying peak demands across seasons.
- **`cap_resource::Resource`** :\
  The resource for which capacity-dependent costs are applied.
  This resource must flow through the link and costs are only associated with this resource.
- **`data::Vector{<:ExtensionData}`**:\
  An entry for providing additional data to the model.
  In the current version, it is used for providing additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used.
  !!! note "Constructor for `CapacityCostLink`"
      The field `data` is not required as we include constructors when the value is excluded.

## [Mathematical description](@id links-CapacityCostLink-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id links-CapacityCostLink-math-var)

#### [Standard variables](@id links-CapacityCostLink-math-var-stand)

[`CapacityCostLink`](@ref) utilizes standard variables from the [`Link`](@extref EnergyModelsBase.Link) type, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*:

- [``\texttt{link\_in}``](@extref man-opt_var-flow)
- [``\texttt{link\_out}``](@extref man-opt_var-flow)
- [``\texttt{link\_cap\_inst}``](@extref man-opt_var-cap)

#### [Additional variables](@id links-CapacityCostLink-math-var-add)

Two additional variables track capacity utilization and associated costs over sub-periods:

- ``\texttt{max\_cap\_use\_sub\_period}[l, t_{sub}]``: Maximum capacity usage in sub-period ``t_{sub}`` for link ``l``.\
- ``\texttt{cap\_cost\_sub\_period}[l, t_{sub}]``: Operational cost in sub-period ``t_{sub}`` for link ``l``.\

### [Constraints](@id links-CapacityCostLink-math-con)

#### [Standard constraints](@id links-CapacityCostLink-math-con-stand)

The applied standard constraint for capacity installed is:

```math
\texttt{link\_cap\_inst}[l, t] = capacity(l, t)
```

and the no-loss constraint

```math
\texttt{link\_out}[l, t, p] = \texttt{link\_in}[l, t, p] \quad \forall p \in inputs(l)
```

#### [Additional constraints](@id links-CapacityCostLink-math-con-add)

All additional constraints are created within a new method for the function [`create_link`](@extref EnergyModelsBase.create_link).

The capacity utilization constraint tracks the maximum usage within each sub-period:

```math
\texttt{link\_in}[l, t, cap\_resource(l)] \leq \texttt{max\_cap\_use\_sub\_period}[l, t_{sub}]
```

The capacity cost is calculated as:

```math
\texttt{cap\_cost\_sub\_period}[l, t_{sub}] = \texttt{max\_cap\_use\_sub\_period}[l, t_{sub}] \times \overline{cap\_price}(l, t_{sub})
```

where ``\overline{cap\_price}`` is the average capacity price over the sub-period.

Finally, costs are aggregated to each strategic period:

```math
\texttt{link\_opex\_var}[l, t_{inv}] = \sum_{t_{sub} \in t_{inv}} \texttt{cap\_cost\_sub\_period}[l, t_{sub}]
```

In addition, the energy flow of the constrained resource should not exceed the maximum pipe capacity, which is included through the following constraint:

```math
\texttt{flow\_in}[l, t, cap\_resource(l)] \leq \texttt{link\_cap\_inst}[l, t]
```
