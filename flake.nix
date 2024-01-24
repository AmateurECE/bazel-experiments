{
  description = "Flake environment for Bazel";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ];
  in {
    devShells = forAllSystems(system:
      let pkgs = import nixpkgs {
          inherit system;
        };
      in {
        default = with pkgs; mkShell {
          packages = [ bazel ];
          # Needed to allow ld-linux.so to locate shared libraries installed
          # by nix packages linked to by executables that are compiled for
          # the host
          LD_LIBRARY_PATH = "${stdenv.cc.cc.lib}/lib";
        };
      }
    );
  };
}
