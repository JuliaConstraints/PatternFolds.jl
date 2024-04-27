@testset "Aqua.jl" begin
	import Aqua
	import Intervals
	import PatternFolds

	# TODO: Fix the broken tests and remove the `broken = true` flag
	Aqua.test_all(
		PatternFolds;
		ambiguities = (broken = true,),
		deps_compat = false,
		piracies = (broken = true,)
	)

	@testset "Ambiguities: PatternFolds" begin
		Aqua.test_ambiguities(PatternFolds)
	end

	@testset "Piracies: PatternFolds" begin
		Aqua.test_piracies(PatternFolds;
			treat_as_own = [Intervals.Interval]
		)
	end

	@testset "Dependencies compatibility (no extras)" begin
		Aqua.test_deps_compat(PatternFolds;
			check_extras = false,
			ignore = [:Random]
		)
	end
end
