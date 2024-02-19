load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")


_BUILD_SOURCES = """
filegroup(
  name = "sources",
  srcs = glob([\"**\"]),
  visibility = ["//visibility:public"],
)
"""


def _sources_impl(module_ctx):
  module_ctx.file('BUILD.bazel', executable=False)
  for mod in module_ctx.modules:
    for archive in mod.tags.archive:
      http_archive(
        build_file_content = _BUILD_SOURCES,
        name = archive.name,
        url = archive.url,
        sha256 = archive.sha256,
        strip_prefix = archive.strip_prefix,
      )


archive = tag_class(
  attrs = {
    'name': attr.string(),
    'url': attr.string(),
    'sha256': attr.string(),
    'strip_prefix': attr.string(),
  },
)


sources = module_extension(
  implementation = _sources_impl,
  tag_classes = {
    'archive': archive,
  },
)
