extends MeleeActorView
## Review aliases only; game and demonstrations share the approved frames/timing.
func phase() -> int: return melee_phase()
func frame_index() -> int: return melee_frame_index()
func cancel_preparation() -> void: cancel_melee_preparation()
static func prepare_time(interval: float) -> float: return MeleeActorView.melee_prepare_time(interval)
