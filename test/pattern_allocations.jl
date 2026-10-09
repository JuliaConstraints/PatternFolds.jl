@testitem "Primitive pattern checks avoid materialized slices" begin
    function reference(v, width, gap, repetitions)
        return all(1:(repetitions - 1)) do j
            left = v[((j - 1) * width + 1):(j * width)]
            right = v[(j * width + 1):((j + 1) * width)]
            all(==(gap), right - left)
        end
    end
    for n in 1:6, assignment in Iterators.product(ntuple(_ -> -1:1, n)...)
        values = collect(assignment)
        for width in 1:n, gap in -2:2
            repetitions, remainder = divrem(n, width)
            iszero(remainder) || continue
            @test check_pattern(values, width, gap, repetitions) ==
                  reference(values, width, gap, repetitions)
        end
    end
    for T in (Int8, UInt8, Int, Float16, Float32, Float64)
        left = T[1, 2, 3]
        right = T[3, 4, 5]
        @test check_pattern(left, right, 2) == all(==(2), right - left)
        @test check_pattern(view(left, :), view(right, :), 2)
        @test_throws DimensionMismatch check_pattern(left, right[1:2], 2)
    end
    values = [NaN, Inf, -Inf, -0.0, 0.0]
    @test check_pattern(values, copy(values), 0.0) == all(iszero, values - values)
    values = collect(1:1000)
    saved = copy(values)
    allocations(values) = (check_pattern(values, 1, 1, length(values));
        @allocated check_pattern(values, 1, 1, length(values)))
    @test allocations(values) == 0
    @test values == saved
    @test unfold(fold(values; kind=:immutable)) == values

    struct MutatingGap
        right::Vector{Int}
    end
    function Base.:(==)(difference::Integer, gap::MutatingGap)
        gap.right[2] = 99
        return iszero(difference)
    end
    left = ones(Int, 3)
    right = ones(Int, 3)
    @test check_pattern(left, right, MutatingGap(right))
    @test right == [1, 99, 1]
end

@testitem "Pattern checks preserve custom storage reads" begin
    import PatternFolds: check_pattern

    struct ObservedPatternDense{F} <: DenseArray{Int,1}
        values::Vector{Int}
        events::Vector{Tuple{Symbol,Symbol,Int}}
        name::Symbol
        throw_at::Int
        onread::F
    end
    Base.IndexStyle(::Type{<:ObservedPatternDense}) = IndexLinear()
    Base.size(values::ObservedPatternDense) = size(values.values)
    function Base.axes(values::ObservedPatternDense)
        push!(values.events, (:axes, values.name, 0))
        return axes(values.values)
    end
    function Base.getindex(values::ObservedPatternDense, index::Int)
        push!(values.events, (:read, values.name, index))
        index == values.throw_at && error("late pattern read")
        values.onread(index)
        return values.values[index]
    end
    function capture(f)
        try
            return (:result, f())
        catch error
            payload = error isa ErrorException ? error.msg :
                      error isa BoundsError ? error.i : nothing
            return (:error, typeof(error), payload)
        end
    end
    function fixture(kind, throw_at, mutate, matches)
        left = zeros(Int, 3)
        right = matches ? zeros(Int, 3) : [1, 2, 3]
        events = Tuple{Symbol,Symbol,Int}[]
        onread = index -> (mutate && index == 2 && (right[end] = 99); nothing)
        a = kind == :right ? left :
            ObservedPatternDense(left, events, :left, throw_at, onread)
        b = kind == :left ? right :
            ObservedPatternDense(right, events, :right, throw_at, onread)
        if kind == :views
            a, b = view(a, :), view(b, :)
        elseif kind == :reshaped
            a = view(reshape(a, 3, 1), :, 1)
            b = view(reshape(b, 3, 1), :, 1)
        end
        empty!(events)
        return (; a, b, left, right, events)
    end
    for kind in (:left, :right, :both, :views, :reshaped),
            throw_at in (0, 2, 3), mutate in (false, true), matches in (false, true)
        actual = fixture(kind, throw_at, mutate, matches)
        expected = fixture(kind, throw_at, mutate, matches)
        @test capture(() -> check_pattern(actual.a, actual.b, 0)) ==
              capture(() -> invoke(check_pattern, Tuple{Any,Any,Any},
                                  expected.a, expected.b, 0))
        @test actual.events == expected.events
        @test actual.left == expected.left
        @test actual.right == expected.right
    end
    late = fixture(:right, 3, false, false)
    @test_throws ErrorException check_pattern(late.a, late.b, 0)
    @test [event[3] for event in late.events if event[1] == :read] == [1, 2, 3]
end

@testitem "Pattern slice parameters retain original behavior" begin
    import PatternFolds: check_pattern

    function capture(f)
        try
            return (:result, f())
        catch error
            return (:error, typeof(error), error isa BoundsError ? error.i : nothing)
        end
    end
    for width in (-2, -1, 0, 1, 2, 3, 4, typemax(Int),
                  false, true, Int8(1), UInt(1), 1.0, 1.5, big(1), 1//1),
            repetitions in (-1, 0, 1, 2, 3, 4, false, true,
                            Int8(3), UInt(3), 3.0, 2.5, big(3), 3//1)
        values = collect(1:6)
        @test capture(() -> check_pattern(values, width, 1, repetitions)) ==
              capture(() -> invoke(check_pattern, Tuple{Any,Any,Any,Any},
                                  values, width, 1, repetitions))
        @test values == collect(1:6)
    end

    # Arbitrary width arithmetic must keep its original callback sequence.
    struct ObservedPatternWidth
        values::Vector{Int}
        events::Vector{Int}
    end
    function Base.:(*)(factor::Integer, width::ObservedPatternWidth)
        push!(width.events, factor)
        width.values[end] = 99
        return factor
    end
    for repetitions in (0, 1, 2, 3, 4, 7)
        actual, expected = collect(1:6), collect(1:6)
        actual_events, expected_events = Int[], Int[]
        actual_width = ObservedPatternWidth(actual, actual_events)
        expected_width = ObservedPatternWidth(expected, expected_events)
        @test capture(() -> check_pattern(actual, actual_width, 1, repetitions)) ==
              capture(() -> invoke(check_pattern, Tuple{Any,Any,Any,Any},
                                  expected, expected_width, 1, repetitions))
        @test actual_events == expected_events
        @test actual == expected
    end

    allocations(left, right) = (check_pattern(left, right, 0);
        @allocated check_pattern(left, right, 0))
    values = collect(1:1000)
    @test allocations(values, copy(values)) == 0
    @test allocations(view(values, :), view(values, :)) == 0
    @test allocations(view(reshape(values, 1000, 1), :, 1), view(values, :)) == 0
    @test allocations(reinterpret(UInt, values), reinterpret(UInt, values)) == 0
    memory = Memory{Int}(undef, length(values))
    memory .= values
    @test allocations(memory, memory) == 0
end
