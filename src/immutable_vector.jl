"""
    VectorFold{T,V <: AbstractVector{T}}
A folded vector structure that extends the methods of AbstractVector to a folded structure.
"""
struct IVectorFold{T,V <: AbstractVector{T}} <: PatternFold{T,V}
    pattern::V
    gap::T
    folds::Int
end

"""
    pattern(vf, index)
Return the element at `index` in the original pattern.
"""
pattern(vf, index) = pattern(vf)[index]

# REVIEW - how to optimize assignation
# TODO - can unfold be made almost generic?
"""
    unfold(vf::VectorFold; from=1, to=folds(vf))
Construct the unfolded version of `vf` (with the same type as `pattern(vf)`) based. Please note that using an iterator on `vf` avoid memory allocation, which is not the case of `unfold`.
"""
function unfold(vf::IVectorFold; from=1, to=folds(vf))
    pl = pattern_length(vf)
    ul = (to - from + 1) * pl
    v = typeof(pattern(vf))(undef, ul)

    count = 0
    for fold in from:to
        for i in 1:pl
            v[count * pl + i] = pattern(vf, i) + (fold - 1) * gap(vf)
        end
        count += 1
    end
    return v
end

"""
    iterate(iter)
Extends `iterate` methods from `Base` to allow forward and reverse iteration on both `VectorFold` and `MVectorFold`.
"""
Base.iterate(iter::IVectorFold) = (pattern(iter, 1), 1) # Base case iterate method

# "Induction" iterate method
function Base.iterate(iter::IVectorFold, state::Int)
    state ≥ length(iter) && return nothing

	next_state = state + 1
    pl = pattern_length(iter)

	pattern_counter = mod1(next_state, pl)
	fold_counter = state ÷ pl
	elem = pattern(iter, pattern_counter) + (fold_counter * gap(iter))

	return elem, next_state
end

# Reverse iterate method
function Base.iterate(r_iter::Base.Iterators.Reverse{IVectorFold{T,V}},
    state::Int = length(r_iter.itr)
) where {T,V}
	state < 1 && return nothing

	next_state = state - 1
	iter = r_iter.itr
    pl = pattern_length(iter)

	pattern_counter = mod1(state, pl)
	fold_counter = next_state ÷ pl
	elem = pattern(iter, pattern_counter) + (fold_counter * gap(iter))

	return elem, next_state
end

# Folding a vector to give a suitable VectorFold
check_pattern(v, w, gap) = all(i -> i == gap, w - v)

function check_pattern(v, i, gap, fold)
    for j in 1:(fold -1)
        v_start, v_end = (j - 1) * i + 1, j * i
        w_start, w_end = j * i + 1, (j + 1) * i
        !check_pattern(v[v_start:v_end], v[w_start:w_end], gap) && return false
    end
    return true
end

make_vector_fold(pattern, gap, fold, ::Val{:immutable}) = IVectorFold(pattern, gap, fold)
