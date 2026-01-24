#!/usr/bin/env bash
set -euo pipefail
out_dir="/Users/xblydxj/Documents/工程/Codex/starknow/assets/images"
mkdir -p "$out_dir"

# Use picsum.photos for stable, unique placeholder photos.
seeds=(
"history_01" "history_02" "history_03" "history_04" "history_05" "history_06" "history_07" "history_08"
"computer_01" "computer_02" "computer_03" "computer_04" "computer_05" "computer_06" "computer_07" "computer_08"
"basketball_01" "basketball_02" "basketball_03" "basketball_04" "basketball_05" "basketball_06" "basketball_07" "basketball_08"
"animal_01" "animal_02" "animal_03" "animal_04" "animal_05" "animal_06"
)

index=1
for seed in "${seeds[@]}"; do
  printf -v name "img_%02d.jpg" "$index"
  dest="$out_dir/$name"
  url="https://picsum.photos/seed/${seed}/900/600"
  echo "Downloading $url -> $dest"
  curl -L "$url" -o "$dest"
  index=$((index+1))
done

echo "Done: $((index-1)) images."
