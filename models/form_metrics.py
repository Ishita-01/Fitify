"""
Fitify ML — Shadow Trainer form metrics (pure numpy, no torch).

Given a per-frame landmark sequence (T,33,4) in pixel space, this module:
  - computes the exercise-specific "rep-driving" joint angle over time,
  - counts reps with an adaptive hysteresis state machine (robust to how deep
    or shallow a given person goes — thresholds derive from the signal itself),
  - grades range-of-motion, tempo, left/right symmetry and consistency,
  - returns clean numbers + human-readable improvement tips.

All angles are 2D image-plane angles (degrees) so they match what you see on
the skeleton overlay and are interpretable for a report.
"""
import numpy as np

# MediaPipe Pose landmark indices
NOSE = 0
L_SH, R_SH = 11, 12
L_EL, R_EL = 13, 14
L_WR, R_WR = 15, 16
L_HIP, R_HIP = 23, 24
L_KNEE, R_KNEE = 25, 26
L_ANK, R_ANK = 27, 28

# name -> (left_idx, right_idx)
JOINTS = {
    "shoulder": (L_SH, R_SH), "elbow": (L_EL, R_EL), "wrist": (L_WR, R_WR),
    "hip": (L_HIP, R_HIP), "knee": (L_KNEE, R_KNEE), "ankle": (L_ANK, R_ANK),
}

# Skeleton connections to draw (clean full-body, no face/hand clutter)
POSE_CONNECTIONS = [
    (L_SH, R_SH), (L_SH, L_EL), (L_EL, L_WR), (R_SH, R_EL), (R_EL, R_WR),
    (L_SH, L_HIP), (R_SH, R_HIP), (L_HIP, R_HIP),
    (L_HIP, L_KNEE), (L_KNEE, L_ANK), (R_HIP, R_KNEE), (R_KNEE, R_ANK),
]


# ----------------------------------------------------------------------------
# Per-exercise config.
#   joints      : (a, b, c) joint names; angle is measured AT b (the vertex)
#   active      : "low"  -> a rep bottoms out at a LOW angle (squat, curl, ...)
#                 "high" -> a rep peaks at a HIGH angle (lateral raise, press)
#   target      : the angle the active phase should reach for full ROM
#   rest        : the angle of the resting/locked-out phase (for ROM %)
#   unit        : label for the plotted signal
#   cue         : short coaching line about the depth target
#   kind        : "rep" (default) | "hold" (plank) | "twist" (russian twist)
# ----------------------------------------------------------------------------
EXERCISES = {
    "squat": dict(joints=("hip", "knee", "ankle"), active="low",
                  target=90, rest=170, unit="knee angle",
                  cue="hit thighs-parallel — knee angle at/under 90°"),
    "push-up": dict(joints=("shoulder", "elbow", "wrist"), active="low",
                    target=90, rest=165, unit="elbow angle",
                    cue="lower until elbows bend to ~90° (chest near floor)"),
    "hammer curl": dict(joints=("shoulder", "elbow", "wrist"), active="low",
                        target=55, rest=160, unit="elbow angle",
                        cue="full squeeze at top, full stretch at bottom"),
    "pull up": dict(joints=("shoulder", "elbow", "wrist"), active="low",
                    target=70, rest=165, unit="elbow angle",
                    cue="pull chin over the bar (elbows under ~70°)"),
    "shoulder press": dict(joints=("hip", "shoulder", "elbow"), active="high",
                           target=160, rest=80, unit="shoulder angle",
                           cue="press to full lock-out overhead"),
    "lateral raise": dict(joints=("hip", "shoulder", "elbow"), active="high",
                          target=85, rest=20, unit="arm-to-torso angle",
                          cue="raise to shoulder height (~90°), no higher"),
    "leg raises": dict(joints=("shoulder", "hip", "knee"), active="low",
                       target=95, rest=170, unit="hip angle",
                       cue="legs to vertical (hip angle ~90°)"),
    "hip thrust": dict(joints=("shoulder", "hip", "knee"), active="high",
                       target=170, rest=120, unit="hip angle",
                       cue="drive hips to full lock-out (flat top)"),
    "deadlift": dict(joints=("shoulder", "hip", "knee"), active="low",
                     target=95, rest=170, unit="hip-hinge angle",
                     cue="hinge to the bar, stand to full lock-out"),
    "romanian deadlift": dict(joints=("shoulder", "hip", "knee"), active="low",
                              target=110, rest=170, unit="hip-hinge angle",
                              cue="hinge with soft knees, feel the hamstrings"),
    "plank": dict(joints=("shoulder", "hip", "ankle"), kind="hold",
                  target=180, unit="body-line angle",
                  cue="keep a straight line shoulder→hip→ankle (~180°)"),
    "russian twist": dict(kind="twist", unit="twist offset",
                          cue="rotate fully to each side"),
}


