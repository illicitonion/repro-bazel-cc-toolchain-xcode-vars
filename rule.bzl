load(
    "@bazel_tools//tools/build_defs/cc:action_names.bzl",
    "CPP_LINK_EXECUTABLE_ACTION_NAME",
)
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def _get_developer_dir_impl(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    link_variables = cc_common.create_link_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        is_linking_dynamic_library = False,
    )

    link_env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = CPP_LINK_EXECUTABLE_ACTION_NAME,
        variables = link_variables,
    )

    out = ctx.actions.declare_file(ctx.label.name)

    print("Env vars:\n{}".format("\n".join(["{}={}".format(k, v) for k, v in link_env.items()])))

    ctx.actions.run_shell(
        outputs = [out],
        command = "if [[ -z ${DEVELOPER_DIR} ]]; then echo >&2 Could not find developer dir ; exit 1 ; fi ; echo ${DEVELOPER_DIR} > $1",
        arguments = [out.path],
        env = link_env,
    )

    return [
        DefaultInfo(files = depset([out])),
    ]

get_developer_dir = rule(
    implementation = _get_developer_dir_impl,
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    attrs = {
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    fragments = ["cpp"],
)
