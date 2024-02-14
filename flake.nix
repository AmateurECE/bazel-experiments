{
  description = "Flake environment for Bazel";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    metalwork = {
      type = "github";
      owner = "AmateurECE";
      repo = "metalwork";
    };
  };

  outputs = { self, nixpkgs, metalwork, ... }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ];
  in {
    devShells = forAllSystems(system:
      let
        pkgs = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "arm-none-eabi";
            libc = "newlib";
            gcc = {
              cpu = "cortex-m4";
              fpu = "fpv4-sp-d16";
            };
          };
        };
        conan-config = metalwork.lib.mkConanConfig pkgs;
      in {
        default = pkgs.callPackage(
          {}: pkgs.mkShell ({
            nativeBuildInputs = with pkgs.pkgsBuildHost; [
              bazel
              conan
              conan-config
            ];
            buildInputs = with pkgs.pkgsBuildTarget; [ gcc ];

            # Needed to allow ld-linux.so to locate shared libraries installed
            # by nix packages linked to by executables that are compiled for
            # the host
            LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";

            shellHook = ''
              conan config install ${conan-config}/conan
            '';
          })
        ) {};
      }
    );
  };
}
