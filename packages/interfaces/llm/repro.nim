## llm -- llm, Simon Willison's command-line client for large language models.
##
## The canonical identity of the package, so that profiles, data files and
## provisioning contributions name it the same way everywhere. This definition
## declares no realization yet: a profile naming it is realized from the host
## (PATH) or reported missing. It has no
## Nix contribution: nixpkgs builds it as a Python environment whose package
## name is `python3`, and a contribution claiming that name would claim every
## Python environment (Gradual-Nix-To-Reprobuild-Migration.md, Identity across
## ecosystems). The Nix realization is the consumer's mapping (GNM-AREQ3).

import repro_project_dsl

package llm:
  discard
