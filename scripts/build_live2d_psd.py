#!/usr/bin/env python3
"""Build a deterministic, minimally layered Cubism PSD from the neutral PNG.

The approved character pixels remain the source of truth. The script only
reconstructs skin underneath facial features, then places the original feature
pixels on separate transparent layers. The composite therefore matches the
input while exposing enough structure for a first blink/mouth/breath rig.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parents[1] / "PrivateAssets/Tools/python-packages"
if TOOL_ROOT.exists():
    sys.path.insert(0, str(TOOL_ROOT))

import numpy as np
from PIL import Image, ImageChops, ImageDraw


@dataclass(frozen=True)
class Feature:
    name: str
    points: tuple[tuple[int, int], ...]


FEATURES = (
    Feature("eyebrow_left", ((412, 419), (429, 398), (456, 393), (478, 420), (458, 411), (432, 411))),
    Feature("eyebrow_right", ((551, 420), (570, 394), (599, 397), (620, 420), (599, 411), (573, 411))),
    Feature("eye_left", ((383, 468), (394, 443), (419, 428), (455, 427), (486, 441), (500, 465), (494, 491), (475, 512), (446, 524), (416, 514), (395, 495))),
    Feature("eye_right", ((529, 468), (541, 443), (566, 428), (603, 427), (633, 441), (648, 465), (641, 491), (622, 512), (593, 524), (562, 514), (541, 495))),
    Feature("mouth", ((485, 535), (497, 530), (510, 538), (522, 530), (540, 535), (526, 552), (509, 556), (493, 550))),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("PrivateAssets/Live2D/Source/phoebe-neutral-rig-v1.png"),
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("PrivateAssets/Live2D/RigLiteV1"),
    )
    return parser.parse_args()


def fit_skin_model(source: np.ndarray) -> np.ndarray:
    """Fit a smooth two-dimensional skin-colour surface over the face."""
    height, width, _ = source.shape
    yy, xx = np.mgrid[0:height, 0:width]
    face = ((xx - 515.0) / 137.0) ** 2 + ((yy - 493.0) / 106.0) ** 2 <= 1.0
    rgba = source.astype(np.float64)
    rgb = rgba[..., :3]
    alpha = rgba[..., 3]
    skin = (
        face
        & (alpha > 250)
        & (rgb[..., 0] > 205)
        & (rgb[..., 1] > 145)
        & (rgb[..., 2] > 135)
        & (rgb[..., 0] > rgb[..., 1] + 8)
        & (rgb[..., 1] > rgb[..., 2] - 8)
    )

    for feature in FEATURES:
        xs = [point[0] for point in feature.points]
        ys = [point[1] for point in feature.points]
        x0, y0, x1, y1 = min(xs), min(ys), max(xs) + 1, max(ys) + 1
        skin[y0:y1, x0:x1] = False

    sample_y, sample_x = np.nonzero(skin)
    if sample_x.size < 100:
        raise RuntimeError("Not enough clean skin pixels to reconstruct the face")

    xn = (sample_x - 515.0) / 140.0
    yn = (sample_y - 493.0) / 110.0
    design = np.column_stack(
        [
            np.ones_like(xn), xn, yn, xn * xn, xn * yn, yn * yn,
            xn * xn * yn, xn * yn * yn,
        ]
    )
    all_xn = (xx - 515.0) / 140.0
    all_yn = (yy - 493.0) / 110.0
    all_design = np.stack(
        [
            np.ones_like(all_xn), all_xn, all_yn, all_xn * all_xn,
            all_xn * all_yn, all_yn * all_yn, all_xn * all_xn * all_yn,
            all_xn * all_yn * all_yn,
        ],
        axis=-1,
    )

    predicted = np.empty((height, width, 3), dtype=np.float64)
    for channel in range(3):
        coefficients, *_ = np.linalg.lstsq(
            design, rgb[sample_y, sample_x, channel], rcond=None
        )
        predicted[..., channel] = all_design @ coefficients
    return np.clip(predicted, 0, 255).astype(np.uint8)


def feature_mask(source: np.ndarray, skin: np.ndarray, feature: Feature) -> Image.Image:
    del skin
    full = Image.new("L", (source.shape[1], source.shape[0]), 0)
    ImageDraw.Draw(full).polygon(feature.points, fill=255)
    source_alpha = Image.fromarray(source[..., 3], mode="L")
    full = ImageChops.multiply(full, source_alpha)
    return full


def make_layer(source_image: Image.Image, mask: Image.Image) -> Image.Image:
    layer = source_image.copy()
    layer.putalpha(mask)
    return layer


def write_psd(output: Path, base: Image.Image, layers: list[tuple[str, Image.Image]]) -> Image.Image:
    from psd_tools import PSDImage

    psd = PSDImage.new(mode="RGB", size=base.size, color=0, depth=8)
    psd.create_pixel_layer(base, name="body_base", top=0, left=0)
    face_group = psd.create_group(name="face_controls")
    for name, image in layers:
        bounds = image.getbbox()
        if bounds is None:
            continue
        left, top, right, bottom = bounds
        face_group.append(
            psd.create_pixel_layer(
                image.crop((left, top, right, bottom)), name=name, top=top, left=left
            )
        )
    psd.save(output)
    return PSDImage.open(output).composite().convert("RGBA")


def main() -> int:
    args = parse_args()
    source_image = Image.open(args.source).convert("RGBA")
    source = np.asarray(source_image)
    skin = fit_skin_model(source)
    masks = [(feature, feature_mask(source, skin, feature)) for feature in FEATURES]
    combined = Image.new("L", source_image.size, 0)
    for _, mask in masks:
        combined = ImageChops.lighter(combined, mask)

    base_array = source.copy()
    combined_array = np.asarray(combined) > 0
    base_array[combined_array, :3] = skin[combined_array]
    base_image = Image.fromarray(base_array, mode="RGBA")

    output_dir = args.output_dir
    layers_dir = output_dir / "layers"
    output_dir.mkdir(parents=True, exist_ok=True)
    layers_dir.mkdir(parents=True, exist_ok=True)
    base_image.save(layers_dir / "body_base.png")

    layer_images: list[tuple[str, Image.Image]] = []
    for feature, mask in masks:
        layer = make_layer(source_image, mask)
        layer.save(layers_dir / f"{feature.name}.png")
        layer_images.append((feature.name, layer))

    composite = base_image.copy()
    for _, layer in layer_images:
        composite.alpha_composite(layer)
    composite.save(output_dir / "phoebe-rig-lite-v1-composite.png")
    base_image.save(output_dir / "phoebe-rig-lite-v1-base-preview.png")

    difference = ImageChops.difference(source_image, composite)
    difference.save(output_dir / "phoebe-rig-lite-v1-difference.png")
    diff_array = np.asarray(difference).astype(np.float32)
    psd_path = output_dir / "phoebe-rig-lite-v1.psd"
    psd_roundtrip = write_psd(psd_path, base_image, layer_images)
    psd_roundtrip.save(output_dir / "phoebe-rig-lite-v1-psd-roundtrip.png")
    psd_difference = ImageChops.difference(source_image, psd_roundtrip)
    psd_diff_array = np.asarray(psd_difference).astype(np.float32)

    report = {
        "source": str(args.source),
        "canvas": list(source_image.size),
        "layers": ["body_base", *[feature.name for feature, _ in masks]],
        "meanAbsoluteError": float(np.mean(diff_array[..., :3])),
        "maxAbsoluteError": int(np.max(diff_array[..., :3])),
        "changedPixels": int(np.count_nonzero(np.any(diff_array[..., :3] != 0, axis=2))),
        "psdRoundtripMeanAbsoluteError": float(np.mean(psd_diff_array[..., :3])),
        "psdRoundtripMaxAbsoluteError": int(np.max(psd_diff_array[..., :3])),
        "psdRoundtripChangedPixels": int(
            np.count_nonzero(np.any(psd_diff_array[..., :3] != 0, axis=2))
        ),
        "note": "RigLiteV1 validates the face control path; production occlusion fills remain pending.",
    }
    (output_dir / "qa-report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
