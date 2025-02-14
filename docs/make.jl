using Documenter
using DocumenterInterLinks
using EnergyModelsBase
using EnergyModelsFlex
using TimeStruct
using Literate

const EMB = EnergyModelsBase
const EMF = EnergyModelsFlex

# Copy the NEWS.md file
news = "docs/src/manual/NEWS.md"
cp("NEWS.md", news; force = true)

#inputfile = joinpath(@__DIR__, "src", "examples", "battery_storage.jl")
#Literate.markdown(inputfile, joinpath(@__DIR__, "src", "examples"))

links = InterLinks(
    "TimeStruct" => "https://sintefore.github.io/TimeStruct.jl/stable/",
    "EnergyModelsBase" => "https://energymodelsx.github.io/EnergyModelsBase.jl/stable/",
)

makedocs(
    sitename = "EnergyModelsFlex",
    repo = "https://gitlab.sintef.no/clean_export/EnergyModelsFlex.jl/blob/{commit}{path}#{line}",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://gitlab.sintef.no/clean_export/EnergyModelsFlex.jl",
        edit_link = "main",
        assets = String[],
    ),
    modules = [
        EnergyModelsFlex,
    ],
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start"=>"manual/quick-start.md",
            "Release notes"=>"manual/NEWS.md",
        ],
        "How-to" =>
            Any["Contribute"=>"how-to/contribute.md", "Utilize"=>"how-to/utilize.md"],
        #"Examples" => Any["Battery storage"=>"examples/battery_storage.md"],
        "Library" => Any[
            "Public"=>"library/public.md",
            "Internals"=>String[
                "library/internals/types.md",
                "library/internals/methods.md",
            ],
        ],
    ],
    plugins = [links],
)
