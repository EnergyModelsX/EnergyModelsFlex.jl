# [MinUpDownTimeNode](@id nodes-minupdowntimenode)

[`MinUpDownTimeNode`](@ref) is a specialized [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) type that introduces unit commitment logic including minimum up and down time constraints. It is useful for modeling dispatchable power plants or technologies where operation must adhere to minimum runtime constraints.

!!! tip "See example"
    This node is included in an [example](@ref examples-flexible_demand) to demonstrate flexible demand.


## [Introduced type and its fields](@id nodes-minupdowntimenode-fields)

The [`MinUpDownTimeNode`](@ref) extends the capabilities of a [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) with binary status tracking and time-dependent logical constraints. It is implemented using integer variables to model on/off behavior and operational transitions.

The fields of a [`MinUpDownTimeNode`](@ref) are:

- **`id`**:\
  Identifier or name for the node.
- **`cap::TimeProfile`**:\
  The upper bound on installed capacity over time.\
  This field constrains the operational capacity and is required.
- **`opex_var::TimeProfile`**:\
  Variable operating expenses per unit of utilized capacity, enforced through the `cap_use` variable.
- **`opex_fixed::TimeProfile`**:\
  Fixed operating expenses applied per installed capacity unit and investment period.
- **`input::Dict{<:Resource,<:Real}`**:\
  Resource definitions with conversion factors for input flows.
- **`output::Dict{<:Resource,<:Real}`**:\
  Resource definitions with conversion factors for output flows.
- **`minUpTime::Real`**:\
  Minimum number of operational periods the unit must remain on after being started.
- **`minDownTime::Real`**:\
  Minimum number of operational periods the unit must remain off after being stopped.
- **`minCapacity::Real`**:\
  Minimum power output when the unit is on.
- **`maxCapacity::Real`**:\
  Maximum power output when the unit is on (usually aligned with `cap`).
- **`data::Vector{<:Data}`**:\
  Optional metadata (e.g., emissions or investment data). This is initialized to an empty array by default.

!!! tip
    The fields `minUpTime` and `minDownTime` are defined in terms of operational period durations and should be consistent with the time granularity of the model.

!!! warning "Compatible time structure"
    Note that this node cannot be used with `OperationalScenarios` or `RepresentativePeriods`.


## [Mathematical description](@id nodes-minupdowntimenode-math)

[`MinUpDownTimeNode`](@ref) introduces integer-based logic and sequencing constraints, in addition to standard flow and capacity formulations of [`NetworkNode`](@ref)s.

### [Variables](@id nodes-minupdowntimenode-math-var)

In addition to variables used in a [`NetworkNode`](@ref):

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{emissions\_node}``](@ref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

The following binary variables are introduced for unit commitment behavior:

- ``\texttt{on\_off}[n, t] \in \{0,1\}``:\
  Indicates if the unit is operating during time step $t$.
- ``\texttt{onswitch}[n, t] \in \{0,1\}``:\
  Indicates a startup at time step $t$.
- ``\texttt{offswitch}[n, t] \in \{0,1\}``:\
  Indicates a shutdown at time step $t$.

### [Constraints](@id nodes-minupdowntimenode-math-con)

In addition to the standard constraints for [`NetworkNode`](@extref EnergyModelsBase nodes-network_node), [`MinUpDownTimeNode`](@ref) implements the following:


#### Standard constraints

The following standard constraints are implemented for a [`NetworkNode`](@extref
EnergyModelsBase nodes-network_node) node.  [`NetworkNode`](@ref) nodes utilize
the declared method for all nodes 𝒩.  The constraint functions are called
within the function [`create_node`](@extref EnergyModelsBase.create_node).
Hence, if you do not have to call additional functions, but only plan to include
a method for one of the existing functions, you do not have to specify a new
[`create_node`](@extref EnergyModelsBase.create_node) method.

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_flow_in`:

  ```math
  \texttt{flow\_in}[n, t, p] = inputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in inputs(n)
  ```

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

- `constraints_capacity`

  - **On/off transition logic:**

    ```math
    \texttt{on\_off}[n, t] =
    \texttt{on\_off}[n, t_{prev}] - \texttt{offswitch}[n, t] + \texttt{onswitch}[n, t]
    ```

  - **Mutual exclusivity of on/off switching:**

    ```math
    \texttt{onswitch}[n, t] + \texttt{offswitch}[n, t] \leq 1
    ```

  - **Minimum up time:**

    ```math
    \sum_{\tau = t+1}^{t+M-1} \texttt{onswitch}[n, \tau] \leq 1
    ```

      and

    ```math
    \texttt{offswitch}[n, t] \leq 1 - \sum_{\tau = t+1}^{t+M-1} \texttt{onswitch}[n, \tau]
    ```

  - **Minimum down time:**

    ```math
    \sum_{\tau = t+1}^{t+N-1} \texttt{offswitch}[n, \tau] \leq 1
    ```

    and

    ```math
    \texttt{onswitch}[n, t] \leq 1 - \sum_{\tau = t+1}^{t+N-1} \texttt{offswitch}[n, \tau]
    ```

  - **Capacity conditional on on/off status:**

    ```math
    \texttt{cap\_use}[n, t] \leq \texttt{on\_off}[n, t] \cdot n.maxCapacity
    ```

    ```math
    \texttt{cap\_use}[n, t] \geq \texttt{on\_off}[n, t] \cdot n.minCapacity
    ```

  - **Upper bound by installed capacity:**

    ```math
    \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
    ```

  - **Installed capacity fixed to defined value:**

    ```math
    \texttt{cap\_inst}[n, t] = capacity(n, t)
    ```

  !!! warning "Mixed-integer complexity"
      The `MinUpDownTimeNode` introduces binary variables and logical constraints that make the model a **Mixed-Integer Linear Program (MILP)**. This may significantly increase solve time and model complexity.
