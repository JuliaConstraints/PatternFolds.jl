module PatternFolds

import Base.length, Base.rand, Base.iterate

# exports
export PatternFold, VectorFold, MVectorFold
export pattern, gap, folds
export length, unfold

# includes
include("common.jl")
include("vector.jl")
include("mutable.jl")

end
