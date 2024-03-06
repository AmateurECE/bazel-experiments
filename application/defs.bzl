load("//kbuild:kbuild.bzl", "kbuild_target", "KbuildToolchainInfo")
load("@rules_cc//cc:defs.bzl", "cc_common")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_skylib//lib:paths.bzl", "paths")


def _hermetic_tool_path(tools):
  """Creates a colon-separated list of path components that can be used to 
  extend the path. The kbuild script will convert these to absolute paths and
  augment the PATH environment variable."""
  tool_path = []
  for tool in tools:
    dirname = paths.dirname(tool)
    if dirname not in tool_path:
      tool_path.append(dirname)
  return tool_path


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
  hermetic_tool_path = _hermetic_tool_path([compiler])

  kbuild = KbuildToolchainInfo(
    hermetic_tool_path = hermetic_tool_path,
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


def _single_app_cpio_initrd_impl(ctx):
  """Create a cpio archive with a single application (init) to run under the
  kernel. Automatically populates libc in the archive, if the application
  links to one, but currently cannot automatically populate other kinds of
  dependencies."""
  archive = ctx.actions.declare_file("initrd.cpio")

  args = ctx.actions.args()
  args.add("-o", "builddir")
  args.add("-f", archive.path)
  args.add_all(ctx.files.init)

  ctx.actions.run(
    mnemonic = "WriteInitrd",
    progress_message = 'Writing %s'.format(archive.path),
    executable = ctx.executable._builder.path,
    arguments = [args],
    outputs = [archive],
    inputs = ctx.files.init + [ctx.executable._builder],
    use_default_shell_env = True,
  )

  return [DefaultInfo(files = depset([archive]))]


single_app_cpio_initrd = rule(
  implementation = _single_app_cpio_initrd_impl,
  attrs = {
    'init': attr.label(),
    '_builder': attr.label(
      default = Label(":initrd-builder.sh"),
      cfg = "exec",
      executable = True,
      allow_files = True,
    ),
  },
)
