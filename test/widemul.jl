@testset "widened products" begin
    @emulate Int1 UInt1 Int3 UInt3 Int7 UInt7 Int63 UInt63 Int65 UInt65 Int127 UInt127 Int129 UInt129 Int257 UInt257 Int3_128 UInt3_128 Int3_256 UInt3_256 Int20_24 UInt20_24
    targets = (Int1, UInt1, Int3, UInt3, Int7, UInt7, Int63, UInt63,
               Int65, UInt65, Int127, UInt127, Int129, UInt129, Int257, UInt257,
               Int3_128, UInt3_128, Int3_256, UInt3_256, Int20_24, UInt20_24,
               Int8, UInt8, Int128, UInt128, Int256, UInt256)
    for Left in targets, Right in targets
        Left <: EmulatedBitIntegers.EmulatedInteger || Right <: EmulatedBitIntegers.EmulatedInteger || continue
        for left in (typemin(Left), zero(Left), typemax(Left)),
            right in (typemin(Right), zero(Right), typemax(Right))
            @test BigInt(@inferred widemul(left, right)) == BigInt(left) * BigInt(right)
        end
    end
    for Left in (Int1, UInt1, Int3, UInt3), Right in (Int1, UInt1, Int3, UInt3)
        for left in Int(typemin(Left)):Int(typemax(Left)), right in Int(typemin(Right)):Int(typemax(Right))
            @test widemul(Left(left), Right(right)) == left * right
        end
    end
    for Target in targets
        Target <: EmulatedBitIntegers.EmulatedInteger || continue
        @test which(widemul, (Target, Bool)) === which(widemul, (Int8, Bool))
        @test which(widemul, (Bool, Target)) === which(widemul, (Bool, Int8))
        for value in (typemin(Target), zero(Target), typemax(Target))
            for other in (big(-1), big(1) << 600)
                expected = BigInt(value) * other
                @test (@inferred widemul(value, other)) == expected
                @test (@inferred widemul(other, value)) == expected
            end
        end
    end
    for (Left, Right, Product) in ((Int7, Int7, Int16), (UInt7, UInt7, UInt16),
                                  (Int7, UInt7, Int16), (Int63, UInt1, Int64),
                                  (Int20_24, UInt20_24, Int64), (Int3_128, Int3, Int128),
                                  (Int3_256, UInt3, Int256), (UInt3_256, UInt3, UInt256))
        @test (@inferred widemul(zero(Left), zero(Right))) isa Product
    end
    @test widen(Int65) === Int128
    @test widen(UInt7) === UInt8
    @test powermod(Int7(50), 2, Int7(63)) == 43
    @test powermod(UInt7(100), 2, UInt7(127)) == 94
end