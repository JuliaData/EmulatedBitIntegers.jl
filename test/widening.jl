module WideningOverride
    using EmulatedBitIntegers
    @emulate Int7 UInt7
    Base.widen(::Type{Int7}) = Int32
    Base.widen(::Type{UInt7}) = UInt32
end

@testset "storage-backed widening" begin
    @emulate Int1 UInt1 Int3 UInt3 Int4 UInt4 Int5 UInt5 Int7 UInt7 Int15 UInt15 Int31 UInt31 Int63 UInt63 Int65 UInt65 Int127 UInt127 Int129 UInt129 Int257 UInt257 Int3_128 UInt3_128 Int3_256 UInt3_256 Int20_24 UInt20_24
    targets = (Int1, UInt1, Int3, UInt3, Int4, UInt4, Int5, UInt5, Int7, UInt7,
               Int15, UInt15, Int31, UInt31, Int63, UInt63, Int65, UInt65,
               Int127, UInt127, Int129, UInt129, Int257, UInt257,
               Int3_128, UInt3_128, Int3_256, UInt3_256, Int20_24, UInt20_24)
    for Target in targets
        Wide = @inferred widen(Target)
        @test Wide === EmulatedBitIntegers.storagetypeof(Target)
        low, high = BigInt(typemin(Target)), BigInt(typemax(Target))
        inputs = Target.(unique(filter(value -> low <= value <= high,
                                      [low, low + 1, -1, 0, 1, high - 1, high])))
        for value in inputs
            @test (@inferred widen(value)) isa Wide
            @test BigInt(widen(value)) == BigInt(value)
        end
    end
    for (Target, Wide) in ((WideningOverride.Int7, Int32), (WideningOverride.UInt7, UInt32))
        @test (@inferred widen(Target)) === Wide
        for value in (typemin(Target), zero(Target), typemax(Target))
            @test (@inferred widen(value)) === Wide(value[])
        end
    end
end