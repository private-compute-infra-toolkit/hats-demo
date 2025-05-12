#!/bin/bash

set -e

echo "===== STARTING OLLAMA SERVER ========"

OLLAMA_HOST=0.0.0.0:11434 ollama serve &


echo "===== SLEEPING 1 ========"
sleep 1

echo "===== STARTING GEMMA3 MODEL ========"

OLLAMA_HOST=0.0.0.0:11434 ollama run gemma3:1b
