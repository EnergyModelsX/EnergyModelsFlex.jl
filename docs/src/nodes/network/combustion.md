# [Combustion node](@id nodes-combustion)

[`Combustion`](@ref) nodes are a variant of [`NetworkNode`](@ref)s that model fuel-based conversion processes where input energy is either transformed into useful outputs or lost as residual heat. The node enforces a complete **energy balance**, with residual losses explicitly accounted for using a designated `heat_res` output.

## [Introduced type and its fields](@id nodes-combustion-fields)

The [`Combustion`](@ref) node is similar to [`LimitedFlexibleInput`](@ref), but includes an additional **energy conservation constraint**. It uses a dedicated resource (`heat_res`) to capture residual or waste heat.

The fields of a [`Combustion`](@ref) node are:

- **`id`**:\
  Unique identifier for the node.
- **`cap::TimeProfile`**:\
  The installed capacity over time.
- **`opex_var::TimeProfile`**:\
  Variable operational expenses per unit of output produced.
- **`opex_fixed::TimeProfile`**:\
  Fixed operational expenses per unit of installed capacity.
- **`limit::Dict{<:Resource,<:Real}`**:\
  A dictionary specifying the maximum share that each input resource may contribute to total inflow.
- **`heat_res::Resource`**:\
  The residual heat or loss resource used to close the energy balance.
- **`input::Dict{<:Resource,<:Real}`**:\
  Input resources with associated conversion efficiencies.
- **`output::Dict{<:Resource,<:Real}`**:\
  Output resources with their respective conversion factors.
- **`data::Vector{<:Data}`**:\
  Optional vector for investment, emissions, or other model-specific metadata.

!!! note
    The residual output defined by `heat_res` is not necessarily "useful" energy—it serves to account for efficiency losses or heat rejection in the energy balance.

## [Mathematical description](@id nodes-combustion-math)

The [`Combustion`](@ref) node enforces a mass/energy balance including residual energy loss. It also supports input blending restrictions using the `limit` dictionary, just like [`LimitedFlexibleInput`](@ref).

### [Variables](@id nodes-combustion-math-var)

The node uses the same variables as a standard [`NetworkNode`](@ref):

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{emissions\_node}``](@ref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

### [Constraints](@id nodes-combustion-math-con)

#### Standard constraints

The following standard constraints are implemented for a [`NetworkNode`](@extref
EnergyModelsBase nodes-network_node) node.  [`NetworkNode`](@ref) nodes utilize
the declared method for all nodes 𝒩.  The constraint functions are called
within the function [`create_node`](@extref EnergyModelsBase.create_node).
Hence, if you do not have to call additional functions, but only plan to include
a method for one of the existing functions, you do not have to specify a new
[`create_node`](@extref EnergyModelsBase.create_node) method.

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
      The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@ref man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given investment period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex\_var(n, t) \times \texttt{cap\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@ref scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified data of the nodes, see above.


#### Additional constraints

The following constraints are applied to ensure correct behavior of the node:

-  `constraints_flow_in`

  - **Input energy balance (normalized by efficiency):**

    ```math
    \sum_{p \in P^{in}} \frac{\texttt{flow\_in}[n, t, p]}{inputs(n, p)} =
    \texttt{cap\_use}[n, t]
    ```

  - **Input share limit:**

    ```math
    \texttt{flow\_in}[n, t, p] \leq
    \left(\sum_{q \in P^{in}} \texttt{flow\_in}[n, t, q]\right) \cdot limits(n, p)
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
    \texttt{flow\_out}[n, t, p] = \texttt{cap\_use}[n, t] \cdot outputs(n, p)
    \qquad \forall p \in outputs(n) \setminus \{heat\_res, CO_2\}
    ```

  !!! warning "Correct definition of `heat_res`"
      It is essential that the resource defined in `heat_res` is also included in the `output` dictionary. If not, the residual balance constraint will not be well-formed and the model may fail.

  !!! tip "Use cases"
      Use this node when modeling combustion or transformation technologies where energy losses are explicit (e.g., boilers, engines, incinerators). It is especially valuable for modeling thermodynamic efficiencies or waste heat utilization.
