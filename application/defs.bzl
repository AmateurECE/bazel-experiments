load("//kbuild:kbuild.bzl", "kbuild_target", "KbuildToolchainInfo")
load("@rules_cc//cc:defs.bzl", "cc_common")


def _linux_toolchain_impl(ctx):
  """Provide information about kernel build tools to the kbuild rules."""
  target = ctx.attr.target_cc_toolchain[cc_common.CcToolchainInfo]
  kbuild = KbuildToolchainInfo(
    ld = ctx.file.ld,
    nm = ctx.file.nm,
    objcopy = ctx.file.objcopy,
    objdump = ctx.file.objdump,
  )
  toolchain_info = platform_common.ToolchainInfo(
    target_cc_toolchain_info = target,
    kbuild_toolchain_info = kbuild,
  )
  return [toolchain_info]


linux_toolchain = rule(
  implementation = _linux_toolchain_impl,
  attrs = {
    "target_cc_toolchain": attr.label(providers=[cc_common.CcToolchainInfo]),
    "ld": attr.label(allow_single_file = True),
    "nm": attr.label(allow_single_file = True),
    "objcopy": attr.label(allow_single_file = True),
    "objdump": attr.label(allow_single_file = True),
  },
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
