# Brief template

Fill every section. Write "none found" rather than leaving one out. Keep the
whole brief to one screen (about 40 lines).

```markdown
# Where to start: <task, in the user's words>

**Before you write code:** <the contribution gate that applies to this task, or "no gates found">

## Setup and checks
| Step | Command | Status |
|---|---|---|
| Install | `<command>` | ran: ok / ran: failed (<why>) / not run (<why>) |
| Narrowest test | `<command>` | ran: <N passed, M failed> |
| Lint / format | `<command>` | ran: clean / not run (<why>) |

**Baseline:** <failures on a clean checkout and their cause, or "all green">

## Files to change (at most five)
| File | Why | Lines |
|---|---|---|
| `<path>` | <what changes here> | <range> |

**Pattern to copy:** `<path>` (<size>, added <date>), because <reason>.
**Tests live in:** `<path>`, or "no tests cover this".

## Issue status (issue tasks only)
<Confirmed / Unconfirmed / As designed / Not reproduced>: <one sentence of evidence>.
Existing pull request: <link or "none found">.

## Conventions that differ from the docs
- <what the docs say> vs <what recent commits do>

## Open questions
- <something only the user or a maintainer can answer>

## Read first
1. `<path>:<lines>`: <why>
```

## Filling it in

- **Lines** are ranges someone can jump to, not whole files.
- **Open questions** are decisions, not gaps in your reading. "What should MAX
  mean when the release time is unknown?" belongs here. "I did not read the
  networking module" does not; go and read it, or drop it as irrelevant.
- **Read first** has at most three entries, ordered. If everything is listed,
  nothing is prioritised.
