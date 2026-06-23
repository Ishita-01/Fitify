"""
Fitify ML — Stage 1: Landmark Extraction
Runs BlazePose (via MediaPipe's Tasks API — PoseLandmarker) over every clip in
the chosen exercise folders and saves a fixed-length landmark sequence per clip.

We use the Tasks API (not the legacy `mp.solutions.pose`, which is absent from
recent MediaPipe builds e.g. 0.10.35 on Kaggle). Same 33-landmark BlazePose
topology. The model bundle is auto-downloaded if not present.

KEY FIX (aspect-ratio): MediaPipe normalizes x by frame WIDTH and y by frame
HEIGHT (different denominators), so its raw normalized space is anisotropic — a
portrait clip and a landscape clip of the same pose come out skewed ~3x on the
x:y axes, and the downstream isotropic torso-scale normalization can't undo it.
We therefore convert to TRUE-ASPECT pixel space here:
    x_px = x_norm * W,   y_px = y_norm * H,   z_px = z_norm * W
(z shares x's width scale). After this, models/dataset.normalize_sequence is
geometrically correct and aspect-invariant.  *** The app's pose pipeline MUST
apply the identical x*W, y*H, z*W before normalization, or the bug returns. ***

Quality filters:
  - visibility: drop clips whose mean landmark visibility < --vis-thresh
  - lighting:   drop clips whose mean frame brightness < --min-brightness
Angle tagging (NOT dropped): a rough front-vs-side heuristic from the
shoulder-width / torso ratio, saved as angle_flag (0=front,1=non-front,2=unclear)
so training can report front vs non-front performance separately.

Output: data/landmarks.npz with arrays
    X      : (N, T, 33, 4) float32  pixel-space (x,y,z) + visibility
    y      : (N,)          int64    class id
    files  : (N,)          str      source filename
    angle  : (N,)          int8     0=front, 1=non-front, 2=unclear
    source : (N,)          str      which dataset root the clip came from
and data/label_map.json / data/id_to_label.json
"""

import os, json, argparse, collections, urllib.request
import numpy as np
import cv2
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision

# The 12 locked exercises. Folder names are matched case-insensitively /
# whitespace-trimmed against the dataset's actual folder names.
CHOSEN = [
    "squat", "deadlift", "romanian deadlift", "push-up", "pull up",
    "shoulder press", "hammer curl", "lateral raise", "plank",
    "leg raises", "russian twist", "hip thrust",
]
norm = lambda s: s.strip().lower().replace("_", " ")
CHOSEN_N = {norm(c) for c in CHOSEN}

VIDEO_EXT = {".mp4", ".mov", ".avi", ".mkv", ".webm"}

# MediaPipe Pose landmark indices
L_SH, R_SH, L_HIP, R_HIP = 11, 12, 23, 24

# Angle heuristic thresholds (rough, tunable): shoulder-width / torso-length.
FRONT_RATIO = 0.45
SIDE_RATIO = 0.22

MODEL_URL = ("https://storage.googleapis.com/mediapipe-models/pose_landmarker/"
             "pose_landmarker_full/float16/latest/pose_landmarker_full.task")


def ensure_model(path):
    if not os.path.exists(path):
        print(f"downloading pose model -> {path} ...", flush=True)
        urllib.request.urlretrieve(MODEL_URL, path)
    return path


def make_landmarker(model_path):
    opts = mp_vision.PoseLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=model_path),
        running_mode=mp_vision.RunningMode.IMAGE,
        num_poses=1,
        min_pose_detection_confidence=0.5,
        min_pose_presence_confidence=0.5,
    )
    return mp_vision.PoseLandmarker.create_from_options(opts)


def sample_frame_indices(total, num):
    if total <= 0:
        return []
    if total <= num:
        return list(range(total))
    return list(np.linspace(0, total - 1, num).astype(int))


def estimate_angle_flag(arr):
    """arr: (T,33,4) pixel-space. Return 0=front, 1=non-front, 2=unclear."""
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
    if r >= FRONT_RATIO:
        return 0
    if r <= SIDE_RATIO:
        return 1
    return 2


def extract_clip(fp, landmarker, num_frames):
    """Return (arr (T,33,4) pixel-space, mean_brightness) or (None, 0)."""
    cap = cv2.VideoCapture(fp)
    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) or 0
    idxs = sample_frame_indices(total, num_frames)
    frames, brights = [], []
    for i in idxs:
        cap.set(cv2.CAP_PROP_POS_FRAMES, int(i))
        ok, fr = cap.read()
        if not ok:
            continue
        h, w = fr.shape[:2]
        brights.append(float(cv2.cvtColor(fr, cv2.COLOR_BGR2GRAY).mean()))
        rgb = np.ascontiguousarray(cv2.cvtColor(fr, cv2.COLOR_BGR2RGB))
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
        res = landmarker.detect(mp_image)
        if res.pose_landmarks:
            pts = res.pose_landmarks[0]
            # --- aspect-ratio fix: normalized -> true-aspect pixel space ---
            lm = np.array([[p.x * w, p.y * h, p.z * w, p.visibility]
                           for p in pts], dtype=np.float32)
        else:
            lm = np.zeros((33, 4), dtype=np.float32)
        frames.append(lm)
    cap.release()
    if not frames:
        return None, 0.0
    arr = np.stack(frames, axis=0)
    if arr.shape[0] < num_frames:                       # pad with last frame
        pad = np.repeat(arr[-1:], num_frames - arr.shape[0], axis=0)
        arr = np.concatenate([arr, pad], axis=0)
    return arr[:num_frames], (float(np.mean(brights)) if brights else 0.0)


