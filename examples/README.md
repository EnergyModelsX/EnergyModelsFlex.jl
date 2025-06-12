# Running the examples

You have to add the package `EnergyModelsFlex` to your current project in order to run the examples.
It is not necessary to add the other used packages, as the example is instantiating itself.

How to add packages is explained in the *[Quick start](https://energymodelsx.github.io/EnergyModelsFlex.jl/stable/manual/quick-start/)* of the documentation

You can run from the Julia REPL the following code:

```julia
# Import EnergyModelsBase
using EnergyModelsFlex

# Get the path of the examples directory
exdir = joinpath(pkgdir(EnergyModelsFlex), "examples")

# Include the code into the Julia REPL to run the example
include(joinpath(exdir, "flexible_demand.jl"))
