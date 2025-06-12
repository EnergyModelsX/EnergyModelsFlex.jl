
# [Pay-as-produced PPA energy source node](@id nodes-payasproducedppa)

Pay-as-produced PPA energy sources generate electricity from intermittent energy sources with a specific constraint on the variable operating expenses (OPEX) such that curtailed energy is also included in the OPEX. This node models a Power Purchase Agreement (PPA) contract.

## Introduced type and its field

The [`PayAsProducedPPA`](@ref) is implemented as a subtype of [`AbstractNonDisRES`](@extref EnergyModelsRenewableProducers.AbstractNonDisRES) extending the existing functionality defined in [`EnergyModelsRenewableProducers`](@extref).

### Standard fields

The standard fields are given as:

- **`id`**:
  The field `id` is used for providing a name to the node. This is similar to the approach utilized in `EnergyModelsBase`.

- **`cap::TimeProfile`**:
  The installed capacity corresponds to the nominal capacity of the node. In addition, all values have to be non-negative.
  If the node should contain investments through the application of [`EnergyModelsInvestments`](@extref), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.

- **`profile::TimeProfile`**:
  The profile is used as a multiplier to the installed capacity to represent the maximum actual capacity in each operational period. The profile can e.g. be provided as `OperationalProfile`. In addition, all values should be in the range `[0, 1]`.

- **`opex_var::TimeProfile`**:
  The variable operational expenses are based on the capacity utilization through the variable `:cap_use`. Hence, it is directly related to the specified `output` ratios. The variable operating expenses can be provided as `OperationalProfile` as well.

- **`opex_fixed::TimeProfile`**:
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of a strategic period as outlined on [*Utilize `TimeStruct`*](@extref EnergyModelsBase how_to-utilize_TS). It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.

- **`output::Dict{<:Resource, <:Real}`**:
  The field `output` includes `Resource`s with their corresponding conversion factors as dictionaries. In the case of a pay-as-produced PPA energy source, `output` should include your *electricity* resource. In practice, you should use a value of 1.

- **`data::Vector{Data}`**:
  An entry for providing additional data to the model. In the current version, it is only relevant for additional investment data when `EnergyModelsInvestments` is used. The field `data` is not required as we include a constructor when the value is excluded.

---


## Mathematical description

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.


### Variables

#### Standard variables

The non-dispatchable renewable energy source node types utilize all standard variables from the [`RefSource`](@extref EnergyModelsBase.RefSource) node type, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`.

!!! note
    Non-dispatchable renewable energy source nodes are not compatible with `CaptureData`.
    Hence, you can only provide [`EmissionsProcess`](@extref EnergyModelsBase.EmissionsProcess) to the node.


#### Additional variables

`PayAsProducedPPA` nodes should keep track of the curtailment of the electricity, that is the unused capacity in each operational time period. Hence, a single additional variable is declared through dispatching on the method `EnergyModelsBase.variables_node()`:

- ``\texttt{curtailment}[n, t]``: Curtailed capacity of source `n` in operational period `t` with a typical unit of MW. The curtailed electricity specifies the unused generation capacity of the pay-as-produced PPA energy source. It is currently only used in the calculation, but not with a cost. This can be added by the user, if desired.

### Constraints

The following sections omit the direct inclusion of the vector of CO₂ source nodes. Instead, it is implicitly assumed that the constraints are valid ``\forall n \in N^{\text{PayAsProducedPPA}\_source}`` for all [`PayAsProducedPPA`](@ref) types if not stated differently. In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

#### Standard constraints

Pay-as-produced PPA energy source nodes utilize in general the standard constraints described on *Constraint functions*. In fact, they use the same `create_node` function as a `RefSource` node. These standard constraints are:

- `constraints_capacity_installed`:
  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

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

- `constraints_data`:
  This function is only called for specified data of the pay-as-produced PPA energy source, see above.

The function `constraints_capacity` is utilizing the [method introduced for `AbstractNonDisRes` nodes](@extref EnergyModelsRenewableProducers nodes-nondisres-math-con-stand):
```math
\texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
```
and
```math
\texttt{cap\_use}[n, t] + \texttt{curtailment}[n, t] =
profile(n, t) \times \texttt{cap\_inst}[n, t]
```
This function still calls the subfunction `constraints_capacity_installed` to limit the variable `cap_inst[n, t]` or provide capacity investment options.


#### Additional constraints

- `constraints_opex_var`:
  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t ∈ t_{inv}} (\texttt{cap\_use}[n, t] + \texttt{curtailment}[n, t]) \times opex\_var(n, t) \times scale\_op\_sp(t_{inv}, t)
  ```
  !!! note
      This is the only constraint on `PayAsProducedPPA` that differs from the standard implementation of [`NonDisRES`](@extref EnergyModelsRenewableProducers.NonDisRES).
