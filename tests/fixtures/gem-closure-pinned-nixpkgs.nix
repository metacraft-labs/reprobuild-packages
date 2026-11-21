# The Ruby-with-gems derivation tests/test_gem_closure_manifest.nim's fixture
# was recorded from: nixpkgs 687f05a9184cad4eaf905c48b63649e3a86f5433 (the
# revision codetracer-ruby-recorder's flake.lock pinned when its Windows gem
# manifest was first generated), Ruby 3.4 with nokogiri and sinatra.
{ system ? "x86_64-linux" }:
let
  nixpkgs = builtins.fetchTree {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "687f05a9184cad4eaf905c48b63649e3a86f5433";
    narHash = "sha256-vZJZjLo513IeI8hjzHFc6TDezUd4uCE2Eq4SNO3DNNg=";
  };
  pkgs = import nixpkgs.outPath { inherit system; };
in
pkgs.ruby_3_4.withPackages (ps: [ ps.nokogiri ps.sinatra ])
