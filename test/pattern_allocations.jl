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
