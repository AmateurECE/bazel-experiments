load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("//:common.bzl", "detect_root", "hermetic_tool_path")


def _make_common_action(ctx, targets, built_artifacts, rule_outputs):
  toolchain = find_cc_toolchain(ctx)

  inputs = ctx.files.srcs + toolchain.all_files.to_list() \
      + [ctx.executable._builder]

  source = detect_root(ctx.files.srcs)

  compiler = cc_common.get_tool_for_action(
    feature_configuration = cc_common.configure_features(
      ctx = ctx,
      cc_toolchain = toolchain,
    ),
    action_name = ACTION_NAMES.c_compile,
  )

  env = {
    'HERMETIC_TOOL_PATH': ':'.join(hermetic_tool_path([compiler])),
    'INSTALL_ARTIFACTS': ':'.join(built_artifacts),
    'MAKE_TARGETS': ':'.join(targets),
    'OUT_DIR': rule_outputs[0].dirname,
    'BUILDDIR_VARIABLE': ctx.attr.builddir_variable,
    'SRC_DIR': source,
  }

  ctx.actions.run(
    executable = ctx.executable._builder.path,
    arguments = ctx.attr.args,
    outputs = rule_outputs,
    inputs = inputs,
    env = env | ctx.attr.env,
    use_default_shell_env = True,
  )


_MAKE_COMMON_ATTRS = {
    'srcs': attr.label_list(allow_files = True),
    'env': attr.string_dict(),
    'builddir_variable': attr.string(),
    'args': attr.string_list(),

    '_builder': attr.label(
      default = Label(":make.sh"),
      cfg = "exec",
      executable = True,
      allow_files = True,
    ),
}


def _make_impl(ctx):
  """Build software that uses the GNUMake build system and install some
  artifacts to the output folder."""
  outputs = []
  for output in ctx.attr.outputs:
    outputs.append(ctx.actions.declare_file(paths.basename(output)))

  _make_common_action(ctx, ctx.attr.targets, ctx.attr.outputs, outputs)
  return [DefaultInfo(files = depset(outputs))]


make = rule(
  implementation = _make_impl,
  attrs = {
    'targets': attr.string_list(),
    'outputs': attr.string_list(),
  } | _MAKE_COMMON_ATTRS,
  fragments = ["cpp"],
  toolchains = [
    "@rules_cc//cc:toolchain_type",
  ],
)

def _make_binary_impl(ctx):
  """Build an executable binary that uses the GNUMake build system"""
  executable = ctx.actions.declare_file(paths.basename(ctx.attr.executable))
  _make_common_action(ctx, [ctx.attr.target], [ctx.attr.executable],
      [executable])
  return [DefaultInfo(executable = executable)]

make_binary = rule(
  implementation = _make_binary_impl,
  attrs = {
    'target': attr.string(),
    'executable': attr.string(),
  } | _MAKE_COMMON_ATTRS,
  fragments = ["cpp"],
  toolchains = [
    "@rules_cc//cc:toolchain_type",
  ],
)

