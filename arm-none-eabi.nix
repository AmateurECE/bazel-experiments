(import <nixpkgs> {
  crossSystem = {
    config = "arm-none-eabi";
    libc = "newlib";
    gcc = {
      cpu = "cortex-m4";
      fpu = "fpv4-sp-d16";
    };
  };
}).pkgsBuildTarget.gcc
