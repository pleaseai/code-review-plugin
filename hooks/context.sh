#!/usr/bin/env bash
set -euo pipefail

# Read plugin.json and gemini-extension.json to get contextFileName
EXTENSION_JSON="${CLAUDE_PLUGIN_ROOT}/gemini-extension.json"
PLUGIN_JSON="${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json"

# Get plugin name for logging
PLUGIN_NAME="unknown"
if [ -f "$PLUGIN_JSON" ]; then
    if command -v jq &> /dev/null; then
        PLUGIN_NAME=$(jq -r '.name // "unknown"' "$PLUGIN_JSON")
    else
        PLUGIN_NAME=$(grep -oP '"name"\s*:\s*"\K[^"]+' "$PLUGIN_JSON" | head -1 || echo "unknown")
    fi
fi

CONTEXT_FILE=""

# First, try to read from plugin.json (Claude Code plugin format)
if [ -f "$PLUGIN_JSON" ]; then
    if command -v jq &> /dev/null; then
        CONTEXT_FILE=$(jq -r '.contextFileName // empty' "$PLUGIN_JSON")
    else
        CONTEXT_FILE=$(grep -oP '"contextFileName"\s*:\s*"\K[^"]+' "$PLUGIN_JSON" || true)
    fi
fi

# Fallback to gemini-extension.json if not found in plugin.json
if [ -z "$CONTEXT_FILE" ] && [ -f "$EXTENSION_JSON" ]; then
    if command -v jq &> /dev/null; then
        CONTEXT_FILE=$(jq -r '.contextFileName // empty' "$EXTENSION_JSON")
    else
        CONTEXT_FILE=$(grep -oP '"contextFileName"\s*:\s*"\K[^"]+' "$EXTENSION_JSON" || true)
    fi
fi

# If contextFileName exists, read and output the file
if [ -n "$CONTEXT_FILE" ] && [ -f "${CLAUDE_PLUGIN_ROOT}/${CONTEXT_FILE}" ]; then
    echo "📦 Loading context from plugin: ${PLUGIN_NAME} (${CONTEXT_FILE})" >&2

    # Read the context file content
    CONTEXT_CONTENT=$(cat "${CLAUDE_PLUGIN_ROOT}/${CONTEXT_FILE}")

    # Output as JSON with additionalContext
    jq -n --arg context "$CONTEXT_CONTENT" '{
      "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": $context
      }
    }'
fi