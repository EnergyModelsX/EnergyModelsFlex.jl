# Storage efficiency node

[`StorageEfficiency`](@ref) nodes enable storage efficiency control compared to [`Storage`](@extref EnergyModelsBase nodes-storage). They are designed as parametric types through the type parameter `T` to differentiate between different cyclic behaviors.

## Introduced type and its field

The `StorageEfficiency{T}` is implemented as a subtype of `EMB.Storage{T}`, extending the existing `Storage` node.

### Standard fields

The standard fields are given as:

- **`id`**:
  The field `id` is used for providing a name to the node. This is similar to the approach utilized in `EnergyModelsBase`.

- **`charge::AbstractStorageParameters`**:
  The charging parameters of the `Storage` node. Depending on the chosen type, the charge parameters can include variable OPEX, fixed OPEX, and/or a capacity.

- **`level::AbstractStorageParameters`**:
  The level parameters of the `Storage` node. Depending on the chosen type, the level parameters can include variable OPEX and/or fixed OPEX.

- **`stor_res::Resource`**:
  The stored `Resource`.

- **`input::Dict{<:Resource, <:Real}`**:
  The input `Resource`s with conversion value `Real`.

- **`output::Dict{<:Resource, <:Real}`**:
  The generated `Resource`s with conversion value `Real`. Only relevant for linking and the stored `Resource` as the output value is not utilized in the calculations.

- **`data::Vector{<:Data}`**:
  An entry for providing additional data to the model. In the current version, it is only relevant for additional investment data when `EnergyModelsInvestments` is used. The field `data` is not required as we include a constructor when the value is excluded.

## Mathematical description

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.


### Variables

#### Standard variables

The storage efficiency node types utilize all standard variables from the `RefStorage{T}` node type, as described on the page *Optimization variables*. The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{stor\_level\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_level}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_charge\_inst}``](@extref EnergyModelsBase man-opt_var-cap) if the `Storage` has the field `charge` with a capacity
- [``\texttt{stor\_charge\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_discharge\_inst}``](@extref EnergyModelsBase man-opt_var-cap) if the `Storage` has the field `discharge` with a capacity
- [``\texttt{stor\_discharge\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{stor\_level\_Δ\_op}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_level\_Δ\_rp}``](@extref EnergyModelsBase man-opt_var-cap) if the `TimeStruct` includes `RepresentativePeriods`
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if specified through the function `has_emissions` or if you use a `RefStorage{AccumulatingEmissions}`.


### Constraints

The following sections omit the direct inclusion of the vector of storage efficiency nodes.
Instead, it is implicitly assumed that the constraints are valid ``∀ n ∈ N^{\text{StorageEfficiency\_source}}`` for all `StorageEfficiency` types if not stated differently.
In addition, all constraints are valid ``∀ t ∈ T`` (that is in all operational periods) or ``∀ t_{\text{inv}} ∈ T^{Inv}`` (that is in all strategic periods).

#### Standard constraints

The node inherits the following constraints from the
standard [`Storage`](@extref EnergyModelsBase nodes-storage)-node.

- `constraints_capacity`:

  ```math
  \begin{aligned}
  \texttt{stor\_level\_use}[n, t] & \leq \texttt{stor\_level\_inst}[n, t] \\
  \texttt{stor\_charge\_use}[n, t] & \leq \texttt{stor\_charge\_inst}[n, t] \\
  \texttt{stor\_discharge\_use}[n, t] & \leq \texttt{stor\_discharge\_inst}[n, t]
  \end{aligned}
  ```

- `constraints_capacity_installed`:

  ```math
  \begin{aligned}
  \texttt{stor\_level\_inst}[n, t] & = capacity(level(n), t) \\
  \texttt{stor\_charge\_inst}[n, t] & = capacity(charge(n), t) \\
  \texttt{stor\_discharge\_inst}[n, t] & = capacity(discharge(n), t)
  \end{aligned}
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_level`:\
  The level constraints are more complex compared to the standard constraints.
  They are explained in detail below in *[Level constraints](@ref nodes-storage-math-con-level)*.

