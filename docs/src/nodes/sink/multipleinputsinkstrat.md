# [AbstractMultipleInputSinkStrat node](@id nodes-mul_in_sink_strat)

[`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) are [`Sink`](@extref EnergyModelsBase.Sink) nodes that models flexible energy service demands that can be met by a combination of multiple input resources.
Unlike [`MultipleInputSink`](@ref ) nodes, we enforce that the ratio between the different input resources is the same in all operational periods of an investment period.
The [`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) introduces **strategic-period-based input fractions**, used to proportionally allocate resource inflows across each operational period.
This allows for continuous blending of energy carriers in a flexible and cost-optimal way.

!!! warning "InvestmentData"
    The current implementation does not allow for the incorporation of investment data as this would lead to bilinear constraints.

## [Introduced types and their fields](@id nodes-mul_in_sink_strat-fields)

We implement two types of [`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) nodes:

1. [`ContinuousMultipleInputSinkStrat`](@ref) and
2. [`BinaryMultipleInputSinkStrat`](@ref).

[`ContinuousMultipleInputSinkStrat`](@ref) allows for a continuous blend between the different input resources while [`BinaryMultipleInputSinkStrat`](@ref) requires that either one or the other resource is utilized.

!!! tip "Use cases"
    **[`ContinuousMultipleInputSinkStrat`](@ref)**:
    Use this node for **fuel-flexible** technologies where optimal blending between input sources (*e.g.*, electricity and biomass) is required over longer-term strategic decisions.

    **[`BinaryMultipleInputSinkStrat`](@ref)**:
    This node is ideal for modeling strategic switching between fuels where only one option can be used at a time (*e.g.*, policy-driven exclusivity, binary retrofitting, or fuel-type switching).

!!! warning "Binary enforcement"
    If you use [`BinaryMultipleInputSinkStrat`](@ref), you introduce binary decision variables, making it a **mixed-integer** optimization problem.
    Be aware of the increased computational complexity.

Both nodes have the same fields.
These fields are:

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
  !!! note "Included constructor"
      The field `data` is not required as we include a constructor when the value is excluded.
  !!! danger "Using `CaptureData`"
      As a `Sink` node does not have any output, it is not possible to utilize [`CaptureData`](@extref EnergyModelsBase.CaptureData).
      If you still plan to specify it, you will receive an error in the model building.

!!! note
    This node supports process emissions if emission data is included in the `data` field.

## [Mathematical description](@id nodes-mul_in_sink_strat-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-mul_in_sink_strat-math-var)

#### [Standard variables](@id nodes-mul_in_sink_strat-math-var-stand)

The [`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) nodes utilize all standard variables from a `Sink` node, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
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

#### [Additional variables](@id nodes-mul_in_sink_strat-math-add)

[`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) nodes declare in addition several variables through dispatching on the method [`EnergyModelsBase.variables_element()`](@ref) for including constraints for deficits and surplus for individual resources as well as what the fraction satisfied by each resource.
These variables are for an [`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) node ``n`` in operational period ``t``:

- ``\texttt{input\_frac\_strat}[n, t_{inv}, p]``:\
  Fraction of the demand satisfied by input resource ``p`` in strategic period ``t_{inv}``.
  The fraction is limited between 0 and 1 in the case of [`ContinuousMultipleInputSinkStrat`](@ref) and is binary in the case of [`BinaryMultipleInputSinkStrat`](@ref).
- ``\texttt{sink\_surplus\_p}[n, t, p]``:\
  Surplus of input resource ``p`` in node ``n`` in operational period ``t``.
- ``\texttt{sink\_deficit\_p}[n, t, p]``:\
  Deficit of input resource ``p`` in node ``n`` in operational period ``t``.

### [Constraints](@id nodes-mul_in_sink_strat-math-con)

The following sections omit the direct inclusion of the vector of [`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all investment periods).

#### [Standard constraints](@id nodes-mul_in_sink_strat-math-con-stand)

[`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) utilize in general the standard constraints that are implemented for a [`Sink`](@extref EnergyModelsBase nodes-sink) node as described in the *[documentation of `EnergyModelsBase`](@extref EnergyModelsBase nodes-sink-math-con)*.
These standard constraints are:

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

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

The function `constraints_capacity` is extended with a new method as we moved the capacity constraint to the function `constraints_flow_in` as outlined below.
As a consequence, it only calls the function `constraints_capacity_installed`.

The function `constraints_flow_in` is extended with a new method to account for the potential of supplying the demand with multiple resources.
The inlet overall flow balance is given by

```math
\sum_{p \in P^{in}} \frac{\texttt{flow\_in}[n, t, p]}{inputs(n, p)} =
\texttt{cap\_use}[n, t]
```

The inlet flow is linked to the binary choice and the capacity through the following function:

```math
\begin{aligned}
\frac{\texttt{flow\_in}[n, t, p]}{inputs(n, p)} + & \texttt{sink\_deficit\_p}[n, t, p] = \\
& capacity(n, {t_{inv}}) \times \texttt{input\_frac\_strat}[n, t_{inv}, p] + \texttt{sink\_surplus\_p}[n, t, p]
\end{aligned}
```

The variable ``\texttt{input\_frac\_strat}`` must sum up to one to avoid problems with the overall mass balance.

```math
\sum_{p \in P^{in}} \texttt{input\_frac\_strat}[n, t_{inv}, p] = 1
```

The sum of the individual surplus and deficits of each resource represent then subsequently the complete surplus and deficit.

```math
\begin{aligned}
\sum_{p \in P^{in}} \texttt{sink\_surplus\_p}[n, t, p] = & \texttt{sink\_surplus}[n, t] \\
\sum_{p \in P^{in}} \texttt{sink\_deficit\_p}[n, t, p] = & \texttt{sink\_deficit}[n, t] \\
\end{aligned}
```
