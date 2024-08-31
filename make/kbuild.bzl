load("//:common.bzl", "detect_root")


KbuildToolchainInfo = provider(
  fields = {
    'hermetic_tool_path': 'List of paths to augment the PATH environment variable',
    'hermetic_tools': 'List of files to add as inputs to kbuild actions',
  }
)


def _kbuild_target_impl(ctx):
  """
  Creates an action that executes a kbuild configuration and installs some
  generated artifacts to the output directory.
  """
  toolchain = ctx.toolchains[":toolchain_type"].kbuild_toolchain_info
  source = detect_root(ctx.files.srcs)
  inputs = ctx.files.srcs + toolchain.hermetic_tools

  outputs = [ctx.actions.declare_file(name) for name in ctx.attr.artifacts.values()]

  args = ctx.actions.args()
  args.add('ARCH={}'.format(ctx.attr.arch))
  args.add('CROSS_COMPILE={}'.format(ctx.attr.cross_compile))

  env = {
    'HERMETIC_TOOL_PATH': ':'.join(toolchain.hermetic_tool_path),
    'INSTALL_ARTIFACTS': ':'.join(ctx.attr.artifacts.keys()),
    # NOTE: Add an extra ":" at the end. This is needed when all_target is ""
    'MAKE_TARGETS': ':'.join([ctx.attr.defconfig, ctx.attr.all_target]) + ":",
    'OUT_DIR': outputs[0].dirname,
    'BUILDDIR_VARIABLE': 'O',
    'SRC_DIR': source,
  }

  ctx.actions.run(
    mnemonic = ctx.attr.name + "Kbuild",
    executable = ctx.executable._builder,
    arguments = [args],
    inputs = inputs,
    outputs = outputs,
    # TODO: Remove this, perhaps?
    use_default_shell_env = True,
    env = env,
  )

  return [
    DefaultInfo(files = depset(outputs)),
  ]


kbuild_target = rule(
  implementation = _kbuild_target_impl,
  attrs = {
    # Standard kbuild parameters
    'srcs': attr.label_list(allow_files = True),
    'defconfig': attr.string(mandatory = True),
    'all_target': attr.string(default = ""),
    'arch': attr.string(),
    'cross_compile': attr.string(),

    # Attributes from the calling macro
    'artifacts': attr.string_dict(),

    # Tools
    '_builder': attr.label(
      default = Label(':make.sh'),
      cfg = "exec",
      executable = True,
      allow_files = True,
    ),
  },
  toolchains = [
    ":toolchain_type",
  ],
)
