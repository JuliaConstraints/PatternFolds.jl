using Test
using TestItemRunner

@testset "Package tests: PatternFolds" begin
	include("Aqua.jl")
	include("TestItemRunner.jl")
end
