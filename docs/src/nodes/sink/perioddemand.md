# [PeriodDemandSink node](@id nodes-perioddemandsink)

[`PeriodDemandSink`](@ref) nodes represent flexible demand sinks where demand must be fulfilled within defined periods (*e.g.* daily or weekly), rather than in each individual operational time step.
A *demand period* is a consecutive range of operational periods, that together will model, *e.g.*, a day, a week or comparable.

This node can, *e.g.*, be combined with [`MinUpDownTimeNode`](@ref), to allow production to be moved to the time of the day when it is cheapest because of, *e.g.*, energy or production costs.

!!! tip "Example"
    This node is included in an *[example](@ref examples-flexible_demand)* to demonstrate flexible demand.

!!! warning "TimeStructure for node"
    This node requires considerations of the operational time structure and the chosen demand period duration.
    Irregular durations may cause misalignment of shifted loads, especially if the field `period_duration` does not align with the chosen [`SimpleTimes`](@extref TimeStruct.SimpleTimes) structure representing the operational periods.

!!! warning "`PeriodDemandSink` and `EnergyModelsGUI`"
    Some of the fields of this node cannot be represented in `EnergyModelsGUI`.
    The reason for that limitation is that `EnergyModelsGUI` does not yet support partitions of `TimePeriod`s.
    `EnergyModelsGUI` can still be utilized for all other fields.

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
  In addition, it is crucial that the sum of both values in each demand period is larger than 0 to avoid an unconstrained model.

  !!! warning "Chosen values"
      The implementation for the demand period is relative to the chosen duration of a strategic period while the demand period deficit and surplus is scaled to a strategic period in the calculation.

- **`input::Dict{<:Resource,<:Real}`**:\
  The field `input` includes [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.\
  All values have to be non-negative.
- **`data::Vector{<:ExtensionData}`**:\
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

- **`period_duration::TimeProfile`**:\
  Defines the total duration of the demand periods.
  For instance, if the duration of 1 of the operational time structure is 1 hour and `period_duration = FixedProfile(24)`, then each demand period spans one day.
  The demand of this node (for a given day, see below) must then be filled on a daily basis, without any restrictions on *when* during the day the demand must be filled given the available capacity.\
  Due to a constructor, it can either be specified as number (the same duration in all demand periods), as a vector (varying duration of each demand period), or as a time profile (*e.g.*, varying period durations due to varying operational time structures).
  It cannot be specified as `OperationalProfile`.

- **`period_demand::TimeProfile`**:\
  The total demand to be met during each demand period.
  The length of this time profile should match the number of demand periods (*e.g.*, days) in the time structure.
  If the time structure represents one year with hourly resolution and the demand periods correspond to a day, this time profile must then have 365 elements.\
  It cannot be specified as `OperationalProfile`.

  It is best to utilize the [`PartitionProfile`](@extref TimeStruct.PartitionProfile) type if the demand is varying.
  If it is constant, you can also utilize [`StrategicProfile`](@extref TimeStruct.StrategicProfile), [`RepresentativeProfile`](@extref TimeStruct.RepresentativeProfile), or [`ScenarioProfile`](@extref TimeStruct.ScenarioProfile), depending on your chosen time structure.

  !!! warning "Time consistency"
      Ensure that the `period_demand` time profile length aligns with the periods specified by `period_duration`.
      Mismatches can lead to indexing errors or inconsistent demand enforcement.

These fields are at the 3ʳᵈ and 4ᵗʰ position below the field `cap` as shown in [`PeriodDemandSink`](@ref).

## [Mathematical description](@id nodes-perioddemandsink-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with parantheses.

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

[`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink) nodes declare in addition several variables through dispatching on the method [`EnergyModelsBase.variables_element()`](@ref) for including constraints for deficits and surplus for individual demand periods.

- ``\texttt{demand\_sink\_surplus}[n, t_pd]``:\
  Surplus of energy delivered beyond the required `period_demand` in demand period `t_pd` .
- ``\texttt{demand\_sink\_deficit}[n, t_pd]``:\
  Deficit of energy delivered relative to the `period_demand` in demand period `t_pd` .

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

The function `constraints_capacity` is extended with a new method to account for the calculation of the period demand deficit and surplus.

The overall balance is modified as

```math
\texttt{cap\_use}[n, t] + \texttt{sink\_deficit}[n, t] = \texttt{cap\_inst}[n, t]
```

while operational period surplus ``\texttt{sink\_surplus}[n, t]`` is fixed to 0.

The surplus and deficit of the demand period can then be calculated as

```math
\begin{aligned}
\texttt{demand\_sink\_deficit}[n, t_{pd}] + & \sum_{t \in t_{pd}} \texttt{​cap\_use}[n, t] \times duration(t) = \\
& \texttt{demand\_sink\_surplus}[n, t_{pd}] + period\_demand(n, t_{pd})
\end{aligned}
```

where ``t_{pd}`` is the demand period consisting of a set of operational periods.

As a consequence, `constraints_opex_var` requires as well a new method as we only consider the deficit within a complete period:

```math
\begin{aligned}
\texttt{opex\_var}[n, t_{inv}] = & \sum_{t_{pd} ∈ periods(t_{inv})}(\texttt{demand\_sink\_surplus}[n, t_{pd}] \times \texttt{surplus\_penalty}(n, t_{pd}) + {}\\
& \phantom{\sum_{t_{pd} ∈ periods(t_{inv})}(} \texttt{demand\_sink\_deficit}[n, t_{pd}] \times \texttt{deficit\_penalty}(n, t_{pd})) \times {} \\
& scale\_op\_sp(t_{inv}, first(t_{pd})) / duration(first(t_{pd}))
\end{aligned}
```

!!! note "`scale_op_sp` and `duration`"
    The function [`scale_op_sp(t_inv, t)`](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and investment periods including the `duration` of each operational period.
    It hence must be divided by the `duration` of the first operational period to avoid including the duration of the operational period.
