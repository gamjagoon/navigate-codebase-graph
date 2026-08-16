# Single-File HTML Report

Create one browser-ready HTML file outside the repository. This reference is
the fixed shape for every review report. Keep prose short and let the diagrams
show the structural change.

After writing it, open it with `xdg-open`, `open`, or `start` when that command
exists. A headless environment must still return the absolute file path.

## Required scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Architecture review — REPOSITORY</title>
    <style>
      :root { color-scheme: light; --ink:#172033; --muted:#64748b;
              --line:#cbd5e1; --accent:#0f766e; --warn:#b45309; }
      body { margin:0; background:#f8fafc; color:var(--ink);
             font:16px/1.5 system-ui,sans-serif; }
      main { max-width:1100px; margin:auto; padding:40px 24px; }
      article, .summary { background:white; border:1px solid var(--line);
                          border-radius:12px; padding:24px; margin:24px 0; }
      .meta, .evidence { display:grid; grid-template-columns:repeat(2,minmax(0,1fr));
                         gap:8px 24px; }
      .diagrams { display:grid; grid-template-columns:1fr 1fr; gap:16px; }
      .diagram { min-height:220px; border:1px solid var(--line); padding:16px;
                 border-radius:8px; background:#f8fafc; }
      .module { border:2px solid #334155; border-radius:8px; padding:10px;
                margin:8px 0; background:#fff; }
      .deep { border:4px solid var(--accent); background:#ecfdf5; }
      .leak { color:#b91c1c; border-color:#dc2626; }
      .label { color:var(--muted); font-size:12px; text-transform:uppercase;
               letter-spacing:.08em; }
      .badge { display:inline-block; border-radius:999px; padding:3px 10px;
               background:#e2e8f0; }
      .strong { background:#bbf7d0; } .worth { background:#fde68a; }
      .speculative { background:#cbd5e1; }
      code { font-family:ui-monospace,monospace; }
      @media (max-width:700px) { .diagrams,.meta,.evidence { grid-template-columns:1fr; } }
    </style>
  </head>
  <body><main>
    <!-- header, candidate articles, and top recommendation go here -->
  </main></body>
</html>
```

The inline CSS is the baseline. Optional Tailwind or Mermaid enhancements may
be used only when the report remains readable without them. If Mermaid is
used, initialize it with `securityLevel: "strict"`; never put raw repository
text inside executable script content.

## Header

Show the repository name, absolute scope, date, review mode, CodeGraph version,
index status, freshness signal, and a short legend:

- solid box = module;
- dashed line = seam;
- red border = leaked detail;
- thick teal border = deep module.

## Candidate article

Create one `<article>` per candidate with a stable anchor such as
`candidate-1`. Keep this exact order:

1. candidate title and recommendation badge;
2. files and symbols;
3. evidence table with `graph evidence`, `source evidence`, `test evidence`,
   and `inference` rows;
4. gate results and the deletion-test sentence;
5. before/after diagrams side by side;
6. one-sentence problem;
7. one-sentence deepening proposal;
8. short locality, leverage, test, and risk bullets;
9. ADR warning, when relevant;
10. unknown values written as `unavailable`.

Do not include a detailed interface signature. The user chooses the candidate
before the exploration/grilling stage.

## Diagram choices

Use the smallest diagram that makes the relationship obvious.

- **Call graph:** before shows several caller hops and red leakage edges;
  after shows one thick deep module with internals faded.
- **Cross-section:** before shows many thin pass-through modules; after shows
  one module owning the behavior.
- **Interface mass:** before shows a wide interface beside a small
  implementation; after shows a small interface hiding a larger implementation.
- **Sequence:** before shows repeated caller orchestration; after shows one
  call crossing the seam.

Use ordinary HTML boxes and inline SVG lines when a diagram must work offline.
Do not invent nodes that are not present in the evidence.

## Top recommendation

End with one larger summary card containing the selected candidate anchor, one
sentence explaining why it is first, and its strength. Finish the file's text
with:

> Which candidate would you like to explore?

## Attribution

This report shape adapts the MIT-licensed architecture-review guidance from
Matt Pocock's `improve-codebase-architecture` skill. Keep the attribution in
`SOURCES.md` and `THIRD_PARTY_LICENSES.md`.
