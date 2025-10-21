#!/bin/bash
# ============================================================
# AI/ML Stack Aliases - NixOS Edition
# Apenas containers testados e funcionais
# ============================================================

# ============================================================
# 💬 OLLAMA (LLM Local) - FUNCIONA
# ============================================================

# Ollama standalone 
alias ollama-start='docker run -d --rm \
  --device=nvidia.com/gpu=all \
  --name ollama-gpu \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  ollama/ollama:latest'

alias ollama-stop='docker stop ollama-gpu 2>/dev/null || echo "Ollama not running"'

alias ollama-pull='docker exec ollama-gpu ollama pull'

alias ollama-list='docker exec ollama-gpu ollama list'

alias ollama-chat='docker exec -it ollama-gpu ollama run'

alias ollama-rm='docker exec ollama-gpu ollama rm'

alias ollama-logs='docker logs -f ollama-gpu'

# Setup modelos populares
alias ollama-setup='echo "📥 Downloading models..." && \
  docker exec ollama-gpu ollama pull llama3.2 && \
  docker exec ollama-gpu ollama pull mistral && \
  docker exec ollama-gpu ollama pull codellama && \
  docker exec ollama-gpu ollama pull llava && \
  echo "✓ Models ready!"'

# ============================================================
# 🗣️ WHISPER (Speech-to-Text) - FUNCIONA
# ============================================================

# Whisper standalone
alias whisper-start='docker run -d --rm \
  --device=nvidia.com/gpu=all \
  --name whisper-gpu \
  -p 9000:9000 \
  -v whisper-cache:/root/.cache \
  -e ASR_MODEL=base \
  -e ASR_ENGINE=faster_whisper \
  onerahmet/openai-whisper-asr-webservice:latest-gpu'

alias whisper-stop='docker stop whisper-gpu 2>/dev/null || echo "Whisper not running"'

alias whisper-logs='docker logs -f whisper-gpu'

# ============================================================
# 🎨 COMFYUI (Image Generation) - ALTERNATIVA QUE FUNCIONA
# ============================================================

# ComfyUI é mais estável que SD WebUI
alias comfy-start='docker run -d --rm \
  --device=nvidia.com/gpu=all \
  --name comfyui \
  -p 8188:8188 \
  -v comfyui-models:/comfyui/models \
  -v comfyui-output:/comfyui/output \
  --listen --enable-cors-header '*' \
  lecode/comfyui-docker:latest'

alias comfy-stop='docker stop comfyui 2>/dev/null || echo "ComfyUI not running"'

alias comfy-logs='docker logs -f comfyui'

alias comfy-open='xdg-open http://localhost:8188'

# ============================================================
# 🔬 JUPYTER ML (Dev Environment)
# ============================================================
# start jup-dev in ~/my-project directory, from /bin in home script.py 
alias jup-dev='jup-ml --port 8899 --workdir ~/my‑project'

# Stop jup-dev container
alias jup-dev-stop='docker stop jupyter-ml 2>/dev/null'

# See jup-dev logs
alias jup-dev-logs='docker logs -f jupyter-ml'

# Open the jup-dev Front End
alias jup-dev-open='xdg-open http://localhost:8888'

# For build it once with customs configurations
alias jup-build='docker build -t my‑jupyter‑ml'


# ==================================================================================================================================================================
# AI + ML + ALL (AI-ML-Front-End) 'Working in Progress "see the PATH environments for inputs and outputs declared in ai-ml-stack.sh aliase.sh, FOR comfy API call"'
# ==================================================================================================================================================================
# For use in kobold folder
alias kobold-chat-stheno="python koboldcpp.py L3-8B-Stheno-v3.2-Q4_K_S.gguf --sdmodel Anything-V3.0-pruned-fp16.safetensors 8080 --host localhost --gpulayers 40  --usecuda all --usecublas all --usehipblas"
alias kobold-chat-erebus="python koboldcpp.py KoboldAI_LLaMA2-13B-Erebus-v3-GGUF_llama2-13b-erebus-v3.Q4_K_M.gguf --sdmodel Anything-V3.0-pruned-fp16.safetensors 8080 --host localhost --gpulayers 40  --usecuda all --usecublas all --usehipblas"

