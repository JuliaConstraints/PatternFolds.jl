module PatternFolds

# Reexporr
using Reexport

# Import
@reexport using Intervals
using Lazy
using Random

# exports
export IntervalsFold
export IVectorFold
export VectorFold

export check_pattern
export fold
export folds
export gap
export length # TODO: rename span
export make_vector_fold
export pattern
export unfold

# includes
include("intervals.jl")
include("common.jl")
include("immutable_vector.jl")
include("vector.jl")

end
