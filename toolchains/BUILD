package(default_visibility = ["//visibility:public"])
load(":cc_toolchain_config.bzl", "cc_toolchain_config")

filegroup(name = "empty")

cc_toolchain_config(name = "cortex_m4_toolchain_config")

cc_toolchain(
  name = "cortex_m4_toolchain",
  toolchain_identifier = "arm-none-eabi-gcc",
  toolchain_config = ":cortex_m4_toolchain_config",
  all_files = ":empty",
  compiler_files = ":empty",
  dwp_files = ":empty",
  linker_files = "@conan//stm32mp1:c_polyfill",
  objcopy_files = ":empty",
  strip_files = ":empty",
  supports_param_files = 0,
)

toolchain(
  name = "arm_none_eabi",
  exec_compatible_with = [
    "@platforms//cpu:aarch64",
  ],
  target_compatible_with = [
    "@platforms//cpu:armv7-m",
  ],
  toolchain = ":cortex_m4_toolchain",
  toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
