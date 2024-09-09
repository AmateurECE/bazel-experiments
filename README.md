# Building

```
$ python3 -m venv .venv
$ pip install -r requirements.txt
$ (cd toolchains && curl -LO https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-18.1.3/LLVM-ET-Arm-18.1.3-Linux-AArch64.tar.xz && tar xvf LLVM-ET-Arm-18.1.3-Linux-AArch64.tar.xz)
$ bazelisk build //board:sdcard.img //rust:panic
```
```
```
