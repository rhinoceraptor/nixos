#!/usr/bin/env bash
# Regenerates SSH/git identity config from ~/.config/nixos-identities.json,
# fetching each identity's public key + email live from 1Password so none of
# it has to live in this (public) repo. Runs on every home-manager
# activation; safe to re-run, and a no-op if the config file is missing or
# `op` isn't signed in (so a fresh clone of the public repo, or a machine
# that hasn't signed into 1Password yet, still activates cleanly).
#
# Config schema (see home/identities.example.json):
#   { "sshKeys": [
#     { "1passwordName": "...", "default": true|false,
#       "path": "~/git/work",        # required unless default
#       "alias": "github-work",      # optional, defaults to a slug of the name
#       "githubOrgs": ["org-name"]   # optional: git@github.com:org/ -> alias
#     }, ...
#   ] }
#
# Each entry's 1Password item needs a "public key" field (standard for
# 1Password's SSH Key item type) and an "email" field (custom).
set -euo pipefail

CONFIG_FILE="$HOME/.config/nixos-identities.json"
SSH_KEYS_DIR="$HOME/.ssh/op-identities"
SSH_INCLUDE="$HOME/.ssh/generated-identities.config"
GIT_IDENTITIES_DIR="$HOME/.config/git/identities"
GIT_INCLUDE="$HOME/.config/git/generated-identities.gitconfig"
AGENT_TOML="$HOME/.config/1Password/ssh/agent.toml"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "generate-identities: no $CONFIG_FILE, skipping (see home/identities.example.json)" >&2
  exit 0
fi

if ! op vault list >/dev/null 2>&1; then
  # Not `op whoami`: this fleet authenticates via the desktop app's CLI
  # integration (Settings > Developer), not `op signin`, and `op whoami`
  # specifically requires a traditional signin session even though ordinary
  # commands like `op item get` work fine under app integration alone.
  echo "generate-identities: 1Password CLI not authorized (desktop app locked, or CLI integration off in Settings > Developer?), skipping" >&2
  exit 0
fi

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

mkdir -p "$SSH_KEYS_DIR" "$GIT_IDENTITIES_DIR" "$(dirname "$AGENT_TOML")"

ssh_tmp=$(mktemp)
git_tmp=$(mktemp)
agent_tmp=$(mktemp)
trap 'rm -f "$ssh_tmp" "$git_tmp" "$agent_tmp"' EXIT

vaults=()
default_count=0

entry_count=$(jq -r '.sshKeys | length' "$CONFIG_FILE")
for ((i = 0; i < entry_count; i++)); do
  entry=$(jq -c ".sshKeys[$i]" "$CONFIG_FILE")
  name=$(jq -r '."1passwordName"' <<<"$entry")
  is_default=$(jq -r '.default // false' <<<"$entry")
  path=$(jq -r '.path // empty' <<<"$entry")
  alias=$(jq -r '.alias // empty' <<<"$entry")
  mapfile -t github_orgs < <(jq -r '.githubOrgs // [] | .[]' <<<"$entry")

  if [[ "$is_default" != "true" && -z "$path" ]]; then
    echo "generate-identities: '$name' has no path and isn't default, skipping" >&2
    continue
  fi

  slug=$(slugify "$name")
  [[ -n "$alias" ]] || alias="github-$slug"

  item_json=$(op item get "$name" --format json)
  public_key=$(jq -r '.fields[]? | select(.label == "public key") | .value' <<<"$item_json")
  email=$(jq -r '.fields[]? | select(.label == "email") | .value' <<<"$item_json")
  vault=$(jq -r '.vault.name' <<<"$item_json")

  if [[ -z "$public_key" || -z "$email" ]]; then
    echo "generate-identities: '$name' is missing a 'public key' or 'email' field in 1Password, skipping" >&2
    continue
  fi

  vaults+=("$vault")

  pubkey_file="$SSH_KEYS_DIR/id_$slug.pub"
  printf '%s\n' "$public_key" >"$pubkey_file"
  chmod 644 "$pubkey_file"

  if [[ "$is_default" == "true" ]]; then
    ((default_count += 1))
    {
      echo "Host github.com"
      echo "    IdentitiesOnly yes"
      echo "    IdentityFile $pubkey_file"
      echo
    } >>"$ssh_tmp"
    {
      echo "[user]"
      echo "    email = $email"
    } >>"$git_tmp"
  else
    {
      echo "Host $alias"
      echo "    HostName github.com"
      echo "    User git"
      echo "    IdentitiesOnly yes"
      echo "    IdentityFile $pubkey_file"
      echo
    } >>"$ssh_tmp"

    identity_file="$GIT_IDENTITIES_DIR/$slug.gitconfig"
    printf '[user]\n    email = %s\n' "$email" >"$identity_file"
    {
      echo "[includeIf \"gitdir:$path/\"]"
      echo "    path = $identity_file"
    } >>"$git_tmp"

    for org in "${github_orgs[@]}"; do
      {
        echo "[url \"git@$alias:$org/\"]"
        echo "    insteadOf = git@github.com:$org/"
      } >>"$git_tmp"
    done
  fi
done

if ((default_count > 1)); then
  echo "generate-identities: more than one entry marked \"default\": true in $CONFIG_FILE" >&2
  exit 1
fi

if ((${#vaults[@]} > 0)); then
  printf '%s\n' "${vaults[@]}" | sort -u | while IFS= read -r vault; do
    {
      echo "[[ssh-keys]]"
      echo "vault = \"$vault\""
      echo
    } >>"$agent_tmp"
  done
fi

mv "$ssh_tmp" "$SSH_INCLUDE"
mv "$git_tmp" "$GIT_INCLUDE"
mv "$agent_tmp" "$AGENT_TOML"
