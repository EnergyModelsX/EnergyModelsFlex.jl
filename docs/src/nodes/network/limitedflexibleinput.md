# [LimitedFlexibleInput node](@id nodes-limitedflexibleinput)

[`LimitedFlexibleInput`](@ref) nodes are a specialized form of [`NetworkNode`](@extref EnergyModelsBase nodes-network_node)s that support multiple input resources with a fixed output structure, but **limit** how much each individual input can contribute to the total inflow.
This is particularly useful for modeling constraints such as fuel blend caps, quality requirements, or policy-imposed input fractions.

## [Introduced type and its fields](@id nodes-limitedflexibleinput-fields)

The [`LimitedFlexibleInput`](@ref) node builds on the [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) implementation by adding an additional `limit` field, which restricts the **fractional contribution** of each input [`Resource`](@extref EnergyModelsBase.Resource) to the total input flow.

### [Standard fields](@id nodes-limitedflexibleinput-fields-stand)

The standard fields are given as:

- **`id`**:\
  The field `id` is only used for providing a name to the node.
- **`cap::TimeProfile`**:\
  The installed capacity corresponds to the nominal capacity of the node.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable [`:cap_use`](@extref EnergyModelsBase man-opt_var-cap).
  Hence, it is directly related to the specified `input` and `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.
- **`opex_fixed::TimeProfile`**:\
  Fixed operating expenses applied per unit of installed capacity and investment period duration.
- **`input::Dict{<:Resource,<:Real}`** and **`output::Dict{<:Resource,<:Real}`**:\
  Both fields describe the `input` and `output` [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.\
  CO₂ cannot be directly specified, *i.e.*, you cannot specify a ratio.
  If you use [`CaptureData`](@extref EnergyModelsBase.CaptureData), it is however necessary to specify CO₂ as output, although the ratio is not important.\
  All values have to be non-negative.
- **`data::Vector{<:Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is used for both providing `EmissionsData` and additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used.

  !!! note "Constructor for `LimitedFlexibleInput`"
      The field `data` is not required as we include a constructor when the value is excluded.

  !!! warning "Using `CaptureData`"
      If you plan to use [`CaptureData`](@extref EnergyModelsBase.CaptureData) for a [`LimitedFlexibleInput`](@ref) node, it is crucial that you specify your CO₂ resource in the `output` dictionary.
      The chosen value is however **not** important as the CO₂ flow is automatically calculated based on the process utilization and the provided process emission value.
      The reason for this necessity is that flow variables are declared through the keys of the `output` dictionary.
      Hence, not specifying CO₂ as `output` resource results in not creating the corresponding flow variable and subsequent problems in the design.

      We plan to remove this necessity in the future.
      As it would most likely correspond to breaking changes, we have to be careful to avoid requiring major changes in other packages.

### [Additional fields](@id nodes-limitedflexibleinput-fields-new)

[`LimitedFlexibleInput`](@ref) nodes add a single additional field compared to a [`NetworkNode`](@extref EnergyModelsBase nodes-network_node):

- **`limit::Dict{<:Resource,<:Real}`**:\
  A dictionary that sets the maximum share each input resource can contribute to the **total inflow**.
  `Resource`s which are specified in the `input` dictionary, but not in the `limit` dictionary will be treated as unconstrained.
  This corresponds to a value of ``1`` in the `limit` dictionary.
  All values should be in the range ``[0, 1]``.

  !!! tip
      The `limit` field can be used to enforce regulatory blending requirements (*e.g.*, max 30 % coal in a hybrid boiler), or to simulate physical limitations such as combustion chamber design.

  !!! note "Total inflow dependency"
      The limit applies **relative to the total inflow**, not to the output or installed capacity.
      This makes it suitable for mix-based constraints, such as resource quota obligations.

## [Mathematical description](@id nodes-limitedflexibleinput-math)

[`LimitedFlexibleInput`](@ref) nodes extend the standard [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) constraint set by introducing resource-specific limits on the input mix.

### [Variables](@id nodes-limitedflexibleinput-math-var)

Like all [`NetworkNode`](@extref EnergyModelsBase nodes-network_node)s, the following optimization variables are used:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex) \
  Variable operating expenses.
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex) \
  Fixed operating expenses.
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap) \
  Actual operational use of the node in time $t$.
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap) \
  Installed capacity at time $t$.
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow) \
  Flow of resource $p$ into node $n$ at time $t$.
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow) \
  Output flow of resource $p$ at time $t$.
- [``\texttt{emissions\_node}``](@ref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

### [Constraints](@id nodes-limitedflexibleinput-math-con)

The following sections omit the direct inclusion of the vector of [`LimitedFlexibleInput`](@ref) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`LimitedFlexibleInput`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all investment periods).

#### [Standard constraints](@id nodes-limitedflexibleinput-math-con-stand)

[`LimitedFlexibleInput`](@ref) utilize in general the standard constraints that are implemented for a [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) node as described in the *[documentation of `EnergyModelsBase`](@extref EnergyModelsBase nodes-network_node-math-con)*.
These standard constraints are:

- `constraints_capacity`:

  ```math
  \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
  ```

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
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
      The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given investment period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex\_var(n, t) \times \texttt{cap\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified data of the nodes, see above.

The function `constraints_flow_in` receives a new method to handle the input flow constraints:

- **Input/output balance (normalized):**

  ```math
  \sum_{p \in P^{in}} \frac{\texttt{flow\_in}[n, t, p]}{inputs(n, p)} =
  \texttt{cap\_use}[n, t]
  ```

  This constraint enforces a normalized energy balance between input resource flows and total utilized capacity.

- **Input share constraint per resource:**

  ```math
  \texttt{flow\_in}[n, t, p] \leq
  \left(\sum_{q \in P^{in}} \texttt{flow\_in}[n, t, q]\right) \cdot limit(n, p)
  ```

  This constraint ensures that the contribution of resource ``p`` is limited to a maximum fraction defined in the `limit` field.
