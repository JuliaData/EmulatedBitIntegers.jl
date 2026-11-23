# Changelog

## 0.6.0 (2026-11-23)

### Breaking

- `bits(Bool)` is `1`, the logical width of `Bool`. `bits` of structs with `Bool` fields changes accordingly.
- Mixed-sign `div`, `rem`, `mod`, `fld`, `cld`, `divrem` and `fldmod` with an emulated signed operand return the promoted type and throw `InexactError` when the exact result does not fit. `rem` and `mod` with an unsigned dividend previously returned storage types.
- `powermod` with a signed emulated modulus returns the modulus type on all Julia versions.

### Fixed

- `zext(T, ::Bool)`.
- `powermod` with a signed emulated modulus: wrong residue for `typemin`, error for `Int1`.
- Stack overflow when promoting wide emulated integers with `BigInt`.
- Signed stepped ranges no longer require the unsigned counterpart. Empty `Int1` stepped ranges work.

## 0.5.0 (2026-09-19)

### Added

- BitIntegers.jl package extension for conversions between both packages' types.
- `ndigits`, `bitreverse`, `trunc`, `unsafe_trunc`, faster `gcd`, `bitstring` and `powermod`.

### Changed

- Comparisons are reimplemented for efficiency and correctness.
- `sum` of narrow emulated integers returns `Int` or `UInt`, as in Base.
- Promotion between equal logical widths picks the larger storage. Promotion with floats is fixed.

### Fixed

- Broadcasting, remainders, `leading_zeros`, `oneunit`, `zext`, `isqrt`, `widemul`, `prod`, `cumsum`, `rand`, `prevpow`, `nextpow`, range `length`, `Int1` ranges and `Bool` promotion.

## 0.4.2 (2026-07-09)

- Storage access tells LLVM the valid value range (Julia 1.13 and later).

## 0.4.1 (2026-06-30)

- `rem` no longer throws for arguments with a larger storage type.

## 0.4.0 (2026-06-15)

- Open source release.
