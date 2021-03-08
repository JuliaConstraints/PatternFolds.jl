
struct VectorFold{T,V <: AbstractVector{T}} <: PatternFold{T,V}
    pattern::V
    gap::T
    folds::Int
end

pattern(vf, index) = pattern(vf)[index]

# REVIEW - how to optimize assignation
# TODO - can unfold be made almost generic?
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
