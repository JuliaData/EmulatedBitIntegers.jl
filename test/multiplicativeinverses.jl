@testset "storage-backed multiplicative inverses" begin
    @emulate Int1 UInt1 Int3 UInt3 Int7 UInt7 Int63 UInt63 Int65 UInt65 Int129 UInt129 Int257 UInt257 Int3_256 UInt3_256 Int20_24 UInt20_24
    for Target in (BOUNDARY_TEST_TYPES..., Int7, UInt7, Int257, UInt257)
        low, high = BigInt(typemin(Target)), BigInt(typemax(Target))
        values = Target.(unique(filter(value -> low <= value <= high,
                                       [low, low + 1, -3, -1, 0, 1, 2, 3, high - 1, high])))
        @test_throws ArgumentError Base.MultiplicativeInverses.multiplicativeinverse(zero(Target))
        for divisor in values
            iszero(divisor) && continue
            inverse = @inferred Base.MultiplicativeInverses.multiplicativeinverse(divisor)
            @test inverse isa Base.MultiplicativeInverses.MultiplicativeInverse{Target}
            @test inverse.divisor === divisor
            for value in values
                expected_div = div(BigInt(value), BigInt(divisor)) % Target
                expected_rem = rem(BigInt(value), BigInt(divisor)) % Target
                expected_mod = mod(BigInt(value), BigInt(divisor)) % Target
                @test (@inferred div(value, inverse)) === expected_div
                @test (@inferred rem(value, inverse)) === expected_rem
                @test (@inferred mod(value, inverse)) === expected_mod
                quotient, remainder = @inferred divrem(value, inverse)
                @test quotient === expected_div
                @test remainder === expected_rem
            end
        end
    end
    for Target in SMALL_TEST_TYPES
        for divisor in Int(typemin(Target)):Int(typemax(Target))
            iszero(divisor) && continue
            inverse = Base.MultiplicativeInverses.multiplicativeinverse(Target(divisor))
            for value in Int(typemin(Target)):Int(typemax(Target))
                @test div(Target(value), inverse) === div(value, divisor) % Target
                @test mod(Target(value), inverse) === mod(value, divisor) % Target
            end
        end
    end
end

@testset "inverse-accelerated modular powers" begin
    @emulate UInt15 UInt31 UInt127
    @test powermod(UInt7(2), 10, UInt7(3)) === UInt7(1)
    for Target in (UInt7, UInt15, UInt31, UInt63, UInt65, UInt127, UInt129, UInt257, UInt3_256, UInt20_24)
        for modulus in (Target(1), Target(3), typemax(Target)),
            base in (zero(Target), Target(2), typemax(Target)),
            power in (0, 1, 2, 10, 2sizeof(Target), 2sizeof(Target) + 1, 257, typemax(Int32))
            @test powermod(base, power, modulus) == powermod(BigInt(base), power, BigInt(modulus))
        end
    end
    for power in (-1, -10, typemin(Int8), big(1) << 80)
        @test powermod(UInt7(2), power, UInt7(3)) == powermod(big(2), power, big(3))
    end
    if isdefined(Base, :_powermod_mi_legal)
        for Target in (UInt7, UInt15, UInt31, UInt63)
            @test !(@inferred Base._powermod_mi_legal(Target(3)))
        end
        for Target in (UInt65, UInt127, UInt129, UInt257, UInt3_256, UInt20_24)
            for modulus in (Target(3), typemax(Target))
                @test (@inferred Base._powermod_mi_legal(modulus)) ==
                      invoke(Base._powermod_mi_legal, Tuple{Unsigned}, modulus)
            end
        end
        @test Base._powermod_mi_legal(UInt127(3))
        @test Base._powermod_mi_legal(UInt20_24(3))
        @test Base._powermod_mi_legal(UInt8(3))
    end
end