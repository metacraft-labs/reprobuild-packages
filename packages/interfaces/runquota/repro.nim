## runquota -- RunQuota, the lease coordinator that gates RunQuota-managed actions.
##
## The canonical identity of the package, so that profiles, data files and
## provisioning contributions name it the same way everywhere. This definition
## declares no realization yet: a profile naming it is realized from the host
## (PATH) or reported missing. It has no
## Nix contribution: a Nix consumer gets it from the runquota flake, not from a
## nixpkgs attribute; its Nix realization is the consumer's mapping
## (GNM-AREQ3).

import repro_project_dsl

package runquota:
  discard
