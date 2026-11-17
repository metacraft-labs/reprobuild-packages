## reprobuild -- Reprobuild, the reproducible build and environment tool (`repro`).
##
## The canonical identity of the package, so that profiles, data files and
## provisioning contributions name it the same way everywhere. This definition
## declares no realization yet: a profile naming it is realized from the host
## (PATH) or reported missing. It has no
## Nix contribution: a Nix consumer gets it from the reprobuild flake, not from
## a nixpkgs attribute; its Nix realization is the consumer's mapping
## (GNM-AREQ3).

import repro_project_dsl

package reprobuild:
  discard
