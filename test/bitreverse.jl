using Random

@testset "logical bit reversal" begin
    @emulate Int1 UInt1 Int3 UInt3 Int7 UInt7 Int9 UInt9 Int63 UInt63 Int65 UInt65 Int127 UInt127 Int129 UInt129 Int257 UInt257 Int3_128 UInt3_128 Int3_256 UInt3_256 Int20_24 UInt20_24
    rng = Xoshiro(1234)

    for Element in (Int1, UInt1, Int3, UInt3, Int7, UInt7, Int9, UInt9,
                    Int63, UInt63, Int65, UInt65, Int127, UInt127, Int129, UInt129,
                    Int257, UInt257, Int3_128, UInt3_128, Int3_256, UInt3_256,
                    Int20_24, UInt20_24)
        values = if bits(Element) <= 9
            Element.(Int(typemin(Element)):Int(typemax(Element)))
        else
            [typemin(Element), zero(Element), typemax(Element), rand(rng, Element, 32)...]
        end
        for value in values
            reversed = @inferred bitreverse(value)
            @test reversed isa Element
            @test bitstring(reversed) == reverse(bitstring(value))
            @test bitreverse(reversed) === value
            @test count_ones(reversed) == count_ones(value)
        end
        for position in 0:bits(Element)-1
            value = (big(1) << position) % Element
            expected = (big(1) << (bits(Element) - position - 1)) % Element
            @test (@inferred bitreverse(value)) === expected
        end
    end

    @test bitreverse(UInt7(1)) === UInt7(64)
    @test bitreverse(Int7(1)) === Int7(-64)
    @test bitreverse(Int7(-64)) === Int7(1)
    @test bitreverse(Int7(-1)) === Int7(-1)
end