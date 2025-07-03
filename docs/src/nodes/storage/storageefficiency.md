# [Storage efficiency node](@id nodes-stor_eff)

The reference storage node, [`RefStorage`](@extref EnergyModelsBase.RefStorage), does not include any efficiencies for the stored [`Resource`](@extref EnergyModelsBase.Resource).
It is always assumed that there is no associated loss of the stored [`Resource`](@extref EnergyModelsBase.Resource) when charging or discharging the storage.
[`StorageEfficiency`](@ref) nodes are introduced to enable storage efficiency control compared to [`Storage`](@extref EnergyModelsBase nodes-storage).

The nodes utilize the *[parametric implementation](@extref EnergyModelsBase nodes-storage-phil-parametric)* for all storage nodes and the individual *[capacities](@extref EnergyModelsBase nodes-storage-phil-capacities)* for `charge` and storage `level`.

## [Introduced type and its fields](@id nodes-stor_eff-fields)

The `StorageEfficiency{T}` is implemented as a subtype of `EMB.Storage{T}`, extending the existing `Storage` node.

The fields of a [`StorageEfficiency`](@ref) are:

- **`id`**:\
  The field `id` is only used for providing a name to the node.
- **`charge::EMB.UnionCapacity`**:\
  The charging parameters of the `Storage` node must include a capacity.
  Depending on the chosen type, the `charge` parameters can also include variable OPEX and/or fixed OPEX.
- **`level::EMB.UnionCapacity`**:\
  The level parameters of the `Storage` node must include a capacity..
  Depending on the chosen type, the `charge` parameters can also include variable OPEX and/or fixed OPEX.
  !!! note "Permitted values for storage parameters in `charge` and `level`"
      If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
      Similarly, you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
      The variable operating expenses can be provided as `OperationalProfile` as well.
      In addition, all capacity and fixed OPEX values have to be non-negative.
- **`stor_res::ResourceEmit`**:\
  The `stor_res` is the stored [`Resource`](@extref EnergyModelsBase.Resource).
- **`input::Dict{<:Resource,<:Real}`** and **`output::Dict{<:Resource,<:Real}`**:\
  Both fields describe the `input` and `output` [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  The stored [`Resource`](@extref EnergyModelsBase.Resource) (outlined above) must be included to create the linking variables.
- **`data::Vector{<:Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is used for additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used.
  !!! note "Constructor for `StorageEfficiency`"
      The field `data` is not required as we include a constructor when the value is excluded.

## [Mathematical description](@id nodes-stor_eff-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-stor_eff-math-var)

#### [Standard variables](@id nodes-stor_eff-math-var-stand)

The storage efficiency node types utilize all standard variables from the `RefStorage{T}` node type, as described on the page *Optimization variables*. The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{stor\_level\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_level}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_charge\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_charge\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{stor\_level\_Δ\_op}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_level\_Δ\_rp}``](@extref EnergyModelsBase man-opt_var-cap) if the `TimeStruct` includes `RepresentativePeriods`

It does not add any additional variables.

### [Constraints](@id nodes-stor_eff-math-con)

The following sections omit the direct inclusion of the vector of [`StorageEfficiency`](@ref) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N`` for all [`StorageEfficiency`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all investment periods).

#### [Standard constraints](@id nodes-stor_eff-math-con-stand)

[`StorageEfficiency`](@ref) utilize in general the standard constraints that are implemented for a [`Storage`](@extref EnergyModelsBase nodes-storage) node as described in the *[documentation of `EnergyModelsBase`](@extref EnergyModelsBase nodes-storage-math-con)*.
These standard constraints are:

- `constraints_capacity`:

  ```math
  \begin{aligned}
  \texttt{stor\_level\_use}[n, t] & \leq \texttt{stor\_level\_inst}[n, t] \\
  \texttt{stor\_charge\_use}[n, t] & \leq \texttt{stor\_charge\_inst}[n, t]
  \end{aligned}
  ```

- `constraints_capacity_installed`:

  ```math
  \begin{aligned}
  \texttt{stor\_level\_inst}[n, t] & = capacity(level(n), t) \\
  \texttt{stor\_charge\_inst}[n, t] & = capacity(charge(n), t)
  \end{aligned}
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_level`:\
  The level constraints are more complex compared to the standard constraints.
  They are explained in detail below in *[the description on level constraints in `EnergyModelsBase`](@extref EnergyModelsBase nodes-storage-math-con-level)*.

- `constraints_opex_fixed`:

  ```math
  \begin{aligned}
  \texttt{opex\_fixed}&[n, t_{inv}] = \\ &
    opex\_fixed(level(n), t_{inv}) \times \texttt{stor\_level\_inst}[n, first(t_{inv})] + \\ &
    opex\_fixed(charge(n), t_{inv}) \times \texttt{stor\_charge\_inst}[n, first(t_{inv})]
  \end{aligned}
  ```

  !!! tip "Why do we use `first()`"
      The variables ``\texttt{stor\_level\_inst}`` are declared over all operational periods (see the section on *[capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacities in the first operational period of a given investment period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \begin{aligned}
  \texttt{opex\_var}&[n, t_{inv}] = \\ \sum_{t \in t_{inv}}&
    opex\_var(level(n), t) \times \texttt{stor\_level}[n, t] \times scale\_op\_sp(t_{inv}, t) + \\ &
    opex\_var(charge(n), t) \times \texttt{stor\_charge\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  \end{aligned}
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified data of the storage node, see above.

!!! info "Implementation of OPEX"
    Even if a `Storage` node includes the corresponding capacity field (*i.e.*, `charge`, `level`, and `discharge`), we only include the fixed and variable OPEX constribution for the different capacities if the corresponding *[storage parameters](@extref EnergyModelsBase lib-pub-nodes-stor_par)* have a field `opex_fixed` and `opex_var`, respectively.
    Otherwise, they are omitted.

The functions `constraints_flow_in` and `constraints_flow_out` are extended with new methods that, compared to a [`RefStorage`](@extref EnergyModelsBase.RefStorage) node, better controls the storage efficiency:

The function `constraints_flow_in` is exytended with a new method to incorporate the conversion factor also for the stored resource.
The effective charging rate is defined by the conversion factor (typically <1) of the stored resource ``p_{\text{stor}}``:

```math
\texttt{stor\_charge\_use}[n, t] = \texttt{flow\_in}[n, t, p_{\text{stor}}] \times inputs(n, p_{\text{stor​}})
```

For each additional input resource ``p ∈ inputs(n) \setminus p_{\text{stor}}``, the flow is proportional to the main storage flow by a conversion factor:

```math
\texttt{flow\_in}[n, t, p] = \texttt{flow\_in}[n, t,p_{\text{stor​}}] \times inputs(n,p)
```

The function `constraints_flow_out` is extended with a new method to incorporate the conversion factor for discharging_

```math
\texttt{flow\_out}[n, t,pstor​]=\texttt{stor\_discharge\_use}[n, t] 'times outputs(n, p_{\text{stor​}})
```

This models energy losses when discharging from storage (*e.g.*, thermal or round-trip losses in batteries).
