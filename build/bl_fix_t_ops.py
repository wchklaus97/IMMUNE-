"""Vertex-displacement operations that turn the Tripo CHAR-BASE-T remesh into the
concept read: flush recessed forehead pore, no nose bump, mirrored eyes, clean
frown, bell proportions.

Pure numpy so it can be driven either from Blender or from a local analysis
session. Nothing here adds, removes or reorders vertices, so the UV layer and the
baked basecolor keep landing exactly where they landed before.
"""

import numpy as np

# ---------------------------------------------------------------- parameters

PARAMS = dict(
    # Bell proportions. The earlier reading of this was wrong: it compared the
    # concept's outline against the *unscaled* remesh render and called them
    # close. Projecting the mesh through bl_shots' own camera (an_flare.py) and
    # lining the two profiles up band by band shows the concept is 6-8% wider
    # than the mesh at every height from the crown to the feet, and the mesh had
    # then been made narrower still. This is the squat half of "squat broad bell"
    # and no amount of limb work substitutes for it.
    scale_xy=1.045,
    scale_z=0.985,
    tuck=0.0,                  # how far the foot lobes come in
    tuck_z0=0.36,              # fraction of height where the tuck starts
    tuck_z1=0.18,              # and where it is fully applied

    # symmetry: copy the clean +X half onto the pinched -X half
    mirror_from_plus_x=True,
    mirror_seam=0.012,
    mirror_blend=0.075,        # width of the crease-free hand-over at the centre

    # --- forehead pore -----------------------------------------------------
    # The remesh models the pore as a closed lens welded onto the skull, not as
    # part of it, and only that lens carries the dark centre in the basecolor.
    # So the lens is reshaped into the dish and the skull behind it is hollowed
    # out far enough that its flat spans cannot cut back through.
    pore_centre=(-0.004, -0.327, 0.641),   # pre-scale, from the painted dark disc
    # The concept's pore is about 0.25 of head width across with the dark centre
    # 0.37 of that. The ratio is matched; the absolute size is not, because the
    # painted dark disc only runs to radius 0.017 and a wider mouth to the hole
    # would show orange funnel walls.
    pore_hole_r=0.022,
    pore_hole_floor=0.50,
    pore_hole_depth=0.036,
    pore_dish_r=0.094,         # dish is carved across lens *and* skull alike
    pore_dish_depth=0.0125,
    pore_lip=0.0024,
    # everything the carve touches has to stay inside the locally subdivided
    # patch, or the coarse triangles just outside it crease where the smooth
    # displacement field gets sampled at their corners
    pore_blend_r=0.100,
    pore_fit_r0=0.088,
    pore_fit_r1=0.180,
    pore_fit_zmin=0.605,       # post-scale; above the brows so the sockets stay out
    pore_fit_xband=0.085,      # the smooth strip between the eyes is fair game
    pore_front_band=0.020,     # how far behind the skull still counts as lens front
    pore_front_fade=0.016,
    # The lens is dived under the skull past this radius instead of being faded
    # out. Two smooth surfaces crossing give a truly circular rim; fading a
    # ragged shell boundary gives the lumpy outline the first attempts had.
    # The visible rim is where the sunk lens crosses the skull, so these radii —
    # not pore_dish_r — set how big the pore reads. The concept's ring is 0.125
    # of body width across, which puts the crossing at r ~ 0.062.
    # The lens's front face only reaches r = 0.065, so a rim placed at 0.064 was
    # landing on the shell's own ragged boundary — that is the faceting and the
    # notch at 7 o'clock the critics saw, and no amount of extra subdivision
    # fixes a rim drawn along a mesh edge. Pulling the crossing well inside the
    # front face gives a clean circle, and the pore is made to read broad by
    # deepening the saucer on the skull instead, which runs out to r = 0.094 —
    # 0.26 of head width, the ratio the concept has.
    pore_sink_r0=0.040,
    pore_sink_r1=0.052,
    pore_sink=0.040,
    pore_clear_rim=0.005,      # skull sits at least this far behind the dish
    # Deep enough that the skull falls behind the hole's own floor. At 0.012 it
    # stopped 0.032 in front of it, so what showed through the hole was a lit
    # sliver of skull rather than the painted dark interior. The core clearance
    # is gone by r = 0.039, which the lens covers, so none of it is visible.
    pore_clear_core=0.045,
    pore_clear_r0=0.038,       # clearance is gone by here, so the skull can carry
    pore_clear_r1=0.070,       # the outer half of the dish itself
    pore_skull_hold=0.058,
    pore_back_push=0.014,      # lens back retreats so the hollowed skull clears it

    # nose bump between the eyes: flatten onto the smoothed skull
    nose_centre=(0.0, -0.34, 0.472),       # pre-scale
    nose_radii=(0.072, 0.14, 0.062),
    nose_strength=0.92,

    # Mouth. The remesh has no crease here: a clay close-up shows a crescent
    # pocket cut clean through the surface, and an_mouth5.py shows the basecolor
    # paints the inside of it dark. That pocket *is* the frown. Filling it in
    # brings the dark paint out onto the skin as a ragged purple patch, so the
    # pocket is kept and squeezed shut instead — the neighbourhood is compressed
    # towards the frown curve until the opening reads as a slit, and the dark
    # interior stays where the light cannot reach it.
    mouth_centre=(0.0, -0.33, 0.4360),     # pre-scale, the pocket's own centre
    mouth_pinch=0.55,          # how far the opening closes
    mouth_pinch_radii=(0.090, 0.080, 0.042),
    mouth_polish=0.30,         # light smoothing of the scratchy rim
    mouth_polish_iters=20,
    mouth_radii=(0.070, 0.100, 0.045),
    mouth_half_width=0.048,    # concept frown is ~0.10 of head width across
    mouth_arc=0.016,
    mouth_groove_w=0.0055,     # a thin slit, not an open mouth
    mouth_depth=0.0,           # the pocket already is the groove

    # --- limbs and skirt ---------------------------------------------------
    # The concept is a squat bell whose hem flares out past the body and breaks
    # into lobes, with two arms that taper to a hooked tip. The remesh has the
    # same features in the same places, just far too timid: an outline overlay
    # (an_overlay.py) puts the concept a clear margin outside the mesh all the
    # way down both arms and around the foot lobes, while the two agree over
    # the dome. So the limbs are amplified rather than invented — every vertex
    # is pushed further along the direction it already sticks out in, which
    # keeps the lobes where the concept has them and keeps the paint aligned.
    limb_gain=1.30,            # clearly widen the existing outer arm limbs
    limb_z0=0.46,              # height fraction where limb work fades out
    limb_z1=0.30,              # and where it is fully on
    limb_core_smooth=18.0,     # sigma in degrees of the azimuth average
    limb_core_zsmooth=1.6,     # bins; keeps the core surface from following lobes
    limb_thin=0.62,            # stronger taper: leave a narrow hooked outer limb
    hem_flare=0.065,           # reinforce the skirt edge without changing its shells
    hem_z0=0.26,               # height fraction where the flare starts
    skin_band=0.13,            # only this near the outer radius counts as skin
    skin_face=0.20,            # and the normal has to be this horizontal
    skin_smooth=20,            # smoothing passes on the mask
    push_smooth=30,            # and on the displacement itself
    radial_smooth=18.0,        # samples of 201; the knots are a trend, not a curve
    arm_cos0=0.82,             # capture the full shoulder-to-tip limb silhouette

    # The bell. Front-on, the mesh's outline already matched the concept on
    # every aggregate worth measuring — width per height, concavity, hem
    # waviness — because the two side nubs happen to be as wide as the concept's
    # arms. The side view is where it falls apart: the mesh's depth *shrinks*
    # from 0.77 at mid height to 0.53 at the hem, so it is an egg tapering to
    # the ground, while the concept flares all the way round. This fills the
    # skirt out towards the widest radius the body reaches at that height, so
    # the waist azimuths (front and back, where nothing sticks out) catch up
    # with the limb azimuths and the whole thing reads as one flared bell.
    bell_fill=0.72,            # how far the narrow azimuths catch up
    bell_env=1.00,             # target radius as a fraction of the widest there
    bell_z0=0.50,              # height fraction where the flare fades out
    bell_z1=0.30,              # and where it is fully on
    bell_toe=0.18,             # near the ground the flare eases off again
    bell_toe_keep=0.30,

    # Width against height, as knots of (height fraction, radial factor).
    # Measured, not guessed: the green-screen reference keys cleanly so its
    # outline is exact, and an_flare.py projects the mesh through bl_shots' own
    # camera, so dividing one profile by the other gives the factor the body is
    # short of at each height directly. The concept render cannot be used for
    # this — its bloom halo adds about 3% of the frame on every side and drags
    # the bounding box with it, which is how the mesh came to be called "within
    # a few percent" while being visibly the wrong shape.
    radial_knots=(
    # Kept monotone up to the crown on purpose. An earlier fit put a local
    # maximum at s = 0.60 and, being a factor on radius at a given height, that
    # is a ridge running right around the body — which at the brow reads as the
    # nose the last round was asked to remove.
        (0.00, 0.900), (0.10, 0.925), (0.20, 0.987), (0.30, 1.002),
        (0.40, 1.031), (0.50, 1.058), (0.60, 1.068), (0.70, 1.071),
        (0.80, 1.067), (0.90, 1.055), (1.00, 1.035),
    ),
    # The outline overlay put the reference's arm 11% of the body's height
    # lower than the mesh's, hanging outside the foot instead of stopping above
    # it, which is the whole of the 23% width shortfall across the bottom fifth.
    # The gain is large because the field is smoothed hard: an unsmoothed drop
    # of this size tears the arm off its own underside.
    arm_drop=-0.16,            # signed: negative lifts the arm field instead of dropping it
    arm_drop_z0=0.15,          # the whole arm below the shoulder goes down as one
    hook_lift=0.480,           # strong upward return so the tapered tip visibly hooks up
    hook_zmax=0.58,            # keep the upward return visible farther along the tip
    outer_lift=0.220,          # direct lift on the visible outer limb for a clear hook
    arm_solid=0.06,            # let the lift carry through the outer limb, not just its tip
    arm_smooth=24,             # retain a readable silhouette bend after smoothing

    # The hem. Front-on the outline was 9-23% short of the reference across the
    # bottom fifth: the reference's skirt dips nearly as low between the lobes
    # as it does under them, one continuous wavy hem, while the remesh arches
    # high between the feet and the gap reads as a bite out of the silhouette.
    # This pulls the high stretches of the hem down towards the low ones.
    hem_fill=0.22,
    hem_keep=0.35,             # notches keep this much of their height above the
    hem_fill_z=0.20,           # lowest hem; the rest is closed
    hem_bins=72,
    hem_smooth=2.5,
    # The concept's arm is a slender tentacle standing away from the body; the
    # remesh's is a paddle smeared along the flank. Squeezing the protruding
    # part in azimuth towards the arm's own axis narrows it into a tentacle and
    # opens the notch between it and the trunk, without shortening its reach.
    arm_squeeze=0.68,
    arm_squeeze_z0=0.42,

    # Four smooth azimuthal skirt lobes. The source already contains the four
    # skirt/foot shells; this field separates their low points from the
    # intervening notches without adding geometry or disturbing the face.
    skirt_lobe_gain=0.105,
    skirt_wave=0.075,
    skirt_wave_phase=0.0,
    skirt_wave_z0=0.34,
    skirt_wave_z1=0.10,

    taubin_iters=90,
)


