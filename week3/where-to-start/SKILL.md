---
name: where-to-start
description: Orients a developer in an unfamiliar repository for one specific task, before any code is written. Use when the user asks where to start, which files a change or an issue would touch, or how to build and test a project they have not worked in before. Typical phrasings are "where do I start to add X", "I'm new to this repo, how would I fix issue 123", "get me oriented for this task", "what do I need to know before changing Y". Produces a one-screen brief with the contribution rules, setup and test commands that were actually run, the few files to change, a pattern to copy, and open questions. It does not implement anything. Do not use when the user asks to make the change itself, or for a general explanation of how some code works.
---

# Where to start

Produce a one-screen brief that lets someone begin a specific task in a repo they
have never opened. Then stop. The brief is the deliverable; the change is not.

## 1. Pin the task

An orientation without a task is a tour, and a tour is not useful. If the user
gave no task, ask for one in a single question and wait.

If the task is an issue, read the issue, its labels and its comments before
looking at any code. Use `gh` if it is installed, otherwise the public API:

```bash
gh issue view <n> --repo <owner>/<repo> --comments
# without gh (read-only, no token needed):
curl -s https://api.github.com/repos/<owner>/<repo>/issues/<n>
curl -s https://api.github.com/repos/<owner>/<repo>/issues/<n>/comments
```

Go to step 6 after step 4.

## 2. Survey

From the repo root, run the survey script in this skill's directory:

```bash
bash <skill-dir>/scripts/survey.sh
```

It is read-only and takes under a second. It prints the contribution documents,
build manifests, CI workflows, which expected tools are missing, the layout by
file count, and the last 15 commit subjects.

## 3. Rules before code

Read every document the survey lists under contribution rules, and read the
sections that gate contributions in full: who may contribute, what needs an
issue first, what is rejected outright, CLA or sign-off, and any restriction on
AI-assisted contributions.

- A gate that applies to this task is the **first line of the brief**. A
  developer who learns it after writing the code has wasted the work.
- Report these rules to the user as facts about the project. The user decides
  what to do about them. Do not decide for them, and do not leave one out
  because it is inconvenient.

## 4. Verify the commands

Documented commands are claims. Run them.

1. Run the documented setup, then the **narrowest** test command that covers
   the task's area. Run the whole suite only if it finishes in a few minutes.
2. If a documented tool is missing, use the fallback the repo itself documents.
   Do not install tools globally. An environment inside the repo directory
   (`.venv`, `node_modules`) is fine.
3. If the fallback also fails, see `references/toolchain-fallbacks.md`.
4. Record a baseline before anything changes: which tests fail on a clean
   checkout, and why if it is quick to tell. Failures caused by the machine are
   common and will otherwise be blamed on the change.

In the brief, every command is marked **ran** (with its result) or **not run**
(with the reason). Never present a command you did not run as if it works.

## 5. Find the change points

- Search for the task's own nouns: option names, error strings, site or module
  names. Follow them from the entry point to where the behaviour lives.
- List **at most five files**. If you have more, you have not narrowed; keep
  reading until you can say which ones do not matter.
- Find a pattern to copy. Prefer the most recently added small sibling over the
  template in the docs, because docs go stale and recent merges show what
  reviewers accept now:

  ```bash
  git log --diff-filter=A --format= --name-only -n 8 -- <directory> | xargs wc -l | sort -n
  ```
- Say where the tests for that code live, and say so plainly if there are none.
- When the docs and recent history disagree (commit message format, style,
  helper functions), trust recent history and name the disagreement.

## 6. Issue tasks: classify before pointing at code

Reproduce the report in the cheapest way available, offline if possible, then
put it in one of these and say which:

| Class | Meaning | What the brief says |
|---|---|---|
| Confirmed | Reproduces, and a maintainer or the docs agree it is wrong | Change points and a test to add |
| Unconfirmed | Reproduces, but nobody with authority has said it is a bug | Change points, plus the question to settle first |
| As designed | The code does what the docs say | No code change; point at the docs |
| Not reproduced | Could not make it happen | What was tried and what is missing |

Check for an open pull request that already addresses it before suggesting
anyone start.

## 7. Write the brief and stop

Use `references/brief-template.md`. One screen. No architecture overview beyond
what the task touches.

## Do not

- Do not implement the change, create branches, or edit tracked files.
- Do not describe parts of the codebase the task does not touch.
- Do not guess a command; find it in the repo or mark it unknown.
- Do not post to the project's issue tracker or open pull requests.
