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


def _kernel_source_archive_impl(repository_ctx):
  repository_ctx.download_and_extract(
    url='https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.7.4.tar.xz',
    sha256='f68d9f5ffc0a24f850699b86c8aea8b8687de7384158d5ed3bede37de098d60c',
    stripPrefix='linux-6.7.4',
  )
  repository_ctx.file("BUILD.bazel", content=(
    "filegroup(\n" +
    "    name = \"sources\",\n" +
    "    srcs = glob([\"**\"]),\n" +
    "    visibility = [\"//visibility:public\"],\n" +
    ")\n"
  ), executable=False)
  repository_ctx.file("run-kbuild.sh", content=(
    "#!/bin/sh\n" +
    "set -x\n" +
    "OUTPUT_DIR=$1; shift;\n" +
    "make O=$PWD/$OUTPUT_DIR $@\n"
  ))


kernel_source_archive = repository_rule(
  implementation = _kernel_source_archive_impl,
)


def _kernel_source_impl(module_ctx):
  kernel_source_archive(name = "linux")


kernel_source = module_extension(
  implementation = _kernel_source_impl,
)


KbuildInfo = provider()


def _kernel_impl(ctx):
  # TODO: Get information from CcToolchain* providers to configure Kbuild?
  root_directory = detect_root(ctx.files.srcs)
  kbuild_info = KbuildInfo(
    root_directory = root_directory,
  )

  config = ctx.actions.declare_file(".config")

  arguments = ctx.actions.args()
  arguments.add(config.dirname)
  arguments.add("-C", root_directory)
  arguments.add("defconfig")

  # TODO: Non-hermetic rule. Uses system GNUMake and default shell env
  ctx.actions.run(
    executable = root_directory + "/run-kbuild.sh",
    arguments = [arguments],
    inputs = ctx.files.srcs,
    outputs = [config],
    use_default_shell_env = True,
  )
  return [
    DefaultInfo(files = depset([config])),
    kbuild_info,
  ]


kernel = rule(
  implementation = _kernel_impl,
  attrs = {
    'srcs': attr.label_list(allow_files = True),
  },
  toolchains = ["@rules_cc//cc:toolchain_type"],
)