def _angle(a, b, c):
    """2D angle at vertex b (degrees), formed by points a-b-c."""
    ba = a[:2] - b[:2]
    bc = c[:2] - b[:2]
    nba = np.linalg.norm(ba)
    nbc = np.linalg.norm(bc)
    if nba < 1e-6 or nbc < 1e-6:
        return np.nan
    cosv = np.clip(np.dot(ba, bc) / (nba * nbc), -1.0, 1.0)
    return float(np.degrees(np.arccos(cosv)))


def _vis(frame, idx):
    return frame[idx, 3] >= 0.4


def joint_series(arr, jnames, side):
    """Angle time-series for one body side. side in {'L','R'}."""
    a_l, a_r = JOINTS[jnames[0]]
    b_l, b_r = JOINTS[jnames[1]]
    c_l, c_r = JOINTS[jnames[2]]
    ai, bi, ci = (a_l, b_l, c_l) if side == "L" else (a_r, b_r, c_r)
    out = np.full(len(arr), np.nan, np.float32)
    for t, fr in enumerate(arr):
        if _vis(fr, ai) and _vis(fr, bi) and _vis(fr, ci):
            out[t] = _angle(fr[ai], fr[bi], fr[ci])
    return out


def _interp_nan(x):
    x = x.copy()
    n = len(x)
    idx = np.arange(n)
    good = ~np.isnan(x)
    if good.sum() < 2:
        return np.zeros(n, np.float32)
    x[~good] = np.interp(idx[~good], idx[good], x[good])
    return x


def _smooth(x, win=7):
    if len(x) < win:
        return x
    k = np.ones(win) / win
    return np.convolve(x, k, mode="same")


def primary_signal(arr, ex):
    """Return (signal, left, right) for the exercise's rep-driving angle.
    left/right are None when not bilateral/applicable."""
    cfg = EXERCISES[ex]
    if cfg.get("kind") == "twist":
        # horizontal sway of the hands relative to the hips, scaled by shoulder
        # width -> a clean oscillation, one peak per side.
        sig = np.full(len(arr), np.nan, np.float32)
        for t, fr in enumerate(arr):
            if _vis(fr, L_WR) or _vis(fr, R_WR):
                wr = np.nanmean([fr[L_WR, 0] if _vis(fr, L_WR) else np.nan,
                                 fr[R_WR, 0] if _vis(fr, R_WR) else np.nan])
                hipc = (fr[L_HIP, 0] + fr[R_HIP, 0]) / 2
                shw = abs(fr[L_SH, 0] - fr[R_SH, 0]) or 1.0
                sig[t] = (wr - hipc) / shw
        s = _smooth(_interp_nan(sig))
        return s, None, None

    jn = cfg["joints"]
    left = _smooth(_interp_nan(joint_series(arr, jn, "L")))
    right = _smooth(_interp_nan(joint_series(arr, jn, "R")))
    # average the two sides for the main signal; keep both for symmetry
    sig = np.nanmean(np.stack([left, right]), axis=0)
    return sig, left, right


