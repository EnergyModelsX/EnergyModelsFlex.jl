# [PeriodDemandSink node](@id nodes-perioddemandsink)

[`PeriodDemandSink`](@ref) nodes represent flexible demand sinks where demand must be fulfilled within defined periods (*e.g.* daily or weekly), rather than in each individual operational time step.
**A *period* is thus a consecutive range of operational periods, that together will model, *e.g.*, a day or a week etc.**

This node can, *e.g.*, be combined with [`MinUpDownTimeNode`](@ref), to allow production to be moved to the time of the day when it is cheapest because of, *e.g.*, energy or production costs.

!!! tip "Example"
    This node is included in an [example](@ref examples-flexible_demand) to demonstrate flexible demand.

!!! warning "TimeStructure for node"
    This node is designed for **uniform or repetitive duration of operational periods**.
    Irregular durations may cause misalignment of shifted loads, especially if the field `period_length` does not align with the chosen [`SimpleTimes`](@extref TimeStruct.SimpleTimes) structure representing the operational periods.

## [Introduced type and its fields](@id nodes-perioddemandsink-fields)

The [`PeriodDemandSink`](@ref) node extends the [`Sink`](@extref EnergyModelsBase.Sink) functionality by introducing aggregated demand over fixed-length periods.
This is useful for representing flexible loads like electric vehicle charging or industrial batch processes, where exact timing of delivery is flexible.

!!! note "Abstract supertype"
    `PeriodDemandSink` is defined as a subtype of [`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink), and constraints are put on this supertype.
    By subtyping `AbstractPeriodDemandSink`, you can easily extend the functionality of this node.

### [Standard fields](@id nodes-perioddemandsink-fields-stand)

The standard fields are given as:

- **`id`**:\
  The field `id` is only used for providing a name to the node.
- **`cap::TimeProfile`**:\
  The maximum amount of demand that can be met in each operational period.
  This acts as a capacity on instantaneous delivery, while `period_demand` enforces total energy delivered within the chosen period.
- **`penalty::Dict{Symbol,<:TimeProfile}`**:\
  The penalty dictionary is used for providing penalties for soft constraints to allow for both over and under delivering the demand.\
  It must include the fields `:surplus` and `:deficit`.
  In addition, it is crucial that the sum of both values is larger than 0 to avoid an unconstrained model.

  !!! warning "Chosen values"
      The current implementation does not represent the proper cost due to the summation.
      Instead, you must consider the duration of an operational period and the field `period_length` when providing a value.
      In this case, the value should be multiplied by ``1/period\_length(n) \times duration(t)``.

- **`input::Dict{<:Resource,<:Real}`**:\
  The field `input` includes [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.\
  All values have to be non-negative.
- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is used for both providing `EmissionsData` and additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used.
  !!! note "Included constructor"
      The field `data` is not required as we include a constructor when the value is excluded.
  !!! danger "Using `CaptureData`"
      As a `Sink` node does not have any output, it is not possible to utilize [`CaptureData`](@extref EnergyModelsBase.CaptureData).
      If you still plan to specify it, you will receive an error in the model building.

!!! note
    Unlike [`RefSink`](@extref EnergyModelsBase.RefSink), the delivery of demand here is flexible within each demand period.
    This is helpful for modeling demand that can shift within a day or week.

### [Additional fields](@id nodes-perioddemandsink-fields-new)

[`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink)s require additional fields to specify both the periods and their respective demands:

- **`period_length::Int`**:\
  Defines how many operational periods are included in a single demand period.\
  For instance, if the duration of the operational periods is 1 hour and `period_length = 24`, then each demand period spans one day.
  The demand of this node (for a given day, see below) must then be filled on a daily basis, without any restrictions on *when* during the day the demand must be filled.

- **`period_demand::Vector{<:Real}`**:\
  The total demand to be met during each demand period. The length of this vector should match the number of periods (*e.g.*, days) in the time structure. If the time structure represents on year with hourly resolution, this vector must then have 365 elements.

  !!! warning "Time consistency"
      Ensure that the `period_demand` vector length aligns with the total time horizon divided by `period_length`. Mismatches can lead to indexing errors or inconsistent demand enforcement.

These fields are at the 2ⁿᵈ and 3ʳᵈ position below the field `id` as shown in [`PeriodDemandSink`](@ref).

## [Mathematical description](@id nodes-perioddemandsink-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-perioddemandsink-math-var)

#### [Standard variables](@id nodes-perioddemandsink-math-var-stand)

The [`PeriodDemandSink`](@ref) nodes utilize all standard variables from a `Sink` node, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{sink\_surplus}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{sink\_deficit}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

#### [Additional variables](@id nodes-perioddemandsink-math-add)

[`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink) nodes declare in addition several variables through dispatching on the method [`EnergyModelsBase.variables_node()`](@ref) for including constraints for deficits and surplus for individual resources as well as what the fraction satisfied by each resource.
These variables are for a [`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink) node ``n`` in demand periods ``i``:

- ``\texttt{demand\_sink\_surplus}[n, i]``:\
  Surplus of energy delivered beyond the required `period_demand` in demand period `i`.
- ``\texttt{demand\_sink\_deficit}[n, i]``:\
  Deficit of energy delivered relative to the `period_demand` in period `i`.

### [Constraints](@id nodes-perioddemandsink-math-con)

The following sections omit the direct inclusion of the vector of [`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all investment periods).

#### [Standard constraints](@id nodes-perioddemandsink-math-con-stand)

[`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink) utilize in general the standard constraints that are implemented for a [`Sink`](@extref EnergyModelsBase nodes-sink) node as described in the *[documentaiton of `EnergyModelsBase`](@extref EnergyModelsBase nodes-sink-math-con)*.
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

- `constraints_data`:\
  This function is only called for specified additional data, see above.

The function `constraints_capacity` is extended with a new method to account for the calculation of the period demand deficit and surplus through:

```math
\texttt{cap\_use}[n, t] + \texttt{sink\_deficit}[n, t] = \texttt{cap\_inst}[n, t] + \texttt{sink\_surplus}[n, t]
```

```math
\begin{aligned}
\texttt{demand\_sink\_deficit}[n, i] + & \sum_{t \in P_i} \texttt{​cap\_use}[n,t]   = \\
& \texttt{demand\_sink\_surplus}[n, i] + period\_demand(n, i)
\end{aligned}
```

where ``P_i`` is the set of operational periods in demand period ``i``.

As a consequence, `constraints_opex_var` requires as well a new method as we only consider the deficit within a complete period:

```math
\begin{aligned}
\texttt{opex\_var}[n, t_{inv}] = \sum_{t ∈ t_{inv}}(& \texttt{demand\_sink\_surplus}[n, i_t] \times \texttt{surplus\_penalty}(n, t) + \\
& \texttt{demand\_sink\_deficit}[n, i_t] \times \texttt{deficit\_penalty}(n, t)) \times \\
& scale\_op\_sp(t_{inv}, t)
\end{aligned}
```

where ``i_t`` is the period index such that ``t \in P_{i_t}``.

!!! tip "The function `scale_op_sp`"
    The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and investment periods.
    It also takes into account potential operational scenarios and their probability as well as representative periods.
