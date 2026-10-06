# app-particle-filtering-tractography

Brainlife.io app for **Particle Filtering Tractography (PFT)** using
[scilpy](https://github.com/scilus/scilpy)'s `scil_tracking_pft.py`, run
inside the `scilus/scilus:1.6.0` Singularity container.

PFT extends standard streamline tractography by spawning multiple particles
when a streamline enters an excluded region (e.g. CSF).  This lets
streamlines recover and reach grey matter targets rather than being
prematurely terminated, substantially increasing anatomical plausibility at
the GM/WM interface.

## Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `fodf` | `neuro/csd` | yes | FODF volume (SH order 8, descoteaux07 basis) |
| `mask_5tt` | `neuro/mask` (tag: `5tt`) | yes | 5-tissue-type probability map |
| `seed_mask` | `neuro/mask` | no | Seeding mask override; WM (vol2 of 5TT) is used if omitted |

### 5TT volume ordering

The app follows the standard brainlife `neuro/mask 5tt` ordering:

| Volume | Tissue |
|---|---|
| 0 | Cortical GM |
| 1 | Subcortical GM |
| 2 | WM / brainstem |
| 3 | CSF / ventricles |
| 4 | Pathological tissue |

- **map\_include** = vol0 + vol1 (all GM probability, clamped to [0, 1])
- **map\_exclude** = vol3 (CSF probability)
- **seed\_mask** = binarize(vol2) (WM mask, unless overridden)

## Output

| Output | Datatype | Description |
|---|---|---|
| `tractogram` | `neuro/track/tck` | Whole-brain tractogram (`tractogram/track.tck`) |

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `algo` | `prob` | Tracking algorithm: `prob` or `det` |
| `seeding_type` | `npv` | `npv` (seeds per voxel) or `nt` (total seeds) |
| `nbr_seeds` | `10` | Number of seeds |
| `step` | `0.5` | Step size (mm) |
| `theta` | `20` | Max angle between steps (degrees) |
| `sfthres` | `0.1` | Spherical function threshold |
| `sfthres_init` | `0.5` | SF threshold for seeding initialization |
| `min_length` | `20` | Minimum streamline length (mm) |
| `max_length` | `200` | Maximum streamline length (mm) |
| `particles` | `15` | PFT particle count |
| `back_tracking` | `2` | Back-tracking steps |
| `forward_tracking` | `1` | Forward-tracking steps |
| `compress` | `true` | Compress output streamlines |
| `compress_value` | `0.2` | Compression error threshold (mm) |
| `random_seed` | `0` | Random seed for reproducibility |
| `sh_basis` | `descoteaux07` | SH basis (`descoteaux07` or `tournier07`) |

## Local usage

```bash
./main_cli.sh \
    --fodf /data/subject/neuro/csd/lmax8.nii.gz \
    --mask_5tt /data/subject/neuro/mask/mask.nii.gz

# With output dir and custom parameters:
./main_cli.sh \
    --fodf /data/subject/neuro/csd/lmax8.nii.gz \
    --mask_5tt /data/subject/neuro/mask/mask.nii.gz \
    --algo prob \
    --nbr_seeds 10 \
    --output_dir /data/subject/results/pft
```

## References

- Girard G, Whittingstall K, Deriche R, Descoteaux M. (2014).
  *Towards quantitative connectivity analysis: reducing tractography biases.*
  NeuroImage, 98, 266–278. https://doi.org/10.1016/j.neuroimage.2014.04.074
- Côté M-A, et al. (2013). *Tractometer: towards validation of tractography pipelines.*
  Medical Image Analysis, 17(7), 844–857.
- [scilpy](https://github.com/scilus/scilpy) — Sherbrooke Connectivity Imaging Lab
- Inspired by [tractoinferno_tracking_flow](https://github.com/ppoulin91/tractoinferno_tracking_flow)