- `constraints_opex_fixed`:

  ```math
  \begin{aligned}
  \texttt{opex\_fixed}&[n, t_{inv}] = \\ &
    opex\_fixed(level(n), t_{inv}) \times \texttt{stor\_level\_inst}[n, first(t_{inv})] + \\ &
    opex\_fixed(charge(n), t_{inv}) \times \texttt{stor\_charge\_inst}[n, first(t_{inv})] + \\ &
    opex\_fixed(discharge(n), t_{inv}) \times \texttt{stor\_discharge\_inst}[n, first(t_{inv})]
  \end{aligned}
  ```

  !!! tip "Why do we use `first()`"
      The variables ``\texttt{stor\_level\_inst}`` are declared over all operational periods (see the section on *[Capacity variables](@ref man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacities in the first operational period of a given investment period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \begin{aligned}
  \texttt{opex\_var}&[n, t_{inv}] = \\ \sum_{t \in t_{inv}}&
    opex\_var(level(n), t) \times \texttt{stor\_level}[n, t] \times scale\_op\_sp(t_{inv}, t) + \\ &
    opex\_var(charge(n), t) \times \texttt{stor\_charge\_use}[n, t] \times scale\_op\_sp(t_{inv}, t) + \\ &
    opex\_var(discharge(n), t) \times \texttt{stor\_discharge\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  \end{aligned}
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@ref scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified data of the storage node, see above.

!!! info "Implementation of capacity and OPEX"
    The capacity constraints, both `constraints_capacity` and `constraints_capacity_installed` are only set for capacities that are included through the corresponding field and if the corresponding *[storage parameters](@ref lib-pub-nodes-stor_par)* have a field `capacity`.
    Otherwise, they are omitted.
    The field `level` is required to have a storage parameter with capacity.

    Even if a `Storage` node includes the corresponding capacity field (*i.e.*, `charge`, `level`, and `discharge`), we only include the fixed and variable OPEX constribution for the different capacities if the corresponding *[storage parameters](@ref lib-pub-nodes-stor_par)* have a field `opex_fixed` and `opex_var`, respectively.
    Otherwise, they are omitted.


#### Additional constraints

This are the constraints implemented for the `StorageEfficiency`-node.

- `constraints_flow_in`

  Defines the input flow constraints for a StorageEfficiency node, accounting for both the primary storage resource and any additional inputs that contribute to charging (e.g. energy losses or auxiliary power).

  This constraint enforces two conditions:

  - **Auxiliary Input Requirements:**
    For each additional input resource $p ∈ inputs(n) \ p_{\text{stor}}$, the flow is proportional to the main storage flow by a conversion factor:
    ```math
    \texttt{flow\_in}[n,t,p]=\texttt{flow\_in}[n,t,p_{\text{stor​}}]⋅inputs(n,p)
    ```
    where ``p_{\text{stor}}`` is the designated storage resource.

  - **Charging Efficiency Application:**
    The effective charging rate is defined by the conversion factor (typically <1) of the storage resource:
    ```math
    \texttt{stor\_charge\_use}[n,t]=\texttt{flow\_in}[n,t,p_{\text{stor}}]⋅inputs(n,p_{\text{stor​}})
    ```
    This models the efficiency of storing energy, such as charging losses or heat dissipation.


- `constraints_flow_out`

  Defines the output flow constraints for a [`StorageEfficiency`](@ref) node, converting the usable discharged energy to the observed output.

  The discharging constraint ensures that output flow matches the usable storage output, accounting for discharging efficiency:
  ```math
  \texttt{flow\_out}[n,t,pstor​]=\texttt{stor\_discharge\_use}[n,t]⋅outputs(n,p_{\text{stor​}})
  ```

  This models energy losses when discharging from storage (e.g., thermal or round-trip losses in batteries).

  !!! note
      These constraints are only meaningful when paired with storage state and balance constraints. The variables ``\texttt{stor\_charge\_use}`` and ``\texttt{stor\_discharge\_use}`` are assumed to be defined elsewhere in the storage node implementation.

  !!! tip
      Use this node to model round-trip efficiency and auxiliary consumption associated with charging/discharging storage technologies (e.g. batteries, thermal tanks).
