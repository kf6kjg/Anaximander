#!/bin/bash

proj_dir="${PWD}"
bin_dir="${proj_dir}/bin"
lib_dir="${proj_dir}/lib"
etc_dir="${proj_dir}/etc"

version="$(date +%Y%m%d%H)"

package_name="anaximander-${version}-linux-x86-64"

package_dir="${proj_dir}/${package_name}"

# Prep.
mkdir "${package_dir}"


# Get the binaries
cp -Ra "${bin_dir}" "${package_dir}/"

# Get the shared object files
mkdir "${package_dir}/lib"
cp -a "${lib_dir}/"*.so* "${package_dir}/lib"

# Get the config data
cp -Ra "${etc_dir}" "${package_dir}/"

# Get the script
cp -a "${proj_dir}/anaximander.sh" "${package_dir}/"

# Package the whole shooting match.
tar -cJf "${package_name}.tar.xz" "${package_dir}"

# Clean up.
rm -rf "${package_dir}"

echo "Package created as ${package_name}.tar.xz"
