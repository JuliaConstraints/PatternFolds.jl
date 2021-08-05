module PatternFolds

# usings
using Lazy

# exports
export Interval
export IntervalsFold
export IVectorFold
export PatternFold
export VectorFold

export a_isless
export a_ismore
export b_isless
export b_ismore
export check_pattern
export closed
export fold
export folds
export gap
export length
export opened
export pattern
export unfold
export value

# includes
include("common.jl")
include("immutable_vector.jl")
include("vector.jl")
include("intervals.jl")

end
