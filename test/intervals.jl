@testset "IntervalsFold" begin
    i01 = Interval{Open,Closed}(0.0, 1.0)
    i23 = Interval{Open,Closed}(2.0, 3.0)
    i45 = Interval{Open,Closed}(4.0, 5.0)
    i67 = Interval{Open,Closed}(6.0, 7.0)
    i89 = Interval{Open,Closed}(8.0, 9.0)
    isf_dict = Dict([
        IntervalsFold(i01, 2.0, 5) => Dict(
            :pattern => i01,
            :gap => 2.0,
            :folds => 5,
            :length => 5,
            :size => 5.0,
            :unfold => [i01, i23, i45, i67, i89],
            :reverse => reverse([i01, i23, i45, i67, i89]),
        ),
    ])

    for (isf, results) in isf_dict
        @test pattern(isf) == results[:pattern]
        @test gap(isf) == results[:gap]
        @test folds(isf) == results[:folds]
        @test length(isf) == results[:length]
        @test size(isf) == results[:size]
        @test unfold(isf) == results[:unfold]
        @test ndims(isf) == 1
        for i in 1:1000
            @test rand(isf) ∈ isf
        end
        @test collect(isf) == [i for i in isf] == unfold(isf)
        @test collect(Iterators.reverse(isf)) == reverse(collect(isf)) == results[:reverse]
    end
    @test isempty(IntervalsFold(Interval{Open, Closed}(1.0, 1.0), 1.0, 1))
end
