load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("//:common.bzl", "detect_root", "hermetic_tool_path")


def _make_impl(ctx):
  """Build software that uses the GNUMake build system and install some
  artifacts to the output folder."""
  toolchain = find_cc_toolchain(ctx)

  inputs = ctx.files.srcs + toolchain.all_files.to_list() \
      + [ctx.executable._builder]

  outputs = []
  for output in ctx.attr.outputs:
    outputs.append(ctx.actions.declare_file(paths.basename(output)))

  source = detect_root(ctx.files.srcs)

  args = ctx.actions.args()
  args.add("-C", source)
  args.add(ctx.attr.target)

  compiler = cc_common.get_tool_for_action(
    feature_configuration = cc_common.configure_features(
      ctx = ctx,
      cc_toolchain = toolchain,
    ),
    action_name = ACTION_NAMES.c_compile,
  )

  actual_output_paths = []
  for output in ctx.attr.outputs:
    actual_output_paths.append(source + "/" + output)

  env = {
    'HERMETIC_TOOL_PATH': ':'.join(hermetic_tool_path([compiler])),
    'INSTALL_ARTIFACTS': ':'.join(actual_output_paths),
    'OUT_DIR': outputs[0].dirname,
  }

  ctx.actions.run(
    executable = ctx.executable._builder.path,
    arguments = [args],
    outputs = outputs,
    inputs = inputs,
    env = env | ctx.attr.env,
    use_default_shell_env = True,
  )

  return [DefaultInfo(files = depset(outputs))]


make = rule(
  implementation = _make_impl,
  attrs = {
    'target': attr.string(),
    'srcs': attr.label_list(allow_files = True),
    'env': attr.string_dict(),
    'outputs': attr.string_list(),

    '_builder': attr.label(
      default = Label(":make.sh"),
      cfg = "exec",
      executable = True,
      allow_files = True,
    ),
  },
  fragments = ["cpp"],
  toolchains = [
    "@rules_cc//cc:toolchain_type",
  ],
)
