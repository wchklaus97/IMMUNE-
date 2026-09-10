#!/usr/bin/env python3
"""Build the preserved V8.6 R7.2 balanced eye-socket candidate.

R7.2 keeps R7.1's selective eye-only smoothing and uses a balanced cavity:
the shorter major axis removes the fixed cheek trench while the slightly
larger minor/depth axes continue to seat the production eye without clipping.
"""

from __future__ import annotations

import numpy as np

import build_t_v8_6_authored_sculpt_r7_1 as r7_1


SOCKET_RADII = (0.285, 0.190, 0.060)
INTERSECTION_TOLERANCE = 0.002
MIN_OUTBOARD_EXTENT = 0.025
MIN_MINOR_SPAN = 0.245
MAX_INBOARD_OVERHANG = 0.035
MAX_SIDE_DIFFERENCE = 0.003
_R6_SHAPE_CONTRACT = r7_1.r7.r6.shape_contract
_last_intersection_metrics: dict[str, float] = {}


def _eye_opening_metrics(
    solid_field: np.ndarray,
    coordinates: tuple[np.ndarray, np.ndarray, np.ndarray],
    raw_bounds: tuple[float, float, float, float, float, float],
    side: int,
) -> dict[str, float]:
    r6 = r7_1.r7.r6
    x_axis = coordinates[0][:, 0, 0].astype(np.float64, copy=False)
    y_axis = coordinates[1][0, :, 0].astype(np.float64, copy=False)
    z_axis = coordinates[2][0, 0, :].astype(np.float64, copy=False)
    inside = solid_field <= 0.0
    has_inside = np.any(inside, axis=2)
    last_inside = len(z_axis) - 1 - np.argmax(inside[:, :, ::-1], axis=2)
    valid = has_inside & (last_inside < len(z_axis) - 1)
    lower = np.take_along_axis(
        solid_field, last_inside[:, :, None], axis=2
    )[:, :, 0]
    upper = np.take_along_axis(
        solid_field, np.minimum(last_inside + 1, len(z_axis) - 1)[:, :, None], axis=2
    )[:, :, 0]
    denominator = upper - lower
    valid &= np.abs(denominator) > 1.0e-9
    interpolation = np.zeros_like(lower, dtype=np.float64)
    interpolation[valid] = -lower[valid] / denominator[valid]
    front_z = z_axis[last_inside] + interpolation * (
        z_axis[np.minimum(last_inside + 1, len(z_axis) - 1)] - z_axis[last_inside]
    )

    x_grid, y_grid = np.meshgrid(x_axis, y_axis, indexing="ij")
    source_x = side * r6.SOCKET_SOURCE_CENTER[0]
    angle_degrees = side * r6.SOCKET_ANGLE_DEGREES
    cavity = (
        (source_x, r6.SOCKET_SOURCE_CENTER[1], r6.SOCKET_SOURCE_CENTER[2]),
        SOCKET_RADII,
        2.18,
        angle_degrees,
    )
    hard_cavity = r6.base.superellipsoid_sdf(
        x_grid, y_grid, front_z, *cavity
    )
    opening = valid & (hard_cavity <= 0.0)
    if not np.any(opening):
        raise r6.BuildError(f"R7.2 side {side:+d} eye opening is empty")

    scale_x = r6.TARGET_SIZE[0] / (raw_bounds[1] - raw_bounds[0])
    scale_y = r6.TARGET_SIZE[1] / (raw_bounds[3] - raw_bounds[2])
    raw_centre_x = (raw_bounds[0] + raw_bounds[1]) * 0.5
    final_x = (x_grid - raw_centre_x) * scale_x
    final_y = (y_grid - raw_bounds[2]) * scale_y
    target_x = side * r6.SOCKET_TARGET_FINAL[0]
    theta = np.radians(angle_degrees)
    local_u = (
        np.cos(theta) * (final_x - target_x)
        + np.sin(theta) * (final_y - r6.SOCKET_TARGET_FINAL[1])
    )
    local_v = (
        -np.sin(theta) * (final_x - target_x)
        + np.cos(theta) * (final_y - r6.SOCKET_TARGET_FINAL[1])
    )
    inward_u = float(side) * local_u[opening]
    sampled_v = local_v[opening]
    u_min = float(np.min(inward_u))
    u_max = float(np.max(inward_u))
    v_min = float(np.min(sampled_v))
    v_max = float(np.max(sampled_v))
    return {
        "u_min": u_min,
        "u_max": u_max,
        "v_min": v_min,
        "v_max": v_max,
        "outboard_extent": u_max,
        "minor_span": v_max - v_min,
        "inboard_overhang": -u_min - r6.RUNTIME_EYE_SCALE[0],
    }