def count_reps(sig, active="low", min_frac=0.30):
    """Adaptive hysteresis rep counter.
    Returns list of dicts: {start, end, extreme_idx, extreme, rom}."""
    s = np.asarray(sig, float)
    lo, hi = np.nanpercentile(s, 5), np.nanpercentile(s, 95)
    amp = hi - lo
    reps = []
    if amp < 8:                      # almost no movement -> no reps
        return reps, (lo, hi)

    if active == "low":
        enter_active = lo + min_frac * amp      # cross below -> in active phase
        enter_rest = hi - min_frac * amp        # cross above -> back to rest
        rest_base = hi
        better = lambda a, b: a < b             # smaller angle = deeper
        extreme0 = np.inf
    else:
        enter_active = hi - min_frac * amp
        enter_rest = lo + min_frac * amp
        rest_base = lo
        better = lambda a, b: a > b
        extreme0 = -np.inf

    state = "rest"
    start = None
    extreme = extreme0
    ext_idx = 0
    for i, v in enumerate(s):
        if state == "rest":
            cross = v < enter_active if active == "low" else v > enter_active
            if cross:
                state = "active"
                start = i
                extreme = v
                ext_idx = i
        else:
            if better(v, extreme):
                extreme = v
                ext_idx = i
            back = v > enter_rest if active == "low" else v < enter_rest
            if back:
                reps.append(dict(start=start, end=i, extreme_idx=ext_idx,
                                 extreme=float(extreme),
                                 rom=float(abs(rest_base - extreme))))
                state = "rest"
                extreme = extreme0
    return reps, (lo, hi)


def count_twists(sig):
    """Count side-to-side twists (each peak and valley = one twist)."""
    from scipy.signal import find_peaks
    s = np.asarray(sig, float)
    amp = np.nanpercentile(s, 95) - np.nanpercentile(s, 5)
    if amp < 1e-3:
        return [], 0
    prom = 0.25 * amp
    pk, _ = find_peaks(s, prominence=prom, distance=4)
    vl, _ = find_peaks(-s, prominence=prom, distance=4)
    marks = sorted(list(pk) + list(vl))
    return marks, len(marks)


