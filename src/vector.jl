"""
    VectorFold{T,V <: AbstractVector{T}}
A mutable structure for folded vector that extends the methods of AbstractVector. Compared to `IVectorFold`, this tructure is about 20% faster using iterators.
Note that this structure keep an active pointer to the `current` *unfolded* pattern. However, its external behavior is similar to `IVectorFold`.
"""
mutable struct VectorFold{T, V <: AbstractVector{T}} <: AbstractVectorFold{T}
    pattern::V
    gap::T
    folds::Int
    current::Int
end

VectorFold(p, g, f; c = 1) = VectorFold(p, g, f, c)

pattern_length(mvf::VectorFold) = length(mvf.pattern)

function pattern(mvf::VectorFold)
    distortion = gap(mvf) * (mvf.current - 1)
    return mvf.pattern .- distortion
end

pattern(mvf::VectorFold, index) = pattern(mvf)[index]

"""
    set_fold!(mvf::VectorFold, new_fold = mvf.current + 1)
Set the *unfolded* pattern to `new_fold`. By default move the next *fold* after `current`.
"""
function set_fold!(mvf, new_fold = mvf.current + 1)
    if new_fold != mvf.current && 0 < new_fold ≤ mvf.folds
        distortion = gap(mvf) * (new_fold - mvf.current)
        mvf.pattern .+= distortion
        mvf.current = new_fold
    end
end

# Base case iterate method
function Base.iterate(iter::VectorFold)
    reset_pattern!(iter)
    return pattern(iter, 1), 1
end

# "Induction" iterate method
function Base.iterate(iter::VectorFold, state::Int)
    state ≥ length(iter) && return nothing

    next_state = state + 1
    pl = pattern_length(iter)

    pattern_counter = mod1(next_state, pl)
    elem = iter.pattern[pattern_counter]
    pattern_counter == pl && set_fold!(iter)

    return elem, next_state
end

# Reverse iterate method
function Base.iterate(
        r_iter::Base.Iterators.Reverse{VectorFold{T, V}}, state::Int = length(r_iter.itr)
) where {T, V}
    state < 1 && return nothing

    iter = r_iter.itr
    state == length(iter) && set_fold!(iter, iter.folds)

    next_state = state - 1
    pl = pattern_length(iter)

    pattern_counter = mod(next_state, pl) + 1
    elem = iter.pattern[pattern_counter]
    pattern_counter == 1 && set_fold!(iter, iter.current - 1)

    return elem, next_state
end

# Specific dispatch for MVectorFold
function Base.rand(mvf::VectorFold)
    return Base.rand(mvf.pattern) +
           Base.rand((1 - mvf.current):(folds(mvf) - mvf.current)) * gap(mvf)
end

Base.rand(mvf::VectorFold, n::Int) = map(_ -> rand(mvf), 1:n)

# Specific dispatch for MVectorFold
function unfold(mvf::VectorFold; from = 1, to = folds(mvf))
    pl = pattern_length(mvf)
    ul = (to - from + 1) * pl
    v = typeof(mvf.pattern)(undef, ul)

    count = 0
    for fold in from:to
        set_fold!(mvf, fold)
        for i in 1:pl
            v[count * pl + i] = mvf.pattern[i]
        end
        count += 1
    end
    return v
end

make_vector_fold(pattern, gap, fold, ::Val{:mutable}) = VectorFold(pattern, gap, fold)

@testitem "VectorFold" tags=[:vectors] begin
    vf_dict = Dict([
        make_vector_fold([1, 2], 10, 5, :immutable) => Dict(
            :pattern => [1, 2],
            :gap => 10,
            :folds => 5,
            :length => 10,
            :unfold => [1, 2, 11, 12, 21, 22, 31, 32, 41, 42],
            :reverse => reverse([1, 2, 11, 12, 21, 22, 31, 32, 41, 42])
        ),
        make_vector_fold([1, 2], 10, 5, :mutable) => Dict(
            :pattern => [1, 2],
            :gap => 10,
            :folds => 5,
            :length => 10,
            :unfold => [1, 2, 11, 12, 21, 22, 31, 32, 41, 42],
            :reverse => reverse([1, 2, 11, 12, 21, 22, 31, 32, 41, 42])
        )
    ])

    for (vf, results) in vf_dict
        @test pattern(vf) == results[:pattern]
        @test gap(vf) == results[:gap]
        @test folds(vf) == results[:folds]
        @test length(vf) == results[:length]
        @test unfold(vf) == results[:unfold]
        @test ndims(vf) == 1
        @test mapreduce(x -> x ∈ vf, *, rand(vf, 10))
        @test collect(vf) == [i for i in vf] == unfold(vf)
        @test collect(Iterators.reverse(vf)) == results[:reverse]
        @test reverse(collect(vf)) == results[:reverse]
    end
    @test isempty(make_vector_fold(Vector(), 1, 1, :immutable))
    @test isempty(make_vector_fold(Vector(), 1, 1))

    v1 = make_vector_fold([42, 3, 45, 6], 13, 4)
    w1 = unfold(v1)
    v11 = fold(w1)

    @test unfold(v11) == w1

    v2 = make_vector_fold([34, 34, 43, 43], 10, 3)
    w2 = unfold(v2)
    v22 = fold(w2)

    @test unfold(v22) == w2

    v3 = make_vector_fold([42, 3, 45, 6], 13, 4, :immutable)
    w3 = unfold(v3)
    v33 = fold(w3)

    @test unfold(v33) == w3
    collect(Iterators.reverse(v33))
end
