# [StratPeriodDemandSink node](@id nodes-stratperioddemandsink)

[`StratPeriodDemandSink`](@ref) nodes represent flexible demand sinks where the demand must be fulfilled on an annual level while individual demand periods can be specified to incorporate lower and upper bounds on the demand satisfaction per demand period.
A *demand period* is a consecutive range of operational periods, that together will model, *e.g.*, a day, a week or comparable.

!!! warning "TimeStructure for node"
    This node requires considerations of the operational time structure and the chosen demand period duration.
    Irregular durations may cause misalignment of shifted loads, especially if the field `period_duration` does not align with the chosen [`SimpleTimes`](@extref TimeStruct.SimpleTimes) structure representing the operational periods.

!!! warning "`StratPeriodDemandSink` and `EnergyModelsGUI`"
    Some of the fields of this node cannot be represented in `EnergyModelsGUI`.
    The reason for that limitation is that `EnergyModelsGUI` does not yet support partitions of `TimePeriod`s.
    `EnergyModelsGUI` can still be utilized for all other fields.

## [Introduced type and its fields](@id nodes-stratperioddemandsink-fields)

The [`StratPeriodDemandSink`](@ref) node is a subtype of [`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink) which reutilizes the variables and some utility functions.
It provides however new capacity and variable operating expenses constraints.

### [Standard fields](@id nodes-stratperioddemandsink-fields-stand)

The standard fields are given as:

- **`id`**:\
  The field `id` is only used for providing a name to the node.
- **`cap::TimeProfile`**:\
  The maximum amount of demand that can be met in each operational period.\
  A warning is printed if the sum of the scaled demand in a strategic period is lower than the strategic demand.
- **`penalty::Dict{Symbol,<:TimeProfile}`**:\
  The penalty dictionary is used for providing penalties for soft constraints to allow for both over and under delivering the demand.\
  It must include the fields `:surplus` and `:deficit`.
  In addition, it is crucial that the sum of both values in each demand period is larger than 0 to avoid an unconstrained model.

  !!! warning "Chosen values"
      The same value is chosen for violations of the lower and upper bounds for the individual demand periods and the strategic demand.

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

### [Additional fields](@id nodes-stratperioddemandsink-fields-new)

[`StratPeriodDemandSink`](@ref EnergyModelsFlex.StratPeriodDemandSink)s require additional fields to specify both the periods and their respective demands:

- **`strat_demand::TimeProfile`**:\
  The total demand within a strategic period relative to a duration of 1 of a strategic period.
  If a duration of 1 corresponds to a year, this value will specify the annual demand that must be satisfied.\
  It must be indexable by a strategic period, that is it can be specified as `FixedProfile`, `StrategicProfile` or `StrategicStochasticProfile`.

- **`period_duration::TimeProfile`**:\
  Defines the total duration of the demand periods.
  For instance, if the duration of 1 of the operational time structure is 1 hour and `period_duration = FixedProfile(24)`, then each demand period spans one day.
  Due to a constructor, it can either be specified as number (the same duration in all demand periods), as a vector (varying duration of each demand period), or as a time profile (*e.g.*, varying period durations due to varying operational time structures).\
  It cannot be specified as `OperationalProfile`.

- **`period_min::TimeProfile`** and **`period_max::TimeProfile`**:\
  The fraction of annual demand that must be at least or can be at most satisfied within a demand period.
  The length of this time profile should match the number of demand periods (*e.g.*, days) in the time structure.\
  They cannot be specified as `OperationalProfile`.
  A warning is printed if either the sum of `period_min` is larger than 1 (guaranteeing a surplus penalty introduction) or if the sum of `period_max` is smaller than 1 (guaranteeing a deficit penalty introduction)

!!! tip "Profiles for `period_min` and `period_max`"
    It is best to utilize the [`PartitionProfile`](@extref TimeStruct.PartitionProfile) type if the fractions are varying in the individual demand periods.
    If they are constant, you can also utilize [`StrategicProfile`](@extref TimeStruct.StrategicProfile), [`RepresentativeProfile`](@extref TimeStruct.RepresentativeProfile), or [`ScenarioProfile`](@extref TimeStruct.ScenarioProfile), depending on your chosen time structure.

!!! warning "Time consistency"
    Ensure that the `period_min` and `period_max` time profiles length aligns with the periods specified by `period_duration`.
    Mismatches can lead to indexing errors or inconsistent demand enforcement.

These fields are at the 3ʳᵈ and 4ᵗʰ position below the field `cap` as shown in [`StratPeriodDemandSink`](@ref).

## [Mathematical description](@id nodes-stratperioddemandsink-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with parantheses.

### [Variables](@id nodes-stratperioddemandsink-math-var)

#### [Standard variables](@id nodes-stratperioddemandsink-math-var-stand)

The [`StratPeriodDemandSink`](@ref) nodes utilize all standard variables from a `Sink` node, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{sink\_surplus}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{sink\_deficit}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

#### [Additional variables](@id nodes-stratperioddemandsink-math-add)

[`StratPeriodDemandSink`](@ref) nodes declare in addition several variables through dispatching on the method [`EnergyModelsBase.variables_element()`](@ref) for including constraints for deficits and surplus for individual resources as well as what the fraction satisfied by each resource on both the level of demand periods (as introduced by the method for [`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink)) and strategic periods (introduced through a dedicated methods for [`StratPeriodDemandSink`](@ref)):

