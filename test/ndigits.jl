@testset "ndigits" begin
    @emulate Int3 UInt3 Int3_128 Int129 UInt129

    @test ndigits(typemin(Int129); base=2) == 129
    @test ndigits(typemin(Int129)) == 39
    @test ndigits(typemin(Int3); base=2) == 3

    for Source in (Int3, UInt3, Int3_128, Int129, UInt129)
        for x in (typemin(Source), typemin(Source) + one(Source), zero(Source), typemax(Source))
            expected = BigInt(x[])
            @test (@inferred ndigits(x)) == ndigits(expected)
            for base in (-16, -2, 2, 3, 10, 16), pad in (0, 1, 150)
                @test (@inferred ndigits(x; base, pad)) == ndigits(expected; base, pad)
            end
        end
        for base in (-1, 0, 1)
            @test_throws DomainError ndigits(zero(Source); base)
        end
    end
end