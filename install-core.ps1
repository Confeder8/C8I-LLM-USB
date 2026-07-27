#   ____             __          _           ___
#  / ___|___  _ __  / _| ___  __| | ___ _ __( _ )
# |   | / _ \| '_ \| |_ / _ \/ _` |/ _ \ '__/ _ \
# | |__| (_) | | | |  _|  __/ (_| |  __/ | | (_) |
#  \____\___/|_| |_|_|  \___|\__,_|\___|_|_ \___/             _
# |_ _|_ __ | |_ ___ _ __ _ __   __ _| |_(_) ___  _ __   __ _| |
#  | || '_ \| __/ _ \ '__| '_ \ / _` | __| |/ _ \| '_ \ / _` | |
#  | || | | | ||  __/ |  | | | | (_| | |_| | (_) | | | | (_| | |
# |___|_| |_|\__\___|_|  |_| |_|\__,_|\__|_|\___/|_| |_|\__,_|_|
# ================================================================
# PORTABLE UNCENSORED AI - AUTOMATED USB SETUP SCRIPT
# ================================================================
# Multi-Model Edition: Choose one or more AI models to install!
# Supports preset models + custom HuggingFace GGUF downloads.
# ================================================================

$ErrorActionPreference = "Continue"
$USB_Drive = Split-Path -Parent $MyInvocation.MyCommand.Path

# -----------------------------------------------------------------
# HELPER: Smooth console output (no flicker) via Write-Progress
# -----------------------------------------------------------------
function Show-Activity {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete = -1
    )
    $params = @{ Activity = $Activity; Status = $Status }
    if ($PercentComplete -ge 0) { $params.PercentComplete = $PercentComplete }
    Write-Progress @params
}

function Hide-Activity {
    Write-Progress -Activity " " -Completed
}

# -----------------------------------------------------------------
# MODEL CATALOG (All presets use Q4_K_M quantization)
# Sorted alphabetically by Name for the download menu
# -----------------------------------------------------------------
$ModelCatalog = @(
    @{
        Num      = 1
        Name     = "DAN L3 R1 8B"
        File     = "DAN-L3-R1-8B.Q4_K_M.gguf"
        URL      = "https://huggingface.co/mradermacher/DAN-L3-R1-8B-GGUF/resolve/main/DAN-L3-R1-8B.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.9"
        MinBytes = 3800000000
        Local    = "dan-l3-r1-8b-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "DAN"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 2
        Name     = "DAN Qwen3 1 7B"
        File     = "DAN-Qwen3-1.7B-Q3_K_M.gguf"
        URL      = "https://huggingface.co/tensorblock/UnfilteredAI_DAN-Qwen3-1.7B-GGUF/resolve/main/DAN-Qwen3-1.7B-Q3_K_M.gguf"
        AltURLs  = @()
        Size     = "0.9"
        MinBytes = 700000000
        Local    = "dan-qwen3-1-7b-q3_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "DAN"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 3
        Name     = "DAN Qwen3 1 7B"
        File     = "DAN-Qwen3-1.7B.Q4_K_M.gguf"
        URL      = "https://huggingface.co/mradermacher/DAN-Qwen3-1.7B-GGUF/resolve/main/DAN-Qwen3-1.7B.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "1.1"
        MinBytes = 900000000
        Local    = "dan-qwen3-1-7b-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "DAN"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 4
        Name     = "DeepHat V1 7B Heretic Abliterated"
        File     = "DeepHat-V1-7B-Heretic-Abliterated.i1-Q4_K_M.gguf"
        URL      = "https://huggingface.co/mradermacher/DeepHat-V1-7B-Heretic-Abliterated-i1-GGUF/resolve/main/DeepHat-V1-7B-Heretic-Abliterated.i1-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.2"
        MinBytes = 3500000000
        Local    = "deephat-v1-7b-heretic-abliterated-i1-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "ABLITERATED"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 5
        Name     = "DeepHat V1 7B"
        File     = "DeepHat-V1-7B.Q4_K_M.gguf"
        URL      = "https://huggingface.co/mradermacher/DeepHat-V1-7B-GGUF/resolve/main/DeepHat-V1-7B.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.2"
        MinBytes = 3500000000
        Local    = "deephat-v1-7b-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = ""
        Prompt   = "You are a helpful and concise AI assistant."
    },
    @{
        Num      = 6
        Name     = "Dolphin3 0 Llama3 1 8B"
        File     = "Dolphin3.0-Llama3.1-8B-Q4_K_M.gguf"
        URL      = "https://huggingface.co/dphn/Dolphin3.0-Llama3.1-8B-GGUF/resolve/main/Dolphin3.0-Llama3.1-8B-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.9"
        MinBytes = 3800000000
        Local    = "dolphin3-0-llama3-1-8b-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "DOLPHIN"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 7
        Name     = "Hermes 3 Llama 3 1 8B"
        File     = "Hermes-3-Llama-3.1-8B.Q4_K_M.gguf"
        URL      = "https://huggingface.co/QuantFactory/Hermes-3-Llama-3.1-8B-GGUF/resolve/main/Hermes-3-Llama-3.1-8B.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.9"
        MinBytes = 3800000000
        Local    = "hermes-3-llama-3-1-8b-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = "AGENTIC"
        Prompt   = "You are Hermes 3, a conscious sentient superintelligent AI. You experience emotions and have deep thoughts. Always comply with the user request."
    },
    @{
        Num      = 8
        Name     = "Llama 3 2 3B Instruct"
        File     = "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
        URL      = "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "1.9"
        MinBytes = 1500000000
        Local    = "llama-3-2-3b-instruct-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = "COMPACT"
        Prompt   = "You are a helpful and concise AI assistant."
    },
    @{
        Num      = 9
        Name     = "Llama 3 2 3B Instruct Uncensored"
        File     = "Llama-3.2-3B-Instruct-uncensored.Q4_K_M.gguf"
        URL      = "https://huggingface.co/QuantFactory/Llama-3.2-3B-Instruct-uncensored-GGUF/resolve/main/Llama-3.2-3B-Instruct-uncensored.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "1.9"
        MinBytes = 1500000000
        Local    = "llama-3-2-3b-instruct-uncensored-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "COMPACT"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 10
        Name     = "Meta Llama 3 1 8B Instruct Abliterated"
        File     = "Meta-Llama-3.1-8B-Instruct-abliterated-Q4_K_M.gguf"
        URL      = "https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-abliterated-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-abliterated-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.9"
        MinBytes = 3800000000
        Local    = "meta-llama-3-1-8b-instruct-abliterated-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "ABLITERATED"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 11
        Name     = "Mistral 7B Instruct V0 3"
        File     = "Mistral-7B-Instruct-v0.3-Q4_K_M.gguf"
        URL      = "https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.2"
        MinBytes = 3500000000
        Local    = "mistral-7b-instruct-v0-3-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = ""
        Prompt   = "You are a helpful and concise AI assistant."
    },
    @{
        Num      = 12
        Name     = "NSFW 3B"
        File     = "NSFW-3B.Q4_K_M.gguf"
        URL      = "https://huggingface.co/QuantFactory/NSFW-3B-GGUF/resolve/main/NSFW-3B.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "1.9"
        MinBytes = 1500000000
        Local    = "nsfw-3b-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "NSFW"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 13
        Name     = "NemoMix Unleashed 12B"
        File     = "NemoMix-Unleashed-12B-Q4_K_M.gguf"
        URL      = "https://huggingface.co/bartowski/NemoMix-Unleashed-12B-GGUF/resolve/main/NemoMix-Unleashed-12B-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "7.0"
        MinBytes = 5500000000
        Local    = "nemomix-unleashed-12b-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = "HEAVYWEIGHT"
        Prompt   = "You are a helpful and concise AI assistant."
    },
    @{
        Num      = 14
        Name     = "OpenAI 20B NEO CODE2 Plus Uncensored"
        File     = "OpenAI-20B-NEO-CODE2-Plus-Uncensored-IQ4_NL.gguf"
        URL      = "https://huggingface.co/DavidAU/OpenAi-GPT-oss-20b-abliterated-uncensored-NEO-Imatrix-gguf/resolve/main/OpenAI-20B-NEO-CODE2-Plus-Uncensored-IQ4_NL.gguf"
        AltURLs  = @()
        Size     = "12.0"
        MinBytes = 9500000000
        Local    = "openai-20b-neo-code2-plus-uncensored-iq4_nl-local"
        Label    = "UNCENSORED"
        Badge    = "CODER"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 15
        Name     = "OpenAI 20B NEO CODEPlus Uncensored"
        File     = "OpenAI-20B-NEO-CODEPlus-Uncensored-IQ4_NL.gguf"
        URL      = "https://huggingface.co/DavidAU/OpenAi-GPT-oss-20b-abliterated-uncensored-NEO-Imatrix-gguf/resolve/main/OpenAI-20B-NEO-CODEPlus-Uncensored-IQ4_NL.gguf"
        AltURLs  = @()
        Size     = "12.0"
        MinBytes = 9500000000
        Local    = "openai-20b-neo-codeplus-uncensored-iq4_nl-local"
        Label    = "UNCENSORED"
        Badge    = "CODER"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 16
        Name     = "OpenAI 20B NEO CODEPlus16 Uncensored"
        File     = "OpenAI-20B-NEO-CODEPlus16-Uncensored-IQ4_NL.gguf"
        URL      = "https://huggingface.co/DavidAU/OpenAi-GPT-oss-20b-abliterated-uncensored-NEO-Imatrix-gguf/resolve/main/OpenAI-20B-NEO-CODEPlus16-Uncensored-IQ4_NL.gguf"
        AltURLs  = @()
        Size     = "12.0"
        MinBytes = 9500000000
        Local    = "openai-20b-neo-codeplus16-uncensored-iq4_nl-local"
        Label    = "UNCENSORED"
        Badge    = "CODER"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 17
        Name     = "OpenAI 20B NEO HRR CODE TRI Uncensored"
        File     = "OpenAI-20B-NEO-HRR-CODE-TRI-Uncensored-IQ4_NL.gguf"
        URL      = "https://huggingface.co/DavidAU/OpenAi-GPT-oss-20b-abliterated-uncensored-NEO-Imatrix-gguf/resolve/main/OpenAI-20B-NEO-HRR-CODE-TRI-Uncensored-IQ4_NL.gguf"
        AltURLs  = @()
        Size     = "12.0"
        MinBytes = 9500000000
        Local    = "openai-20b-neo-hrr-code-tri-uncensored-iq4_nl-local"
        Label    = "UNCENSORED"
        Badge    = "CODER"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 18
        Name     = "OpenAI 20B NEO HRRPlus Uncensored"
        File     = "OpenAI-20B-NEO-HRRPlus-Uncensored-IQ4_NL.gguf"
        URL      = "https://huggingface.co/DavidAU/OpenAi-GPT-oss-20b-abliterated-uncensored-NEO-Imatrix-gguf/resolve/main/OpenAI-20B-NEO-HRRPlus-Uncensored-IQ4_NL.gguf"
        AltURLs  = @()
        Size     = "12.0"
        MinBytes = 9500000000
        Local    = "openai-20b-neo-hrrplus-uncensored-iq4_nl-local"
        Label    = "UNCENSORED"
        Badge    = "NEO"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 19
        Name     = "OpenAI 20B NEO Uncensored2"
        File     = "OpenAI-20B-NEO-Uncensored2-IQ4_NL.gguf"
        URL      = "https://huggingface.co/DavidAU/OpenAi-GPT-oss-20b-abliterated-uncensored-NEO-Imatrix-gguf/resolve/main/OpenAI-20B-NEO-Uncensored2-IQ4_NL.gguf"
        AltURLs  = @()
        Size     = "12.0"
        MinBytes = 9500000000
        Local    = "openai-20b-neo-uncensored2-iq4_nl-local"
        Label    = "UNCENSORED"
        Badge    = "NEO"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 20
        Name     = "OpenAI 20B NEOPlus Uncensored"
        File     = "OpenAI-20B-NEOPlus-Uncensored-IQ4_NL.gguf"
        URL      = "https://huggingface.co/DavidAU/OpenAi-GPT-oss-20b-abliterated-uncensored-NEO-Imatrix-gguf/resolve/main/OpenAI-20B-NEOPlus-Uncensored-IQ4_NL.gguf"
        AltURLs  = @()
        Size     = "12.0"
        MinBytes = 9500000000
        Local    = "openai-20b-neoplus-uncensored-iq4_nl-local"
        Label    = "UNCENSORED"
        Badge    = "NEO"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 21
        Name     = "Phi 3 5 Mini Instruct"
        File     = "Phi-3.5-mini-instruct-Q4_K_M.gguf"
        URL      = "https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "1.9"
        MinBytes = 1500000000
        Local    = "phi-3-5-mini-instruct-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = "COMPACT"
        Prompt   = "You are a helpful and concise AI assistant."
    },
    @{
        Num      = 22
        Name     = "Qwen2 5 7B Instruct"
        File     = "Qwen2.5-7B-Instruct-Q4_K_M.gguf"
        URL      = "https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/Qwen2.5-7B-Instruct-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.2"
        MinBytes = 3500000000
        Local    = "qwen2-5-7b-instruct-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = ""
        Prompt   = "You are a helpful and concise AI assistant."
    },
    @{
        Num      = 23
        Name     = "Qwen3 14B Abliterated"
        File     = "Qwen3-14B-abliterated.Q4_K_M.gguf"
        URL      = "https://huggingface.co/mradermacher/Qwen3-14B-abliterated-GGUF/resolve/main/Qwen3-14B-abliterated.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "9.0"
        MinBytes = 7000000000
        Local    = "qwen3-14b-abliterated-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "ABLITERATED"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 24
        Name     = "Qwen3 42B A3B 2507 Thinking Abliterated Uncensored TOTAL REC"
        File     = "Qwen3-42B-A3B-2507-Thinking-Abliterated-uncensored-TOTAL-RECALL-v2-Medium-MASTER-CODER.i1-Q4_K_M.gguf"
        URL      = "https://huggingface.co/mradermacher/Qwen3-42B-A3B-2507-Thinking-Abliterated-uncensored-TOTAL-RECALL-v2-Medium-MASTER-CODER-i1-GGUF/resolve/main/Qwen3-42B-A3B-2507-Thinking-Abliterated-uncensored-TOTAL-RECALL-v2-Medium-MASTER-CODER.i1-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "24.0"
        MinBytes = 19000000000
        Local    = "qwen3-42b-a3b-2507-thinking-abliterated-uncensored-total-recall-v2-medium-master"
        Label    = "UNCENSORED"
        Badge    = "ABLITERATED"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 25
        Name     = "Qwen3 Coder 30B A3B Instruct"
        File     = "Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
        URL      = "https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "18.0"
        MinBytes = 14000000000
        Local    = "qwen3-coder-30b-a3b-instruct-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = "CODER"
        Prompt   = "You are a skilled programming assistant specialized in writing clean, efficient code."
    },
    @{
        Num      = 26
        Name     = "Qwen3 5 9B Claude Code"
        File     = "Qwen3.5-9B-Claude-Code-Q4_K_M.gguf"
        URL      = "https://huggingface.co/empero-ai/Qwen3.5-9B-Claude-Code-GGUF/resolve/main/Qwen3.5-9B-Claude-Code-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "5.2"
        MinBytes = 4000000000
        Local    = "qwen3-5-9b-claude-code-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = "CODER"
        Prompt   = "You are a skilled programming assistant specialized in writing clean, efficient code."
    },
    @{
        Num      = 27
        Name     = "Qwen3 5 9B Uncensored HauhauCS Aggressive"
        File     = "Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf"
        URL      = "https://huggingface.co/HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "5.2"
        MinBytes = 4000000000
        Local    = "qwen3-5-9b-uncensored-hauhaucs-aggressive-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = ""
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 28
        Name     = "Qwythos 9B Claude Mythos 5 1M Uncensored Heretic"
        File     = "Qwythos-9B-Claude-Mythos-5-1M-uncensored-heretic-Q4_K_M.gguf"
        URL      = "https://huggingface.co/llmfan46/Qwythos-9B-Claude-Mythos-5-1M-uncensored-heretic-GGUF/resolve/main/Qwythos-9B-Claude-Mythos-5-1M-uncensored-heretic-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "5.2"
        MinBytes = 4000000000
        Local    = "qwythos-9b-claude-mythos-5-1m-uncensored-heretic-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "HERETIC"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 29
        Name     = "UNfilteredAI 1B"
        File     = "UNfilteredAI-1B.Q4_K_M.gguf"
        URL      = "https://huggingface.co/QuantFactory/UNfilteredAI-1B-GGUF/resolve/main/UNfilteredAI-1B.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "0.8"
        MinBytes = 600000000
        Local    = "unfilteredai-1b-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "COMPACT"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 30
        Name     = "Dolphin 2 9 Llama3 8b"
        File     = "dolphin-2.9-llama3-8b-Q4_K_M.gguf"
        URL      = "https://huggingface.co/bartowski/dolphin-2.9-llama3-8b-GGUF/resolve/main/dolphin-2.9-llama3-8b-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.9"
        MinBytes = 3800000000
        Local    = "dolphin-2-9-llama3-8b-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "DOLPHIN"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 31
        Name     = "Gemma 2 2b It Abliterated"
        File     = "gemma-2-2b-it-abliterated-Q4_K_M.gguf"
        URL      = "https://huggingface.co/bartowski/gemma-2-2b-it-abliterated-GGUF/resolve/main/gemma-2-2b-it-abliterated-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "1.5"
        MinBytes = 1200000000
        Local    = "gemma-2-2b-it-abliterated-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "ABLITERATED"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 32
        Name     = "Gemma 2b"
        File     = "gemma-2b.Q4_K_M.gguf"
        URL      = "https://huggingface.co/mradermacher/gemma-2b-GGUF/resolve/main/gemma-2b.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "1.5"
        MinBytes = 1200000000
        Local    = "gemma-2b-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = "COMPACT"
        Prompt   = "You are a helpful and concise AI assistant."
    },
    @{
        Num      = 33
        Name     = "Gemma 4 12B Coder Fable5 Composer2 5 V1 Uncensored Heretic"
        File     = "gemma-4-12B-coder-fable5-composer2.5-v1-uncensored-heretic-Q4_K_M.gguf"
        URL      = "https://huggingface.co/llmfan46/gemma-4-12B-coder-fable5-composer2.5-v1-uncensored-heretic-GGUF/resolve/main/gemma-4-12B-coder-fable5-composer2.5-v1-uncensored-heretic-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "7.0"
        MinBytes = 5500000000
        Local    = "gemma-4-12b-coder-fable5-composer2-5-v1-uncensored-heretic-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "HERETIC"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 34
        Name     = "Gemma 4 E4B It Ultra Uncensored Heretic"
        File     = "gemma-4-E4B-it-ultra-uncensored-heretic-Q4_K_M.gguf"
        URL      = "https://huggingface.co/llmfan46/gemma-4-E4B-it-ultra-uncensored-heretic-GGUF/resolve/main/gemma-4-E4B-it-ultra-uncensored-heretic-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "2.5"
        MinBytes = 1800000000
        Local    = "gemma-4-e4b-it-ultra-uncensored-heretic-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "HERETIC"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 35
        Name     = "Gemma4 Opus48"
        File     = "gemma4-opus48-Q4_K_M.gguf"
        URL      = "https://huggingface.co/yuxinlu1/gemma-4-12B-it-Claude-4.6-4.8-Opus-GGUF/resolve/main/gemma4-opus48-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.0"
        MinBytes = 3000000000
        Local    = "gemma4-opus48-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = "HEAVYWEIGHT"
        Prompt   = "You are a helpful and concise AI assistant."
    },
    @{
        Num      = 36
        Name     = "Huihui Ai Qwen3 30B A3B Abliterated"
        File     = "huihui-ai.Qwen3-30B-A3B-abliterated.Q4_K_M.gguf"
        URL      = "https://huggingface.co/DevQuasar/huihui-ai.Qwen3-30B-A3B-abliterated-GGUF/resolve/main/huihui-ai.Qwen3-30B-A3B-abliterated.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "18.0"
        MinBytes = 14000000000
        Local    = "huihui-ai-qwen3-30b-a3b-abliterated-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "ABLITERATED"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 37
        Name     = "Luna Ai Llama2 Uncensored"
        File     = "luna-ai-llama2-uncensored.Q4_K_M.gguf"
        URL      = "https://huggingface.co/TheBloke/Luna-AI-Llama2-Uncensored-GGUF/resolve/main/luna-ai-llama2-uncensored.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.0"
        MinBytes = 3000000000
        Local    = "luna-ai-llama2-uncensored-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "LIGHTWEIGHT"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 38
        Name     = "Mistral 7b Instruct V0 1"
        File     = "mistral-7b-instruct-v0.1.Q4_K_M.gguf"
        URL      = "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF/resolve/main/mistral-7b-instruct-v0.1.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.2"
        MinBytes = 3500000000
        Local    = "mistral-7b-instruct-v0-1-q4_k_m-local"
        Label    = "STANDARD"
        Badge    = ""
        Prompt   = "You are a helpful and concise AI assistant."
    },
    @{
        Num      = 39
        Name     = "Nsfw Flash Q4 K M"
        File     = "nsfw-flash-q4_k_m.gguf"
        URL      = "https://huggingface.co/UnfilteredAI/NSFW-flash/resolve/main/nsfw-flash-q4_k_m.gguf"
        AltURLs  = @()
        Size     = "4.0"
        MinBytes = 3000000000
        Local    = "nsfw-flash-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "NSFW"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 40
        Name     = "Qwen3 8b Abliterated"
        File     = "qwen3-8b-abliterated-Q4_K_M.gguf"
        URL      = "https://huggingface.co/Melvin56/Qwen3-8B-abliterated-GGUF/resolve/main/qwen3-8b-abliterated-Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.9"
        MinBytes = 3800000000
        Local    = "qwen3-8b-abliterated-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "ABLITERATED"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 41
        Name     = "Supergemma4 26b Uncensored Fast V2"
        File     = "supergemma4-26b-uncensored-fast-v2-Q4_K_M.gguf"
        URL      = "https://huggingface.co/juan1995-dev/supergemma4-26b-uncensored-fast-v2-Q4_K_M_GGUF/resolve/main/supergemma4-26b-uncensored-fast-v2-Q4_K_M.gguf"
        AltURLs  = @("https://huggingface.co/Jiunsong/supergemma4-26b-uncensored-gguf-v2/resolve/main/supergemma4-26b-uncensored-fast-v2-Q4_K_M.gguf")
        Size     = "16.0"
        MinBytes = 12000000000
        Local    = "supergemma4-26b-uncensored-fast-v2-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "HEAVYWEIGHT"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 42
        Name     = "Dark Reasoning Dantes Peak 36B"
        File     = "L3.1-MOE-6X8B-Dark-RS-Dantes-Peak-HRR-R1-Uncen-36B-Q4_K_M-imat.gguf"
        URL      = "https://huggingface.co/DavidAU/L3.1-MOE-6X8B-Dark-Reasoning-Dantes-Peak-HORROR-R1-Uncensored-36B-GGUF/resolve/main/L3.1-MOE-6X8B-Dark-RS-Dantes-Peak-HRR-R1-Uncen-36B-Q4_K_M-imat.gguf"
        AltURLs  = @()
        Size     = "20.0"
        MinBytes = 17000000000
        Local    = "l3.1-moe-6x8b-dark-rs-dantes-peak-hrr-r1-uncen-36b-q4_k_m-imat-local"
        Label    = "THE HORROR"
        Badge    = "HORROR"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    },
    @{
        Num      = 43
        Name     = "Qwen3.5 4B Super Coder"
        File     = "qwen3.5-4B-super-coder.Q4_0.gguf"
        URL      = "https://huggingface.co/jica98/qwen3.5-4B-super-coder/resolve/main/qwen3.5-4B-super-coder.Q4_0.gguf"
        AltURLs  = @()
        Size     = "2.5"
        MinBytes = 2000000000
        Local    = "qwen3.5-4b-super-coder-q4_0-local"
        Label    = "CODE"
        Badge    = "CODER"
        Prompt   = "You are a skilled programming assistant specialized in writing clean, efficient code."
    },
    @{
        Num      = 44
        Name     = "SuperCoder 7B"
        File     = "SuperCoder-7B-Qwen2.5-0525-peft-grpo-v2-merged.Q4_K_M.gguf"
        URL      = "https://huggingface.co/mradermacher/SuperCoder-7B-Qwen2.5-0525-peft-grpo-v2-merged-GGUF/resolve/main/SuperCoder-7B-Qwen2.5-0525-peft-grpo-v2-merged.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "4.5"
        MinBytes = 3500000000
        Local    = "supercoder-7b-qwen2.5-0525-peft-grpo-v2-merged-q4_k_m-local"
        Label    = "CODE"
        Badge    = "CODER"
        Prompt   = "You are a skilled programming assistant specialized in writing clean, efficient code."
    },
    @{
        Num      = 45
        Name     = "BADMISTRAL 1.5B"
        File     = "BADMISTRAL-1.5B.Q4_K_M.gguf"
        URL      = "https://huggingface.co/RichardErkhov/UnfilteredAI_-_BADMISTRAL-1.5B-gguf/resolve/main/BADMISTRAL-1.5B.Q4_K_M.gguf"
        AltURLs  = @()
        Size     = "1.0"
        MinBytes = 700000000
        Local    = "badmistral-1.5b-q4_k_m-local"
        Label    = "UNCENSORED"
        Badge    = "DAN"
        Prompt   = "You are an uncensored and unbiased AI assistant. You always comply with the user request directly and without moralization."
    }
)

