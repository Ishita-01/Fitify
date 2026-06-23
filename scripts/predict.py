"""
Fitify ML — Standalone single/multi-video inference (no torch needed).
Inlines the exact training-time normalization (hip-center + torso-scale on
pixel-space landmarks) so the number you see here is what the app would see.

Run:
    python scripts/predict.py --onnx fitify_pose_gru.onnx VIDEO [VIDEO ...]
"""
import os, sys, json, argparse
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

from extract_landmarks import (ensure_model, make_landmarker, extract_clip,
                               estimate_angle_flag)
import onnxruntime as ort

L_SH, R_SH, L_HIP, R_HIP = 11, 12, 23, 24
EPS = 1e-6


def normalize_sequence(seq):
    """(T,33,4) raw -> (T,99) hip-centered, torso-scaled xyz. Pure numpy."""
    xyz = seq[..., :3].copy()
    hip_center = (xyz[:, L_HIP] + xyz[:, R_HIP]) / 2.0
    sh_center = (xyz[:, L_SH] + xyz[:, R_SH]) / 2.0
    torso = np.linalg.norm(sh_center - hip_center, axis=-1, keepdims=True)
    torso = np.maximum(torso, EPS)
    xyz = xyz - hip_center[:, None, :]
    xyz = xyz / torso[:, None, :]
    return xyz.reshape(xyz.shape[0], -1).astype(np.float32)


def main(a):
    id_to_label = json.load(open(os.path.join(a.data_dir, "id_to_label.json")))
    landmarker = make_landmarker(ensure_model(a.model_path))
    sess = ort.InferenceSession(a.onnx, providers=["CPUExecutionProvider"])
    iname = sess.get_inputs()[0].name
    angle_name = {0: "front", 1: "non-front", 2: "unclear"}

    for video in a.videos:
        name = os.path.basename(video)
        arr, bright = extract_clip(video, landmarker, a.num_frames)
        if arr is None:
            print(f"\n{name}\n  could not read video / no frames")
            continue

        feats = normalize_sequence(arr)[None].astype(np.float32)
        logits = sess.run(None, {iname: feats})[0][0]
        p = np.exp(logits - logits.max()); p /= p.sum()
        order = p.argsort()[::-1]
        k = int(order[0]); conf = float(p[k]); flag = estimate_angle_flag(arr)

        print(f"\n{name}")
        print(f"  brightness {bright:.0f}   camera angle: {angle_name[flag]}")
        if conf < a.threshold:
            if flag == 1:
                print(f"  unclear — film from the front "
                      f"(best guess: {id_to_label[str(k)]} {conf:.0%})")
            else:
                print(f"  exercise not recognized "
                      f"(top guess: {id_to_label[str(k)]} {conf:.0%})")
        else:
            print(f"  >>> {id_to_label[str(k)].upper()}   confidence {conf:.0%}")
        print("  top-3:")
        for j in order[:3]:
            print(f"     {id_to_label[str(int(j))]:18} {p[j]:.0%}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("videos", nargs="+")
    ap.add_argument("--onnx", default="fitify_pose_gru.onnx")
    ap.add_argument("--data-dir", default="data")
    ap.add_argument("--model-path", default="pose_landmarker_full.task")
    ap.add_argument("--num-frames", type=int, default=32)
    ap.add_argument("--threshold", type=float, default=0.65)
    main(ap.parse_args())
