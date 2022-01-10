{ pkgs ? import <nixpkgs> {} }:
let
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_13;
  local = pkgs.callPackage ./. { inherit ocamlPackages; };
in
pkgs.mkShell {
  inputsFrom = with local; [ rock opium opium-testing opium-graphql ];
  buildInputs = [ ocamlPackages.ocaml-lsp pkgs.ocamlformat ];
}
