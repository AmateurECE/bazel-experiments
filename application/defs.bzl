load("//kbuild:kbuild.bzl", "kbuild_target", "KbuildToolchainInfo")
load("//:common.bzl", "hermetic_tool_path")
load("@rules_cc//cc:defs.bzl", "cc_common")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")


def _linux_toolchain_impl(ctx):
  """Provide information about kernel build tools to the kbuild rules."""
  target_cc_toolchain = ctx.attr.target_cc_toolchain[cc_common.CcToolchainInfo]

  # Right now, the target toolchain is the only hermetic toolchain, so the
  # set of hermetic_tools is just the set of files in the target cc toolchain
  hermetic_tools = target_cc_toolchain.all_files.to_list()

  compiler = cc_common.get_tool_for_action(
    feature_configuration = cc_common.configure_features(
      ctx = ctx,
      cc_toolchain = target_cc_toolchain,
    ),
    action_name = ACTION_NAMES.c_compile,
  )

  # For hermetic GCC toolchains, all the tools should be listed in the same
  # directory as the compiler.
  tool_path = hermetic_tool_path([compiler])

  kbuild = KbuildToolchainInfo(
    hermetic_tool_path = tool_path,
    hermetic_tools = hermetic_tools,
  )
  return [platform_common.ToolchainInfo(
    kbuild_toolchain_info = kbuild,
  )]


linux_toolchain = rule(
  implementation = _linux_toolchain_impl,
  attrs = {
    "target_cc_toolchain": attr.label(providers=[cc_common.CcToolchainInfo]),
  },
  fragments = ["cpp"],
)


def kernel_build(name, arch, image, dtb, **kwargs):
  artifacts = {
    "arch/%s/boot/%s" % (arch, image): image,
    "arch/%s/boot/dts/%s" % (arch, dtb): dtb,
  }

  return kbuild_target(
    # Kbuild stuff
    name = name,
    arch = arch,

    # Kernel-specific stuff
    artifacts = artifacts,

    **kwargs,
  )


def uboot_build(name, image, dtb, **kwargs):
  artifacts = {
    image: image,
    "u-boot.dtb": "u-boot.dtb",
  }

  return kbuild_target(
    name = name,
    artifacts = artifacts,
    all_target = 'all',
    **kwargs,
  )
