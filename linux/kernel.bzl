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
  name = "linux"
  config = ctx.actions.declare_file(name + ".cfg")
  image = ctx.actions.declare_file(ctx.attr.image, sibling=config)
  dtb = ctx.actions.declare_file(ctx.attr.dtb, sibling=config)
  artifacts = [
    "arch/%s/boot/%s" % (ctx.attr.arch, ctx.attr.image),
    "arch/%s/boot/dts/%s" % (ctx.attr.arch, ctx.attr.dtb),
  ]
  outputs = [config, image, dtb]

  inputs = ctx.files.srcs + [ctx.file.initramfs] \
      + toolchain.all_files.to_list()

  args = ctx.actions.args()
  args.add("-C", root_directory)
  args.add(ctx.attr.defconfig)

  # TODO: Create a "kernel toolchain" that combines a "kbuild toolchain"
  # (itself combining a exec & target cc_toolchain, plus the tools to run
  # kbuild--make, etc.) plus the tools needed to compile the kernel--flex,
  # bison, bc, etc.
  ctx.actions.run(
    mnemonic = name + "Kbuild",
    executable = ctx.executable._builder,
    arguments = [args],
    inputs = inputs,
    outputs = outputs,
    use_default_shell_env = True,
    env = {
      # Standard kbuild stuff
      'ARCH': ctx.attr.arch,
      'CROSS_COMPILE': ctx.attr.cross_compile,

      # Tools
      # TODO: This makes target toolchain hermetic, but not host toolchain.
      'AR': toolchain.ar_executable,
      'CC': toolchain.compiler_executable,
      'LD': toolchain.ld_executable,
      'NM': toolchain.nm_executable,
      'OBJCOPY': toolchain.objcopy_executable,
      'OBJDUMP': toolchain.objdump_executable,
      'STRIP': toolchain.strip_executable,

      # Instructions for kbuild.sh
      'NAME': 'linux',
      'OUT_DIR': config.dirname,
      'ARTIFACTS': ':'.join(artifacts),
      'CONFIG': 'CONFIG_INITRAMFS_SOURCE',
      'CONFIG_INITRAMFS_SOURCE': '"%s"' % (ctx.file.initramfs.path),
    },
  )

  return [
    DefaultInfo(files = depset(outputs)),
  ]


kernel_build = rule(
  implementation = _kernel_build_impl,
  attrs = {
    'srcs': attr.label_list(allow_files = True),
    'defconfig': attr.string(mandatory = True),
    'arch': attr.string(),
    'cross_compile': attr.string(),
    'image': attr.string(mandatory = True),
    'dtb': attr.string(mandatory = True),
    'initramfs': attr.label(allow_single_file = [".cpio"], mandatory = True),
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
