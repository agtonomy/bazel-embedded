load("//devices/arm:cortex_m.bzl", "CORTEX_M_DEVICE_CONFIGS")

package(default_visibility = ["//visibility:public"])

# The toolchain() targets for //toolchains/gcc_arm_none_eabi. Bazel loads the package of every registered toolchain()
# while resolving toolchains. This package loads nothing from the compiler repository, so only a selected toolchain
# triggers the compiler download.
[toolchain(
    name = "cc-toolchain-{}-{}".format(
        cfg.cpu,
        cfg.fpu,
    ),
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//cpu:" + cfg.cpu,
        "//constraints/fpu:" + cfg.fpu,
    ],
    toolchain = "@gcc_arm_none_eabi_compiler//:arm_none_eabi_{}_{}".format(
        cfg.cpu,
        cfg.fpu,
    ),
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
) for cfg in CORTEX_M_DEVICE_CONFIGS]
