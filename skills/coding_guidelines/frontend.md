# Frontend notes:

- When writing CSS, use a proper design system with CSS variables that are re-used.
- Never define new CSS variables that are just renaming existing, root CSS variables; use the root ones directly.
- Use as few CSS rules as possible.
  - For example, do not add `line-height` unless the user gave feedback about the UI that necessitated it. This applies to _all_ CSS properties.
- A single CSS file should ideally only style one component and its various states.

  If this project uses React, see the guidelines here: [/Users/jona/.codex/skills/coding_guidelines/react.md]
