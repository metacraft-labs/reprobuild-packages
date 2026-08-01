# Reprobuild Packages

This repository owns reusable package interfaces and their source-build
recipes. Package declarations use canonical identities such as `bash` and
`curl`; the source implementation is a realization of that package, not part
of its public name.

Keep package recipes independently importable from
`packages/source/<selector>/repro.nim`. Do not add aggregate imports that make
every package part of every provider compile.

Changes land on `dev`. Keep the public commit history user-facing and avoid
workspace-specific implementation details.

