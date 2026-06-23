# =====================================================================
# Fitify — evaluate the trained GRU ONNX (NO retraining). Paste into ONE cell.
#
# MODE = "test_split":  honest re-score of the held-out 15% test split from your
#                       saved landmarks.npz, using the deployable ONNX. Runs now,
#                       no re-extraction, no leakage. Reproduces your 95.1%.
#
# MODE = "external":    true generalization test on UNTOUCHED folders (raw_data,
#                       test/). Requires those uploaded to Kaggle. Do NOT point
#                       this at verified_data — the model trained on it (leakage).
# =====================================================================
import subprocess, sys
subprocess.run([sys.executable, "-m", "pip", "install", "-q", "mediapipe", "onnxruntime"])

MODE = "external"            # "test_split"  or  "external"

# --- trained-model paths (your notebook-output mount) ---
NB   = "/kaggle/input/notebooks/vishardmehta/fitify-model"
ONNX = f"{NB}/results/gru/fitify_pose_gru.onnx"
NPZ  = f"{NB}/data/landmarks.npz"
LABELMAP = f"{NB}/data/label_map.json"

# --- MODE="external": untouched folders from the ORIGINAL public dataset.
# Model trained on verified_data only, so raw_data + test/ are unseen.
# test/test = cleanest (designated test split); raw_data may overlap verified
# (verified was likely curated from it) — interpret the raw number with care.
SRC = "/kaggle/input/datasets/philosopher0808/gym-workoutexercises-video"
DATASET_ROOTS = [
    f"{SRC}/test/test",                       # cleanest external set
    f"{SRC}/raw_data/raw_data/data-btc",      # extra volume (possible overlap)
    f"{SRC}/raw_data/raw_data/data-crawl",    # extra volume (possible overlap)
]
NUM_FRAMES, VIS_THRESH, MIN_BRIGHT = 32, 0.7, 50.0
MODEL_PATH = "pose_landmarker_full.task"
# =====================================================================

import os, json
import numpy as np
import onnxruntime as ort

CHOSEN = ["squat", "deadlift", "romanian deadlift", "push-up", "pull up",
          "shoulder press", "hammer curl", "lateral raise", "plank",
          "leg raises", "russian twist", "hip thrust"]
norm = lambda s: s.strip().lower().replace("_", " ")
CHOSEN_N = {norm(c) for c in CHOSEN}
L_SH, R_SH, L_HIP, R_HIP = 11, 12, 23, 24

label_map = (json.load(open(LABELMAP)) if os.path.exists(LABELMAP)
             else {n: i for i, n in enumerate(sorted(CHOSEN_N))})
id_to_label = {i: n for n, i in label_map.items()}
num_classes = len(label_map)
labels = [id_to_label[i] for i in range(num_classes)]

assert os.path.exists(ONNX), f"ONNX not found: {ONNX} (add the notebook output as Input)"
sess = ort.InferenceSession(ONNX, providers=["CPUExecutionProvider"])
INAME = sess.get_inputs()[0].name


def normalize_sequence(seq):                      # (T,33,4) pixel-space -> (T,99)
    xyz = seq[..., :3].copy()
    hip = (xyz[:, L_HIP] + xyz[:, R_HIP]) / 2.0
    sh = (xyz[:, L_SH] + xyz[:, R_SH]) / 2.0
    torso = np.maximum(np.linalg.norm(sh - hip, axis=-1, keepdims=True), 1e-6)
    xyz = (xyz - hip[:, None, :]) / torso[:, None, :]
    return xyz.reshape(xyz.shape[0], -1).astype(np.float32)


FRONT_RATIO, SIDE_RATIO = 0.45, 0.22


def estimate_angle_flag(arr):                     # 0=front 1=non-front 2=unclear
    ratios = []
    for fr in arr:
        if fr[L_SH, 3] < 0.5 or fr[R_SH, 3] < 0.5:
            continue
        if fr[L_HIP, 3] < 0.5 and fr[R_HIP, 3] < 0.5:
            continue
        sh_dx = abs(fr[L_SH, 0] - fr[R_SH, 0])
        sh_c = (fr[L_SH, :2] + fr[R_SH, :2]) / 2.0
        hip_c = (fr[L_HIP, :2] + fr[R_HIP, :2]) / 2.0
        torso = float(np.linalg.norm(sh_c - hip_c))
        if torso < 1e-3:
            continue
        ratios.append(sh_dx / torso)
    if len(ratios) < 3:
        return 2
    r = float(np.median(ratios))
    return 0 if r >= FRONT_RATIO else (1 if r <= SIDE_RATIO else 2)


def report(y, pred, ang, title):
    print(f"\n=== {title}: accuracy {(y == pred).mean():.4f}  on {len(y)} clips ===")
    try:
        from sklearn.metrics import classification_report, confusion_matrix
        print(classification_report(y, pred, labels=list(range(num_classes)),
                                    target_names=labels, digits=3, zero_division=0))
        np.save("eval_confusion.npy", confusion_matrix(y, pred, labels=list(range(num_classes))))
    except Exception as e:
        print("(sklearn unavailable)", e)
    print("angle breakdown:")
    for flag, nm in {0: "front", 1: "non-front", 2: "unclear"}.items():
        m = ang == flag
        if m.sum():
            print(f"  {nm:10} n={int(m.sum()):4d}  acc={(y[m] == pred[m]).mean():.4f}")


