# ============================================
# ADB Aliases & Functions
# Reference: https://mazhuang.org/awesome-adb/
# ============================================

# Device & Connection
alias adev='adb devices -l'               # List devices (detailed)
alias aconn='adb connect'                 # Connect to device
alias adisc='adb disconnect'              # Disconnect from device
alias aroot='adb root'                    # Restart adbd as root
alias aremount='adb remount'              # Remount system as writable
alias akill='adb kill-server'             # Kill ADB server
alias astart='adb start-server'           # Start ADB server
alias ashell='adb shell'                  # Enter device shell


# App Management
alias ain='adb install -r'                # Install app (overwrite)
alias aun='adb uninstall'                 # Uninstall app
alias aclear='adb shell pm clear'         # Clear app data
alias alaunch='adb shell am start -W -n'  # Launch app & measure time
alias akillapp='adb shell am force-stop'  # Force stop app
alias apkinfo='adb shell dumpsys package' # View app details


# File Operations
alias apush='adb push'                    # Push file to device
alias apull='adb pull'                    # Pull file from device


# Device Control
alias areboot='adb reboot'                # Reboot device
alias arecovery='adb reboot recovery'     # Reboot to Recovery
alias abootloader='adb reboot bootloader' # Reboot to Bootloader


# Debugging & Testing
alias amonkey='adb shell monkey'          # Run Monkey test
alias apkg='adb shell dumpsys activity activities | grep -E "mResumedActivity" | sed -E "s/.*u[0-9]+ //; s/\/.*//"' # Current package
alias aact='adb shell dumpsys activity activities | grep -E "mResumedActivity" | sed -E "s/.*u[0-9]+ //; s/.*\///; s/[ ^}].*//"' # Current activity
alias afrag='adb shell "dumpsys activity top | grep -E \"^ *#[0-9]+: [^ :]+{\" | tail -1" | awk "{sub(/\{.*/,\"\",\$2);print \$2}"' # Current fragment


# System Information
alias ameminfo='adb shell dumpsys meminfo' # View memory info
alias abuildprop='adb shell cat system/build.prop' # View build.prop
alias aprop='adb shell getprop'           # View device properties
alias aver='adb shell getprop ro.build.version.release' # Get Android version
alias awm='adb shell dumpsys window displays' # View window info
alias aip='adb shell ifconfig | grep Mask' # View IP & mask
alias averity='adb disable-verity'        # Disable verification


# Core Functions

# Show current UI components (package/activity/fragments)
adbui() {
  # Get activity list info; exit silently if failed
  local acts=$(adb shell dumpsys activity activities 2>/dev/null)
  [ -z "$acts" ] && return 0

  # Extract line with current resumed activity
  local resumed=$(echo "$acts" | grep -E "mResumedActivity") || return 0

  # Extract package name from resumed activity line
  local pkg=$(echo "$resumed" | awk '{
    sub(/.*u[0-9]+ /, ""); sub(/\/.*/, ""); print
  }')
  [ -z "$pkg" ] && return 0
  echo "Package: $pkg"

  # Extract activity name from resumed activity line
  local act=$(echo "$resumed" | awk '{
    sub(/.*u[0-9]+ /, ""); sub(/.*\//, ""); sub(/[ ^}].*/, ""); print
  }')
  [ -z "$act" ] && return 0
  echo "Activity: $act"

  # Get detailed info of current activity (package/activity)
  local comp="$pkg/$act"
  local activity_details=$(adb shell "dumpsys activity $comp" 2>/dev/null)
  [ -z "$activity_details" ] && return 0

  # Extract fragments from details, format with indent
  echo "$activity_details" | awk '
    /Added Fragments:/ { last = NR }  # Track last fragment list position
    { lines[NR] = $0 }                # Cache all lines
    END {
      if (last == 0) exit             # Exit if no fragments
      print "Fragments:"              # Fragment section header
      for (i = last + 1; i <= NR; i++) {
        line = lines[i]
        # Stop at section end or other fragment lists
        if (line ~ /^ *\}|[A-Za-z]+ Fragments:/) break
        # Format and print valid fragment entries
        if (line ~ /^ *#?[0-9]+: /) {
          sub(/^ */, "", line); sub(/\{.*/, "", line)
          print "    " line  # 4-space indent for entries
        }
      }
    }
  '
}


# Capture and save screenshot
adbshot() {
    local target_dir="${1:-.}"
    local filename="screenshot-$(date +%Y%m%d_%H%M%S).png"
    local full_path="$target_dir/$filename"

    # Validate input path and create directory
    if [[ -f "$target_dir" ]]; then
        echo "Error: Path '$target_dir' is a file, not a directory." >&2
        return 1
    fi
    [[ ! -d "$target_dir" ]] && mkdir -p "$target_dir"

    # Capture screenshot and validate output
    if adb exec-out screencap -p > "$full_path" && [[ -s "$full_path" ]]; then
        echo "Screenshot saved: $full_path"
    else
        echo "Error: Screenshot capture unsuccessful." >&2
        [[ -f "$full_path" ]] && rm -f "$full_path"
        return 1
    fi
}


# Open settings for current foreground app
adbset() {
    local pkg
    pkg=$(adb shell dumpsys activity activities 2>/dev/null | 
          grep -E "mResumedActivity" | head -1 | 
          sed -E 's/.*u[0-9]+ //; s/\/.*//')
    
    [[ -z "$pkg" ]] && { echo "Error: Could not get package name." >&2; return 1; }
    
    if adb shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:$pkg" >/dev/null 2>&1; then
        echo "App settings opened for: $pkg"
    else
        echo "Error: Failed to open settings for: $pkg" >&2
        return 1
    fi
}


# Enhanced ADB logcat tool
adblog() {
    case "$1" in
        "-c"|"--clear")
            adb logcat -c
            echo "Log buffer cleared."
            ;;
        "-f"|"--file")
            local filepath="${2:-log_$(date +%Y%m%d_%H%M%S).log}"
            echo "Logging to file: $filepath (Press Ctrl+C to stop)..."
            adb logcat -v threadtime > "$filepath"
            ;;
        "-e"|"--error")
            adb logcat -v color,threadtime *:E
            ;;
        "-h"|"--help")
            echo "Enhanced ADB Logcat Function"
            echo "Usage: alog [options]"
            echo ""
            echo "Options:"
            echo "  (no args)     Real-time colored logs (threadtime format)"
            echo "  -c, --clear   Clear device log buffer"
            echo "  -f, --file [path]  Export logs to file (default: timestamped .log)"
            echo "  -e, --error   Show only ERROR level and above"
            echo "  -h, --help    Show this help"
            ;;
        *)
            # Default behavior: real-time colored logs
            adb logcat -v color,threadtime
            ;;
    esac
}