def analyze(arr, ex, fps):
    """Full form analysis for one clip. Returns a dict the dashboard + report
    both consume."""
    cfg = EXERCISES[ex]
    kind = cfg.get("kind", "rep")
    sig, left, right = primary_signal(arr, ex)
    res = dict(exercise=ex, kind=kind, unit=cfg["unit"], cue=cfg["cue"],
               signal=sig, left=left, right=right, fps=fps,
               target=cfg.get("target"))

    if kind == "hold":
        # plank: how straight & how stable is the body line, over the actual
        # held segment? Tracking glitches (lost person, camera cut) show up as
        # implausible spikes — score the longest CLEAN hold, not the raw mean.
        body = sig.copy()
        held = (body >= 150) & (body <= 195) & ~np.isnan(body)
        s0, e0, cur = 0, 0, None                 # longest contiguous held run
        for i, v in enumerate(held):
            if v and cur is None:
                cur = i
            if (not v or i == len(held) - 1) and cur is not None:
                e = i + 1 if v else i
                if e - cur > e0 - s0:
                    s0, e0 = cur, e
                cur = None
        if e0 - s0 >= max(3, int(0.8 * fps)):
            seg = body[s0:e0]
            hold_s = (e0 - s0) / fps
        else:                                    # no steady hold found
            valid = body[(body >= 120) & (body <= 200) & ~np.isnan(body)]
            seg = valid if len(valid) else body[~np.isnan(body)]
            hold_s = len(seg) / fps
        mean_line = float(np.median(seg)) if len(seg) else 0.0
        stability = float(np.std(seg)) if len(seg) else 99.0
        dev = abs(180 - mean_line)
        # score: penalize sag/pike (dev) and wobble (stability)
        score = max(0, 100 - dev * 2.2 - stability * 1.5)
        res.update(reps=[], rep_count=0, hold_seconds=hold_s,
                   mean_line=mean_line, stability=stability, deviation=dev,
                   form_score=round(score), markers=[])
        tips = []
        if mean_line < 172:
            tips.append("Hips are sagging — squeeze glutes & brace your core to "
                        "lift them back into a straight line.")
        elif mean_line > 188:
            tips.append("Hips are piking up — drop them slightly so shoulders, "
                        "hips and ankles form one line.")
        if stability > 4:
            tips.append("Body is wobbling — slow your breathing and keep tension "
                        "even to hold a rock-solid position.")
        if not tips:
            tips.append("Excellent line and stability — textbook plank.")
        res["tips"] = tips
        return res

    if kind == "twist":
        marks, n = count_twists(sig)
        tempo = (len(arr) / fps) / max(n, 1)
        score = 80 if n >= 4 else 60
        res.update(reps=[], rep_count=n, markers=marks, tempo=tempo,
                   form_score=score,
                   tips=["Rotate until your hands pass over the hip on each side "
                         "for the fullest range." if n else
                         "Couldn't see a clear twist — film from the front, seated."])
        return res

    # ---- rep-based exercises ----
    reps, (lo, hi) = count_reps(sig, active=cfg["active"])
    res["lohi"] = (lo, hi)
    target = cfg["target"]
    rest = cfg["rest"]
    active = cfg["active"]
    full_rom = abs(rest - target)

    rom_pcts, tempos, extremes = [], [], []
    for r in reps:
        achieved = abs(rest - r["extreme"])
        rom_pcts.append(min(1.2, achieved / full_rom) if full_rom else 0)
        tempos.append((r["end"] - r["start"]) / fps)
        extremes.append(r["extreme"])

    rep_count = len(reps)
    avg_rom = float(np.mean(rom_pcts)) if rom_pcts else 0.0
    avg_tempo = float(np.mean(tempos)) if tempos else 0.0
    rom_consistency = float(np.std(rom_pcts)) if len(rom_pcts) > 1 else 0.0

    # symmetry: L vs R angle at each rep's active frame
    sym = None
    if left is not None and right is not None and reps:
        diffs = [abs(left[r["extreme_idx"]] - right[r["extreme_idx"]]) for r in reps]
        sym = float(np.mean(diffs))

    # ---- form score: ROM (55) + consistency (25) + symmetry (20) ----
    rom_score = min(1.0, avg_rom) * 55
    cons_score = max(0, 1 - rom_consistency / 0.35) * 25
    sym_score = 20 if sym is None else max(0, 1 - sym / 25) * 20
    form_score = round(rom_score + cons_score + sym_score)

    # ---- improvement tips ----
    tips = []
    if avg_rom < 0.85:
        tips.append(f"Add depth — you're hitting ~{avg_rom*100:.0f}% range. {cfg['cue'].capitalize()}.")
    if rom_consistency > 0.18:
        tips.append("Your reps vary in depth — keep every rep to the same range "
                    "for cleaner, safer volume.")
    if sym is not None and sym > 14:
        tips.append(f"Left/right are uneven (~{sym:.0f}° apart) — balance the effort "
                    "so both sides work equally.")
    if avg_tempo and avg_tempo < 1.0:
        tips.append("You're moving fast — slow the lowering phase to ~2s for more "
                    "muscle control and less momentum.")
    if not tips:
        tips.append("Clean, full-range, balanced reps — keep this exact form.")

    res.update(reps=reps, rep_count=rep_count, rom_pcts=rom_pcts,
               tempos=tempos, avg_rom=avg_rom, avg_tempo=avg_tempo,
               rom_consistency=rom_consistency, symmetry=sym,
               form_score=form_score, tips=tips,
               markers=[r["extreme_idx"] for r in reps])
    return res
