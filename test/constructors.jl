@testset "checked constructor storage" begin
    @emulate Int1 UInt1 Int3 UInt3 Int7 UInt7 Int63 UInt63 Int3_256 UInt3_256 Int128_256 UInt128_256 Int129 UInt129
    targets = (Int1, UInt1, Int7, UInt7, Int63, UInt63, Int3_256, UInt3_256, Int128_256, UInt128_256, Int129, UInt129)
    for Target in targets
        low, high = BigInt(typemin(Target)), BigInt(typemax(Target))
        for Source in (Int8, UInt8, Int, UInt, Int128, UInt128, BitIntegers.Int256, BitIntegers.UInt256, Int3, UInt3, BigInt)
            for value in unique([low - 1, low, big(-1), big(0), big(1), high, high + 1])
                Source === BigInt || BigInt(typemin(Source)) <= value <= BigInt(typemax(Source)) || continue
                source = Source(value)
                if low <= value <= high
                    result = @inferred Target(source)
                    @test typeof(result) === Target
                    @test BigInt(result[]) == value
                else
                    @test_throws InexactError Target(source)
                end
            end
        end
        for Float in (Float16, Float32, Float64)
            bound = Float(ldexp(1.0, bits(Target) - (Target <: Signed)))
            inputs = (Float(-Inf), Float(Inf), Float(NaN), Float(-0.0), Float(0), Float(1),
                      Float(-1), Float(1.5), Float(-1.5), bound, prevfloat(bound), nextfloat(bound),
                      -bound, prevfloat(-bound), nextfloat(-bound))
            for source in inputs
                valid = isfinite(source) && isinteger(source) && low <= BigInt(source) <= high
                if valid
                    result = @inferred Target(source)
                    @test typeof(result) === Target
                    @test BigInt(result[]) == BigInt(source)
                else
                    @test_throws InexactError Target(source)
                end
            end
        end
        for source in (0//1, 1//2, BigFloat(0), BigFloat(0.5))
            if iszero(source)
                @test BigInt(Target(source)[]) == 0
            else
                @test_throws InexactError Target(source)
            end
        end
    end
end