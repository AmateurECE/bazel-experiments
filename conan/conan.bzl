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
  # Install our custom generator and deployer.
  repository_ctx.template(
    ".conan/extensions/generators/bzlmod_generator.py",
    Label(":bzlmod_generator.py"),
    executable=False,
  )
  repository_ctx.template(
    ".conan/extensions/deployers/bzlmod_deployer.py",
    Label(":bzlmod_deployer.py"),
    executable=False,
  )

def _conan_install(repository_ctx, requires, profile):
  _conan(
    repository_ctx,
    [
      'install', '--requires={}'.format(requires),
      '-g', 'Bzlmod', '-d', 'bzlmod_deployer',
      '-pr:b=default', '-pr:h={}'.format(profile),
    ],
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
    _conan_install(repository_ctx, package, repository_ctx.attr.profile)

  repository_ctx.file('BUILD.bazel', executable=False)

conan_cache = repository_rule(
  implementation = _conan_cache_impl,
  local = True,
  attrs = {
    "config": attr.string(),
    "requires": attr.string_list(mandatory=True),
    "profile": attr.string(),
  }
)

def _conan_extension_impl(module_ctx):
  # TODO: Do we need to implement Bazel dependency resolution rules here?
  # Perhaps only for duplicated transitive dependencies where
  # options.shared=True?
  for mod in module_ctx.modules:
    requires = [p.requires for p in mod.tags.install]
    profile = [p.profile for p in mod.tags.install]

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
      profile=profile[0],
    )

install = tag_class(
  attrs={
    "requires": attr.string(mandatory=True),
    "profile": attr.string(default="default")
  }
)
config = tag_class(attrs={"install_from": attr.string()})
conan = module_extension(
  implementation = _conan_extension_impl,
  tag_classes = {
    "install": install,
    "config": config,
  },
)
