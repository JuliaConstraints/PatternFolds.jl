"""
    VectorFold{T,V <: AbstractVector{T}}
A folded vector structure that extends the methods of AbstractVector to a folded structure.
"""
struct VectorFold{T,V <: AbstractVector{T}} <: PatternFold{T,V}
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
function unfold(vf::VectorFold; from=1, to=folds(vf))
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

# Base case iterate method
function Base.iterate(iter::VectorFold)
    if any(isempty.((pattern(iter), gap(iter), folds(iter))))
		return nothing
	end

    return first(pattern(iter)), 0
end

# "Induction" iterate method
function Base.iterate(iter::VectorFold, state::Int)
    state += 1
		
    if state >= length(iter)
        return nothing
    end
	
	pattern_counter = mod1(state + 1, length(pattern(iter)))
	fold_counter = state ÷ length(pattern(iter))
	elem = pattern(iter)[pattern_counter] + (fold_counter * gap(iter))
		
	return elem, state
end
