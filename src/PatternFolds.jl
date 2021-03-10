module PatternFolds

import Base: length, rand, iterate, isempty, ndims
import Lazy: @forward

# exports
export PatternFold, VectorFold, MVectorFold
export pattern, gap, folds
export length, unfold

# includes
include("common.jl")
include("vector.jl")
include("mutable_vector.jl")

end