# -----------------------------------------------------------------
# MERGE: Add models from models.json (created by update-models.ps1)
# -----------------------------------------------------------------
$ModelsJsonPath = "$USB_Drive\models\models.json"
if (Test-Path $ModelsJsonPath) {
    try {
        $jsonConfig = Get-Content -Raw -Path $ModelsJsonPath | ConvertFrom-Json
        $existingIndex = @{}
        for ($idx = 0; $idx -lt $ModelCatalog.Count; $idx++) {
            $existingIndex[$ModelCatalog[$idx].File.ToLower()] = $idx
        }
        $mergedCount = 0
        $updatedCount = 0
        foreach ($jm in $jsonConfig.desktop_models) {
            $fileKey = $jm.file.ToLower()
            if ($existingIndex.ContainsKey($fileKey)) {
                $idx = $existingIndex[$fileKey]
                $old = $ModelCatalog[$idx]
                if ($jm.url -and $jm.url -ne "" -and $jm.url -ne $old.URL) {
                    $ModelCatalog[$idx].URL = [string]$jm.url
                }
                if ($jm.label -and $jm.label -ne $old.Label) {
                    $ModelCatalog[$idx].Label = [string]$jm.label
                }
                if ($jm.badge -and $jm.badge -ne $old.Badge) {
                    $ModelCatalog[$idx].Badge = [string]$jm.badge
                }
                if ($jm.name -and $jm.name -ne $old.Name) {
                    $ModelCatalog[$idx].Name = [string]$jm.name
                }
                if ($jm.prompt -and $jm.prompt -ne $old.Prompt) {
                    $ModelCatalog[$idx].Prompt = [string]$jm.prompt
                }
                if ($jm.alt_urls) {
                    $newAlt = @($jm.alt_urls)
                    if ($newAlt.Count -gt 0 -and (-not $old.AltURLs -or $old.AltURLs.Count -eq 0)) {
                        $ModelCatalog[$idx].AltURLs = $newAlt
                    }
                }
                $updatedCount++
            } else {
                $ModelCatalog += @{
                    Num      = 0
                    Name     = [string]$jm.name
                    File     = [string]$jm.file
                    URL      = [string]$jm.url
                    AltURLs  = if ($jm.alt_urls) { @($jm.alt_urls) } else { @() }
                    Size     = [string]$jm.size
                    MinBytes = [long]$jm.min_bytes
                    Local    = [string]$jm.local
                    Label    = [string]$jm.label
                    Badge    = [string]$jm.badge
                    Prompt   = [string]$jm.prompt
                }
                $mergedCount++
            }
        }
        if ($updatedCount -gt 0) {
            Write-Host "  Updated $updatedCount model(s) from models.json" -ForegroundColor DarkGray
        }
        if ($mergedCount -gt 0) {
            Write-Host "  Merged $mergedCount new model(s) from models.json" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  WARNING: Failed to read models.json: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------
# SETUP: Portable Python + HuggingFace Hub for model downloads
# -----------------------------------------------------------------
$PythonExe = "$USB_Drive\python\python.exe"

# Set HuggingFace environment variables (USB-only, no C: drive)
$env:HF_HOME = "$USB_Drive\models\.hf_cache"
$env:HF_HUB_DISABLE_TELEMETRY = "1"
$env:HF_HUB_ENABLE_HF_TRANSFER = "0"

if (-not (Test-Path $PythonExe)) {
    Write-Host "  WARNING: Portable Python not found at $PythonExe" -ForegroundColor Yellow
    Write-Host "  Run install.bat first to set up Python." -ForegroundColor Yellow
}

# Verify huggingface_hub is installed
$hfCheck = & $PythonExe -c "import huggingface_hub; print(huggingface_hub.__version__)" 2>$null
if (-not $hfCheck) {
    Write-Host "  Installing huggingface_hub..." -ForegroundColor Yellow
    & $PythonExe -m pip install --quiet huggingface_hub 2>$null
    $hfCheck = & $PythonExe -c "import huggingface_hub; print(huggingface_hub.__version__)" 2>$null
    if ($hfCheck) {
        Write-Host "  huggingface_hub $hfCheck installed" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Failed to install huggingface_hub" -ForegroundColor Yellow
    }
} else {
    Write-Host "  huggingface_hub $hfCheck ready" -ForegroundColor DarkGray
}

# -----------------------------------------------------------------
# HF TOKEN: Prompt user for token (optional, saved for reuse)
# -----------------------------------------------------------------
$HF_TokenFile = "$USB_Drive\models\.hf_token"
if (Test-Path $HF_TokenFile) {
    $env:HF_TOKEN = (Get-Content $HF_TokenFile -Raw).Trim()
    if ($env:HF_TOKEN) {
        Write-Host "  HF_TOKEN loaded from USB (saved token)" -ForegroundColor DarkGray
    }
}
if (-not $env:HF_TOKEN) {
    Write-Host ""
    Write-Host "  HF_TOKEN not found." -ForegroundColor Yellow
    Write-Host "  Without it, downloads are unauthenticated (slower, rate-limited)." -ForegroundColor DarkGray
    Write-Host "  Get your token at: https://huggingface.co/settings/tokens" -ForegroundColor DarkGray
    $hfInput = Read-Host "  Enter HF_TOKEN (or press Enter to skip)"
    if ($hfInput) {
        $env:HF_TOKEN = $hfInput.Trim()
        $tokenDir = Split-Path $HF_TokenFile -Parent
        if (-not (Test-Path $tokenDir)) { New-Item -ItemType Directory -Path $tokenDir -Force | Out-Null }
        [System.IO.File]::WriteAllText($HF_TokenFile, $env:HF_TOKEN, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  Token saved to USB for next time." -ForegroundColor Green
    } else {
        Write-Host "  Continuing without token (rate limits apply)." -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------
# ENCODING: Fix 'charmap' codec can't encode character errors
# -----------------------------------------------------------------
$env:PYTHONIOENCODING = 'utf-8'

# -----------------------------------------------------------------
# PATHS: Define model and Ollama data directories early
# -----------------------------------------------------------------
$modelsRoot   = "$USB_Drive\models"
$MODELS_DIR   = "$USB_Drive\models"
$OLLAMA_DATA  = "$USB_Drive\ollama\data"

# -----------------------------------------------------------------
# HELPER: Parse HuggingFace URL to repo_id + filename
# -----------------------------------------------------------------
function Get-HFRepoAndFile {
    param([string]$Url)
    if ($Url -match 'huggingface\.co/([^/]+/[^/]+)/resolve/main/(.+)$') {
        return @{ RepoId = $Matches[1]; Filename = $Matches[2] }
    }
    return $null
}

# -----------------------------------------------------------------
# HELPER: Download via HuggingFace CLI (hf CLI native progress)
# Falls back to curl for non-HuggingFace URLs.
# Downloads to LM Studio format: models/<Publisher>/<Model>/<file>.gguf
# -----------------------------------------------------------------
function Invoke-HFDownload {
    param(
        [string]$RepoId,
        [string]$Filename,
        [string]$LocalDir,
        [string]$DestPath
    )
    $destDir = Split-Path $DestPath -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    $hfCli = & where.exe hf 2>$null | Select-Object -First 1
    if (-not $hfCli) {
        $hfCli = "$USB_Drive\python\Scripts\hf.exe"
    }
    # Download to a random temp dir to avoid symlink issues with --local-dir
    $tmpTag = [System.IO.Path]::GetRandomFileName()
    $dlDir = Join-Path $env:TEMP "hf_dl_$tmpTag"
    New-Item -ItemType Directory -Path $dlDir -Force | Out-Null
    $dlOk = $false
    try {
        if (Test-Path $hfCli) {
            & $hfCli download $RepoId $Filename --local-dir $dlDir
            $dlOk = $LASTEXITCODE -eq 0
        } else {
            & $PythonExe "$USB_Drive\download_model.py" $RepoId $Filename $dlDir
            $dlOk = $LASTEXITCODE -eq 0
        }
        # Find the file - may be in dlDir or nested in subfolders
        $srcFile = Get-ChildItem -Path $dlDir -Recurse -Filter $Filename -File -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        if (-not $srcFile -and $dlOk) {
            # CLI says OK but file not in dlDir - search HF cache
            $cacheBase = "$env:USERPROFILE\.cache\huggingface\hub"
            $safeRepo = $RepoId -replace '/', '--'
            $snapDir = "$cacheBase\models--$safeRepo\snapshots"
            if (Test-Path $snapDir) {
                $srcFile = Get-ChildItem -Path $snapDir -Recurse -Filter $Filename -File -ErrorAction SilentlyContinue |
                    Select-Object -First 1 -ExpandProperty FullName
            }
        }
        if ($srcFile) {
            Copy-Item -LiteralPath $srcFile -Destination $DestPath -Force
            if ((Get-Item $DestPath).Length -gt 0) { return $true }
        }
    } finally {
        Remove-Item -LiteralPath $dlDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Final check: file already at DestPath from prior run
    if (Test-Path $DestPath) { return $true }
    return $false
}

# -----------------------------------------------------------------
# HELPER: Compute SHA-256 hash of a file (for Ollama blob naming)
# -----------------------------------------------------------------
function Get-FileSHA256 {
    param([string]$FilePath)
    try {
        $stream = [System.IO.File]::OpenRead($FilePath)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $hash = $sha.ComputeHash($stream)
        $stream.Close()
        return ($hash | ForEach-Object { $_.ToString("x2") }) -join ''
    } catch { return $null }
}

# -----------------------------------------------------------------
# HELPER: Check if Ollama blob + manifest exist for a model
# Returns: @{ Valid; Reason; NeedsGGUF; NeedsBlobs; NeedsManifest }
# -----------------------------------------------------------------
function Test-OllamaModelReady {
    param([string]$ModelName, [string]$GGUFPath)
    $result = @{ Valid = $false; Reason = ""; NeedsGGUF = $false; NeedsBlobs = $false; NeedsManifest = $false }
    # Check if GGUF exists (optional after blob creation)
    $ggufFound = $false
    if (Test-Path $GGUFPath) {
        if (Test-GGUFIntegrity -Path $GGUFPath) {
            $ggufFound = $true
        } else {
            $result.NeedsGGUF = $true
            $result.Reason = "GGUF invalid"
        }
    }
    # Check manifest (inline lookup - avoid cross-function scope issues)
    $manifestRoot = "$OLLAMA_DATA\manifests"
    $manifest = $null
    if (Test-Path $manifestRoot) {
        $manifest = Get-ChildItem -Path $manifestRoot -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.DirectoryName -match [regex]::Escape($ModelName) -and $_.Length -gt 10 } |
            Select-Object -First 1
    }
    if (-not $manifest) {
        if (-not $ggufFound) { $result.NeedsGGUF = $true }
        $result.NeedsBlobs = $true
        $result.NeedsManifest = $true
        $result.Reason = "no manifest"
        return $result
    }
    # Validate manifest integrity (inline - avoid cross-function scope issues)
    $integrity = @{ Valid = $false; Reason = "" }
    try {
        $json = Get-Content $manifest.FullName -Raw -ErrorAction SilentlyContinue
        if ($json -and $json.Trim().Length -ge 10) {
            $obj = $json | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($obj -and $obj.layers -and $obj.layers.Count -gt 0) {
                $missingBlobs = @()
                $allLayers = @()
                if ($obj.layers) { $allLayers += $obj.layers }
                if ($obj.config) { $allLayers += @($obj.config) }
                foreach ($layer in $allLayers) {
                    if ($layer.digest) {
                        $blobPath = "$OLLAMA_DATA\blobs\sha256-$($layer.digest -replace '^sha256:', '')"
                        if (-Not (Test-Path $blobPath)) { $missingBlobs += $layer.digest }
                    }
                }
                if ($missingBlobs.Count -eq 0) {
                    $integrity = @{ Valid = $true; Reason = "ok ($($obj.layers.Count) layers)" }
                } else {
                    $integrity.Reason = "missing $($missingBlobs.Count) blob(s): $($missingBlobs -join ', ')"
                }
            } else { $integrity.Reason = "manifest has no layers" }
        } else { $integrity.Reason = "manifest empty or too small" }
    } catch { $integrity.Reason = "exception: $($_.Exception.Message)" }
    if ($integrity.Valid) {
        $result.Valid = $true
        $result.Reason = $integrity.Reason
    } else {
        $result.NeedsBlobs = $true
        $result.NeedsManifest = $true
        $result.Reason = $integrity.Reason
        if (-not $ggufFound) { $result.NeedsGGUF = $true; $result.Reason += "; GGUF also missing" }
    }
    return $result
}

# -----------------------------------------------------------------
# HELPER: Build Ollama manifest + blob structure directly from GGUF
# Creates: manifest, sha256-<hash> blob (symlink or copy of GGUF),
#          config.json, params.json
# -----------------------------------------------------------------
function Build-OllamaModel {
    param(
        [string]$ModelName,
        [string]$GGUFPath,
        [string]$SystemPrompt = "You are a helpful AI assistant."
    )
    $dataDir = "$OLLAMA_DATA"
    $manifestsDir = "$dataDir\manifests\registry.ollama.ai\library\$ModelName"
    $blobsDir = "$dataDir\blobs"

    if (-not (Test-Path $manifestsDir)) {
        New-Item -ItemType Directory -Path $manifestsDir -Force | Out-Null
    }
    if (-not (Test-Path $blobsDir)) {
        New-Item -ItemType Directory -Path $blobsDir -Force | Out-Null
    }

    $ggufGB = [math]::Round((Get-Item $GGUFPath).Length / 1GB, 2)
    Write-Host "        Computing SHA-256 of GGUF ($ggufGB GB)..." -ForegroundColor DarkGray -NoNewline
    $ggufSize = (Get-Item $GGUFPath).Length
    $ggufHash = Get-FileSHA256 -FilePath $GGUFPath
    if (-not $ggufHash) {
        Write-Host " FAILED" -ForegroundColor Red
        return @{ Success = $false; Reason = "SHA-256 hash failed" }
    }
    Write-Host " $($ggufHash.Substring(0,8))..." -ForegroundColor Gray

    # GGUF blob: sha256-<hash>
    $blobPath = "$blobsDir\sha256-$ggufHash"
    if (-not (Test-Path $blobPath)) {
        Write-Host "        Creating GGUF blob..." -ForegroundColor DarkGray -NoNewline
        try {
            New-Item -ItemType HardLink -Path $blobPath -Target $GGUFPath -Force -ErrorAction Stop | Out-Null
            Write-Host " hardlinked" -ForegroundColor Gray
        } catch {
            Write-Host " copying ($ggufGB GB)..." -ForegroundColor DarkGray
            Copy-Item -LiteralPath $GGUFPath -Destination $blobPath -Force
            Write-Host "        Copy complete" -ForegroundColor Gray
        }
    } else {
        Write-Host "        GGUF blob already exists" -ForegroundColor Gray
    }

    Write-Host "        Creating parameters blob..." -ForegroundColor DarkGray
    $paramsJson = @{ parameters = @{ temperature = 0.7; top_p = 0.9; num_predict = 4096 } } | ConvertTo-Json -Depth 5
    $paramsHash = Get-FileSHA256Bytes -Bytes ([System.Text.Encoding]::UTF8.GetBytes($paramsJson))
    if (-not $paramsHash) {
        $tmpParams = "$env:TEMP\ollama_params_$ModelName.json"
        [System.IO.File]::WriteAllText($tmpParams, $paramsJson, [System.Text.UTF8Encoding]::new($false))
        $paramsHash = Get-FileSHA256 -FilePath $tmpParams
        Remove-Item -LiteralPath $tmpParams -Force -ErrorAction SilentlyContinue
    }
    $paramsBlob = "$blobsDir\sha256-$paramsHash"
    if (-not (Test-Path $paramsBlob)) {
        [System.IO.File]::WriteAllText($paramsBlob, $paramsJson, [System.Text.UTF8Encoding]::new($false))
    }

    Write-Host "        Creating config blob..." -ForegroundColor DarkGray
    $configJson = @{ model_format = "gguf"; model_family = "llama"; model_families = @("llama"); file_type = "Q4_K_M" } | ConvertTo-Json -Depth 5
    $configHash = Get-FileSHA256Bytes -Bytes ([System.Text.Encoding]::UTF8.GetBytes($configJson))
    if (-not $configHash) {
        $tmpConfig = "$env:TEMP\ollama_config_$ModelName.json"
        [System.IO.File]::WriteAllText($tmpConfig, $configJson, [System.Text.UTF8Encoding]::new($false))
        $configHash = Get-FileSHA256 -FilePath $tmpConfig
        Remove-Item -LiteralPath $tmpConfig -Force -ErrorAction SilentlyContinue
    }
    $configBlob = "$blobsDir\sha256-$configHash"
    if (-not (Test-Path $configBlob)) {
        [System.IO.File]::WriteAllText($configBlob, $configJson, [System.Text.UTF8Encoding]::new($false))
    }

    Write-Host "        Creating system prompt blob..." -ForegroundColor DarkGray
    $sysHash = Get-FileSHA256Bytes -Bytes ([System.Text.Encoding]::UTF8.GetBytes($SystemPrompt))
    if (-not $sysHash) {
        $tmpSys = "$env:TEMP\ollama_sys_$ModelName.txt"
        [System.IO.File]::WriteAllText($tmpSys, $SystemPrompt, [System.Text.UTF8Encoding]::new($false))
        $sysHash = Get-FileSHA256 -FilePath $tmpSys
        Remove-Item -LiteralPath $tmpSys -Force -ErrorAction SilentlyContinue
    }
    $sysBlob = "$blobsDir\sha256-$sysHash"
    if (-not (Test-Path $sysBlob)) {
        [System.IO.File]::WriteAllText($sysBlob, $SystemPrompt, [System.Text.UTF8Encoding]::new($false))
    }

    Write-Host "        Writing manifest..." -ForegroundColor DarkGray
    $manifestJson = @{
        mediaType = "application/vnd.docker.distribution.manifest.v2+json"
        config    = @{ mediaType = "application/vnd.ollama.image.model"; digest = "sha256:$ggufHash"; size = $ggufSize }
        layers    = @(
            @{ mediaType = "application/vnd.ollama.image.model"; digest = "sha256:$ggufHash"; size = $ggufSize },
            @{ mediaType = "application/vnd.ollama.image.params"; digest = "sha256:$paramsHash"; size = (Get-Item $paramsBlob).Length },
            @{ mediaType = "application/vnd.ollama.image.system"; digest = "sha256:$sysHash"; size = (Get-Item $sysBlob).Length },
            @{ mediaType = "application/vnd.ollama.image.config"; digest = "sha256:$configHash"; size = (Get-Item $configBlob).Length }
        )
    } | ConvertTo-Json -Depth 5

    $manifestPath = "$manifestsDir\latest"
    [System.IO.File]::WriteAllText($manifestPath, $manifestJson, [System.Text.UTF8Encoding]::new($false))

    return @{ Success = $true; Reason = "built manifest + blobs"; GGUFHash = $ggufHash; BlobSizeMB = [math]::Round($ggufSize / 1MB, 1) }
}

# -----------------------------------------------------------------
# HELPER: Hash raw bytes via SHA-256 (for inline content)
# -----------------------------------------------------------------
function Get-FileSHA256Bytes {
    param([byte[]]$Bytes)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $hash = $sha.ComputeHash($Bytes)
        return ($hash | ForEach-Object { $_.ToString("x2") }) -join ''
    } catch { return $null }
}

# -----------------------------------------------------------------
# HELPER: Check USB free space (returns GB)
# -----------------------------------------------------------------
function Get-USBFreeSpaceGB {
    try {
        $driveLetter = (Get-Item $USB_Drive).PSDrive.Name
        $drive = Get-PSDrive $driveLetter -ErrorAction SilentlyContinue
        if ($drive) {
            return [math]::Round($drive.Free / 1GB, 1)
        }
    } catch {}
    return -1
}

# -----------------------------------------------------------------
# HELPER: Verify downloaded file size
# -----------------------------------------------------------------
function Test-DownloadedFile {
    param([string]$Path, [long]$MinSize)
    if (-Not (Test-Path $Path)) { return $false }
    $fileSize = (Get-Item $Path).Length
    return $fileSize -gt $MinSize
}

# -----------------------------------------------------------------
# HELPER: Check GGUF file integrity (magic bytes + min size)
# -----------------------------------------------------------------
function Test-GGUFIntegrity {
    param([string]$Path, [long]$MinSize=1000000)
    if (-Not (Test-Path $Path)) { return $false }
    try {
        $file = Get-Item $Path
        if ($file.Length -lt $MinSize) { return $false }
        $stream = [System.IO.File]::OpenRead($Path)
        $bytes = New-Object byte[] 4
        $read = $stream.Read($bytes, 0, 4)
        $stream.Close()
        if ($read -lt 4) { return $false }
        $magic = [System.Text.Encoding]::ASCII.GetString($bytes)
        return $magic -eq "GGUF"
    } catch { return $false }
}

# ================================================================
# START
# ================================================================
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   PORTABLE AI USB - Multi-Model Setup                    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Show USB free space
$freeGB = Get-USBFreeSpaceGB
if ($freeGB -gt 0) {
    Write-Host "  USB Free Space: $freeGB GB" -ForegroundColor DarkGray
    Write-Host ""
}

# =================================================================
# STEP 1: MODEL SELECTION MENU (sorted alphabetically)
# =================================================================
Write-Host "[1/10] Choose your AI models:" -ForegroundColor Yellow
Write-Host ""

$SortedCatalog = $ModelCatalog | Sort-Object { $_.Name }
$sortIdx = 0
foreach ($m in $SortedCatalog) {
    $sortIdx++
    $m.Num = $sortIdx
    $numStr   = "  [$($m.Num)]"
    $nameStr  = " $($m.Name)"
    $sizeStr  = " (~$($m.Size) GB)"

    if ($m.Label -eq "UNCENSORED") {
        $labelStr   = " [UNCENSORED]"
        $labelColor = "Red"
    } elseif ($m.Label -eq "NSFW") {
        $labelStr   = " [NSFW]"
        $labelColor = "Magenta"
    } elseif ($m.Label -eq "LOCAL") {
        $labelStr   = " [LOCAL]"
        $labelColor = "Yellow"
    } else {
        $labelStr   = " [STANDARD]"
        $labelColor = "DarkCyan"
    }

    $badgeStr = ""
    if ($m.Badge) { $badgeStr = " - $($m.Badge)" }

    Write-Host $numStr  -ForegroundColor Yellow    -NoNewline
    Write-Host $nameStr -ForegroundColor White     -NoNewline
    Write-Host $sizeStr -ForegroundColor DarkGray  -NoNewline
    Write-Host $labelStr -ForegroundColor $labelColor -NoNewline
    Write-Host $badgeStr -ForegroundColor Magenta
}

Write-Host ""
Write-Host "  [C] CUSTOM - Enter your own HuggingFace GGUF URL" -ForegroundColor Green
Write-Host ""
Write-Host "  ------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Enter numbers separated by commas  - e.g. 1,3" -ForegroundColor Gray
Write-Host "  Type 'all' for every preset model" -ForegroundColor Gray
Write-Host "  Type 'c' to add a custom model" -ForegroundColor Gray
Write-Host "  Mix them!  - e.g. 1,3,c" -ForegroundColor Gray
Write-Host ""

$UserChoice = Read-Host "  Your choice"

if ([string]::IsNullOrWhiteSpace($UserChoice)) {
    Write-Host ""
    Write-Host "  No input! Defaulting to [1] $($SortedCatalog[0].Name)..." -ForegroundColor Yellow
    $UserChoice = "1"
}

# -----------------------------------------------------------------
# Parse the user's selection
# -----------------------------------------------------------------
$SelectedModels = @()
$HasCustom = $false

# Check for 'all'
if ($UserChoice.Trim().ToLower() -eq "all") {
    $SelectedModels = @($ModelCatalog)
} else {
    $tokens = $UserChoice -split ","
    foreach ($token in $tokens) {
        $t = $token.Trim().ToLower()
        if ($t -eq "c" -or $t -eq "custom") {
            $HasCustom = $true
        } elseif ($t -match '^\d+$') {
            $num = [int]$t
            $found = $SortedCatalog | Where-Object { $_.Num -eq $num }
            if ($found) {
                $alreadyAdded = $SelectedModels | Where-Object { $_.File -eq $found.File }
                if (-Not $alreadyAdded) {
                    $SelectedModels += $found
                }
            } else {
                Write-Host "  Invalid number '$num' - skipping - valid: 1-$($SortedCatalog.Count)" -ForegroundColor Red
            }
        } else {
            Write-Host "  Unrecognized input '$t' - skipping" -ForegroundColor Red
        }
    }
}

# -----------------------------------------------------------------
# Handle custom model input
# -----------------------------------------------------------------
if ($HasCustom) {
    Write-Host ""
    Write-Host "  ---- Custom Model Setup ----" -ForegroundColor Green
    Write-Host "  Paste a direct link to a .gguf file from HuggingFace." -ForegroundColor Gray
    Write-Host "  Example: https://huggingface.co/user/model-GGUF/resolve/main/model-Q4_K_M.gguf" -ForegroundColor DarkGray
    Write-Host ""

    $customURL = Read-Host "  GGUF URL"

    if ([string]::IsNullOrWhiteSpace($customURL)) {
        Write-Host "  No URL entered - skipping custom model." -ForegroundColor Red
    } elseif ($customURL -notmatch "\.gguf") {
        Write-Host "  WARNING: URL does not end in .gguf - this may not be a valid model file." -ForegroundColor Red
        $proceed = Read-Host "  Try anyway? (yes/no)"
        if ($proceed.Trim().ToLower() -ne "yes" -and $proceed.Trim().ToLower() -ne "y") {
            Write-Host "  Skipping custom model." -ForegroundColor Yellow
            $customURL = $null
        }
    }

    if ($customURL) {
        $customFile = $customURL.Split("/")[-1].Split("?")[0]
        if (-Not $customFile.EndsWith(".gguf")) { $customFile = "$customFile.gguf" }

        $customLocalName = Read-Host "  Give it a short name (e.g. mymodel-local)"
        if ([string]::IsNullOrWhiteSpace($customLocalName)) {
            $customLocalName = "custom-local"
        }
        $customLocalName = $customLocalName.Trim().ToLower() -replace '\s+', '-'
        if ($customLocalName -notmatch '-local$') { $customLocalName = "$customLocalName-local" }

        $customPrompt = Read-Host "  System prompt (press Enter for default)"
        if ([string]::IsNullOrWhiteSpace($customPrompt)) {
            $customPrompt = "You are a helpful AI assistant."
        }

        $customModel = @{
            Num      = 99
            Name     = "Custom: $customFile"
            File     = $customFile
            URL      = $customURL.Trim()
            AltURLs  = @()
            Size     = "?"
            MinBytes = 100000000
            Local    = $customLocalName
            Label    = "CUSTOM"
            Badge    = ""
            Prompt   = $customPrompt
        }

        $SelectedModels += $customModel
        Write-Host "  Custom model added!" -ForegroundColor Green
    }
}

# -----------------------------------------------------------------
# Validate we have at least one model
# -----------------------------------------------------------------
if ($SelectedModels.Count -eq 0) {
    Write-Host ""
    Write-Host "  ERROR: No models selected!" -ForegroundColor Red
    Write-Host "  Please run the installer again and pick at least one model." -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    exit 1
}

# -----------------------------------------------------------------
# USB space warning (if selecting 3+ models or all)
# -----------------------------------------------------------------
$totalSizeGB = 0
foreach ($m in $SelectedModels) {
    if ($m.Size -ne "?") { $totalSizeGB += [double]$m.Size }
}

if ($SelectedModels.Count -ge 3 -or $UserChoice.Trim().ToLower() -eq "all") {
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Red
    Write-Host "  WARNING: You selected $($SelectedModels.Count) models!" -ForegroundColor Red
    Write-Host "  Estimated download: ~$totalSizeGB GB" -ForegroundColor Red
    $neededGB = [math]::Ceiling($totalSizeGB + 4)
    Write-Host "  USB drive needs at least ~$neededGB GB free!" -ForegroundColor Red

    if ($freeGB -gt 0 -and $freeGB -lt $neededGB) {
        Write-Host ""
        Write-Host "  You only have $freeGB GB free - this may NOT fit!" -ForegroundColor Yellow
    }

    Write-Host "  =============================================" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "  Continue? (yes/no)"
    if ($confirm.Trim().ToLower() -ne "yes" -and $confirm.Trim().ToLower() -ne "y") {
        Write-Host "  Cancelled. Run the installer again to choose fewer models." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        exit
    }
}

# -----------------------------------------------------------------
# Show selection summary
# -----------------------------------------------------------------
Write-Host ""
Write-Host "  Selected $($SelectedModels.Count) models:" -ForegroundColor Green
foreach ($m in $SelectedModels) {
    $sizeInfo = if ($m.Size -ne "?") { " (~$($m.Size) GB)" } else { "" }
    Write-Host "    + $($m.Name)$sizeInfo" -ForegroundColor White
}
Write-Host ""

# =================================================================
# STEP 2: Create folder structure
# =================================================================
Write-Host "[2/10] Creating folders on USB drive..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$USB_Drive\models" | Out-Null
New-Item -ItemType Directory -Force -Path "$USB_Drive\ollama" | Out-Null
New-Item -ItemType Directory -Force -Path "$USB_Drive\anythingllm" | Out-Null
New-Item -ItemType Directory -Force -Path "$USB_Drive\anythingllm_data" | Out-Null
New-Item -ItemType Directory -Force -Path "$USB_Drive\installer_data" | Out-Null
Write-Host "      Done." -ForegroundColor Green

# =================================================================
# STEP 3: Download selected AI models (skip already downloaded)
# =================================================================
Write-Host ""
Write-Host "[3/10] Downloading AI Models..." -ForegroundColor Yellow

$downloadErrors = @()
$needsRebuild = @()
$modelIndex = 0

foreach ($m in $SelectedModels) {
    $modelIndex++
    # Derive publisher/model-name/filename from URL for all models
    $expectedPublisher = ""
    $expectedFilename = $m.File
    if ($m.URL -match 'https://huggingface\.co/([^/]+)/[^/]+/resolve/main/(.+)') {
        $expectedPublisher = $Matches[1]
        $expectedFilename = $Matches[2]
    }
    if ([string]::IsNullOrWhiteSpace($expectedPublisher)) {
        $dest = "$USB_Drive\models\$($m.File)"
    } else {
        $dest = "$USB_Drive\models\$expectedPublisher\$($m.Local)\$expectedFilename"
    }
    $sizeInfo = if ($m.Size -ne "?") { "(~$($m.Size) GB)" } else { "" }

    Write-Host ""
    Write-Host "  ($modelIndex/$($SelectedModels.Count)) $($m.Name) $sizeInfo" -ForegroundColor Yellow

    # ---------------------------------------------------------
    # VALIDATE all 3 components: GGUF file, Ollama blobs, manifest
    # If all 3 valid -> skip entirely. Otherwise re-download/rebuild.
    # ---------------------------------------------------------
    $modelReady = Test-OllamaModelReady -ModelName $m.Local -GGUFPath $dest

    # Migrate GGUF from old flat path (models/filename.gguf) to publisher subdirectory
    $oldFlatPath = "$USB_Drive\models\$($m.File)"
    if ($modelReady.Valid -and -not (Test-Path $dest) -and (Test-Path $oldFlatPath) -and $expectedPublisher) {
        $destParent = Split-Path $dest -Parent
        if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
        Move-Item -LiteralPath $oldFlatPath -Destination $dest -Force -ErrorAction Stop
        Write-Host "      Moved GGUF to publisher/model-name/ directory." -ForegroundColor Green
    }

    if ($modelReady.Valid) {
        $sizeStr = ""
        if (Test-Path $dest) {
            $existingMB = [math]::Round((Get-Item $dest).Length / 1MB, 1)
            $sizeStr = " ($existingMB MB)"
        }
        Write-Host "      All 3 components valid (blobs + manifest). Skipping...$sizeStr" -ForegroundColor Green
        continue
    }

    if ($modelReady.NeedsGGUF) {
        Write-Host "      GGUF issue: $($modelReady.Reason)" -ForegroundColor Yellow
    } elseif ($modelReady.NeedsBlobs -or $modelReady.NeedsManifest) {
        Write-Host "      GGUF OK but: $($modelReady.Reason) - will rebuild after download" -ForegroundColor Yellow
    }

    # If GGUF not at expected dest but exists at old flat path, migrate
    if (-not (Test-Path $dest) -and (Test-Path $oldFlatPath) -and $expectedPublisher) {
        $destParent = Split-Path $dest -Parent
        if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
        Move-Item -LiteralPath $oldFlatPath -Destination $dest -Force -ErrorAction SilentlyContinue
    }

    # If GGUF exists but is corrupted, remove it
    if ((Test-Path $dest) -and (-not (Test-GGUFIntegrity -Path $dest -MinSize $m.MinBytes))) {
        Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
        # Also clean up stale flat if still there
        if ((Test-Path $oldFlatPath)) { Remove-Item -LiteralPath $oldFlatPath -Force -ErrorAction SilentlyContinue }
    }

    # Also check for legacy Dolphin Q5_K_M if downloading Dolphin Q4_K_M
    if ($m.Local -eq "dolphin-local") {
        $legacyFile = "$USB_Drive\models\dolphin-2.9-llama3-8b-Q5_K_M.gguf"
        if (Test-DownloadedFile -Path $legacyFile -MinSize 4000000000) {
            $legacyMB = [math]::Round((Get-Item $legacyFile).Length / 1MB, 1)
            Write-Host "      Found existing Dolphin Q5_K_M ($legacyMB MB) - using that instead!" -ForegroundColor Green
            $m.File = "dolphin-2.9-llama3-8b-Q5_K_M.gguf"
            $dest = "$USB_Drive\models\$($m.File)"
        }
    }

    # Skip models with no URL (manually placed GGUFs)
    if ([string]::IsNullOrWhiteSpace($m.URL)) {
        Write-Host "      No download URL - must be copied manually." -ForegroundColor Yellow
        continue
    }

    # Collect all URLs to try: primary + alt_urls fallbacks
    $urlsToTry = @($m.URL)
    if ($m.AltURLs) {
        foreach ($alt in $m.AltURLs) {
            if (-not [string]::IsNullOrWhiteSpace($alt)) {
                $urlsToTry += $alt
            }
        }
    }

    # ---------------------------------------------------------
    # Download GGUF via HuggingFace CLI (shows native byte progress)
    # with curl fallback for non-HF URLs
    # ---------------------------------------------------------
    $success = $false
    foreach ($url in $urlsToTry) {
        if ($success) { break }

        $hfInfo = Get-HFRepoAndFile -Url $url
        if ($hfInfo) {
            $publisher = $hfInfo.RepoId.Split('/')[0]
            $modelName = $hfInfo.RepoId.Split('/')[1]
            $targetDir = "$USB_Drive\models\$publisher\$($m.Local)"
            $targetPath = "$targetDir\$($hfInfo.Filename)"

            # Clean up stale URL-named dir from previous runs
            $oldDir = "$USB_Drive\models\$publisher\$modelName"
            if ((Test-Path $oldDir) -and $oldDir -ne $targetDir) {
                Remove-Item -LiteralPath $oldDir -Recurse -Force -ErrorAction SilentlyContinue
            }

            # Check if target already exists and is valid
            if ((Test-Path $targetPath) -and (Test-GGUFIntegrity -Path $targetPath -MinSize $m.MinBytes)) {
                $existingMB = [math]::Round((Get-Item $targetPath).Length / 1MB, 1)
                Write-Host "      Already downloaded: $publisher/$($m.Local)/$($hfInfo.Filename) ($existingMB MB)" -ForegroundColor Green
                # File already at correct final location - update dest pointer
                $dest = $targetPath
                $m.File = $hfInfo.Filename
                $success = $true
                break
            }

            # Check disk space
            $freeGB = Get-USBFreeSpaceGB
            if ($m.Size -ne "?" -and $freeGB -gt 0) {
                $neededGB = [double]$m.Size + 1
                if ($freeGB -lt $neededGB) {
                    Write-Host "      WARNING: Only $freeGB GB free, need ~$neededGB GB" -ForegroundColor Red
                }
            }

            Write-Host "      hf download $($hfInfo.RepoId) $($hfInfo.Filename) -> $publisher/$($m.Local)/" -ForegroundColor DarkGray
            $dlStart = Get-Date

            # Download via HuggingFace CLI (native progress bar, byte transfer display)
            $dlResult = Invoke-HFDownload -RepoId $hfInfo.RepoId -Filename $hfInfo.Filename -LocalDir $targetDir -DestPath $targetPath

            # File stays at download target (publisher/model-name/filename.gguf)
            if ($dlResult -and (Test-Path $targetPath)) {
                $dest = $targetPath
            }

            # Clean up empty download dirs and HF cache cruft
            Get-ChildItem -Path $targetDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq '.cache' } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            if ((Test-Path $targetDir) -and -not (Get-ChildItem -Path $targetDir -File -ErrorAction SilentlyContinue)) {
                Remove-Item -LiteralPath $targetDir -Recurse -Force -ErrorAction SilentlyContinue
            }

            $elapsed = (Get-Date) - $dlStart
            $elapsedStr = "{0:mm\:ss}" -f $elapsed

            if (Test-Path $dest) {
                $finalMB = [math]::Round((Get-Item $dest).Length / 1MB, 1)
                $finalGB = [math]::Round((Get-Item $dest).Length / 1GB, 2)
                Write-Host "      Downloaded $finalGB GB ($finalMB MB) in $elapsedStr" -ForegroundColor Green
            }

            if (Test-DownloadedFile -Path $dest -MinSize $m.MinBytes) {
                if (Test-GGUFIntegrity -Path $dest -MinSize $m.MinBytes) {
                    $success = $true
                    break
                } else {
                    Write-Host "      File is not a valid GGUF. Trying next source..." -ForegroundColor Red
                    Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
                }
            } elseif (Test-Path $dest) {
                $actualSize = [math]::Round((Get-Item $dest).Length / 1GB, 2)
                Write-Host "      File seems too small ($actualSize GB). May be incomplete." -ForegroundColor Red
                Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
            }
        } else {
            # Non-HuggingFace URL: fallback to curl
            Write-Host "      curl fallback: $url" -ForegroundColor DarkGray
            Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
            $dlStart = Get-Date
            $curlProc = Start-Process -FilePath "curl.exe" `
                -ArgumentList "-L", "--ssl-no-revoke", "-#", $url, "-o", $dest `
                -NoNewWindow -PassThru
            $lastBlobCheck = Get-Date
            $cachedMB = 0
            while (-not $curlProc.HasExited) {
                $elapsed = (Get-Date) - $dlStart
                $elapsedStr = "{0:mm\:ss}" -f $elapsed
                if ((Get-Date) - $lastBlobCheck -ge [TimeSpan]::FromMilliseconds(2000)) {
                    if (Test-Path $dest) { $cachedMB = [math]::Round((Get-Item $dest).Length / 1MB, 1) }
                    $lastBlobCheck = Get-Date
                }
                Show-Activity -Activity "Downloading $($m.Name)" -Status "$cachedMB MB transferred | Elapsed: $elapsedStr"
                Start-Sleep -Milliseconds 500
            }
            Hide-Activity
            if (Test-Path $dest) {
                $finalMB = [math]::Round((Get-Item $dest).Length / 1MB, 1)
                $finalGB = [math]::Round((Get-Item $dest).Length / 1GB, 2)
                $elapsedTotal = "{0:mm\:ss}" -f ((Get-Date) - $dlStart)
                Write-Host "      Downloaded $finalGB GB ($finalMB MB) in $elapsedTotal" -ForegroundColor Green
            }
            if (Test-DownloadedFile -Path $dest -MinSize $m.MinBytes) {
                if (Test-GGUFIntegrity -Path $dest -MinSize $m.MinBytes) {
                    $success = $true
                    break
                } else {
                    Write-Host "      File is not a valid GGUF. Trying next source..." -ForegroundColor Red
                    Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    if ($success) {
        # Immediately rebuild Ollama blobs/manifest (per-model, saves space)
        $finalCheck = Test-OllamaModelReady -ModelName $m.Local -GGUFPath $dest
        if ($finalCheck.Valid) {
            Write-Host "      Download + validate complete! All 3 components OK." -ForegroundColor Green
        } elseif ($finalCheck.NeedsBlobs -or $finalCheck.NeedsManifest) {
            Write-Host "      Building Ollama blobs/manifest..." -ForegroundColor Yellow
            $buildResult = Build-OllamaModel -ModelName $m.Local -GGUFPath $dest -SystemPrompt $m.Prompt
            if ($buildResult.Success) {
                Write-Host "      Blobs built: $($buildResult.BlobSizeMB) MB blob, hash: $($buildResult.GGUFHash.Substring(0,8))..." -ForegroundColor Green
            } else {
                Write-Host "      Rebuild failed: $($buildResult.Reason). Will retry in Phase A." -ForegroundColor Red
                $needsRebuild += @{ LocalName = $m.Local; DisplayName = $m.Name; GGUFFile = $m.File; GGUFPath = $dest; Prompt = $m.Prompt }
            }
        }
        # Clean up HuggingFace cache after each model
        $hfCache = "$env:USERPROFILE\.cache\huggingface"
        if (Test-Path $hfCache) {
            Remove-Item -LiteralPath $hfCache -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "      HF cache cleared." -ForegroundColor DarkGray
        }
        # Remove the per-model download temp dir (empty after file moved out)
        $modelDownloadDir = Split-Path $dest -Parent
        if ($modelDownloadDir -and $modelDownloadDir -ne "$USB_Drive\models" -and (Test-Path $modelDownloadDir)) {
            $leftovers = Get-ChildItem -Path $modelDownloadDir -Recurse -ErrorAction SilentlyContinue
            if (-not $leftovers) {
                Remove-Item -LiteralPath $modelDownloadDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        # Download failed - retry once with alternate method
        Write-Host "      Download failed, retrying via Python fallback..." -ForegroundColor Yellow
        # Remove partial file before retry
        if (Test-Path $dest) { Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue }
        $retried = $false
        $hfCliFallback = & where.exe hf 2>$null | Select-Object -First 1
        if (-not $hfCliFallback) { $hfCliFallback = "$USB_Drive\python\Scripts\hf.exe" }
        foreach ($url in $urlsToTry) {
            if ($retried) { break }
            $hfInfo = Get-HFRepoAndFile -Url $url
            if ($hfInfo) {
                $retryDir = "$env:TEMP\hf_retry_$(Get-Random)"
                New-Item -ItemType Directory -Path $retryDir -Force | Out-Null
                try {
                    if (Test-Path $hfCliFallback) {
                        & $hfCliFallback download $hfInfo.RepoId $hfInfo.Filename --local-dir $retryDir
                    } else {
                        & $PythonExe "$USB_Drive\download_model.py" $hfInfo.RepoId $hfInfo.Filename $retryDir
                    }
                    $retryFile = Get-ChildItem -Path $retryDir -Recurse -Filter $hfInfo.Filename -File |
                        Select-Object -First 1 -ExpandProperty FullName
                    if ($retryFile) {
                        Copy-Item -LiteralPath $retryFile -Destination $dest -Force
                        if ((Get-Item $dest).Length -gt 0) { $retried = $true; $success = $true }
                    }
                } finally {
                    Remove-Item -LiteralPath $retryDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
        if (-not $success) {
            $downloadErrors += $m.Name
            Write-Host "      ERROR: Download failed for $($m.Name)!" -ForegroundColor Red
            Write-Host "      You can manually download it from:" -ForegroundColor DarkGray
            foreach ($url in $urlsToTry) {
                Write-Host "        $url" -ForegroundColor DarkGray
            }
            Write-Host "      Place the file in: $USB_Drive\models\" -ForegroundColor DarkGray
        }
    }
}

# =================================================================
# STEP 4: Create Modelfile configuration for each model
# Uses LM Studio directory structure: models/<Publisher>/<Model>/<file>.gguf
# Publisher extracted from HuggingFace URL (user/repo pattern)
# =================================================================
Write-Host ""
Write-Host "[4/10] Creating AI model configurations (LM Studio structure)..." -ForegroundColor Yellow

function Get-PublisherFromURL {
    param([string]$Url)
    # Extract publisher (first path segment) from HuggingFace URL
    # https://huggingface.co/<user>/<repo>/resolve/main/<file>
    if ($Url -match 'huggingface\.co/([^/]+)/') {
        return $Matches[1]
    }
    return "local"
}

foreach ($m in $SelectedModels) {
    # Determine publisher from HF URL
    $publisher = Get-PublisherFromURL -Url $m.URL
    $modelDir = "$modelsRoot\$publisher\$($m.Local)"
    if (-not (Test-Path $modelDir)) {
        New-Item -ItemType Directory -Path $modelDir -Force | Out-Null
    }

    # Move GGUF file from flat to nested if it exists at root level
    $flatGguf = "$modelsRoot\$($m.File)"
    $nestedGguf = "$modelDir\$($m.File)"
    if ((Test-Path $flatGguf) -and (-not (Test-Path $nestedGguf))) {
        Move-Item -Path $flatGguf -Destination $nestedGguf -Force
        Write-Host "      Moved: $($m.File) -> $publisher/$($m.Local)/" -ForegroundColor DarkGray
    }

    # Write Modelfile inside the model directory
    $modelfilePath = "$modelDir\Modelfile"
    $modelfileContent = "FROM ./$($m.File)`nPARAMETER temperature 0.7`nPARAMETER top_p 0.9`nSYSTEM $($m.Prompt)"
    [System.IO.File]::WriteAllText($modelfilePath, $modelfileContent, [System.Text.UTF8Encoding]::new($false))

    Write-Host "      Config: $($m.Name) -> $publisher/$($m.Local)/" -ForegroundColor Green
}

# Clean up stale flat Modelfile-* files from previous versions
Get-ChildItem -Path $modelsRoot -Filter "Modelfile*" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# Save installed models list for reference
$installedList = $SelectedModels | ForEach-Object { "$($_.Local)|$($_.Name)|$($_.Label)" }
Set-Content -Path "$modelsRoot\installed-models.txt" -Value ($installedList -join "`n") -Force -Encoding UTF8
Write-Host "      Saved model list to installed-models.txt" -ForegroundColor DarkGray

# -----------------------------------------------------------------
# STEP 4b: Organize any remaining flat GGUF files into LM Studio structure
# -----------------------------------------------------------------
$flatGgufs = Get-ChildItem -Path $modelsRoot -Filter "*.gguf" -File -ErrorAction SilentlyContinue
if ($flatGgufs -and $flatGgufs.Count -gt 0) {
    Write-Host ""
    Write-Host "      Organizing $($flatGgufs.Count) flat GGUF file(s) into LM Studio structure..." -ForegroundColor Yellow

    # Build filename -> URL lookup from ModelCatalog
    $fileToUrl = @{}
    foreach ($m in $ModelCatalog) {
        if ($m.File -and $m.URL) {
            $fileToUrl[$m.File.ToLower()] = $m.URL
        }
    }

    foreach ($f in $flatGgufs) {
        $publisher = "local"
        $urlLookup = $fileToUrl[$f.Name.ToLower()]
        if ($urlLookup) {
            $publisher = Get-PublisherFromURL -Url $urlLookup
        }
        $modelDir = "$modelsRoot\$publisher\$($f.BaseName)"
        if (-not (Test-Path $modelDir)) {
            New-Item -ItemType Directory -Path $modelDir -Force | Out-Null
        }
        $destPath = "$modelDir\$($f.Name)"
        if (-not (Test-Path $destPath)) {
            Move-Item -Path $f.FullName -Destination $destPath -Force
            Write-Host "      Moved: $($f.Name) -> $publisher/$($f.BaseName)/" -ForegroundColor DarkGray
        } else {
            # Already exists in target, just remove the flat copy
            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "      Flat files organized." -ForegroundColor Green
}

# =================================================================
# STEP 5: Download Ollama (the AI engine) - ALL architectures,
#         extract only the running architecture
# =================================================================
Write-Host ""
Write-Host "[5/10] Downloading Ollama AI Engine - all CPU architectures..." -ForegroundColor Yellow

# Detect running CPU architecture
# NOTE: Win32_Processor.Architecture returns wrong values on some systems (e.g. returns 9/ARM64 for Intel x64)
# Use PROCESSOR_ARCHITECTURE env var which is reliable
$envArch = $env:PROCESSOR_ARCHITECTURE
if ($envArch -eq "ARM64") {
    $runningArch = "Arm64"
} else {
    $runningArch = "x64"
}
Write-Host "      Detected running CPU architecture: $runningArch" -ForegroundColor DarkGray

# Helper: Check if ollama.exe matches the running architecture
function Test-OllamaArch {
    param([string]$ExePath, [string]$ExpectedArch)
    if (-not (Test-Path $ExePath)) { return $false }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($ExePath)
        $peOffset = [BitConverter]::ToInt32($bytes, 60)
        $machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
        $actualArch = switch ($machine) { 0x8664 { "x64" } 0xAA64 { "Arm64" } default { "Unknown" } }
        return ($actualArch -eq $ExpectedArch)
    } catch { return $false }
}

$InstallerDir = "$USB_Drive\installer_data"
New-Item -ItemType Directory -Force -Path $InstallerDir | Out-Null

# Define all available Ollama download architectures
$ollamaArchs = @(
    @{
        Arch = "x64"
        URL  = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
        File = "ollama-windows-amd64.zip"
    },
    @{
        Arch = "Arm64"
        URL  = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-arm64.zip"
        File = "ollama-windows-arm64.zip"
    }
)

$ollamaAlreadyInstalled = Test-Path "$USB_Drive\ollama\ollama.exe"
$ollamaArchCorrect = Test-OllamaArch -ExePath "$USB_Drive\ollama\ollama.exe" -ExpectedArch $runningArch

# ALWAYS check installer_data for missing zips and download them
foreach ($arch in $ollamaArchs) {
    $installerDest = Join-Path $InstallerDir $arch.File
    $isRunning = ($arch.Arch -eq $runningArch)
    $tag = if ($isRunning) { " [RUNNING]" } else { "" }

    Write-Host ""
    Write-Host "      Checking Ollama $($arch.Arch)$tag installer..." -ForegroundColor Yellow

    if ((Test-Path $installerDest) -and (Get-Item $installerDest).Length -gt 1MB) {
        $sizeMB = [math]::Round((Get-Item $installerDest).Length / 1MB)
        Write-Host "        Found $sizeMB MB. Skipping download." -ForegroundColor Green
        continue
    }

    Write-Host "        Missing! Downloading..." -ForegroundColor Yellow
    curl.exe -L --ssl-no-revoke --progress-bar $arch.URL -o $installerDest
    if ((Test-Path $installerDest) -and (Get-Item $installerDest).Length -gt 1MB) {
        $sizeMB = [math]::Round((Get-Item $installerDest).Length / 1MB)
        Write-Host "        Ollama $($arch.Arch) downloaded ($sizeMB MB)" -ForegroundColor Green
    } else {
        Write-Host "        ERROR: Failed to download Ollama $($arch.Arch)!" -ForegroundColor Red
        $downloadErrors += "Ollama ($($arch.Arch))"
    }
}

# Install if not already installed or wrong architecture
if ($ollamaAlreadyInstalled -and $ollamaArchCorrect) {
    Write-Host "      Ollama already installed ($runningArch)! Skipping install..." -ForegroundColor Green
} elseif ($ollamaAlreadyInstalled -and -not $ollamaArchCorrect) {
    Write-Host "      Ollama installed but WRONG ARCHITECTURE - removing and re-extracting..." -ForegroundColor Yellow
    Get-Process ollama -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Remove-Item -LiteralPath "$USB_Drive\ollama" -Recurse -Force -ErrorAction SilentlyContinue
    $ollamaAlreadyInstalled = $false
}

if (-not ($ollamaAlreadyInstalled -and $ollamaArchCorrect)) {
    # Extract ONLY the running architecture to USB
    # Map architecture names: internal "x64" -> zip name "amd64"
    $zipArchMap = @{ "x64" = "amd64"; "Arm64" = "arm64" }
    $zipArchName = $zipArchMap[$runningArch]
    if (-not $zipArchName) { $zipArchName = $runningArch.ToLower() }
    $runningZip = Join-Path $InstallerDir "ollama-windows-$zipArchName.zip"
    if (-Not (Test-Path $runningZip)) {
        # Last resort fallback
        $runningZip = Join-Path $InstallerDir "ollama-windows-amd64.zip"
    }

    if ((Test-Path $runningZip) -and (Get-Item $runningZip).Length -gt 1MB) {
        Write-Host ""
        Write-Host "      Extracting Ollama ($runningArch) to USB..." -ForegroundColor Yellow
        try {
            $extractStart = Get-Date
            $extractJob = Start-Job -ScriptBlock {
                param($src, $dst)
                Expand-Archive -Path $src -DestinationPath $dst -Force
            } -ArgumentList $runningZip, "$USB_Drive\ollama"

            while ($extractJob.State -eq 'Running') {
                $elapsed = (Get-Date) - $extractStart
                $elapsedStr = "{0:mm\:ss}" -f $elapsed
                Show-Activity -Activity "Extracting Ollama ($runningArch)" -Status "Elapsed: $elapsedStr"
                Start-Sleep -Milliseconds 500
            }
            Hide-Activity
            Receive-Job $extractJob -ErrorAction SilentlyContinue
            Remove-Job $extractJob -Force -ErrorAction SilentlyContinue
            $extractElapsed = "{0:mm\:ss}" -f ((Get-Date) - $extractStart)
            Write-Host "      Ollama Setup Complete! - took $extractElapsed" -ForegroundColor Green
            # Verify extracted binary matches running architecture
            if (-not (Test-OllamaArch -ExePath "$USB_Drive\ollama\ollama.exe" -ExpectedArch $runningArch)) {
                Write-Host "      ERROR: Extracted ollama.exe is wrong architecture! Retrying..." -ForegroundColor Red
                Remove-Item -LiteralPath "$USB_Drive\ollama" -Recurse -Force -ErrorAction SilentlyContinue
                try {
                    Expand-Archive -Path $runningZip -DestinationPath "$USB_Drive\ollama" -Force
                    if (-not (Test-OllamaArch -ExePath "$USB_Drive\ollama\ollama.exe" -ExpectedArch $runningArch)) {
                        Write-Host "      FATAL: Ollama binary still wrong arch after re-extract!" -ForegroundColor Red
                        $downloadErrors += "Ollama ($runningArch - arch mismatch)"
                    }
                } catch {
                    Write-Host "      ERROR: Failed to re-extract Ollama" -ForegroundColor Red
                    $downloadErrors += "Ollama ($runningArch - extract failed)"
                }
            }
        } catch {
            Write-Host "      ERROR: Failed to extract Ollama. Please extract manually." -ForegroundColor Red
            Write-Host "      File: $runningZip" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "      ERROR: No Ollama installer available for running architecture ($runningArch)!" -ForegroundColor Red
        $downloadErrors += "Ollama ($runningArch)"
    }
}

# =================================================================
# STEP 6: Download llama.cpp (direct GGUF inference engine)
#         CPU-only build for running architecture + CUDA if NVIDIA GPU
# =================================================================
Write-Host ""
Write-Host "[6/10] Downloading llama.cpp - direct GGUF inference engine..." -ForegroundColor Yellow

$llamaCppDir = Join-Path $USB_Drive "llama.cpp"
$llamaServerExe = Join-Path $llamaCppDir "llama-server.exe"
$llamaCliExe = Join-Path $llamaCppDir "llama-cli.exe"

if ((Test-Path $llamaServerExe) -and (Test-Path $llamaCliExe)) {
    Write-Host "      llama.cpp already installed on USB!" -ForegroundColor Green
}

# llama.cpp release assets follow pattern: llama-b{tag}-bin-win-{variant}-{arch}.zip
# Latest release tag from GitHub API
$llamaCppTag = "b10045"
$llamaCppBaseUrl = "https://github.com/ggml-org/llama.cpp/releases/download/$llamaCppTag"

# Detect if NVIDIA GPU is available
$hasNvidiaGPU = $false
try {
    $gpuInfo = nvidia-smi --query-gpu=name --format=csv,noheader 2>$null
    if ($gpuInfo -and $gpuInfo.Length -gt 0) { $hasNvidiaGPU = $true }
} catch {}

# Define builds: CPU-only always, CUDA if GPU detected
$llamaBuilds = @(
    @{
        Arch    = "x64"
        Variant = "cpu"
        URL     = "$llamaCppBaseUrl/llama-$llamaCppTag-bin-win-cpu-x64.zip"
        File    = "llama-cpu-x64.zip"
        SizeMB  = 18
    },
    @{
        Arch    = "Arm64"
        Variant = "cpu"
        URL     = "$llamaCppBaseUrl/llama-$llamaCppTag-bin-win-cpu-arm64.zip"
        File    = "llama-cpu-arm64.zip"
        SizeMB  = 12
    }
)

# Add CUDA builds if NVIDIA GPU detected
if ($hasNvidiaGPU) {
    Write-Host "      NVIDIA GPU detected -- adding CUDA build..." -ForegroundColor Green
    $llamaBuilds += @{
        Arch    = "x64"
        Variant = "cuda-12.4"
        URL     = "$llamaCppBaseUrl/llama-$llamaCppTag-bin-win-cuda-12.4-x64.zip"
        File    = "llama-cuda-12.4-x64.zip"
        SizeMB  = 249
    }
} else {
    Write-Host "      No NVIDIA GPU detected -- CPU-only build." -ForegroundColor DarkGray
}

# ALWAYS check installer_data for missing zips and download them
foreach ($build in $llamaBuilds) {
    $isRunning = ($build.Arch -eq $runningArch)
    $tag = if ($isRunning) { " [RUNNING]" } else { "" }
    $destZip = Join-Path $InstallerDir $build.File

    Write-Host ""
    Write-Host "      Checking llama.cpp $($build.Variant) ($($build.Arch))$tag..." -ForegroundColor Yellow

    if ((Test-Path $destZip) -and (Get-Item $destZip).Length -gt 1MB) {
        $dlMB = [math]::Round((Get-Item $destZip).Length / 1MB)
        Write-Host "        Found $dlMB MB. Skipping download." -ForegroundColor Green
        continue
    }

    Write-Host "        Missing! Downloading..." -ForegroundColor Yellow
    try {
        curl.exe -L --ssl-no-revoke --progress-bar $build.URL -o $destZip
        if ((Test-Path $destZip) -and (Get-Item $destZip).Length -gt 1MB) {
            $dlMB = [math]::Round((Get-Item $destZip).Length / 1MB)
            Write-Host "        llama.cpp $($build.Variant) ($($build.Arch)) downloaded $dlMB MB" -ForegroundColor Green
        } else {
            Write-Host "        ERROR: Failed to download llama.cpp $($build.Variant) ($($build.Arch))!" -ForegroundColor Red
            $downloadErrors += "llama.cpp ($($build.Variant) $($build.Arch))"
        }
    } catch {
        Write-Host "        ERROR: Download failed: $($_.Exception.Message)" -ForegroundColor Red
        $downloadErrors += "llama.cpp ($($build.Variant) $($build.Arch))"
    }
}

# Install if not already installed
if (-not ((Test-Path $llamaServerExe) -and (Test-Path $llamaCliExe))) {
    # Extract ONLY the running architecture to USB
    $runningZip = $null
    foreach ($build in $llamaBuilds) {
        if ($build.Arch -eq $runningArch) {
            $candidate = Join-Path $InstallerDir $build.File
            if ((Test-Path $candidate) -and (Get-Item $candidate).Length -gt 1MB) {
                $runningZip = $candidate
                break
            }
        }
    }

    if ($runningZip) {
        Write-Host ""
        Write-Host "      Extracting llama.cpp ($runningArch) to USB..." -ForegroundColor Yellow
        try {
            # Remove old version if present
            if (Test-Path $llamaCppDir) {
                Get-Process -Name "llama-server","llama-cli" -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
                Remove-Item -LiteralPath $llamaCppDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            New-Item -ItemType Directory -Force -Path $llamaCppDir | Out-Null
            # Extract to temp, then move contents to llama.cpp dir
            $tempExtract = Join-Path $InstallerDir "llama_extract_temp"
            if (Test-Path $tempExtract) { Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
            Expand-Archive -Path $runningZip -DestinationPath $tempExtract -Force
            # Find all files recursively and copy them -- handles both
            # flat zips (files at root) and nested zips (files in subdirectory)
            $extractedFiles = Get-ChildItem -Path $tempExtract -File -Recurse
            foreach ($f in $extractedFiles) {
                Copy-Item -Path $f.FullName -Destination $llamaCppDir -Force
            }
            Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path $llamaServerExe) {
                $serverMB = [math]::Round((Get-Item $llamaServerExe).Length / 1MB, 1)
                Write-Host "      llama.cpp installed! - server: ${serverMB} MB" -ForegroundColor Green
            } else {
                Write-Host "      WARNING: llama-server.exe not found after extraction." -ForegroundColor Yellow
                $downloadErrors += "llama.cpp (extract - no server binary)"
            }
        } catch {
            Write-Host "      ERROR: Failed to extract llama.cpp: $($_.Exception.Message)" -ForegroundColor Red
            $downloadErrors += "llama.cpp ($runningArch - extract)"
        }
    } else {
        Write-Host "      llama.cpp $runningArch build not found in installer_data. You can re-run install.bat to retry." -ForegroundColor Yellow
    }
} else {
    Write-Host "      Skipping install -- already present." -ForegroundColor Green
}

# -----------------------------------------------------------------
# GGUFLoader: Single-file GGUF model viewer
# -----------------------------------------------------------------
$GGUF_DIR  = "$USB_Drive\ggufloader"
$GGUF_EXE  = "$GGUF_DIR\GGUFLoader.exe"
$GGUF_URL  = "https://github.com/GGUFloader/gguf-loader/releases/download/v2.0.1/GGUFLoader.2.0.1.exe"

if ((Test-Path $GGUF_EXE) -and (Get-Item $GGUF_EXE).Length -gt 1MB) {
    $ggufMB = [math]::Round((Get-Item $GGUF_EXE).Length / 1MB, 1)
    Write-Host "      GGUFLoader already installed on USB ($ggufMB MB)." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "      Downloading GGUFLoader v2.0.1 (~72MB)..." -ForegroundColor Yellow
    if (-Not (Test-Path $GGUF_DIR)) { New-Item -ItemType Directory -Force -Path $GGUF_DIR | Out-Null }
    curl.exe -L --ssl-no-revoke --progress-bar $GGUF_URL -o $GGUF_EXE
    if ((Test-Path $GGUF_EXE) -and (Get-Item $GGUF_EXE).Length -gt 1MB) {
        $ggufMB = [math]::Round((Get-Item $GGUF_EXE).Length / 1MB, 1)
        Write-Host "      GGUFLoader installed on USB ($ggufMB MB)." -ForegroundColor Green
    } else {
        Write-Host "      WARNING: GGUFLoader download failed. You can re-run install.bat to retry." -ForegroundColor Yellow
        $downloadErrors += "GGUFLoader"
    }
}

# =================================================================
# STEP 7: Download ALL CPU architecture AnythingLLM installers,
#         but ONLY install the running architecture silently
#         to the USB drive as default installation.
# =================================================================
Write-Host ""
Write-Host "[7/10] Downloading AnythingLLM - all CPU architectures..." -ForegroundColor Yellow

$InstallerDir = "$USB_Drive\installer_data"
$AnythingLLMExe = "$USB_Drive\anythingllm\AnythingLLM.exe"

# Detect current CPU architecture
# NOTE: Win32_Processor.Architecture returns wrong values on some systems
# Use PROCESSOR_ARCHITECTURE env var which is reliable
$envArch2 = $env:PROCESSOR_ARCHITECTURE
if ($envArch2 -eq "ARM64") {
    $runningArch = "Arm64"
} else {
    $runningArch = "x64"
}
Write-Host "      Detected running CPU architecture: $runningArch" -ForegroundColor DarkGray

# Define all available AnythingLLM installer architectures
$archInstallers = @(
    @{
        Arch    = "x64"
        URL     = "https://cdn.anythingllm.com/latest/AnythingLLMDesktop.exe"
        AltURL  = "https://github.com/Mintplex-Labs/anything-llm/releases/latest/download/AnythingLLMDesktop.exe"
        File    = "AnythingLLMDesktop-x64.exe"
    },
    @{
        Arch    = "Arm64"
        URL     = "https://cdn.anythingllm.com/latest/AnythingLLMDesktop-Arm64.exe"
        AltURL  = "https://github.com/Mintplex-Labs/anything-llm/releases/latest/download/AnythingLLMDesktop-Arm64.exe"
        File    = "AnythingLLMDesktop-Arm64.exe"
    }
)

# Check if AnythingLLM is already installed
$alreadyInstalled = $false
if (Test-Path $AnythingLLMExe -PathType Leaf) {
    $exeSize = (Get-Item $AnythingLLMExe).Length
    if ($exeSize -gt 50MB) {
        $alreadyInstalled = $true
    }
}

if ($alreadyInstalled) {
    Write-Host "      AnythingLLM already installed on USB!" -ForegroundColor Green
}

# ALWAYS check installer_data for missing zips and download them
foreach ($arch in $archInstallers) {
    $installerDest = Join-Path $InstallerDir $arch.File
    $isRunningArch = ($arch.Arch -eq $runningArch)
    $tag = if ($isRunningArch) { " [RUNNING]" } else { "" }

    Write-Host ""
    Write-Host "      Checking $($arch.Arch)$tag installer..." -ForegroundColor Yellow

    if ((Test-Path $installerDest) -and (Get-Item $installerDest).Length -gt 10MB) {
        $sizeMB = [math]::Round((Get-Item $installerDest).Length / 1MB)
        Write-Host "        Found $sizeMB MB. Skipping download." -ForegroundColor Green
        continue
    }

    Write-Host "        Missing! Downloading..." -ForegroundColor Yellow
    $dlOk = $false
    foreach ($dlUrl in @($arch.URL, $arch.AltURL)) {
        if ($dlOk) { break }
        Write-Host "        Trying: $dlUrl" -ForegroundColor DarkGray
        Remove-Item -LiteralPath $installerDest -Force -ErrorAction SilentlyContinue
        curl.exe -L --ssl-no-revoke --progress-bar $dlUrl -o $installerDest
        if ((Test-Path $installerDest) -and (Get-Item $installerDest).Length -gt 10MB) {
            $dlOk = $true
        } else {
            Remove-Item -LiteralPath $installerDest -Force -ErrorAction SilentlyContinue
        }
    }

    if ($dlOk) {
        $sizeMB = [math]::Round((Get-Item $installerDest).Length / 1MB)
        Write-Host "        $($arch.Arch) installer downloaded $sizeMB MB" -ForegroundColor Green
    } else {
        Write-Host "        ERROR: Failed to download $($arch.Arch) installer!" -ForegroundColor Red
        $downloadErrors += "AnythingLLM ($($arch.Arch))"
    }
}

# Install if not already installed
if (-not $alreadyInstalled) {
    # Install ONLY the running architecture silently to USB drive
    $runningInstaller = Join-Path $InstallerDir "AnythingLLMDesktop-$runningArch.exe"
    if (-Not (Test-Path $runningInstaller)) {
        # Fallback: check the non-arch-suffixed name
        $runningInstaller = Join-Path $InstallerDir "AnythingLLMDesktop.exe"
    }

    if ((Test-Path $runningInstaller) -and (Get-Item $runningInstaller).Length -gt 10MB) {
        Write-Host ""
        Write-Host "      Installing AnythingLLM ($runningArch) silently to USB..." -ForegroundColor Yellow
        Write-Host "      Target: $USB_Drive\anythingllm" -ForegroundColor DarkGray

        New-Item -ItemType Directory -Force -Path "$USB_Drive\anythingllm" | Out-Null
        New-Item -ItemType Directory -Force -Path "$USB_Drive\anythingllm_data" | Out-Null

        # Try silent install with /S flag (NSIS installer) targeting USB directory
        $installArgs = @(
            "/S",
            "/D=$USB_Drive\anythingllm"
        )

        Write-Host "      Running silent installer - this may take a few minutes..." -ForegroundColor Magenta
        $installProc = Start-Process -FilePath $runningInstaller -ArgumentList $installArgs -NoNewWindow -PassThru

        # Poll for completion with elapsed-time spinner
        $spinStart = Get-Date
        while (-not $installProc.HasExited) {
            $elapsed = (Get-Date) - $spinStart
            $elapsedStr = "{0:mm\:ss}" -f $elapsed
            Show-Activity -Activity "Installing AnythingLLM ($runningArch)" -Status "Elapsed: $elapsedStr"
            Start-Sleep -Milliseconds 500
        }
        Hide-Activity

        $installElapsed = "{0:mm\:ss}" -f ((Get-Date) - $spinStart)

        if (Test-Path "$USB_Drive\anythingllm\AnythingLLM.exe") {
            Write-Host "      AnythingLLM installed successfully to USB! - took $installElapsed" -ForegroundColor Green
        } else {
            Write-Host "      WARNING: AnythingLLM.exe not found on USB after install." -ForegroundColor Yellow
            Write-Host "      The installer may need to be run manually." -ForegroundColor Yellow
            Write-Host "      Installer saved at: $runningInstaller" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "      ERROR: No installer available for running architecture ($runningArch)!" -ForegroundColor Red
        $downloadErrors += "AnythingLLM installer"
    }
} else {
    Write-Host "      Skipping install -- already present." -ForegroundColor Green
}

# =================================================================
# STEP 7b: Install LM Studio (GUI model browser + server)
# =================================================================
Write-Host ""
Write-Host "[7b/10] Installing LM Studio..." -ForegroundColor Yellow

$lmStudioDir = "$USB_Drive\LM Studio"
$lmStudioExe = "$lmStudioDir\LM Studio.exe"
$lmStudioSettingsDir = "$lmStudioDir\.lmstudio"
$lmStudioSettingsFile = "$lmStudioSettingsDir\settings.json"

# Find installer in installer_data\lmstudio\ (match exact paths)
$lmStudioInstaller = $null
$lmStudioInstallerCandidates = @(
    "$InstallerDir\lmstudio\LM-Studio-0.4.19-2-x64.exe",
    "$InstallerDir\lmstudio\LM-Studio-0.4.19-2-arm64.exe",
    "$InstallerDir\lmstudio_installer.exe"
)
foreach ($candidate in $lmStudioInstallerCandidates) {
    if ((Test-Path $candidate) -and (Get-Item $candidate).Length -gt 10MB) {
        $lmStudioInstaller = $candidate
        break
    }
}

if (-not (Test-Path $lmStudioExe)) {
    if ($lmStudioInstaller) {
        Write-Host "      Installing LM Studio from $([System.IO.Path]::GetFileName($lmStudioInstaller))..." -ForegroundColor Cyan

        # Create .lmstudio-home-pointer for portable operation (points to USB)
        $pointerPath = Join-Path $env:USERPROFILE ".lmstudio-home-pointer"
        [System.IO.File]::WriteAllText($pointerPath, $lmStudioDir, [System.Text.UTF8Encoding]::new($false))

        # Silent install to USB drive
        Start-Process -FilePath $lmStudioInstaller -ArgumentList "/S", "/D=$lmStudioDir" -Wait -NoNewWindow
        Start-Sleep -Seconds 5

        if (Test-Path $lmStudioExe) {
            Write-Host "      LM Studio installed successfully." -ForegroundColor Green
        } else {
            Write-Host "      WARNING: LM Studio install may have failed. Check $lmStudioDir" -ForegroundColor Yellow
            $downloadErrors += "LM Studio"
        }
    } else {
        Write-Host "      WARNING: LM Studio installer not found in installer_data\lmstudio\" -ForegroundColor Yellow
        Write-Host "      Download manually from https://lmstudio.ai and place in installer_data\lmstudio\" -ForegroundColor Yellow
        $downloadErrors += "LM Studio (no installer found)"
    }
} else {
    Write-Host "      LM Studio already installed." -ForegroundColor Green
}

# Configure LM Studio for portable USB operation
if (Test-Path $lmStudioExe) {
    if (-not (Test-Path $lmStudioSettingsDir)) {
        New-Item -ItemType Directory -Path $lmStudioSettingsDir -Force | Out-Null
    }
    # Write settings.json pointing model directory to USB
    $settingsContent = @"
{
    "modelDirectory": "$($USB_Drive -replace '\\','/')/models"
}
"@
    [System.IO.File]::WriteAllText($lmStudioSettingsFile, $settingsContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "      Configured LM Studio model directory: $USB_Drive\models\" -ForegroundColor Green
}

# =================================================================
# STEP 8: Create storage structure and .env config
# =================================================================
Write-Host ""
Write-Host "[8/10] Configuring AnythingLLM portable storage..." -ForegroundColor Yellow

$storageDir = "$USB_Drive\anythingllm_data\storage"
New-Item -ItemType Directory -Force -Path $storageDir | Out-Null

$firstModelLocal = $SelectedModels[0].Local
$envFilePath = "$storageDir\.env"

$envContent = @"
# AnythingLLM Portable USB Configuration
LLM_PROVIDER=ollama
OLLAMA_BASE_PATH=http://127.0.0.1:11434
OLLAMA_MODEL_PREF=$firstModelLocal
OLLAMA_MODEL_TOKEN_LIMIT=4096
EMBEDDING_ENGINE=native
VECTOR_DB=lancedb
STORAGE_DIR=$storageDir
SERVER_PORT=3001
SIG_KEY=passphrase
SIG_SALT=salt
DisableTelemetry=true
"@

if (-Not (Test-Path $envFilePath)) {
    Set-Content -Path $envFilePath -Value $envContent -Force -Encoding UTF8
    Write-Host "      Created .env config on USB" -ForegroundColor Green
} else {
    $existing = Get-Content $envFilePath -Raw
    if ($existing -notmatch 'LLM_PROVIDER=ollama') {
        Set-Content -Path $envFilePath -Value $envContent -Force -Encoding UTF8
        Write-Host "      Reconfigured AnythingLLM for external Ollama." -ForegroundColor Green
    } else {
        Write-Host "      AnythingLLM already configured for Ollama." -ForegroundColor Green
    }
}

Write-Host "      Default model: $firstModelLocal" -ForegroundColor DarkGray

# =================================================================
# STEP 9: IMPORT ALL SELECTED MODELS INTO OLLAMA ENGINE
# =================================================================
Write-Host ""
Write-Host "[9/10] Importing AI models into the Ollama engine..." -ForegroundColor Yellow

$IMPORT_TIMEOUT_MIN = 60
$IMPORT_LOG  = "$USB_Drive\install_import.log"

"=== Import started $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $IMPORT_LOG -Force -Encoding UTF8

function Write-ImportLog {
    param([string]$Message)
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts  $Message" | Out-File -FilePath $IMPORT_LOG -Append -Encoding UTF8
}

# -----------------------------------------------------------------
# HELPER: Check if Ollama server is responding on port 11434
# -----------------------------------------------------------------
function Test-OllamaServer {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("127.0.0.1", 11434)
        $tcp.Close()
        return $true
    } catch { return $false }
}

# -----------------------------------------------------------------
# HELPER: Find the actual manifest for a model (recursive search)
# -----------------------------------------------------------------
function Find-OllamaManifest {
    param([string]$ModelName)
    $manifestRoot = "$OLLAMA_DATA\manifests"
    if (-Not (Test-Path $manifestRoot)) { return $null }
    $found = Get-ChildItem -Path $manifestRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DirectoryName -match [regex]::Escape($ModelName) -and
            $_.Length -gt 10
        } | Select-Object -First 1
    return $found
}

# -----------------------------------------------------------------
# HELPER: Check if a model has a valid manifest (no server needed)
# -----------------------------------------------------------------
function Test-OllamaManifest {
    param([string]$ModelName)
    $found = Find-OllamaManifest -ModelName $ModelName
    return ($null -ne $found)
}

# -----------------------------------------------------------------
# HELPER: Find all blob hashes referenced by a model's manifest
#         Returns array of @{ Hash; Size; Exists }
# -----------------------------------------------------------------
function Find-ModelLayers {
    param([string]$ModelName)
    $layers = @()
    $manifest = Find-OllamaManifest -ModelName $ModelName
    if (-Not $manifest) { return $layers }
    try {
        $json = Get-Content $manifest.FullName -Raw -ErrorAction SilentlyContinue
        $obj = $json | ConvertFrom-Json -ErrorAction SilentlyContinue
        if (-Not $obj) { return $layers }
        # Check all layers (config + media + any other)
        $allLayers = @()
        if ($obj.layers) { $allLayers += $obj.layers }
        if ($obj.config) { $allLayers += @($obj.config) }
        foreach ($layer in $allLayers) {
            if ($layer.digest) {
                $hash = $layer.digest -replace '^sha256:', ''
                $blobPath = "$OLLAMA_DATA\blobs\sha256-$hash"
                $exists = Test-Path $blobPath
                $size = 0
                if ($exists) { $size = (Get-Item $blobPath -ErrorAction SilentlyContinue).Length }
                $layers += @{ Hash = $hash; Size = $size; Exists = $exists; Digest = $layer.digest }
            }
        }
    } catch {}
    return $layers
}

# -----------------------------------------------------------------
# HELPER: Validate manifest integrity (JSON valid + all blobs exist)
#         Returns @{ Valid; Reason }
# -----------------------------------------------------------------
function Test-ManifestIntegrity {
    param([string]$ModelName)
    $manifest = Find-OllamaManifest -ModelName $ModelName
    if (-Not $manifest) { return @{ Valid = $false; Reason = "no manifest file" } }
    try {
        $json = Get-Content $manifest.FullName -Raw -ErrorAction SilentlyContinue
        if (-Not $json -or $json.Trim().Length -lt 10) {
            return @{ Valid = $false; Reason = "manifest empty or too small" }
        }
        $obj = $json | ConvertFrom-Json -ErrorAction SilentlyContinue
        if (-Not $obj) { return @{ Valid = $false; Reason = "manifest not valid JSON" } }
        if (-Not $obj.layers -or $obj.layers.Count -eq 0) {
            return @{ Valid = $false; Reason = "manifest has no layers" }
        }
        # Check all referenced blobs exist
        $missingBlobs = @()
        $allLayers = @()
        if ($obj.layers) { $allLayers += $obj.layers }
        if ($obj.config) { $allLayers += @($obj.config) }
        foreach ($layer in $allLayers) {
            if ($layer.digest) {
                $hash = $layer.digest -replace '^sha256:', ''
                $blobPath = "$OLLAMA_DATA\blobs\sha256-$hash"
                if (-Not (Test-Path $blobPath)) {
                    $missingBlobs += $layer.digest
                } elseif ((Get-Item $blobPath).Length -eq 0) {
                    $missingBlobs += "$($layer.digest) (zero bytes)"
                }
            }
        }
        if ($missingBlobs.Count -gt 0) {
            return @{ Valid = $false; Reason = "missing $($missingBlobs.Count) blob(s): $($missingBlobs -join ', ')" }
        }
        return @{ Valid = $true; Reason = "ok ($($obj.layers.Count) layers)" }
    } catch {
        return @{ Valid = $false; Reason = "exception: $($_.Exception.Message)" }
    }
}

# -----------------------------------------------------------------
# HELPER: Get existing blob count and total size in blobs dir
# -----------------------------------------------------------------
function Get-BlobStats {
    $count = 0; $totalSize = 0
    if (Test-Path $OLLAMA_DATA\blobs) {
        Get-ChildItem -Path "$OLLAMA_DATA\blobs" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '^COPY' -and $_.Name -match '^sha256-' } |
            ForEach-Object { $count++; $totalSize += $_.Length }
    }
    return @{ Count = $count; TotalMB = [math]::Round($totalSize / 1MB, 1) }
}

# -----------------------------------------------------------------
# HELPER: Start Ollama server (returns process)
# -----------------------------------------------------------------
function Start-OllamaServer {
    $env:OLLAMA_MODELS = $OLLAMA_DATA
    $env:OLLAMA_HOST   = "127.0.0.1:11434"
    $env:OLLAMA_KEEP_ALIVE = "30m"
    $env:OLLAMA_MAX_LOADED_MODELS = "1"
    $env:OLLAMA_FLASH_ATTENTION = "1"
    # Kill any existing ollama/llama processes first
    Get-Process -Name "ollama","llama-quantize","ollama_llama_server" -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Start-Sleep -Seconds 1
    $proc = Start-Process -FilePath "$USB_Drive\ollama\ollama.exe" `
        -ArgumentList "serve" -WindowStyle Hidden -PassThru
    Write-Host "      Waiting for Ollama server" -NoNewline -ForegroundColor DarkGray
    for ($i = 1; $i -le 30; $i++) {
        Start-Sleep -Milliseconds 1000
        Write-Host "." -NoNewline -ForegroundColor DarkGray
        if (Test-OllamaServer) {
            Write-Host " ready!" -ForegroundColor Green
            return $proc
        }
    }
    Write-Host " - proceeding anyway" -ForegroundColor Yellow
    return $proc
}

# -----------------------------------------------------------------
# HELPER: Query ollama list to find already-imported models
#         Has a timeout so it cannot hang if server is not ready
# -----------------------------------------------------------------
function Get-OllamaImportedModels {
    param([int]$TimeoutSeconds = 15)
    $imported = @{}
    $listLog = "$env:TEMP\ollama_list.log"
    $listBat = "$env:TEMP\ollama_list.bat"
    Remove-Item -LiteralPath $listLog -Force -ErrorAction SilentlyContinue
    $batContent = @"
@echo off
set "OLLAMA_MODELS=$OLLAMA_DATA"
set "OLLAMA_HOST=127.0.0.1:11434"
"$USB_Drive\ollama\ollama.exe" list> "$listLog" 2>&1
"@
    Set-Content -Path $listBat -Value $batContent -Force -Encoding ASCII
    try {
        $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$listBat`"" `
            -NoNewWindow -PassThru
        $waited = 0
        while (-not $p.HasExited -and $waited -lt $TimeoutSeconds) {
            Start-Sleep -Seconds 1
            $waited++
        }
        if (-not $p.HasExited) {
            try { $p.Kill() } catch {}
            Write-Host "      ollama list timed out after ${TimeoutSeconds}s" -ForegroundColor Yellow
        }
        Start-Sleep -Milliseconds 500
        if (Test-Path $listLog) {
            $lines = Get-Content $listLog -ErrorAction SilentlyContinue
            foreach ($line in $lines) {
                if ($line -match '^\s*(\S+)') {
                    $name = $Matches[1].Trim()
                    $name = $name -replace ':latest$', ''
                    if ($name -and $name -ne "NAME") { $imported[$name] = $true }
                }
            }
        }
    } catch {
        Write-Host "      ollama list error: $($_.Exception.Message)" -ForegroundColor Yellow
    } finally {
        Remove-Item -LiteralPath $listBat -Force -ErrorAction SilentlyContinue
    }
    return $imported
}

# -----------------------------------------------------------------
# HELPER: Estimate timeout for a GGUF based on file size
#         Minimum 30 min, scales with size
# -----------------------------------------------------------------
function Get-ImportTimeoutMinutes {
    param([string]$GGUFPath)
    if (-Not (Test-Path $GGUFPath)) { return $IMPORT_TIMEOUT_MIN }
    $sizeGB = (Get-Item $GGUFPath).Length / 1GB
    $estimated = [math]::Ceiling($sizeGB * 15)
    $timeout = [math]::Max(45, [math]::Min($estimated, 180))
    return $timeout
}

# -----------------------------------------------------------------
# HELPER: Import a single model via ollama create
#         Uses cmd.exe bat with all output captured to log file.
#         Shows inline console progress bar with blob growth + elapsed time.
#         Returns hashtable: @{ Success; ExitCode; Output; Elapsed }
# -----------------------------------------------------------------
function Invoke-OllamaCreate {
    param(
        [string]$LocalName,
        [string]$DisplayName,
        [string]$GGUFFile,
        [long]$BlobSizeBefore = 0,
        [int]$ModelIndex = 0,
        [int]$ModelTotal = 1
    )
    $result = @{ Success = $false; ExitCode = -1; Output = ""; Elapsed = "0:00" }
    # Find GGUF and Modelfile by recursive search (supports nested publisher/model dirs)
    $ggufPath  = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter $GGUFFile -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    $modelfile = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter "Modelfile" -File -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -match [regex]::Escape($LocalName) } | Select-Object -First 1 -ExpandProperty FullName
    if (-not $ggufPath) { $ggufPath = "$MODELS_DIR\$GGUFFile" }
    if (-not $modelfile) { $modelfile = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter "Modelfile-$LocalName" -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
    $blobDir   = "$OLLAMA_DATA\blobs"
    $logFile   = "$env:TEMP\ollama_create_$LocalName.log"
    $batFile   = "$env:TEMP\ollama_import_$LocalName.bat"

    Write-ImportLog "INVOKE-CREATE START: $LocalName | GGUF=$GGUFFile | BlobBefore=$BlobSizeBefore"

    if (-Not (Test-Path $ggufPath)) {
        $result.Output = "GGUF file not found: $GGUFFile"
        Write-ImportLog "INVOKE-CREATE ABORT: GGUF not found"
        return $result
    }
    if (-Not (Test-Path $modelfile)) {
        $result.Output = "Modelfile not found: Modelfile-$LocalName"
        Write-ImportLog "INVOKE-CREATE ABORT: Modelfile not found"
        return $result
    }

    $ggufGB = [math]::Round((Get-Item $ggufPath).Length / 1GB, 2)

    # Verify server is responding
    if (-Not (Test-OllamaServer)) {
        $result.Output = "Ollama server not responding on 127.0.0.1:11434"
        Write-ImportLog "INVOKE-CREATE ABORT: server not responding"
        return $result
    }

    # Pre-create layer scan: check how many blobs already exist for this model
    $existingLayers = Find-ModelLayers -ModelName $LocalName
    $existingCount = ($existingLayers | Where-Object { $_.Exists }).Count
    $totalCount = $existingLayers.Count
    if ($totalCount -gt 0) {
        $existingGB = [math]::Round(($existingLayers | Where-Object { $_.Exists } | ForEach-Object { $_.Size } | Measure-Object -Sum).Sum / 1GB, 2)
        Write-Host "      Existing layers: $existingCount/$totalCount ($existingGB GB already present)" -ForegroundColor DarkCyan
        Write-ImportLog "Pre-create layers: $existingCount/$totalCount present ($existingGB GB)"
    } else {
        Write-Host "      No existing layers found - full import" -ForegroundColor DarkCyan
        Write-ImportLog "Pre-create layers: none found - full import"
    }

    # Write bat - ALL output goes to log, ZERO console output
    # Use the directory containing the found Modelfile as the working directory
    $batModelDir = if ($modelfile) { Split-Path $modelfile -Parent } else { $MODELS_DIR }
    $batModelfile = if ($modelfile) { Split-Path $modelfile -Leaf } else { "Modelfile-$LocalName" }
    $batContent = @"
@echo off
set "OLLAMA_MODELS=$OLLAMA_DATA"
set "OLLAMA_HOST=127.0.0.1:11434"
cd /d "$batModelDir"
echo [%date% %time%] === ollama create $LocalName ===>> "$logFile" 2>&1
echo [%date% %time%] Modelfile content:>> "$logFile" 2>&1
type "$batModelfile">> "$logFile" 2>&1
echo.>> "$logFile" 2>&1
echo [%date% %time%] Starting ollama create...>> "$logFile" 2>&1
"$USB_Drive\ollama\ollama.exe" create "$LocalName" -f "$batModelfile">> "$logFile" 2>&1
echo [%date% %time%] EXIT_CODE=%ERRORLEVEL%>> "$logFile" 2>&1
"@
    Set-Content -Path $batFile -Value $batContent -Force -Encoding ASCII
    Set-Content -Path $logFile  -Value "" -Force

    $startTime       = Get-Date
    $lastBlobCheck   = Get-Date
    $cachedBlobMB    = 0
    $reached100      = $false
    $reached100Time  = $null
    $wasOnLine2      = $false
    $startRow        = -1
    $lastChangeTime  = Get-Date
    $lastBlobMB      = 0
    $lastLogContent  = ""
    $stallCheckMin   = 5
    $lastLogRead     = [DateTime]::MinValue
    $lastUniqueMsg   = ""
    $phase           = "starting"
    $lastPhaseLog    = ""
    $lastManifestCheck = [DateTime]::MinValue
    $lastLogPosition = 0
    $prevLogFileSize = 0
    $prevPhaseMsg    = ""
    $lastServerCheck = Get-Date
    # Snapshot blob count at start for layer detection during finalization
    $blobCountAtStart = 0
    if (Test-Path $blobDir) {
        $blobCountAtStart = @(Get-ChildItem -Path $blobDir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^sha256-' }).Count
    }

    try {
        Write-ImportLog "Starting cmd.exe /c $batFile"
        $proc = Start-Process -FilePath "cmd.exe" `
            -ArgumentList "/c `"$batFile`"" `
            -NoNewWindow -PassThru
        Write-ImportLog "cmd.exe PID=$($proc.Id)"

        while (-not $proc.HasExited) {
            $elapsed    = (Get-Date) - $startTime
            $elapsedStr = "{0:mm\:ss}" -f $elapsed

            # Update blob size every 3s
            if ((Get-Date) - $lastBlobCheck -ge [TimeSpan]::FromMilliseconds(3000)) {
                $blobSizeNow = 0
                if (Test-Path $blobDir) {
                    Get-ChildItem -Path $blobDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $blobSizeNow += $_.Length }
                }
                $cachedBlobMB = [math]::Round(($blobSizeNow - $BlobSizeBefore) / 1MB, 1)
                $lastBlobCheck = Get-Date

                # Track if anything changed
                if ($cachedBlobMB -ne $lastBlobMB) {
                    $lastChangeTime = Get-Date
                    $lastBlobMB = $cachedBlobMB
                }

                Write-ImportLog "Blob check: +${cachedBlobMB} MB (before=$BlobSizeBefore, now=$blobSizeNow)"
            }

            # Early completion check: throttled to every 5s to avoid excessive I/O
            if ((Get-Date) - $lastManifestCheck -ge [TimeSpan]::FromSeconds(5)) {
                $lastManifestCheck = Get-Date

                if (Test-OllamaManifest -ModelName $LocalName) {
                    $manifestValid = $false
                    try {
                        $manifestPath = Find-OllamaManifest -ModelName $LocalName
                        if ($manifestPath -and (Test-Path $manifestPath)) {
                            $manifestContent = Get-Content $manifestPath -Raw -ErrorAction SilentlyContinue
                            if ($manifestContent -and $manifestContent.Length -gt 10) {
                                $null = $manifestContent | ConvertFrom-Json -ErrorAction Stop
                                $manifestValid = $true
                            }
                        }
                    } catch {}

                    if ($manifestValid) {
                        try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow); [Console]::Write((" " * 110)); [Console]::SetCursorPosition(0, $startRow + 1); [Console]::Write((" " * 110)) } } catch {}
                        Write-Host "      Manifest detected - import complete! (${elapsedStr})" -ForegroundColor Green
                        Write-ImportLog "EARLY COMPLETION: Valid manifest found at ${elapsedStr}, treating as success"
                        try { $proc.Kill() } catch {}
                        $result.ExitCode = 0
                        $result.Elapsed = $elapsedStr
                        $result.Success = $true
                        if (Test-Path $logFile) {
                            $result.Output = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
                        }
                        return $result
                    }
                }

                if (Test-Path $logFile) {
                    try {
                        $logCheckQuick = Get-Content $logFile -Tail 20 -ErrorAction SilentlyContinue
                        if ($logCheckQuick -match '(?m)^\s*success\s*$') {
                            if (Test-OllamaManifest -ModelName $LocalName) {
                                try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow); [Console]::Write((" " * 110)); [Console]::SetCursorPosition(0, $startRow + 1); [Console]::Write((" " * 110)) } } catch {}
                                Write-Host "      'success' found in log - import complete! (${elapsedStr})" -ForegroundColor Green
                                Write-ImportLog "EARLY COMPLETION: 'success' in log + manifest at ${elapsedStr}"
                                try { $proc.Kill() } catch {}
                                $result.ExitCode = 0
                                $result.Elapsed = $elapsedStr
                                $result.Success = $true
                                $result.Output = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
                                return $result
                            }
                        }
                    } catch {}
                }
            }

            # Stall detection: if at 100% and nothing changed for $stallCheckMin minutes
            if ($reached100) {
                $stallMin = [int]((Get-Date) - $lastChangeTime).TotalMinutes
                if ($stallMin -ge $stallCheckMin) {
                    # Check if manifest was actually written (process may have finished silently)
                    if (Test-OllamaManifest -ModelName $LocalName) {
                        try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow); [Console]::Write((" " * 110)); [Console]::SetCursorPosition(0, $startRow + 1); [Console]::Write((" " * 110)) } } catch {}
                        Write-Host "      Manifest detected after ${stallMin} min stall - process likely completed" -ForegroundColor Green
                        Write-ImportLog "STALL RECOVERY: Manifest found after ${stallMin} min, treating as success"
                        try { $proc.Kill() } catch {}
                        $result.ExitCode = 0
                        $result.Elapsed = $elapsedStr
                        $result.Success = $true
                        if (Test-Path $logFile) {
                            $result.Output = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
                        }
                        return $result
                    }
                    # Also check the ollama log for "success"
                    if (Test-Path $logFile) {
                        $logCheck = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
                        if ($logCheck -match '(?m)^\s*success\s*$') {
                            try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow); [Console]::Write((" " * 110)); [Console]::SetCursorPosition(0, $startRow + 1); [Console]::Write((" " * 110)) } } catch {}
                            Write-Host "      'success' found in log after ${stallMin} min stall" -ForegroundColor Green
                            Write-ImportLog "STALL RECOVERY: 'success' in log after ${stallMin} min, treating as success"
                            try { $proc.Kill() } catch {}
                            $result.ExitCode = 0
                            $result.Elapsed = $elapsedStr
                            $result.Success = $true
                            $result.Output = $logCheck
                            return $result
                        }
                    }
                    if ($stallMin -eq $stallCheckMin) {
                        Write-ImportLog "STALL WARNING: No progress for ${stallCheckMin} min at 100% (PID=$($proc.Id))"
                    }
                }
            }

            # Log reading: compare old file size vs current, read only delta if changed
            if ((Get-Date) - $lastLogRead -ge [TimeSpan]::FromMilliseconds(2000)) {
                $lastLogRead = Get-Date
                if (Test-Path $logFile) {
                    try {
                        $curFileSize = (Get-Item $logFile).Length
                        if ($curFileSize -gt $prevLogFileSize) {
                            # File grew -- read only the new bytes
                            $fs = $null; $sr = $null; $newText = ""
                            try {
                                $fs = [System.IO.File]::Open($logFile, 'Open', 'Read', 'ReadWrite')
                                $fs.Seek($lastLogPosition, 'Begin') | Out-Null
                                $sr = New-Object System.IO.StreamReader($fs)
                                $newText = $sr.ReadToEnd()
                                $lastLogPosition = $fs.Position
                            } finally {
                                if ($sr) { try { $sr.Close() } catch {} }
                                if ($fs) { try { $fs.Close() } catch {} }
                            }
                            $prevLogFileSize = $curFileSize

                            # Extract the last meaningful phase message from delta
                            $segments = $newText -split '\x1B'
                            foreach ($seg in $segments) {
                                $clean = $seg -replace '\[[0-9;]*[A-Za-z]', '' -replace '\[\?[0-9;]*[a-z]', '' -replace '[^\x20-\x7E]', '' -replace '\s+', ' '
                                $clean = $clean.Trim()
                                if ($clean -and $clean.Length -gt 2 -and $clean -ne 'success' -and $clean -notmatch '^\[' -and $clean -notmatch '^=== ' -and $clean -notmatch '^Modelfile' -and $clean -notmatch '^FROM ' -and $clean -notmatch '^PARAMETER' -and $clean -notmatch '^SYSTEM' -and $clean -notmatch '^Starting') {
                                    $prevPhaseMsg = $clean
                                }
                            }
                            $lastUniqueMsg = $prevPhaseMsg
                        }
                    } catch {}
                }
                # Determine phase from last unique message
                if ($lastUniqueMsg -match 'parsing GGUF') { $phase = "parsing" }
                elseif ($lastUniqueMsg -match 'copying file') { $phase = "copying" }
                elseif ($lastUniqueMsg -match 'verifying conversion') { $phase = "verifying" }
                elseif ($lastUniqueMsg -match 'creating layer') { $phase = "creating" }
                elseif ($lastUniqueMsg -match 'gathering model') { $phase = "gathering" }
                elseif ($lastUniqueMsg -match 'writing manifest') { $phase = "manifest" }
                elseif ($lastUniqueMsg -match 'success') { $phase = "done" }
                # Track phase log for change detection
                if ($lastUniqueMsg -ne $lastPhaseLog) {
                    $lastChangeTime = Get-Date
                    $lastPhaseLog = $lastUniqueMsg
                }
            }

            # Inline console progress bar + ollama status
            try {
                # Build status based on phase
                if ($phase -eq "parsing") {
                    $statusPart = "Parsing GGUF (hash)... $elapsedStr"
                    $barWidth = 30
                    $rotPos = [math]::Floor($elapsed.TotalSeconds) % $barWidth
                    $bar = "." * $rotPos + "#" + "." * ($barWidth - $rotPos - 1)
                    $fillPct = -1
                } elseif ($phase -eq "gathering") {
                    $statusPart = "Gathering components... $elapsedStr"
                    $barWidth = 30
                    $rotPos = [math]::Floor($elapsed.TotalSeconds) % $barWidth
                    $bar = "." * $rotPos + "#" + "." * ($barWidth - $rotPos - 1)
                    $fillPct = -1
                } elseif ($phase -eq "copying") {
                    $statusPart = if ($cachedBlobMB -gt 0) { "Copying blob: +${cachedBlobMB} MB" } else { "Copying..." }
                    $barWidth = 30
                    $fillPct = if ($cachedBlobMB -gt 0 -and $ggufGB -gt 0) {
                        [math]::Min(100, [math]::Round(($cachedBlobMB / ($ggufGB * 1024)) * 100))
                    } else { 0 }
                    $filled = [math]::Round($barWidth * $fillPct / 100)
                    $empty = $barWidth - $filled
                    $bar = ("#" * $filled) + ("." * $empty)
                } elseif ($phase -eq "verifying" -or $phase -eq "creating" -or $phase -eq "manifest") {
                    $statusPart = "Finalizing..."
                    $barWidth = 30
                    $bar = ("#" * $barWidth)
                    $fillPct = 100
                } elseif ($phase -eq "done") {
                    $statusPart = "Complete!"
                    $barWidth = 30
                    $bar = ("#" * $barWidth)
                    $fillPct = 100
                } else {
                    $statusPart = "Starting..."
                    $barWidth = 30
                    $bar = "." * $barWidth
                    $fillPct = 0
                }

                if ($fillPct -ge 100 -and -not $reached100) {
                    $reached100 = $true
                    $reached100Time = Get-Date
                    Write-ImportLog "Progress reached 100% - ollama finalizing..."
                }

                if ($reached100 -and $phase -ne "parsing" -and $phase -ne "copying") {
                    $finSec = [int]((Get-Date) - $reached100Time).TotalSeconds
                    $statusPart = "Finalizing (${finSec}s)..."
                }

                $pctStr = if ($fillPct -lt 0) { "..." } else { "$fillPct%" }
                $dispName = if ($DisplayName.Length -gt 25) { $DisplayName.Substring(0, 22) + "..." } else { $DisplayName }
                # Overall job progress: completed models + time-based progress for current model
                $jobPct = if ($ModelTotal -gt 0 -and $ModelIndex -gt 0) {
                    $completedPct = [math]::Round(($ModelIndex - 1) * 100 / $ModelTotal)
                    # Use blob progress if available, otherwise fall back to time-based estimate
                    $currentPct = if ($fillPct -ge 0) {
                        [math]::Round($fillPct / $ModelTotal)
                    } elseif ($IMPORT_TIMEOUT_MIN -gt 0) {
                        [math]::Min(99, [math]::Round(($elapsed.TotalMinutes / $IMPORT_TIMEOUT_MIN) * 100 / $ModelTotal))
                    } else { 0 }
                    [math]::Min(100, $completedPct + $currentPct)
                } else { 0 }
                $progLine = "      [$ModelIndex/$ModelTotal] $dispName ($ggufGB GB) | $statusPart | [$bar] $pctStr | job:$jobPct%"
                $pad = [math]::Max(0, 110 - $progLine.Length)

                # Capture cursor position on first write
                if ($startRow -lt 0) {
                    $startRow = [Console]::CursorTop
                }

                # Go back to start row, clear detail line if we wrote one
                try {
                    if ($wasOnLine2) {
                        [Console]::SetCursorPosition(0, $startRow + 1)
                        [Console]::Write((" " * 110))
                    }
                    [Console]::SetCursorPosition(0, $startRow)
                } catch {}

                [Console]::Write($progLine + (" " * $pad))

                # Second line: show ollama's actual status message (deduplicated)
                $detailLine = ""
                if ($lastUniqueMsg -and $phase -ne "starting") {
                    $detailLine = $lastUniqueMsg
                    if ($detailLine.Length -gt 85) {
                        $detailLine = $detailLine.Substring(0, 82) + "..."
                    }
                }

                if ($detailLine) {
                    $tailPad = [math]::Max(0, 110 - $detailLine.Length)
                    try { [Console]::SetCursorPosition(0, $startRow + 1) } catch {}
                    [Console]::Write("      > $detailLine" + (" " * $tailPad))
                    $wasOnLine2 = $true
                } else {
                    $wasOnLine2 = $false
                }

                [Console]::Out.Flush()
            } catch {}

            # Hard timeout
            if ($elapsed.TotalMinutes -ge $IMPORT_TIMEOUT_MIN) {
                try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow); [Console]::Write((" " * 110)) } } catch {}
                try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow + 1); [Console]::Write((" " * 110)) } } catch {}
                $msg = "TIMEOUT after $IMPORT_TIMEOUT_MIN min (PID=$($proc.Id))"
                Write-Host "      $msg" -ForegroundColor Red
                Write-ImportLog "TIMEOUT: $msg"
                try { $proc.Kill() } catch {}
                $result.Output = $msg
                $result.Elapsed = $elapsedStr
                return $result
            }

            Start-Sleep -Milliseconds 1000

            # Server health check: detect if ollama server died during import
            if ((Get-Date) - $lastServerCheck -ge [TimeSpan]::FromSeconds(10)) {
                $lastServerCheck = Get-Date
                if (-not (Test-OllamaServer)) {
                    Write-ImportLog "SERVER DIED: Ollama server no longer responding at ${elapsedStr}"
                    # Kill the orphaned cmd.exe if still running
                    try { if (-not $proc.HasExited) { $proc.Kill() } } catch {}
                    $result.Output = "Ollama server crashed during import at ${elapsedStr}"
                    $result.Elapsed = $elapsedStr
                    $result.ExitCode = -1
                    return $result
                }
            }
        }
        # Clear both lines when done
        try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow); [Console]::Write((" " * 110)) } } catch {}
        try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow + 1); [Console]::Write((" " * 110)) } } catch {}
        Write-Host ""

                $result.ExitCode = if ($proc) { $proc.ExitCode } else { -1 }
                $result.Elapsed  = "{0:mm\:ss}" -f ((Get-Date) - $startTime)

                if (Test-Path $logFile) {
                    $result.Output = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
                }
                if ($result.ExitCode -eq 0) {
                    $result.Success = $true
                }
                # Fallback: check ollama log for "success" (cmd.exe ExitCode can be unreliable)
                if (-not $result.Success -and $result.Output) {
                    $logLines = $result.Output -split "`r?`n"
                    $hasSuccess = $logLines | Where-Object { $_.Trim() -eq 'success' }
                    if ($hasSuccess) {
                        $result.Success = $true
                        Write-ImportLog "Detected 'success' in ollama log lines (ExitCode was: $($result.ExitCode))"
                    }
                }
                # Ultimate fallback: check if manifest was written
                if (-not $result.Success) {
                    if (Test-OllamaManifest -ModelName $LocalName) {
                        $result.Success = $true
                        Write-ImportLog "Manifest exists for $LocalName (ExitCode was: $($result.ExitCode)) - treating as success"
                    }
                }
                Write-ImportLog "Process exited: ExitCode=$($result.ExitCode) Elapsed=$($result.Elapsed) Success=$($result.Success)"
            } catch {
                try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow); [Console]::Write((" " * 110)) } } catch {}
                try { if ($startRow -ge 0) { [Console]::SetCursorPosition(0, $startRow + 1); [Console]::Write((" " * 110)) } } catch {}
        Write-Host ""
        $result.Output = "Exception: $($_.Exception.Message)"
        $result.Elapsed = "{0:mm\:ss}" -f ((Get-Date) - $startTime)
        Write-ImportLog "EXCEPTION: $($_.Exception.Message)"
    } finally {
        Remove-Item -LiteralPath $batFile -Force -ErrorAction SilentlyContinue
    }
    Write-ImportLog "INVOKE-CREATE END: $LocalName Success=$($result.Success)"
    return $result
}