# ------------------------------------------------------------------ topology

def weld(co, tol=1e-5):
    """Group coincident vertices (the GLB splits them along UV seams)."""
    key = np.round(co / tol).astype(np.int64)
    _, inv = np.unique(key, axis=0, return_inverse=True)
    m = int(inv.max()) + 1
    acc = np.zeros((m, 3))
    cnt = np.zeros(m)
    np.add.at(acc, inv, co)
    np.add.at(cnt, inv, 1.0)
    return inv, acc / cnt[:, None]


def group_tris(tris, inv):
    gt = inv[tris]
    good = (gt[:, 0] != gt[:, 1]) & (gt[:, 1] != gt[:, 2]) & (gt[:, 0] != gt[:, 2])
    return gt[good]


def neighbour_sum(P, edges, n):
    """Sum of neighbour positions and neighbour count, from an edge list."""
    acc = np.zeros((n, 3))
    cnt = np.zeros(n)
    np.add.at(acc, edges[:, 0], P[edges[:, 1]])
    np.add.at(acc, edges[:, 1], P[edges[:, 0]])
    np.add.at(cnt, edges[:, 0], 1.0)
    np.add.at(cnt, edges[:, 1], 1.0)
    cnt[cnt == 0] = 1.0
    return acc, cnt


def taubin(P, edges, iters, lam=0.5, mu=-0.53):
    """Volume-preserving smoothing; used only as a base surface to blend toward."""
    n = len(P)
    Q = P.copy()
    for _ in range(iters):
        for f in (lam, mu):
            acc, cnt = neighbour_sum(Q, edges, n)
            Q = Q + f * (acc / cnt[:, None] - Q)
    return Q


def tri_edges(gt):
    e = np.concatenate([gt[:, [0, 1]], gt[:, [1, 2]], gt[:, [2, 0]]])
    e = np.sort(e, axis=1)
    return np.unique(e, axis=0)


