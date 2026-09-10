module BitIntegersExt

using EmulatedBitIntegers: EmulatedInteger
using BitIntegers: AbstractBitSigned, AbstractBitUnsigned

(::Type{Target})(value::EmulatedInteger) where {Target<:Union{AbstractBitSigned, AbstractBitUnsigned}} = Target(value[])

end