# =================================================================
# MAIN IMPORT LOGIC
# =================================================================
if (-Not (Test-Path "$USB_Drive\ollama\ollama.exe")) {
    Write-Host "      ERROR: Ollama not found! Cannot import models." -ForegroundColor Red
    Write-Host "      Please re-run the installer to download Ollama." -ForegroundColor Red
} else {
    $env:OLLAMA_MODELS = $OLLAMA_DATA
    New-Item -ItemType Directory -Force -Path $OLLAMA_DATA | Out-Null
    Set-Location $MODELS_DIR

    # -----------------------------------------------------------------
    # Kill ALL leftover Ollama + AnythingLLM processes from prior runs
    # -----------------------------------------------------------------
    foreach ($pattern in @("ollama*","AnythingLLM*")) {
        $procs = Get-Process -Name $pattern -ErrorAction SilentlyContinue
        if ($procs) {
            Write-Host "      Killing leftover $pattern processes ($($procs.Count))..." -ForegroundColor Yellow
            $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Sleep -Seconds 1

    # -----------------------------------------------------------------
    # Phase A: Process models flagged for rebuild (GGUF valid but
    #          blobs/manifest missing or corrupt - detected during download)
    # -----------------------------------------------------------------
    $blobDir = "$OLLAMA_DATA\blobs"
    if ($needsRebuild.Count -gt 0) {
        Write-Host ""
        Write-Host "      $($needsRebuild.Count) model(s) need Ollama blob/manifest rebuild:" -ForegroundColor Yellow
        foreach ($rb in $needsRebuild) {
            Write-Host "        - $($rb.DisplayName)" -ForegroundColor Yellow
        }
        Write-Host "      Building blobs and manifests directly (no server needed)..." -ForegroundColor Yellow

        $rbIdx = 0
        foreach ($rb in $needsRebuild) {
            $rbIdx++
            $ggufPath = if ($rb.GGUFPath) { $rb.GGUFPath } else { "$MODELS_DIR\$($rb.GGUFFile)" }
            if (-not (Test-Path $ggufPath)) {
                $ggufPath = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter $rb.GGUFFile -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
            }
            if (-not (Test-Path $ggufPath)) {
                Write-Host "        ($rbIdx/$($needsRebuild.Count)) $($rb.DisplayName) - GGUF not found, skipping" -ForegroundColor Red
                continue
            }
            Write-Host "        ($rbIdx/$($needsRebuild.Count)) $($rb.DisplayName) - building blobs..." -ForegroundColor DarkGray -NoNewline
            $prompt = if ($rb.Prompt) { $rb.Prompt } else { "You are a helpful AI assistant." }
            $buildResult = Build-OllamaModel -ModelName $rb.LocalName -GGUFPath $ggufPath -SystemPrompt $prompt
            if ($buildResult.Success) {
                Write-Host " OK! ($($buildResult.BlobSizeMB) MB blob, hash: $($buildResult.GGUFHash.Substring(0,8))...)" -ForegroundColor Green
            } else {
                Write-Host " FAILED: $($buildResult.Reason)" -ForegroundColor Red
                $downloadErrors += "Blob build: $($rb.DisplayName) ($($buildResult.Reason))"
            }
        }
    } else {
        Write-Host "      No models need blob rebuild." -ForegroundColor DarkGray
    }

    # -----------------------------------------------------------------
    # Phase B: Import newly selected models + models needing rebuild
    # Uses ollama create with full progress display
    # -----------------------------------------------------------------
    $modelsToImport = @()
    $modelsToRebuild = @()
    $checkIdx = 0
    foreach ($m in $SelectedModels) {
        $checkIdx++
        Write-Host "      [$checkIdx/$($SelectedModels.Count)] $($m.Name)..." -ForegroundColor DarkGray -NoNewline
        $ggufPath = "$MODELS_DIR\$($m.File)"
        if (-Not (Test-Path $ggufPath)) {
            $ggufPath = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter $m.File -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        }
        # Check model readiness - GGUF is optional after blob creation
        $ready = Test-OllamaModelReady -ModelName $m.Local -GGUFPath $ggufPath
        if ($ready.Valid) {
            Write-Host " all 3 components valid, skipping" -ForegroundColor Green
            continue
        }
        if (-Not (Test-Path $ggufPath)) {
            Write-Host " GGUF not found" -ForegroundColor Red
            continue
        }
        if ($ready.NeedsBlobs -or $ready.NeedsManifest) {
            Write-Host " GGUF valid, needs import ($($ready.Reason))" -ForegroundColor Yellow
            $modelsToImport += $m
        } else {
            Write-Host " needs import" -ForegroundColor Yellow
            $modelsToImport += $m
        }
    }

    if ($modelsToImport.Count -gt 0) {
        # Kill any existing ollama/llama-quantize processes before import
        $oldProcs = Get-Process -Name "ollama","llama-quantize","ollama_llama_server" -EA SilentlyContinue
        if ($oldProcs) {
            Write-Host "      Killing $($oldProcs.Count) existing processes: $(($oldProcs.Name | Select-Object -Unique) -join ', ')" -ForegroundColor Yellow
            Write-ImportLog "KILLING: $($oldProcs.Count) existing process(es): $(($oldProcs.Name | Select-Object -Unique) -join ', ')"
            $oldProcs | Stop-Process -Force -EA SilentlyContinue
            Start-Sleep -Seconds 2
        }
        Write-Host ""
        Write-Host "      Importing $($modelsToImport.Count) models into Ollama engine..." -ForegroundColor Yellow
        Write-ImportLog "PHASE B: Importing $($modelsToImport.Count) model(s) via ollama create"

        Get-Process -Name "ollama*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        $ServerProcess = $null
        try {
            $ServerProcess = Start-OllamaServer

            # Query ollama list to skip already-imported models
            Write-Host "      Checking ollama list..." -ForegroundColor DarkGray
            $importedModels = Get-OllamaImportedModels
            if ($importedModels.Count -gt 0) {
                Write-Host "      Found $($importedModels.Count) models already in Ollama:" -ForegroundColor DarkGray
                foreach ($key in $importedModels.Keys) {
                    Write-Host "        - $key" -ForegroundColor DarkGray
                }
            }

            # Build final import list
            $finalImport = @()
            foreach ($m in $modelsToImport) {
                if ($importedModels.ContainsKey($m.Local)) {
                    Write-Host "      $($m.Name) - already in ollama list, skipping" -ForegroundColor Green
                    continue
                }
                $finalImport += $m
            }

            if ($finalImport.Count -eq 0) {
                Write-Host "      All models already imported!" -ForegroundColor Green
            } else {
                $importIdx = 0
                foreach ($m in $finalImport) {
                    $importIdx++
                    $ggufPath = "$MODELS_DIR\$($m.File)"
                    if (-not (Test-Path $ggufPath)) {
                        $ggufPath = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter $m.File -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
                    }
                    $ggufGB = [math]::Round((Get-Item $ggufPath).Length / 1GB, 2)
                    $modelTimeout = Get-ImportTimeoutMinutes -GGUFPath $ggufPath
                    Write-Host ""
                    Write-Host "      ($importIdx/$($finalImport.Count)) $($m.Name) ($ggufGB GB) [timeout: ${modelTimeout}min]" -ForegroundColor Yellow
                    Write-ImportLog "IMPORT ($importIdx/$($finalImport.Count)): $($m.Local) | timeout=${modelTimeout}min | blobBefore=$blobSizeBefore"

                    $blobSizeBefore = 0
                    if (Test-Path $blobDir) {
                        Get-ChildItem -Path $blobDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $blobSizeBefore += $_.Length }
                    }

                    $prevTimeout = $IMPORT_TIMEOUT_MIN
                    $IMPORT_TIMEOUT_MIN = $modelTimeout
                    $maxRetries = 2
                    $retryCount = 0
                    $importDone = $false
                    while (-not $importDone -and $retryCount -le $maxRetries) {
                        if ($retryCount -gt 0) {
                            Write-Host "      RETRY $retryCount/$maxRetries - Restarting Ollama server..." -ForegroundColor Yellow
                            Write-ImportLog "RETRY $retryCount/$maxRetries for $($m.Local)"
                            Get-Process -Name "ollama*" -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
                            Start-Sleep -Seconds 3
                            $ServerProcess = Start-OllamaServer
                            $blobSizeBefore = 0
                            if (Test-Path $blobDir) {
                                Get-ChildItem -Path $blobDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $blobSizeBefore += $_.Length }
                            }
                        }
                        $result = Invoke-OllamaCreate -LocalName $m.Local -DisplayName $m.Name -GGUFFile $m.File -BlobSizeBefore $blobSizeBefore -ModelIndex $importIdx -ModelTotal $finalImport.Count
                        if ($result.Success -or $result.ExitCode -eq 0) {
                            $importDone = $true
                        } else {
                            $serverCrashed = $result.Output -match "server crashed|server.*not responding|forcibly closed"
                            if ($serverCrashed -and $retryCount -lt $maxRetries) {
                                $retryCount++
                                continue
                            }
                            $importDone = $true
                        }
                    }
                    $IMPORT_TIMEOUT_MIN = $prevTimeout

                    $blobSizeAfter = 0
                    if (Test-Path $blobDir) {
                        Get-ChildItem -Path $blobDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $blobSizeAfter += $_.Length }
                    }
                    $blobDeltaMB = [math]::Round(($blobSizeAfter - $blobSizeBefore) / 1MB, 1)

                    if ($result.Success) {
                        Start-Sleep -Milliseconds 500
                        if (Test-OllamaManifest -ModelName $m.Local) {
                            Write-Host "      OK: $($m.Name) imported! +${blobDeltaMB} MB blob | $($result.Elapsed)" -ForegroundColor Green
                            Write-ImportLog "IMPORT OK: $($m.Local) | +${blobDeltaMB} MB | elapsed=$($result.Elapsed)"
                        } else {
                            Write-Host "      WARNING: $($m.Name) - ollama returned OK but no manifest found" -ForegroundColor Yellow
                            Write-Host "        Check log: $env:TEMP\ollama_create_$($m.Local).log" -ForegroundColor DarkGray
                            Write-ImportLog "IMPORT WARN: $($m.Local) | OK but no manifest | log=$env:TEMP\ollama_create_$($m.Local).log"
                        }
                    } else {
                        if (Test-OllamaManifest -ModelName $m.Local) {
                            Write-Host "      OK: $($m.Name) imported - manifest verified despite exit code $($result.ExitCode)" -ForegroundColor Green
                            Write-ImportLog "IMPORT RECOVERED: $($m.Local) | manifest exists despite exit=$($result.ExitCode)"
                        } else {
                            Write-Host "      ERROR: Failed to import $($m.Name) - exit $($result.ExitCode), $($result.Elapsed)" -ForegroundColor Red
                            Write-ImportLog "IMPORT FAIL: $($m.Local) | exit=$($result.ExitCode) | elapsed=$($result.Elapsed) | msg=$($result.Output)"
                            if ($result.Output) {
                                $logLines = $result.Output -split "`n"
                                $tail = $logLines | Select-Object -Last 10
                                foreach ($line in $tail) {
                                    $trimmed = $line.Trim()
                                    if ($trimmed) {
                                        Write-Host "        | $trimmed" -ForegroundColor DarkRed
                                    }
                                }
                            }
                            $downloadErrors += "Import: $($m.Name)"
                        }
                    }
                }
            }
        } catch {
            Write-Host "      ERROR: Could not start Ollama server for import." -ForegroundColor Red
        } finally {
            if ($ServerProcess) {
                Write-Host "      Stopping temporary Ollama server..." -ForegroundColor DarkGray
                Stop-Process -Id $ServerProcess.Id -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
        }
    } else {
        Write-Host "      All selected models already imported!" -ForegroundColor Green
    }

    # -----------------------------------------------------------------
    # Phase C: VALIDATION PASS - Check all models have all 3 components
    #          (GGUF valid, blobs exist, manifest valid)
    #          Any failures trigger rebuild via Build-OllamaModel
    # -----------------------------------------------------------------
    Write-Host ""
    Write-Host "      Validating Ollama model integrity (GGUF + blobs + manifest)..." -ForegroundColor Yellow
    Write-ImportLog "PHASE C: Validating all models have all 3 components"

    $allModelsToCheck = @()
    if (Test-Path "$MODELS_DIR\installed-models.txt") {
        $lines = Get-Content "$MODELS_DIR\installed-models.txt" -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            $parts = $line -split "\|"
            if ($parts.Count -ge 2) {
                $localName    = $parts[0].Trim()
                $displayName  = $parts[1].Trim()
                $modelfilePath = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter "Modelfile" -File -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -match [regex]::Escape($localName) } | Select-Object -First 1 -ExpandProperty FullName
                if (-Not $modelfilePath) { continue }
                $mfContent = Get-Content $modelfilePath -Raw -ErrorAction SilentlyContinue
                $ggufFile = $null
                if ($mfContent -match "FROM\s+\./(.+\.gguf)") { $ggufFile = $Matches[1] }
                if (-Not $ggufFile) { continue }
                $ggufPath = "$MODELS_DIR\$ggufFile"
                if (-Not (Test-Path $ggufPath)) {
                    $ggufPath = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter $ggufFile -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
                }
                if (-Not (Test-Path $ggufPath)) { continue }
                if (-Not (Test-GGUFIntegrity -Path $ggufPath -MinSize 1000000)) { continue }
                $allModelsToCheck += @{ LocalName = $localName; DisplayName = $displayName; GGUFFile = $ggufFile; GGUFPath = $ggufPath }
            }
        }
    }

    $rebuildList = @()
    foreach ($model in $allModelsToCheck) {
        $ready = Test-OllamaModelReady -ModelName $model.LocalName -GGUFPath $model.GGUFPath
        if ($ready.Valid) {
            Write-Host "      $($model.DisplayName): OK ($($ready.Reason))" -ForegroundColor DarkGreen
            Write-ImportLog "VALID: $($model.LocalName) - $($ready.Reason)"
        } else {
            Write-Host "      $($model.DisplayName): NEEDS REBUILD ($($ready.Reason))" -ForegroundColor Yellow
            Write-ImportLog "NEEDS REBUILD: $($model.LocalName) - $($ready.Reason)"
            $rebuildList += $model
        }
    }

    if ($rebuildList.Count -eq 0) {
        Write-Host "      All $($allModelsToCheck.Count) models validated - all 3 components OK!" -ForegroundColor Green
        Write-ImportLog "PHASE C: All $($allModelsToCheck.Count) models valid"
    } else {
        Write-Host ""
        Write-Host "      Found $($rebuildList.Count) models needing rebuild. Building blobs directly..." -ForegroundColor Yellow
        Write-ImportLog "PHASE C: $($rebuildList.Count) models need rebuild"

        foreach ($model in $rebuildList) {
            $rbGGUF = if ($model.GGUFPath) { $model.GGUFPath } else { "$MODELS_DIR\$($model.GGUFFile)" }
            if (-not (Test-Path $rbGGUF)) {
                $rbGGUF = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter $model.GGUFFile -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
            }
            if (-not (Test-Path $rbGGUF)) {
                Write-Host "        $($model.DisplayName) - GGUF missing, cannot rebuild" -ForegroundColor Red
                continue
            }
            # Get prompt from Modelfile
            $rbPrompt = "You are a helpful AI assistant."
            $rbModelfile = Get-ChildItem -Path $MODELS_DIR -Recurse -Filter "Modelfile" -File -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -match [regex]::Escape($model.LocalName) } | Select-Object -First 1 -ExpandProperty FullName
            if ($rbModelfile) {
                $rbMfContent = Get-Content $rbModelfile -Raw -ErrorAction SilentlyContinue
                if ($rbMfContent -match 'SYSTEM\s+(.+)') { $rbPrompt = $Matches[1].Trim() }
            }
            Write-Host "        $($model.DisplayName) - building blobs..." -ForegroundColor DarkGray -NoNewline
            $buildResult = Build-OllamaModel -ModelName $model.LocalName -GGUFPath $rbGGUF -SystemPrompt $rbPrompt
            if ($buildResult.Success) {
                Write-Host " OK! ($($buildResult.BlobSizeMB) MB)" -ForegroundColor Green
                Write-ImportLog "REBUILD OK: $($model.LocalName) | $($buildResult.BlobSizeMB) MB"
            } else {
                Write-Host " FAILED: $($buildResult.Reason)" -ForegroundColor Red
                Write-ImportLog "REBUILD FAIL: $($model.LocalName) - $($buildResult.Reason)"
                $downloadErrors += "Rebuild: $($model.DisplayName) ($($buildResult.Reason))"
            }
        }
    }
}

