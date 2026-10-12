# Toolchain fallbacks

Read this only when the repo's documented setup and its own documented fallback
have both failed. Order of preference: the repo's documented command, the
repo's documented fallback, then the table below.

## Finding the real commands

The CI workflow is the most reliable source, because it runs on every merge:

```bash
grep -nE '^\s*(run|uses):' .github/workflows/*.yml | grep -viE 'checkout|setup-|cache|upload' | head -40
```

Then the manifest's script table:

| Manifest | Where the commands are |
|---|---|
| `pyproject.toml` | `[tool.hatch.envs.*.scripts]`, `[tool.poe.tasks]`, `[tool.pdm.scripts]`, `[dependency-groups]` |
| `package.json` | `"scripts"` (`npm run` lists them) |
| `Makefile` | `grep -E '^[a-zA-Z_-]+:' Makefile` |
| `tox.ini` / `noxfile.py` | `tox -l` / `nox -l` |
| `Cargo.toml` | `cargo test -p <crate>` for one crate |
| `go.mod` | `go test ./<package>/...` for one package |

## Known failure modes

| Symptom | Cause | What to do |
|---|---|---|
| `No module named pip` inside a `uv venv` | `uv` environments ship without `pip` | If the repo's installer can print requirements, pipe them: `<installer> --print > reqs.txt && uv pip install -r reqs.txt`. Otherwise `uv pip install -e .` plus the dev group. |
| Documented runner (`hatch`, `poetry`, `tox`) is not installed | Not on this machine | Read what the runner's script expands to in the manifest and run that directly inside a local environment. |
| `uv venv` picks a Python newer than CI tests | No version pinned | Compare with the CI matrix; recreate with `uv venv --python <version>` if tests fail on syntax or deprecations. |
| A few tests fail on a clean checkout | Machine-specific: extra loopback addresses, missing optional binaries, no network | Run one failing test alone and read the error. Record it in the baseline; do not try to fix it. |
| Tests need the network | The suite calls live services | Say so in the brief. Run the offline subset for the baseline. |
| `git log -L` or `git blame` hangs | Partial clone fetching blobs one by one | Use `git log --format='%h %ad %s' --date=short -n 10 -- <file>` instead, or search the forge's web history. |
| `node_modules` install takes many minutes | Monorepo | Install one workspace: `pnpm install --filter <pkg>...` or `npm install -w <pkg>`. |

## Running the narrowest test

| Runner | One file | One test |
|---|---|---|
| pytest | `pytest path/to/test_x.py` | `pytest path/to/test_x.py::TestClass::test_name` or `-k name` |
| jest / vitest | `npx jest path/to/x.test.js` | `-t "name"` |
| go | `go test ./pkg/x` | `-run TestName` |
| cargo | `cargo test -p crate` | `cargo test -p crate name` |

Many repos wrap the runner (for example `python -m devscripts.run_tests <name>`).
Prefer the wrapper: it sets warning flags and markers that a bare runner does not.
