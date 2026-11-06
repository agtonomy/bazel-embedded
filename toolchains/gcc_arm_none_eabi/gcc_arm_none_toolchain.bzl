# MIT License
#
# Copyright (c) 2019 Nathaniel Brough
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

load("@rules_cc//cc:defs.bzl", "cc_toolchain")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "tool_path",
)
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@gcc_arm_none_eabi_compiler//:defs.bzl", "SYSTEM_INCLUDE_COMMAND_LINE", "SYSTEM_INCLUDE_PATHS")
load("//devices/arm:cortex_m.bzl", "CORTEX_M_DEVICE_CONFIGS")
load("//toolchains/features/common:defs.bzl", "GetCommonFeatures")
load("//toolchains/features/embedded:defs.bzl", "GetEmbeddedFeatures")

_ARM_NONE_EABI_VERSION = "9.2.1"
_CPP_ALL_COMPILE_ACTIONS = [
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.lto_backend,
    ACTION_NAMES.clif_match,
]

_C_ALL_COMPILE_ACTIONS = [
    ACTION_NAMES.assemble,
    ACTION_NAMES.c_compile,
]

_LD_ALL_ACTIONS = [
    ACTION_NAMES.cpp_link_executable,
]

def _get_injected_headers_command_line(ctx):
    command_line = []
    for hdr_lib in ctx.attr.injected_hdr_deps:
        cc_ctx = hdr_lib[CcInfo].compilation_context
        for hdr in cc_ctx.headers.to_list():
            command_line += ["-include", hdr.short_path]
    return command_line

def _get_additional_system_includes_command_line(ctx):
    command_line = []
    for hdr_lib in ctx.attr.system_hdr_deps:
        cc_ctx = hdr_lib[CcInfo].compilation_context
        for inc in cc_ctx.system_includes.to_list():
            command_line += ["-isystem", inc]
    return command_line

def _get_additional_system_include_paths(ctx):
    include_paths = []
    for hdr_lib in ctx.attr.system_hdr_deps:
        cc_ctx = hdr_lib[CcInfo].compilation_context
        for inc in cc_ctx.system_includes.to_list():
            if inc not in ".":
                include_paths.append(inc)
    return include_paths

def _gcc_arm_none_toolchain_config_info_impl(ctx):
    # The wrappers are generated into the compiler repository, next to the cc_toolchain that uses them.
    postfix = ""
    if ctx.configuration.host_path_separator == ";":
        postfix = ".bat"
    tool_paths = [
        tool_path(name = name, path = "wrappers/" + name + postfix)
        for name in ["gcc", "ld", "ar", "cpp", "gcov", "nm", "objcopy", "objdump", "strip"]
    ]

    common_features = GetCommonFeatures(
        compiler = "GCC",
        architecture = ctx.attr.architecture,
        float_abi = ctx.attr.float_abi,
        endian = ctx.attr.endian,
        fpu = ctx.attr.fpu,
        include_paths = _get_additional_system_includes_command_line(ctx) +
                        SYSTEM_INCLUDE_COMMAND_LINE +
                        _get_injected_headers_command_line(ctx),
        sysroot = None,
    )
    embedded_features = GetEmbeddedFeatures("GCC")
    toolchain_config_info = cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        cxx_builtin_include_directories = SYSTEM_INCLUDE_PATHS,
        host_system_name = "i686-unknown-linux-gnu",
        target_system_name = "arm-none-eabi",
        target_cpu = ctx.attr.architecture,
        target_libc = "unknown",
        compiler = "arm-none-eabi-gcc",
        abi_version = "unknown",
        abi_libc_version = "unknown",
        tool_paths = tool_paths,
        features = [
            common_features.all_warnings,
            common_features.all_warnings_as_errors,
            common_features.reproducible,
            common_features.includes,
            common_features.symbol_garbage_collection,
            common_features.architecture,
            common_features.dbg,
            common_features.opt,
            common_features.fastbuild,
            common_features.output_format,
            embedded_features.exceptions,
            embedded_features.runtime_type_information,
            embedded_features.sys_spec,
            embedded_features.cc_constructor_destructor,
        ],
    )
    return toolchain_config_info

