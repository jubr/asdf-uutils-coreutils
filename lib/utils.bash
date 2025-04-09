#!/usr/bin/env bash

#set -x # debug much?
set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded.
GH_REPO="https://github.com/uutils/coreutils"
TOOL_NAME="coreutils"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if task is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  # TODO: Adapt this. By default we simply list the tag names from GitHub releases.
  # Change this function if task has other means of determining installable versions.
  list_github_tags
}

determine_download_url() {
  local version="$1"
  local platform=""
  local arch=""
  
  # Determine platform and architecture
  platform="$(uname | tr '[:upper:]' '[:lower:]')"
  case $(uname -m) in
    arm64) arch="aarch64" ;;
    *) arch="$(uname -m)" ;;
  esac

  # Simplified - one format per platform/arch combination
  case "${platform}" in
    linux)
      echo "$GH_REPO/releases/download/${version}/${TOOL_NAME}-${version}-${arch}-unknown-linux-gnu.tar.gz"
      ;;
    darwin)
      echo "$GH_REPO/releases/download/${version}/${TOOL_NAME}-${version}-${arch}-apple-darwin.tar.gz"
      ;;
    windows)
      echo "$GH_REPO/releases/download/${version}/${TOOL_NAME}-${version}-${arch}-pc-windows-msvc.zip"
      ;;
    *)
      fail "Unsupported platform '${platform}' found. Only Linux, Darwin, and Windows are supported."
      ;;
  esac
}

download_release() {
  local version filename url

  version="$1"
  filename="$2"
  
  url=$(determine_download_url "$version")
  
  echo "* Downloading $TOOL_NAME release $version..."
  curl "${curl_opts[@]}" -o "$filename" "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p "$install_path/bin"
    
    # Determine file extension from ASDF_DOWNLOAD_PATH
    local file_extension=""
    for file in "$ASDF_DOWNLOAD_PATH"/*; do
      if [[ "$file" == *.tar.gz ]]; then
        file_extension="tar.gz"
        break
      elif [[ "$file" == *.zip ]]; then
        file_extension="zip"
        break
      fi
    done

    # Extract based on file extension
    if [[ "$file_extension" == "tar.gz" ]]; then
      echo "* Extracting tar.gz archive..."
      tar -xzf "$ASDF_DOWNLOAD_PATH"/*.tar.gz -C "$install_path" --strip-components=1
    elif [[ "$file_extension" == "zip" ]]; then
      echo "* Extracting zip archive..."
      unzip -q "$ASDF_DOWNLOAD_PATH"/*.zip -d "$install_path"
      # Move files from extracted directory to install_path if needed
      find "$install_path" -name "$TOOL_NAME*" -type d | while read -r dir; do
        mv "$dir"/* "$install_path/"
        rmdir "$dir"
      done
    fi

    mv $install_path/$TOOL_NAME $install_path/bin/$TOOL_NAME

    # Verify executable
    test -x "$install_path/bin/$TOOL_NAME" || fail "Expected $install_path/bin/$TOOL_NAME to be executable."
    $install_path/bin/$TOOL_NAME | grep '(multi-call binary)' || fail "Expected $install_path/bin/$TOOL_NAME output to contain '(multi-call binary)'."

    for applet in $("$install_path/bin/$TOOL_NAME" --list); do
      ln -s coreutils "$install_path/bin/$applet"
    done

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error occurred while installing $TOOL_NAME $version."
  )
}
