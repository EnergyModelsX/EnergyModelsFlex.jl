# [LoadShiftingNode](@id nodes-loadshiftingnode)

[`LoadShiftingNode`](@ref) is a specialized [`Sink`](@ref) node that allows for **batch-wise load shifting**. It is designed for demand profiles where discrete production batches can be rescheduled within defined working shifts. This flexibility allows modeling of industrial processes that can shift load within operational constraints.

!!! warning
    This node is designed for **uniform timestep durations**. Irregular durations may cause misalignment of shifted loads.

!!! danger "Experimental node"
    The node is experimental and has in its current version a lot of prerequisites:
    - This node is designed for **uniform timestep durations**.
      Irregular durations may cause misalignment of shifted loads.
    - The node utilizes the indices of the operational period.
      It cannot be used with `OperationalScenarios` and `RepresentativePeriods`.
    Its application should be carefully evaluated.


## [Introduced type and its fields](@id nodes-loadshiftingnode-fields)

The [`LoadShiftingNode`](@ref) extends the basic [`Sink`](@ref) with load shifting logic based on indexed operational periods and discrete batch shifts.

The fields of a [`LoadShiftingNode`](@ref) are:

- **`id`**:\
  Identifier for the node.
- **`cap::TimeProfile`**:\
  The original, unshifted demand profile.
- **`penalty::Dict{Symbol,<:TimeProfile}`**:\
  Penalties for `:surplus` and `:deficit`, though not actively used in the load shifting formulation.
- **`input::Dict{<:Resource,<:Real}`**:\
  Resource inputs and their conversion factors.
- **`load_shift_times::Vector{<:Int}`**:\
  Indices of time steps where batches may be shifted from/to.
- **`load_shifts_per_period::Int`**:\
  Maximum number of batch shifts allowed within each load shifting group.
- **`load_shift_duration::Int`**:\
  Number of consecutive periods each load shift lasts.
- **`load_shift_magnitude::Real`**:\
  The magnitude of demand shifted per period in a batch.
- **`load_shift_times_per_period::Int`**:\
  Number of time steps per shift group in which shifts may occur.
- **`data::Vector{Data}`**:\
  Optional metadata (e.g., emissions, investment data).

!!! warning
    This node is designed for **uniform timestep durations**. Irregular durations may cause misalignment of shifted loads.

!!! warning "No investments"
    Investments are not implemented for this node.


## [Mathematical description](@id nodes-loadshiftingnode-math)

[`LoadShiftingNode`](@ref) introduces integer and continuous variables to allow demand shifting across time, subject to batching, balance, and capacity constraints.

### [Variables](@id nodes-loadshiftingnode-math-var)

In addition to standard [`Sink`](@ref) variables:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{sink\_surplus}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{sink\_deficit}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

the node introduces:

- ``\texttt{load\_shift\_from}[n, t]``:\
  Integer variable for number of batches shifted *away from* operational period $t$.
  This variable is only defined for the operational periods given by the vector `load_shift_times`.
- ``\texttt{load\_shift\_to}[n, t]``:\
  Integer variable for number of batches shifted *to* operational period $t$.
  This variable is only defined for the operational periods given by the vector `load_shift_times`.
- ``\texttt{load\_shifted}[n, t]``:\
  Continuous variable representing the net capacity added or removed via load shifting at operational period $t$.

### [Constraints](@id nodes-loadshiftingnode-math-con)

#### Standard constraints

- `constraints_flow_in`:

  ```math
  \texttt{flow\_in}[n, t, p] =
  inputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in inputs(n)
  ```

  !!! tip "Multiple inputs"
      The constrained above allows for the utilization of multiple inputs with varying ratios.
      it is however necessary to deliver the fixed ratio of all inputs.

- `constraints_opex_fixed`:\
  The current implementation fixes the fixed operating expenses of a sink to 0.

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = 0
  ```

- `constraints_opex_var`:

  ```math
  \begin{aligned}
  \texttt{opex\_var}[n, t_{inv}] = & \\
    \sum_{t \in t_{inv}} & surplus\_penalty(n, t) \times \texttt{sink\_surplus}[n, t] + \\ &
    deficit\_penalty(n, t) \times \texttt{sink\_deficit}[n, t] \times \\ &
    scale\_op\_sp(t_{inv}, t)
  \end{aligned}
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@ref scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified additional data, see above.


#### Additional constraints

The following constraints are implemented:

- `constraints_capacity`

  - **Group-level limits on load shifts:**

    For each group of ``n.load\_shift\_times\_per\_period`` steps:

    ```math
    \sum \texttt{load\_shift\_from}[n, \text{group}] \leq n.load\_shifts\_per\_period
    ```

    ```math
    \sum \texttt{load\_shift\_to}[n, \text{group}] \leq n.load\_shifts\_per\_period
    ```

    ```math
    \sum \texttt{load\_shift\_from}[n, \text{group}] =
    \sum \texttt{load\_shift\_to}[n, \text{group}]
    ```

    This ensures no net addition or removal of demand—only rescheduling.

  - **Define shifted load across duration:**

    For each time $t$ in ``n.load\_shift\_times``, and for each period $t+i$ in ``n.load\_shift\_duration``:

    ```math
    \texttt{load\_shifted}[n, t+i] =
    n.load\_shift\_magnitude \cdot
    (\texttt{load\_shift\_to}[n, t] - \texttt{load\_shift\_from}[n, t])
    ```

  - **Zero shifted load outside batch duration periods:**

    ```math
    \texttt{load\_shifted}[n, t] = 0
    \qquad \forall t \notin \text{shifted batch times}
    ```

  - **Final demand with shifted load:**

    ```math
    \texttt{cap\_use}[n, t] = \texttt{cap\_inst}[n, t] + \texttt{load\_shifted}[n, t]
    ```

  !!! tip "Batch interpretation"
      Each shift moves a *batch* of demand of fixed size and duration. Shifted batches cannot be split or partially allocated—this preserves discrete process modeling.

  !!! note "Integer programming"
      Load shifting relies on integer variables (`load_shift_from`, `load_shift_to`), making this a **mixed-integer problem** (MIP).
