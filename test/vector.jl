@testset "VectorFold" begin
    vf_dict = Dict([
        make_vector_fold([1,2], 10, 5, :immutable) => Dict(
            :pattern => [1,2],
            :gap => 10,
            :folds => 5,
            :length => 10,
            :unfold => [1,2,11,12,21,22,31,32,41,42],
            :reverse => reverse([1,2,11,12,21,22,31,32,41,42]),
        ),
        make_vector_fold([1,2], 10, 5, :mutable) => Dict(
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
    @test isempty(make_vector_fold(Vector(),1,1,:immutable))
    @test isempty(make_vector_fold(Vector(),1,1))

    v1 = make_vector_fold([42,3,45,6],13,4)
    w1 = unfold(v1)
    v11 = fold(w1)

    @test unfold(v11) == w1

    v2 = make_vector_fold([34,34,43,43],10,3)
    w2 = unfold(v2)
    v22 = fold(w2)

    @test unfold(v22) == w2
end
