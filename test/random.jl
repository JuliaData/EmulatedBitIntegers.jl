using Random

@testset "random unit ranges" begin
    @emulate Int1 UInt1 Int3 UInt3 Int7 UInt7 Int63 UInt63 Int65 UInt65 Int127 UInt127 Int129 UInt129 Int257 UInt257 Int3_128 UInt3_128 Int3_256 UInt3_256 Int20_24 UInt20_24

    for Element in (BOUNDARY_TEST_TYPES..., Int3_128, UInt3_128, Int257, UInt257)
        minimum, maximum = typemin(Element), typemax(Element)
        ranges = (minimum:maximum, minimum:minimum, maximum:maximum)
        if Element <: Signed
            ranges = (ranges..., minimum:zero(Element), zero(Element):maximum)
        end
        for range in ranges
            backing = first(range)[]:last(range)[]
            rng_types = Element in (Int3, UInt3, Int129, UInt129) ? (Xoshiro, MersenneTwister) : (Xoshiro,)
            for RNG in rng_types, repetition in (Val(1), Val(Inf))
                rng, reference = RNG(1234), RNG(1234)
                sampler = @inferred Random.Sampler(RNG, range, repetition)
                backing_sampler = Random.Sampler(RNG, backing, repetition)
                @test sampler isa Random.Sampler{Element}
                for draw in 1:4
                    value = @inferred rand(rng, sampler)
                    @test value === rand(reference, backing_sampler) % Element
                    @test first(range) <= value <= last(range)
                end
            end
            @test (@inferred rand(Xoshiro(1234), range)) isa Element
        end
        if Element in (SMALL_TEST_TYPES..., Int3_256, UInt3_256, Int129, UInt129)
            range = minimum:maximum
            backing = first(range)[]:last(range)[]
            values = @inferred rand(Xoshiro(1234), range, 2, 4)
            @test eltype(values) === Element
            @test values == rand(Xoshiro(1234), backing, 2, 4) .% Element
            @test all(value -> first(range) <= value <= last(range), values)
            destination = similar(values)
            @test rand!(Xoshiro(1234), destination, range) === destination
            @test destination == values
        end
        empty_range = maximum:minimum
        @test_throws ArgumentError rand(Xoshiro(1), empty_range)
        @test_throws ArgumentError Random.Sampler(Xoshiro, empty_range, Val(Inf))
    end

    for Element in REDUCTION_TEST_TYPES
        singleton = typemax(Element):typemax(Element)
        @test rand(Xoshiro(1), singleton, 2, 2) == fill(typemax(Element), 2, 2)
        @test isempty(rand(Xoshiro(1), singleton, 0))
        @test_throws ArgumentError rand(Xoshiro(1), typemax(Element):typemin(Element), 2)
    end

    for Element in REDUCTION_TEST_TYPES
        range = Base.OneTo(Element(3))
        @test rand(Xoshiro(1234), range, 32) == rand(Xoshiro(1234), first(range)[]:last(range)[], 32) .% Element
        @test rand(range) isa Element
    end
end