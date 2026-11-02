#!/usr/bin/env bash
set -euo pipefail

env_name="${1:-}"
case "$env_name" in
  dev|stg|prod) ;;
  *)
    echo "Usage: $0 dev|stg|prod" >&2
    exit 2
    ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$root/config/env_${env_name}.env"
generated="$root/ios/Flutter/Generated.xcconfig"

if [ ! -f "$env_file" ]; then
  echo "Missing environment file: $env_file" >&2
  exit 1
fi

if [ ! -f "$generated" ]; then
  echo "Missing $generated. Run 'fvm flutter build ios --config-only' first." >&2
  exit 1
fi

if ! bash "$root/scripts/check_config.sh" "$env_file" "$env_name" >/dev/null 2>&1; then
  echo "Invalid environment file: $env_file" >&2
  exit 1
fi

dart_defines="$(
  awk '
    function trim(value) {
      sub(/^[ \t\r]+/, "", value)
      sub(/[ \t\r]+$/, "", value)
      return value
    }

    function unquote(value, first, last, single_quote) {
      first = substr(value, 1, 1)
      last = substr(value, length(value), 1)
      if (first == "\"" && last == "\"") {
        return substr(value, 2, length(value) - 2)
      }
      single_quote = sprintf("%c", 39)
      if (first == single_quote && last == single_quote) {
        return substr(value, 2, length(value) - 2)
      }
      if (first == "`" && last == "`") {
        return substr(value, 2, length(value) - 2)
      }
      return value
    }

    {
      line = trim($0)
      if (line == "" || substr(line, 1, 1) == "#") next

      separator = index(line, "=")
      if (separator == 0) {
        print "Invalid .env line: " $0 > "/dev/stderr"
        exit 1
      }

      key = trim(substr(line, 1, separator - 1))
      value = trim(substr(line, separator + 1))
      print key "=" unquote(value)
    }
  ' "$env_file" |
    while IFS= read -r entry; do
      printf '%s' "$entry" | base64 | tr -d '\n'
      printf '\n'
    done |
    paste -s -d ',' -
)"

tmp="$(mktemp "${generated}.XXXXXX")"
grep -v '^DART_DEFINES=' "$generated" > "$tmp" || true
printf 'DART_DEFINES=%s\n' "$dart_defines" >> "$tmp"
mv "$tmp" "$generated"

echo "Applied $env_name dart defines to Generated.xcconfig"
