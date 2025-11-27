"""V Language Toolchain Extension for Bzlmod"""

def _v_toolchain_impl(module_ctx):
    """Download and set up the V language toolchain."""
    
    # Detect host platform
    os_name = module_ctx.os.name.lower()
    if "linux" in os_name:
        platform = "linux"
        archive_ext = "zip"
    elif "mac" in os_name or "darwin" in os_name:
        platform = "macos"
        archive_ext = "zip"
    elif "win" in os_name:
        platform = "windows"
        archive_ext = "zip"
    else:
        platform = "linux"  # Default fallback
        archive_ext = "zip"
    
    # V language release info
    v_version = "0.4.8"
    
    # Create the repository rule
    _v_binary_repo(
        name = "v_binary",
        version = v_version,
        platform = platform,
    )

def _v_binary_repo_impl(repository_ctx):
    """Repository rule to download V binary."""
    version = repository_ctx.attr.version
    platform = repository_ctx.attr.platform
    
    # V download URLs
    if platform == "linux":
        url = "https://github.com/vlang/v/releases/download/{}/v_linux.zip".format(version)
        sha256 = ""  # Will be populated after first download
    elif platform == "macos":
        url = "https://github.com/vlang/v/releases/download/{}/v_macos.zip".format(version)
        sha256 = ""
    else:
        url = "https://github.com/vlang/v/releases/download/{}/v_windows.zip".format(version)
        sha256 = ""
    
    # Download and extract
    repository_ctx.download_and_extract(
        url = url,
        output = ".",
        stripPrefix = "v",
    )
    
    # Make V executable
    if platform != "windows":
        repository_ctx.execute(["chmod", "+x", "v"])
    
    # Create BUILD.bazel for the V toolchain
    repository_ctx.file("BUILD.bazel", """
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "v_binary",
    srcs = ["v"],
)

filegroup(
    name = "v_toolchain",
    srcs = glob(["**/*"]),
)

# Export the V home directory path
exports_files(["v"])
""")

_v_binary_repo = repository_rule(
    implementation = _v_binary_repo_impl,
    attrs = {
        "version": attr.string(mandatory = True),
        "platform": attr.string(mandatory = True),
    },
)

v_toolchain = module_extension(
    implementation = _v_toolchain_impl,
)