def stratified_split(y, seed=42, val=0.15, test=0.15):   # identical to training
    rng = np.random.default_rng(seed)
    tr, va, te = [], [], []
    for c in np.unique(y):
        idx = np.where(y == c)[0]; rng.shuffle(idx); n = len(idx)
        n_test = max(1, int(round(n * test))); n_val = max(1, int(round(n * val)))
        te += idx[:n_test].tolist(); va += idx[n_test:n_test + n_val].tolist(); tr += idx[n_test + n_val:].tolist()
    return np.array(tr), np.array(va), np.array(te)


if MODE == "test_split":
    assert os.path.exists(NPZ), f"npz not found: {NPZ}"
    d = np.load(NPZ, allow_pickle=True)
    X, y = d["X"], d["y"]
    ang = d["angle"] if "angle" in d.files else np.full(len(y), 2, np.int8)
    _, _, te = stratified_split(y)
    Xt = np.stack([normalize_sequence(x) for x in X[te]]).astype(np.float32)
    pred = sess.run(None, {INAME: Xt})[0].argmax(1)
    report(y[te], pred, np.asarray(ang)[te], "HELD-OUT TEST (ONNX, no leakage)")

elif MODE == "external":
    assert DATASET_ROOTS and all(os.path.isdir(r) for r in DATASET_ROOTS), \
        "set DATASET_ROOTS to UNTOUCHED folders (raw_data/test). Don't use verified_data."
    import cv2, urllib.request
    import mediapipe as mp
    from mediapipe.tasks import python as mp_python
    from mediapipe.tasks.python import vision as mp_vision

    if not os.path.exists(MODEL_PATH):
        urllib.request.urlretrieve(
            "https://storage.googleapis.com/mediapipe-models/pose_landmarker/"
            "pose_landmarker_full/float16/latest/pose_landmarker_full.task", MODEL_PATH)
    lmk = mp_vision.PoseLandmarker.create_from_options(mp_vision.PoseLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=MODEL_PATH),
        running_mode=mp_vision.RunningMode.IMAGE, num_poses=1,
        min_pose_detection_confidence=0.5, min_pose_presence_confidence=0.5))
    EXT = {".mp4", ".mov", ".avi", ".mkv", ".webm"}

    def extract(fp, n):
        cap = cv2.VideoCapture(fp); total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) or 0
        idxs = (list(range(total)) if total <= n
                else list(np.linspace(0, total - 1, n).astype(int))) if total > 0 else []
        frames, br = [], []
        for i in idxs:
            cap.set(cv2.CAP_PROP_POS_FRAMES, int(i)); ok, fr = cap.read()
            if not ok:
                continue
            h, w = fr.shape[:2]; br.append(float(cv2.cvtColor(fr, cv2.COLOR_BGR2GRAY).mean()))
            rgb = np.ascontiguousarray(cv2.cvtColor(fr, cv2.COLOR_BGR2RGB))
            res = lmk.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb))
            if res.pose_landmarks:
                p = res.pose_landmarks[0]
                lm = np.array([[q.x * w, q.y * h, q.z * w, q.visibility] for q in p], np.float32)
            else:
                lm = np.zeros((33, 4), np.float32)
            frames.append(lm)
        cap.release()
        if not frames:
            return None, 0.0
        a = np.stack(frames, 0)
        if a.shape[0] < n:
            a = np.concatenate([a, np.repeat(a[-1:], n - a.shape[0], 0)], 0)
        return a[:n], (float(np.mean(br)) if br else 0.0)

    X, y, ang = [], [], []
    for root in DATASET_ROOTS:
        for folder in sorted(os.listdir(root)):
            n = norm(folder); fdir = os.path.join(root, folder)
            if n not in label_map or not os.path.isdir(fdir):
                continue
            vids = [f for f in os.listdir(fdir) if os.path.splitext(f)[1].lower() in EXT]
            print(f"[{n}] {os.path.basename(root)}/{folder}: {len(vids)}", flush=True)
            for f in vids:
                arr, b = extract(os.path.join(fdir, f), NUM_FRAMES)
                if arr is None or b < MIN_BRIGHT or float(arr[..., 3].mean()) < VIS_THRESH:
                    continue
                X.append(normalize_sequence(arr)); y.append(label_map[n]); ang.append(estimate_angle_flag(arr))
    assert X, "no external clips found"
    X = np.stack(X).astype(np.float32)
    pred = sess.run(None, {INAME: X})[0].argmax(1)
    report(np.array(y), pred, np.array(ang), "EXTERNAL (never-seen clips)")

else:
    raise SystemExit("MODE must be 'test_split' or 'external'")
