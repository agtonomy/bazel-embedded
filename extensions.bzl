"""Module extension creating the repositories that the toolchains and tools load from."""

load("//toolchains/compilers/gcc_arm_none_eabi:gcc_arm_none_repository.bzl", "gcc_arm_none_repository")
load("//toolchains/compilers/gcc_arm_none_eabi/impl:gcc_arm_none_versions.bzl", "TOOLCHAIN_VERSIONS")
load("//toolchains/upstream:toolchain_upstream_deps.bzl", "toolchain_upstream_repository")
load("//tools/openocd:openocd_repository.bzl", "openocd_repository")

def _bazel_embedded_impl(module_ctx):
    gcc_arm_none_args = {}
    for module in module_ctx.modules:
        if not module.is_root:
            continue
        for tag in module.tags.gcc_arm_none:
            gcc_arm_none_args["version"] = tag.version

    toolchain_upstream_repository(name = "bazel_embedded_upstream_toolchain")
    gcc_arm_none_repository(name = "gcc_arm_none_eabi_compiler", **gcc_arm_none_args)
    openocd_repository(name = "com_openocd")

_gcc_arm_none = tag_class(
    attrs = {
        "version": attr.string(
            doc = "The gcc-arm-none-eabi release to download.",
            mandatory = True,
            values = TOOLCHAIN_VERSIONS.keys(),
        ),
    },
    doc = "Configures the gcc-arm-none-eabi compiler. Only tags in the root module are used.",
)

bazel_embedded = module_extension(
    implementation = _bazel_embedded_impl,
    tag_classes = {"gcc_arm_none": _gcc_arm_none},
)
