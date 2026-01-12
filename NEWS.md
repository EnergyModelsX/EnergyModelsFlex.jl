# Release notes

## Version 0.2.10 (2026-01-05)

### Enhancements

* Added the new link `CapacityCostLink`.
* Added the nodes `InflexibleSource` and `FlexibleOutput`.

### Adjustments

* Removed `ext/EMGUIExt/descriptive_names.yml` as this will now be provided directly in `EnergyModelsGUI`.
* Removed `docs/src/example/flexible_demand.md` as the markdown versions of the example files are now generated automatically (and these are thus added to the `.gitignore`-file).


## Version 0.2.9 (2025-07-08)

* Adjusted to [`EnergyModelsBase` v0.9.0](https://github.com/EnergyModelsX/EnergyModelsBase.jl/releases/tag/v0.9.0):
  * Increased version number for EMB.
  * Replaced `variables_node` with `variables_element`.

### Bugfix

* Fixed a bug in `MultipleInputStrat` nodes:
  * The variables were declared over all input resources of a nodes of this type.
  * As a consequence, unconstrained variables were declared when multiple nodes with differing inputs were included.
  * In the worst case, this could lead to an unbound problem if the surplus penalty was negative.

## Version 0.2.8 (2025-07-04)

### Public release on GitHub

* Released the exisiting version so that case studies in the project [FLEX4FACT](https://flex4fact.eu/) are running without any problems.
* Release depends on old versions of `EnergyModelsBase`.
* It is planned to update the model to the latest version within a short period of time.

## Version 0.2.7 (2025-01-14)

### Enhancement

* Add a Combustion node

## Version 0.2.6 (2025-01-18)

### Enhancement

* Added more checks, documentation and tests.
* Replaced `Combustion` with `LimitedFlexibleInput` where the inverse convention of the conversion ratio is used for the input resources.
* Renamed `AbstractMachineryDemand` to `AbstractMultipleInputSinkStrat` with `AbstractMultipleInputSink` as supertype.
* Renamed `BinaryMachineryDemand` and `ContinuousMachineryDemand` to `BinaryMultipleInputSinkStrat` and `ContinuousMultipleInputSinkStrat`, respectively.
  Also generalized the `electrification` variable to the variable `input_frac_strat` which enables more input resources.
* Add documentation, NEWS and README.
* Adjusted code to comply with Aqua requirements and to comply with EMX standards.
* Added descriptive names for variables introduced in `EnergyModelsFlex` to be used in `EnergyModelsGUI`.
* Added new nodes for SPS, remove redundant constraint for `PayAsProducedPPA` and dispatch on `AbstractNonDisRES` (instead of `Source`).
* Improve documentation of `LoadShiftingNode`, use Int-type where appropriate and fix minor bug in load shift constraints.

## Version 0.2.5 (2024-11-12)

### Enhancement

* Add SPS nodes.

## Version 0.2.4 (2024-11-01)

### Enhancement

* Add `PayAsProducedPPA` node.

## Version 0.2.3 (2024-10-29)

### Enhancement

* Version update.

## Version 0.2.2 (2024-10-10)

### Enhancement

* Create an abstract base type for `PeriodDemandSink`.

## Version 0.2.1 (2024-10-09)

### Enhancement

* Add `demand_sink_surplus` slack variable.

## Version 0.2.0 (2024-10-08)

### Enhancement

* `BatteryStorage` cant be included before it is updated to `EnergyModelsBase` v0.8.0.

## Version 0.1.1 (2024-06-18)

### Enhancement

* Make `BatteryStorage` work when included in investment models, note that investments in `BatteryStorage` needs further development.

## Version 0.1.0 (2024-04-16)

### Initial (skeleton) version

* Make it into a package.
