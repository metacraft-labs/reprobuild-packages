## xdg-desktop-portal -- xdg-desktop-portal, the desktop integration portal
## service.
##
## The canonical identity of the package, so that profiles, data files and
## provisioning contributions name it the same way everywhere. This definition
## declares no realization yet: a profile naming it is realized from the host
## (PATH) or reported missing. The Nix contribution catalog
## (reprobuild-nix-packages) maps the nixpkgs attribute `xdg-desktop-portal` to
## this name, which is how a Home Manager configuration's package is identified
## in `repro home compare`.

import repro_project_dsl

package `xdg-desktop-portal`:
  discard
