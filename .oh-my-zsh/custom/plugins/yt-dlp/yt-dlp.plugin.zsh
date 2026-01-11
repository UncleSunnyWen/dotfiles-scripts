# ==================================================
# yt-dlp helper plugin for oh-my-zsh (uses global config)
# ==================================================

# ----------------------------
# Print usage
# ----------------------------
_yd_usage() {
  cat <<EOF
Usage:
  yd Name URL [extra_options]        -> download video as Name.mp4
  ya Name URL [extra_options]        -> download audio as Name.mp3
  ydlist Name URL [extra_options]    -> download playlist with index
Notes:
  - extra_options are optional yt-dlp arguments, e.g. --referer, --cookies
EOF
}

# ----------------------------
# Core yt-dlp runner
# ----------------------------
_yd_run() {
  local output="$1"
  local url="$2"
  shift 2
  local extra_opts="$*"
  yt-dlp $extra_opts -o "$output" "$url"
}

# ----------------------------
# Download video
# ----------------------------
yd() {
  [[ $# -lt 2 ]] && { _yd_usage; return 1; }
  local name="$1"
  local url="$2"
  shift 2
  _yd_run "$name.%(ext)s" "$url" "$@"
}

# ----------------------------
# Download audio only
# ----------------------------
ya() {
  [[ $# -lt 2 ]] && { _yd_usage; return 1; }
  local name="$1"
  local url="$2"
  shift 2
  _yd_run "$name.%(ext)s" "$url" -x --audio-format mp3 "$@"
}

# ----------------------------
# Download playlist with auto index
# ----------------------------
ydlist() {
  [[ $# -lt 2 ]] && { _yd_usage; return 1; }
  local name="$1"
  local url="$2"
  shift 2
  _yd_run "%(playlist_index)02d - $name - %(title)s-%(id)s.%(ext)s" "$url" "$@"
}
