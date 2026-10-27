#!/usr/bin/env bash
# sweeteh installer, safe to run again at any time
# for a one line install pipe this file from github into bash, the readme has the command
# every file it replaces is moved into a dated backup folder first, uninstall puts them back
set -euo pipefail

repo_url="${SWEETEH_REPO:-https://github.com/Aarav2709/Sweeteh.git}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
checkout="$data_home/sweeteh"
target="$config_home/quickshell/sweeteh"
bin_dir="$HOME/.local/bin"
backup_root="$state_home/sweeteh/backups"
backups="$backup_root/$(date +%Y%m%d-%H%M%S)"
profile="$HOME/.bash_profile"
mark_start="# sweeteh start"
mark_end="# sweeteh end"

# shipped configs, source in the repo and where they go
dots=(
  "hypr/hyprland.lua:$config_home/hypr/hyprland.lua"
  "dots/kitty/kitty.conf:$config_home/kitty/kitty.conf"
  "dots/fish/config.fish:$config_home/fish/config.fish"
  "dots/starship.toml:$config_home/starship.toml"
)

# files the shell writes while it runs
generated=(
  "$config_home/hypr/sweeteh"
  "$config_home/kitty/sweeteh.conf"
  "$config_home/gtk-3.0/sweeteh.css"
  "$config_home/gtk-4.0/sweeteh.css"
  "$config_home/vesktop/themes/sweeteh.css"
  "$config_home/zed/themes/sweeteh.json"
  "$data_home/icons/Sweeteh"
)

dry=0
deps=1
keep=0
uninstall=0
purge=0
assume_yes=0

packages=(
  hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland polkit
  quickshell matugen qt6-multimedia qt6-multimedia-ffmpeg ffmpeg
  pipewire wireplumber playerctl brightnessctl upower power-profiles-daemon
  networkmanager bluez bluez-utils cava hyprsunset fprintd
  cliphist wl-clipboard wf-recorder libnotify curl git glib2
  kitty nautilus ttf-jetbrains-mono-nerd fish starship eza
)

usage() {
  cat <<USAGE
Usage: install.sh [options]

  --dry-run        Show what would change without touching anything.
  --no-deps        Skip installing packages.
  --keep-configs   Keep your own Hyprland, kitty, fish and starship configs.
  --uninstall      Remove Sweeteh and put your previous configs back.
  --purge          With --uninstall, also delete Sweeteh settings, backups and cache.
  -y, --yes        Do not ask before installing packages.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry=1 ;;
    --no-deps) deps=0 ;;
    --keep-configs|--keep-hypr) keep=1 ;;
    --uninstall) uninstall=1 ;;
    --purge) purge=1 ;;
    -y|--yes) assume_yes=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option $arg." >&2; usage; exit 1 ;;
  esac
done

bold=$'\e[1m'; dim=$'\e[2m'; accent=$'\e[38;5;147m'; reset=$'\e[0m'
step() { printf '\n%s%s%s\n' "$accent$bold" "$*" "$reset"; }
say() { printf '  %s\n' "$*"; }
note() { printf '  %s%s%s\n' "$dim" "$*" "$reset"; }
act() {
  if [[ $dry -eq 1 ]]; then
    note "Would run: $*"
  else
    "$@"
  fi
}

