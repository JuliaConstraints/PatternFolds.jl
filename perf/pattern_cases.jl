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
end
