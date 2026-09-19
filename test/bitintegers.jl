@define_integers 24 ConversionInt24 ConversionUInt24
@define_integers 128 MultiplicationInt128 MultiplicationUInt128

@testset "BitIntegers checked multiplication" begin
    @emulate UInt127 UInt128 UInt129 UInt255 UInt257 UInt513 UInt3_256
    for Source in (MultiplicationUInt128, UInt256, UInt512, UInt1024,
                   UInt127, UInt128, UInt129, UInt255, UInt257, UInt513, UInt3_256)
        high = BigInt(typemax(Source))
        root = isqrt(high)
        values = unique([big(0), big(1), big(2), root, root + 1, high - 1, high])
        @test (@inferred Base.Checked.mul_with_overflow(zero(Source), zero(Source))) === (zero(Source), false)
        @test (@inferred Base.Checked.checked_mul(zero(Source), zero(Source))) === zero(Source)
        for (index, left) in enumerate(values), right in values[index:end]
            x, y = Source(left), Source(right)
            product = left * right
            overflow = product > high
            @test Base.Checked.mul_with_overflow(x, y) === (product % Source, overflow)
            if overflow
                @test_throws OverflowError Base.Checked.checked_mul(x, y)
            else
                @test Base.Checked.checked_mul(x, y) === Source(product)
            end
            multiple = lcm(left, right)
            if multiple > high
                @test_throws OverflowError lcm(x, y)
            else
                @test lcm(x, y) === Source(multiple)
            end
        end
    end
end

@testset "BitIntegers conversion" begin
    @emulate Int3 UInt3 Int3_128 UInt3_128 Int129 UInt129

    for Source in (Int3, UInt3, Int3_128, UInt3_128, Int129, UInt129)
        for value in (typemin(Source), zero(Source), one(Source), typemax(Source))
            @test BigInt(value) == BigInt(value[])
        end
        targets = Source in SMALL_TEST_TYPES ? (Base.BitInteger_types..., Int256, UInt256, Int512, UInt512, Int1024, UInt1024, ConversionInt24, ConversionUInt24) :
                  (Int8, UInt8, Int128, UInt128, Int256, UInt256, ConversionInt24, ConversionUInt24)
        for Target in targets
            @test (@inferred zero(Source) % Target) === zero(Target)
            @test (@inferred Target(zero(Source))) === zero(Target)
            @test (@inferred convert(Target, zero(Source))) === zero(Target)
            for value in (typemin(Source), zero(Source), one(Source), typemax(Source))
                @test value % Target === BigInt(value[]) % Target
                if typemin(Target) <= BigInt(value[]) <= typemax(Target)
                    expected = Target(value[])
                    @test Target(value) === expected
                    @test convert(Target, value) === expected
                else
                    @test_throws InexactError Target(value)
                    @test_throws InexactError convert(Target, value)
                end
            end
        end
    end

    @test Int256(Int3(1)) === Int256(1)
    @test Int3(-1) % UInt256 === typemax(UInt256)
    @test_throws InexactError UInt256(Int3(-1))
    extension = Base.get_extension(EmulatedBitIntegers, :BitIntegersExt)
    @test isempty(Test.detect_ambiguities(EmulatedBitIntegers, BitIntegers, extension))
end