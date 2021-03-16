"""
    MVectorFold{T,V <: AbstractVector{T}}
A mutable structure for folded vector that extends the methods of AbstractVector. Compared to `VectorFold`, this tructure is about 20% faster using iterators. Unfolding is twice slower though.
Note that this structure keep an active pointer to the `current` *unfolded* pattern. However, its external behavior is similar to `VectorFold`.
"""
mutable struct VectorFold{T,V <: AbstractVector{T}} <: PatternFold{T,V}
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
    set_fold!(mvf::MVectorFold, new_fold = mvf.current + 1)
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
function Base.iterate(r_iter::Base.Iterators.Reverse{VectorFold{T,V}},
    state::Int = length(r_iter.itr)
) where {T,V}
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
    return Base.rand(mvf.pattern) + Base.rand((1 - mvf.current):(folds(mvf) - mvf.current)) * gap(mvf)
end

# Specific dispatch for MVectorFold
function unfold(mvf::VectorFold; from=1, to=folds(mvf))
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
