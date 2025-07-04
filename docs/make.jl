using Documenter
using DocumenterInterLinks
using EnergyModelsBase
using EnergyModelsFlex
using TimeStruct
using Literate

const EMB = EnergyModelsBase
const EMF = EnergyModelsFlex

DocMeta.setdocmeta!(
    EnergyModelsFlex,
    :DocTestSetup,
    :(using EnergyModelsFlex);
    recursive = true,
)

# Copy the NEWS.md file
news = "docs/src/manual/NEWS.md"
cp("NEWS.md", news; force = true)

links = InterLinks(
    "TimeStruct" => "https://sintefore.github.io/TimeStruct.jl/stable/",
    "EnergyModelsBase" => "https://energymodelsx.github.io/EnergyModelsBase.jl/stable/",
    "EnergyModelsRenewableProducers" => "https://energymodelsx.github.io/EnergyModelsRenewableProducers.jl/stable/",
    "EnergyModelsInvestments" => "https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/",
)

makedocs(
    sitename = "EnergyModelsFlex",
    modules = [EnergyModelsFlex],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "main",
        assets = String[],
        ansicolor = true,
    ),
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start"=>"manual/quick-start.md",
            "Examples"=>Any[
                "Flexible demand"=>"examples/flexible_demand.md",
            ],
            "Release notes"=>"manual/NEWS.md",
        ],
        "Nodes" => Any[
            "PayAsProducedPPA"=>"nodes/source/payasproducedppa.md",
            "Sink nodes"=>Any[
                "PeriodDemandSink"=>"nodes/sink/perioddemand.md",
                "LoadShiftingNode"=>"nodes/sink/loadshiftingnode.md",
                "MultipleInputSink"=>"nodes/sink/multipleinputsink.md",
                "AbstractMultipleInputSinkStrat"=>"nodes/sink/multipleinputsinkstrat.md",
            ],
            "Network nodes"=>Any[
                "MinUpDownTimeNode"=>"nodes/network/minupdowntimenode.md",
                "ActivationCostNode"=>"nodes/network/activationcostnode.md",
                "LimitedFlexibleInput"=>"nodes/network/limitedflexibleinput.md",
                "Combustion"=>"nodes/network/combustion.md",
            ],
            "StorageEfficiency"=>"nodes/storage/storageefficiency.md",
        ],
        "How-to" =>
            Any["Contribute"=>"how-to/contribute.md"],
        "Library" => Any[
            "Public"=>"library/public.md",
            "Internals"=>String[
                "library/internals/types.md",
                "library/internals/methods-fields.md",
                "library/internals/methods-EMF.md",
                "library/internals/methods-EMB.md",
            ],
        ],
    ],
    plugins = [links],
)

deploydocs(;
    repo = "github.com/EnergyModelsX/EnergyModelsFlex.jl.git",
)