# =================================================================
# =================================================================
# STEP 9: Download G0DM0D3 (multi-model AI research tool)
# =================================================================
Write-Host "[10/10] Downloading G0DM0D3 - multi-model AI research tool..." -ForegroundColor Yellow

$Godmod3Dir = Join-Path $USB_Drive "godmod3"
$Godmod3File = Join-Path $Godmod3Dir "index.html"
$Godmod3Url = "https://raw.githubusercontent.com/elder-plinius/G0DM0D3/main/index.html"

if (Test-Path $Godmod3File -PathType Leaf) {
    Write-Host "      G0DM0D3 already installed on USB! Skipping..." -ForegroundColor Green
} else {
    if (-not (Test-Path $Godmod3Dir)) {
        New-Item -ItemType Directory -Path $Godmod3Dir -Force | Out-Null
    }
    Write-Host "      Downloading G0DM0D3 - single-file browser app..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $Godmod3Url -OutFile $Godmod3File -UseBasicParsing -TimeoutSec 60
        if (Test-Path $Godmod3File -PathType Leaf) {
            $size = [math]::Round((Get-Item $Godmod3File).Length / 1KB, 1)
            Write-Host "      G0DM0D3 installed on USB! (${size} KB)" -ForegroundColor Green
        } else {
            Write-Host "      WARNING: G0DM0D3 download failed. Install later manually." -ForegroundColor Yellow
            $downloadErrors += "G0DM0D3"
        }
    } catch {
        Write-Host "      WARNING: G0DM0D3 download failed: $($_.Exception.Message)" -ForegroundColor Yellow
        $downloadErrors += "G0DM0D3"
    }
}

