# [MinUpDownTimeNode](@id nodes-minupdowntimenode)

[`MinUpDownTimeNode`](@ref) is a specialized [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) type that introduces unit commitment logic including minimum up and down time constraints.
It is useful for modeling dispatchable power plants or technologies where operation must adhere to minimum runtime constraints.

!!! tip "Example"
    This node is included in an [example](@ref examples-flexible_demand) to demonstrate flexible demand.

## [Introduced type and its fields](@id nodes-minupdowntimenode-fields)

The [`MinUpDownTimeNode`](@ref) extends the capabilities of a [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) with binary status tracking and time-dependent logical constraints. It is implemented using integer variables to model on/off behavior and operational transitions.

### [Standard fields](@id nodes-minupdowntimenode-fields-stand)

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
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of an investment period as outlined on *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`input::Dict{<:Resource,<:Real}`** and **`output::Dict{<:Resource,<:Real}`**:\
  Both fields describe the `input` and `output` [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.\
  CO₂ cannot be directly specified, *i.e.*, you cannot specify a ratio.
  If you use [`CaptureData`](@extref EnergyModelsBase.CaptureData), it is however necessary to specify CO₂ as output, although the ratio is not important.\
  All values have to be non-negative.
- **`data::Vector{<:Data}`**:\
  Optional metadata (*e.g.*, emissions or investment data). This is initialized to an empty array by default.

  !!! note "Constructor for `MinUpDownTimeNode`"
      The field `data` is not required as we include a constructor when the value is excluded.

  !!! warning "Using `CaptureData`"
      If you plan to use [`CaptureData`](@extref EnergyModelsBase.CaptureData) for a [`MinUpDownTimeNode`](@ref) node, it is crucial that you specify your CO₂ resource in the `output` dictionary.
      The chosen value is however **not** important as the CO₂ flow is automatically calculated based on the process utilization and the provided process emission value.
      The reason for this necessity is that flow variables are declared through the keys of the `output` dictionary.
      Hence, not specifying CO₂ as `output` resource results in not creating the corresponding flow variable and subsequent problems in the design.

      We plan to remove this necessity in the future.
      As it would most likely correspond to breaking changes, we have to be careful to avoid requiring major changes in other packages.

!!! warning "Compatible time structure"
    Note that this node cannot be used with `OperationalScenarios` or `RepresentativePeriods`.

### [Additional fields](@id nodes-minupdowntimenode-fields-new)

[`MinUpDownTimeNode`](@ref) nodes add four additional fields compared to a [`NetworkNode`](@extref EnergyModelsBase nodes-network_node):

- **`minUpTime::Real`**:\
  Minimum number of operational periods the unit must remain on after being started.
- **`minDownTime::Real`**:\
  Minimum number of operational periods the unit must remain off after being stopped.
- **`minCapacity::Real`**:\
  Minimum power output when the unit is on. The value must be larger than zero.
- **`maxCapacity::Real`**:\
  Maximum power output when the unit is on (usually aligned with `cap`).
  The value must not be less than `minCapacity`.

!!! tip
    The fields `minUpTime` and `minDownTime` are defined in terms of operational period durations and should be consistent with the time granularity of the model.

## [Mathematical description](@id nodes-minupdowntimenode-math)

[`MinUpDownTimeNode`](@ref) introduces integer-based logic and sequencing constraints, in addition to standard flow and capacity formulations of [`NetworkNode`](@extref EnergyModelsBase nodes-network_node)s.

### [Variables](@id nodes-minupdowntimenode-math-var)

In addition to variables used in a [`NetworkNode`](@extref EnergyModelsBase nodes-network_node):

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

The following sections omit the direct inclusion of the vector of [`MinUpDownTimeNode`](@ref) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`MinUpDownTimeNode`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all investment periods).

#### [Standard constraints](@id nodes-minupdowntimenode-math-con-stand)

[`MinUpDownTimeNode`](@ref) utilize in general the standard constraints that are implemented for a [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) node as described in the *[documentation of `EnergyModelsBase`](@extref EnergyModelsBase nodes-network_node-math-con)*.
These standard constraints are:

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

The function `constraints_capacity` receives a new method to handle the minimum up and down time constraints:

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
