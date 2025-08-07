# [Combustion node](@id nodes-combustion)

[`Combustion`](@ref) nodes are a variant of [`NetworkNode`](@extref EnergyModelsBase nodes-network_node)s that model fuel-based conversion processes where input energy is either transformed into useful outputs or lost as residual heat.
The node enforces a complete **energy balance**, with residual losses explicitly accounted for using a designated `heat_res` output.

!!! tip "Use cases"
    Use this node when modeling combustion or transformation technologies where energy losses are explicit (*e.g.*, boilers, engines, incinerators).
    It is especially valuable for modeling thermodynamic efficiencies or waste heat utilization.

## [Introduced type and its fields](@id nodes-combustion-fields)

The [`Combustion`](@ref) node is similar to [`LimitedFlexibleInput`](@ref), but includes an additional **energy conservation constraint**. It uses a dedicated resource (`heat_res`) to capture residual or waste heat.

### [Standard fields](@id nodes-combustion-fields-stand)

The standard fields are given as:

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
- **`data::Vector{<:Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is used for both providing `EmissionsData` and additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used.

  !!! note "Constructor for `Combustion`"
      The field `data` is not required as we include a constructor when the value is excluded.

  !!! warning "Using `CaptureData`"
      If you plan to use [`CaptureData`](@extref EnergyModelsBase.CaptureData) for a [`Combustion`](@ref) node, it is crucial that you specify your CO₂ resource in the `output` dictionary.
      The chosen value is however **not** important as the CO₂ flow is automatically calculated based on the process utilization and the provided process emission value.
      The reason for this necessity is that flow variables are declared through the keys of the `output` dictionary.
      Hence, not specifying CO₂ as `output` resource results in not creating the corresponding flow variable and subsequent problems in the design.

      We plan to remove this necessity in the future.
      As it would most likely correspond to breaking changes, we have to be careful to avoid requiring major changes in other packages.

### [Additional fields](@id nodes-combustion-fields-new)

[`Combustion`](@ref) nodes add two additional fields compared to a [`NetworkNode`](@extref EnergyModelsBase nodes-network_node):

- **`limit::Dict{<:Resource,<:Real}`**:\
  A dictionary specifying the maximum share that each input resource may contribute to total inflow.
  All values should be in the range ``[0, 1]``.
  `Resource`s which are specified in the `input` dictionary, but not in the `limit` dictionary will be treated as unconstrained.
  This corresponds to a value of ``1`` in the `limit` dictionary.
- **`heat_res::Resource`**:\
  The residual heat or loss resource used to close the energy balance.
  This resource must be in the `output` dictionary.
  The residual output defined by `heat_res` is not necessarily "useful" energy — it serves to account for efficiency losses or heat rejection in the energy balance.

  !!! warning "Correct definition of `heat_res`"
      It is essential that the resource defined in `heat_res` is also included in the `output` dictionary.
      If not, the residual balance constraint will not be well-formed and the model may fail.

## [Mathematical description](@id nodes-combustion-math)

The [`Combustion`](@ref) node enforces a mass/energy balance including residual energy loss.
It also supports input blending restrictions using the `limit` dictionary, just like [`LimitedFlexibleInput`](@ref).

### [Variables](@id nodes-combustion-math-var)

The node uses the same variables as a standard [`NetworkNode`](@extref EnergyModelsBase nodes-network_node):

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

### [Constraints](@id nodes-combustion-math-con)

The following sections omit the direct inclusion of the vector of [`Combustion`](@ref) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`Combustion`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all investment periods).

#### [Standard constraints](@id nodes-combustion-math-con-stand)

[`Combustion`](@ref) utilize in general the standard constraints that are implemented for a [`NetworkNode`](@extref EnergyModelsBase nodes-network_node) node as described in the *[documentation of `EnergyModelsBase`](@extref EnergyModelsBase nodes-network_node-math-con)*.
These standard constraints are:

- `constraints_capacity`:

  ```math
  \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
  ```

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times \texttt{cap\_inst}[n, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given investment period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex\_var(n, t) \times \texttt{cap\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified data of the nodes, see above.


The functions `constraints_flow_in` and `constraints_flow_out` receive new methods to handle, respectively, the input and output flow constraints:

- `constraints_flow_in`

  - **Input energy balance (normalized by efficiency):**

    ```math
    \sum_{p \in P^{in}} \frac{\texttt{flow\_in}[n, t, p]}{inputs(n, p)} =
    \texttt{cap\_use}[n, t]
    ```

  - **Input share limit:**

    ```math
    \texttt{flow\_in}[n, t, p] \leq
    \left(\sum_{q \in P^{in}} \texttt{flow\_in}[n, t, q]\right) \times limits(n, p)
    ```

  - **Energy balance including residual heat:**

    ```math
    \sum_{p \in P^{in}} \texttt{flow\_in}[n, t, p] =
    \texttt{cap\_use}[n, t] +
    \frac{\texttt{flow\_out}[n, t, heat\_res]}{outputs(n, heat\_res)}
    ```

    This ensures that total energy input equals the sum of useful output and waste heat output.

- `constraints_flow_out`

  - **Standard output constraint (for non-residual outputs):**

    ```math
    \texttt{flow\_out}[n, t, p] = \texttt{cap\_use}[n, t] \times outputs(n, p)
    \qquad \forall p \in outputs(n) \setminus \{heat\_res, CO_2\}
    ```
