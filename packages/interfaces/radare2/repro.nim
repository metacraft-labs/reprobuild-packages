## radare2 -- radare2, the reverse-engineering framework.
##
## The canonical identity of the package, so that profiles, data files and
## provisioning contributions name it the same way everywhere. This definition
## declares no realization yet: a profile naming it is realized from the host
## (PATH) or reported missing. The Nix contribution catalog
## (reprobuild-nix-packages) maps the nixpkgs attribute `radare2` to this name,
## which is how a Home Manager configuration's package is identified in
## `repro home compare`.

import repro_project_dsl

package radare2:
  discard
