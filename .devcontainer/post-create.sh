#!/usr/bin/env bash
set -euo pipefail

codex_config="${HOME}/.codex/config.toml"
git_devcontainer_config="${HOME}/.gitconfig-devcontainer"
mkdir -p "${HOME}/.codex" "${HOME}/.config/gh"
touch "${codex_config}" "${HOME}/.gitconfig" "${git_devcontainer_config}"

if ! grep -Fq '[projects."/app"]' "${codex_config}"; then
  {
    printf '\n[projects."/app"]\n'
    printf 'trust_level = "trusted"\n'
  } >> "${codex_config}"
fi

if [ -f "${HOME}/.gitconfig-host" ] && ! git config --global --get-all include.path | grep -Fxq /root/.gitconfig-host; then
  git config --global --add include.path /root/.gitconfig-host
fi

if ! git config --global --get-all include.path | grep -Fxq /root/.gitconfig-devcontainer; then
  git config --global --add include.path /root/.gitconfig-devcontainer
fi

if ! git config --file "${git_devcontainer_config}" --get-all safe.directory | grep -Fxq /app; then
  git config --file /root/.gitconfig-devcontainer --add safe.directory /app
fi

for shell_rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  touch "${shell_rc}"
  sed -i "/alias codex='command codex --cd \/app --sandbox workspace-write --ask-for-approval never'/d" "${shell_rc}"
  sed -i "/# Wild Waters devcontainer Codex defaults/,/^}/d" "${shell_rc}"

  cat >> "${shell_rc}" <<'SHELL'

# Wild Waters devcontainer Codex defaults
codex() {
  command codex \
    --cd /app \
    --dangerously-bypass-approvals-and-sandbox \
    -c 'mcp_servers.chrome-devtools.command="npx"' \
    "$@"
}
SHELL
done

bundle check || bundle install
npm ci
bin/rails db:prepare

if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  printf '%s\n' "GitHub CLI authentication is available."
else
  printf '%s\n' "GitHub CLI is installed, but no authenticated session was detected."
fi

if command -v codex >/dev/null; then
  codex --version
else
  printf '%s\n' "Codex CLI is not available in this container image."
fi

bin/openspec --version
