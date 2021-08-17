# _maxfloat(::Type{T}) where {T<:AbstractFloat} = prevfloat(typemax(T))
# _minfloat(::Type{T}) where {T<:AbstractFloat} = nextfloat(typemin(T))

Base.ndims(::Interval) = 1

function Base.rand(i::Interval{T,L,R}) where {T,L,R}
    # α = max(_minfloat(T), first(i))
    # β = min(_maxfloat(T), last(i))
    μ = maxintfloat(T, Int)
    α = max(-μ, first(i))
    β = min(μ, last(i))
    δ = β - α
    # if δ === Inf
    if δ > μ
        return rand(rand() < 0.5 ? α..zero(T) : zero(T)..β)
    else
        # r = α + exp10(log10(δ) * rand())
        r = α + δ * rand()
        r ∉ i && return rand(i)
        return r
    end
end

# TODO - Optimise the type of Intervals.Bound (currently abstract super type)
mutable struct IntervalsFold{T<:AbstractFloat,L<:Intervals.Bound,R<:Intervals.Bound}
    pattern::Interval{T,L,R}
    gap::T
    folds::Int
    current::Int
end

IntervalsFold(p, g, f, c=1) = IntervalsFold(p, g, f, c)

@forward IntervalsFold.pattern Base.isempty, Base.ndims

Base.lastindex(isf::IntervalsFold) = folds(isf)

Base.getindex(isf::IntervalsFold, key...) = map(k -> get_fold!(isf, k), key)

function pattern(isf::IntervalsFold)
    distortion = gap(isf) * (isf.current - 1)
    return isf.pattern + (-distortion)
end

function unfold(isf::IntervalsFold{T,L,R}) where {T,L,R}
    reset_pattern!(isf)
    x = first(pattern(isf))
    y = last(pattern(isf))
    g = gap(isf)
    f = folds(isf)
    return [Interval{T,L,R}(x + g * i, y + g * i) for i in 0:(f - 1)]
end

function set_fold!(isf::IntervalsFold, new_fold=isf.current + 1)
    if new_fold != isf.current && 0 < new_fold ≤ isf.folds
        distortion = gap(isf) * (new_fold - isf.current)
        isf.pattern += distortion
        isf.current = new_fold
    end
end

function get_fold!(isf::IntervalsFold, f)
    set_fold!(isf, f)
    return isf.pattern
end

function Base.iterate(iter::IntervalsFold)
    reset_pattern!(iter)
    return pattern(iter), 1
end

# "Induction" iterate method
function Base.iterate(iter::IntervalsFold, state::Int)
    state ≥ folds(iter) && return nothing
    set_fold!(iter)
    return iter.pattern, state + 1
end

# Reverse iterate method
function Base.iterate(
    r_iter::Base.Iterators.Reverse{<:IntervalsFold}, state::Int=length(r_iter.itr)
)
    state < 1 && return nothing
    iter = r_iter.itr
    next_state = state - 1
    set_fold!(iter, state)
    return iter.pattern, next_state
end

function Base.in(val, isf::IntervalsFold)
    reset_pattern!(isf)
    return any(i -> val ∈ i, isf)
end

Base.size(isf::IntervalsFold) = span(isf.pattern) * folds(isf)

Base.length(isf::IntervalsFold) = folds(isf)

Base.eltype(::Type{<:IntervalsFold{T,L,R}}) where {T,L,R} = Interval{T,L,R}

is_points(isf) = is_point(pattern(isf))

pattern_length(isf::IntervalsFold) = span(pattern(isf))

function Base.rand(isf::IntervalsFold)
    i = rand(1:folds(isf)) - 1
    p = pattern(isf)
    return rand(p) + i * gap(isf)
end
