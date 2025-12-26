# [Inflexible source node](@id nodes-inflexiblesource)

Inflexible sources represent energy sources with fixed capacity usage that cannot be varied operationally.
Unlike flexible sources (e.g., like [`RefSource`](@extref EnergyModelsBase.RefSource)) that can adjust output based on system needs, inflexible sources operate at their full installed capacity in every operational period.
Examples include must-run generation units or baseload power plants with operational constraints.

The [`InflexibleSource`](@ref) is implemented as a simplified variant of the [`RefSource`](@extref EnergyModelsBase.RefSource) that enforces constant capacity utilization.

## [Introduced type and its fields](@id nodes-inflexiblesource-fields)

The [`InflexibleSource`](@ref) extends the [`Source`](@extref EnergyModelsBase.Source) type with fixed operational characteristics.

### [Standard fields](@id nodes-inflexiblesource-fields-stand)

The [`InflexibleSource`](@ref) has the same standard fields as the [`RefSource`](@extref EnergyModelsBase.RefSource):

- **`id`**:\
  The field `id` is only used for providing a name to the node.
  This is similar to the approach utilized in `EnergyModelsBase`.
- **`cap::TimeProfile`**:\
  The installed capacity corresponds to the forced capacity usage of the node.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable [`:cap_use`](@extref EnergyModelsBase man-opt_var-cap).
  Hence, it is directly related to the specified `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.
- **`opex_fixed::TimeProfile`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of a strategic period as outlined on *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`output::Dict{<:Resource, <:Real}`**:\
  The field `output` includes [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  In the case of a non-dispatchable renewable energy source, `output` should always include your *electricity* resource. In practice, you should use a value of 1.\
  All values have to be non-negative.
- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is only relevant for additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) is used.
  !!! note
      The field `data` is not required as we include a constructor when the value is excluded.

  !!! warning "Using `CaptureData`"
      If you plan to use [`CaptureData`](@extref EnergyModelsBase.CaptureData) for a [`InflexibleSource`](@ref InflexibleSource) node, it is crucial that you specify your CO₂ resource in the `output` dictionary.
      The chosen value is however **not** important as the CO₂ flow is automatically calculated based on the process utilization and the provided process emission value.
      The reason for this necessity is that flow variables are declared through the keys of the `output` dictionary.
      Hence, not specifying CO₂ as `output` resource results in not creating the corresponding flow variable and subsequent problems in the design.

      We plan to remove this necessity in the future.
      As it would most likely correspond to breaking changes, we have to be careful to avoid requiring major changes in other packages.

## [Mathematical description](@id nodes-inflexiblesource-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-inflexiblesource-math-var)

#### [Standard variables](@id nodes-inflexiblesource-math-var-stand)

The inflexible source node type utilize all standard variables from the [`RefSource`](@extref EnergyModelsBase.RefSource) node type, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`.

### [Constraints](@id nodes-inflexiblesource-math-con)

The following sections omit the direct inclusion of the vector of inflexible source nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N^{\text{inflexiblesource}\_source}`` for all [`InflexibleSource`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

#### [Standard constraints](@id nodes-inflexiblesource-math-con-stand)

Inflexible source nodes utilize in general the standard constraints described on *[Constraint functions](@extref EnergyModelsBase man-con)*.
In fact, they use the same `create_node` function as a [`RefSource`](@extref EnergyModelsBase.RefSource) node.
These standard constraints are:

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_flow_out`:

  ```math
  \texttt{flow\_out}[n, t, p] =
  outputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in outputs(n) \setminus \{\text{CO}_2\}
  ```

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times \texttt{cap\_inst}[n, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variables ``\texttt{cap\_inst}`` are declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacities in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex\_var(n, t) \times \texttt{cap\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and strategic periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:
  This function is only called for specified additional data, see above.

The function `constraints_capacity` is extended with a new method for inflexible source nodes to allow the fixing of the ``\texttt{cap\_use}[n, t]`` to the variable ``\texttt{cap\_inst}[n, t]``
(only replacing inequality with equality compared to [`RefSource`](@extref EnergyModelsBase.RefSource)).
It now includes the individual constraint:

```math
\texttt{cap\_use}[n, t] = \texttt{cap\_inst}[n, t]
```

This function still calls the subfunction `constraints_capacity_installed` to limit the variable ``\texttt{cap\_inst}[n, t]`` or provide capacity investment options.

#### [Additional constraints](@id nodes-inflexiblesource-math-con-add)

[`InflexibleSource`](@ref) nodes do not add additional constraints.
