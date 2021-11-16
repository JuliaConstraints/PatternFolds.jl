using PerfChecker
using BenchmarkTools

using PatternFolds

target = PatternFolds

# function bench() # 0.2.x
#     # Intervals
#     itv = Interval{Open,Closed}(0.0, 1.0)
#     i = IntervalsFold(itv, 2.0, 10^6)

#     unfold(i)
#     collect(i)
#     reverse(collect(i))

#     # rand(i, 1000)

#     # Vectors
#     vf = make_vector_fold([0, 1], 2, 10^6)
#     # @info "Checking VectorFold" vf pattern(vf) gap(vf) folds(vf) length(vf)

#     unfold(vf)
#     collect(vf)
#     reverse(collect(vf))

#     rand(vf, 1000)

#     return nothing
# end

function bench() # 0.1.1-0.1.5
    # Intervals
    i = IntervalsFold(Interval((0.0, true), (1.0, false)), 2.0, 1000)

    unfold(i)
    collect(i)
    reverse(collect(i))

    # rand(i, 1000)

    # Vectors
    vf = VectorFold([0, 1], 2, 1000)
    # @info "Checking VectorFold" vf pattern(vf) gap(vf) folds(vf) length(vf)

    unfold(vf)
    collect(vf)
    reverse(collect(vf))

    for _ in 1:1000
        rand(vf)
    end

    return nothing
end

t = @benchmark bench() evals = 1 samples = 1000 seconds = 3600

# Actual call to PerfChecker
store_benchmark(t, target; path=@__DIR__)
