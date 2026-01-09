# [FlexibleOutput](@id nodes-FlexibleOutput)

The [`FlexibleOutput`](@ref) node models a conversion technology that can produce **multiple output resources** while sharing a **single capacity limit**.
In contrast to a standard [`NetworkNode`](@extref EnergyModelsBase.NetworkNode), the utilized capacity is defined by the **sum of all output flows**, scaled by their respective output conversion factors.

This formulation enables flexible allocation of production across several co-products (*e.g.*, multiple heat levels or energy carriers) while ensuring that total production remains consistent with the available capacity.

## [Introduced type and its fields](@id nodes-FlexibleOutput-fields)

The [`FlexibleOutput`](@ref) is a subtype of the [`NetworkNode`](@extref EnergyModelsBase.NetworkNode).
It reuses all standard `NetworkNode` functionality except for the output-flow formulation, which is extended to allow flexible output composition.

### [Standard fields](@id nodes-FlexibleOutput-fields-stand)

The standard fields of a [`FlexibleOutput`](@ref) node are given as:

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
- **`data::Vector{<:ExtensionData}`**:\
  An entry for providing additional data to the model.
  In the current version, it is used for both providing `EmissionsData` and additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used.
  !!! note "Constructor for `NewNetworkNode`"
      The field `data` is not required as we include a constructor when the value is excluded.

  !!! warning "Using `CaptureData`"
      If you plan to use [`CaptureData`](@extref EnergyModelsBase.CaptureData) for a [`NewNetworkNode`] node, it is crucial that you specify your CO₂ resource in the `output` dictionary.
      The chosen value is however **not** important as the CO₂ flow is automatically calculated based on the process utilization and the provided process emission value.
      The reason for this necessity is that flow variables are declared through the keys of the `output` dictionary.
      Hence, not specifying CO₂ as `output` resource results in not creating the corresponding flow variable and subsequent problems in the design.

      We plan to remove this necessity in the future.
      As it would most likely correspond to breaking changes, we have to be careful to avoid requiring major changes in other packages.

## [Mathematical description](@id nodes-FlexibleOutput-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-FlexibleOutput-math-var)

The [`FlexibleOutput`](@ref) node uses the standard `NetworkNode` optimization variables (see *[Optimization variables](@extref EnergyModelsBase man-opt_var)*):

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)

### [Constraints](@id nodes-FlexibleOutput-math-con)

The following sections omit the direct inclusion of the vector of flexible output nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N^{FlexibleOutput}`` for all [`FlexibleOutput`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

#### [Standard constraints](@id nodes-FlexibleOutput-math-con-stand)

[`FlexibleOutput`](@ref) nodes utilize in general the standard constraints described on *[Constraint functions](@extref EnergyModelsBase man-con)* for [`NetworkNode`](@extref EnergyModelsBase.NetworkNode)s, except for the output-flow constraint.

The following standard constraints apply:

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_capacity`:

  ```math
  \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
  ```

- `constraints_flow_in`:

  ```math
  \texttt{flow\_in}[n, t, p] = inputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in inputs(n)
  ```

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times
  \texttt{cap\_inst}[n, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}}
  opex\_var(n, t) \times \texttt{cap\_use}[n, t]
  \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and strategic periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_ext_data`:
  This function is only called if extension data are specified for the node.

The function `constraints_flow_out` is extended with a new method for flexible output nodes such that the outputs are flexible within their sum being the capacity usage of the node.

Let ``\mathcal{P}^{out}(n)`` denote the set of output resources of node ``n`` excluding CO₂, obtained through the function [`soutputs`](@extref EnergyModelsBase.outputs).
The implemented constraint is then given by

```math
\sum_{p \in \mathcal{P}^{out}(n)} \frac{\texttt{flow\_out}[n, t, p]}{outputs(n, p)} = \texttt{cap\_use}[n, t]
```

#### [Additional constraints](@id nodes-FlexibleOutput-math-con-add)

[`FlexibleOutput`](@ref) nodes do not introduce additional constraint functions beyond the flexible output-flow formulation described above.
