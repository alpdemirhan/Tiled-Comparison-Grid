# Tiled Comparison Grid

An ImageJ/Fiji macro that tiles a folder of microscopy images into one labelled
hyperstack, grouped into rows by genotype and animal, so a whole experiment can be
looked at in a single window instead of opened one file at a time.

Channels and z stay live. The grid is a hyperstack, not a flattened picture, so one
z slider scrolls every tile together and the Channels tool still toggles markers on and
off across the whole sheet.

## Why

Comparing twenty sections by opening twenty windows does not work: you cannot hold two
images side by side in memory, and anything systematic — one animal darker than the
rest, one condition with smaller canals, a channel that failed on half a session —
hides in the sequence. Laid out in a grid with WT above KO, that kind of pattern is
visible at a glance.

It is a viewing tool. It measures nothing and writes no numbers.

## Requirements

- Fiji, or ImageJ with Bio-Formats
- Enough RAM for the grid (it estimates the size first and asks before building
  anything large)

## Use

Open `10_Tiled_Comparison_Grid.ijm` in Fiji and press Run, or
**Plugins → Macros → Run…**

Point it at a folder, choose how to group the rows, press OK.

## Options

### Files

| Field | What it does |
|---|---|
| Image folder | Searched recursively, so a folder of per-animal subfolders is fine |
| File extensions | Comma separated. Default `.tif, .lsm, .czi` |
| Skip names containing | Leaves out derived files — `_Projected` by default |
| Keyword that splits the two sets | A word in the file or folder name, e.g. `SGN` |
| Also require the name to contain | A second filter, applied to everything |
| Window / save name | Title of the result, and the TIFF name if saved |

### Layout

**Which images** — all of them, only names with the keyword, or only names without it.

**One row per** — genotype; genotype + animal; genotype + keyword; animal; keyword;
all three; or no grouping at all, in which case tiles flow into a fixed number of
columns.

**Row order** takes a list like `WT, KO` and puts those groups first, in that order.
**Column order** does the same within a row, matching on the file *or* folder name.
Anything unlisted follows in natural sort order, so `2` comes before `10`.

Rows are padded so the columns line up even when one animal has fewer sections than
another — a tile missing from the middle of a row is itself informative.

### Zoom and crop

- **whole image**
- **centred crop** — the same box on every image, set by crop width and height
  (0 = chosen automatically)
- **crop around each image's saved ROI** — reads the `.roi` beside each image, matched
  by a name fragment (`RC_boundary` by default), and crops to it plus a margin

The ROI crop is the one to use for canal comparisons: it centres each tile on the
structure rather than on the field of view, so differences in where the section was
photographed stop mattering.

### Z and channels

Keep the z-stack, or flatten each tile to a max projection first. Keeping it costs
memory but lets one slider move every tile through depth together.

Channel LUTs are applied in channel order — `Blue, Green, Red, Gray` by default — and
the Channels tool can be opened with the result so markers can be toggled while you
look.

### Labels

Each tile can be labelled with the full file name, the name without its extension,
everything after the animal number, or the first two words. Colour and font size are
set in the dialog. Tiles can also be outlined, which helps when adjacent images have
similar backgrounds.

## Output

A hyperstack window named after **Window / save name**, optionally saved as a TIFF
beside the images. The log records the grid dimensions, the estimated memory, and the
saved path.

Before building, the macro estimates the size of the combined hyperstack and, when it
is large, states the figure and asks whether to go ahead. Tick **Build it anyway** to
proceed. Scaling each image down (default `0.5`) or flattening z are the two settings
that move that number most.

## Limits worth knowing

- **It is a viewer.** Nothing is measured, nothing is written except the optional TIFF.
- **Memory is the real constraint.** Twenty 4-channel z-stacks at full size will not
  fit; scale down, crop, or flatten z. The estimate is shown for that reason.
- **Grouping is read from file and folder names**, so it is only as good as the naming.
  Genotype is found from a `WT`/`KO`/`HET` token, the animal from the digits near it.
- **Tiles are display-scaled.** Do not measure off the grid — go back to the original
  images for that.
- **Brightness is per tile**, set by each image's own display range. Two tiles that
  look different may only be contrasted differently. For honest visual comparison of
  intensity, set one display range across the images first.

## Part of a larger toolbox

This is tool 10 of the SGN toolbox, split out to run on its own. It needs no other file
from that toolbox. The all-in-one version adds a `.xlsx` export and an HTML guide, which
are shared across tools and so are not included here.
