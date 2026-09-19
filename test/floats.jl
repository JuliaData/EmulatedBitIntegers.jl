using Random

@testset "logical-width float conversion" begin
    @emulate Int1 Int3 UInt3 Int3_128 UInt3_128 Int3_256 UInt3_256 Int20_24 UInt20_24 Int53_256 UInt53_256 Int63_256 UInt63_256 Int65_256 UInt65_256 Int127_256 UInt127_256 Int129 UInt129
    rng = Xoshiro(1234)
    for Element in (Int1, Int3, UInt3, Int3_128, UInt3_128, Int3_256, UInt3_256,
                    Int20_24, UInt20_24, Int53_256, UInt53_256, Int63_256, UInt63_256,
                    Int65_256, UInt65_256, Int127_256, UInt127_256, Int129, UInt129)
        values = if bits(Element) <= 3
            Element.(Int(typemin(Element)):Int(typemax(Element)))
        else
            [typemin(Element), zero(Element), typemax(Element), rand(rng, Element, 8)...]
        end
        for power in (11, 24, 53, 64, 100), offset in (-1, 0, 1), sign in (-1, 1)
            exact = sign * ((big(1) << power) + offset)
            typemin(Element) <= exact <= typemax(Element) && push!(values, Element(exact))
        end
        unique!(values)
        for Float in (Float16, Float32, Float64)
            @test (@inferred Float(zero(Element))) === zero(Float)
        end
        @test (@inferred AbstractFloat(zero(Element))) === 0.0
        @test (@inferred float(zero(Element))) === 0.0
        @test isequal(@inferred(zero(Element) / zero(Element)), NaN)
        for value in values
            for Float in (Float16, Float32, Float64)
                expected = bits(Element) <= 128 ? Float(value[] % (Element <: Signed ? Int128 : UInt128)) : Float(value[])
                @test isequal(Float(value), expected)
                if Float !== Float16
                    @test isequal(Float(value), Float(value[]))
                end
            end
            @test AbstractFloat(value) === Float64(value)
            @test float(value) === Float64(value)
        end
        for value in (typemin(Element), zero(Element), typemax(Element)),
            denominator in (typemin(Element), zero(Element), typemax(Element))
            @test isequal(value / denominator, value[] / denominator[])
        end
    end
end