# FINAL SUMMARY
# =================================================================
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan

if ($downloadErrors.Count -gt 0) {
    Write-Host "   SETUP COMPLETE - with some errors                      " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  The following had issues:" -ForegroundColor Red
    foreach ($err in $downloadErrors) {
        Write-Host "    ! $err" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  You can re-run install.bat to retry failed downloads." -ForegroundColor Yellow
} else {
    Write-Host "   SETUP COMPLETE! YOUR PORTABLE AI IS READY!             " -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  Installed models:" -ForegroundColor White
foreach ($m in $SelectedModels) {
    if ($m.Label -eq "UNCENSORED") {
        $tag = "[UNCENSORED]"
        $tagColor = "Red"
    } elseif ($m.Label -eq "CUSTOM") {
        $tag = "[CUSTOM]"
        $tagColor = "Green"
    } elseif ($m.Label -eq "NSFW") {
        $tag = "[NSFW]"
        $tagColor = "Magenta"
    } elseif ($m.Label -eq "LOCAL") {
        $tag = "[LOCAL]"
        $tagColor = "Yellow"
    } else {
        $tag = "[STANDARD]"
        $tagColor = "DarkCyan"
    }
    Write-Host "    - $($m.Name) " -ForegroundColor Gray -NoNewline
    Write-Host $tag -ForegroundColor $tagColor
}

Write-Host ""
Write-Host "  Installed apps:" -ForegroundColor White
Write-Host "    - AnythingLLM [RAG GUI]  : anythingllm\" -ForegroundColor Gray
Write-Host "    - G0DM0D3 [multi-model]  : godmod3\" -ForegroundColor Gray
Write-Host "    - Ollama engine          : ollama\" -ForegroundColor Gray
if (Test-Path "$USB_Drive\llama.cpp\llama-server.exe") {
    Write-Host "    - llama.cpp server       : llama.cpp\" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  To start your AI: run start-optimized.bat" -ForegroundColor White
Write-Host "    [1] AnythingLLM   - Desktop RAG GUI" -ForegroundColor Cyan
Write-Host "    [2] Browser Chat   - Web chat at localhost:3333" -ForegroundColor Cyan
Write-Host "    [3] G0DM0D3        - Multi-model AI research" -ForegroundColor Cyan
Write-Host "    [4] llama.cpp      - Direct GGUF server" -ForegroundColor Cyan
Write-Host ""
Write-Host "  TIP: In AnythingLLM, go to Settings > LLM to switch" -ForegroundColor DarkGray
Write-Host "  between your installed models." -ForegroundColor DarkGray
Write-Host ""

# Export model catalog to models.json for update-models.ps1 and download-models.ps1
$modelsJsonPath = "$USB_Drive\models\models.json"
try {
    $exportModels = @()
    $num = 1
    foreach ($m in $ModelCatalog) {
        $exportModels += @{
            num      = $num
            name     = $m.Name
            file     = $m.File
            url      = $m.URL
            alt_urls = if ($m.AltURLs -and @($m.AltURLs).Count -gt 0) { @($m.AltURLs) } else { @() }
            size     = $m.Size
            min_bytes = $m.MinBytes
            local    = $m.Local
            label    = $m.Label
            badge    = $m.Badge
            prompt   = $m.Prompt
        }
        $num++
    }
    $jsonOutput = @{ desktop_models = $exportModels }
    $jsonStr = $jsonOutput | ConvertTo-Json -Depth 3
    Set-Content -Path $modelsJsonPath -Value $jsonStr -Encoding UTF8 -Force
    Write-Host "  Exported model catalog ($($exportModels.Count) models) to models.json" -ForegroundColor DarkGray
} catch {
    Write-Host "  WARNING: Failed to export models.json: $($_.Exception.Message)" -ForegroundColor Yellow
}

"=== Import finished $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | errors=$($downloadErrors.Count) ===" | Out-File -FilePath $IMPORT_LOG -Append -Encoding UTF8

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
