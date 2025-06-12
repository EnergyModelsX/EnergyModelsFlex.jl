# [ContinuousMultipleInputSinkStrat node](@id nodes-continuousmultipleinputsinkstrat)

[`ContinuousMultipleInputSinkStrat`](@ref) is a [`Sink`](@ref) node that models flexible energy service demands that can be met by a combination of multiple input resources. Unlike [`BinaryMultipleInputSinkStrat`](@ref) binary input switches, this node allows **continuous input blending**, where the optimal fraction of each resource is determined by the optimization.

!!! warning
    Due to that the added optimization variables are named the same, [`BinaryMultipleInputSinkStrat`](@ref) and [`ContinuousMultipleInputSinkStrat`](@ref) can not be used at the same time, i.e. in the same optimization model.

## [Introduced type and its fields](@id nodes-continuousmultipleinputsinkstrat-fields)

The [`ContinuousMultipleInputSinkStrat`](@ref) node extends the [`AbstractMultipleInputSinkStrat`](@ref EnergyModelsFlex.AbstractMultipleInputSinkStrat) interface and enables simultaneous use of multiple input energy carriers to meet demand, with input shares defined as **continuous decision variables** across strategic periods.

The fields of a [`ContinuousMultipleInputSinkStrat`](@ref) node are:

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
      As a `Sink` node does not have any output, it is not possible to utilize `CaptureData`.
      If you still plan to specify it, you will receive an error in the model building.

!!! note
    This node supports process emissions if emission data is included in the `data` field.

## [Mathematical description](@id nodes-continuousmultipleinputsinkstrat-math)

The [`ContinuousMultipleInputSinkStrat`](@ref) introduces **strategic-period-based input fractions**, used to proportionally allocate resource inflows across each operational period. This allows for continuous blending of energy carriers in a flexible and cost-optimal way.

### [Variables](@id nodes-continuousmultipleinputsinkstrat-math-var)

In addition to standard [`Sink`](@ref) variables:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{sink\_surplus}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{sink\_deficit}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

the following variables are introduced:

- ``\texttt{input\_frac\_strat}[n, t_{inv}, p]``:\
  Fraction of the demand satisfied by input resource $p$ in strategic period $t_{inv}$.
  The fraction is limited between 0 and 1.
- ``\texttt{sink\_surplus\_p}[n, t, p]``:\
  Surplus of input resource ``p`` in node ``n`` in operational period ``t``.
- ``\texttt{sink\_deficit\_p}[n, t, p]``:\
  Deficit of input resource ``p`` in node ``n`` in operational period ``t``.



### [Constraints](@id nodes-continuousmultipleinputsinkstrat-math-con)

#### Standarad constraints

The following standard constraints are implemented for a [`Sink`](@extref
EnergyModelsBase.Sink) node.  `Sink` nodes utilize the declared method for all
nodes 𝒩.  The constraint functions are called within the function
[`create_node`](@extref EnergyModelsBase.create_node).  Hence, if you do not
have to call additional functions, but only plan to include a method for one of
the existing functions, you do not have to specify a new `create_node`-method.


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
      The function [``scale\_op\_sp(t_{inv}, t)``](@ref scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified additional data, see above.


#### Additional constraints

This is the constraints differing from the regular [`Sink`](@extref EnergyModelsBase nodes-sink)-node defined in `EnergyModelsBase`.

- `constraints_capacity`:

  !!! note
      Note that this method only contains a call to `EMB.constraints_capacity_installed`, since the constraint is moved to `constraints_flow_in`, described below.

- `constraints_flow_in`:

  - **Aggregate resource flow balances:**

    ```math
    \sum_{p \in P^{in}} \frac{\texttt{flow\_in}[n, t, p]}{inputs(n, p)} =
    \texttt{cap\_use}[n, t]
    ```

  - **Link flow to binary input choice:**

    ```math
    \frac{\texttt{flow\_in}[n, t, p]}{inputs(n, p)} +
    \texttt{sink\_deficit\_p}[n, t, p] =
    \texttt{cap\_inst}[n, t] \cdot \texttt{input\_frac\_strat}[n, t_{sp}, p] +
    \texttt{sink\_surplus\_p}[n, t, p]
    ```

  - **Only one input active per strategic period:**

    ```math
    \sum_{p \in P^{in}} \texttt{input\_frac\_strat}[n, t_{inv}, p] = 1
    ```

  - **Link per-resource surplus/deficit to total:**

    ```math
    \sum_{p \in P^{in}} \texttt{sink\_surplus\_p}[n, t, p] =
    \texttt{sink\_surplus}[n, t]
    ```

    ```math
    \sum_{p \in P^{in}} \texttt{sink\_deficit\_p}[n, t, p] =
    \texttt{sink\_deficit}[n, t]
    ```


  !!! note "Implicit surplus/deficit balance"
      The constraint

      ```math
      \texttt{cap\_use}[n, t] + \texttt{sink\_deficit}[n, t] =
      \texttt{cap\_inst}[n, t] + \texttt{sink\_surplus}[n, t]
      ```
      is implicitly enforced via the `flow_in` and `input_frac_strat` constraints, see the [`Sink`](@extref EnergyModelsBase nodes-sink) documentation in `EnergyModelsBase`.

  !!! tip "Use case"
      Use this node for **fuel-flexible** technologies where optimal blending between input sources (e.g. electricity and biomass) is required over longer-term strategic decisions.
