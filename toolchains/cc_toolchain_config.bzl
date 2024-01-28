load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "tool_path")

def _impl(ctx):
  tool_paths = [
    tool_path(
      name = "gcc",
      path = "/nix/store/qs1k0kjz0hxx7g1nbk0az6m32sqibs6b-arm-none-eabi-gcc-wrapper-12.3.0/bin/arm-none-eabi-gcc",
    ),
    tool_path(
      name = "ld",
      path = "/nix/store/qs1k0kjz0hxx7g1nbk0az6m32sqibs6b-arm-none-eabi-gcc-wrapper-12.3.0/bin/arm-none-eabi-ld",
    ),
    tool_path(
      name = "ar",
      path = "/nix/store/qs1k0kjz0hxx7g1nbk0az6m32sqibs6b-arm-none-eabi-gcc-wrapper-12.3.0/bin/arm-none-eabi-ar",
    ),
    tool_path(
      name = "cpp",
      path = "/nix/store/qs1k0kjz0hxx7g1nbk0az6m32sqibs6b-arm-none-eabi-gcc-wrapper-12.3.0/bin/arm-none-eabi-g++",
    ),
    tool_path(
      name = "gcov",
      path = "/bin/false",
    ),
    tool_path(
      name = "nm",
      path = "/nix/store/qs1k0kjz0hxx7g1nbk0az6m32sqibs6b-arm-none-eabi-gcc-wrapper-12.3.0/bin/arm-none-eabi-nm",
    ),
    tool_path(
      name = "objdump",
      path = "/nix/store/qs1k0kjz0hxx7g1nbk0az6m32sqibs6b-arm-none-eabi-gcc-wrapper-12.3.0/bin/arm-none-eabi-objdump",
    ),
    tool_path(
      name = "strip",
      path = "/nix/store/qs1k0kjz0hxx7g1nbk0az6m32sqibs6b-arm-none-eabi-gcc-wrapper-12.3.0/bin/arm-none-eabi-strip",
    ),
  ]

  return cc_common.create_cc_toolchain_config_info(
    ctx = ctx,
    cxx_builtin_include_directories = [
      "/nix/store/7sarp0k2yvybff5pk5a343yl175kl5wj-arm-none-eabi-gcc-12.3.0/lib/gcc/arm-none-eabi/12.3.0/../../../../arm-none-eabi/include/c++/12.3.0",
      "/nix/store/7sarp0k2yvybff5pk5a343yl175kl5wj-arm-none-eabi-gcc-12.3.0/lib/gcc/arm-none-eabi/12.3.0/../../../../arm-none-eabi/include/c++/12.3.0/arm-none-eabi",
      "/nix/store/7sarp0k2yvybff5pk5a343yl175kl5wj-arm-none-eabi-gcc-12.3.0/lib/gcc/arm-none-eabi/12.3.0/../../../../arm-none-eabi/include/c++/12.3.0/backward",
      "/nix/store/7sarp0k2yvybff5pk5a343yl175kl5wj-arm-none-eabi-gcc-12.3.0/lib/gcc/arm-none-eabi/12.3.0/include",
      "/nix/store/7sarp0k2yvybff5pk5a343yl175kl5wj-arm-none-eabi-gcc-12.3.0/lib/gcc/arm-none-eabi/12.3.0/include-fixed",
      "/nix/store/7sarp0k2yvybff5pk5a343yl175kl5wj-arm-none-eabi-gcc-12.3.0/lib/gcc/arm-none-eabi/12.3.0/../../../../arm-none-eabi/sys-include",
      "/nix/store/7sarp0k2yvybff5pk5a343yl175kl5wj-arm-none-eabi-gcc-12.3.0/lib/gcc/arm-none-eabi/12.3.0/../../../../arm-none-eabi/include",
      "/nix/store/pcdisqcx7jvjh8dbpxs4r2qcav1vk4jf-newlib-arm-none-eabi-4.3.0.20230120/arm-none-eabi/include",
    ],
    toolchain_identifier = "arm-none-eabi-gcc",
    host_system_name = "local",
    target_system_name = "stm32g4",
    target_cpu = "armv7-m",
    target_libc = "newlib",
    compiler = "gcc",
    abi_version = "unknown",
    abi_libc_version = "unknown",
    tool_paths = tool_paths,
  )

cc_toolchain_config = rule(
  implementation = _impl,
  attrs = {},
  provides = [CcToolchainConfigInfo],
)
