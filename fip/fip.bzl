def _fip_impl(ctx):
  """Build a FIP binary from a number of images"""
  image = ctx.actions.declare_file("fip.bin")

  args = ctx.actions.args()
  args.add("create")
  args.add("--tos-fw", ctx.file.tos_fw)
  args.add("--tos-fw-extra1", ctx.file.tos_fw_extra1)
  args.add("--tos-fw-extra2", ctx.file.tos_fw_extra2)
  args.add("--nt-fw", ctx.file.nt_fw)
  args.add("--fw-config", ctx.file.fw_config)
  args.add("--hw-config", ctx.file.hw_config)
  args.add(image.path)

  ctx.actions.run(
    executable = ctx.file._fiptool,
    arguments = [args],
    outputs = [image],
    inputs = [
      ctx.file.tos_fw,
      ctx.file.tos_fw_extra1,
      ctx.file.tos_fw_extra2,
      ctx.file.nt_fw,
      ctx.file.fw_config,
      ctx.file.hw_config,
      ctx.file._fiptool,
    ]
  )

  return [DefaultInfo(files = depset([image]))]

fip = rule(
  implementation = _fip_impl,
  attrs = {
    "tos_fw": attr.label(allow_single_file = True, mandatory = True),
    "tos_fw_extra1": attr.label(allow_single_file = True, mandatory = True),
    "tos_fw_extra2": attr.label(allow_single_file = True, mandatory = True),
    "nt_fw": attr.label(allow_single_file = True, mandatory = True),
    "fw_config": attr.label(allow_single_file = True, mandatory = True),
    "hw_config": attr.label(allow_single_file = True, mandatory = True),
    "_fiptool": attr.label(
      default = Label(":fiptool"),
      cfg = "exec",
      executable = True,
      allow_single_file = True,
    ),
  },
)
