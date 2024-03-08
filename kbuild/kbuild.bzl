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
  root_directory = detect_root(ctx.files.srcs)
  config = ctx.actions.declare_file(ctx.attr.name + ".cfg")

  inputs = ctx.files.srcs + ctx.files.additional_inputs \
      + toolchain.hermetic_tools

  outputs = [config]
  for name in ctx.attr.artifacts.values():
    outputs.append(ctx.actions.declare_file(name, sibling=config))

  args = ctx.actions.args()
  args.add("-C", root_directory)
  args.add(ctx.attr.defconfig)
  args.add(ctx.attr.all_target)

  env = {
    # Standard kbuild stuff
    'ARCH': ctx.attr.arch,
    'CROSS_COMPILE': ctx.attr.cross_compile,

    # Tools
    'HERMETIC_TOOL_PATH': ':'.join(toolchain.hermetic_tool_path),

    # Instructions for kbuild.sh
    'NAME': ctx.attr.name,
    'OUT_DIR': config.dirname,
    'ARTIFACTS': ':'.join(ctx.attr.artifacts.keys()),
  }

  for key, value in ctx.attr.additional_config.items():
    env[key] = value
  env['CONFIG'] = ':'.join(ctx.attr.additional_config.keys())

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
    'all_target': attr.string(),
    'arch': attr.string(),
    'cross_compile': attr.string(),

    # Attributes from the calling macro
    'artifacts': attr.string_dict(),
    'additional_inputs': attr.label_list(),
    'additional_config': attr.string_dict(),

    # Tools
    '_builder': attr.label(
      default = Label(':kbuild.sh'),
      cfg = "exec",
      executable = True,
      allow_files = True,
    ),
  },
  toolchains = [
    ":toolchain_type",
  ],
)
