"""
Fitify — Shadow Trainer.
Takes one workout clip and produces three artifacts in results/shadow/<clip>/:
  1. <clip>_overlay.mp4  — skeleton tracking + live rep counter + angle HUD
  2. <clip>_report.png   — dark, app-styled dashboard (angles, reps, tempo, ROM)
  3. <clip>_report.md    — plain-English form report with improvement tips

The exercise is auto-detected with the trained GRU (override with --exercise).
Rep counting + form grading live in models/form_metrics.py.

Run:
    python scripts/shadow_trainer.py VIDEO [--onnx fitify_pose_gru.onnx]
"""
import os, sys, json, argparse
import numpy as np
import cv2

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, ROOT)

from extract_landmarks import ensure_model, make_landmarker
import mediapipe as mp
from models.form_metrics import analyze, POSE_CONNECTIONS, JOINTS, EXERCISES
import onnxruntime as ort

# ---- palette (matches lib/core/theme/app_colors.dart) ----
BG, PANEL, GRID = "#0B0D12", "#141821", "#232A36"
TXT, MUT = "#E8ECF4", "#8A93A6"
BLUE, YEL, GRN, ORG, RED = "#3B82FF", "#F5C518", "#1FB271", "#F5872A", "#E5484D"
# BGR tuples for OpenCV overlay
C_LINE = (255, 150, 60)      # blue
C_JOINT = (244, 236, 232)    # near-white
C_VERTEX = (24, 197, 245)    # yellow-ish highlight (BGR of #F5C518-ish)
C_DEEP = (113, 178, 31)      # green when in active phase
L_SH, R_SH, L_HIP, R_HIP = 11, 12, 23, 24

EPS = 1e-6


def normalize_sequence(seq):
    xyz = seq[..., :3].copy()
    hip = (xyz[:, L_HIP] + xyz[:, R_HIP]) / 2.0
    sh = (xyz[:, L_SH] + xyz[:, R_SH]) / 2.0
    torso = np.maximum(np.linalg.norm(sh - hip, axis=-1, keepdims=True), EPS)
    xyz = (xyz - hip[:, None, :]) / torso[:, None, :]
    return xyz.reshape(xyz.shape[0], -1).astype(np.float32)


def _detect(landmarker, disp):
    dh, dw = disp.shape[:2]
    rgb = np.ascontiguousarray(cv2.cvtColor(disp, cv2.COLOR_BGR2RGB))
    res = landmarker.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb))
    if res.pose_landmarks:
        pts = res.pose_landmarks[0]
        return np.array([[p.x * dw, p.y * dh, p.z * dw, p.visibility]
                         for p in pts], np.float32)
    return np.zeros((33, 4), np.float32)


def _fit(fr, out_w):
    h, w = fr.shape[:2]
    if w <= out_w:
        return fr
    s = out_w / w
    return cv2.resize(fr, (int(w * s), int(h * s)))


def dense_extract(video, landmarker, target_fps=14, max_frames=800, out_w=640):
    """Read the clip, detect landmarks at a fixed ~target_fps (so fast reps in
    long clips aren't aliased). Seek-based sampling, robust to codecs where
    sequential read fails. Returns (arr (T,33,4) pixel-space, frames, fps_eff)."""
    cap = cv2.VideoCapture(video)
    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) or 0
    src_fps = cap.get(cv2.CAP_PROP_FPS) or 30.0

    arr, frames = [], []
    if total > 0:
        stride = max(1, int(round(src_fps / target_fps)))
        if total // stride > max_frames:                 # hard cap for safety
            stride = int(np.ceil(total / max_frames))
        idxs = np.arange(0, total, stride)
        fps_eff = src_fps / stride
        for ix in idxs:
            cap.set(cv2.CAP_PROP_POS_FRAMES, int(ix))
            ok, fr = cap.read()
            if not ok:
                continue
            disp = _fit(fr, out_w)
            arr.append(_detect(landmarker, disp))
            frames.append(disp)
    else:                                   # unknown length -> sequential
        i = 0
        while True:
            ok, fr = cap.read()
            if not ok:
                break
            disp = _fit(fr, out_w)
            arr.append(_detect(landmarker, disp))
            frames.append(disp)
            i += 1
        fps_eff = src_fps
    cap.release()
    if not arr:
        return None, None, fps_eff
    return np.stack(arr), frames, fps_eff


def classify(arr, onnx, id_to_label):
    idx = np.linspace(0, len(arr) - 1, 32).astype(int)
    feats = normalize_sequence(arr[idx])[None]
    sess = ort.InferenceSession(onnx, providers=["CPUExecutionProvider"])
    logits = sess.run(None, {sess.get_inputs()[0].name: feats})[0][0]
    p = np.exp(logits - logits.max()); p /= p.sum()
    k = int(p.argmax())
    return id_to_label[str(k)], float(p[k])


