# [Pay-as-produced PPA energy source node](@id nodes-payasproducedppa)

Pay-as-produced PPA energy sources generate electricity from intermittent energy sources with a specific constraint on the variable operating expenses (OPEX) such that curtailed energy is also included in the OPEX.
This node models a Power Purchase Agreement (PPA) contract.

## [Introduced type and its fields](@id nodes-payasproducedppa-fields)

The [`PayAsProducedPPA`](@ref) is implemented as a subtype of [`AbstractNonDisRES`](@extref EnergyModelsRenewableProducers.AbstractNonDisRES) extending the existing functionality defined in [`EnergyModelsRenewableProducers`](@extref).

The fields of a [`PayAsProducedPPA`](@ref) are:

- **`id`**:\
  The field `id` is used for providing a name to the node.
  This is similar to the approach utilized in `EnergyModelsBase`.

- **`cap::TimeProfile`**:\
  The installed capacity corresponds to the nominal capacity of the node.
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.

- **`profile::TimeProfile`**:\
  The profile is used as a multiplier to the installed capacity to represent the maximum actual capacity in each operational period.
  The profile should be provided as `OperationalProfile` or at least as `RepresentativeProfile`.
  In addition, all values should be in the range ``[0, 1]``.

- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable `:cap_use`.
  Hence, they are directly related to the specified `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.

- **`opex_fixed::TimeProfile`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of a strategic period as outlined on [*Utilize `TimeStruct`*](@extref EnergyModelsBase how_to-utilize_TS).
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.

- **`output::Dict{<:Resource, <:Real}`**:\
  The field `output` includes `Resource`s with their corresponding conversion factors as dictionaries.
  In the case of a pay-as-produced PPA energy source, `output` should include your *electricity* resource.
  In practice, you should use a value of 1.

- **`data::Vector{Data}`**:
  An entry for providing additional data to the model.
  In the current version, it is only relevant for additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) is used.
  !!! note "Constructor for `PayAsProducedPPA`"
      The field `data` is not required as we include a constructor when the value is excluded.

## [Mathematical description](@id nodes-payasproducedppa-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-payasproducedppa-math-var)

The [`PayAsProducedPPA`](@ref) node types utilize all variables from the [`AbstractNonDisRES`](@extref EnergyModelsRenewableProducers.AbstractNonDisRES) node type, as described on the page *[Optimization variables](@extref EnergyModelsRenewableProducers nodes-nondisres-math-var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`.
- [``\texttt{curtailment}``](@extref EnergyModelsRenewableProducers nodes-nondisres-math-add)

!!! note
    Non-dispatchable renewable energy source nodes are not compatible with `CaptureData`.
    Hence, you can only provide [`EmissionsProcess`](@extref EnergyModelsBase.EmissionsProcess) to the node.
    It is our aim to include the potential for construction emissions in a latter stage

### [Constraints](@id nodes-payasproducedppa-math-con)

The following sections omit the direct inclusion of the vector of [`PayAsProducedPPA`](@ref) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`PayAsProducedPPA`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all investment periods).

#### [Standard constraints](@id nodes-payasproducedppa-math-con-stand)

[`PayAsProducedPPA`](@ref) utilize in general the standard constraints that are implemented for a [`AbstractNonDisRES`](@extref EnergyModelsRenewableProducers nodes-nondisres) node as described in the *[documentation of `EnergyModelsRenewableProducers`](@extref EnergyModelsRenewableProducers nodes-nondisres-math-con)*.
These standard constraints are:

- `constraints_capacity`:
  This function utilizes the [method introduced for `AbstractNonDisRes` nodes](@extref EnergyModelsRenewableProducers nodes-nondisres-math-con-stand) to include the variable ``\texttt{curtailment}``:

  ```math
  \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
  ```

  and

  ```math
  \texttt{cap\_use}[n, t] + \texttt{curtailment}[n, t] =
  profile(n, t) \times \texttt{cap\_inst}[n, t]
  ```


- `constraints_capacity_installed`:
  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/) to incorporate the potential for investments.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_flow_out`:
  ```math
  \texttt{flow\_out}[n, t, p] =
  outputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p ∈ outputs(n) \setminus \{\text{CO}_2\}
  ```

- `constraints_opex_fixed`:
  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times \texttt{cap\_inst}[n, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variables ``\texttt{cap\_inst}`` are declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacities in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_data`:
  This function is only called for specified data of the pay-as-produced PPA energy source, see above.

The function `constraints_opex_var` is extended with a new method to include the variable operating expenses also for the variable ``\texttt{curtailment}``:

```math
\texttt{opex\_var}[n, t_{inv}] = \sum_{t ∈ t_{inv}} (\texttt{cap\_use}[n, t] + \texttt{curtailment}[n, t]) \times opex\_var(n, t) \times scale\_op\_sp(t_{inv}, t)
```

This change allows to model systems corresponding to the current regulation in which renewable power generation from solar PV or wind is paid, independently of the actual production.

!!! tip "The function `scale_op_sp`"
    The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and strategic periods.
    It also takes into account potential operational scenarios and their probability as well as representative periods.
