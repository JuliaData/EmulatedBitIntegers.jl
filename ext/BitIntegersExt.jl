module BitIntegersExt

using EmulatedBitIntegers: EmulatedInteger
import BitIntegers
using BitIntegers: AbstractBitSigned, AbstractBitUnsigned

if VERSION < v"1.11-" && isdefined(BitIntegers, :broken_mul_with_overflow) &&
   !hasmethod(BitIntegers.broken_mul_with_overflow, Tuple{T, T} where T<:AbstractBitUnsigned)
	# TODO: Upstream the missing unsigned checked-multiplication fallback to BitIntegers.
	function BitIntegers.broken_mul_with_overflow(x::T, y::T) where T<:AbstractBitUnsigned
		product = BigInt(x) * BigInt(y)
		result = product % T
		return result, product > typemax(T)
	end
end

(::Type{Target})(value::EmulatedInteger) where {Target<:Union{AbstractBitSigned, AbstractBitUnsigned}} = Target(value[])

Base.rem(value::EmulatedInteger, ::Type{Target}) where {Target<:Union{AbstractBitSigned, AbstractBitUnsigned}} = value[] % Target

end