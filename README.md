# AILI Automatic Image Quality Evaluation (RGB Metrics)

This MATLAB script automatically evaluates **image super-resolution results** using **RGB-based quality metrics** —  
**PSNR**, **SSIM**, and **FSIM** — across multiple upscaling factors (**×2**, **×3**, **×4**).  
It compares low-resolution (LR) images processed by your `AILI_pipeline` with high-resolution ground-truth (GT) images,  
and outputs quantitative results to CSV files for easy analysis.

All metrics are calculated **directly on RGB images** (no grayscale conversion).

---

##  Dataset Folder Structure

The dataset folder should follow this structure (example: `Set14`):

```
Classical/
└── Set14/
    ├── GTmod12/       ← Ground-truth high-resolution images
    ├── LRbicx2/       ← Low-resolution images for ×2 scaling
    ├── LRbicx3/       ← Low-resolution images for ×3 scaling
    └── LRbicx4/       ← Low-resolution images for ×4 scaling
```

Each subfolder must contain images with **identical filenames**, for example:

```
GTmod12/baboon.png
LRbicx2/baboon.png
LRbicx3/baboon.png
LRbicx4/baboon.png
```

---

## Required Files

Ensure the following MATLAB functions are available in your workspace path:

| File | Description |
|------|--------------|
| `AILI_pipeline.m` | The main AILI interpolation or super-resolution algorithm |
| `PSNRcalc.m` | Computes RGB Peak Signal-to-Noise Ratio |
| `SSIMcalc.m` | Computes RGB Structural Similarity Index |
| `FSIMcalc.m` | Computes RGB Feature Similarity Index (supports color) |

---

## How to Use

1. Open MATLAB -> AILI_Quality_Metrics_AUTO.m 
2. Set your dataset directory path in the script:
   ```matlab
   baseDir = 'C:\Image_Super_Resolution_dataset\Classical\Set14';
   ```
   For the Set5 dataset, simply modify:
   ```matlab
   baseDir = 'C:\Image_Super_Resolution_dataset\Classical\Set5';
   ```
3. Run the script.

The program will:
- Automatically find matching GT and LR images for each scale.  
- Use `AILI_pipeline` to upsample each LR image to the GT size.  
- Compute **PSNR**, **SSIM**, and **FSIM** (all in RGB).  
- Export both per-image and mean results to `.csv` files.

---

## Output Files

| File Name | Description |
|------------|--------------|
| **metrics_per_image.csv** | PSNR, SSIM, and FSIM results for each image and scale. |
| **metrics_summary.csv**   | Mean results of each metric grouped by scale. |

### Example: `metrics_per_image.csv`

| image  | scale | psnr  | ssim  | fsim  |
|--------|-------|-------|-------|-------|
| baboon | 2 | 26.42 | 0.791 | 0.893 |
| baboon | 3 | 24.13 | 0.743 | 0.856 |
| baboon | 4 | 22.58 | 0.701 | 0.823 |

### Example: `metrics_summary.csv`

| image | scale | psnr_mean | ssim_mean | fsim_mean |
|--------|-------|------------|------------|------------|
| [MEAN] | 2 | 28.74 | 0.812 | 0.901 |
| [MEAN] | 3 | 26.02 | 0.765 | 0.870 |
| [MEAN] | 4 | 23.81 | 0.721 | 0.836 |

---

## Metric Overview

| Metric | Full Name | Description | Range |
|---------|------------|-------------|--------|
| **PSNR** | Peak Signal-to-Noise Ratio | Measures pixel-level reconstruction accuracy (higher = better). | 0 – ∞ |
| **SSIM** | Structural Similarity Index | Evaluates structural similarity, contrast, and luminance. | 0 – 1 |
| **FSIM** | Feature Similarity Index | Based on phase congruency and gradient magnitude for perceptual similarity. | 0 – 1 |

---

## Processing Workflow

1. **Image Matching**  
   Finds corresponding GT and LR images by filename.

2. **Upscaling**  
   Calls `AILI_pipeline(input_img, newH, newW)` to generate the upscaled image.

3. **Metric Computation**  
   Evaluates PSNR, SSIM, and FSIM using RGB data directly.

4. **Result Aggregation**  
   Generates per-image and averaged CSV reports.

---

## Notes

- Grayscale images will be automatically expanded to 3 channels to match RGB format.  
- If the AILI output size differs from the GT size, bicubic resizing will be applied automatically.  
- Missing or unmatched files will be skipped with a warning message.  
- The script supports **Set5**, **Set14**, or any dataset with a similar folder naming convention.

---


