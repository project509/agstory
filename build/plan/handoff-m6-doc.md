# Handoff — M6-DOC-01 (root README)

Owner of this file: the agent that owned `README.md` only. Two things the README needs but
could not carry today, because the truth was not there to describe.

## 1. The export section is missing, deliberately

`M6-DOC-01`'s remaining_work asks the README to document `./tools/export_build.sh` and the
export-template prerequisite (`%APPDATA%/Godot/export_templates/4.7.1.stable.mono/`).
**`tools/export_build.sh` does not exist** (verified: `ls tools/` — no such file), and the
README must not describe a planned feature as present.

Whoever lands `M6-EXP-02` should add a short **Export a build** section between "Build the
art" and "Repo layout", naming the script, its flags and the export-template prerequisite.
`tests/unit/test_readme.gd::test_every_repo_path_the_readme_cites_exists` will hold that new
path honest automatically.

## 2. Two gates the docs require that this build does not have

The README describes the gates that exist. Two documented prerequisites/gates have no
implementation, and the README says so rather than listing a prerequisite nothing needs:

- **docs/14 §3.5 / §10.1 — ripgrep + Git Bash on `PATH`, or a shipped PowerShell
  equivalent.** Nothing in `tools/` uses `rg`; `tools/lint_no_global_classes.sh` and
  `tools/verify.sh` use `grep -P` from Git Bash. The README lists bash (Git Bash on Windows)
  and does not claim ripgrep. Per the audit this divergence belongs in **M6-EXP-05's
  docs/15 entry**, not in a second entry from here.
- **docs/14 §3.5 — `tools/check_sim_purity.sh`.** Not written. The README states plainly that
  the sim-purity rule is held by review and by the golden tests today, and that the proposed
  grep gate does not exist. If someone writes it, add it to the `verify.sh` stage table in
  the README.
