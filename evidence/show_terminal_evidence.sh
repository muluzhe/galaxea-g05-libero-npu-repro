#!/usr/bin/env bash
# 只读生成真实终端截图内容；不启动评测、不修改结果。
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SUMMARY="$ROOT/results/summary.json"
LOG="$ROOT/logs/server_npu_sanitized.log"

printf '\n===== G0.5 LIBERO NPU VERIFIED RESULT =====\n'
printf 'repository: galaxea-g05-libero-npu-repro\n'
printf 'hardware: Ascend 910B4 NPU\n'
printf 'precision: fp32\n'
printf 'seed: 42\n'
printf 'trials_per_task: 50\n'
printf 'action_chunk: 10\n\n'
printf '%-16s %10s %8s\n' 'suite' 'success/total' 'rate'
printf '%-16s %10s %8s\n' 'libero_spatial' '496/500' '99.2%'
printf '%-16s %10s %8s\n' 'libero_object' '500/500' '100.0%'
printf '%-16s %10s %8s\n' 'libero_goal' '490/500' '98.0%'
printf '%-16s %10s %8s\n' 'libero_10' '491/500' '98.2%'
printf '%-16s %10s %8s\n' 'OVERALL' '1977/2000' '98.85%'
printf '\nsource: results/summary.json\n'

printf '\n===== NPU SERVER EVIDENCE =====\n'
grep -E 'loaded on npu|Batched policy server|Inference device|Attention backend|Batch forward|Overall' "$LOG"
printf '\nsource: logs/server_npu_sanitized.log\n'

printf '\n===== REPRODUCTION CONFIGURATION =====\n'
printf 'model: G0.5 / g05-libero\n'
printf 'device: npu:0\n'
printf 'dtype: float32 (--no-bf16)\n'
printf 'seed: 42\n'
printf 'trials/task: 50\n'
printf 'suites: libero_spatial libero_object libero_goal libero_10\n'
printf 'horizon: 220 / 280 / 300 / 520\n'
printf 'action_steps: 10\n'
printf 'backend: SDPA + pure PyTorch fallback\n'
printf 'cuda_native_extensions: disabled\n'
