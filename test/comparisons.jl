@testset "float comparisons" begin
    @emulate Int1 UInt1 Int3 UInt3 Int31 UInt31 Int63 UInt63 Int65 UInt65 Int129 UInt129 Int3_256 UInt3_256
    @emulate Int20_24 UInt20_24 Int63_256 UInt63_256 Int65_256 UInt65_256 Int128_256 UInt128_256
    @emulate Int12 UInt12 UInt24_64 Int25 UInt25 Int53 UInt53 Int54 UInt54 Int3_128 UInt3_128

    @testset "comparison storage" begin
        for (Source, SmallFloat) in ((Int12, Float32), (UInt12, Float32),
                                     (Int20_24, Float32), (UInt20_24, Float32),
                                     (UInt24_64, Float32), (Int25, Float32), (UInt25, Float64),
                                     (Int53, Float64), (UInt53, Float64), (Int54, Float64),
                                     (Int3_128, Float32), (UInt3_128, Float32),
                                     (Int3_256, Float32), (UInt3_256, Float32))
            for x in (typemin(Source), zero(Source), typemax(Source)), Float in (Float16, Float32, Float64)
                Target = Float === Float64 ? Float64 : SmallFloat
                y = Float(0.5)
                operands = @inferred EmulatedBitIntegers.prepromote(x, y)
                @test operands isa Tuple{Target,Target}
                @test operands === (Target(x[]), Target(y))
                @test BigInt(first(operands)) == BigInt(x[])
                @test (@inferred EmulatedBitIntegers.prepromote(y, x)) === reverse(operands)
            end
        end
        for (Source, Target) in ((UInt54, UInt64), (Int63, Int64), (UInt63, UInt64),
                                  (Int63_256, Int64), (UInt63_256, UInt64),
                                  (Int65_256, Int128), (UInt65_256, UInt128),
                                  (Int128_256, Int128), (UInt128_256, UInt128),
                                  (Int129, BigInt), (UInt129, BigInt))
            for x in (typemin(Source), zero(Source), typemax(Source)), Float in (Float16, Float32, Float64)
                y = Float(0.5)
                operands = @inferred EmulatedBitIntegers.prepromote(x, y)
                @test operands isa Tuple{Target,Float}
                @test operands == (Target(x[]), y)
                operands = @inferred EmulatedBitIntegers.prepromote(y, x)
                @test operands isa Tuple{Float,Target}
                @test operands == (y, Target(x[]))
            end
        end
    end

    x = Int63(9007199254740993)
    y = 9007199254740992.0
    @test x != y
    @test !isequal(x, y)
    @test x > y
    @test y < x
    @test length(Set{Real}(Real[x, y])) == 2
    @test !haskey(Dict{Real,Int}(x => 1), y)
    @test Int129(big(2)^100 + 1) > Float64(big(2)^100)
    @test UInt129(big(2)^100 + 1) != Float64(big(2)^100)

    operators = COMPARISON_OPERATORS
    sources = (BOUNDARY_TEST_TYPES..., Int12, UInt12, UInt24_64, Int25, UInt25,
               Int53, UInt53, Int54, UInt54, Int3_128, UInt3_128)
    for Source in sources
        low, high = BigInt(typemin(Source)), BigInt(typemax(Source))
        values = boundary_values(Source)
        for shift in (11, 24, 53, 63, 64, 100, 127, 128), offset in (-1, 0, 1)
            value = (big(1) << shift) + offset
            push!(values, value, -value)
        end
        filter!(value -> low <= value <= high, values)
        unique!(values)
        floats_to_test = Source in (Int3, UInt3, Int129, UInt129) ? (Float16, Float32, Float64, BigFloat) :
                 bits(Source) <= 25 ? (Float16, Float32, Float64) : (Float64,)
        for Float in floats_to_test, op in operators
            @test (@inferred op(zero(Source), zero(Float))) === op(big(0), zero(Float))
            @test (@inferred op(zero(Float), zero(Source))) === op(zero(Float), big(0))
        end
        for Float in floats_to_test, value in values
            x = Source(value)
            rounded = Float(value)
            floats = (rounded, prevfloat(rounded), nextfloat(rounded))
            for y in floats, op in operators
                @test op(x, y) === op(value, y)
                @test op(y, x) === op(y, value)
            end
            for y in floats
                if isequal(value, y)
                    @test hash(x) == hash(y)
                    @test haskey(Dict{Real,Int}(x => 1), y)
                end
            end
        end
        for Float in floats_to_test, value in (low, big(0), high)
            x = Source(value)
            for y in (Float(0.0), Float(-0.0), Float(0.5), Float(-0.5), Float(Inf), Float(-Inf), Float(NaN)), op in operators
                @test op(x, y) === op(value, y)
                @test op(y, x) === op(y, value)
            end
        end
    end
    setprecision(BigFloat, 24) do
        x = Int129(big(2)^100 + 1)
        y = BigFloat(big(2)^100)
        for op in operators
            @test op(x, y) === op(BigInt(x[]), y)
            @test op(y, x) === op(y, BigInt(x[]))
        end
    end
end

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
    integer_types = (Bool, Int8, UInt8, Int, UInt, Int128, UInt128, BitIntegers.Int256, BitIntegers.UInt256)
    for Emulated in emulated_types
        operators = Emulated in (Int9, UInt9) ? COMPARISON_OPERATORS : (==, <, <=)
        for value in (typemin(Emulated), zero(Emulated), typemax(Emulated))
            for Other in (integer_types..., Emulated, signed(Emulated), unsigned(Emulated), Int3, UInt3) |> unique
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