(import <nixpkgs> {
  crossSystem = {
    config = "armv7l-unknown-linux-gnueabihf";
  };
}).pkgsBuildTarget.gcc
