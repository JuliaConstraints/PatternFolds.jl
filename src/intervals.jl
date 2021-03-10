
struct Interval{T <: Real}
    a::Tuple{T, Bool}
    b::Tuple{T, Bool}
end

const Intervals{T} = Vector{Interval{T}}

a(i) = i.a
b(i) = i.b

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
end

@forward IntervalsFold.pattern a, b

+(bound::Tuple{T, Bool}, gap::T) where T = bound[1]+gap, bound[2]

function unfold(isf::IntervalsFold)
    x, y = a(isf), b(isf)
    g = gap(isf)
    f = folds(isf)
    return map(i -> Interval(x + g * i, y + g * i), 0:(f - 1))
end
