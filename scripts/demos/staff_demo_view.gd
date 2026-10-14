extends StaffActorView
## Review UI aliases; the actual game owns the shared approved presentation.
func phase() -> int: return staff_phase()
func frame_index() -> int: return staff_frame_index()
static func prepare_time(interval: float) -> float: return StaffActorView.staff_prepare_time(interval)
