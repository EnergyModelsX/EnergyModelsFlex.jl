# EnergyModelsFlex

[![DOI](https://joss.theoj.org/papers/10.21105/joss.06619/status.svg)](https://doi.org/10.21105/joss.06619)
[![Build Status](https://github.com/EnergyModelsX/EnergyModelsFlex.jl/workflows/CI/badge.svg)](https://github.com/EnergyModelsX/EnergyModelsFlex.jl/actions?query=workflow%3ACI)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://energymodelsx.github.io/EnergyModelsFlex.jl/stable/)
[![In Development](https://img.shields.io/badge/docs-dev-blue.svg)](https://energymodelsx.github.io/EnergyModelsFlex.jl/dev/)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/JuliaDiff/BlueStyle)

`EnergyModelsFlex` is a package extending `EnergyModelsBase` with additional node types that capture different aspects of flexibility in energy systems.

> [!WARNING]
> The different node types are partly experimental.
> They have furthermore some limitations with respect to the chosen `TimeStructure` or whether they are able to handle investments.
> As a consequence, it is advised to read the documentation for each node to identify their usefulness.
>
> The initial version is based on [`EnergyModelsBase` v0.8](https://energymodelsx.github.io/EnergyModelsBase.jl/v0.8/).
> It is planned to update the model in the near future to support the latest version of `EnergyModelsBase`.
> This update may include the removal of some nodes and a rewrite of the behaviour of the different nodes.

## Usage

The usage of the package is best illustrated through the commented [`examples`](examples).
The examples are minimum working examples highlighting how the different nodes can be utilized.

Please refer to the *[documentation](https://energymodelsx.github.io/EnergyModelsFlex.jl/stable/)* for more details.

## Cite

If you find `EnergyModelsFlex` useful in your work, we kindly request that you cite the following [publication](https://doi.org/10.69997/sct.119164):

```bibtex
@article{venas2025energymodelsflex,
  title = {Energy system modelling for studying flexibility on industrial sites},
  author = {Ven{\aa}s, Jon Vegard and Bernardino, Lucas Ferreira and Thorvaldsen, Kasper Emil and Aunsmo, Sigrid and Holm, Sigmund Eggen and Krog, Halvor Aarnes and Wolfgang, Ove and R{\o}e, Ingeborg Treu},
  journal = {Systems and Control Transactions},
  volume = {4},
  pages = {824--830},
  year = {2025},
  doi = {10.69997/sct.119164},
  url = {https://doi.org/10.69997/sct.119164},
}
```

## Project Funding

EnergyModelsFlex was funded by [FLEX4FACT](https://flex4fact.eu/). FLEX4FACT is receiving funding from the European Union’s Horizon Europe research and innovation programme under grant agreement [101058657](https://doi.org/10.3030/101058657).
