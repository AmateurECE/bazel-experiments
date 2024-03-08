load("@bazel_skylib//lib:paths.bzl", "paths")


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


def hermetic_tool_path(tools):
  """Creates a colon-separated list of path components that can be used to 
  extend the path. The kbuild script will convert these to absolute paths and
  augment the PATH environment variable."""
  tool_path = []
  for tool in tools:
    dirname = paths.dirname(tool)
    if dirname not in tool_path:
      tool_path.append(dirname)
  return tool_path
