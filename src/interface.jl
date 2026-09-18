# A type-specific docstring is added in `@emulate` in order for `help?>` to find the constructor.
function (::Type{T})(x::Real) where {S, T<:EmulatedInteger{S}}
    reinterpret(T, convert_storage(T, x))
end

# Due to [unintuitive method resolution in Julia](https://github.com/JuliaLang/julia/issues/24723), the above constructor is ambiguous with Base's `T(::Rational) where T<:Integer` (rational.jl) and `T(::BigFloat) where T<:Integer` (mpfr.jl). So tell Julia which constructor to choose by defining more specific constructors and forwarding them to the one defined above.
for X in (Rational, BigFloat)
    @eval (::Type{T})(x::$X) where {S, T<:EmulatedInteger{S}} = invoke(T, Tuple{Real}, x)
end

# Keeping exception construction out of line avoids GC-frame setup on successful conversions.
@noinline function throw_inexact(::Type{T}, x) where T
    throw(InexactError(:trunc, T, x))
end

"""
    convert_storage(T::Type{<:EmulatedInteger}, x::Real)

Convert `x` to the storage type of `T`, requiring exact representability in `T`.

Separate storage conversion from construction so specialized methods can avoid redundant range checks and unnecessary wide-integer conversions.
"""
function convert_storage(::Type{T}, x::Real) where T<:EmulatedInteger
    _x = convert(T |> storagetypeof, x)
    inrange(T, _x) ? _x : throw_inexact(T, _x)
end

function convert_storage(::Type{T}, x::Integer) where T<:EmulatedInteger
    minvalue(T) <= x <= maxvalue(T) || throw_inexact(T, x)
    return x % storagetypeof(T)
end

function convert_storage(::Type{T}, x::Base.IEEEFloat) where T<:EmulatedInteger
    isinteger(x) || throw_inexact(T, x)
    return trunc(T, x)[]
end

function Base.trunc(::Type{T}, x::Float) where {T<:EmulatedInteger, Float<:Base.IEEEFloat}
    bound = ldexp(oneunit(x), bits(T) - (T <: Signed))
    lower_ok = if T <: Unsigned
        -oneunit(x) < x
    elseif bits(T) <= precision(Float)
        -bound - oneunit(x) < x
    else
        -bound <= x
    end
    lower_ok && x < bound && isfinite(x) || throw_inexact(T, x)
    return unsafe_trunc(T, x)
end

"""
    unsafe_trunc(T::Type{<:EmulatedInteger}, x::Union{Float16, Float32, Float64})

Truncate `x` toward zero as `T`, requiring the truncated value to be representable in `T`.
"""
function Base.unsafe_trunc(::Type{T}, x::Float) where {S, T<:EmulatedInteger{S}, Float<:Base.IEEEFloat}
    width = min(bits(T), exponent(floatmax(Float)) + 1 + (T <: Signed))
    if width <= 128
        native = Base.BitSigned_types |> filter(Native -> width <= bits(Native)) |> first
        storage = unsafe_trunc(T <: Signed ? native : unsigned(native), x)
        return reinterpret(T, storage % S)
    end
    raw = reinterpret(Unsigned, x)
    fraction_bits = precision(Float) - 1
    exponent_bits = 8sizeof(Float) - precision(Float)
    shift = Int(raw >> fraction_bits) & (2^exponent_bits - 1) - (2^(exponent_bits - 1) - 1 + fraction_bits)
    implicit_bit = oneunit(raw) << fraction_bits
    significand = raw & (implicit_bit - oneunit(raw)) | implicit_bit
    significand >>= unsigned(max(-shift, 0))
    storage = (T <: Signed ? flipsign(signed(significand), x) : significand) % S
    return reinterpret(T, storage << unsigned(max(shift, 0)))
end

"""
    bits(T::Type) -> Int
    bits(x) -> Int

Logical bit width of `T` (or `typeof(x)`).

For the default primitive types, `bits(T) == 8 * sizeof(T)`. For struct types,
`bits(T)` is the recursive sum of `bits` over the fields.
Specific types may override this to report their logical width directly when
their storage includes padding.
"""
function bits(::Type{T}) where T
    isprimitivetype(T) && return 8 * sizeof(T)
    isstructtype(T) && return sum(i -> bits(fieldtype(T, i)), 1:fieldcount(T); init=0)
    8 * Base.packedsize(T)
end
bits(::Type{T}) where T<:Base.BitInteger = 8 * sizeof(T)
# `Base.Bottom` is a subtype of every type, including `Base.BitInteger`, so the `<:Base.BitInteger` method above would match it and recurse into `sizeof(Bottom)`, which errors. Bottom has no instances, so this branch is unreachable at runtime; the explicit method exists only to give type inference (and JET) a deterministic answer instead of the propagated error.
bits(::Type{Base.Bottom}) = lazy"Cannot determine bits for Bottom" |> ArgumentError |> throw
bits(x) = x |> typeof |> bits

"""
    zext(x)

Zero-extend the high order bits of the value to the storage type.

For standard integers, this function acts as the identity function since their logical size
and storage size are the same.
"""
zext(x::Integer) = x

"""
    zext(T::Type{<:Integer}, x::Integer) -> T

Zero-extend the bit pattern of `x` to integer type `T`, whose logical width must be at least that of `x`.
"""
function zext(T::Type{<:Integer}, x::Integer)
    T |> bits >= x |> typeof |> bits || lazy"$T must not be a type with less bits than the type of x" |> ArgumentError |> throw
    reinterpret(x |> zext |> typeof |> unsigned, x |> zext) % T
end

# Zero-extension to the storage type. Unsigned storage is already clean. Signed storage is sign-extended, so mask off the wasted high bits; the mask `storagetypeof(T)(-1) >>> wastedbits(T)` folds to a literal.
zext(x::EmulatedUnsigned) = x[]
zext(x::T) where T<:EmulatedSigned = x[] & (storagetypeof(T)(-1) >>> wastedbits(T))

"""
    storagetypeof(T::Type) -> Type

Return the storage type.

For primitive types, this is `T` itself. For single-field struct types, it is the
storage type of the field (recursively). All other types (abstract, `Union`, `UnionAll`,
multi-field structs, structs with non-bits fields) throw an `ArgumentError`.
"""
@inline function storagetypeof(x::DataType)
    isprimitivetype(x) && return x
    isstructtype(x) && fieldcount(x) == 1 && return fieldtype(x, 1) |> storagetypeof
    lazy"$x does not have a storage type" |> ArgumentError |> throw
end
storagetypeof(::Type{<:EmulatedInteger{S}}) where S = S
# Fallback for `UnionAll`, `Union`, and other non-`DataType` `Type` values. Without this, `fieldtype` on those would silently produce a `TypeVar` or `Any` and the recursion would yield garbage.
storagetypeof(x::Type) = lazy"$x does not have a storage type" |> ArgumentError |> throw
