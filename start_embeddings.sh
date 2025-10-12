#!/bin/bash

# Start MLX OpenAI Server for Embeddings Model
# Model: mlx-community/qwen3-embedding-0.6b-8bit

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/embeddings_server.log"

mkdir -p "$LOG_DIR"

echo "Starting MLX OpenAI Server for embeddings..."
echo "Logs will be written to: $LOG_FILE"

nohup uv run mlx-openai-server launch \
  --model-type embeddings \
  --model-path mlx-community/qwen3-embedding-0.6b-8bit \
  --max-concurrency 4 \
  --queue-timeout 300 \
  --queue-size 100 \
  --log-file "$LOG_FILE" \
  > /dev/null 2>&1 &

PID=$!
echo "Server started with PID: $PID"
echo "To stop the server, run: kill $PID"
echo "To view logs, run: tail -f $LOG_FILE"
