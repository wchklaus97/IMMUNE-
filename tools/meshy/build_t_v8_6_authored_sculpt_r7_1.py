#!/usr/bin/env python3
"""Build the preserved V8.6 R7.1 selective-socket smoothing candidate.

R7.1 keeps R7's conservative core and arm unions, but limits the wider
subtraction blend to the two eye sockets. The forehead pore, mouth and foot
arch retain R6's audited subtraction softness.
"""

from __future__ import annotations

import numpy as np

import build_t_v8_6_authored_sculpt_r7 as r7


EYE_SOCKET_SOFTNESS = 0.014
OTHER_CAVITY_SOFTNESS = 0.008
SOCKET_RADII = (0.305, 0.185, 0.045)
LAST_SOLID_FIELD: np.ndarray | None = None


def authored_field() -> tuple[np.ndarray, tuple[np.ndarray, np.ndarray, np.ndarray]]:
    global LAST_SOLID_FIELD
    r6 = r7.r6
    x_min, x_max, y_min, y_max, z_min, z_max = r6.GRID_BOUNDS
    nx, ny, nz = r6.GRID_DIMS
    xs = np.linspace(x_min, x_max, nx, dtype=np.float32)[:, None, None]
    ys = np.linspace(y_min, y_max, ny, dtype=np.float32)[None, :, None]
    zs = np.linspace(z_min, z_max, nz, dtype=np.float32)[None, None, :]

    solids = [
        ((0.000, 0.810, -0.010), (0.620, 0.700, 0.420), 2.28, 0.0),
        ((0.000, 0.430, 0.030), (0.655, 0.345, 0.450), 2.02, 0.0),
        ((0.000, 0.215, 0.075), (0.570, 0.210, 0.415), 2.48, 0.0),
        ((-0.385, 0.112, 0.170), (0.405, 0.165, 0.400), 2.16, 3.0),
        ((0.385, 0.112, 0.170), (0.405, 0.165, 0.400), 2.16, -3.0),
        ((-0.575, 0.800, -0.005), (0.235, 0.290, 0.290), 2.20, -20.0),
        ((-0.755, 0.640, 0.025), (0.170, 0.225, 0.230), 2.12, -14.0),
        ((-0.900, 0.475, 0.070), (0.125, 0.185, 0.200), 2.06, -5.0),
        ((-0.850, 0.345, 0.095), (0.150, 0.125, 0.190), 2.04, 22.0),
        ((0.575, 0.800, -0.005), (0.235, 0.290, 0.290), 2.20, 20.0),
        ((0.755, 0.640, 0.025), (0.170, 0.225, 0.230), 2.12, 14.0),
        ((0.900, 0.475, 0.070), (0.125, 0.185, 0.200), 2.06, 5.0),
        ((0.850, 0.345, 0.095), (0.150, 0.125, 0.190), 2.04, -22.0),
    ]
    field = r6.base.superellipsoid_sdf(xs, ys, zs, *solids[0])
    for solid_index, solid in enumerate(solids[1:], start=1):
        softness = (
            r7.CORE_UNION_SOFTNESS if solid_index < 5 else r7.ARM_UNION_SOFTNESS
        )
        field = r6.base.smooth_min(
            field,
            r6.base.superellipsoid_sdf(xs, ys, zs, *solid),
            softness,
        )
    # Retain the pre-subtraction skin for R7.2's eye-opening intersection gate.
    # smooth_max returns a new array, so the solid field remains immutable here.
    LAST_SOLID_FIELD = field

    cavities = [
        (
            (
                -r6.SOCKET_SOURCE_CENTER[0],
                r6.SOCKET_SOURCE_CENTER[1],
                r6.SOCKET_SOURCE_CENTER[2],
            ),
            r7.SOCKET_RADII,
            2.18,
            -r6.SOCKET_ANGLE_DEGREES,
        ),
        (
            r6.SOCKET_SOURCE_CENTER,
            r7.SOCKET_RADII,
            2.18,
            r6.SOCKET_ANGLE_DEGREES,
        ),
        ((0.000, 1.085, 0.420), (0.064, 0.064, 0.034), 2.00, 0.0),
        ((0.000, 0.625, 0.460), (0.084, 0.028, 0.032), 2.00, 0.0),
        ((0.000, 0.015, 0.055), (0.235, 0.185, 0.720), 2.08, 0.0),
    ]
    for cavity_index, cavity in enumerate(cavities):
        cavity_field = r6.base.superellipsoid_sdf(xs, ys, zs, *cavity)
        softness = EYE_SOCKET_SOFTNESS if cavity_index < 2 else OTHER_CAVITY_SOFTNESS
        field = r6.base.smooth_max(field, -cavity_field, softness)
    return field.astype(np.float32, copy=False), (xs, ys, zs)


def main() -> int:
    r7.CORE_UNION_SOFTNESS = 0.084
    r7.ARM_UNION_SOFTNESS = 0.050
    r7.SOCKET_SOFTNESS = OTHER_CAVITY_SOFTNESS
    r7.SOCKET_RADII = SOCKET_RADII
    r7.r6.authored_field = authored_field
    result = r7.main()
    args = r7.r6.parse_args()
    output = args.output.resolve()
    print(
        "T_V8_6_AUTHORED_SCULPT_R7_1_OK "
        f"output={output} bytes={output.stat().st_size} sha256={r7.r6.sha256(output)} "
        f"eye_socket_softness={EYE_SOCKET_SOFTNESS:.3f} "
        f"other_cavity_softness={OTHER_CAVITY_SOFTNESS:.3f}"
    )
    return result


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (
        r7.r6.BuildError,
        r7.r6.base.BuildError,
        OSError,
        ValueError,
    ) as exc:
        print(f"T_V8_6_AUTHORED_SCULPT_R7_1_FAILED {exc}")
        raise SystemExit(1)
