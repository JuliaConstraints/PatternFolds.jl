abstract type PatternFold{T, P} end

pattern(pf) = pf.pattern
gap(pf) = pf.gap
folds(pf) = pf.folds

# TODO - look if another name is more appropriate
pattern_length(pf) = length(pattern(pf))

length(pf) = pattern_length(pf) * folds(pf)

function rand(pf::PF) where {PF <: PatternFold}
    return rand(pattern(pf)) + rand(0:(folds(pf) - 1)) * gap(pf)
end
