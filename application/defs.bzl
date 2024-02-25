load("//kbuild:kbuild.bzl", "kbuild_target")


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
