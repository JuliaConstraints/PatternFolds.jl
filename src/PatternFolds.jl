module PatternFolds

import Base: length, rand, iterate, isempty, ndims, +, in, size
import Lazy: @forward

# exports
export PatternFold, IVectorFold, VectorFold, Interval, IntervalsFold
export pattern, gap, folds
export length, unfold

# includes
include("common.jl")
include("immutable_vector.jl")
include("vector.jl")
include("intervals.jl")

end
