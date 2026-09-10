@testset "scalar broadcasting" begin
    @emulate Int3 UInt3 Int3_128 UInt3_128

    @test Int3(2) * Int3[2] == Int3[-4]
    @test UInt3(3) * UInt3[3] == UInt3[1]

    for Element in (Int3, UInt3, Int3_128, UInt3_128)
        for scalar in (Element(2), typemin(Element), typemax(Element))
            vector = Element[2, 3]
            expected = map(value -> scalar * value, vector)
            @test Base.broadcastable(scalar)[] === scalar
            @test identity.(scalar) === scalar
            @test scalar .* scalar === scalar * scalar
            @test scalar * vector == expected
            @test vector * scalar == expected
            @test scalar .* vector == expected
            @test vector .* scalar == expected
            @test eltype(scalar * vector) === Element
            @test eltype(vector * scalar) === Element
            @test eltype(scalar .* vector) === Element
            @test scalar .+ vector == map(value -> scalar + value, vector)
            @test scalar .* (vector .+ scalar) == map(value -> scalar * (value + scalar), vector)
            destination = similar(vector)
            destination .= scalar .* vector
            @test destination == expected
            matrix = reshape(vector, 1, 2)
            @test scalar * matrix == reshape(expected, 1, 2)
            @test matrix * scalar == reshape(expected, 1, 2)
            @test scalar * fill(Element(2)) == fill(scalar * Element(2))
            @test eltype(scalar * fill(Element(2))) === Element
            @test isempty(scalar * Element[])
            @test eltype(scalar * Element[]) === Element
        end
    end
end