def _shape_contract_with_intersection(
    field: np.ndarray,
    coordinates: tuple[np.ndarray, np.ndarray, np.ndarray],
    raw_bounds: tuple[float, float, float, float, float, float],
    source,
    faces: np.ndarray,
) -> dict[str, float | int]:
    global _last_intersection_metrics
    metrics = _R6_SHAPE_CONTRACT(field, coordinates, raw_bounds, source, faces)
    solid_field = r7_1.LAST_SOLID_FIELD
    if solid_field is None:
        raise r7_1.r7.r6.BuildError("R7.2 pre-subtraction solid field is unavailable")
    left = _eye_opening_metrics(solid_field, coordinates, raw_bounds, -1)
    right = _eye_opening_metrics(solid_field, coordinates, raw_bounds, 1)
    for side_name, opening in (("left", left), ("right", right)):
        if opening["u_min"] > INTERSECTION_TOLERANCE or opening["u_max"] < -INTERSECTION_TOLERANCE:
            raise r7_1.r7.r6.BuildError(
                f"R7.2 {side_name} eye opening does not cross local u=0: {opening}"
            )
        if opening["v_min"] > INTERSECTION_TOLERANCE or opening["v_max"] < -INTERSECTION_TOLERANCE:
            raise r7_1.r7.r6.BuildError(
                f"R7.2 {side_name} eye opening does not cross local v=0: {opening}"
            )
        if opening["outboard_extent"] + INTERSECTION_TOLERANCE < MIN_OUTBOARD_EXTENT:
            raise r7_1.r7.r6.BuildError(
                f"R7.2 {side_name} eye opening lacks outboard lip: {opening}"
            )
        if opening["minor_span"] + INTERSECTION_TOLERANCE < MIN_MINOR_SPAN:
            raise r7_1.r7.r6.BuildError(
                f"R7.2 {side_name} eye opening clips the minor axis: {opening}"
            )
        if opening["inboard_overhang"] > MAX_INBOARD_OVERHANG + INTERSECTION_TOLERANCE:
            raise r7_1.r7.r6.BuildError(
                f"R7.2 {side_name} eye opening recreates the cheek trench: {opening}"
            )
    for key in ("outboard_extent", "minor_span", "inboard_overhang"):
        if abs(left[key] - right[key]) > MAX_SIDE_DIFFERENCE:
            raise r7_1.r7.r6.BuildError(
                f"R7.2 eye opening asymmetry for {key}: left={left[key]} right={right[key]}"
            )
    _last_intersection_metrics = {
        "left_outboard": left["outboard_extent"],
        "left_minor_span": left["minor_span"],
        "left_inboard_overhang": left["inboard_overhang"],
        "right_outboard": right["outboard_extent"],
        "right_minor_span": right["minor_span"],
        "right_inboard_overhang": right["inboard_overhang"],
    }
    metrics.update(_last_intersection_metrics)
    return metrics


def main() -> int:
    r7_1.SOCKET_RADII = SOCKET_RADII
    r7_1.r7.r6.shape_contract = _shape_contract_with_intersection
    result = r7_1.main()
    args = r7_1.r7.r6.parse_args()
    output = args.output.resolve()
    print(
        "T_V8_6_AUTHORED_SCULPT_R7_2_OK "
        f"output={output} bytes={output.stat().st_size} "
        f"sha256={r7_1.r7.r6.sha256(output)} "
        f"socket_radii={SOCKET_RADII} "
        f"left_outboard={_last_intersection_metrics['left_outboard']:.6f} "
        f"left_minor_span={_last_intersection_metrics['left_minor_span']:.6f} "
        f"left_inboard_overhang={_last_intersection_metrics['left_inboard_overhang']:.6f} "
        f"right_outboard={_last_intersection_metrics['right_outboard']:.6f} "
        f"right_minor_span={_last_intersection_metrics['right_minor_span']:.6f} "
        f"right_inboard_overhang={_last_intersection_metrics['right_inboard_overhang']:.6f}"
    )
    return result


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (
        r7_1.r7.r6.BuildError,
        r7_1.r7.r6.base.BuildError,
        OSError,
        ValueError,
    ) as exc:
        print(f"T_V8_6_AUTHORED_SCULPT_R7_2_FAILED {exc}")
        raise SystemExit(1)
