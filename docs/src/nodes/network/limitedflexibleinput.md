# [LimitedFlexibleInput node](@id nodes-limitedflexibleinput)

[`LimitedFlexibleInput`](@ref) nodes are a specialized form of [`NetworkNode`](@ref)s that support multiple input resources with a fixed output structure, but **limit** how much each individual input can contribute to the total inflow. This is particularly useful for modeling constraints such as fuel blend caps, quality requirements, or policy-imposed input fractions.

## [Introduced type and its fields](@id nodes-limitedflexibleinput-fields)

The [`LimitedFlexibleInput`](@ref) node builds on the [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) implementation by adding an additional `limit` field, which restricts the **fractional contribution** of each input [`Resource`](@ref) to the total input flow.

The fields of a [`LimitedFlexibleInput`](@ref) node are:

- **`id`**:\
  The name or identifier of the node.
- **`cap::TimeProfile`**:\
  The installed capacity profile over time.\
  This sets the upper bound on `cap_use`, which is used in capacity-related constraints.
- **`opex_var::TimeProfile`**:\
  Variable operating expenses applied per unit of output.
- **`opex_fixed::TimeProfile`**:\
  Fixed operating expenses applied per unit of installed capacity and investment period duration.
- **`limit::Dict{<:Resource,<:Real}`**:\
  A dictionary that sets the maximum share each input resource can contribute to the **total inflow**.

  !!! note "Total inflow dependency"
      The limit applies **relative to the total inflow**, not to the output or installed capacity. This makes it suitable for mix-based constraints, such as resource quota obligations.

  !!! warning "Input limits must be non-zero"
      If a resource is listed in `input` but not in `limit`, it is treated as **unconstrained**. Ensure that all input resources you wish to constrain are included in the `limit` dictionary.

- **`input::Dict{<:Resource,<:Real}`**:\
  Input resources and their conversion factors.
- **`output::Dict{<:Resource,<:Real}`**:\
  Output resources and their conversion factors.
- **`data::Vector{<:Data}`**:\
  Optional metadata for investment and emissions modeling.

!!! tip
    The `limit` field can be used to enforce regulatory blending requirements (e.g., max 30% coal in a hybrid boiler), or to simulate physical limitations such as combustion chamber design.


## [Mathematical description](@id nodes-limitedflexibleinput-math)

[`LimitedFlexibleInput`](@ref) nodes extend the standard [`NetworkNode`](@ref) constraint set by introducing resource-specific limits on the input mix.

### [Variables](@id nodes-limitedflexibleinput-math-var)

Like all [`NetworkNode`](@ref)s, the following optimization variables are used:

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

#### Standard constraints

The following standard constraints are implemented for a [`NetworkNode`](@extref
EnergyModelsBase nodes-network_node) node.  [`NetworkNode`](@ref) nodes utilize
the declared method for all nodes 𝒩.  The constraint functions are called
within the function [`create_node`](@extref EnergyModelsBase.create_node).
Hence, if you do not have to call additional functions, but only plan to include
a method for one of the existing functions, you do not have to specify a new
[`create_node`](@extref EnergyModelsBase.create_node) method.

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
      The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@ref man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given investment period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex\_var(n, t) \times \texttt{cap\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@ref scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified data of the nodes, see above.


#### Additional constraints

- `constraints_flow_in`

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

    This constraint ensures that the contribution of resource $p$ is limited to a maximum fraction defined in the `limit` field.