- ``\texttt{demand\_sink\_surplus}[n, t_pd]``:\
  Surplus of energy delivered beyond the required `period_max` fraction in demand period `t_pd` .
- ``\texttt{demand\_sink\_deficit}[n, t_pd]``:\
  Deficit of energy delivered relative to the required `period_min` fraction in demand period `t_pd` .
- ``\texttt{demand\_sink\_strat\_surplus}[n, t_inv]``:\
  Surplus of energy delivered beyond the required `strat_demand` in strategic period `t_inv` .
- ``\texttt{demand\_sink\_strat\_deficit}[n, t_inv]``:\
  Deficit of energy delivered relative to the required `strat_demand` in strategic period `t_inv` .

### [Constraints](@id nodes-stratperioddemandsink-math-con)

The following sections omit the direct inclusion of the vector of [`StratPeriodDemandSink`](@ref) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`StratPeriodDemandSink`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all investment periods).

#### [Standard constraints](@id nodes-stratperioddemandsink-math-con-stand)

[`StratPeriodDemandSink`](@ref) utilize in general the standard constraints that are implemented for a [`Sink`](@extref EnergyModelsBase nodes-sink) node as described in the *[documentaiton of `EnergyModelsBase`](@extref EnergyModelsBase nodes-sink-math-con)*.
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

The deficit and surplus in a demand period can then be calculated as

```math
\begin{aligned}
\sum_{t \in t_{pd}} \texttt{​cap\_use}[n, t] \times duration(t) + {} & \texttt{demand\_sink\_deficit}[n, t_{pd}]  \geq \\
& \frac{period\_demand\_min(n, t_{pd}) \times strategic\_demand(n, t_{inv})}{multiple(first(t_{pd})) / duration\_strat(t_{inv})} \\
\sum_{t \in t_{pd}} \texttt{​cap\_use}[n, t] \times duration(t) \geq {} & \texttt{demand\_sink\_surplus}[n, t_{pd}] + {} \\
& \frac{period\_demand\_max(n, t_{pd}) \times strategic\_demand(n, t_{inv})}{multiple(first(t_{pd})) / duration\_strat(t_{inv})}
\end{aligned}
```

where ``t_{pd}`` is the demand period consisting of a set of operational periods and ``t_{inv}`` is the strategic period.

!!! note "`multiple` and `duration_strat`"
    The division by ``multiple(first(t_{pd}))/duration\_strat(t_{inv})`` is introduced for scaling the strategic demand to duration 1 of an operational period.
    The function [`scale_op_sp(t_inv, t)`](@extref EnergyModelsBase.scale_op_sp) cannot be used here as it includes as well the probability.

As a consequence, `constraints_opex_var` requires as well a new method as we consider the deficit within a strategic period and penalize violation of the period demand bounds:

```math
\begin{aligned}
\texttt{opex\_var}[n, t_{inv}] = {} &
\texttt{demand\_sink\_strat\_surplus}[n, t_{inv}] \times \texttt{surplus\_penalty}(n, t_{inv}) + {}\\
&  \texttt{demand\_sink\_strat\_deficit}[n, t_{inv}] \times \texttt{deficit\_penalty}(n, t_{inv}) + {}\\
& \sum_{t_{pd} ∈ periods(t_{inv})}(\texttt{demand\_sink\_surplus}[n, t_{pd}] \times \texttt{surplus\_penalty}(n, t_{pd}) + {}\\
&\phantom{\sum_{t_{pd} ∈ periods(t_{inv})}(} \texttt{demand\_sink\_deficit}[n, t_{pd}] \times \texttt{deficit\_penalty}(n, t_{pd})) \times {}\\
& scale\_op\_sp(t_{inv}, first(t_{pd})) / duration(first(t_{pd}))
\end{aligned}
```

!!! note "`scale_op_sp` and `duration`"
    The function [`scale_op_sp(t_inv, t)`](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and investment periods including the `duration` of each operational period.
    It hence must be divided by the `duration` of the first operational period to avoid including the duration of the operational period.
