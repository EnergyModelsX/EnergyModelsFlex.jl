# Use Literate.jl to generate Markdown docs from examples.
julia --project=docs --eval 'using Literate; \
    Literate.markdown("examples/flexible_demand.jl",
        "docs/src/examples/";
        flavor = Literate.DocumenterFlavor())'
