# Alternative is to set visibility = ["//main:__pkg__"] for library target,
# see: https://github.com/bazelbuild/examples/blob/main/cpp-tutorial/stage3/lib/BUILD
package(default_visibility = ["//visibility:public"])

cc_library(
  name = "stm32g4-polyfill",
  srcs = [
    "syscalls.c",
    "sysmem.c",
  ],

  # Causes bazel to always link this library, and wrap it in
  # -Wl,--whole-archive, which is needed to prevent symbol resolution errors
  # related to link order (since this library implements some C standard
  # library functions). See:
  # https://bazel.build/reference/be/c-cpp#cc_library
  alwayslink = True,
)
