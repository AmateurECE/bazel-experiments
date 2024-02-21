load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
  name = "io_tweag_rules_nixpkgs",
  url = "https://github.com/tweag/rules_nixpkgs/archive/refs/tags/v0.10.0.tar.gz",
  sha256 = "3744f41fb9de44e15861ac17909d3d3d7b15ad7d5147ab1a73a0da87591b7cdf",
  strip_prefix = "rules_nixpkgs-0.10.0",
)

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")
rules_nixpkgs_dependencies()

load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_cc_configure")
nixpkgs_git_repository(
  name = "nixpkgs",
  revision = "666fc80e7b2afb570462423cb0e1cf1a3a34fedd",
)

nixpkgs_cc_configure(
  repository = "@nixpkgs",
  name = "arm_linux_gnu",
  nix_file = "//:arm-linux-gnu.nix",
  cross_cpu = "cortex-a7",
  exec_constraints = [ ],
  target_constraints = [
    "@platforms//os:linux",
    "@platforms//cpu:armv7",
  ],
)

nixpkgs_cc_configure(
  repository = "@nixpkgs",
  name = "arm_none_eabi",
  nix_file = "//:arm-none-eabi.nix",
  cross_cpu = "cortex-m4",
  exec_constraints = [ ],
  target_constraints = [
    "@platforms//os:none",
    "@platforms//cpu:armv7-m",
  ],
)

# Load rules_cc, a dependency of nixpkgs_cc_configure
http_archive(
  name = "rules_cc",
  sha256 = "4dccbfd22c0def164c8f47458bd50e0c7148f3d92002cdb459c2a96a68498241",
  urls = ["https://github.com/bazelbuild/rules_cc/releases/download/0.0.1/rules_cc-0.0.1.tar.gz"],
)

load("@rules_cc//cc:repositories.bzl", "rules_cc_dependencies", "rules_cc_toolchains")
rules_cc_dependencies()
rules_cc_toolchains()
