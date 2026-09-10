@define_integers 24 ConversionInt24 ConversionUInt24

@testset "BitIntegers conversion" begin
    @emulate Int3 UInt3 Int3_128 UInt3_128 Int129 UInt129

    for Source in (Int3, UInt3, Int3_128, UInt3_128, Int129, UInt129)
        for Target in (Int256, UInt256, Int512, UInt512, Int1024, UInt1024, ConversionInt24, ConversionUInt24)
            for value in (typemin(Source), zero(Source), one(Source), typemax(Source))
                if typemin(Target) <= BigInt(value[]) <= typemax(Target)
                    expected = Target(value[])
                    @test (@inferred Target(value)) === expected
                    @test (@inferred convert(Target, value)) === expected
                else
                    @test_throws InexactError Target(value)
                    @test_throws InexactError convert(Target, value)
                end
            end
        end
    end

    @test Int256(Int3(1)) === Int256(1)
    extension = Base.get_extension(EmulatedBitIntegers, :BitIntegersExt)
    @test isempty(Test.detect_ambiguities(EmulatedBitIntegers, BitIntegers, extension))
end