using Random

@testset "IEEE float truncation" begin
    @emulate Int1 UInt1 Int7 UInt7 Int15 UInt15 Int31 UInt31 Int63 UInt63 Int65 UInt65 Int127 UInt127 Int128_256 UInt128_256 Int129 UInt129 Int257 UInt257 Int1025 UInt1025 Int20_24 UInt20_24 Int3_128 UInt3_128 Int3_256 UInt3_256 Int6_128
    targets = (Int1, UInt1, Int7, UInt7, Int15, UInt15, Int31, UInt31, Int63, UInt63,
               Int65, UInt65, Int127, UInt127, Int129, UInt129,
               Int257, UInt257, Int1025, UInt1025, Int20_24, UInt20_24,
               Int3_128, UInt3_128, Int3_256, UInt3_256, Int6_128)
    rng = MersenneTwister(851)
    for Target in targets, Float in (Float16, Float32, Float64)
        low, high = BigInt(typemin(Target)), BigInt(typemax(Target))
        inputs = Float[0, -0.0, 0.75, -0.75, 1.75, -1.75,
                       nextfloat(zero(Float)), -nextfloat(zero(Float)),
                       floatmin(Float), -floatmin(Float), floatmax(Float), -floatmax(Float),
                       Inf, -Inf, NaN]
        for boundary in (Float(low), Float(high))
            append!(inputs, (prevfloat(boundary), boundary, nextfloat(boundary)))
        end
        append!(inputs, (Float(low) - oneunit(Float), Float(low) - Float(0.75),
                         prevfloat(-oneunit(Float)), -oneunit(Float), nextfloat(-oneunit(Float))))
        for sample in 1:128
            value = ldexp(Float(1) + rand(rng, Float), rand(rng, -2:min(bits(Target), exponent(floatmax(Float)))))
            push!(inputs, value, -value)
        end
        for source in unique(inputs)
            if !isfinite(source)
                @test_throws InexactError trunc(Target, source)
                @test_throws InexactError Target(source)
                continue
            end
            exact = trunc(BigInt, source)
            if !(low <= exact <= high)
                @test_throws InexactError trunc(Target, source)
                @test_throws InexactError Target(source)
                continue
            end
            result = @inferred unsafe_trunc(Target, source)
            @test result isa Target
            @test BigInt(result[]) == exact
            @test (@inferred trunc(Target, source)) === result
            if isinteger(source)
                @test (@inferred Target(source)) === result
            else
                @test_throws InexactError Target(source)
            end
        end
    end
    for Target in targets
        for source in (BigFloat(-0.75), BigFloat(0.75), big(0), BigInt(typemin(Target)), BigInt(typemax(Target)))
            @test (@inferred unsafe_trunc(Target, source)) === Target(trunc(BigInt, source))
        end
    end
end

@testset "truncation precision boundaries" begin
    @emulate Int10 Int11 Int12 Int23 Int24_64 Int25 Int52 Int53 Int54
    for (Float, targets) in ((Float16, (Int10, Int11, Int12)),
                             (Float32, (Int23, Int24_64, Int25)),
                             (Float64, (Int52, Int53, Int54)))
        for Target in targets
            lower = Float(typemin(Target))
            for boundary in (lower, lower - oneunit(Float))
                for source in (prevfloat(boundary), boundary, nextfloat(boundary))
                    exact = trunc(BigInt, source)
                    if BigInt(typemin(Target)) <= exact <= BigInt(typemax(Target))
                        @test BigInt((@inferred trunc(Target, source))[]) == exact
                    else
                        @test_throws InexactError trunc(Target, source)
                    end
                end
            end
        end
    end
end

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