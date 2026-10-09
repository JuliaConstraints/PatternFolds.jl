module PatternCases
import PatternFolds as PF
function copied_pattern(values, width, gap, repetitions)
    for j in 1:(repetitions - 1)
        left = values[((j - 1) * width + 1):(j * width)]
        right = values[(j * width + 1):((j + 1) * width)]
        all(==(gap), right - left) || return false
    end
    true
end
current(state) = PF.check_pattern(state.values, 1, 1, length(state.values))
original(state) = copied_pattern(state.values, 1, 1, length(state.values))
function pattern(parameters)
    values = collect(1:Int(get(parameters, "n", 1000)))
    operation = get(parameters, "method", "current") == "original" ? original : current
    (; prepare=() -> (; values=copy(values)), operation,
        verify=(state, result) -> result === true && state.values == values)
end

scalar_current(state) = PF.pattern(state.fold, state.index)
scalar_original(state) = invoke(PF.pattern, Tuple{PF.VectorFold, Any}, state.fold, state.index)
function mutable_scalar(parameters)
    n = Int(get(parameters, "n", 1000))
    n >= 1 || throw(ArgumentError("positive pattern width required"))
    T = get(parameters, "type", "integer") == "float" ? Float64 : Int
    values = T.(1:n)
    gap = T(3)
    index = Int(get(parameters, "index", 1))
    expected = (values .- gap)[index]
    operation = get(parameters, "method", "current") == "original" ?
                scalar_original : scalar_current
    (; prepare=() -> (; fold=PF.VectorFold(copy(values), gap, 4; c=2), index),
        operation,
        verify=(state, result) -> isequal(result, expected) && typeof(result) === typeof(expected) &&
                                 state.fold.pattern == values && state.fold.current == 2 &&
                                 state.fold.gap == gap && state.fold.folds == 4)
end
end
