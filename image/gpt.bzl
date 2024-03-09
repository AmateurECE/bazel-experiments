def _gpt_image_impl(ctx):
  """Generate a GPT disk image from the inputs"""
  image = ctx.actions.declare_file(ctx.attr.name + ".img")

  inputs = [ctx.executable._builder, ctx.file.first_stage_bootloader, \
      ctx.file.second_stage_bootloader] + ctx.files.rootfs

  args = ctx.actions.args()
  args.add("-f", ctx.file.first_stage_bootloader.path)
  args.add("-s", ctx.file.second_stage_bootloader.path)
  args.add("-o", image.path)
  args.add_all(ctx.files.rootfs)

  ctx.actions.run(
    inputs = inputs,
    outputs = [image],
    executable = ctx.executable._builder.path,
    arguments = [args],
    use_default_shell_env = True,
  )

  return DefaultInfo(files = depset([image]))


gpt_image = rule(
  implementation = _gpt_image_impl,
  attrs = {
    'first_stage_bootloader': attr.label(allow_single_file=True),
    'second_stage_bootloader': attr.label(allow_single_file=True),
    'rootfs': attr.label_list(),

    '_builder': attr.label(
      default = Label(':mkgpt.sh'),
      cfg = "exec",
      executable = True,
      allow_files = True,
    ),
  },
)
