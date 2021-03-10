@testset "IntervalsFold" begin
    isf_dict = Dict([
        IntervalsFold(Interval((0.0, true), (1.0, false)), 2.0, 5) => Dict(
            :pattern => Interval((0.0, true), (1.0, false)),
            :gap => 2.0,
            :folds => 5,
            :length => 5.0,
            :unfold => [
                Interval{Float64}((0.0, true), (1.0, false)),
                Interval{Float64}((2.0, true), (3.0, false)),
                Interval{Float64}((4.0, true), (5.0, false)),
                Interval{Float64}((6.0, true), (7.0, false)),
                Interval{Float64}((8.0, true), (9.0, false)),
            ],
            :reverse => reverse([
                Interval{Float64}((0.0, true), (1.0, false)),
                Interval{Float64}((2.0, true), (3.0, false)),
                Interval{Float64}((4.0, true), (5.0, false)),
                Interval{Float64}((6.0, true), (7.0, false)),
                Interval{Float64}((8.0, true), (9.0, false)),
            ]),
        ),
    ])

    for (isf, results) in isf_dict
        @test pattern(isf) == results[:pattern]
        @test gap(isf) == results[:gap]
        @test folds(isf) == results[:folds]
        @test length(isf) == results[:length]
        @test unfold(isf) == results[:unfold]
        @test ndims(isf) == 1
        @test rand(isf) ∈ isf
        @test collect(isf) == [i for i in isf] == unfold(isf)
        @test collect(Iterators.reverse(isf)) == reverse(collect(isf)) == results[:reverse]
    end
end
