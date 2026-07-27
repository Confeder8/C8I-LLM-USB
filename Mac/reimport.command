#!/bin/bash
# ===================================================
#  Portable AI - Re-Import All Models (Mac)
#  Re-imports all existing GGUF files into Ollama
#  without re-downloading anything.
# ===================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USB_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_DIR="$USB_ROOT/Shared"
OLLAMA_BIN="$SHARED_DIR/bin/ollama-darwin"
MODELS_DIR="$SHARED_DIR/models"
OLLAMA_DATA="$MODELS_DIR/ollama_data"
OLLAMA_RUNTIME="$SHARED_DIR/.ollama-runtime"

if [ ! -x "$OLLAMA_BIN" ]; then
    echo "ERROR: Ollama engine not found at $OLLAMA_BIN"
    echo "Run install.command first to download the engine."
    exit 1
fi

GGUF_COUNT=$(ls -1 "$MODELS_DIR"/*.gguf 2>/dev/null | wc -l)
if [ "$GGUF_COUNT" -eq 0 ]; then
    echo "ERROR: No GGUF model files found in $MODELS_DIR"
    exit 1
fi

echo "=========================================================="
echo "   PORTABLE AI - RE-IMPORT ALL MODELS (Mac)"
echo "=========================================================="
echo ""
echo "  Found $GGUF_COUNT GGUF files - no downloads needed."

mkdir -p "$OLLAMA_DATA" "$OLLAMA_RUNTIME/tmp"
export OLLAMA_MODELS="$OLLAMA_DATA"
export OLLAMA_HOME="$OLLAMA_RUNTIME"
export OLLAMA_TMPDIR="$OLLAMA_RUNTIME/tmp"
export OLLAMA_ORIGINS="*"
export OLLAMA_HOST="127.0.0.1:11434"

pkill -f "ollama-darwin" 2>/dev/null
sleep 2

echo "[1/3] Starting Ollama engine..."
HOME="$OLLAMA_RUNTIME" "$OLLAMA_BIN" serve > "$OLLAMA_RUNTIME/reimport.log" 2>&1 &
OLLAMA_PID=$!

OLLAMA_READY=false
for i in $(seq 1 30); do
    if curl -s http://127.0.0.1:11434/api/tags | grep -q '"models"'; then
        OLLAMA_READY=true
        echo "      Ollama ready after ${i}s"
        break
    fi
    sleep 1
done

if [ "$OLLAMA_READY" != true ]; then
    echo "ERROR: Ollama did not start."
    kill "$OLLAMA_PID" 2>/dev/null
    exit 1
fi

cd "$MODELS_DIR" || exit 1

echo ""
echo "[2/3] Importing models..."
TOTAL=$(ls -1 Modelfile-* 2>/dev/null | wc -l)
INDEX=0
SUCCESS=0
FAIL=0
WIDTH=50
START_TIME=$(date +%s)

bar() {
    local pct=$1 filled empty i
    filled=$((pct * WIDTH / 100))
    empty=$((WIDTH - filled))
    printf -v BAR '%*s' "$filled" ''
    printf -v SPACE '%*s' "$empty" ''
    BAR="${BAR// /#}"
    SPACE="${SPACE// / }"
    echo -ne "\r[$BAR$SPACE] $pct% ($((INDEX-1))/$TOTAL) OK=$SUCCESS FAIL=$FAIL"
}

for MF in Modelfile-*; do
    INDEX=$((INDEX + 1))
    MODEL_NAME="${MF#Modelfile-}"
    FROM_LINE=$(head -1 "$MF")
    GGUFFILE=$(echo "$FROM_LINE" | sed -n 's/^FROM \.\/\(.*\.gguf\)/\1/p')
    PCT=$(( (INDEX - 1) * 100 / TOTAL ))

    # Show ETA after first model
    if [ $INDEX -gt 1 ]; then
        NOW=$(date +%s)
        ELAPSED=$((NOW - START_TIME))
        AVG=$(echo "scale=1; $ELAPSED / ($INDEX - 1)" | bc 2>/dev/null)
        REMAINING=$(echo "scale=0; ($TOTAL - $INDEX + 1) * $AVG" | bc 2>/dev/null)
        ETA=$(printf '%02d:%02d:%02d' $((REMAINING/3600)) $(((REMAINING%3600)/60)) $((REMAINING%60)) 2>/dev/null)
        bar $PCT
        echo -ne " ETA $ETA"
    else
        bar $PCT
    fi
    echo ""

    if [ ! -f "$GGUFFILE" ]; then
        FAIL=$((FAIL + 1))
        echo "  $MODEL_NAME - GGUF MISSING, skipping"
        continue
    fi

    SIZE_STR=$(ls -lh "$GGUFFILE" 2>/dev/null | awk '{print $5}')
    [ -z "$SIZE_STR" ] && SIZE_STR="?GB"
    echo "  ($INDEX/$TOTAL) $MODEL_NAME ($SIZE_STR)..."
    CREATE_START=$(date +%s)
    CREATE_OUTPUT=$("$OLLAMA_BIN" create "$MODEL_NAME" -f "$MF" 2>&1)
    CREATE_EXIT=$?
    CREATE_END=$(date +%s)
    CT=$(printf '%d:%02d' $(((CREATE_END-CREATE_START)/60)) $(((CREATE_END-CREATE_START)%60)))
    if [ $CREATE_EXIT -eq 0 ]; then
        SUCCESS=$((SUCCESS + 1))
        echo -e "      imported in $CT"
    else
        FAIL=$((FAIL + 1))
        echo -e "      \e[31mFAILED after $CT: $CREATE_OUTPUT\e[0m"
    fi
done

# Final 100% bar
bar 100
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DUR_STR=$(printf '%02d:%02d:%02d' $((DURATION/3600)) $(((DURATION%3600)/60)) $((DURATION%60)))
echo ""
echo ""
echo -e "  Results: \e[32m$SUCCESS imported\e[0m, \e[31m$FAIL failed\e[0m in $DUR_STR"

echo ""
echo "[3/3] Cleaning up..."
kill "$OLLAMA_PID" 2>/dev/null
wait "$OLLAMA_PID" 2>/dev/null

echo ""
echo "=========================================================="
echo "   RE-IMPORT COMPLETE!"
echo "=========================================================="
echo ""
echo "  Start your AI: open Mac/start.command"
echo ""
