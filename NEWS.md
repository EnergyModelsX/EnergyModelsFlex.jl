# Release notes

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
