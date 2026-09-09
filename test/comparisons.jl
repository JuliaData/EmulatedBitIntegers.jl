@testset "integer comparisons" begin
    @emulate UInt1 Int1 UInt9 Int9 UInt9_32 Int9_32 UInt65 Int65 UInt129 Int129

    @test Int8(-1) < UInt9(0)
    @test Int8(-1) <= UInt9(0)
    @test !(Int8(-1) == UInt9(0))
    @test !(UInt9(0) < Int8(-1))
    @test !(UInt9(0) <= Int8(-1))
    @test !(UInt9(0) == Int8(-1))

    @testset "comparison storage" begin
        for (Left, Right, Storage) in ((Int8, UInt9, Int16), (Int9, UInt8, Int16),
                                      (Int9, UInt9, Int16), (Int8, UInt9_32, Int32),
                                      (Int9_32, UInt16, Int32), (Int65, UInt65, Int128))
            for (First, Second) in ((Left, Right), (Right, Left))
                operands = @inferred EmulatedBitIntegers.prepromote(typemin(First), typemax(Second))
                @test operands isa Tuple{Storage, Storage}
                @test operands == (typemin(First)[], typemax(Second)[])
            end
        end
        @test EmulatedBitIntegers.prepromote(Int9(-1), typemax(UInt16)) === (Int16(-1), typemax(UInt16))
        @test EmulatedBitIntegers.prepromote(typemax(UInt16), Int9(-1)) === (typemax(UInt16), Int16(-1))
    end

    @testset "single comparison codegen" begin
        for (Left, Right) in ((Int8, UInt9), (Int9, UInt8), (Int9, UInt9),
                              (Int8, UInt9_32), (Int9_32, UInt16))
            for types in ((Left, Right), (Right, Left)), op in (==, <, <=)
                ir = sprint(io -> code_llvm(io, op, types; debuginfo=:none))
                @test count("icmp", ir) == 1
            end
        end
    end

    emulated_types = (UInt1, Int1, UInt9, Int9, UInt9_32, Int9_32, UInt65, Int65, UInt129, Int129)
    integer_types = (Bool, Base.BitInteger_types..., BitIntegers.Int256, BitIntegers.UInt256)
    operators = (==, !=, <, <=, >, >=, isequal, isless)

    Threads.@threads for Emulated in emulated_types
        for value in (typemin(Emulated), zero(Emulated), typemax(Emulated))
            for Other in (integer_types..., emulated_types...)
                for other in (typemin(Other), zero(Other), typemax(Other)), op in operators
                    @test op(value, other) === op(value[], other[])
                    @test op(other, value) === op(other[], value[])
                end
            end
            for other in (-big(2)^256, big(-1), big(0), big(1), big(2)^256, BigInt(value[])), op in operators
                @test op(value, other) === op(value[], other[])
                @test op(other, value) === op(other[], value[])
            end
        end
    end
end