module PatternFolds

import Base: length, rand, iterate, isempty, ndims, +, in
import Lazy: @forward

# exports
export PatternFold, VectorFold, MVectorFold, Interval, IntervalsFold
export pattern, gap, folds
export length, unfold

# includes
include("common.jl")
include("vector.jl")
include("mutable_vector.jl")
include("intervals.jl")

end
