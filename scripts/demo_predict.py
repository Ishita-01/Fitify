"""
Fitify ML — Single-video inference demo (app-shaped).
Predicts the exercise + confidence from one clip, and rejects low-confidence /
non-front inputs the way the app should:
  - confidence < threshold  -> "exercise not recognized" / "film from the front"
  - otherwise               -> exercise name + confidence (+ angle flag)

Run:
    python scripts/demo_predict.py --video clip.mp4 --onnx results/gru/fitify_pose_gru.onnx
"""
import os, sys, json, argparse
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)

from extract_landmarks import (ensure_model, make_landmarker, extract_clip,
                               estimate_angle_flag)
from models.dataset import normalize_sequence
import onnxruntime as ort


def main(a):
    id_to_label = json.load(open(os.path.join(a.data_dir, "id_to_label.json")))
    landmarker = make_landmarker(ensure_model(a.model_path))

    arr, bright = extract_clip(a.video, landmarker, a.num_frames)
    if arr is None:
        raise SystemExit("could not read video / no frames")

    feats = normalize_sequence(arr)[None].astype(np.float32)     # (1,T,99)
    sess = ort.InferenceSession(a.onnx, providers=["CPUExecutionProvider"])
    logits = sess.run(None, {sess.get_inputs()[0].name: feats})[0][0]
    p = np.exp(logits - logits.max()); p /= p.sum()
    k = int(p.argmax()); conf = float(p[k]); flag = estimate_angle_flag(arr)
    angle_name = {0: "front", 1: "non-front", 2: "unclear"}[flag]

    if conf < a.threshold:
        if flag == 1:
            print(f"unclear angle — please film from the front "
                  f"(best guess: {id_to_label[str(k)]} {conf:.2f})")
        else:
            print(f"exercise not recognized (top: {id_to_label[str(k)]} {conf:.2f})")
    else:
        print(f"{id_to_label[str(k)]}  |  confidence {conf:.2f}  |  angle {angle_name}")
        # The normalized (T,99) `feats` is exactly what the form-feedback module
        # consumes next (hip-centered, torso-scaled) — pipe it straight through.


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--video", required=True)
    ap.add_argument("--onnx", default="results/gru/fitify_pose_gru.onnx")
    ap.add_argument("--data-dir", default="data")
    ap.add_argument("--model-path", default="pose_landmarker_full.task")
    ap.add_argument("--num-frames", type=int, default=32)
    ap.add_argument("--threshold", type=float, default=0.65)
    main(ap.parse_args())
