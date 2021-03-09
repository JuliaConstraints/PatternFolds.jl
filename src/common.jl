"""
    PatternFold{T, P}
An abstract stype used as an interface for folded patterns such as `VectorFold`.
To implement the interface and inherit from it, a new structure must define three fields:
- `pattern::P`. Note that both `length(::P)` and `rand(::P)` methods must be available
- `gap::T`
- `folds::int`
"""
abstract type PatternFold{T, P} end

"""
    pattern(<:PatternFold)
Return the *pattern* of any `PatternFold`. The pattern defines the occurences of the first fold.
"""
pattern(pf) = pf.pattern

"""
    gap(<:PatternFold)
Return the *gap* between the starts of consecutive folds.
"""
gap(pf) = pf.gap

"""
    folds(<:PatternFold)
Return the number of *folds*. An infinite folded pattern returns `0`.
"""
folds(pf) = pf.folds

# Forwards isempty, ndims
@forward PatternFold.pattern isempty, ndims

# TODO - look if another name is more appropriate
"""
    pattern_length(pf<:PatternFold)
Return the length of the basic pattern of `pf`.
"""
pattern_length(pf) = length(pattern(pf))

"""
    length(pf<:PatternFold)
Return the length of `pf` if unfolded.
"""

Base.length(pf::PatternFold) = pattern_length(pf) * folds(pf)

"""
    eltype(pf<: PatternFolds)
"""
Base.eltype(::Type{<:PatternFold{T,P}}) where {T,P} = T

"""
    rand(pf<:PatternFold)
Returns a random value of `pf` as if it was unfolded.
"""
function Base.rand(pf::PF) where {PF <: PatternFold}
    return Base.rand(pattern(pf)) + Base.rand(0:(folds(pf) - 1)) * gap(pf)
end
