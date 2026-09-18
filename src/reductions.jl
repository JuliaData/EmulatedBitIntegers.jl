"""
    sum_hooks_compatible()

Check the private reduction hooks required for small-integer sum widening.

This check runs before installing the extensions during package precompilation.
Integration tests verify that `sum` actually uses these hooks.
"""
function sum_hooks_compatible()
    all(name -> isdefined(Base, name) && getfield(Base, name) isa Function,
        (:add_sum, :reduce_first, :reduce_empty)) || return false
    add = Base.add_sum
    first = Base.reduce_first
    empty = Base.reduce_empty
    for (Small, Accumulator, left, right) in ((Int8, Int, 100, 28), (UInt8, UInt, 200, 100))
        applicable(add, Small(left), Small(right)) || return false
        applicable(first, add, Small(1)) || return false
        applicable(empty, add, Small) || return false
        add(Small(left), Small(right)) === Accumulator(left + right) || return false
        first(add, Small(1)) === Accumulator(1) || return false
        empty(add, Small) === zero(Accumulator) || return false
    end
    return true
end

function sumtype(::Type{T}) where T<:EmulatedInteger
    if isconcretetype(T)
        return bits(T) < bits(Int) ? (T <: Signed ? Int : UInt) : T
    elseif T isa Union
        targets = map(sumtype, Base.uniontypes(T))
        allequal(targets) && return first(targets)
    end
    return T
end
sumvalue(x::Number) = x
sumvalue(x::EmulatedInteger) = sumtype(typeof(x))(x)

if sum_hooks_compatible()
    Base.add_sum(x::EmulatedInteger, y::Real) = sumvalue(x) + sumvalue(y)
    Base.add_sum(x::Real, y::EmulatedInteger) = sumvalue(x) + sumvalue(y)
    Base.add_sum(x::EmulatedInteger, y::EmulatedInteger) = sumvalue(x) + sumvalue(y)
    Base.reduce_first(::typeof(Base.add_sum), x::EmulatedInteger) = sumvalue(x)
    Base.reduce_empty(::typeof(Base.add_sum), ::Type{T}) where T<:EmulatedInteger = zero(sumtype(T))
else
    error("Unsupported Base sum internals for Julia $VERSION")
end

function prod_hooks_compatible()
    all(name -> isdefined(Base, name) && getfield(Base, name) isa Function,
        (:mul_prod, :reduce_first, :reduce_empty, :reducedim_init, :_reducedim_init)) || return false
    multiply = Base.mul_prod
    first = Base.reduce_first
    empty = Base.reduce_empty
    for (Small, Accumulator, left, right) in ((Int8, Int, 100, 3), (UInt8, UInt, 200, 3))
        applicable(multiply, Small(left), Small(right)) || return false
        applicable(first, multiply, Small(1)) || return false
        applicable(empty, multiply, Small) || return false
        multiply(Small(left), Small(right)) === Accumulator(left * right) || return false
        first(multiply, Small(1)) === Accumulator(1) || return false
        empty(multiply, Small) === one(Accumulator) || return false
    end
    return true
end

if prod_hooks_compatible()
    Base.mul_prod(x::EmulatedInteger, y::Real) = sumvalue(x) * sumvalue(y)
    Base.mul_prod(x::Real, y::EmulatedInteger) = sumvalue(x) * sumvalue(y)
    Base.mul_prod(x::EmulatedInteger, y::EmulatedInteger) = sumvalue(x) * sumvalue(y)
    Base.reduce_first(::typeof(Base.mul_prod), x::EmulatedInteger) = sumvalue(x)
    Base.reduce_empty(::typeof(Base.mul_prod), ::Type{T}) where T<:EmulatedInteger = one(sumtype(T))
    Base.reducedim_init(f, op::typeof(Base.mul_prod), values::AbstractArray{<:EmulatedInteger}, region) =
        Base._reducedim_init(f, op, value -> one(sumvalue(value)), prod, values, region)
else
    error("Unsupported Base product internals for Julia $VERSION")
end