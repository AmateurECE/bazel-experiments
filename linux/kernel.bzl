# TODO: Use rules_cc?
# load("@rules_cc//cc:defs.bzl", "cc_common")

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


KbuildInfo = provider()


def _kernel_configuration_impl(ctx):
  # TODO: Get information from CcToolchain* providers to configure Kbuild?
  root_directory = detect_root(ctx.files.srcs)
  config = ctx.actions.declare_file(".config")
  builder = ctx.actions.declare_file("run-kbuild.sh")

  arguments = ctx.actions.args()
  arguments.add(ctx.bin_dir.path)
  arguments.add("-C", root_directory)
  arguments.add("defconfig")

  ctx.actions.write(
    output = builder,
    content=(
      "#!/bin/sh\n" +
      "set -x\n" +
      "OUTPUT_DIR=$1; shift;\n" +
      "make O=$PWD/$OUTPUT_DIR $@\n"
    ),
    is_executable = True,
  )

  kbuild_info = KbuildInfo(
    root_directory = root_directory,
    srcs = ctx.files.srcs,
    builder = builder,
  )

  # TODO: Non-hermetic rule. Uses system GNUMake and default shell env
  ctx.actions.run(
    executable = builder,
    arguments = [arguments],
    inputs = ctx.files.srcs,
    outputs = [config],
    use_default_shell_env = True,
  )

  return [
    DefaultInfo(files = depset([config])),
    kbuild_info,
  ]


kernel_configuration = rule(
  implementation = _kernel_configuration_impl,
  attrs = {
    'srcs': attr.label_list(allow_files = True),
  },
  toolchains = ["@rules_cc//cc:toolchain_type"],
)


def _kernel_headers_impl(ctx):
  """Provides the set of kernel headers to dependents."""
  root_directory = ctx.attr.cfg[KbuildInfo].root_directory
  header_install_directory = ctx.actions.declare_directory("include")

  arguments = ctx.actions.args()
  arguments.add(ctx.bin_dir.path)
  arguments.add("-C", root_directory)
  arguments.add("INSTALL_HDR_PATH=" + header_install_directory.path)
  arguments.add("headers_install")

  # TODO: Non-hermetic rule. Uses system GNUMake and default shell env
  ctx.actions.run(
    executable = ctx.attr.cfg[KbuildInfo].builder,
    arguments = [arguments],
    inputs = ctx.files.cfg + ctx.attr.cfg[KbuildInfo].srcs,
    outputs = [header_install_directory],
    use_default_shell_env = True,
  )

  return [
    DefaultInfo(files = depset([header_install_directory])),
    CcInfo(
      compilation_context = cc_common.create_compilation_context(
        system_includes = depset([header_install_directory.path]),
      )
    )
  ]


kernel_headers = rule(
  implementation = _kernel_headers_impl,
  attrs = {
    'cfg': attr.label(),
  },
  toolchains = ["@rules_cc//cc:toolchain_type"],
)


def _single_app_cpio_initrd_impl(ctx):
  """Create a cpio archive with a single application (init) to run under the
  kernel. Automatically populates libc in the archive, if the application
  links to one, but currently cannot automatically populate other kinds of
  dependencies."""
  archive = ctx.actions.declare_file("initrd.cpio.gz")

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
