def _array(array):
  return ",".join(['"{}"'.format(a) for a in array])

def _glob_headers(array):
  # TODO: .hpp headers?
  return _array(["{}/**/*.h".format(a) for a in array])

def _conan(repository_ctx, args):
  conan = repository_ctx.which("conan")
  if conan == None:
    fail("Unable to find conan. Is it installed?")

  environment = {
    'CONAN_HOME': str(repository_ctx.path(".conan")),
  }

  command = [str(conan)] + args
  result = repository_ctx.execute(command, environment=environment)
  if result.return_code != 0:
    fail("Command '{}' failed: {}".format(" ".join(command), result.stderr))

def _conan_config_install(repository_ctx, config):
  _conan(repository_ctx, ['config', 'install', config])

def _conan_install(repository_ctx, requires):
  _conan(
    repository_ctx,
    ['install', '--requires={}'.format(requires), '-g', 'JsonDeps'],
  )
  reference = requires.split("/")
  return json.decode(repository_ctx.read(reference[0] + '.json'))

def _write_build(repository_ctx, cpp_info):
  repository_ctx.template(
    "BUILD",
    Label(":BUILD.template"),
    substitutions = {
      "%{name}": repository_ctx.attr.name,
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

def _conan_cache_impl(repository_ctx):
  # NOTE: Can use absolute paths to profiles in conan commands.
  # How to get profiles from toolchain? Aspects?
  if repository_ctx.attr.config:
    location = repository_ctx.attr.config
    if not location.startswith("/"):
      location = str(repository_ctx.workspace_root) + "/" + location
    _conan_config_install(repository_ctx, location)

  for package in repository_ctx.attr.requires:
    cpp_info = _conan_install(repository_ctx, package)
    _write_build(repository_ctx, cpp_info)

conan_cache = repository_rule(
  implementation = _conan_cache_impl,
  local = True,
  attrs = {
    "config": attr.string(),
    "requires": attr.string_list(mandatory=True)
  }
)

def _conan_extension_impl(module_ctx):
  # TODO: Do we need to implement Bazel dependency resolution rules here?
  # Perhaps only for duplicated transitive dependencies where
  # options.shared=True?
  for mod in module_ctx.modules:
    requires = [p.requires for p in mod.tags.install]

    if mod.tags.config:
      config = mod.tags.config[len(mod.tags.config) - 1].install_from
    else:
      config = None

    # TODO: Does this create multiple repositories with the same name? Is that
    # allowed?
    conan_cache(
      name="conan",
      requires=requires,
      config=config,
    )

install = tag_class(attrs={"requires": attr.string(mandatory=True)})
config = tag_class(attrs={"install_from": attr.string()})
conan = module_extension(
  implementation = _conan_extension_impl,
  tag_classes = {
    "install": install,
    "config": config,
  },
)
