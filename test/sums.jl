@testset "sum widening" begin
    @emulate Int3 UInt3 Int9 UInt9 Int3_128 UInt3_128 Int63 UInt63 Int65 UInt65

    @test EmulatedBitIntegers.sum_hooks_compatible()

    for Element in (Int3, UInt3, Int9, UInt9, Int3_128, UInt3_128, Int63, UInt63, Int65, UInt65)
        Accumulator = bits(Element) < bits(Int) ? Element <: Signed ? Int : UInt : Element
        for count in (0, 1, 2, 17, 2048)
            values = fill(Element(1), count)
            expected = count % Accumulator
            @test sum(values) === expected
            @test sum(identity, values) === expected
            @test sum(value for value in values) === expected
            @test sum(Iterators.filter(_ -> true, values)) === expected
            @test sum(values; init=zero(Accumulator)) === expected
            @test sum(reshape(values, count, 1); dims=1) == fill(expected, 1, 1)
            @test eltype(sum(reshape(values, count, 1); dims=1)) === Accumulator
            if count > 0
                @test sum(Integer[values...]) === expected
                @test sum(Any[values...]) === expected
            end
        end
    end

    @test sum(Int3[3, 3]) === 6
    @test sum(UInt3[7, 7]) === UInt(14)
    @test (@inferred sum(Int3[3, 3])) === 6
    @test (@inferred sum(UInt3[7, 7])) === UInt(14)
    @test sum(fill(Int3(3), 2, 3); dims=2) == fill(9, 2, 1)
    @test eltype(sum(fill(Int3(3), 2, 3); dims=2)) === Int
    @test sum(fill(UInt3(7), 2, 3); dims=2) == fill(UInt(21), 2, 1)
    @test eltype(sum(fill(UInt3(7), 2, 3); dims=2)) === UInt
    @test sum(Union{Int3,Int9}[Int3(3) Int9(4)]; dims=2) == fill(7, 1, 1)
    @test eltype(sum(Union{Int3,Int9}[Int3(3) Int9(4)]; dims=2)) === Int
    @test sum(Integer[Int3(3) Int9(4)]; dims=2) == fill(7, 1, 1)
    @test sum(Any[Int3(3) Int9(4)]; dims=2) == fill(7, 1, 1)
    @test sum(Union{Int3,Int9}[Int3(3), Int9(4)]) === 7
    @test sum(Union{Int,Int3}[Int3(3), 4]) === 7
    @test sum(Union{UInt3,UInt9}[UInt3(7), UInt9(8)]) === UInt(15)
    @test sum(Union{Int3,Int9}[]) === 0
    @test sum(Union{UInt3,UInt9}[]) === UInt(0)
    @test sum(Union{Int,Int3}[]) === 0
    @test_throws MethodError sum(Union{Int3,UInt3}[])
    @test_throws MethodError sum(EmulatedBitIntegers.EmulatedInteger[])
    @test sum(Int3[1, 2]; init=0.5) === 3.5
    @test sum(Int3[1, 2]; init=Int3(0)) === 3
    @test sum(Int3[]; init=Int3(0)) === Int3(0)
    @test sum(Int3[1, 2]; init=big(0)) == big(3)
    @test sum(Int3[1, 2]; init=0//1) === 3//1
    @test sum(Int3[1, 2]; init=0 + 1im) === 3 + 1im
    @test_throws MethodError sum(Any[])
    @test sum(Any[]; init=0) === 0
    @test sum(Integer[]) === sum(Integer[]; init=0)
    @test sum(value -> Int3(value), 1:3) === 6
    @test sum(Int3(1):Int3(3)) === 6
    @test sum(UInt3(1):UInt3(3)) === sum(UInt8(1):UInt8(3))
end