gcc_arm_none_toolchain_config = rule(
    implementation = _gcc_arm_none_toolchain_config_info_impl,
    attrs = {
        "architecture": attr.string(
            default = "armv4",
            doc = "System architecture",
            mandatory = False,
            values = [
                "armv4",
                "armv4t",
                "armv5t",
                "armv5te",
                "armv6",
                "armv6j",
                "armv6k",
                "armv6kz",
                "armv6t2",
                "armv6z",
                "armv6zk",
                "armv7",
                "armv7-a",
                "armv7ve",
                "armv8-a",
                "armv8.1-a",
                "armv8.2-a",
                "armv8.3-a",
                "armv8.4-a",
                "armv8.5-a",
                "armv7-r",
                "armv8-r",
                "armv6-m",
                "armv6s-m",
                "armv7-m",
                "armv7e-m",
                "armv8-m",
                "armv8-m.base",
                "armv8-m.main",
                "iwmmxt",
                "iwmmxt2",
            ],
        ),
        "float_abi": attr.string(
            default = "soft",
            doc = "Application Binary Interface",
            mandatory = False,
            values = ["soft", "softfp", "hard"],
        ),
        "system_hdr_deps": attr.label_list(
            doc = "A set of additional system header libraries that are added as a dependency of every cc_<target>",
            default = ["@bazel_embedded_upstream_toolchain//:polyfill"],
            providers = [CcInfo],
        ),
        "injected_hdr_deps": attr.label_list(
            doc = "A set of headers that are injected into the toolchain e.g. by -include",
            default = ["@bazel_embedded_upstream_toolchain//:injected_headers"],
            providers = [CcInfo],
        ),
        "fpu": attr.string(
            default = "auto",
            doc = "Floating point unit",
            mandatory = False,
            values = [
                "none",
                "auto",
                "vfpv2",
                "vfpv3",
                "vfpv3-fp16",
                "vfpv3-d16",
                "vfpv3-d16-fp16",
                "vfpv3xd",
                "vfpv3xd-fp16",
                "neon-vfpv3",
                "neon-fp16",
                "vfpv4",
                "vfpv4-d16",
                "fpv4-sp-d16",
                "neon-vfpv4",
                "fpv5-d16",
                "fpv5-sp-d16",
                "fp-armv8",
                "neon-fp-armv8",
                "crypto-neon-fp-armv8",
            ],
        ),
        "endian": attr.string(
            default = "little",
            doc = "Endianess",
            mandatory = False,
            values = ["little", "big"],
        ),
        "toolchain_identifier": attr.string(
            mandatory = True,
            doc = "Indentifier used by the toolchain, this should be consistent with the cc_toolchain rule attribute",
        ),
    },
    provides = [CcToolchainConfigInfo],
)

def compiler_components(system_hdr_deps, injected_hdr_deps):
    native.filegroup(
        name = "additional_headers",
        srcs = [
            system_hdr_deps,
            injected_hdr_deps,
        ],
    )
    native.filegroup(
        name = "compiler_components",
        srcs = [
            ":all",
            ":additional_headers",
        ],
    )

def gcc_arm_none_toolchain(name, compiler_components, architecture, float_abi, endian, fpu):
    toolchain_config = name + "_config"

    gcc_arm_none_toolchain_config(
        name = toolchain_config,
        architecture = architecture,
        float_abi = float_abi,
        endian = endian,
        fpu = fpu,
        toolchain_identifier = "arm-none-eabi",
    )

    cc_toolchain(
        name = name,
        all_files = compiler_components,
        compiler_files = compiler_components,
        dwp_files = compiler_components,
        linker_files = compiler_components,
        objcopy_files = compiler_components,
        strip_files = compiler_components,
        as_files = compiler_components,
        ar_files = compiler_components,
        supports_param_files = 0,
        toolchain_config = ":" + toolchain_config,
        toolchain_identifier = "arm-none-eabi",
    )

def gcc_arm_none_toolchains():
    """Declares a cc_toolchain for every cortex-m device config.

    Called from the BUILD file generated into the compiler repository, which provides the `all` filegroup of the
    compiler files and the generated wrappers. The matching toolchain() targets are in
    //toolchains/gcc_arm_none_eabi/registry.
    """
    compiler_components(
        injected_hdr_deps = "@bazel_embedded_upstream_toolchain//:injected_headers",
        system_hdr_deps = "@bazel_embedded_upstream_toolchain//:polyfill",
    )

    for cfg in CORTEX_M_DEVICE_CONFIGS:
        gcc_arm_none_toolchain(
            name = "arm_none_eabi_" + cfg.cpu + "_" + cfg.fpu,
            architecture = cfg.cpu,
            compiler_components = ":compiler_components",
            endian = cfg.endian,
            float_abi = cfg.float_abi,
            fpu = cfg.fpu,
        )

def register_gcc_arm_none_toolchain():
    native.register_toolchains("@bazel_embedded//toolchains/gcc_arm_none_eabi/registry:all")
