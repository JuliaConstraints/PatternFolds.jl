struct Interval{T <: Real}
    a::Tuple{T, Bool}
    b::Tuple{T, Bool}

    function Interval{T}(a, b) where {T <: Real}
        bounds = (a[1] < b[1] ? (a, b) : (b, a))
        return new{T}(bounds[1], bounds[2])
    end
end
Interval(a, b) = Interval{typeof(a[1])}(a,b)

a(i) = i.a
b(i) = i.b
Base.:+(bound::Tuple{T, Bool}, gap::T) where T = bound[1]+gap, bound[2]
Base.:+(i::Interval, gap) = Interval(a(i) + gap, b(i) + gap)

value(i, ::Val{:a}) = i.a[1]
value(i, ::Val{:b}) = i.b[1]
value(i, bound) = value(i, Val(bound))

closed(i, ::Val{:a}) = i.a[2]
closed(i, ::Val{:b}) = i.b[2]
closed(i, bound) = closed(i, Val(bound))
opened(i, bound) = !closed(i, bound)

function a_isless(i₁, i₂)
    a₁ = value(i₁, :a)
    a₂ = value(i₂, :a)
    return a₁ == a₂ ? closed(i₁, :a) || opened(i₂, :a) : a₁ < a₂
end

a_ismore(i₁, i₂) = a_isless(i₂, i₁)

function b_ismore(i₁, i₂)
    b₁ = value(i₁, :b)
    b₂ = value(i₂, :b)
    return b₁ == b₂ ? closed(i₁, :b) || opened(i₂, :b) : b₁ > b₂
end

b_isless(i₁, i₂) = b_ismore(i₂, i₁)

function Base.in(val, i::Interval)
    (x, y) = (value(i, :a), value(i, :b))
    lesser = closed(i, :a) ? x ≤ val : x < val
    greater = closed(i, :b) ? y ≥ val : y > val
    return lesser && greater
end

Base.length(i::Interval) = 1
Base.size(i::Interval) = value(i, :b) - value(i, :a)
Base.isempty(i::Interval) = size(i) == 0 && (opened(i, :a) || opened(i, :b))
Base.ndims(::Interval) = 1
Base.rand(i::Interval) = rand() * size(i) + value(i, :a)

mutable struct IntervalsFold{T <: Real} <: PatternFold{T, Interval{T}}
    pattern::Interval{T}
    gap::T
    folds::Int
    current::Int
end

IntervalsFold(p, g, f, c = 1) = IntervalsFold(p, g, f, c)

@forward IntervalsFold.pattern a, b, Base.isempty

function pattern(isf::IntervalsFold)
    distortion = gap(isf) * (isf.current - 1)
    return isf.pattern + (-distortion)
end

function unfold(isf::IntervalsFold)
    reset_pattern!(isf)
    x, y = a(isf), b(isf)
    g = gap(isf)
    f = folds(isf)
    return map(i -> Interval(x + g * i, y + g * i), 0:(f - 1))
end

function set_fold!(isf::IntervalsFold, new_fold = isf.current + 1)
    if new_fold != isf.current && 0 < new_fold ≤ isf.folds
        distortion = gap(isf) * (new_fold - isf.current)
        isf.pattern += distortion
        isf.current = new_fold
    end
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
function Base.iterate(r_iter::Base.Iterators.Reverse{IntervalsFold{T}},
    state::Int = length(r_iter.itr)) where {T}
	state < 1 && return nothing
	iter = r_iter.itr
    next_state = state - 1
    set_fold!(iter, state)
	return  iter.pattern, next_state
end

function Base.in(val, isf::IntervalsFold)
    reset_pattern!(isf)
    return any(i -> val ∈ i, isf)
end

Base.size(isf::IntervalsFold) = size(isf.pattern) * folds(isf)

Base.eltype(::Type{<:IntervalsFold{T}}) where {T} = Interval{T}
