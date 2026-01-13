# [CapacityCostLink](@id links-CapacityCostLink)

[`CapacityCostLink`](@ref) links model the transport of energy between two nodes with capacity-dependent operational costs applied to a specified resource.
Unlike standard [`Direct`](@extref EnergyModelsBase.Direct) links, they enable cost modeling based on maximum capacity utilization over defined time periods.
This is useful for applications such as transmission networks, pipelines, or interconnectors where usage fees scale with peak capacity demands.

In addition, they only allow the transport of a single, specified [`Resource`](@extref EnergyModelsBase.Resource).

## [Introduced type and its fields](@id links-CapacityCostLink-fields)

[`CapacityCostLink`](@ref) is implemented as equivalent to an abstract type [`Link`](@extref EnergyModelsBase.Link).
Hence, it utilizes the same functions declared in `EnergyModelsBase`.

!!! warning "Application of the link"
    The current implementation is not very flexible with respect to the chosen time structure.
    Specifically, if you use [`OperationalScenarios`](@extref TimeStruct.OperationalScenarios), [`RepresentativePeriods`](@extref TimeStruct.RepresentativePeriods), or differing operational structures within your [`TwoLevel`](@extref TimeStruct.TwoLevel), you must be careful when choosing the parameter `cap_price_periods`.

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
  !!! note "Different formulations"
      The current implementation of links does not provide another formulation.
      Our aim is in a later stage to allow the user to switch fast through different formulations to increase or decrese the complexity of the model.

### [Additional fields](@id links-CapacityCostLink-fields-new)

The following additional fields are included for [`CapacityCostLink`](@ref) links:

- **`cap::TimeProfile`** :\
  The maximum transport capacity of the link for the `cap_resource`.
  If the link should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`cap_price::TimeProfile`** :\
  The price per unit of maximum capacity usage over the sub-periods.
  This value is averaged over sub-periods as defined by `cap_price_periods`.
  All values have to be non-negative.
- **`cap_price_periods::Int64`** :\
  The number of sub-periods within a year for which the capacity cost is calculated.
  This allows modeling of varying peak demands across seasons.
  The value must be positive.

  !!! tip "Number of sub-periods"
      For investment periods with many operational periods, consider increasing the number of `cap_price_periods`.
      The [`CapacityCostLink`](@ref) capacity constraints couple operational periods and can significantly increase solve time.
      Splitting the horizon into multiple sub-periods reduces this coupling and often makes the problem much easier to solve.
      In some cases, this also means using more than one capacity price period even if capacity costs occur only annually in reality, depending on model size and complexity.

- **`cap_resource::Resource`** :\
  The [`Resource`](@extref EnergyModelsBase.Resource) for which capacity-dependent costs are applied.
  This `Resource` is the only transported `Resource` by a [`CapacityCostLink`](@ref).
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

- ``\texttt{ccl\_cap\_use\_max}[l, t_{sub}]``: Maximum capacity usage in sub-period ``t_{sub}`` for link ``l``.
- ``\texttt{ccl\_cap\_use\_cost}[l, t_{sub}]``: Operational cost in sub-period ``t_{sub}`` for link ``l``.

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
\texttt{link\_in}[l, t, cap\_resource(l)] \leq \texttt{ccl\_cap\_use\_max}[l, t_{sub}]
```

The capacity cost is calculated as:

```math
\texttt{ccl\_cap\_use\_cost}[l, t_{sub}] = \texttt{ccl\_cap\_use\_max}[l, t_{sub}] \times \overline{cap\_price}(l, t_{sub})
```

where ``\overline{cap\_price}`` is the average capacity price over the sub-period.

Finally, costs are aggregated to each strategic period:

```math
\texttt{link\_opex\_var}[l, t_{inv}] = \sum_{t_{sub} \in t_{inv}} \texttt{ccl\_cap\_use\_cost}[l, t_{sub}]
```

In addition, the energy flow of the constrained resource should not exceed the maximum pipe capacity, which is included through the following constraint:

```math
\texttt{flow\_in}[l, t, cap\_resource(l)] \leq \texttt{link\_cap\_inst}[l, t]
```
