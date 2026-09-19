@testset "signed one-bit unit ranges" begin
    @emulate Int1 Int1_16 Int1_24 Int1_128 Int1_256

    for Element in (Int1, Int1_16, Int1_24, Int1_128, Int1_256)
        @test_throws InexactError one(Element)
        @test_throws InexactError oneunit(Element)
        for start in (-1, 0), stop in (-1, 0)
            range = @inferred Element(start):Element(stop)
            expected = collect(start:stop)
            @test range isa UnitRange{Element}
            @test first(range) === Element(start)
            @test last(range) === Element(stop)
            @test (@inferred step(range)) === 1
            @test (@inferred length(range)) === length(expected)
            @test isempty(range) == isempty(expected)
            @test (@inferred collect(range)) == expected
            @test eltype(collect(range)) === Element
            actual = Element[]
            state = iterate(range)
            while !isnothing(state)
                value, position = state
                push!(actual, value)
                state = iterate(range, position)
            end
            @test actual == expected
            @test Tuple(range) == Tuple(expected)
            @test [value for value in range] == expected
            for index in eachindex(expected)
                @test (@inferred range[index]) === Element(expected[index])
            end
            @test sum(range) === sum(expected)
            @test prod(range) === prod(expected)
            @test_throws InexactError oneunit(first(range))
        end
    end
end