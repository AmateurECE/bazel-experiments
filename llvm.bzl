load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:cc_toolchain_config_lib.bzl", "action_config", "feature", "flag_set", "flag_group")

def _make_action_configs(action_names, tool):
  return [
    action_config(
      action_name = action_name,
      tools = [
        struct(
          type_name = "tool",
          tool = tool,
        ),
      ],
    )
    for action_name in action_names
  ]

# clang++ --target=armv7m-none-eabi -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 \
#      -mthumb -mfloat-abi=softfp -fno-exceptions -fno-rtti -lcrt0-semihost \
#      -lsemihost -T picolibc.ld -o example main.cpp
def _cc_arm_llvm_toolchain_config_impl(ctx):
  """Provides a CcToolchainConfigInfo for the ARM LLVM toolchain."""
  action_configs = _make_action_configs(
    [
      ACTION_NAMES.assemble,
      ACTION_NAMES.preprocess_assemble,
      ACTION_NAMES.c_compile,
      ACTION_NAMES.cc_flags_make_variable,
      ACTION_NAMES.cpp_link_executable,
      ACTION_NAMES.cpp_link_dynamic_library,
      ACTION_NAMES.cpp_link_nodeps_dynamic_library,
      ACTION_NAMES.cpp_compile,
      ACTION_NAMES.cpp_header_parsing,
    ],
    ctx.file.clang,
  )

  compiler_flags = feature(
    name = "compiler_flags",
    enabled = True,
    flag_sets = [
      flag_set(
        actions = [
          ACTION_NAMES.assemble,
          ACTION_NAMES.preprocess_assemble,
          ACTION_NAMES.linkstamp_compile,
          ACTION_NAMES.c_compile,
          ACTION_NAMES.cpp_compile,
          ACTION_NAMES.cpp_header_parsing,
          ACTION_NAMES.cpp_module_compile,
          ACTION_NAMES.cpp_module_codegen,
          ACTION_NAMES.lto_backend,
          ACTION_NAMES.clif_match,
        ],
        flag_groups = [
          flag_group(flags = [
            "--target=armv7m-none-eabi", "-mcpu=cortex-m4", "-mfpu=fpv4-sp-d16",
            "-mthumb", "-mfloat-abi=softfp", "-fno-exceptions", "-fno-rtti",
          ]),
        ],
      )
    ]
  )

  linker_flags = feature(
    name = "linker_flags",
    enabled = True,
    flag_sets = [
      flag_set(
        actions = [
          ACTION_NAMES.cpp_link_executable,
        ],
        flag_groups = [
          flag_group(flags = [
            "--target=armv7m-none-eabi", "-mcpu=cortex-m4", "-mfpu=fpv4-sp-d16",
            "-mthumb", "-mfloat-abi=softfp", "-fno-exceptions", "-fno-rtti",
            "-T", "picolibc.ld",
          ]),
        ],
      )
    ]
  )

  semihosting = feature(
    name = "semihosting",
    flag_sets = [
      flag_set(
        actions = [
          ACTION_NAMES.cpp_link_executable,
        ],
        flag_groups = [
          flag_group(flags = [
            "-lcrt0-semihost", "-lsemihost",
          ]),
        ],
      )
    ]
  )

  return cc_common.create_cc_toolchain_config_info(
    ctx = ctx,
    toolchain_identifier = "config_linux_aarch64_arm_none_eabi",
    host_system_name = "linux-aarch64",
    target_system_name = "armv7m-none-eabi",
    target_cpu = "cortex-m4",
    target_libc = "picolibc",
    compiler = "clang",
    abi_version = "11",
    abi_libc_version = "11",
    action_configs = action_configs,
    features = [
      compiler_flags,
      linker_flags,
    ],
  )


cc_arm_llvm_toolchain_config = rule(
  implementation = _cc_arm_llvm_toolchain_config_impl,
  attrs = {
    "clang": attr.label(mandatory = True, allow_single_file = True),
  },
  provides = [CcToolchainConfigInfo],
)


def _arm_llvm_toolchain_impl(repository_ctx):
  """Repository rule for ARM LLVM toolchains"""
  repository_ctx.download_and_extract(
    url='https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-18.1.3/LLVM-ET-Arm-18.1.3-Windows-x86_64.zip',
    sha256='3013dcf1dba425b644e64cb4311b9b7f6ff26df01ba1fcd943105d6bb2a6e68b',
  )
  pass

arm_llvm_toolchain = repository_rule(
  implementation = _arm_llvm_toolchain_impl,
)

def _arm_toolchain_impl(module_ctx):
  """Bzlmod extension for ARM LLVM toolchains"""
  arm_llvm_toolchain(
    name = "arm_none_eabi",
  )
  pass

arm_toolchain = module_extension(
  implementation = _arm_toolchain_impl,
)
