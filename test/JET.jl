@testset "Code linting (JET.jl)" begin
    JET.test_package(PatternFolds; target_defined_modules = true)
end
