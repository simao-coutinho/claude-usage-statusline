#!/bin/sh
export LC_NUMERIC=C
input=$(cat)

CACHE_FILE="/tmp/.claude_statusline_cache"

# Helper: convert a resets_at Unix epoch to a countdown string
time_until() {
  resets_at="$1"
  now=$(date +%s)
  diff=$((resets_at - now))
  if [ "$diff" -le 0 ]; then
    echo "now"
    return
  fi
  days=$((diff / 86400))
  hours=$(( (diff % 86400) / 3600 ))
  mins=$(( (diff % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf "%dd%02dh" "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf "%dh%02dm" "$hours" "$mins"
  else
    printf "%dm" "$mins"
  fi
}

# Read cached values
cached_five_pct=""
cached_five_resets=""
cached_week_pct=""
cached_week_resets=""
if [ -f "$CACHE_FILE" ]; then
  cached_five_pct=$(sed -n '1p' "$CACHE_FILE")
  cached_five_resets=$(sed -n '2p' "$CACHE_FILE")
  cached_week_pct=$(sed -n '3p' "$CACHE_FILE")
  cached_week_resets=$(sed -n '4p' "$CACHE_FILE")
fi

# Extract current API values
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

now=$(date +%s)

# --- 5h: hold last known high value, only accept lower if timer expired ---
if [ -n "$five_pct" ]; then
  timer_expired=0
  if [ -n "$cached_five_resets" ] && [ "$now" -ge "$cached_five_resets" ] 2>/dev/null; then
    timer_expired=1
  fi

  new_lower=0
  if [ -n "$cached_five_pct" ]; then
    new_lower=$(awk "BEGIN { print ($five_pct < $cached_five_pct) ? 1 : 0 }")
  fi

  if [ "$new_lower" -eq 1 ] && [ "$timer_expired" -eq 0 ]; then
    five_pct="$cached_five_pct"
  fi
  if [ -n "$five_resets" ]; then
    cached_five_resets="$five_resets"
  fi
fi

# --- 7d: same logic ---
if [ -n "$week_pct" ]; then
  timer_expired=0
  if [ -n "$cached_week_resets" ] && [ "$now" -ge "$cached_week_resets" ] 2>/dev/null; then
    timer_expired=1
  fi

  new_lower=0
  if [ -n "$cached_week_pct" ]; then
    new_lower=$(awk "BEGIN { print ($week_pct < $cached_week_pct) ? 1 : 0 }")
  fi

  if [ "$new_lower" -eq 1 ] && [ "$timer_expired" -eq 0 ]; then
    week_pct="$cached_week_pct"
  fi
  if [ -n "$week_resets" ]; then
    cached_week_resets="$week_resets"
  fi
fi

# Save current values to cache
cat > "$CACHE_FILE" <<EOF
$five_pct
$cached_five_resets
$week_pct
$cached_week_resets
EOF

# Build rate limits segment
limits=""
if [ -n "$five_pct" ]; then
  five_label="5h:$(printf '%.1f' "$five_pct")%"
  if [ -n "$cached_five_resets" ]; then
    five_label="${five_label} ($(time_until "$cached_five_resets"))"
  fi
  limits="$five_label"
fi
if [ -n "$week_pct" ]; then
  week_label="7d:$(printf '%.1f' "$week_pct")%"
  if [ -n "$cached_week_resets" ]; then
    week_label="${week_label} ($(time_until "$cached_week_resets"))"
  fi
  [ -n "$limits" ] && limits="$limits  "
  limits="${limits}${week_label}"
fi

# Build context segment
ctx_segment=""
if [ -n "$ctx_used" ]; then
  ctx_segment="ctx:$(printf '%.1f' "$ctx_used")%"
fi

# Combine segments
output=""
if [ -n "$limits" ]; then
  output="$limits"
fi
if [ -n "$ctx_segment" ]; then
  [ -n "$output" ] && output="$output  "
  output="${output}${ctx_segment}"
fi

if [ -n "$output" ]; then
  printf "%s" "$output"
fi