# ---------------------------------------------------------------------------
# Skeleton overlay video
# ---------------------------------------------------------------------------
def _panel(img, x, y, w, h, alpha=0.55):
    ov = img.copy()
    cv2.rectangle(ov, (x, y), (x + w, y + h), (18, 14, 11), -1)
    cv2.addWeighted(ov, alpha, img, 1 - alpha, 0, img)


def render_overlay(frames, arr, res, out_path):
    cfg = EXERCISES[res["exercise"]]
    reps = res.get("reps", [])
    rep_end = sorted(r["end"] for r in reps)
    active_spans = [(r["start"], r["end"]) for r in reps]
    vertex_name = cfg["joints"][1] if "joints" in cfg else None
    vL = vR = None
    if vertex_name:
        vL, vR = JOINTS[vertex_name]
    sig = res["signal"]

    h, w = frames[0].shape[:2]
    vw = cv2.VideoWriter(out_path, cv2.VideoWriter_fourcc(*"mp4v"),
                         max(12, res["fps"]), (w, h))
    pop = 0
    for t, fr in enumerate(frames):
        img = fr.copy()
        in_active = any(s <= t <= e for s, e in active_spans)
        line_col = C_DEEP if in_active else C_LINE
        lm = arr[t]
        # bones
        for a, b in POSE_CONNECTIONS:
            if lm[a, 3] >= 0.3 and lm[b, 3] >= 0.3:
                pa = (int(lm[a, 0]), int(lm[a, 1]))
                pb = (int(lm[b, 0]), int(lm[b, 1]))
                cv2.line(img, pa, pb, line_col, 3, cv2.LINE_AA)
        # joints
        for j in range(33):
            if 11 <= j <= 28 and lm[j, 3] >= 0.3:
                c = C_VERTEX if j in (vL, vR) else C_JOINT
                rad = 7 if j in (vL, vR) else 4
                cv2.circle(img, (int(lm[j, 0]), int(lm[j, 1])), rad, c, -1, cv2.LINE_AA)

        # reps done so far
        done = sum(1 for e in rep_end if e <= t)
        if rep_end and t in rep_end:
            pop = 12

        # HUD: top-left exercise + rep count
        _panel(img, 16, 16, 250, 96)
        cv2.putText(img, res["exercise"].upper(), (30, 46),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (232, 236, 244), 2, cv2.LINE_AA)
        label = "HOLD" if res["kind"] == "hold" else "REPS"
        num = f"{res['hold_seconds']:.0f}s" if res["kind"] == "hold" else str(done)
        cv2.putText(img, f"{label}", (30, 74),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (138, 147, 166), 1, cv2.LINE_AA)
        sz = 1.7 + (0.25 if pop > 0 else 0)
        cv2.putText(img, num, (108, 100),
                    cv2.FONT_HERSHEY_SIMPLEX, sz, (24, 197, 245), 4, cv2.LINE_AA)

        # HUD: bottom angle readout + gauge
        if res["kind"] != "twist" and not np.isnan(sig[t]):
            ang = sig[t]
            _panel(img, 16, h - 70, 300, 54)
            cv2.putText(img, f"{cfg.get('unit','angle')}: {ang:.0f}deg",
                        (30, h - 40), cv2.FONT_HERSHEY_SIMPLEX, 0.6,
                        (232, 236, 244), 2, cv2.LINE_AA)
            tgt = cfg.get("target")
            if tgt:
                lo, hi = min(tgt, cfg.get("rest", 180)), max(tgt, cfg.get("rest", 180))
                frac = np.clip((ang - lo) / max(hi - lo, 1), 0, 1)
                gx, gy, gw = 30, h - 28, 270
                cv2.rectangle(img, (gx, gy), (gx + gw, gy + 8), (60, 66, 78), -1)
                fillc = (113, 178, 31) if in_active else (255, 150, 60)
                cv2.rectangle(img, (gx, gy), (gx + int(gw * frac), gy + 8), fillc, -1)

        if pop > 0:
            pop -= 1
        vw.write(img)
    vw.release()


