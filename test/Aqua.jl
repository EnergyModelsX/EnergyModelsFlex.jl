using Aqua

@testset "Aqua.jl" begin
    Aqua.test_ambiguities(EnergyModelsFlex)
    Aqua.test_unbound_args(EnergyModelsFlex)
    Aqua.test_undefined_exports(EnergyModelsFlex)
    Aqua.test_project_extras(EnergyModelsFlex)
    Aqua.test_stale_deps(EnergyModelsFlex)
    Aqua.test_deps_compat(EnergyModelsFlex)
    Aqua.test_piracies(EnergyModelsFlex)
    Aqua.test_persistent_tasks(EnergyModelsFlex)
end
