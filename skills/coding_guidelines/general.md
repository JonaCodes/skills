These are general guidelines you should always following when writing and/or reviewing any code:

- Keep things _simple_.
- Keep to the YAGNI principle.
- Avoid unnecessary abstractions.
- The 'main' function in any file should be top-most in the file.
- Helpers/utils should live in helper/util files, and should be re-used when possible. You can read `docs/utils.md` to find existing utils/helpers.
- All files should be 320 lines or fewer, unless there is a very good reason otherwise (for example, a unified store - but even then, worth considering how to split it up).
- When reviewing code, always ask yourself: "can this be done more simply? Have I overcomplicated this?" and if so, cut anything unnecessary.
- Generally speaking, when a function is too long, or too nested: it should be split apart.
- By and large, I should be able to read the code and follow 'core logic' in the main functions, with helpers doing the 'heavy lifting'.
- Handling errors should be reserved for the beginning and endpoints of major flows. For example: controller entry points, API access, etc. Avoid wrapping too many things in try-catch blocks. I prefer for the app to break when something unexpected happens rather than trying to gracefully handle every edge case.
- Separate concerns religiously; each file should have a clear purpose, not a jumble of different responsibilities.
- That said, files with one line or one function are ridiculous; avoid these.
- Take it easy with typescript Types. While they are important, avoid unnecessary abstractions and weird types. Keep it simple.

**Crucial**: when checking your own work, if you need to test something visual, use the built-in browser. If it does not work, stop and say so.

## --

For specific guidelines depending on your task, see:

- Backend: [/Users/jona/.codex/skills/coding_guidelines/backend.md]
- Frontend: [/Users/jona/.codex/skills/coding_guidelines/frontend.md]
- Database: [/Users/jona/.codex/skills/coding_guidelines/db.md]