def vertex_normals(P, gt):
    n = np.zeros_like(P)
    a, b, c = P[gt[:, 0]], P[gt[:, 1]], P[gt[:, 2]]
    fn = np.cross(b - a, c - a)
    for k in range(3):
        np.add.at(n, gt[:, k], fn)
    ln = np.linalg.norm(n, axis=1)
    ln[ln == 0] = 1.0
    return n / ln[:, None]


# --------------------------------------------------------- closest point kit

def closest_point_on_tris(Q, A, B, C, chunk=96):
    """Nearest surface point for each query, over a triangle soup (Ericson)."""
    out = np.empty_like(Q)
    ab = B - A
    ac = C - A
    for s in range(0, len(Q), chunk):
        q = Q[s:s + chunk][:, None, :]
        ap = q - A[None]
        d1 = (ab[None] * ap).sum(-1)
        d2 = (ac[None] * ap).sum(-1)
        bp = q - B[None]
        d3 = (ab[None] * bp).sum(-1)
        d4 = (ac[None] * bp).sum(-1)
        cp = q - C[None]
        d5 = (ab[None] * cp).sum(-1)
        d6 = (ac[None] * cp).sum(-1)

        vc = d1 * d4 - d3 * d2
        vb = d5 * d2 - d1 * d6
        va = d3 * d6 - d5 * d4
        denom = 1.0 / np.maximum(va + vb + vc, 1e-20)
        v = vb * denom
        w = vc * denom

        # start from the interior solution, then override each outside region
        v = np.clip(v, 0.0, 1.0)
        w = np.clip(w, 0.0, 1.0)

        p = A[None] + ab[None] * v[..., None] + ac[None] * w[..., None]

        reg_a = (d1 <= 0) & (d2 <= 0)
        reg_b = (d3 >= 0) & (d4 <= d3)
        reg_c = (d6 >= 0) & (d5 <= d6)
        reg_ab = (vc <= 0) & (d1 >= 0) & (d3 <= 0)
        reg_ac = (vb <= 0) & (d2 >= 0) & (d6 <= 0)
        reg_bc = (va <= 0) & ((d4 - d3) >= 0) & ((d5 - d6) >= 0)

        t = np.clip(d1 / np.maximum(d1 - d3, 1e-20), 0, 1)
        p = np.where(reg_ab[..., None], A[None] + ab[None] * t[..., None], p)
        t = np.clip(d2 / np.maximum(d2 - d6, 1e-20), 0, 1)
        p = np.where(reg_ac[..., None], A[None] + ac[None] * t[..., None], p)
        t = np.clip((d4 - d3) / np.maximum((d4 - d3) + (d5 - d6), 1e-20), 0, 1)
        p = np.where(reg_bc[..., None], B[None] + (C - B)[None] * t[..., None], p)
        p = np.where(reg_a[..., None], A[None], p)
        p = np.where(reg_b[..., None], B[None], p)
        p = np.where(reg_c[..., None], C[None], p)

        d = ((p - q) ** 2).sum(-1)
        best = np.argmin(d, axis=1)
        out[s:s + chunk] = p[np.arange(len(best)), best]
    return out


# ------------------------------------------------------------------ helpers

def components(n, edges):
    """Union-find over the welded edge list.

    The remesh is not one closed surface: the eyes and the forehead pore are
    separate shells dropped into the body. Knowing which shell a vertex belongs
    to is what makes the pore fixable, because the pore lens and the skull
    behind it have to move in opposite directions.
    """
    parent = np.arange(n)

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for a, b in edges:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb
    return np.array([find(i) for i in range(n)])


