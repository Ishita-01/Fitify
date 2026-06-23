"""
Generates a self-contained Kaggle notebook (fitify_pose_kaggle.ipynb) from the
canonical pipeline modules, so the notebook never drifts from the repo code.

The notebook writes the four modules to disk via %%writefile, runs extraction on
the verified_data folders, trains GRU then CNN, and renders both confusion
matrices + the front/non-front angle breakdown with a model recommendation.

Run:  python scripts/make_notebook.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read(rel):
    with open(os.path.join(ROOT, rel)) as fh:
        return fh.read()


def code(src):
    return {"cell_type": "code", "metadata": {}, "execution_count": None,
            "outputs": [], "source": src}


def md(src):
    return {"cell_type": "markdown", "metadata": {}, "source": src}


def writefile(path, content):
    return code(f"%%writefile {path}\n{content}")


cells = []

cells.append(md(
    "# Fitify — Pose-Landmark Exercise Classifier (Kaggle)\n"
    "\n"
    "Path B: BlazePose landmarks → normalized sequences → small temporal "
    "classifier (GRU / 1D-CNN). Self-contained: run top to bottom on a GPU "
    "kernel.\n"
    "\n"
    "**Aspect-ratio fix baked in:** extraction converts MediaPipe's normalized "
    "coords to true-aspect pixel space (`x*W, y*H, z*W`) before the hip-center + "
    "torso-scale normalization. The dataset is ~20% portrait / 79% landscape, so "
    "this removes real training noise (and the portrait-inference bug).\n"
    "\n"
    "> **App parity:** the deployed pose pipeline must apply the identical "
    "`x*W, y*H, z*W` (live camera frame W/H) before normalization, or the bug "
    "returns at inference."
))

cells.append(md(
    "## 1. Setup\n"
    "**Accelerator must be `GPU T4 x2`** (Settings → Accelerator). Kaggle's "
    "current PyTorch does **not** support the P100 (sm_60); T4 is sm_75."
))
cells.append(code(
    "# Kaggle pre-installs torch/numpy/sklearn/opencv; add the rest.\n"
    "# (no output suppression, so install problems are visible)\n"
    "!pip install -q mediapipe onnxscript\n"
    "import mediapipe as mp\n"
    "print('mediapipe', mp.__version__)\n"
    "from mediapipe.tasks.python import vision as _v  # verify Tasks vision API\n"
    "print('tasks.vision OK')\n"
    "import os\n"
    "os.makedirs('models', exist_ok=True)\n"
    "os.makedirs('scripts', exist_ok=True)\n"
    "open('models/__init__.py', 'w').close()"
))
cells.append(code(
    "import torch\n"
    "print('CUDA:', torch.cuda.is_available())\n"
    "print('device:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU')"
))

cells.append(md("## 2. Write the pipeline modules"))
cells.append(writefile("models/dataset.py", read("models/dataset.py")))
cells.append(writefile("models/nets.py", read("models/nets.py")))
cells.append(writefile("scripts/extract_landmarks.py", read("scripts/extract_landmarks.py")))
cells.append(writefile("scripts/train.py", read("scripts/train.py")))

cells.append(md(
    "## 3. Extract landmarks (verified_data only)\n"
    "Point these at your uploaded Kaggle dataset. Two roots = the two verified "
    "sources; extraction merges same-named class folders across both."
))
cells.append(code(
    "# Dataset mount paths (verified_data, both sources):\n"
    "ROOT_BTC   = '/kaggle/input/datasets/vishardmehta/fitify-private-dataset/verified_data/verified_data/data_btc_10s'\n"
    "ROOT_CRAWL = '/kaggle/input/datasets/vishardmehta/fitify-private-dataset/verified_data/verified_data/data_crawl_10s'\n"
    "assert os.path.isdir(ROOT_BTC) and os.path.isdir(ROOT_CRAWL), \\\n"
    "    'paths wrong — run:  !find /kaggle/input -type d -name data_btc_10s -o -type d -name data_crawl_10s'\n"
    "!python scripts/extract_landmarks.py --dataset \"$ROOT_BTC\" \"$ROOT_CRAWL\" \\\n"
    "    --num-frames 32 --vis-thresh 0.7 --min-brightness 50"
))

cells.append(md("## 4. Train GRU"))
cells.append(code(
    "!python scripts/train.py --model gru --epochs 120 --patience 20\n"
    "import shutil, os\n"
    "os.makedirs('results/gru', exist_ok=True)\n"
    "for f in ['test_report.txt','confusion_matrix.npy','history.json']:\n"
    "    shutil.copy(f'results/{f}', f'results/gru/{f}')\n"
    "shutil.copy('checkpoints/fitify_pose.onnx', 'results/gru/fitify_pose_gru.onnx')"
))

cells.append(md("## 5. Train CNN"))
cells.append(code(
    "!python scripts/train.py --model cnn --epochs 120 --patience 20\n"
    "os.makedirs('results/cnn', exist_ok=True)\n"
    "for f in ['test_report.txt','confusion_matrix.npy','history.json']:\n"
    "    shutil.copy(f'results/{f}', f'results/cnn/{f}')\n"
    "shutil.copy('checkpoints/fitify_pose.onnx', 'results/cnn/fitify_pose_cnn.onnx')"
))

cells.append(md("## 6. Compare — confusion matrices, angle split, recommendation"))
cells.append(code(
    "import numpy as np, json, matplotlib.pyplot as plt\n"
    "labels = [v for k, v in sorted(json.load(open('data/id_to_label.json')).items(), key=lambda x:int(x[0]))]\n"
    "\n"
    "def show(tag, ax):\n"
    "    cm = np.load(f'results/{tag}/confusion_matrix.npy')\n"
    "    cmn = cm / cm.sum(1, keepdims=True).clip(min=1)\n"
    "    im = ax.imshow(cmn, cmap='Blues', vmin=0, vmax=1)\n"
    "    ax.set_title(tag.upper()); ax.set_xticks(range(len(labels))); ax.set_yticks(range(len(labels)))\n"
    "    ax.set_xticklabels(labels, rotation=90, fontsize=7); ax.set_yticklabels(labels, fontsize=7)\n"
    "    return cm\n"
    "\n"
    "fig, axes = plt.subplots(1, 2, figsize=(15, 6))\n"
    "for tag, ax in zip(['gru','cnn'], axes):\n"
    "    show(tag, ax)\n"
    "plt.tight_layout(); plt.show()\n"
    "\n"
    "for tag in ['gru','cnn']:\n"
    "    print('='*60, tag.upper()); print(open(f'results/{tag}/test_report.txt').read())"
))
cells.append(code(
    "# Most-confused pairs + recommendation\n"
    "for tag in ['gru','cnn']:\n"
    "    cm = np.load(f'results/{tag}/confusion_matrix.npy').astype(float)\n"
    "    off = cm.copy(); np.fill_diagonal(off, 0)\n"
    "    pairs = sorted(((off[i,j], labels[i], labels[j]) for i in range(len(labels)) for j in range(len(labels)) if off[i,j]>0), reverse=True)[:5]\n"
    "    acc = np.trace(cm)/cm.sum()\n"
    "    print(f'\\n{tag.upper()} test_acc={acc:.3f}  top confusions:')\n"
    "    for n,a,b in pairs: print(f'   {a} -> {b}: {int(n)}')\n"
))

cells.append(md(
    "## 7. Ship decision\n"
    "Pick the model with the better **macro-F1** (read from the reports above); "
    "if GRU and CNN are within ~1%, ship the **CNN** (smaller + faster inference). "
    "The exported ONNX is in `results/<model>/`. Feed the same normalized 99-dim "
    "landmark sequence to the form-feedback module — it's already hip-centered & "
    "torso-scaled."
))

nb = {
    "cells": cells,
    "metadata": {
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {"name": "python"},
        "accelerator": "GPU",
    },
    "nbformat": 4,
    "nbformat_minor": 5,
}

out = os.path.join(ROOT, "fitify_pose_kaggle.ipynb")
with open(out, "w") as fh:
    json.dump(nb, fh, indent=1)
print(f"wrote {out} ({len(cells)} cells)")