# For go to kobold folder
alias kobold-ai="cd ~/base/ml/chat/koboldcpp"

# ============================================================
# 🧪 API TESTING
# ============================================================

test-ollama() {
    echo "🧪 Testing Ollama API..."
    curl -s http://localhost:11434/api/generate -d '{
      "model": "hf.co/KoboldAI/LLaMA2-13B-Erebus-v3-GGUF:Q4_K_M",
      "prompt": "Hey there",
      "stream": true
    }' | jq -r '.response' || echo "❌ Ollama not responding"
}

test-whisper() {
    echo "🧪 Testing Whisper API..."
    curl -s http://localhost:9000/health || echo "❌ Whisper not responding"
}

test-comfy() {
    echo "🧪 Testing ComfyUI API..."
    curl -s http://localhost:8188/ > /dev/null && echo "✓ ComfyUI responding" || echo "❌ ComfyUI not responding"
}

test-all() {
    echo "🔍 Testing all services..."
    echo ""
    test-ollama
    test-whisper
    test-comfy
}

# ============================================================
# 📊 MONITORING
# ============================================================

alias ai-ps='docker ps --filter "name=ollama\|whisper\|comfy\|jupyter-ml" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

alias ai-gpu='watch -n 1 "nvidia-smi && echo && docker ps --filter \"name=ollama\|whisper\|comfy\" --format \"table {{.Names}}\t{{.Status}}\""'

alias ai-stats='docker stats $(docker ps --filter "name=ollama\|whisper\|comfy\|jupyter-ml" -q) --no-stream'

# ============================================================
# 🎯 WORKFLOWS
# ============================================================

# Transcrever áudio
whisper-transcribe() {
    if [ -z "$1" ]; then
        echo "Usage: whisper-transcribe <audio_file>"
        return 1
    fi

    echo "🎤 Transcribing: $1"
    curl -s -F "audio_file=@$1" "http://localhost:9000/asr?task=transcribe" | jq -r '.text'
}

# Traduzir áudio para inglês
whisper-translate() {
    if [ -z "$1" ]; then
        echo "Usage: whisper-translate <audio_file>"
        return 1
    fi

    echo "🌍 Translating: $1"
    curl -s -F "audio_file=@$1" "http://localhost:9000/asr?task=translate" | jq -r '.text'
}

# Chat direto com Ollama
ollama-ask() {
    local model="${1:-hf.co/KoboldAI/LLaMA2-13B-Erebus-v3-GGUF:Q4_K_M}"
    local prompt="${2:-Hey there}"

    echo "💬 Asking $model: $prompt"
    curl -s http://localhost:11434/api/generate -d "{
      \"model\": \"$model\",
      \"prompt\": \"$prompt\",
      \"stream\": true
    }" | jq -r '.response'
}

# Pipeline: Audio → Transcript → LLM Summary
audio-to-summary() {
    if [ -z "$1" ]; then
        echo "Usage: audio-to-summary <audio_file>"
        return 1
    fi

    echo "🎤 Step 1: Transcribing audio..."
    local transcript=$(curl -s -F "audio_file=@$1" "http://localhost:9000/asr?task=transcribe" | jq -r '.text')

    echo "📝 Transcript: $transcript"
    echo ""
    echo "🤖 Step 2: Generating summary..."

    curl -s http://localhost:11434/api/generate -d "{
      \"model\": \"llama3.2\",
      \"prompt\": \"Summarize this in one sentence: $transcript\",
      \"stream\": false
    }" | jq -r '.response'
}

# ============================================================
# 🔧 UTILITIES
# ============================================================

ai-start-all() {
    echo "🚀 Starting AI stack..."
    ollama-start
    sleep 3
    whisper-start
    sleep 2
    comfy-start
    echo ""
    echo "✓ Stack started!"
    echo "  - Ollama:  http://localhost:11434"
    echo "  - Whisper: http://localhost:9000"
    echo "  - ComfyUI: http://localhost:8188"
}

