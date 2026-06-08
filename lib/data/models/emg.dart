// EMG (electromyography) muscle-monitoring domain models — FUTURE FEATURE.
//
// No real EMG processing exists yet. These models define the intended data
// shape so the UI placeholders and a future hardware/ML integration agree on
// a contract. A backend table sketch is documented below.
//
// Suggested future DB schema (PostgreSQL):
//   emg_sessions(id PK, user_id FK, workout_id FK?, started_at, ended_at,
//                device_id, sample_rate_hz)
//   emg_channels(id PK, session_id FK, muscle_group, side ENUM(left,right))
//   emg_samples(id PK, channel_id FK, t_ms, micro_volts)   -- high volume
//   emg_metrics(id PK, session_id FK, muscle_group, activation_pct,
//               fatigue_index, lr_balance_pct, recovery_score)

enum MuscleGroup {
  quadriceps('Quadriceps'),
  hamstrings('Hamstrings'),
  glutes('Glutes'),
  core('Core'),
  chest('Chest'),
  back('Back'),
  shoulders('Shoulders'),
  biceps('Biceps');

  const MuscleGroup(this.label);
  final String label;
}

/// A single muscle's monitoring snapshot (placeholder values for mock charts).
class MuscleReading {
  final MuscleGroup group;
  final int activationPct; // 0..100
  final int fatigueIndex; // 0..100
  final int leftBalancePct; // 0..100 (vs right)

  const MuscleReading({
    required this.group,
    required this.activationPct,
    required this.fatigueIndex,
    required this.leftBalancePct,
  });
}
