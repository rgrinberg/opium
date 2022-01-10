{ pkgs ? import <nixpkgs> {}
, ocamlPackages ? pkgs.ocaml-ng.ocamlPackages_4_13
, opam2nix ?
    pkgs.callPackage ./nix/opam2nix.nix {
      inherit pkgs;
      ocamlPackagesOverride = ocamlPackages;
} }:

pkgs.callPackage ./nix { inherit ocamlPackages opam2nix; }
