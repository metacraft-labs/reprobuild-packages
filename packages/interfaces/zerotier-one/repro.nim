## zerotier-one -- ZeroTier One, the ZeroTier network virtualization client (a
## system network extension and its daemon on macOS).
##
## The canonical identity of the application, so that profiles, data files and
## provisioning contributions name it the same way everywhere. This definition
## declares no realization yet: Reprobuild cannot install it, and a profile
## naming it resolves to a missing realization. Hosts that install it through
## Homebrew keep doing so; the Homebrew contribution catalog
## (reprobuild-brew-packages) maps the cask `zerotier-one` to this name as a
## bridge record that Nix consumers read and Reprobuild never realizes.

import repro_project_dsl

package `zerotier-one`:
  discard
