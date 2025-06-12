# [ActivationCostNode](@id nodes-activationcostnode)

[`ActivationCostNode`](@ref) is a specialized [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) that introduces unit commitment logic with additional fuel or resource costs incurred upon startup. It models technologies that consume extra input when switching on, such as combustion turbines or thermal boilers.

## [Introduced type and its fields](@id nodes-activationcostnode-fields)

The [`ActivationCostNode`](@ref) extends the standard [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) by incorporating binary unit commitment variables and explicit **activation costs** in the form of additional input resource usage during startup.

The fields of an [`ActivationCostNode`](@ref) are:

- **`id`**:\
  The field `id` is only used for providing a name to the node.
- **`cap::TimeProfile`**:\
  The installed capacity corresponds to the nominal capacity of the node.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable [`:cap_use`](@ref man-opt_var-cap).
  Hence, it is directly related to the specified `input` and `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.
- **`opex_fixed::TimeProfile`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of an investment period as outlined on *[Utilize `TimeStruct`](@ref how_to-utilize_TS)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`input::Dict{<:Resource,<:Real}`** and **`output::Dict{<:Resource,<:Real}`**:\
  Both fields describe the `input` and `output` [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.\
  CO₂ cannot be directly specified, *i.e.*, you cannot specify a ratio.
  If you use [`CaptureData`](@ref), it is however necessary to specify CO₂ as output, although the ratio is not important.\
  All values have to be non-negative.
- **`activation_time::Real`**:\
  Duration of activation effect (currently used to inform activation logic in customized formulations).
- **`activation_consumption::Dict{<:Resource,<:Real}`**:\
  Additional input resources required when the unit switches on.
- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is used for providing `EmissionsData`.
  <!-- and additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used. -->

  !!! warning "No investments"
      Note that investments are currently not implemented for this node.

  !!! note
      The field `data` is not required as we include a constructor when the value is excluded.

  !!! warning "Using `CaptureData`"
      If you plan to use [`CaptureData`](@ref) for a [`RefNetworkNode`](@ref) node, it is crucial that you specify your CO₂ resource in the `output` dictionary.
      The chosen value is however **not** important as the CO₂ flow is automatically calculated based on the process utilization and the provided process emission value.
      The reason for this necessity is that flow variables are declared through the keys of the `output` dictionary.
      Hence, not specifying CO₂ as `output` resource results in not creating the corresponding flow variable and subsequent problems in the design.

      We plan to remove this necessity in the future.
      As it would most likely correspond to breaking changes, we have to be careful to avoid requiring major changes in other packages.

!!! tip
    This node is useful when modeling generation or conversion units that consume startup fuel, such as gas turbines, diesel generators, or heating systems with preheat requirements.

!!! warning "Compatible time structure"
    Note that this node cannot be used with `OperationalScenarios` or `RepresentativePeriods`.

## [Mathematical description](@id nodes-activationcostnode-math)

[`ActivationCostNode`](@ref) introduces startup-aware constraints and binary control variables, alongside the standard flow and cost formulations of [`NetworkNode`](@ref)s.

### [Variables](@id nodes-activationcostnode-math-var)

In addition to common variables:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{emissions\_node}``](@ref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

the following **binary variables** are defined for unit commitment logic:

- ``\texttt{on\_off}[n, t] \in \{0,1\}``:\
  Binary status indicator for whether the unit is active in time period $t$.
- ``\texttt{onswitch}[n, t] \in \{0,1\}``:\
  Indicates that the unit is being turned on in time period $t$.
- ``\texttt{offswitch}[n, t] \in \{0,1\}``:\
  Indicates that the unit is being turned off in time period $t$.

### [Constraints](@id nodes-activationcostnode-math-con)

#### Standard constraints

The following standard constraints are implemented for a [`NetworkNode`](@extref
EnergyModelsBase nodes-network_node) node.  [`NetworkNode`](@ref) nodes utilize
the declared method for all nodes 𝒩.  The constraint functions are called
within the function [`create_node`](@extref EnergyModelsBase.create_node).
Hence, if you do not have to call additional functions, but only plan to include
a method for one of the existing functions, you do not have to specify a new
[`create_node`](@extref EnergyModelsBase.create_node) method.

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

  - **Unit commitment state transition** (ensures consistency across time):

    ```math
    \texttt{on\_off}[n, t] =
    \texttt{on\_off}[n, t_{prev}] - \texttt{offswitch}[n, t] + \texttt{onswitch}[n, t]
    ```
    For the first time step in each investment period, the last value of the previous period is used instead of $t_{prev}$.

    !!! warning "No investments"
        Note that investments are currently not implemented for this node.

  - **Operational capacity conditional on status:**

    ```math
    \texttt{cap\_use}[n, t] = \texttt{on\_off}[n, t] \cdot capacity(n, t)
    ```

    ```math
    \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
    ```

- `constraints_flow_in`

  - **Startup-adjusted input flow:**

    ```math
    \texttt{flow\_in}[n, t, p] =
    inputs(n, p) \cdot \texttt{cap\_use}[n, t] +
    activation\_consumption(n, p) \cdot \texttt{onswitch}[n, t]
    ```

    This models additional startup consumption, e.g., diesel or gas during ignition or ramp-up.

    !!! note "Activation logic"
        The field `activation_time` is not directly included in the constraint equations above but can be used in more advanced formulations where startup effects extend beyond a single time step.

    !!! warning "Binary complexity"
        Similar to [`MinUpDownTimeNode`](@ref), this node is a **mixed-integer** formulation and increases the complexity of the optimization model.
