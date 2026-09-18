@testset "product widening" begin
    @emulate Int1 UInt1 Int3 UInt3 Int9 UInt9 Int3_128 UInt3_128 Int3_256 UInt3_256 Int20_24 UInt20_24 Int63 UInt63 Int65 UInt65

    @test EmulatedBitIntegers.prod_hooks_compatible()

    for Element in (Int1, UInt1, Int3, UInt3, Int9, UInt9, Int3_128, UInt3_128,
                    Int3_256, UInt3_256, Int20_24, UInt20_24, Int63, UInt63, Int65, UInt65)
        Accumulator = bits(Element) < bits(Int) ? Element <: Signed ? Int : UInt : Element
        factor = Element <: Signed ? Element(-1) : one(Element)
        for count in (0, 1, 2, 17, 2048)
            values = fill(factor, count)
            expected = isodd(count) ? Accumulator(factor) : one(Accumulator)
            @test prod(values) === expected
            @test prod(identity, values) === expected
            @test prod(value for value in values) === expected
            @test prod(Iterators.filter(_ -> true, values)) === expected
            @test prod(values; init=one(Accumulator)) === expected
            matrix = reshape(values, count, 1)
            @test prod(matrix; dims=1) == fill(expected, 1, 1)
            @test eltype(prod(matrix; dims=1)) === Accumulator
            cumulative = cumprod(Accumulator.(values))
            @test cumprod(values) == cumulative
            @test eltype(cumprod(values)) === Accumulator
            @test cumprod(matrix; dims=1) == reshape(cumulative, count, 1)
            @test eltype(cumprod(matrix; dims=1)) === Accumulator
            @test cumprod!(Vector{Accumulator}(undef, count), values) == cumulative
            if count > 0
                @test prod(Integer[values...]) === expected
                @test prod(Any[values...]) === expected
            end
        end
    end

    @test (@inferred prod(Int3[3, 3])) === 9
    @test (@inferred prod(UInt3[7, 7])) === UInt(49)
    @test (@inferred prod(Int1[])) === 1
    @test prod(Int1[-1, -1]) === 1
    @test (@inferred cumprod(Int1[-1, -1])) == [-1, 1]
    @test (@inferred cumprod(Int3[3, 3, 3])) == [3, 9, 27]
    @test (@inferred cumprod(UInt3[7, 7, 7])) == UInt[7, 49, 343]
    @test cumprod((Int3(3), Int3(3))) === (3, 9)
    @test cumprod(value for value in Int3[3, 3]) == [3, 9]
    @test prod(Int3(1):Int3(3)) === 6
    @test prod(value -> Int3(value), 1:3) === 6

    for (Element, Accumulator, factor) in ((Int3, Int, 3), (UInt3, UInt, 7))
        values = fill(Element(factor), 2, 3)
        @test prod(values; dims=2) == fill(Accumulator(factor)^3, 2, 1)
        @test eltype(prod(values; dims=2)) === Accumulator
        @test cumprod(values; dims=2) == cumprod(Accumulator.(values); dims=2)
        @test eltype(cumprod(values; dims=2)) === Accumulator
        @test prod(fill(Element(factor), 100)) === big(factor)^100 % Accumulator
    end

    @test prod(Union{Int3,Int9}[Int3(3), Int9(4)]) === 12
    @test prod(Union{UInt3,UInt9}[UInt3(7), UInt9(8)]) === UInt(56)
    @test prod(Union{Int3,Int9}[]) === 1
    @test prod(Union{UInt3,UInt9}[]) === UInt(1)
    @test prod(Union{Int,Int3}[]) === 1
    @test_throws MethodError prod(Union{Int3,UInt3}[])
    @test_throws MethodError prod(EmulatedBitIntegers.EmulatedInteger[])
    @test prod(Int3[2, 3]; init=0.5) === 3.0
    @test prod(Int3[2, 3]; init=Int3(1)) === 6
    @test prod(Int3[]; init=Int3(1)) === Int3(1)
    @test prod(Int3[2, 3]; init=big(1)) == big(6)
    @test prod(Int3[2, 3]; init=1//2) === 3//1
    @test prod(Int3[2, 3]; init=1im) === 6im
    @test_throws MethodError prod(Any[])
    @test prod(Any[]; init=1) === 1
end