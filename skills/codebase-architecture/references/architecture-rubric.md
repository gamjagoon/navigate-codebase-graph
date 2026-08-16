# Architecture Candidate Rubric

Use this file to judge a candidate. It is intentionally self-contained so the
skill does not require a separate `codebase-design`, `grilling`, or
`domain-modeling` skill.

## Vocabulary

- **Module:** a unit that owns a responsibility.
- **Interface:** every fact a caller must know: inputs, outputs, ordering,
  invariants, errors, and relevant performance behavior.
- **Deep module:** substantial implementation hidden behind a small interface.
- **Shallow module:** an interface almost as complicated as its implementation.
- **Seam:** a place where behavior can change without editing the caller.
- **Adapter:** a translation between an interface and one concrete mechanism.
- **Locality:** related behavior and the bugs it creates stay together.
- **Leverage:** many callers gain behavior from one small interface.

Use these terms in the report. Do not replace `module` with `service`,
`interface` with `API`, or `seam` with `boundary`.

## Five gates

Check every candidate in order:

1. **Caller burden:** callers know internal ordering, data shape, error rules,
   transport details, or repeated orchestration.
2. **Repeated work:** the same behavior or orchestration appears in at least
   two callers or files, or the caller must bounce through many small modules.
3. **Deletion test:** deleting the suspected module would spread complexity
   into its callers instead of making that complexity disappear.
4. **Deepening benefit:** one smaller interface would increase locality or
   leverage by hiding the repeated or leaked behavior.
5. **Test seam:** the main behavior could be tested through the proposed
   interface instead of through internal helpers.

Record `pass`, `fail`, or `unavailable` for every gate. Attach the evidence
  label and exact file/symbol to each non-trivial claim.

## Strength

- **Reject:** gate 1 or gate 3 fails. Do not put it in the report.
- **Speculative:** graph evidence suggests a problem but current source or
  tests do not confirm it.
- **Worth exploring:** gates 1–3 pass, but gate 4 or gate 5 is uncertain, or
  an ADR needs review.
- **Strong:** all five gates pass with current graph, source, and test evidence.

High fan-in is not a defect by itself. A high-fan-in module with a small,
stable interface can be healthy and should be marked as such.

## Deletion-test wording

Write one sentence in every candidate card:

> If `<module>` disappeared, `<specific behavior>` would have to be repeated
> in `<callers/files>`, so the complexity would spread rather than vanish.

If this sentence cannot be supported, reject the candidate.

## Candidate limits

- Return no more than three candidates.
- Do not propose a detailed function signature before the user selects one.
- A file rename, wrapper, or layer move is not a deepening opportunity unless
  it also hides real behavior behind a smaller interface.
