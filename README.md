<h1 align="center">Particle Filtering Tractography (PFT)</h1>

<p align="center">
  Generates a whole-brain tractogram with particle filtering tractography (PFT, Girard et al. 2014) in DIPY from fODF spherical harmonics and a 5-tissue-type map, with probabilistic or deterministic tracking.
</p>

<p align="center">
  <a href="https://github.com/brainlife/abcd-spec"><img src="https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg" alt="ABCD Spec v1.1"></a>
  <a href="https://doi.org/10.25663/brainlife.app.984"><img src="https://img.shields.io/badge/Brainlife-brainlife.app.984-blue.svg" alt="Run on brainlife.io"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-see_LICENSE-lightgrey.svg" alt="License"></a>
</p>

## At a glance

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

> **Generates a whole-brain tractogram with particle filtering tractography (PFT, Girard et al. 2014) in DIPY from fODF spherical harmonics and a 5-tissue-type map, with probabilistic or deterministic tracking.**

Builds include (cortical plus subcortical GM) and exclude (CSF) maps from the 5TT image and seeds in white matter (or a given seed mask), then tracks with DIPY ParticleFilteringTracking and an ACT stopping criterion, using the chosen step, angle, thresholds and particle settings, and saves a .tck file. The README describes scilpy in the scilus container, but main runs run_pft.py with DIPY in gamorosino/pft-dipy:1.0. fODFs are expected as SH order 8 in the descoteaux07 basis unless sh_basis says otherwise.

| | |
|---|---|
| **Inputs** | `neuro/csd` · `neuro/mask` · `neuro/mask` (optional) |
| **Outputs** | `neuro/track/tck` |
| **Container** | `gamorosino/pft-dipy:1.0` |
| **Resources** | 8 CPUs · 32 GB memory · 4 h walltime |
| **Run it** | [doi.org/10.25663/brainlife.app.984](https://doi.org/10.25663/brainlife.app.984) |

#### Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `fodf` | `neuro/csd` | yes | Fibre orientation distribution (spherical harmonics) volume. SH basis must match sh_basis (descoteaux07 by default). |
| `mask_5tt` | `neuro/mask` (5tt) | yes | 5-tissue-type probability map in the fODF space. Volume order: cortical GM, subcortical GM, WM, CSF, pathological tissue. |
| `seed_mask` | `neuro/mask` | no | Optional seeding mask; white matter from the 5TT map is used if omitted. |

#### Outputs

| Output | Datatype | Description |
|---|---|---|
| `tractogram` | `neuro/track/tck` | Whole-brain tractogram produced by Particle Filtering Tractography. |

<details>
<summary><b>Parameters</b> (16)</summary>

| Parameter | Type | Default | Description |
|---|---|---|---|
| `algo` | string | `prob` | Tracking algorithm: 'prob' (probabilistic) or 'det' (deterministic). |
| `seeding_type` | string | `npv` | Seeding strategy: 'npv' (seeds per voxel) or 'nt' (total seeds). |
| `nbr_seeds` | number | `10` | Number of seeds (per voxel when seeding_type=npv, total when seeding_type=nt). |
| `step` | number | `0.5` | Step size in mm. |
| `theta` | number | `20` | Maximum angle between consecutive steps (degrees). |
| `sfthres` | number | `0.1` | Spherical function threshold for tractography. |
| `sfthres_init` | number | `0.5` | Spherical function threshold for seeding initialization. |
| `min_length` | number | `20` | Minimum streamline length in mm. |
| `max_length` | number | `200` | Maximum streamline length in mm. |
| `particles` | number | `15` | Number of PFT particles for back-tracking. |
| `back_tracking` | number | `2` | Back-tracking steps when a streamline enters an excluded region. |
| `forward_tracking` | number | `1` | Forward-tracking steps after PFT back-tracking. |
| `compress` | boolean | `true` | Compress output streamlines to reduce file size. |
| `compress_value` | number | `0.2` | Maximum compression error in mm (used when compress=true). |
| `random_seed` | number | `0` | Random seed for reproducibility. |
| `sh_basis` | string | `descoteaux07` | Spherical harmonics basis: 'descoteaux07' or 'tournier07'. |

</details>

<!-- brainlife-app:end -->

## Running the App

### On brainlife.io

Open the App at [doi.org/10.25663/brainlife.app.984](https://doi.org/10.25663/brainlife.app.984), choose `neuro/csd`, `neuro/mask`, `neuro/mask` from your project, set the parameters and press **Execute**. The results are saved to your project as `neuro/track/tck`.

### Locally

You need [Singularity/Apptainer](https://apptainer.org/) (the App runs in `gamorosino/pft-dipy:1.0`), [`jq`](https://jqlang.github.io/jq/).

1. Clone this repository.
2. Create `config.json` with the paths to your inputs and the parameters:

   ```json
   {
       "fodf": "/path/to/fodf/fodf",
       "mask_5tt": "/path/to/mask_5tt/mask_5tt",
       "seed_mask": "/path/to/seed_mask/seed_mask",
       "algo": "prob",
       "seeding_type": "npv",
       "nbr_seeds": 10,
       "step": 0.5,
       "theta": 20,
       "sfthres": 0.1,
       "sfthres_init": 0.5,
       "min_length": 20,
       "max_length": 200,
       "particles": 15,
       "back_tracking": 2,
       "forward_tracking": 1,
       "compress": true,
       "compress_value": 0.2,
       "random_seed": 0,
       "sh_basis": "descoteaux07"
   }
   ```

3. Run `./main`.

## 5TT volume ordering

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

## Citing

If you use this App, please cite it, the software it builds on and brainlife.io:

- Particle Filtering Tractography (PFT). brainlife.io App. [doi:10.25663/brainlife.app.984](https://doi.org/10.25663/brainlife.app.984)
- Girard G, Whittingstall K, Deriche R, Descoteaux M. Towards quantitative connectivity analysis: reducing tractography biases. NeuroImage 98:266-278 (2014).
- Girard G, Whittingstall K, Deriche R, Descoteaux M. (2014). *Towards quantitative connectivity analysis: reducing tractography biases.* NeuroImage, 98, 266–278. https://doi.org/10.1016/j.neuroimage.2014.04.074
- Côté M-A, et al. (2013). *Tractometer: towards validation of tractography pipelines.* Medical Image Analysis, 17(7), 844–857.
- [scilpy](https://github.com/scilus/scilpy) — Sherbrooke Connectivity Imaging Lab
- Inspired by [tractoinferno_tracking_flow](https://github.com/ppoulin91/tractoinferno_tracking_flow)
- Garyfallidis et al. Dipy, a library for the analysis of diffusion MRI data. *Frontiers in Neuroinformatics* 8 (2014). [doi:10.3389/fninf.2014.00008](https://doi.org/10.3389/fninf.2014.00008)
- Hayashi S, Caron BA, Heinsfeld AS, et al. brainlife.io: a decentralized and open-source cloud platform to support neuroscience research. *Nature Methods* 21:809–813 (2024). [doi:10.1038/s41592-024-02237-2](https://doi.org/10.1038/s41592-024-02237-2)
- Avesani P, McPherson B, Hayashi S, et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. *Scientific Data* 6:69 (2019). [doi:10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

## Authors

Maintained by [@gamorosino](https://github.com/gamorosino).

## License

See [LICENSE](LICENSE).