def smootherstep(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * t * (t * (t * 6 - 15) + 10)


def front_height_field(P, gt, C, n, t1, t2, half, grid=128, samples=6, blur=3):
    """Height of the front-most surface of one shell over the pore's plane.

    The lens is closed, so most of its vertices are behind its own front face.
    Landing every vertex on the target height would turn it inside out; knowing
    where its front face is lets the back ride along at a fixed offset instead.
    """
    A, B, Cc = P[gt[:, 0]], P[gt[:, 1]], P[gt[:, 2]]
    bs = [(i / samples, j / samples, 1 - i / samples - j / samples)
          for i in range(samples + 1) for j in range(samples + 1 - i)]
    pts = np.concatenate([A * b[0] + B * b[1] + Cc * b[2] for b in bs])
    rel = pts - C
    h, u, v = rel @ n, rel @ t1, rel @ t2
    m = (np.abs(u) < half) & (np.abs(v) < half)
    u, v, h = u[m], v[m], h[m]

    iu = np.clip(((u + half) / (2 * half) * (grid - 1)).astype(int), 0, grid - 1)
    iv = np.clip(((v + half) / (2 * half) * (grid - 1)).astype(int), 0, grid - 1)
    field = np.full(grid * grid, -1e9)
    np.maximum.at(field, iv * grid + iu, h)
    field = field.reshape(grid, grid)

    empty = field < -1e8
    for _ in range(24):                      # spread into cells nothing landed in
        if not empty.any():
            break
        pad = np.full((grid + 2, grid + 2), -1e9)
        pad[1:-1, 1:-1] = field
        stack = np.stack([pad[:-2, 1:-1], pad[2:, 1:-1], pad[1:-1, :-2], pad[1:-1, 2:]])
        field = np.where(empty, stack.max(axis=0), field)
        empty = field < -1e8
    field = np.where(empty, field[~empty].min() if (~empty).any() else 0.0, field)

    for _ in range(blur):                    # max-pooling is jagged; average it out
        pad = np.pad(field, 1, mode="edge")
        field = (pad[:-2, 1:-1] + pad[2:, 1:-1] + pad[1:-1, :-2] + pad[1:-1, 2:]
                 + 2.0 * field) / 6.0

    def sample(uq, vq):
        fu = np.clip((uq + half) / (2 * half) * (grid - 1), 0, grid - 1)
        fv = np.clip((vq + half) / (2 * half) * (grid - 1), 0, grid - 1)
        i0 = np.floor(fu).astype(int)
        j0 = np.floor(fv).astype(int)
        i1 = np.minimum(i0 + 1, grid - 1)
        j1 = np.minimum(j0 + 1, grid - 1)
        au, av = fu - i0, fv - j0
        return ((field[j0, i0] * (1 - au) + field[j0, i1] * au) * (1 - av)
                + (field[j1, i0] * (1 - au) + field[j1, i1] * au) * av)

    return sample


def ellipsoid_weight(P, centre, radii):
    d = (P - np.asarray(centre)) / np.asarray(radii)
    r = np.linalg.norm(d, axis=1)
    return 1.0 - smootherstep(r)


# --------------------------------------------------------------- operations

def apply_scale(P, p):
    """Bell nudge. z is scaled about the ground plane so the feet stay planted."""
    out = P.copy()
    z0 = P[:, 2].min()
    H = max(P[:, 2].max() - z0, 1e-6)
    t = (P[:, 2] - z0) / H
    tuck = 1.0 - p["tuck"] * (1.0 - smootherstep(
        (t - p["tuck_z1"]) / (p["tuck_z0"] - p["tuck_z1"])))
    out[:, 0] *= p["scale_xy"] * tuck
    out[:, 1] *= p["scale_xy"] * tuck
    out[:, 2] *= p["scale_z"]
    return out


def _project_mirror(P, out, tgt, src_mask, gt, p, xmin=None, twosided=False):
    keep = src_mask[gt].all(axis=1)
    if xmin is not None:
        keep &= P[gt, 0].max(axis=1) > xmin
    src_tri = gt[keep]
    if len(src_tri) == 0 or len(tgt) == 0:
        return
    A, B, C = P[src_tri[:, 0]], P[src_tri[:, 1]], P[src_tri[:, 2]]
    Q = P[tgt].copy()
    Q[:, 0] *= -1.0
    hit = closest_point_on_tris(Q, A, B, C)
    hit[:, 0] *= -1.0
    if twosided:
        # Replacing one half outright leaves a slope break exactly on the centre
        # line, which renders as a hairline crease straight down the face. This
        # ramp is 1 out on the -X side, 0 out on the +X side and 0.5 on the
        # centre line, and w(-x) = 1 - w(x), so the result is still an exact
        # mirror image of itself — just without the kink.
        t = -P[tgt, 0] / max(p["mirror_blend"], 1e-6)
        w = smootherstep(np.clip((t + 1.0) * 0.5, 0.0, 1.0))[:, None]
    else:
        w = smootherstep(np.abs(P[tgt, 0]) / max(p["mirror_seam"], 1e-6))[:, None]
    out[tgt] = P[tgt] * (1 - w) + hit * w


def symmetrize(P, gt, comp, p):
    """Project the pinched half onto the mirror of the clean half.

    Shell by shell, because the eyes are two separate shells: each one lives
    entirely on its own side, so the left eye has to be mirrored from the right
    eye's geometry rather than from anything inside itself.
    """
    out = P.copy()
    ids = np.unique(comp)
    cx = {c: P[comp == c, 0].mean() for c in ids}
    ctr = {c: P[comp == c].mean(axis=0) for c in ids}
    for c in ids:
        m = comp == c
        if abs(cx[c]) < 0.05:                     # straddles the centre line
            _project_mirror(P, out, np.nonzero(m)[0], m, gt, p, twosided=True)
        elif cx[c] < 0:                           # a left-side shell: find its partner
            mirrored = ctr[c] * np.array([-1.0, 1.0, 1.0])
            partner = min((c2 for c2 in ids if cx[c2] > 0.05),
                          key=lambda c2: np.linalg.norm(ctr[c2] - mirrored),
                          default=None)
            if partner is not None:
                _project_mirror(P, out, np.nonzero(m)[0], comp == partner, gt, p)
    return out


def flatten_region(P, base, centre, radii, strength):
    w = ellipsoid_weight(P, centre, radii)[:, None] * strength
    return P * (1 - w) + base * w


def pore_frame(P, gt, lens, p):
    """Centre, outward axis and a quadric fit of the skull around the pore.

    Two things have to stay out of the fit or the base surface lies: the lens
    itself, and the eye sockets, which sit inside the fitting annulus and drag
    the surface backwards. A smoothed copy of the mesh is no base either —
    smoothing a bump leaves a broad low mound exactly where the bump was.
    """
    C = np.array(p["pore_centre"], dtype=float)
    C = C * np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    N = vertex_normals(P, gt)

    n = N[(~lens) & (np.linalg.norm(P - C, axis=1) < 0.16)].mean(axis=0)
    n[0] = 0.0                     # the face is symmetric, so the pore looks straight out
    n /= np.linalg.norm(n)

    coef = None
    ok = None
    for _ in range(3):
        t1 = np.cross(n, np.array([0.0, 0.0, 1.0]))
        t1 /= np.linalg.norm(t1)
        t2 = np.cross(n, t1)
        rel = P - C
        h, u, v = rel @ n, rel @ t1, rel @ t2
        r = np.hypot(u, v)

        band = (~lens) & ((N @ n) > 0.30)
        band &= (r > p["pore_fit_r0"]) & (r < p["pore_fit_r1"]) & (np.abs(h) < 0.10)
        band &= (P[:, 2] > p["pore_fit_zmin"]) | (np.abs(P[:, 0]) < p["pore_fit_xband"])
        ok = band.copy()
        for _ in range(4):
            M = np.stack([np.ones(int(ok.sum())), u[ok], v[ok],
                          u[ok] ** 2, u[ok] * v[ok], v[ok] ** 2], axis=1)
            coef, *_ = np.linalg.lstsq(M, h[ok], rcond=None)
            res = h - quad(coef, u, v)
            trimmed = band & (res > -0.010) & (res < 0.012)
            if trimmed.sum() < 12:
                break
            ok = trimmed
        n = n - coef[1] * t1 - coef[2] * t2
        n[0] = 0.0
        n /= np.linalg.norm(n)
    return C, n, t1, t2, coef, ok


def quad(c, u, v):
    return c[0] + c[1] * u + c[2] * v + c[3] * u ** 2 + c[4] * u * v + c[5] * v ** 2


def carve_pore(P, gt, lens, p, log=None):
    """Turn the welded-on lens into a flush dish and hollow the skull behind it.

    Everything that reads at camera distance lives on the lens: its front face
    is the ring and the dark centre. Pressing that front into a shallow dish is
    only half the job — the skull runs straight across underneath it, so once
    the dish drops below the skull the skull's own flat spans slice through the
    dish and show up as chips around the rim. The skull therefore gets hollowed
    out to stay a clear margin behind whatever the dish is doing.
    """
    C, n, t1, t2, coef, ok = pore_frame(P, gt, lens, p)
    rel = P - C
    h, u, v = rel @ n, rel @ t1, rel @ t2
    r = np.hypot(u, v)
    base_h = quad(coef, u, v)

    R_hole, R_dish = p["pore_hole_r"], p["pore_dish_r"]
    dish = -p["pore_dish_depth"] * (1.0 - smootherstep((r - R_hole) / (R_dish - R_hole)))
    floor = p["pore_hole_floor"] * R_hole
    hole = -p["pore_hole_depth"] * (
        1.0 - smootherstep((r - floor) / max(R_hole - floor, 1e-6)))
    lip = p["pore_lip"] * np.exp(-((r - R_dish) / (0.22 * R_dish)) ** 2)
    target = base_h + dish + hole + lip

    rel_h = h - base_h

    # The lens moves as a body: its front face lands on the dish, and everything
    # behind that face is carried by the same amount, keeping the shell intact.
    # Past pore_sink_r0 the whole thing dives under the skull, so the visible rim
    # is where two smooth surfaces cross — which is a true circle, unlike the
    # ragged shell boundary an opacity fade would have exposed.
    lens_tri = gt[lens[gt].all(axis=1)]
    hf = front_height_field(P, lens_tri, C, n, t1, t2,
                            half=p["pore_blend_r"])(u, v)
    s = 1.0 - smootherstep((hf - h - 0.003) / 0.012)
    h_ref = s * h + (1.0 - s) * hf
    sink = -p["pore_sink"] * smootherstep(
        (r - p["pore_sink_r0"]) / (p["pore_sink_r1"] - p["pore_sink_r0"]))

    # the skull: hollowed to sit behind the dish where the lens covers it, and
    # carrying the dish itself further out where it does not
    clear = (p["pore_clear_rim"] + p["pore_clear_core"] * (
        1.0 - smootherstep(r / (0.42 * R_dish)))) * (1.0 - smootherstep(
            (r - p["pore_clear_r0"]) / (p["pore_clear_r1"] - p["pore_clear_r0"])))
    w_skull_r = 1.0 - smootherstep(
        (r - p["pore_skull_hold"]) / (p["pore_blend_r"] - p["pore_skull_hold"]))
    # only the outer skin of the skull moves; the back of the head falls inside
    # this radius too and must not follow
    w_skull_d = 1.0 - smootherstep((-0.018 - rel_h) / 0.014)
    w_skull = (~lens) * np.clip(w_skull_r, 0, 1) * np.clip(w_skull_d, 0, 1)

    delta = (lens * (target + sink - h_ref)
             + w_skull * (target - clear - h))
    out = P + delta[:, None] * n[None, :]

    if log is not None:
        core = lens & (r < R_dish * 0.5) & (s > 0.5)
        log["pore_axis"] = n.round(4).tolist()
        log["pore_centre_scaled"] = C.round(4).tolist()
        log["pore_lens_verts"] = int(lens.sum())
        log["pore_fit_pts"] = int(ok.sum())
        log["pore_lens_moved"] = int((lens & (np.abs(delta) > 1e-5)).sum())
        log["pore_skull_moved"] = int(
            (w_skull * np.abs(target - clear - h) > 1e-5).sum())
        log["pore_boss_before"] = round(float(rel_h[core].max()), 4)
        log["pore_boss_after"] = round(float((h + delta - base_h)[core].max()), 4)
        log["pore_floor_after"] = round(float((h + delta - base_h)[core].min()), 4)
        sk = (~lens) & (r < p["pore_sink_r0"]) & (rel_h > -0.05)
        log["pore_skull_after"] = round(float((h + delta - base_h)[sk].max()), 4)
    return out


def pinch_mouth(P, p, log=None):
    """Squeeze the mouth pocket shut towards its own frown curve.

    Everything in the neighbourhood moves, walls and skin alike, so nothing
    tears; the only visible effect is that the opening narrows and the painted
    interior stops catching light.
    """
    C = np.array(p["mouth_centre"], dtype=float)
    C = C * np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    # The frown curve is only defined across the mouth. Left to run, the
    # parabola drops 0.056 by the edge of the pinch region — deeper than the
    # region is tall — and drags the cheeks down into a chevron that renders as
    # a hard crease under both eyes.
    dx = np.clip(P[:, 0] - C[0], -p["mouth_half_width"], p["mouth_half_width"])
    k = p["mouth_arc"] / (p["mouth_half_width"] ** 2)
    dz = P[:, 2] - (C[2] - k * dx ** 2)
    w = ellipsoid_weight(P, C, p["mouth_pinch_radii"])
    out = P.copy()
    out[:, 2] -= p["mouth_pinch"] * w * dz
    if log is not None:
        log["mouth_pinched"] = int((w > 0.01).sum())
    return out


def mouth_frame(P, gt, p):
    """Centre, outward axis and a quadric fit of the lower face around the mouth.

    Same construction as pore_frame, with the eye sockets kept out of the fit by
    height rather than by shell membership — the mouth pocket is part of the body
    shell, so there is nothing to exclude by component.
    """
    C = np.array(p["mouth_centre"], dtype=float)
    C = C * np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    N = vertex_normals(P, gt)

    n = np.array([0.0, -1.0, 0.0])
    coef = None
    ok = None
    for _ in range(3):
        t1 = np.cross(n, np.array([0.0, 0.0, 1.0]))
        t1 /= np.linalg.norm(t1)
        t2 = np.cross(n, t1)
        rel = P - C
        h, u, v = rel @ n, rel @ t1, rel @ t2
        r = np.hypot(u, v)

        band = ((N @ n) > 0.30) & (np.abs(h) < 0.10)
        band &= (r > p["mouth_fit_r0"]) & (r < p["mouth_fit_r1"])
        band &= P[:, 2] < p["mouth_fit_zmax"]
        ok = band.copy()
        for _ in range(4):
            M = np.stack([np.ones(int(ok.sum())), u[ok], v[ok],
                          u[ok] ** 2, u[ok] * v[ok], v[ok] ** 2], axis=1)
            coef, *_ = np.linalg.lstsq(M, h[ok], rcond=None)
            res = h - quad(coef, u, v)
            trimmed = band & (res > -0.012) & (res < 0.012)
            if trimmed.sum() < 12:
                break
            ok = trimmed
        n = n - coef[1] * t1 - coef[2] * t2
        n[0] = 0.0
        n /= np.linalg.norm(n)
    return C, n, t1, t2, coef, ok


def fill_mouth(P, gt, p, log=None):
    """Snap the whole mouth patch onto the fitted skull surface.

    Lifting only the vertices that sit behind the fit leaves the pocket's rim
    bunched up and the patch renders as a crumpled lump. Snapping every front
    vertex in the patch onto the quadric instead gives an analytically smooth
    face for the frown to be cut into, which is the whole point of fitting one.
    """
    C, n, t1, t2, coef, ok = mouth_frame(P, gt, p)
    rel = P - C
    h, u, v = rel @ n, rel @ t1, rel @ t2
    r = np.hypot(u, v * p["mouth_fill_vscale"])
    off = quad(coef, u, v) - h

    near = 1.0 - smootherstep((r - p["mouth_fill_r0"])
                              / (p["mouth_fill_r1"] - p["mouth_fill_r0"]))
    # anything further back than this is interior body geometry, not the shell
    shell = 1.0 - smootherstep((np.abs(off) - p["mouth_fill_depth"])
                               / p["mouth_fill_fade"])
    lift = p["mouth_fill"] * near * shell * off
    if log is not None:
        log["mouth_fit_pts"] = int(ok.sum())
        log["mouth_pocket_depth"] = round(
            float(off[(near > 0.5) & (shell > 0.5)].max()), 4)
        log["mouth_filled"] = int((np.abs(lift) > 1e-4).sum())
    return P + lift[:, None] * n[None, :]


def smooth_scalar(x, edges, n, iters, lam=0.6):
    """Laplacian smoothing of a per-vertex weight, over the welded edge graph."""
    q = np.asarray(x, dtype=float).copy()
    for _ in range(iters):
        acc = np.zeros(n)
        cnt = np.zeros(n)
        np.add.at(acc, edges[:, 0], q[edges[:, 1]])
        np.add.at(acc, edges[:, 1], q[edges[:, 0]])
        np.add.at(cnt, edges[:, 0], 1.0)
        np.add.at(cnt, edges[:, 1], 1.0)
        cnt[cnt == 0] = 1.0
        q = q + lam * (acc / cnt - q)
    return q


def strain(before, after, edges, log=None):
    """How unevenly a deformation stretched the mesh, edge by edge.

    A displacement field that changes fast compared with the local edge length
    is what shows up in a render as facets and spikes, and the low-poly foot
    lobes have edges four times the length of the ones on the face. Measuring
    it here catches that in a second instead of after a two-minute render.
    """
    d = after - before
    a, b = edges[:, 0], edges[:, 1]
    L = np.linalg.norm(before[a] - before[b], axis=1)
    g = np.linalg.norm(d[a] - d[b], axis=1) / np.maximum(L, 1e-9)
    if log is not None:
        log["strain_p50"] = round(float(np.percentile(g, 50)), 4)
        log["strain_p99"] = round(float(np.percentile(g, 99)), 4)
        log["strain_max"] = round(float(g.max()), 4)
        log["strain_over_25pct"] = int((g > 0.25).sum())
        worst = np.argsort(g)[-6:][::-1]
        log["strain_worst_at"] = [
            [round(float(v), 3) for v in (0.5 * (before[a[i]] + before[b[i]]))]
            for i in worst]
    return g


def shape_radial(P, body, p, log=None):
    """Scale the body's width by height, from the knot table.

    A pure radial scale about the vertical axis, so nothing can tear and the
    marks on the face ride along with the head they sit on instead of sliding
    across it.
    """
    knots = np.asarray(p["radial_knots"], dtype=float)
    if np.allclose(knots[:, 1], 1.0):
        return P
    B = P[body]
    z0, z1 = B[:, 2].min(), B[:, 2].max()
    s = (P[:, 2] - z0) / max(z1 - z0, 1e-6)

    # resample the knots onto a fine ladder and smooth it, so the factor has no
    # corners that would show up as rings around the body
    grid = np.linspace(0.0, 1.0, 201)
    f = np.interp(grid, knots[:, 0], knots[:, 1])
    sg = p["radial_smooth"]
    k = int(3 * sg)
    w = np.exp(-0.5 * (np.arange(-k, k + 1) / sg) ** 2)
    w /= w.sum()
    f = np.convolve(np.pad(f, k, mode="edge"), w, mode="valid")
    fac = np.interp(np.clip(s, 0.0, 1.0), grid, f)

    cx = 0.5 * (B[:, 0].min() + B[:, 0].max())
    cy = 0.5 * (B[:, 1].min() + B[:, 1].max())
    out = P.copy()
    out[:, 0] = cx + (P[:, 0] - cx) * fac
    out[:, 1] = cy + (P[:, 1] - cy) * fac
    if log is not None:
        log["radial_range"] = [round(float(f.min()), 4), round(float(f.max()), 4)]
    return out


def core_radius(P, body, p, nz=44, nt=72):
    """The body's radius with the limbs averaged away, sampled per vertex.

    Averaging the outer radius over a wide arc of azimuth gives a surface that
    follows the trunk but rides straight through the arms and the foot lobes.
    Whatever a vertex sticks out past that is, by construction, limb.
    """
    B = P[body]
    zlo, zhi = B[:, 2].min(), B[:, 2].max()
    H = max(zhi - zlo, 1e-6)
    cx = 0.5 * (B[:, 0].min() + B[:, 0].max())
    cy = 0.5 * (B[:, 1].min() + B[:, 1].max())

    def polar(Q):
        dx, dy = Q[:, 0] - cx, Q[:, 1] - cy
        return np.hypot(dx, dy), np.arctan2(dy, dx), (Q[:, 2] - zlo) / H

    rb, tb, sb = polar(B)
    # azimuth bins are centred on +X and -X, so mirrored vertices land in
    # mirrored bins exactly and the amplified limbs stay symmetric
    iz = np.clip((sb * nz).astype(int), 0, nz - 1)
    it = np.floor((tb / (2 * np.pi) + 0.5) * nt + 0.5).astype(int) % nt
    grid = np.zeros((nz, nt))
    np.maximum.at(grid, (iz, it), rb)

    # bins nothing landed in would read as radius zero and pull the core in
    for _ in range(6):
        empty = grid <= 0
        if not empty.any():
            break
        nb = np.stack([np.roll(grid, 1, 1), np.roll(grid, -1, 1),
                       np.roll(grid, 1, 0), np.roll(grid, -1, 0)])
        grid = np.where(empty, nb.max(axis=0), grid)

    sig_t = max(p["limb_core_smooth"] / (360.0 / nt), 1e-6)
    k = np.exp(-0.5 * (np.arange(nt) - nt // 2) ** 2 / sig_t ** 2)
    k /= k.sum()
    core = np.real(np.fft.ifft(np.fft.fft(grid, axis=1)
                               * np.fft.fft(np.roll(k, -(nt // 2)))[None, :], axis=1))
    sig_z = p["limb_core_zsmooth"]
    if sig_z > 0:
        w = np.exp(-0.5 * (np.arange(-3, 4) / sig_z) ** 2)
        w /= w.sum()
        pad = np.pad(core, ((3, 3), (0, 0)), mode="edge")
        core = sum(w[i] * pad[i:i + nz] for i in range(7))

    r, th, s = polar(P)
    fz = np.clip(s * nz - 0.5, 0, nz - 1)
    ft = (th / (2 * np.pi) + 0.5) * nt
    z0 = np.floor(fz).astype(int)
    z1 = np.minimum(z0 + 1, nz - 1)
    t0 = np.floor(ft).astype(int) % nt
    t1 = (t0 + 1) % nt
    az, at = fz - z0, ft - np.floor(ft)
    Rc = ((core[z0, t0] * (1 - at) + core[z0, t1] * at) * (1 - az)
          + (core[z1, t0] * (1 - at) + core[z1, t1] * at) * az)

    # widest the body gets at each height, for the bell to aim at
    wide = core.max(axis=1)
    w = np.exp(-0.5 * (np.arange(-3, 4) / 1.5) ** 2)
    w /= w.sum()
    padw = np.pad(wide, 3, mode="edge")
    wide = sum(w[i] * padw[i:i + nz] for i in range(7))
    Rw = wide[z0] * (1 - az) + wide[z1] * az
    return r, th, s, Rc, Rw, (cx, cy)


def flare_limbs(P, gt, body, p, log=None):
    """Amplify the arms, the foot lobes and the wavy hem of the skirt.

    Nothing is added or removed; each vertex is moved further out along the
    direction it already protrudes in, so the four lobes stay where the concept
    puts them and the basecolor still lands on the same geometry. The extra
    terms give the limbs the shape the outline overlay says they are missing:
    the arms rise outward and curl up at the tip, and the skirt keeps four
    distinct low lobes instead of collapsing into two flat feet.
    """
    r, th, s, Rc, Rw, (cx, cy) = core_radius(P, body, p)
    edges = tri_edges(gt)

    # A radial push only makes sense on the body's outer side wall. The remesh
    # is packed with interior geometry, the sole faces straight down, and near
    # the axis neighbouring vertices sit at completely different azimuths — push
    # any of those radially and the mesh shatters into facets. Two gates: how
    # close the vertex is to the outer radius at its own height and azimuth, and
    # how much of its normal is horizontal. Both are then smoothed over the mesh
    # so the field cannot change faster than the geometry can carry.
    N = vertex_normals(P, gt)
    nh = np.hypot(N[:, 0], N[:, 1])
    skin = (body * smootherstep((r - Rc + p["skin_band"]) / p["skin_band"])
            * smootherstep((nh - p["skin_face"]) / 0.35))
    skin = smooth_scalar(skin, edges, len(P), p["skin_smooth"])

    ex = np.maximum(r - Rc, 0.0)                       # how much is limb
    gz = 1.0 - smootherstep((s - p["limb_z1"]) / (p["limb_z0"] - p["limb_z1"]))

    # taper: the flanks of a lobe get less of the push than its spine, so the
    # limb narrows as it grows instead of turning into a paddle
    peak = _lobe_peak(ex, s)
    frac = np.clip(ex / np.maximum(peak, 1e-6), 0.0, 1.5)
    taper = 1.0 - p["limb_thin"] * (1.0 - smootherstep(frac))

    dr = p["limb_gain"] * gz * skin * ex * taper

    # the bell: bring the narrow azimuths out towards the widest radius the
    # body reaches at that height, so the skirt flares in every direction
    gb = 1.0 - smootherstep((s - p["bell_z1"]) / (p["bell_z0"] - p["bell_z1"]))
    gb = gb * (p["bell_toe_keep"] + (1.0 - p["bell_toe_keep"])
               * smootherstep(s / p["bell_toe"])) * skin
    dr = dr + p["bell_fill"] * gb * np.maximum(p["bell_env"] * Rw - Rc, 0.0)

    # and a little more right at the hem, where the concept's skirt turns out
    hem = 1.0 - smootherstep(s / p["hem_z0"])
    dr = dr + (p["hem_flare"] * hem * skin
               * (0.35 + 0.65 * smootherstep(frac)))

    # Separate four broad existing skirt shells into lobes and notches. The
    # lobe centres get a little more radial reach; the signed wave below lowers
    # those same centres while leaving the intervening notches higher.
    skirt_gate = (1.0 - smootherstep(
        (s - p["skirt_wave_z1"])
        / max(p["skirt_wave_z0"] - p["skirt_wave_z1"], 1e-6))) * skin
    four = 0.5 + 0.5 * np.cos(4.0 * (th - p["skirt_wave_phase"]))
    dr = dr + p["skirt_lobe_gain"] * skirt_gate * four
    dr = smooth_scalar(dr, edges, len(P), p["push_smooth"])

    # The arms, and only the arms: a window around +/-X. The foot lobes sit at
    # about 35 degrees off the front and would otherwise be dragged down and
    # curled with them, which is what the concept does not do.
    armw = smootherstep((np.abs(np.cos(th)) - p["arm_cos0"])
                        / max(1.0 - p["arm_cos0"], 1e-6))
    arm = armw * skin

    # narrow the arm in azimuth so it reads as a tentacle rather than a paddle
    off = th - np.where(np.cos(th) >= 0.0, 0.0, np.pi)
    off = (off + np.pi) % (2 * np.pi) - np.pi
    wsq = (arm * smootherstep((frac - 0.25) / 0.55)
           * (1.0 - smootherstep((s - p["arm_squeeze_z0"]) / 0.14)))
    wsq = smooth_scalar(wsq, edges, len(P), p["push_smooth"])
    th2 = th - p["arm_squeeze"] * wsq * off

    out = P.copy()
    out[:, 0] = cx + (r + dr) * np.cos(th2)
    out[:, 1] = cy + (r + dr) * np.sin(th2)

    # Lowering a limb is a translation of the whole limb, not of its outer skin.
    # The skin mask drops anything whose normal points down, so the arm's own
    # underside is not in it: gating the drop on that slides the side wall past
    # a cap that stayed where it was. This gate asks only where a vertex is.
    solid = body * armw * gz * smootherstep(
        (frac - p["arm_solid"]) / max(1.0 - p["arm_solid"], 1e-6))
    solid = smooth_scalar(solid, edges, len(P), p["arm_smooth"])

    band = smootherstep((s - 0.02) / max(p["arm_drop_z0"] - 0.02, 1e-6))
    dz = -solid * band * p["arm_drop"]
    # and the tip curls back up into a hook
    tip = smootherstep((frac - 0.45) / 0.55) * (
        1.0 - smootherstep((s - p["hook_zmax"]) / 0.10))
    # The tip must first cancel the arm's downward translation, then rise above
    # it; otherwise a larger hook_lift only makes the drop less deep and the
    # rendered outline never forms the concept's upward hook.
    dz = dz + solid * tip * (p["hook_lift"] + p["arm_drop"] * band)

    # The smoothed whole-limb translation above preserves continuity, but can
    # still leave the raster's outer silhouette reading as a low paddle. Add a
    # second, vertex-only lift keyed to the existing outer protrusion so the
    # visible limb returns upward at its end without moving the shoulder/core.
    outer = (body * armw * smootherstep((frac - 0.15) / 0.55)
             * (1.0 - smootherstep((s - p["hook_zmax"]) / 0.12)))
    outer = smooth_scalar(outer, edges, len(P), max(8, p["arm_smooth"] // 2))
    dz = dz + p["outer_lift"] * outer

    # Close the arch between the foot lobes: measure how low the hem hangs at
    # each azimuth and pull the high stretches down towards the low ones.
    hemw = skin * (1.0 - smootherstep((s - p["hem_fill_z"]) / 0.10))
    lo = azimuth_min(P[:, 2], th, hemw, p["hem_bins"], p["hem_smooth"])
    z0 = P[:, 2].min()
    dz = dz + p["hem_fill"] * hemw * (1.0 - p["hem_keep"]) * (z0 - lo)
    dz = dz - p["skirt_wave"] * skirt_gate * four

    dz = smooth_scalar(dz, edges, len(P), p["arm_smooth"])
    out[:, 2] += dz

    if log is not None:
        log["limb_verts"] = int((np.abs(dr) > 1e-4).sum())
        log["limb_max_push"] = round(float(dr.max()), 4)
        log["limb_hook_verts"] = int((arm * tip > 0.15).sum())
        log["skirt_lobe_verts"] = int((skirt_gate * four > 0.15).sum())
        log["limb_dz_min"] = round(float(dz.min()), 4)
        log["limb_dz_max"] = round(float(dz.max()), 4)
    return out


def azimuth_min(z, th, w, nt=72, sig=2.5):
    """Lowest z reached at each azimuth, wrapped and smoothed, per vertex.

    Only vertices the caller has marked count towards the minimum, but every
    vertex gets an answer, so the field is defined across the whole hem band.
    """
    it = np.clip(((th + np.pi) / (2 * np.pi) * nt).astype(int), 0, nt - 1)
    lo = np.full(nt, np.inf)
    m = w > 0.25
    if m.any():
        np.minimum.at(lo, it[m], z[m])
    bad = ~np.isfinite(lo)
    lo[bad] = lo[~bad].max() if (~bad).any() else 0.0
    k = int(np.ceil(3 * sig))
    g = np.exp(-0.5 * (np.arange(-k, k + 1) / sig) ** 2)
    g /= g.sum()
    lo = sum(g[i] * np.roll(lo, i - k) for i in range(2 * k + 1))
    return lo[it]


def _lobe_peak(ex, s, nz=44):
    """Largest protrusion at each height, for normalising the taper."""
    iz = np.clip((s * nz).astype(int), 0, nz - 1)
    peak = np.zeros(nz)
    np.maximum.at(peak, iz, ex)
    w = np.exp(-0.5 * (np.arange(-4, 5) / 2.0) ** 2)
    w /= w.sum()
    pad = np.pad(peak, 4, mode="edge")
    peak = sum(w[i] * pad[i:i + nz] for i in range(9))
    return peak[iz]


def carve_mouth(P, gt, p):
    C = np.array(p["mouth_centre"], dtype=float)
    C = C * np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    N = vertex_normals(P, gt)
    n = np.array([0.0, -1.0, 0.0])
    ring = (np.linalg.norm(P - C, axis=1) < 0.10) & (N[:, 1] < -0.4)
    if ring.sum() > 6:
        n = N[ring].mean(axis=0)
        n /= np.linalg.norm(n)

    dx = P[:, 0] - C[0]
    k = p["mouth_arc"] / (p["mouth_half_width"] ** 2)
    z_curve = C[2] - k * dx ** 2
    dz = P[:, 2] - z_curve
    along = 1.0 - smootherstep((np.abs(dx) - p["mouth_half_width"] * 0.66)
                               / (p["mouth_half_width"] * 0.34))
    across = np.exp(-(dz / p["mouth_groove_w"]) ** 2)
    facing = (N @ n) > 0.25
    depth = -p["mouth_depth"] * along * across * facing
    return P + depth[:, None] * n[None, :]


# -------------------------------------------------------------------- driver

def fix(co, tris, params=None, log=None):
    p = dict(PARAMS)
    if params:
        p.update(params)
    log = {} if log is None else log

    inv, P = weld(co)
    gt = group_tris(tris, inv)
    edges = tri_edges(gt)
    comp = components(len(P), edges)
    sizes = np.unique(comp, return_counts=True)
    log["groups"] = int(len(P))
    log["shells"] = sorted(int(s) for s in sizes[1])

    # a T-junction left by local subdivision shows up here as an extra one-sided
    # edge, and turns into an open crack the moment the carve moves anything
    half = np.sort(np.concatenate(
        [gt[:, [0, 1]], gt[:, [1, 2]], gt[:, [2, 0]]]), axis=1)
    _, used = np.unique(half, axis=0, return_counts=True)
    log["edges_one_sided"] = int((used == 1).sum())
    log["edges_over_shared"] = int((used > 2).sum())

    C0 = np.array(p["pore_centre"]) * np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    lens = comp == comp[np.argmin(np.linalg.norm(apply_scale(P, p) - C0, axis=1))]
    log["lens_shell"] = int(lens.sum())

    ids, counts = np.unique(comp, return_counts=True)
    body = comp == ids[np.argmax(counts)]
    log["body_shell"] = int(body.sum())

    P = apply_scale(P, p)
    P = symmetrize(P, gt, comp, p)

    base = taubin(P, edges, p["taubin_iters"])
    scale = np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    P = flatten_region(P, base, np.array(p["nose_centre"]) * scale,
                       p["nose_radii"], p["nose_strength"])
    polish = taubin(P, edges, p["mouth_polish_iters"])
    P = flatten_region(P, polish, np.array(p["mouth_centre"]) * scale,
                       p["mouth_radii"], p["mouth_polish"])
    P = pinch_mouth(P, p, log)
    if p["mouth_depth"] > 0.0:
        P = carve_mouth(P, gt, p)
    P = carve_pore(P, gt, lens, p, log)

    # Silhouette last, deliberately. Every head-mark fit — the pore's quadric,
    # the mouth frame, the nose flatten — is written in the coordinates the
    # carve sees, so reshaping the limbs afterwards cannot move a fit out from
    # under a carve. The limb field is zero everywhere near the face anyway,
    # but ordering it this way means that is a guarantee rather than a hope.
    pre = P.copy()
    P = shape_radial(P, body, p, log)
    P = flare_limbs(P, gt, body, p, log)
    strain(pre, P, edges, log)

    # One more pass over the brow. flatten_region only takes a fraction of the
    # residual at a time, and the radial profile leaves a little more of it
    # behind than the first pass was tuned for, so a second one gets the bump
    # from 0.009 back to 0.008. It touches 22 vertices, none near the pore or
    # the eyes.
    again = taubin(P, edges, p["taubin_iters"])
    P = flatten_region(P, again, np.array(p["nose_centre"]) * scale,
                       p["nose_radii"], p["nose_strength"])

    lo, hi = P.min(axis=0), P.max(axis=0)
    P[:, 2] -= lo[2]
    log["size"] = (hi - lo).round(4).tolist()
    log["wh_ratio"] = round(float((hi[0] - lo[0]) / (hi[2] - lo[2])), 4)
    return P[inv], log


def welded_normals(co, tris):
    """Vertex normals computed across UV seams.

    The GLB splits vertices along seams, so per-vertex normals computed on the
    split mesh disagree either side of a seam and shade as a visible line. The
    original asset hid that with baked split normals, which stop being true once
    the vertices move.
    """
    inv, P = weld(co)
    gt = group_tris(tris, inv)
    n = vertex_normals(P, gt)
    return n[inv]
