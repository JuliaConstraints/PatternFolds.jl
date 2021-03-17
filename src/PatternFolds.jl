module PatternFolds

# usings
using Lazy

# exports
export PatternFold
export IVectorFold, VectorFold
export Interval, IntervalsFold
export pattern, gap, folds, check_pattern
export length
export fold, unfold
export value

# includes
include("common.jl")
include("immutable_vector.jl")
include("vector.jl")
include("intervals.jl")

end
