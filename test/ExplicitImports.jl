@testset "Look for Explicit Imports" begin
    @test check_no_implicit_imports(PatternFolds) === nothing
end
