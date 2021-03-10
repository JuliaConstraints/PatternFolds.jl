@testset "VectorFold" begin
    vf_dict = Dict([
        VectorFold([1,2], 10, 5) => Dict(
            :pattern => [1,2],
            :gap => 10,
            :folds => 5,
            :length => 10,
            :unfold => [1,2,11,12,21,22,31,32,41,42],
            :reverse => reverse([1,2,11,12,21,22,31,32,41,42]),
        ),
        MVectorFold([1,2], 10, 5) => Dict(
            :pattern => [1,2],
            :gap => 10,
            :folds => 5,
            :length => 10,
            :unfold => [1,2,11,12,21,22,31,32,41,42],
            :reverse => reverse([1,2,11,12,21,22,31,32,41,42]),
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
        @test collect(vf) == [i for i in vf] == unfold(vf)
        @test collect(Iterators.reverse(vf)) == reverse(collect(vf)) == results[:reverse]
    end
    @test isempty(VectorFold(Vector(),1,1))
    @test isempty(MVectorFold(Vector(),1,1))
end
