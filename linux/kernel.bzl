load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")

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


def _kernel_build_impl(ctx):
  toolchain = find_cc_toolchain(ctx)
  root_directory = detect_root(ctx.files.srcs)
  config = ctx.actions.declare_file(".config")
  image = ctx.actions.declare_file(ctx.attr.image, sibling=config)
  dtb = ctx.actions.declare_file(ctx.attr.dtb, sibling=config)
  outputs = [config, image, dtb]

  args = ctx.actions.args()
  args.add("-C", root_directory)
  args.add(ctx.attr.defconfig)

  ctx.actions.run(
    mnemonic = "BuildKernel",
    executable = ctx.executable._builder,
    arguments = [args],
    inputs = ctx.files.srcs + toolchain.all_files.to_list(),
    outputs = outputs,
    use_default_shell_env = True,
    env = {
      'ARCH': ctx.attr.arch,
      'CROSS_COMPILE': ctx.attr.cross_compile,
      'AR': toolchain.ar_executable,
      'CC': toolchain.compiler_executable,
      'LD': toolchain.ld_executable,
      'NM': toolchain.nm_executable,
      'OBJCOPY': toolchain.objcopy_executable,
      'OBJDUMP': toolchain.objdump_executable,
      'STRIP': toolchain.strip_executable,
      'OUT_DIR': config.dirname,
      'IMAGE': ctx.attr.image,
      'DTB': ctx.attr.dtb,
      'INITRAMFS_SOURCE': ctx.files.initramfs[0].path,
    },
  )

  return [
    DefaultInfo(files = depset(outputs)),
  ]


kernel_build = rule(
  implementation = _kernel_build_impl,
  attrs = {
    'srcs': attr.label_list(allow_files = True),
    'defconfig': attr.string(),
    'arch': attr.string(),
    'cross_compile': attr.string(),
    'image': attr.string(),
    'dtb': attr.string(),
    'initramfs': attr.label(),
    '_builder': attr.label(
      default = Label(':kbuild.sh'),
      cfg = "exec",
      executable = True,
      allow_files = True,
    ),
  },
  toolchains = ["@rules_cc//cc:toolchain_type"],
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