def discover_classes(roots):
    """Map normalized class name -> list of (root, folder) across all roots."""
    found = collections.defaultdict(list)
    for root in roots:
        if not os.path.isdir(root):
            raise SystemExit(f"dataset root not found: {root}")
        for entry in sorted(os.listdir(root)):
            n = norm(entry)
            if n in CHOSEN_N and os.path.isdir(os.path.join(root, entry)):
                found[n].append((root, entry))
    if not found:
        raise SystemExit(f"No chosen folders found under: {roots}")
    return found


def main(args):
    landmarker = make_landmarker(ensure_model(args.model_path))

    found = discover_classes(args.dataset)
    canon = sorted(found.keys())
    label_map = {name: i for i, name in enumerate(canon)}
    id_to_label = {str(i): name for name, i in label_map.items()}

    X, y, files, angles, sources = [], [], [], [], []
    kept = collections.Counter()
    drop_vis = collections.Counter()
    drop_light = collections.Counter()
    drop_noframe = collections.Counter()
    angle_counts = collections.Counter()      # (cls, flag) -> n

    for cls in canon:
        cid = label_map[cls]
        for root, folder in found[cls]:
            fdir = os.path.join(root, folder)
            vids = [f for f in os.listdir(fdir)
                    if os.path.splitext(f)[1].lower() in VIDEO_EXT]
            src = os.path.basename(root.rstrip("/"))
            print(f"[{cls}] {src}/{folder}: {len(vids)} clips ...", flush=True)
            for f in vids:
                arr, bright = extract_clip(os.path.join(fdir, f), landmarker, args.num_frames)
                if arr is None:
                    drop_noframe[cls] += 1
                    continue
                if bright < args.min_brightness:
                    drop_light[cls] += 1
                    continue
                if float(arr[..., 3].mean()) < args.vis_thresh:
                    drop_vis[cls] += 1
                    continue
                flag = estimate_angle_flag(arr)
                X.append(arr); y.append(cid); files.append(f)
                angles.append(flag); sources.append(src)
                kept[cls] += 1
                angle_counts[(cls, flag)] += 1

    if not X:
        raise SystemExit("No clips survived filtering — loosen thresholds.")

    X = np.stack(X).astype(np.float32)
    y = np.array(y, dtype=np.int64)
    files = np.array(files)
    angles = np.array(angles, dtype=np.int8)
    sources = np.array(sources)

    os.makedirs(args.out, exist_ok=True)
    np.savez_compressed(os.path.join(args.out, "landmarks.npz"),
                        X=X, y=y, files=files, angle=angles, source=sources)
    with open(os.path.join(args.out, "label_map.json"), "w") as fh:
        json.dump(label_map, fh, indent=2)
    with open(os.path.join(args.out, "id_to_label.json"), "w") as fh:
        json.dump(id_to_label, fh, indent=2)

    # ---- summary ----
    print("\n=== extraction summary ===")
    print(f"{'exercise':20}{'kept':>5}{'lowvis':>7}{'dark':>5}{'noframe':>8}"
          f"{'front':>7}{'nonfront':>9}{'unclear':>8}")
    for cls in canon:
        fr0 = angle_counts[(cls, 0)]; fr1 = angle_counts[(cls, 1)]; fr2 = angle_counts[(cls, 2)]
        print(f"{cls:20}{kept[cls]:>5}{drop_vis[cls]:>7}{drop_light[cls]:>5}"
              f"{drop_noframe[cls]:>8}{fr0:>7}{fr1:>9}{fr2:>8}")
    tf = sum(v for (c, f), v in angle_counts.items() if f == 0)
    tn = sum(v for (c, f), v in angle_counts.items() if f == 1)
    tu = sum(v for (c, f), v in angle_counts.items() if f == 2)
    print(f"\nkept {len(X)} | front {tf}  non-front {tn}  unclear {tu}")
    print(f"X shape: {X.shape} (pixel-space xyz + vis)  ->  {args.out}/landmarks.npz")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", required=True, nargs="+",
                    help="one or more dataset roots, each containing class folders")
    ap.add_argument("--out", default="data")
    ap.add_argument("--num-frames", type=int, default=32)
    ap.add_argument("--vis-thresh", type=float, default=0.7)
    ap.add_argument("--min-brightness", type=float, default=50.0)
    ap.add_argument("--model-path", default="pose_landmarker_full.task")
    main(ap.parse_args())