# questions read from the terminal, so they work when this script is piped from curl
ask() {
  [[ $assume_yes -eq 1 ]] && return 0
  local reply
  printf '  %s [Y/n] ' "$1"
  read -r reply < /dev/tty || reply=""
  [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

# move a file aside into the backup folder, keeping its place under home
park() {
  local path="$1" rel
  [[ -e "$path" || -L "$path" ]] || return 0
  rel="${path#"$HOME"/}"
  act mkdir -p "$backups/$(dirname "$rel")"
  act mv "$path" "$backups/$rel"
  note "Backed up ${path/#$HOME/\~}."
}

# the newest backup of a file, if there is one
latest_backup() {
  local rel="${1#"$HOME"/}"
  ls -1d "$backup_root"/*/"$rel" 2>/dev/null | tail -n 1 || true
}

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, it asks for sudo when it needs it." >&2
  exit 1
fi

# piped from curl there is no checkout yet, so fetch one and run its installer
here="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || pwd)"
if [[ ! -f "$here/shell.qml" || ! -d "$here/modules" ]]; then
  command -v git >/dev/null || { echo "Git is needed, install it with sudo pacman -S git." >&2; exit 1; }
  if [[ -d "$checkout/.git" ]]; then
    step "Updating Sweeteh"
    git -C "$checkout" fetch --tags --force --quiet origin
  else
    step "Downloading Sweeteh"
    mkdir -p "$(dirname "$checkout")"
    git clone --quiet "$repo_url" "$checkout"
  fi
  # the newest release tag, or the main branch until there is one
  latest="$(git -C "$checkout" tag -l 'v*' --sort=-v:refname | head -n 1)"
  if [[ -n "$latest" ]]; then
    git -C "$checkout" checkout --quiet "$latest"
    say "Using release $latest."
  else
    git -C "$checkout" checkout --quiet main 2>/dev/null || true
    git -C "$checkout" pull --ff-only --quiet || true
  fi
  exec bash "$checkout/install.sh" "$@"
fi
repo="$here"

if [[ $uninstall -eq 1 ]]; then
  step "Removing Sweeteh"
  [[ $dry -eq 0 ]] && pkill -f "^qs -c sweeteh( |$)" 2>/dev/null || true
  [[ -L "$target" ]] && act rm "$target" && say "Removed the shell link."
  [[ -L "$bin_dir/sweeteh" ]] && act rm "$bin_dir/sweeteh" && say "Removed the sweeteh command."
  for entry in "${dots[@]}"; do
    dest="${entry#*:}"
    [[ -f "$dest" ]] && cmp -s "$repo/${entry%%:*}" "$dest" || continue
    previous="$(latest_backup "$dest")"
    act rm -f "$dest"
    if [[ -n "$previous" ]]; then
      act cp -a "$previous" "$dest"
      say "Restored your ${dest/#$HOME/\~}."
    else
      say "Removed ${dest/#$HOME/\~}."
    fi
  done
  for path in "${generated[@]}"; do
    [[ -e "$path" ]] && act rm -rf "$path"
  done
  for css in "$config_home/gtk-3.0/gtk.css" "$config_home/gtk-4.0/gtk.css"; do
    [[ -f "$css" ]] && act sed -i "/@import url('sweeteh.css');/d" "$css"
  done
  if [[ -f "$profile" ]] && grep -qF "$mark_start" "$profile"; then
    act sed -i "/^$mark_start$/,/^$mark_end$/d" "$profile"
    say "Hyprland no longer starts by itself on tty1."
  fi
  if command -v gsettings >/dev/null && [[ "$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null)" == "'Sweeteh'" ]]; then
    act gsettings set org.gnome.desktop.interface icon-theme Adwaita
  fi
  if [[ $purge -eq 1 ]]; then
    act rm -rf "$config_home/sweeteh" "$state_home/sweeteh" "$cache_home/sweeteh"
    say "Deleted Sweeteh settings, backups and cache."
  else
    say "Your Sweeteh settings and backups stay in ~/.config/sweeteh and ~/.local/state/sweeteh."
  fi
  exit 0
fi

printf '\n%s  Sweeteh  %s %sOne shell, two layouts, all island%s\n' "$accent$bold" "$reset" "$dim" "$reset"
[[ $dry -eq 1 ]] && note "Dry run, nothing will change."

if [[ $deps -eq 1 ]]; then
  step "Packages"
  if command -v pacman >/dev/null; then
    missing=()
    for p in "${packages[@]}"; do
      pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
      say "Everything is already installed."
    elif ask "Install ${missing[*]}?"; then
      act sudo pacman -S --needed --noconfirm "${missing[@]}"
    else
      say "Skipped, some features will stay off until these are installed."
    fi
  else
    say "This is not an Arch based system, install these with your package manager."
    note "${packages[*]}"
  fi

  step "Services"
  for svc in NetworkManager bluetooth power-profiles-daemon; do
    systemctl list-unit-files "$svc.service" >/dev/null 2>&1 || continue
    systemctl is-enabled --quiet "$svc" 2>/dev/null && continue
    # never start a second network manager next to one that already runs
    if [[ "$svc" == NetworkManager ]] && systemctl is-active --quiet iwd systemd-networkd connman 2>/dev/null; then
      note "Another network service is running, leaving NetworkManager off."
      continue
    fi
    act sudo systemctl enable --now "$svc" && say "Enabled $svc."
  done
fi

step "Shell"
act mkdir -p "$(dirname "$target")" "$bin_dir"
if [[ -L "$target" ]]; then
  act rm "$target"
elif [[ -e "$target" ]]; then
  park "$target"
fi
act ln -s "$repo" "$target"
act ln -sf "$repo/bin/sweeteh" "$bin_dir/sweeteh"
say "Installed the shell and the sweeteh command."
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) note "Add $bin_dir to your PATH to use the sweeteh command." ;;
esac

step "Configs"
if [[ $keep -eq 1 ]]; then
  say "Kept your own configs, add this to hyprland.lua so the shell starts on login:"
  note 'hl.on("hyprland.start", function() hl.exec_cmd("sweeteh run") end)'
else
  for entry in "${dots[@]}"; do
    src="$repo/${entry%%:*}"
    dest="${entry#*:}"
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
      continue
    fi
    act mkdir -p "$(dirname "$dest")"
    park "$dest"
    act cp "$src" "$dest"
  done
  say "Hyprland, kitty, fish and starship are set up."
fi

step "Session"
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  say "Already in Hyprland."
elif systemctl is-enabled --quiet display-manager 2>/dev/null; then
  say "Pick Hyprland on your login screen next time you sign in."
elif ! grep -qF "$mark_start" "$profile" 2>/dev/null; then
  # no login screen, so start hyprland straight from the first console
  if [[ $dry -eq 1 ]]; then
    note "Would make Hyprland start on tty1 login through $profile."
  else
    printf '\n%s\nif [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then exec start-hyprland; fi\n%s\n' "$mark_start" "$mark_end" >> "$profile"
  fi
  say "Hyprland now starts when you log into tty1."
fi

step "Wallpapers"
act mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos/Recordings"
if [[ -z "$(ls -A "$HOME/Pictures/Wallpapers" 2>/dev/null)" ]]; then
  act cp -n "$repo"/assets/wallpapers/* "$HOME/Pictures/Wallpapers/"
  say "Added the Sweeteh wallpapers to ~/Pictures/Wallpapers."
else
  say "Using the wallpapers already in ~/Pictures/Wallpapers."
fi

step "Done"
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" && $dry -eq 0 ]]; then
  hyprctl reload >/dev/null 2>&1 || true
  pgrep -f "^qs -c sweeteh( |$)" >/dev/null || setsid -f "$bin_dir/sweeteh" run >/dev/null 2>&1
  say "Sweeteh is running, it starts by itself from now on."
else
  say "Sweeteh starts by itself the next time Hyprland does."
fi
note "Tap Super for the launcher, Super A for the island, Super Period for every keybind."