# ---------------------------------------------------------------------------
# Dark dashboard
# ---------------------------------------------------------------------------
def render_dashboard(res, conf, clip_name, out_path):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib import gridspec

    plt.rcParams.update({
        "figure.facecolor": BG, "axes.facecolor": PANEL,
        "axes.edgecolor": GRID, "axes.labelcolor": MUT,
        "xtick.color": MUT, "ytick.color": MUT, "text.color": TXT,
        "font.size": 11, "axes.grid": True, "grid.color": GRID,
        "grid.linewidth": 0.6,
    })
    fig = plt.figure(figsize=(13, 8.6))
    gs = gridspec.GridSpec(3, 4, height_ratios=[0.9, 2.0, 1.4],
                           hspace=0.55, wspace=0.32,
                           left=0.06, right=0.965, top=0.90, bottom=0.09)

    fig.text(0.06, 0.955, "SHADOW TRAINER", color=BLUE, fontsize=15,
             fontweight="bold")
    fig.text(0.06, 0.925, f"{res['exercise'].upper()}  ·  {clip_name}",
             color=TXT, fontsize=12)
    fig.text(0.965, 0.95, f"detected {conf:.0%}", color=MUT, fontsize=10, ha="right")

    kind = res["kind"]
    # ---- stat tiles ----
    if kind == "hold":
        tiles = [("HOLD", f"{res['hold_seconds']:.0f}s", GRN),
                 ("FORM SCORE", f"{res['form_score']}", YEL),
                 ("BODY LINE", f"{res['mean_line']:.0f}°", BLUE),
                 ("STABILITY", f"±{res['stability']:.1f}°", ORG)]
    elif kind == "twist":
        tiles = [("TWISTS", f"{res['rep_count']}", YEL),
                 ("FORM SCORE", f"{res['form_score']}", GRN),
                 ("PACE", f"{res['tempo']:.1f}s", BLUE),
                 ("UNIT", "offset", MUT)]
    else:
        sym = res.get("symmetry")
        tiles = [("REPS", f"{res['rep_count']}", YEL),
                 ("FORM SCORE", f"{res['form_score']}", GRN),
                 ("AVG RANGE", f"{min(1.0, res['avg_rom'])*100:.0f}%", BLUE),
                 ("L/R BALANCE", "—" if sym is None else f"{sym:.0f}°", ORG)]
    for i, (lab, val, col) in enumerate(tiles):
        ax = fig.add_subplot(gs[0, i]); ax.axis("off")
        ax.add_patch(plt.Rectangle((0, 0), 1, 1, transform=ax.transAxes,
                     facecolor=PANEL, edgecolor=GRID, lw=1))
        ax.text(0.5, 0.66, val, ha="center", va="center", color=col,
                fontsize=27, fontweight="bold")
        ax.text(0.5, 0.22, lab, ha="center", va="center", color=MUT, fontsize=10)

    # ---- timeline ----
    ax = fig.add_subplot(gs[1, :])
    sig = res["signal"]
    x = np.arange(len(sig)) / res["fps"]
    ax.plot(x, sig, color=BLUE, lw=2.0, label=res["unit"])
    if kind == "rep":
        cfg = EXERCISES[res["exercise"]]
        ax.axhline(cfg["rest"], color=MUT, ls=":", lw=1, alpha=0.7)
        ax.axhline(cfg["target"], color=GRN, ls="--", lw=1.2, alpha=0.9)
        ax.text(x[-1], cfg["target"], "  target depth", color=GRN, fontsize=9, va="center")
        for r in res["reps"]:
            ax.axvspan(r["start"]/res["fps"], r["end"]/res["fps"],
                       color=BLUE, alpha=0.07)
            ax.plot(r["extreme_idx"]/res["fps"], r["extreme"], "o",
                    color=YEL, ms=7, zorder=5)
    elif kind == "hold":
        ax.axhspan(176, 184, color=GRN, alpha=0.10)
        ax.axhline(180, color=GRN, ls="--", lw=1.2, alpha=0.9)
        ax.text(x[-1], 180, "  ideal line", color=GRN, fontsize=9, va="center")
    elif kind == "twist":
        ax.axhline(0, color=MUT, ls=":", lw=1, alpha=0.6)
        for m in res["markers"]:
            ax.plot(m/res["fps"], sig[m], "o", color=YEL, ms=6, zorder=5)
    ax.set_xlabel("time (s)"); ax.set_ylabel(res["unit"])
    ax.set_title("joint angle over time" if kind != "twist" else "rotation over time",
                 color=TXT, fontsize=11, loc="left", pad=8)

    # ---- bottom panels ----
    if kind == "rep" and res["reps"]:
        axL = fig.add_subplot(gs[2, :2])
        roms = [min(100, p*100) for p in res["rom_pcts"]]
        cols = [GRN if p >= 85 else (ORG if p >= 65 else RED) for p in roms]
        axL.bar(range(1, len(roms)+1), roms, color=cols)
        axL.axhline(100, color=MUT, ls=":", lw=1)
        axL.set_title("range of motion per rep (%)", color=TXT, fontsize=11, loc="left")
        axL.set_xlabel("rep"); axL.set_ylim(0, 120)

        axR = fig.add_subplot(gs[2, 2:])
        temps = res["tempos"]
        axR.bar(range(1, len(temps)+1), temps, color=BLUE)
        axR.set_title("tempo per rep (s)", color=TXT, fontsize=11, loc="left")
        axR.set_xlabel("rep")
    else:
        axB = fig.add_subplot(gs[2, :]); axB.axis("off")
        tip = res["tips"][0]
        axB.add_patch(plt.Rectangle((0, 0), 1, 1, transform=axB.transAxes,
                      facecolor=PANEL, edgecolor=GRID, lw=1))
        axB.text(0.03, 0.62, "COACH", color=YEL, fontsize=11, fontweight="bold",
                 transform=axB.transAxes)
        axB.text(0.03, 0.30, tip, color=TXT, fontsize=12, transform=axB.transAxes,
                 wrap=True)

    fig.savefig(out_path, dpi=140, facecolor=BG)
    plt.close(fig)


