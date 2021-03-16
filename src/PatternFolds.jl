module PatternFolds

# usings
using Lazy

# exports
export PatternFold
export IVectorFold, VectorFold
export Interval, IntervalsFold
export pattern, gap, folds
export length
export unfold
export value

# includes
include("common.jl")
include("immutable_vector.jl")
include("vector.jl")
include("intervals.jl")

end
