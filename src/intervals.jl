
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
+(bound::Tuple{T, Bool}, gap::T) where T = bound[1]+gap, bound[2]
+(i::Interval, gap) = Interval(a(i) + gap, b(i) + gap)

function Base.in(value, i::Interval)
    x, y = value(i, :a), value(i, :b)
    lesser = closed(i, :a) ? x ≤ value : x < value
    greater = closed(i, :b) ? x ≥ value : x > value
    return lesser && greater
end

value(i, ::Val{:a}) = i.a[1]
value(i, ::Val{:b}) = i.b[1]
value(i, bound) = value(i, Val(bound))

closed(i, ::Val{:a}) = i.a[2]
closed(i, ::Val{:b}) = i.b[2]
closed(i, bound) = closed(i, Val(bound))
opened(i, bound) = !closed(i, bound)

Base.length(i::Interval) = value(i, :b) - value(i, :a)
Base.isempty(i::Interval) = lenght(i) == 0 && (opened(i, :a) || opened(i, :b))
Base.ndims(::Interval) = 1
Base.rand(i::Interval) = rand() * length(i) + value(i, :a)

mutable struct IntervalsFold{T <: Real} <: PatternFold{T, Interval{T}}
    pattern::Interval{T}
    gap::T
    folds::Int
    current::Int
end

IntervalsFold(p, g, f, c = 1) = IntervalsFold(p, g, f, c)

@forward IntervalsFold.pattern a, b

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
    set_fold!(iter, next_state)
	return  iter.pattern, next_state
end

Base.in(val, isf::IntervalsFold) = any(i -> val ∈ i, isf)