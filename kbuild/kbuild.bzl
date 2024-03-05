load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")


KbuildToolchainInfo = provider()


def detect_root(sources):
  """Detect the topmost root directory of a collection of sources.
  Implementation taken from rules_foreign_cc"""
  if len(sources) == 0:
    return ""

  root = None
  for file in sources:
    if root == None or root.startswith(file.dirname):
      root = file.dirname

  if not root:
    fail("No root source or directory was found")

  return root


def _kbuild_target_impl(ctx):
  """
  Creates an action that executes a kbuild configuration and installs some
  generated artifacts to the output directory.
  """
  toolchain = ctx.toolchains[":toolchain_type"]
  target_cc_toolchain = toolchain.target_cc_toolchain_info
  kbuild_toolchain_info = toolchain.kbuild_toolchain_info
  root_directory = detect_root(ctx.files.srcs)
  config = ctx.actions.declare_file(ctx.attr.name + ".cfg")

  inputs = ctx.files.srcs + ctx.files.additional_inputs \
      + target_cc_toolchain.all_files.to_list()

  outputs = [config]
  for name in ctx.attr.artifacts.values():
    outputs.append(ctx.actions.declare_file(name, sibling=config))

  args = ctx.actions.args()
  args.add("-C", root_directory)
  args.add(ctx.attr.defconfig)
  args.add(ctx.attr.all_target)

  feature_configuration = cc_common.configure_features(
    ctx = ctx,
    cc_toolchain = target_cc_toolchain,
  )

  env = {
    # Standard kbuild stuff
    'ARCH': ctx.attr.arch,
    'CROSS_COMPILE': ctx.attr.cross_compile,

    # Tools
    # TODO: This makes target toolchain hermetic, but not host toolchain.
    'AR': cc_common.get_tool_for_action(
      feature_configuration = feature_configuration,
      action_name = ACTION_NAMES.cpp_link_static_library,
    ),
    'CC': cc_common.get_tool_for_action(
      feature_configuration = feature_configuration,
      action_name = ACTION_NAMES.c_compile,
    ),
    'LD': kbuild_toolchain_info.ld.path,
    'NM': kbuild_toolchain_info.nm.path,
    'OBJCOPY': kbuild_toolchain_info.objcopy.path,
    'OBJDUMP': kbuild_toolchain_info.objdump.path,
    'STRIP': cc_common.get_tool_for_action(
      feature_configuration = feature_configuration,
      action_name = ACTION_NAMES.strip,
    ),

    # Instructions for kbuild.sh
    'NAME': ctx.attr.name,
    'OUT_DIR': config.dirname,
    'ARTIFACTS': ':'.join(ctx.attr.artifacts.keys()),
  }

  for key, value in ctx.attr.additional_config.items():
    env[key] = value
  env['CONFIG'] = ':'.join(ctx.attr.additional_config.keys())

  # TODO: Create a "kernel toolchain" that combines a "kbuild toolchain"
  # (itself combining a exec & target cc_toolchain, plus the tools to run
  # kbuild--make, etc.) plus the tools needed to compile the kernel--flex,
  # bison, bc, etc.
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
  fragments = ["cpp"],
  toolchains = [
    "@rules_cc//cc:toolchain_type",
    ":toolchain_type",
  ],
)
