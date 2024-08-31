def _genimage_impl(ctx):
  """Rule to generate an image from some inputs."""
  template = ctx.actions.declare_file("genimage.cfg.template")
  ctx.actions.write(template, ctx.attr.configuration)

  # TODO: Error here if any of the deps contain more than one file.

  substitutions = { v:k[DefaultInfo].files.to_list()[0].path for k,v in ctx.attr.deps.items() }
  configuration = ctx.actions.declare_file("genimage.cfg")
  ctx.actions.expand_template(template=template, output=configuration, substitutions=substitutions)

  deps = [k[DefaultInfo].files.to_list()[0] for k in ctx.attr.deps.keys()]
  image = ctx.actions.declare_file(ctx.attr.name)

  arguments = ctx.actions.args()
  arguments.add("--inputpath", ".")
  arguments.add("--config", configuration.path)
  arguments.add("--outputpath", image.dirname)

  ctx.actions.run(
    outputs = [image],
    inputs = deps + [configuration],
    executable = ctx.executable._genimage,
    arguments = [arguments],
  )
  return [DefaultInfo(files = depset([image]))]

genimage = rule(
  implementation = _genimage_impl,
  attrs = {
    "configuration": attr.string(mandatory = True),
    "deps": attr.label_keyed_string_dict(allow_files = True, mandatory = True),
    "_genimage": attr.label(
      default = Label("@rules_genimage//:bin/genimage"),
      cfg = "exec",
      executable = True,
      allow_single_file = True,
    ),
  },
)

def _make_partition(name, data, placeholders):
  """Make a partition fragment for a genimage configuration file."""
  partition  = "  partition {} {{\n".format(name)
  for attribute, value in data.items():
    if attribute == "image":
      value = "\"{}\"".format(placeholders[value])
    partition += "    {} = {}\n".format(attribute, value)
  partition += "  }"
  return partition

def _filter_images(partitions):
  """Returns a list of the images referenced in this configuration."""
  images = []
  for partition in partitions.values():
    if 'image' in partition:
      images.append(partition['image'])
  return images

def hdimage(name, partition_table_type, **kwargs):
  """Macro to define a rule that builds an hdimage from the provided data."""
  configuration  = "image {} {{\n".format(name)
  configuration += "  hdimage {\n"
  configuration += "    partition-table-type = \"{}\"\n".format(partition_table_type)
  configuration += "  }\n"

  images = _filter_images(kwargs)
  placeholders = ["%{}%".format(i) for i in list(range(len(images), 0, -1))]
  deps = dict(zip(images, placeholders))
  configuration += "\n".join([_make_partition(k, v, deps) for k, v in kwargs.items()]) + "\n"

  configuration += "}\n"

  genimage(
    name = name,
    configuration = configuration,
    deps = deps,
  )
