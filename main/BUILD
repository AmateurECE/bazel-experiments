cc_binary(
  name = "hello-world",
  srcs = [
    "hello-world.cpp",
  ],
  linkopts = ["-T", "$(location :STM32G474RETX_FLASH.ld)"],
  deps = [
    "//libc:stm32g4-polyfill",
    ":STM32G474RETX_FLASH.ld",
  ],
)
