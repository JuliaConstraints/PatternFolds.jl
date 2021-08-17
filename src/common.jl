"""
    AbstractVectorFold{T, P}
An abstract type used as an interface for folded vectors such as `VectorFold`.
To implement the interface and inherit from it, a new structure must define three fields:
- `pattern::P`. Note that both `length(::P)` and `rand(::P)` methods must be available
- `gap::T`
- `folds::int`
"""
abstract type AbstractVectorFold{T} <: AbstractVector{T} end

"""
    PatternFold{T, P}
A `Union` type used as an interface for folded patterns such as `VectorFold`.
To implement the interface and inherit from it, a new structure `MyFold{T[,P]}` must define three fields:
- `pattern::P`. Note that both `length(::P)` and `rand(::P)` methods must be available
- `gap::T`S
- `folds::int`
Finally one can redefine PatternFold{T}
```julia
PatternFold{T} = Union{AbstractVectorFold{T}, IntervalsFold{T}, MyFold{T[,P]}}
```
"""
PatternFold = Union{AbstractVectorFold, IntervalsFold}

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

"""
    make_vector_fold(pattern, gap, fold, kind = :mutable)
A dispatcher to construct a folded vector. The `kind` of vector can be set to either `:mutable` (default) or `:immutable`. The default is faster in most cases but it depends on the `pattern`, `gap`, and `fold` parameters. For critical code, it is recommended to benchmark both options.
"""
function make_vector_fold(pattern, gap, fold, kind = :mutable)
    return make_vector_fold(pattern, gap, fold, Val(kind))
end
function make_vector_fold(isf; kind = :mutable)
    vf = kind == :mutable ? "VectorFold" : "IVectorFold"
    str = "The pattern of the interval is not a point." *
        " The IntervalsFold cannot be converted to a $vf"
    @assert is_points(isf) str

    return make_vector_fold([value(pattern(isf), :a)], gap(isf), folds(isf), kind)
end

function Base.print_array(io::IO, X::AbstractVectorFold)
    print(io, "\tPattern: $(pattern(X))\n\tGap: $(gap(X))\n\tFolds: $(folds(X))")
end

function Base.getindex(vf::AbstractVectorFold, key)
    d, r = divrem(key + 1, pattern_length(vf))
    return (d - 1) * gap(vf) + pattern(vf, r + 1)
end
Base.getindex(vf::AbstractVectorFold, key...) = map(k -> getindex(vf, k), key)
