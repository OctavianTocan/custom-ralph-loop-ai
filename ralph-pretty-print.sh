#!/bin/bash
# ralph-pretty-print.sh
# Pretty-prints Claude CLI stream-json output with emojis and formatting
# Reads newline-delimited JSON from stdin, outputs formatted text to stdout

# Colors (default enabled)
ENABLE_COLOR=1
DIM='\033[2m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Truncation limits
THINKING_LIMIT=200
RESULT_LIMIT=500

# Show usage
show_usage() {
  cat << EOF
Usage: ralph-pretty-print.sh [OPTIONS]

Pretty-prints Claude CLI stream-json output with emojis and formatting.

OPTIONS:
  --no-color          Disable ANSI color codes
  --log-file FILE     Write raw JSON to log file (not implemented)
  --help              Show this help message

DESCRIPTION:
  Reads newline-delimited JSON from stdin (stream-json format from claude CLI).
  Outputs human-readable formatted text with emojis and colors.

EVENT TYPES:
  🤔 Thinking        - Agent's internal reasoning (truncated to 200 chars)
  🔧 Tool Use        - Tool calls (Read, Edit, Bash, etc.)
  ✅ Tool Result     - Tool execution results (truncated to 500 chars)
  💬 Text Output     - Agent's text responses (full output)

EXAMPLES:
  # Pretty-print claude output
  claude -p --output-format stream-json | ralph-pretty-print.sh

  # Disable colors
  claude -p --output-format stream-json | ralph-pretty-print.sh --no-color

  # From file
  cat session.jsonl | ralph-pretty-print.sh

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-color)
      ENABLE_COLOR=0
      shift
      ;;
    --log-file)
      LOG_FILE="$2"
      shift 2
      ;;
    --help|-h)
      show_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_usage >&2
      exit 1
      ;;
  esac
done

# Disable colors if requested
if [[ $ENABLE_COLOR -eq 0 ]]; then
  DIM=""
  CYAN=""
  GREEN=""
  YELLOW=""
  NC=""
fi

# Truncate string to specified length
truncate_string() {
  local str="$1"
  local limit="$2"
  if [[ ${#str} -gt $limit ]]; then
    echo "${str:0:$limit}..."
  else
    echo "$str"
  fi
}

# Check if jq is available
HAS_JQ=0
if command -v jq &> /dev/null; then
  HAS_JQ=1
fi

# Process each line of JSONL
while IFS= read -r line; do
  # Skip empty lines
  [[ -z "$line" ]] && continue

  # Try to parse JSON
  if [[ $HAS_JQ -eq 1 ]]; then
    # Use jq for parsing
    if ! echo "$line" | jq -e . &> /dev/null; then
      # Invalid JSON, skip with warning
      continue
    fi

    # Extract event type
    EVENT_TYPE=$(echo "$line" | jq -r '.type // empty')

    if [[ "$EVENT_TYPE" == "assistant" ]]; then
      # Parse assistant message content
      CONTENT_TYPE=$(echo "$line" | jq -r '.message.content[0].type // empty')

      case "$CONTENT_TYPE" in
        thinking)
          # Extract thinking text
          THINKING=$(echo "$line" | jq -r '.message.content[0].thinking // empty')
          if [[ -n "$THINKING" ]]; then
            TRUNCATED=$(truncate_string "$THINKING" $THINKING_LIMIT)
            echo -e "${DIM}🤔 ${TRUNCATED}${NC}"
          fi
          ;;

        tool_use)
          # Extract tool name and input
          TOOL_NAME=$(echo "$line" | jq -r '.message.content[0].name // empty')
          TOOL_INPUT=$(echo "$line" | jq -r '.message.content[0].input // empty')

          if [[ -n "$TOOL_NAME" ]]; then
            # Try to extract file path if present
            FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || echo "")
            COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null || echo "")

            if [[ -n "$FILE_PATH" ]]; then
              echo -e "${CYAN}🔧 ${TOOL_NAME}: ${FILE_PATH}${NC}"
            elif [[ -n "$COMMAND" ]]; then
              echo -e "${CYAN}🔧 ${TOOL_NAME}: ${COMMAND}${NC}"
            else
              echo -e "${CYAN}🔧 ${TOOL_NAME}${NC}"
            fi
          fi
          ;;

        text)
          # Extract text content
          TEXT=$(echo "$line" | jq -r '.message.content[0].text // empty')
          if [[ -n "$TEXT" ]]; then
            echo -e "${GREEN}💬 ${TEXT}${NC}"
          fi
          ;;

        *)
          # Unknown content type, skip silently
          ;;
      esac

    elif [[ "$EVENT_TYPE" == "result" ]]; then
      # Parse result event
      RESULT=$(echo "$line" | jq -r '.result // empty')
      if [[ -n "$RESULT" ]]; then
        TRUNCATED=$(truncate_string "$RESULT" $RESULT_LIMIT)
        echo -e "${YELLOW}✅ ${TRUNCATED}${NC}"
      fi
    fi

  else
    # Fallback parsing without jq (basic grep/sed)
    # Check for thinking
    if echo "$line" | grep -q '"type":"thinking"'; then
      THINKING=$(echo "$line" | sed -n 's/.*"thinking":"\([^"]*\)".*/\1/p')
      if [[ -n "$THINKING" ]]; then
        TRUNCATED=$(truncate_string "$THINKING" $THINKING_LIMIT)
        echo -e "${DIM}🤔 ${TRUNCATED}${NC}"
      fi
    # Check for tool_use
    elif echo "$line" | grep -q '"type":"tool_use"'; then
      TOOL_NAME=$(echo "$line" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
      if [[ -n "$TOOL_NAME" ]]; then
        echo -e "${CYAN}🔧 ${TOOL_NAME}${NC}"
      fi
    # Check for text
    elif echo "$line" | grep -q '"type":"text"'; then
      TEXT=$(echo "$line" | sed -n 's/.*"text":"\([^"]*\)".*/\1/p')
      if [[ -n "$TEXT" ]]; then
        echo -e "${GREEN}💬 ${TEXT}${NC}"
      fi
    # Check for result
    elif echo "$line" | grep -q '"type":"result"'; then
      RESULT=$(echo "$line" | sed -n 's/.*"result":"\([^"]*\)".*/\1/p')
      if [[ -n "$RESULT" ]]; then
        TRUNCATED=$(truncate_string "$RESULT" $RESULT_LIMIT)
        echo -e "${YELLOW}✅ ${TRUNCATED}${NC}"
      fi
    fi
  fi
done

exit 0
