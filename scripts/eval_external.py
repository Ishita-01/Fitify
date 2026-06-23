"""
Fitify ML — External generalization test.
Extracts landmarks from UNTOUCHED folders (e.g. raw_data, test/) and scores a
trained ONNX model on them. Independent of the verified train/val/test split, so
it's an honest "never-seen clips" number for the capstone.

Run:
    python scripts/eval_external.py \
        --onnx results/gru/fitify_pose_gru.onnx \
        --dataset "<raw data-btc>" "<raw data-crawl>" "<test/test>"
"""
import os, sys, json, argparse
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)

from extract_landmarks import (ensure_model, make_landmarker, discover_classes,
                               extract_clip, estimate_angle_flag, VIDEO_EXT)
from models.dataset import normalize_sequence
import onnxruntime as ort


def main(a):
    label_map = json.load(open(os.path.join(a.data_dir, "label_map.json")))
    id_to_label = json.load(open(os.path.join(a.data_dir, "id_to_label.json")))
    num_classes = len(id_to_label)

    landmarker = make_landmarker(ensure_model(a.model_path))
    found = discover_classes(a.dataset)

    X, y, ang = [], [], []
    for cls, locs in found.items():
        if cls not in label_map:                 # only the trained classes
            continue
        cid = label_map[cls]
        for root, folder in locs:
            fdir = os.path.join(root, folder)
            vids = [f for f in os.listdir(fdir)
                    if os.path.splitext(f)[1].lower() in VIDEO_EXT]
            print(f"[{cls}] {os.path.basename(root)}/{folder}: {len(vids)}", flush=True)
            for f in vids:
                arr, bright = extract_clip(os.path.join(fdir, f), landmarker, a.num_frames)
                if arr is None or bright < a.min_brightness:
                    continue
                if float(arr[..., 3].mean()) < a.vis_thresh:
                    continue
                X.append(normalize_sequence(arr))
                y.append(cid)
                ang.append(estimate_angle_flag(arr))

    if not X:
        raise SystemExit("no external clips survived filtering")
    X = np.stack(X).astype(np.float32)
    y = np.array(y)
    ang = np.array(ang)
    print(f"\nexternal clips scored: {len(y)}")

    sess = ort.InferenceSession(a.onnx, providers=["CPUExecutionProvider"])
    iname = sess.get_inputs()[0].name
    logits = sess.run(None, {iname: X})[0]
    pred = logits.argmax(1)

    labels = [id_to_label[str(i)] for i in range(num_classes)]
    print(f"\n=== EXTERNAL test accuracy: {(y == pred).mean():.4f} ===")
    try:
        from sklearn.metrics import classification_report, confusion_matrix
        print(classification_report(y, pred, labels=list(range(num_classes)),
                                    target_names=labels, digits=3, zero_division=0))
        cm = confusion_matrix(y, pred, labels=list(range(num_classes)))
    except Exception:
        cm = np.zeros((num_classes, num_classes), int)
        for t, p in zip(y, pred):
            cm[t, p] += 1

    print("angle breakdown:")
    for flag, nm in {0: "front", 1: "non-front", 2: "unclear"}.items():
        m = ang == flag
        if m.sum():
            print(f"  {nm:10} n={int(m.sum()):4d}  acc={(y[m] == pred[m]).mean():.4f}")

    os.makedirs("results", exist_ok=True)
    np.save("results/external_confusion.npy", cm)
    print("\nsaved results/external_confusion.npy")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", required=True, nargs="+")
    ap.add_argument("--onnx", default="results/gru/fitify_pose_gru.onnx")
    ap.add_argument("--data-dir", default="data")
    ap.add_argument("--model-path", default="pose_landmarker_full.task")
    ap.add_argument("--num-frames", type=int, default=32)
    ap.add_argument("--vis-thresh", type=float, default=0.7)
    ap.add_argument("--min-brightness", type=float, default=50.0)
    main(ap.parse_args())
