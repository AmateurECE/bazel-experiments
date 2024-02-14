def _array(array):
  return ",".join(['"{}"'.format(a) for a in array])

def _glob_headers(array):
  # TODO: .hpp headers?
  return _array(["{}/**/*.h".format(a) for a in array])

def _conan_install(ctx, requires):
  conan = ctx.which("conan")
  if conan == None:
    fail("Unable to find conan. Is it installed?")

  command = [str(conan)] + ['install', '--requires={}'.format(requires), '-g', 'JsonDeps']
  result = ctx.execute(command)
  if result.return_code != 0:
    fail("Command '{}' failed: {}".format(" ".join(command), result.stderr))

  reference = requires.split("/")
  return json.decode(ctx.read(reference[0] + '.json'))

def _conan_package_impl(ctx):
  # NOTE: Can use absolute paths to profiles in conan commands.
  # How to get profiles from toolchain? Aspects?
  cpp_info = _conan_install(ctx, ctx.attr.requires)
  ctx.template(
    "BUILD",
    Label(":BUILD.template"),
    substitutions = {
      "%{name}": ctx.attr.name,
      "%{headers}": _glob_headers(cpp_info["includedirs"]),
      "%{includedirs}": _array(cpp_info["includedirs"]),
      "%{cflags}": _array(cpp_info["cflags"]),
      "%{cxxflags}": _array(cpp_info["cxxflags"]),
      "%{exelinkflags}": _array(cpp_info["exelinkflags"]),
      "%{sharedlinkflags}": _array(cpp_info["sharedlinkflags"]),
      "%{libdirs}": _array(cpp_info["libdirs"]),
    },
    executable = False,
  )

conan_package = repository_rule(
  implementation = _conan_package_impl,
  local = True,
  attrs = {
    "requires": attr.string(mandatory=True)
  }
)

def _conan_extension_impl(module_ctx):
  # TODO: Do we need to implement Bazel dependency resolution rules here?
  # Perhaps only for duplicated transitive dependencies where
  # options.shared=True?
  for mod in module_ctx.modules:
    for data in mod.tags.install:
      conan_package(
        name="conan",
        requires=data.requires,
      )

install = tag_class(attrs={"requires": attr.string(mandatory=True)})
conan = module_extension(
  implementation = _conan_extension_impl,
  tag_classes = {"install": install},
)