# ---------------------------------------------------------------------------
def write_report(res, conf, clip_name, md_path, png_name, mp4_name):
    L = []
    L.append(f"# Shadow Trainer — {res['exercise'].title()}\n")
    L.append(f"**Clip:** {clip_name}  ")
    L.append(f"**Auto-detected:** {res['exercise']} ({conf:.0%} confidence)\n")
    L.append("## Summary\n")
    if res["kind"] == "hold":
        L.append(f"- **Hold time:** {res['hold_seconds']:.0f}s")
        L.append(f"- **Form score:** {res['form_score']}/100")
        L.append(f"- **Body-line angle:** {res['mean_line']:.0f}° (ideal 180°)")
        L.append(f"- **Stability:** ±{res['stability']:.1f}° wobble\n")
    elif res["kind"] == "twist":
        L.append(f"- **Twists:** {res['rep_count']}")
        L.append(f"- **Form score:** {res['form_score']}/100")
        L.append(f"- **Pace:** {res['tempo']:.1f}s per side\n")
    else:
        L.append(f"- **Reps:** {res['rep_count']}")
        L.append(f"- **Form score:** {res['form_score']}/100")
        L.append(f"- **Average range of motion:** {min(1.0, res['avg_rom'])*100:.0f}% of full")
        L.append(f"- **Average tempo:** {res['avg_tempo']:.1f}s per rep")
        if res.get("symmetry") is not None:
            L.append(f"- **Left/right balance:** {res['symmetry']:.0f}° difference")
        L.append("")
    L.append("## How to improve\n")
    for t in res["tips"]:
        L.append(f"- {t}")
    L.append("\n## Files\n")
    L.append(f"- Skeleton overlay: `{mp4_name}`")
    L.append(f"- Dashboard: `{png_name}`")
    with open(md_path, "w") as fh:
        fh.write("\n".join(L) + "\n")


def main(a):
    id_to_label = json.load(open(os.path.join(a.data_dir, "id_to_label.json")))
    landmarker = make_landmarker(ensure_model(a.model_path))

    print(f"extracting landmarks: {os.path.basename(a.video)} ...", flush=True)
    arr, frames, fps = dense_extract(a.video, landmarker, a.max_frames)
    if arr is None:
        raise SystemExit("could not read video")
    print(f"  {len(arr)} frames @ {fps:.1f} eff-fps", flush=True)

    if a.exercise:
        ex, conf = a.exercise, 1.0
    else:
        ex, conf = classify(arr, a.onnx, id_to_label)
    print(f"  exercise: {ex} ({conf:.0%})", flush=True)

    res = analyze(arr, ex, fps)
    if res["kind"] == "hold":
        print(f"  {res['hold_seconds']:.0f}s hold, form {res['form_score']}/100", flush=True)
    else:
        n = "reps" if res["kind"] == "rep" else "twists"
        print(f"  {res['rep_count']} {n}, form {res['form_score']}/100", flush=True)

    stem = os.path.splitext(os.path.basename(a.video))[0]
    safe = "".join(c if c.isalnum() else "_" for c in stem)[:48]
    outdir = os.path.join("results", "shadow", safe)
    os.makedirs(outdir, exist_ok=True)
    mp4 = os.path.join(outdir, f"{safe}_overlay.mp4")
    png = os.path.join(outdir, f"{safe}_report.png")
    md = os.path.join(outdir, f"{safe}_report.md")

    print("  rendering overlay video ...", flush=True)
    render_overlay(frames, arr, res, mp4)
    print("  rendering dashboard ...", flush=True)
    render_dashboard(res, conf, os.path.basename(a.video), png)
    write_report(res, conf, os.path.basename(a.video), md,
                 os.path.basename(png), os.path.basename(mp4))
    print(f"\n✓ {outdir}/")
    print(f"    {os.path.basename(mp4)}\n    {os.path.basename(png)}\n    {os.path.basename(md)}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("--onnx", default="fitify_pose_gru.onnx")
    ap.add_argument("--data-dir", default="data")
    ap.add_argument("--model-path", default="pose_landmarker_full.task")
    ap.add_argument("--exercise", default=None, help="override auto-detect")
    ap.add_argument("--max-frames", type=int, default=360)
    main(ap.parse_args())
