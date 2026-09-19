using EmulatedBitIntegers, BitIntegers, Test

@testset "uninstrumented effects" begin
    @emulate Int1 UInt1 Int7 UInt7 Int63 UInt63 Int129 UInt129 Int3_256 UInt3_256
    for Source in (Int1, UInt1, Int7, UInt7, Int63, UInt63, Int129, UInt129, Int3_256, UInt3_256)
        effects = Base.infer_effects(getindex, Tuple{Source})
        expected = Base.infer_effects(getindex, Tuple{storagetypeof(Source)})
        for property in (:consistent, :effect_free, :nothrow, :terminates)
            @test getproperty(effects, property) === getproperty(expected, property)
        end
        if VERSION >= v"1.13.0-"
            @test effects.noub === expected.noub
        end
    end
    for Source in (Int7, UInt7), operation in (float, nextpow, prevpow)
        arguments = operation === float ? Tuple{Source} : Tuple{Int, Source}
        storage_arguments = operation === float ? Tuple{storagetypeof(Source)} : Tuple{Int, storagetypeof(Source)}
        effects = Base.infer_effects(operation, arguments)
        expected = Base.infer_effects(operation, storage_arguments)
        for property in (:consistent, :effect_free, :nothrow, :terminates)
            @test getproperty(effects, property) === getproperty(expected, property)
        end
        if VERSION >= v"1.13.0-"
            @test effects.noub === expected.noub
        end
    end
end