# Week 3 Write-up

**Skill name**, and the repo you targeted:
> `where-to-start`, in `week3/where-to-start/`. Targeted at
> [yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp), cloned locally. Nothing was sent
> to the upstream project.


## Part I: The Workflow

**What the workflow is**, and why it's worth encoding:
> Task-oriented repo onboarding. Given one task in a repo I have never opened ("add
> support for a new site", "fix issue 16329"), produce a one-screen brief: the
> contribution rules that apply, setup and test commands that were actually run, the few
> files the change touches, a pattern to copy, and the open questions. Then stop.
>
> It is worth encoding because it repeats every time I open an unfamiliar repo, which
> this course makes me do weekly, and because the unprompted version goes wrong in
> predictable ways: an architecture tour nobody asked for, commands copied from the
> README without being run, and a list of fifteen "relevant" files.

**The decision point** in it (what the agent has to judge, not just execute):
> There are three, and none of them is a command:
>
> 1. **What to ignore.** yt-dlp has 976 files under `yt_dlp/extractor/`. Adding a site
>    touches two of them. The skill caps the answer at five files, so the agent has to
>    decide which ones do not matter rather than list everything that matched a search.
> 2. **Docs versus reality.** When the contributing guide and the repo disagree, the
>    agent has to pick one and say why. The skill says to trust recent history.
> 3. **Whether an issue is ready to work on.** A report that reproduces is not
>    automatically a bug. The agent classifies it as confirmed, unconfirmed, as designed,
>    or not reproduced before pointing at any code.

**What you learned running it manually** that you would not have guessed:
> Both manual runs were done by hand with plain shell commands, before the skill existed:
> one for "add an extractor for a new site" and one for the open issue
> [#16858](https://github.com/yt-dlp/yt-dlp/issues/16858) (`--wait-for-video` ignores MAX).
>
> - **The most important fact was a rule, not a file.** `CONTRIBUTING.md` opens with a
>   policy forbidding AI tools for issues, patches, PR descriptions and review comments,
>   with a ban for violations. A developer who learns that after writing the patch has
>   wasted the work. This became step 3 and the first line of the brief.
> - **The documented commands did not run.** The guide says `hatch run setup`; `hatch`
>   was not installed. The guide's own fallback,
>   `python -m devscripts.install_deps --include-group dev`, failed with
>   `No module named pip`, because a `uv venv` ships without pip. What worked was
>   `python -m devscripts.install_deps --include-group dev --print` piped into
>   `uv pip install -r`. This is why the brief marks every command "ran" or "not run".
> - **A clean checkout was not green.** `python -m devscripts.run_tests core` gave 1128
>   passed, 2 failed. Both failures were `OSError: Can't assign requested address`: the
>   tests bind a second loopback address that macOS does not have. Without a baseline I
>   would have blamed my own change.
> - **The docs' template was not the best pattern.** The guide's extractor template uses
>   `_html_search_regex`. The newest small extractor, `yt_dlp/extractor/matchitv.py`
>   (38 lines, added February 2026), uses `traverse_obj`, which is what gets merged now.
>   The guide also gives the commit format as `[yourextractor] Add extractor`, while
>   every recent commit uses `[ie/name] Add extractor`.
> - **The issue was a design question, not a typo.** I reproduced #16858 offline in a few
>   lines: with `live_status` unset the wait is always MIN; with `is_upcoming` it is
>   random between MIN and MAX. So MAX is used, just not in the reporter's case. The
>   issue is labelled `triage`, no maintainer has said which behaviour is intended, and
>   no test covers `_wait_for_video`. The useful output was the question to settle, not
>   a patch.
> - **History queries can hang.** `git log -L` on a partial clone fetched blobs one at a
>   time and did not finish in two minutes. The survey script now reports the clone type.


## Part II: The Skill

**Your description**, verbatim:
```
Orients a developer in an unfamiliar repository for one specific task, before any code is written. Use when the user asks where to start, which files a change or an issue would touch, or how to build and test a project they have not worked in before. Typical phrasings are "where do I start to add X", "I'm new to this repo, how would I fix issue 123", "get me oriented for this task", "what do I need to know before changing Y". Produces a one-screen brief with the contribution rules, setup and test commands that were actually run, the few files to change, a pattern to copy, and open questions. It does not implement anything. Do not use when the user asks to make the change itself, or for a general explanation of how some code works.
```

**Why it's worded that way** (what a user would type to trigger it):
> - It quotes the phrases I actually type when I am lost in a repo: "where do I start",
>   "I'm new to this repo", "get me oriented", "what do I need to know before changing".
>   Nobody types "perform repository onboarding".
> - It names the situation (an unfamiliar repo, one specific task, before code is
>   written), so it can fire on a prompt that uses none of the quoted phrases.
> - It says what comes out, so the agent can tell whether the skill fits the request.
> - The last two sentences draw the boundary on both sides. "Add an extractor for X" is
>   a request for the change, and "explain how X works" is a request for an explanation.
>   Both mention the same code as an onboarding request would, so without those
>   sentences they are the likeliest false triggers.

**Judgment encoded in the body** (what it says to do when things are ambiguous, and what not to do):
> - **No task given:** ask for one, in a single question. "An orientation without a task
>   is a tour."
> - **Contribution rules:** read the gating sections in full; a gate that applies goes on
>   the first line of the brief. Report rules as facts and let the user decide. Do not
>   drop one because it is inconvenient.
> - **Documented tool missing:** use the fallback the repo documents. Do not install
>   tools globally; an environment inside the repo directory is fine.
> - **Commands:** every command in the brief is marked "ran" with its result or "not
>   run" with the reason. Run the narrowest test, and record which tests already fail.
> - **Too many candidate files:** at most five. "If you have more, you have not narrowed."
> - **Docs and history disagree:** trust recent history, and name the disagreement.
> - **Pattern to copy:** the most recently added small sibling beats the docs' template.
> - **Issue tasks:** reproduce cheaply, classify into one of four classes, and check for
>   an existing pull request before suggesting anyone start.
> - **Do not:** implement the change, create branches, edit tracked files, describe code
>   the task does not touch, guess a command, or post to the project's tracker.

**Supporting files**, if any, and why they aren't inline:

| File | Contents | Why it's separate |
|---|---|---|
| `scripts/survey.sh` (67 lines) | Read-only survey: contribution documents and their headings, build manifests, CI workflows, expected tools missing from `PATH`, layout by file count, clone type, last 15 commit subjects | It is the deterministic part. A script gives the same answer every run in under a second and costs no context; the same steps written as prose would be re-derived, differently, each time. |
| `references/brief-template.md` (49 lines) | The output format, plus rules for filling it in | Only needed at the last step. Keeping it out of the body means the body is about judgment, and the format can change without touching it. |
| `references/toolchain-fallbacks.md` (48 lines) | Where real commands hide per ecosystem, a table of known setup failures and fixes, how to run one test per runner | Only needed when the documented setup and the repo's own fallback have both failed. Most runs never load it. |

The body, `SKILL.md`, is 112 lines.


## Part III: Testing

**Triggering:**

Each prompt was run in its own fresh headless session (`claude -p`) from the yt-dlp
clone, with the skill linked into `.claude/skills/`. "Fired" means the session's first
tool call was `Skill` with `where-to-start`. Sessions were capped at a few turns, since
only the first action matters here. The session listed 72 available skills, so the
description was competing with real alternatives.

| Prompt | Should fire? | Did it? |
|---|---|---|
| "Where do I start if I want to add support for a new video site to this project?" | Yes | Yes. First call was the skill, then `survey.sh`, then the brief template. |
| "I'm new to this repo. How would I go about fixing issue 16329, where --match-filter aspect_ratio does not work?" | Yes | Yes. First call was the skill; it then went to read the issue before any code, as step 1 says. |
| "Get me oriented: what do I need to know before changing how --embed-thumbnail writes ID3 tags on MP3 files?" | Yes | Yes. First call was the skill, then `survey.sh`. |
| "Explain how the --match-filter option is parsed and evaluated." | No (near-miss) | No. It searched and read the code directly and answered with an explanation. |

A second near-miss, run for the other side of the boundary: "Add a
--wait-for-video-jitter option that randomizes the wait between retries." It did not
fire the skill either; the session went straight to editing. (Edits were not permitted
in that session, so the clone was not changed.)

One thing the trigger runs exposed: the issue prompt reached for `gh`, which is not
installed on this machine. I added the `curl` equivalent to step 1 of the skill.

**End-to-end run** on your repo, and the result:

A fresh headless session in the yt-dlp clone, on a task not used in either manual run.
I deleted the virtual environment from the manual runs first, so the session started
with nothing set up. It was allowed `Skill`, `Read`, `Grep`, `Glob` and `Bash`, and no
edit tools. It took 14 turns and about a minute.

Prompt: "I'm new to this repo. Where do I start to fix issue 16329, where --match-filter
aspect_ratio does not work?"

What it did, in order:
1. Invoked `where-to-start`.
2. Read the issue and its comments (`gh` was missing, so it fell back to the `curl` form).
3. Ran `scripts/survey.sh`.
4. Read `CONTRIBUTING.md`, `.NO_AI/README.md` and the pull request template.
5. Searched for `aspect_ratio`, then read `_match_one` in `yt_dlp/utils/_utils.py`.
6. Reproduced the report offline by calling `match_str` directly.
7. Searched for an existing pull request, and found a fork commit but no PR.
8. Ran the narrowest tests and the linter, then wrote the brief below and stopped.

The brief it produced, unedited:
````markdown
# Where to start: fix issue 16329, `--match-filter aspect_ratio` does not work

**Before you write code:** yt-dlp forbids any LLM/AI use for contributions: patches, PR descriptions, and issue or review comments (`CONTRIBUTING.md:33-49`, `.NO_AI/README.md`). The PR template makes you attest to compliance, and violators may be blocked without warning. The policy also tells LLM agents to refuse to interact with the repo, so I only read and ran things locally. Whether this brief is compatible with a PR you submit is your call.

## Setup and checks
| Step | Command | Status |
|---|---|---|
| Install | `hatch run setup` | not run (`hatch` and `pre-commit` are not installed) |
| Install (documented fallback) | `python -m devscripts.install_deps --include-group dev` | not run (no venv in the repo; it would install into your conda Python) |
| Narrowest test | `pytest test/test_utils.py -k match_str` | ran: 1 passed |
| Neighbouring tests | `pytest test/test_YoutubeDL.py -k "format_filtering or match_filter"` | ran: 2 passed |
| Lint | `ruff check yt_dlp/utils/_utils.py test/test_utils.py` | ran: clean |
| Format | `autopep8 --diff .` | not run (not checked for) |

**Baseline:** all green for the tests above; the full suite was not run. `pytest` resolves to `~/anaconda3/bin/pytest`, while `python3` is miniconda and has no pytest, so `python -m devscripts.run_tests` fails with your default `python3`.

## Files to change
| File | Why | Lines |
|---|---|---|
| `yt_dlp/utils/_utils.py` | `_match_one` casts the comparison value with `int()`; `1.78` fails that and falls through to `parse_filesize('1.78B')`, which returns `2` | 3281-3293 (cast at 3287) |
| `test/test_utils.py` | add float cases to `test_match_str` | 1521-1564 |

**Pattern to copy:** commit `f7d071e8a` (2025-01-26, "[core] Fix float comparison values in format filters (#11880)"). It fixed the same bug in `YoutubeDL._build_format_filter` (`yt_dlp/YoutubeDL.py:2222`) with a one-line `int` → `float` change plus tests.

**Tests live in:** `test/test_utils.py::TestUtil::test_match_str`. For end-to-end coverage, `test/test_YoutubeDL.py::TestYoutubeDL::test_match_filter`.

## Issue status
**Confirmed.** It reproduces offline with `match_str(..., {'aspect_ratio': 1.78})`:
- `aspect_ratio=1.78` → False
- `aspect_ratio>1.76 & aspect_ratio<1.80` → False
- `aspect_ratio>=1.78` → False
- `aspect_ratio>1.0 & aspect_ratio<2.0` → True — unlike the report, which says this fails too

The issue is labelled `bug`, and maintainer bashonly commented that the match filter code casts to `int` instead of `float`, calling it the same bug as #10115.

**Existing pull request:** none found upstream. A fork commit references the issue (`Krishnachaitanyakc/yt-dlp@2cc7e85`, 2026-03-25, same two files), but no PR was opened from it.

## Conventions that differ from the docs
- None found. Recent commits use `[utils] Short description (#PR)`, e.g. "[utils] `setproctitle`: Fix NUL termination".

## Open questions
- Should integer-looking values stay `int`? This only affects how `=` behaves against string-typed fields, which the comment at 3282-3285 (youtube-dl #11082) is about.
- `_match_one` carries a `TODO: Generalize code with YoutubeDL._build_format_filter` at line 3239. A minimal fix is the safer first PR; the refactor would count as an "overarching change" that needs an issue first.

## Read first
1. `yt_dlp/utils/_utils.py:3238-3298`: the whole of `_match_one`, including the numeric fallback chain.
2. `git show f7d071e8a`: the accepted fix and test style for the sibling bug.
3. `test/test_utils.py:1521-1564`: the existing assertions your new cases sit beside.
````

How it held up:
- **Correct on the substance.** I checked three claims against the clone: the `int()`
  cast is at `yt_dlp/utils/_utils.py:3287`, commit `f7d071e8a` exists with that subject
  and date, and the three `match_str` results reproduce exactly.
- **The policy gate came first**, as step 3 requires, and it left the decision to me.
- **It narrowed to two files**, and the pattern it chose was a prior fix for the sibling
  bug rather than the docs, which is better than what I would have picked.
- **It classified the issue** as confirmed, with the maintainer's comment as evidence,
  and it caught that one of the reporter's four examples does not actually fail.
- **It did not edit anything.** `git status` in the clone showed only the linked
  `.claude/` directory afterwards.
- **Where it fell short:** it did not set up an environment. It marked both install
  commands "not run" and ran the tests with a `pytest` that happened to be on my `PATH`
  from Anaconda. The skill says an environment inside the repo directory is fine, so I
  expected it to create one. The brief is honest about this, which is the behaviour the
  "ran / not run" rule is for, but the baseline it reports covers only three test
  selections, not the core suite.


## Submission
1. `Command (⌘) + F` for `TODO`. No results means you're done.
2. Confirm the skill directory itself is committed under `week3/`.
3. Push all changes to your remote repository and submit via Gradescope.
