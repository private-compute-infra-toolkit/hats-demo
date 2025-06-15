load("@oak//bazel:defs.bzl", "oci_runtime_bundle")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")

package(
    default_visibility = ["//visibility:public"],
)

cc_binary(
    name = "main",
    srcs = ["main.cc"],
    deps = [
        ":trusted-application",
        "@hats//client/proto:orchestrator_cc_proto",
        "@hats//client/sdk:hats_lightweight_client",
        "@hats//status_macro:status_macros",
        "@hats//crypto:aead-crypter",
        "@hats//crypto:secret-data",
        "@com_google_absl//absl/flags:flag",
        "@com_google_absl//absl/flags:parse",
        "@com_google_absl//absl/log:flags",
        "@com_google_absl//absl/log:initialize",
        "@com_google_absl//absl/strings",
    ],
)

cc_library(
  name = "trusted-application",
  srcs = ["trusted-application.cc"],
  hdrs = ["trusted-application.h"],
  deps = [
      "//workloads/trusted-application/proto:trusted_service_cc_grpc",
      "//workloads/trusted-application/proto:trusted_service_cc_proto",
      "@hats//client/proto:orchestrator_cc_proto",
      "@hats//crypto:aead-crypter",
      "@hats//crypto:secret-data",
      "@com_google_absl//absl/status",
  ],
)

pkg_tar(
    name = "tar",
    srcs = [":main"],
    package_dir = "/usr/local/bin",
    visibility = [
        "//visibility:public",
    ],
)

oci_image(
    name = "image",
    base = "@distroless_cc_debian12",
    entrypoint = ["/usr/local/bin/main"],
    tars = [":tar"],
)

oci_runtime_bundle(
    name = "bundle",
    image = ":image",
)