ai-stop-all() {
    echo "🛑 Stopping AI stack..."
    ollama-stop
    whisper-stop
    comfy-stop
    jup-ml-stop
    echo "✓ Stack stopped!"
}

ai-cleanup() {
    echo "🧹 Cleaning up AI containers..."
    docker stop $(docker ps -q --filter "name=ollama\|whisper\|comfy\|jupyter-ml") 2>/dev/null
    docker system prune -f
    echo "✓ Cleanup complete!"
}

ai-reset() {
    echo "♻️  Resetting AI stack..."
    ai-stop-all
    sleep 2
    ai-start-all
}

# Backup de modelos do Ollama
ai-backup-ollama() {
    local backup_dir="$HOME/ai-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    echo "💾 Backing up Ollama models to: $backup_dir"
    docker run --rm \
        -v ollama-data:/data \
        -v "$backup_dir":/backup \
        alpine \
        tar czf /backup/ollama-models.tar.gz -C /data .

    echo "✓ Backup saved: $backup_dir/ollama-models.tar.gz"
}

# ============================================================
# 📚 HELP
# ============================================================

ai-help() {
    echo "🤖 AI/ML Stack - Commands (NixOS Edition)"
    echo ""
    echo "Stack Management:"
    echo "  ai-start-all       - Start all AI services"
    echo "  ai-stop-all        - Stop all AI services"
    echo "  ai-reset           - Restart all services"
    echo "  ai-cleanup         - Clean up containers and images"
    echo ""
    echo "Ollama (LLM):"
    echo "  ollama-start       - Start Ollama container"
    echo "  ollama-stop        - Stop Ollama"
    echo "  ollama-pull <m>    - Download model"
    echo "  ollama-list        - List installed models"
    echo "  ollama-chat <m>    - Interactive chat"
    echo "  ollama-setup       - Download popular models"
    echo "  ollama-ask <model> <prompt> - Quick query"
    echo ""
    echo "Whisper (STT):"
    echo "  whisper-start      - Start Whisper container"
    echo "  whisper-stop       - Stop Whisper"
    echo "  whisper-transcribe <file>  - Transcribe audio"
    echo "  whisper-translate <file>   - Translate to English"
    echo ""
    echo "ComfyUI (Image Gen):"
    echo "  comfy-start        - Start ComfyUI container"
    echo "  comfy-stop         - Stop ComfyUI"
    echo "  comfy-open         - Open WebUI in browser"
    echo ""
    echo "Jupyter ML:"
    echo "  jup-ml             - Start Jupyter ML container"
    echo "  jup-ml-stop        - Stop Jupyter"
    echo "  jup-open           - Open Jupyter in browser"
    echo ""
    echo "Testing:"
    echo "  test-ollama        - Test Ollama API"
    echo "  test-whisper       - Test Whisper API"
    echo "  test-comfy         - Test ComfyUI API"
    echo "  test-all           - Test all services"
    echo ""
    echo "Monitoring:"
    echo "  ai-ps              - List AI containers"
    echo "  ai-gpu             - GPU usage monitor"
    echo "  ai-stats           - Container resource usage"
    echo ""
    echo "Workflows:"
    echo "  audio-to-summary <audio_file>  - Audio → Text → Summary"
    echo ""
    echo "Utilities:"
    echo "  ai-backup-ollama   - Backup Ollama models"
    echo ""
    echo "🎯 Quick Start:"
    echo "  1. ai-start-all       # Start everything"
    echo "  2. ollama-setup       # Download models"
    echo "  3. test-all           # Verify services"
}

# ============================================================
# EXPORT FUNCTIONS
# ============================================================

export -f test-ollama
export -f test-whisper
export -f test-comfy
export -f test-all
export -f whisper-transcribe
export -f whisper-translate
export -f ollama-ask
export -f audio-to-summary
export -f ai-start-all
export -f ai-stop-all
export -f ai-cleanup
export -f ai-reset
export -f ai-backup-ollama
export -f ai-help

#echo "✓ AI/ML Stack aliases loaded! Type 'ai-help' for commands"
