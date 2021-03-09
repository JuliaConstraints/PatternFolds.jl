@testset "VectorFold" begin
    vf_dict = Dict([
        VectorFold([1,2], 10, 5) => Dict(
            :pattern => [1,2],
            :gap => 10,
            :folds => 5,
            :length => 10,
            :unfold => [1,2,11,12,21,22,31,32,41,42],
        ),
        MVectorFold([1,2], 10, 5) => Dict(
            :pattern => [1,2],
            :gap => 10,
            :folds => 5,
            :length => 10,
            :unfold => [1,2,11,12,21,22,31,32,41,42],
        ),
    ])

    for (vf, results) in vf_dict
        @test pattern(vf) == results[:pattern]
        @test gap(vf) == results[:gap]
        @test folds(vf) == results[:folds]
        @test length(vf) == results[:length]
        @test unfold(vf) == results[:unfold]
        @test ndims(vf) == 1
        @test rand(vf) ∈ vf
    end

    @test collect(VectorFold([1, 2], 10, 5)) == [i for i in VectorFold([1, 2], 10, 5)] == unfold(VectorFold([1, 2], 10, 5))
    @test collect(Iterators.reverse(VectorFold([1, 2], 10, 5))) == reverse(collect(VectorFold([1, 2], 10, 5)))
    @test 41 ∈ VectorFold([1, 2], 10, 5)
    @test isempty(VectorFold(Vector(),1,1))
end
