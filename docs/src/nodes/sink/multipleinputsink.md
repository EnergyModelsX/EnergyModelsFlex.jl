# [MultipleInputSink node](@id nodes-mul_in_sink)

[`MultipleInputSink`](@ref) nodes are [`Sink`](@extref EnergyModelsBase.Sink) nodes that allow the use of multiple energy carriers (resources) to satisfy a single demand.
Each input resource has a conversion factor, and their combined contribution must meet the demand.

## [Introduced type and its fields](@id nodes-mul_in_sink-fields)

The [`MultipleInputSink`](@ref) node extends the [`Sink`](@extref EnergyModelsBase.Sink) functionality to support multiple simultaneous energy inputs with equivalent service delivery. This is useful for modeling technologies such as hybrid heating systems or multi-fuel industrial boilers.

The fields of a [`MultipleInputSink`](@ref) node are given as:

- **`id`**:\
  The field `id` is only used for providing a name to the node.
- **`cap::TimeProfile`**:\
  The installed capacity corresponds to the nominal demand of the node.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`penalty::Dict{Symbol,<:TimeProfile}`**:\
  The penalty dictionary is used for providing penalties for soft constraints to allow for both over and under delivering the demand.\
  It must include the fields `:surplus` and `:deficit`.
  In addition, it is crucial that the sum of both values is larger than 0 to avoid an unconstrained model.
- **`input::Dict{<:Resource,<:Real}`**:\
  The field `input` includes [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.\
  All values have to be non-negative.
- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is used for both providing `EmissionsData` and additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used.
  !!! note
      The field `data` is not required as we include a constructor when the value is excluded.
  !!! danger "Using `CaptureData`"
      As a `Sink` node does not have any output, it is not possible to utilize [`CaptureData`](@extref EnergyModelsBase.CaptureData).
      If you still plan to specify it, you will receive an error in the model building.

## [Mathematical description](@id nodes-mul_in_sink-math)

[`MultipleInputSink`](@ref) nodes introduce a modified flow-in constraint to aggregate contributions from multiple energy carriers, each adjusted by their specific conversion factor.

### [Variables](@id nodes-mul_in_sink-math-var)

#### [Standard variables](@id nodes-mul_in_sink-math-var-stand)

The [`MultipleInputSink`](@ref) nodes utilize all standard variables from a `Sink` node, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{sink\_surplus}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{sink\_deficit}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

It does not add any additional variables.

### [Constraints](@id nodes-mul_in_sink-math-con)

The following sections omit the direct inclusion of the vector of [`MultipleInputSink`](@ref) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`MultipleInputSink`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all investment periods).

#### [Standard constraints](@id nodes-mul_in_sink-math-con-stand)

[`MultipleInputSink`](@ref) utilize in general the standard constraints that are implemented for a [`Sink`](@extref EnergyModelsBase.Sink) node as described in the *[documentaiton of `EnergyModelsBase`](@extref EnergyModelsBase nodes-sink-math-con)*.
These standard constraints are:

- `constraints_capacity`:

  ```math
  \texttt{cap\_use}[n, t] + \texttt{sink\_deficit}[n, t] = \texttt{cap\_inst}[n, t] + \texttt{sink\_surplus}[n, t]
  ```

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

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
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified additional data, see above.

The function `constraints_flow_in` receives a new method to account for that the individual resources can be used interchangeably:

```math
\sum_{p \in P} \frac{\texttt{inflow}[n,t,p]}{inputs(n,p)}=\texttt{cap\_use}[n,t]
```

The total effective input from all resources (accounting for their conversion factors) must equal the capacity used to meet demand.

!!! tip "Conversion factors"
    The input resource values in ``\texttt{flow\_in}`` are divided by their conversion factors to normalize their contribution toward demand fulfillment.
