# [PeriodDemandSink node](@id nodes-perioddemandsink)

[`PeriodDemandSink`](@ref) nodes represent flexible demand sinks where demand must be fulfilled within defined periods (e.g. daily or weekly), rather than in each individual operational time step. **A *period* is thus a consecutive range of operational periods, that together will model e.g. a day or a week etc.**

This node can, e.g., be combined with [`MinUpDownTimeNode`](@ref), to allow production to be moved to the time of the day when it is cheapest because of, e.g., energy or production costs.

!!! tip "See example"
    This node is included in an [example](@ref examples-flexible_demand) to demonstrate flexible demand.

!!! warning
    This node is designed for **uniform timestep durations**. Irregular durations may cause misalignment of shifted loads.


## [Introduced type and its fields](@id nodes-perioddemandsink-fields)

The [`PeriodDemandSink`](@ref) node extends the [`Sink`](@ref) functionality by introducing aggregated demand over fixed-length periods. This is useful for representing flexible loads like electric vehicle charging or industrial batch processes, where exact timing of delivery is flexible.

!!! note "Abstract supertype"
    `PeriodDemandSink` is defined as a subtype of [`AbstractPeriodDemandSink`](@ref EnergyModelsFlex.AbstractPeriodDemandSink), and constraints are put on this supertype. By subtyping `AbstractPeriodDemandSink`, you can easily extend the functionality of this node.

The fields of a [`PeriodDemandSink`](@ref) node are given as:

- **`id`**:\
  A general identifier for the node.
- **`period_length::Int`**:\
  Defines how many operational periods are included in a single demand period.\
  For instance, if operational periods are 1 hour and `period_length = 24`, then each demand period spans one day. The demand of this node (for a given day, see below) must then be filled on a daily basis, without any restrictions on *when* during the day the demand must be filled.

  !!! warning "Multiple `PeriodDemandSink`s"
      Note that if multiple `PeriodDemandSink`-nodes are used in the same energy system, they must all have the same [`number_of_periods`](@ref EnergyModelsFlex.number_of_periods) i.e. `n.period_length`.

- **`period_demand::Vector{<:Real}`**:\
  The total demand to be met during each demand period. The length of this vector should match the number of periods (e.g., days) in the time structure. If the time structure represents on year with hourly resolution, this vector must then have 365 elements.

  !!! warning "Time consistency"
      Ensure that the `period_demand` vector length aligns with the total time horizon divided by `period_length`. Mismatches can lead to indexing errors or inconsistent demand enforcement.

- **`cap::TimeProfile`**:\
  The maximum amount of demand that can be met in each operational period. This acts as a capacity on instantaneous delivery, while `period_demand` enforces total energy delivered.
- **`penalty::Dict{Symbol,<:TimeProfile}`**:\
  Specifies penalties for both surplus and deficit in demand delivery at the period level.\
  Must include the keys `:surplus` and `:deficit`.
- **`input::Dict{<:Resource,<:Real}`**:\
  Describes the energy input required to meet demand, with conversion factors.
- **`data::Vector{Data}`**:\
  An optional field to pass in investment- or emissions-related metadata. The default constructor omits this, initializing to an empty vector.

!!! note
    Unlike [`RefSink`](@extref EnergyModelsBase.RefSink), the delivery of demand here is flexible within each demand period. This is helpful for modeling demand that can shift within a day or week.



## [Mathematical description](@id nodes-perioddemandsink-math)

The [`PeriodDemandSink`](@ref) node introduces variables and constraints associated with period-based demand fulfillment.

### [Variables](@id nodes-perioddemandsink-math-var)

In addition to standard [`Sink`](@ref) variables such as:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{sink\_surplus}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{sink\_deficit}``](@extref EnergyModelsBase man-opt_var-sink)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

This node also defines:

- ``\texttt{demand\_sink\_surplus}[n, i]``:\
  Surplus of energy delivered beyond the required `period_demand` in period `i`.
- ``\texttt{demand\_sink\_deficit}[n, i]``:\
  Deficit of energy delivered relative to the `period_demand` in period `i`.

### [Constraints](@id nodes-perioddemandsink-math-con)

#### Standard constraints

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

- `constraints_flow_in`:

  ```math
  \texttt{flow\_in}[n, t, p] =
  inputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in inputs(n)
  ```

  !!! tip "Multiple inputs"
      The constrained above allows for the utilization of multiple inputs with varying ratios.
      it is however necessary to deliver the fixed ratio of all inputs.

- `constraints_opex_fixed`:\
  The current implementation fixes the fixed operating expenses of a sink to 0.

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = 0
  ```


- `constraints_data`:\
  This function is only called for specified additional data, see above.


#### Additional constratins

In addition to constraints inherited from [`Sink`](@extref), the following are implemented:

- `constraints_capacity`:

  ```math
  \texttt{cap\_use}[n, t] + \texttt{sink\_deficit}[n, t] = \texttt{cap\_inst}[n, t] + \texttt{sink\_surplus}[n, t]
  ```

  ```math
  \sum_{t\in P_i} \texttt{​cap\_use}[n,t]+\texttt{demand\_sink\_deficit}[n,i]=n.period\_demand[i]+\texttt{demand\_sink\_surplus}[n,i]
  ```

where $P_i$ is the set of operational periods in demand period i.

- `constraints_opex_var`:
  ```math
  \texttt{opex\_var}[n,t_{\text{inv}}]=\sum{t∈t_{\text{inv}}}( \texttt{demand\_sink\_surplus}[n,i_t]×\texttt{surplus\_penalty}(n,t)+\texttt{demand\_sink\_deficit}[n,i_t]×\texttt{deficit\_penalty}(n,t))×scale\_op\_sp(t_{\text{inv}},t)
  ```

    where ``i_t`` is the period index such that ``t \in P_{i_t}``.

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@ref scale_op_sp) calculates the scaling factor between operational and investment periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.
