# Test Matrices

Run the full suite with `Pkg.test()`. The shared groups in `testtypes.jl` cover
small signed and unsigned values, 24-bit backing storage, oversized 256-bit
backing storage, the native 128-bit path, and logical widths exceeding 128 bits.
`BOUNDARY_TEST_TYPES` adds one-bit integers and the 63/64-bit boundary.
Tests with additional width or precision thresholds declare those types locally.

To limit cold-run compilation without discarding the important cases:

- Check inference once per argument-type signature. Check numerical results
  independently over the value matrix.
- Exhaust small domains. Use extrema, adjacent boundary values, seeded samples,
  and one-hot patterns for larger domains.
- Exercise storage behavior across the shared groups. Cross container forms,
  RNG implementations, and array shapes only with representative types.
- Check the package-defined integer comparison operators broadly. Check the
  operators derived by Base on representative signed and unsigned types.
- Keep explicit regression cases, precision boundaries, range-length overflow,
  empty inputs, signed zero, nonfinite floats, and method/codegen checks.

Testset times include compilation and depend on suite order and Julia version.
One second is a target, not a timing assertion. JET and Aqua are unchanged.
README doctests still run in full, including Documenter's startup cost.