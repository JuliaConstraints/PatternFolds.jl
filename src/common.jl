"""
    AbstractVectorFold{T, P}
An abstract stype used as an interface for folded patterns such as `VectorFold`.
To implement the interface and inherit from it, a new structure must define three fields:
- `pattern::P`. Note that both `length(::P)` and `rand(::P)` methods must be available
- `gap::T`
- `folds::int`
"""
abstract type AbstractVectorFold{T} <: AbstractVector{T} end

PatternFold{T} = Union{AbstractVectorFold{T}, IntervalsFold{T}}

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
@forward PatternFold.pattern Base.isempty, Base.ndims

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
Base.size(pf::PatternFold) = (length(pf),)

"""
    eltype(pf<: PatternFolds)
"""
Base.eltype(::Type{<:PatternFold{T}}) where {T} = T

"""
    rand(pf<:PatternFold)
Returns a random value of `pf` as if it was unfolded.
"""
function Base.rand(pf::PF) where {PF <: PatternFold}
    return Base.rand(pattern(pf)) + Base.rand(0:(folds(pf) - 1)) * gap(pf)
end

"""
    reset_pattern!(<:PatternFold)
Reset the *unfolded* pattern to the first fold.
"""
reset_pattern!(mvf) = set_fold!(mvf, 1)

"""
    fold(v::V, depth = 0)
returns a suitable `VectorFold`, which when unfolded gives the Vector V.
"""
function fold(v::V, depth = 0; kind = :mutable) where {T <: Real, V <: AbstractVector{T}}
    l = length(v)
    for i in 1:(l ÷ 2)
        gap = v[i + 1] - v[1]
        fold, r = divrem(l, i)
        if  r == 0 && check_pattern(v, i, gap, fold)
            # return VectorFold(fold(v[1:i], depth + 1), gap, fold)
            return make_vector_fold(v[1:i], gap, fold, kind)
        end
    end
    if depth == 0
        @warn "No non-degenerate patterns have been found" v
        return make_vector_fold(v, zero(T), 1, kind)
    else
        return v
    end
end

function make_vector_fold(pattern, gap, fold, kind = :mutable)
    return make_vector_fold(pattern, gap, fold, Val(kind))
end
