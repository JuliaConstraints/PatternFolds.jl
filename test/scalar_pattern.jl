@testitem "Mutable pattern scalar reads preserve eager semantics" default_imports=false begin
    import PatternFolds as PF
    import Test: @test
    import Random: Xoshiro, rand

    reference(vf, index) = invoke(PF.pattern, Tuple{PF.VectorFold, Any}, vf, index)
    capture(fn, vf, index) = try
        fn(vf, index)
    catch exception
        exception
    end
    function same_result(actual, expected)
        @test typeof(actual) === typeof(expected)
        if expected isa Exception
            if expected isa BoundsError
                @test isequal(actual.i, expected.i)
                @test typeof(actual.a) === typeof(expected.a)
                @test isequal(actual.a, expected.a)
                if eltype(expected.a) <: PF._PatternScalar
                    @test collect(reinterpret(UInt8, actual.a)) ==
                          collect(reinterpret(UInt8, expected.a))
                end
            end
        else
            @test isequal(actual, expected)
            if expected isa Union{Float16, Float32, Float64}
                @test reinterpret(UInt8, [actual]) == reinterpret(UInt8, [expected])
            elseif expected isa AbstractArray{<:PF._PatternScalar}
                @test reinterpret(UInt8, actual) == reinterpret(UInt8, expected)
            end
        end
    end
    function check(vf, index)
        before = copy(vf.pattern)
        current = vf.current
        actual = capture(PF.pattern, vf, index)
        expected = capture(reference, vf, index)
        same_result(actual, expected)
        @test isequal(vf.pattern, before)
        @test vf.current == current
    end

    types = (Bool, Int8, Int16, Int32, Int64, Int128,
        UInt8, UInt16, UInt32, UInt64, UInt128, Float16, Float32, Float64)
    for T in types
        values = if T === Bool
            Bool[false, true]
        elseif T <: Unsigned
            T[0, 1, typemax(T)]
        elseif T <: Signed
            T[typemin(T), -1, 0, 1, typemax(T)]
        else
            nan1, nan2 = T === Float16 ? (reinterpret(T, UInt16(0x7e01)), reinterpret(T, UInt16(0xfe12))) :
                         T === Float32 ? (reinterpret(T, UInt32(0x7fc00001)), reinterpret(T, UInt32(0xffc00012))) :
                         (reinterpret(T, UInt64(0x7ff8000000000001)), reinterpret(T, UInt64(0xfff8000000000012)))
            T[-Inf, -1, -zero(T), zero(T), nextfloat(zero(T)), 1, Inf, nan1, nan2]
        end
        for gap in values, current in (-2, 0, 1, 2, 5)
            vf = PF.VectorFold(copy(values), gap, 5; c=current)
            for index in 0:(length(values) + 1)
                check(vf, index)
            end
        end
        vf = PF.VectorFold(copy(values), zero(T), 5; c=2)
        for index in (Int32(1), UInt(1), CartesianIndex(1), 1:1, [1], :, true, -1)
            check(vf, index)
        end
        empty = PF.VectorFold(T[], zero(T), 1)
        check(empty, 1)
    end

    rng = Xoshiro(2719)
    for T in (Float16, Float32, Float64), _ in 1:200
        U = T === Float16 ? UInt16 : T === Float32 ? UInt32 : UInt64
        values = collect(reinterpret(T, rand(rng, U, 33)))
        gap = reinterpret(T, rand(rng, U))
        current = rand(rng, (-655, 0, 1, 2, 3, 34, 11001, typemin(Int) + 1, typemax(Int)))
        vf = PF.VectorFold(values, gap, 5; c=current)
        for index in (0, 1, 17, 33, 34)
            check(vf, index)
        end
    end

    for values in (BigInt[1, 3, 5], BigFloat[1, -0.0, Inf],
            [1//2, 3//4, 5//6]), current in (1, 2, 4)
        vf = PF.VectorFold(copy(values), one(eltype(values)), 4; c=current)
        for index in (0, 1, 2, 4)
            check(vf, index)
        end
    end

    struct ObservedPattern <: AbstractVector{Int}
        values::Vector{Int}
        reads::Vector{Int}
    end
    Base.size(values::ObservedPattern) = size(values.values)
    Base.IndexStyle(::Type{ObservedPattern}) = IndexLinear()
    function Base.getindex(values::ObservedPattern, index::Int)
        push!(values.reads, index)
        index == 1 && (values.values[2] = 99)
        return values.values[index]
    end
    first_pattern = ObservedPattern([1, 2, 3], Int[])
    second_pattern = ObservedPattern([1, 2, 3], Int[])
    observed_actual = PF.VectorFold(first_pattern, 2, 3; c=2)
    observed_expected = PF.VectorFold(second_pattern, 2, 3; c=2)
    same_result(PF.pattern(observed_actual, 1), reference(observed_expected, 1))
    @test first_pattern.reads == second_pattern.reads
    @test first_pattern.values == second_pattern.values == [1, 99, 3]

    # Starting iteration resets the mutable fold; later steps keep its pointer
    # and shifted backing vector. Compare both against the original first read.
    function original_start(vf)
        PF.reset_pattern!(vf)
        return reference(vf, 1), 1
    end
    for T in (Int8, Int, Float16, Float32, Float64), width in (1, 2, 5),
        current in (1, 2, 4)
        values = T.(1:width)
        actual = PF.VectorFold(copy(values), T(3), 4; c=current)
        expected = PF.VectorFold(copy(values), T(3), 4; c=current)
        actual_start = iterate(actual)
        expected_start = original_start(expected)
        same_result(first(actual_start), first(expected_start))
        @test last(actual_start) == last(expected_start)
        @test actual.current == expected.current
        @test isequal(actual.pattern, expected.pattern)
        state = last(actual_start)
        while true
            actual_next = iterate(actual, state)
            expected_next = iterate(expected, state)
            @test (actual_next === nothing) == (expected_next === nothing)
            actual_next === nothing && break
            same_result(first(actual_next), first(expected_next))
            @test last(actual_next) == last(expected_next)
            @test actual.current == expected.current
            @test isequal(actual.pattern, expected.pattern)
            state = last(actual_next)
        end
    end
end
