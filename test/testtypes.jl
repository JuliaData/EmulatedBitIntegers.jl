@emulate Int1 UInt1 Int3 UInt3 Int20_24 UInt20_24 Int63 UInt63 Int65 UInt65 Int129 UInt129 Int3_256 UInt3_256

const SMALL_TEST_TYPES = (Int3, UInt3)
const STORAGE_TEST_TYPES = (SMALL_TEST_TYPES..., Int20_24, UInt20_24, Int3_256, UInt3_256,
                            Int65, UInt65, Int129, UInt129)
const BOUNDARY_TEST_TYPES = (Int1, UInt1, STORAGE_TEST_TYPES..., Int63, UInt63)
const REDUCTION_TEST_TYPES = (SMALL_TEST_TYPES..., Int65, UInt65)
const COMPARISON_OPERATORS = (==, !=, <, <=, >, >=, isequal, isless)

function boundary_values(::Type{Source}) where Source
    low, high = BigInt(typemin(Source)), BigInt(typemax(Source))
    return unique(filter(value -> low <= value <= high,
                         [low, low + 1, big(-1), big(0), big(1), high - 1, high]))
end