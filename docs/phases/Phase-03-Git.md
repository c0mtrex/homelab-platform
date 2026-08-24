# Phase 003 — Git and GitHub

## Objective

Use version control as an operational control rather than only as file storage. Changes should be reviewable, reversible, attributable, and reproducible.

## Accomplishments

- Installed and configured Git.
- Created the public `homelab-platform` GitHub repository.
- Connected local and remote repositories.
- Practiced staging, commits, pushes, branches, and history inspection.
- Preserved an unpublished OPNsense commit while moving development from a QNAP checkout to local VM storage.
- Introduced a feature branch for platform reconciliation.
- Added LF line-ending policy for consistent Linux, Windows, and NAS checkouts.

## Current workflow

```text
Synchronize main
      |
      v
Create feature branch
      |
      v
Make and validate a focused change
      |
      v
Commit and push branch
      |
      v
Open pull request
      |
      v
Automated checks and review
      |
      v
Merge into main
```

## Lessons learned

- A working tree, local repository, remote-tracking reference, and GitHub repository are different states.
- Changing a remote URL does not fetch new remote state.
- `git fetch` refreshes remote-tracking references without changing working files.
- `git status -sb` quickly reveals divergence such as `ahead 1`.
- Git tracks files and content rather than empty directories.
- NAS and Windows tools can introduce line-ending-only changes.
- A commit hash identifies content and history; it is not an approval or test result.
- GitHub is a collaboration location, while a pull request and CI provide workflow controls.

## Storage decision

Active development occurs in a local Linux clone. GitHub provides the collaboration copy, and QNAP provides another recovery location. This avoids treating an SMB working directory as the only active development filesystem.

## Next improvements

- Add pull-request validation through GitHub Actions.
- Validate Markdown, YAML, Docker Compose, and Kubernetes manifests.
- Create issue templates and operational change records when they add value.
- Protect `main` where the repository plan supports enforcement.
- Verify successful replication to QNAP after accepted changes.
