#!/bin/bash
# Cursor Agent runner for Ralph
# Usage: run-cursor.sh <prompt-file> <log-file> [session-dir] [model]

set -e

PROMPT_FILE="$1"
LOG_FILE="$2"
SESSION_DIR="$3"
MODEL="$4"

[[ -z "$PROMPT_FILE" || -z "$LOG_FILE" ]] && { echo "Usage: run-cursor.sh <prompt-file> <log-file> [session-dir] [model]" >&2; exit 1; }
command -v cursor &> /dev/null || { echo "ERROR: Cursor CLI not found!" >&2; exit 1; }

PROMPT_CONTENT=$(cat "$PROMPT_FILE")
CMD_ARGS=("agent" "-p" "--output-format" "stream-json" "--stream-partial-output" "--force" "--approve-mcps")

[[ -n "$SESSION_DIR" ]] && CMD_ARGS+=("--workspace" "$(cd "$SESSION_DIR" && cd ../../../.. && pwd)")
[[ -n "$MODEL" ]] && CMD_ARGS+=("--model" "$MODEL")
CMD_ARGS+=("$PROMPT_CONTENT")

# Python parser
PARSER=$(mktemp)
cat > "$PARSER" << 'PYEOF'
import sys, json, re, os

sys.stdout.reconfigure(line_buffering=True)

LOG = os.environ.get('RALPH_LOG_FILE', '')
logf = open(LOG, 'a') if LOG else None

# ANSI codes for terminal
D, N, G, Y, C, M = '\033[2m', '\033[0m', '\033[0;32m', '\033[1;33m', '\033[0;36m', '\033[0;35m'

def short(s, n=70): return (s[:n-3] + '...') if len(s) > n else s
def base(p): return p.rsplit('/', 1)[-1] if p else ''

def clean(t):
    t = re.sub(r'\}\]\},"session_id":"[^"]*","timestamp_ms:\d+\}', '', t)
    t = re.sub(r'\}\]\},"session_id":"[^"]*","model_call_id":"[^"]*","timestamp_ms:\d+\}', '', t)
    t = re.sub(r'"\]\},"[a-z_]+":"[^"]*"[,\}]', '', t)
    t = re.sub(r'\}\]\}[,\s]*$', '', t)
    return t.strip()

def emit(term_str, log_str, nl=True):
    """Write colored to terminal, plain to log"""
    e = '\n' if nl else ''
    sys.stdout.write(term_str + e)
    sys.stdout.flush()
    if logf:
        logf.write(log_str + e)
        logf.flush()

buf = []
was_tool = False

for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
    except: continue

    typ = d.get('type', '')
    sub = d.get('subtype', '')
    tc = d.get('tool_call', {})

    if typ == 'text':
        txt = clean(d.get('text', ''))
        if txt:
            buf.append(txt)
            was_tool = False

    elif sub == 'started':
        if buf:
            msg = clean(''.join(buf))
            if msg:
                if was_tool: emit('', '')
                emit(msg, msg)
            buf = []

        # Build colored (for terminal) and plain (for log) versions
        term = plain = ''
        if 'readToolCall' in tc:
            b = base(tc['readToolCall'].get('args', {}).get('path', ''))
            term = f"{D}[read]{N} {C}{b}{N}"
            plain = f"[read] {b}"
        elif 'writeToolCall' in tc:
            b = base(tc['writeToolCall'].get('args', {}).get('path', ''))
            term = f"{D}[write]{N} {G}{b}{N}"
            plain = f"[write] {b}"
        elif 'editToolCall' in tc:
            b = base(tc['editToolCall'].get('args', {}).get('path', ''))
            term = f"{D}[edit]{N} {G}{b}{N}"
            plain = f"[edit] {b}"
        elif 'shellToolCall' in tc:
            s = short(tc['shellToolCall'].get('args', {}).get('command', ''))
            term = f"{D}[run]{N} {Y}{s}{N}"
            plain = f"[run] {s}"
        elif 'semSearchToolCall' in tc:
            s = short(tc['semSearchToolCall'].get('args', {}).get('query', ''), 55)
            term = f"{D}[search]{N} {M}{s}{N}"
            plain = f"[search] {s}"
        elif 'grepToolCall' in tc:
            s = short(tc['grepToolCall'].get('args', {}).get('pattern', ''), 45)
            term = f"{D}[grep]{N} {M}{s}{N}"
            plain = f"[grep] {s}"
        elif 'listDirToolCall' in tc:
            b = base(tc['listDirToolCall'].get('args', {}).get('path', ''))
            term = f"{D}[ls]{N} {C}{b}{N}"
            plain = f"[ls] {b}"

        if term:
            emit(term, plain, nl=False)
            was_tool = True

    elif sub == 'completed':
        for k in tc:
            res = tc[k].get('result', {})
            suc = res.get('success', {})
            if 'exitCode' in suc:
                ok = suc['exitCode'] == 0
                emit(f" {G}ok{N}" if ok else f" {Y}FAIL{N}", " ok" if ok else " FAIL")
                break
            elif suc:
                emit(f" {G}ok{N}", " ok")
                break

if buf:
    msg = clean(''.join(buf))
    if msg: emit(msg, msg)

if logf: logf.close()
PYEOF

# Enhanced separator
echo ""
echo -e "\033[0;36m╔════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[0;36m║\033[0m                    \033[1mStarting Agent Iteration\033[0m                    \033[0;36m║\033[0m"
echo -e "\033[0;36m╚════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

export PYTHONUNBUFFERED=1
export RALPH_LOG_FILE="$LOG_FILE"
stdbuf -oL cursor "${CMD_ARGS[@]}" 2>&1 | python3 -u "$PARSER" || true
rm -f "$PARSER"

echo ""
echo -e "\033[0;36m╔════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[0;36m║\033[0m                    \033[1mIteration Complete\033[0m                        \033[0;36m║\033[0m"
echo -e "\033[0;36m╚════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
