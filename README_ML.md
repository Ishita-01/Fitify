# Fitify ML — Pose-Landmark Exercise Classifier

Path B pipeline: BlazePose landmarks → normalized sequences → small temporal
classifier (GRU / 1D-CNN). Tiny (~0.4–2 MB), portable (ONNX → TFLite/server),
and the same landmark stream feeds your angle-based form-feedback module.

## The 12 locked exercises
squat, deadlift, romanian deadlift, push-up, pull up, shoulder press,
hammer curl, lateral raise, plank, leg raises, russian twist, hip thrust

(Dropped bench press, incline bench, tricep dips, barbell biceps curl —
horizontal/occluded → poor landmark visibility, confirmed by the scorer.)

## Pipeline

```
scripts/extract_landmarks.py   Stage 1: BlazePose over clips -> data/landmarks.npz
models/dataset.py              Normalization (hip-center + torso-scale) + split
models/nets.py                 GRUClassifier (default) / CNN1DClassifier
scripts/train.py               Stage 4: weighted loss, early stop, test + CM, ONNX
```

## Run

Data source = **verified_data only** (`data_btc_10s` + `data_crawl_10s`, ~843
clips). Extraction takes multiple roots and merges same-named class folders.

```bash
pip install -r requirements.txt

# 1. extract landmarks from the two verified roots (local paths shown)
python scripts/extract_landmarks.py \
    --dataset "archive/verified_data/verified_data/data_btc_10s" \
              "archive/verified_data/verified_data/data_crawl_10s" \
    --num-frames 32 --vis-thresh 0.7 --min-brightness 50

# 2. train (GRU default) and the featherweight CNN alternative
python scripts/train.py --model gru --epochs 120 --patience 20
python scripts/train.py --model cnn --epochs 120 --patience 20
```

**Kaggle (recommended for GPU):** run `python scripts/make_notebook.py` to
generate `fitify_pose_kaggle.ipynb` — a self-contained notebook (writes the
modules, extracts, trains both, renders confusion matrices + angle split). Edit
the two `ROOT_*` paths to your uploaded Kaggle dataset and run top to bottom.

Outputs: `checkpoints/fitify_pose.onnx`, `results/test_report.txt` (now incl. a
front vs non-front accuracy breakdown), `results/confusion_matrix.npy`,
`results/history.json`.

## Aspect-ratio fix (important)
MediaPipe normalizes `x` by frame **width** and `y` by **height**, so its raw
normalized space is anisotropic — portrait vs landscape clips of the same pose
come out skewed ~3x, and the isotropic torso-scale step can't undo it. The
dataset is ~20% portrait / 79% landscape, so this was corrupting **training**,
not just portrait inference (a shoulder press was being read as a squat).

`extract_landmarks.py` converts to true-aspect pixel space before saving:
`x_px = x*W, y_px = y*H, z_px = z*W` (z shares x's width scale). After this,
`normalize_sequence` is geometrically correct and aspect-invariant.

### App-side parity (do NOT skip)
The deployed pose pipeline must apply the **identical** transform before feeding
the model, using the live camera frame's real width/height:
1. BlazePose → normalized `(x, y, z, vis)` per joint
2. `x*=W; y*=H; z*=W`  (true-aspect pixel space)
3. hip-center re-origin + divide by torso length (per `normalize_sequence`)
4. → `(T, 99)` sequence → ONNX model

If the app skips step 2, the portrait/landscape bug returns at inference even
though training is correct.

## Angle tagging
Each clip is tagged `angle_flag` (0=front, 1=non-front, 2=unclear) via a rough
shoulder-width / torso-length heuristic. Clips are **not** dropped by angle —
training uses all of them and `train.py` reports test accuracy split by angle so
you can show whether non-front camera angles hurt (capstone writeup material).

## Key design notes
- **Normalization is the load-bearing step.** Each frame is re-origined to the
  hip-center and scaled by torso length → invariant to body size, camera
  distance, and frame position. Done in `models/dataset.normalize_sequence`.
- **Class imbalance** (67→195 clips) handled by inverse-frequency weighted
  cross-entropy + label smoothing.
- **Held-out test set** is split once (seeded) and only touched after training.
- **Offline / upload-based**: clips are processed as whole sequences, not
  streamed — matches the "upload a video → get analysis" UX.

## Deploy
- ONNX runs as-is on a server (onnxruntime).
- For on-device: `onnx2tf` or the TF→TFLite path; model is already small enough
  that INT8 quantization gets you well under 1 MB.

## Report baseline (optional, recommended)
Train a small frame-CNN or VideoMAE-base once on the same split purely to get
one comparison row: "pose-landmark model matched the video baseline at ~1/70th
the size." One paragraph of academic credit, not a maintained codepath.
