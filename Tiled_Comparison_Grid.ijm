// ======================================================================
//  10. Tiled Comparison Grid
//  Standalone macro, split out of SGN_Toolbox_AllInOne.ijm
// ======================================================================
//
//  Tiles all samples into a single hyperstack for synchronized 
//  Z-slider and channel inspection.
//
//  Needs : Images or projections
//  Makes : Tiled hyperstack
//
//  To run: open in Fiji and press Run, or Plugins > Macros > Run...
//  Self-contained - nothing else from the toolbox is needed.
//  The .xlsx export and the shared HTML guide live only in the
//  all-in-one toolbox; this file writes its CSVs and ROIs directly.
// ======================================================================

var cg_imgPaths = newArray(0);
var cg_extList  = newArray(".tif", ".lsm", ".czi");
var cg_root     = "";
var cg_ROW_GENOANIM = "genotype + animal   (WT 2673)";
var cg_ROW_ANIMAL   = "animal only   (2673)";
var cg_ROW_GENO     = "genotype only   (WT)";
var cg_ROW_GENOKEY  = "genotype + keyword   (WT SGN / WT other)";
var cg_ROW_KEY      = "keyword vs not   (SGN / other)";
var cg_ROW_ALL3     = "genotype + animal + keyword";
var cg_ROW_NONE     = "no grouping - fixed columns";
var cg_CROP_NONE = "whole image";
var cg_CROP_MID  = "centred crop (same box on every image)";
var cg_CROP_ROI  = "crop around each image's saved ROI";
var cg_PICK_ALL   = "all images";
var cg_PICK_KEY   = "only names WITH the keyword";
var cg_PICK_NOKEY = "only names WITHOUT the keyword";


cg_run();


function cg_run() {
// =========================================================================
//  Side-by-side comparison grid - one hyperstack, all samples
// =========================================================================
//  Opens every image in a folder and tiles them into a SINGLE hyperstack,
//  so that:
//      - you see all samples side by side
//      - ONE z-slider scrolls every sample together
//      - the Channels tool (merge / composite / LUTs) applies to them ALL
//      - brightness and contrast are identical across samples
//  Each tile is labelled with its file name.
//
//  Because it is one image, anything you do to channels or contrast is
//  applied identically everywhere - which is what makes the comparison
//  honest. The cost is that you cannot set a different contrast per
//  sample; if you need that, open them separately instead.
//
//  Layout options:
//      - fixed number of columns
//      - one row per group, taken from the first word of the file name
//        (so "WT 2673 ..." and "KO 2679 ..." land on their own rows)
// =========================================================================





// These MUST be declared with var: ImageJ macro functions can only see
// globals declared this way. As plain assignments they were invisible
// inside rowLabel(), so every mode test silently failed.
















// -------------------------------------------------------------------------
//  1 - settings
// -------------------------------------------------------------------------
Dialog.create("Side-by-side comparison grid");
Dialog.setLocation(20, 20);   // keep OK on screen
Dialog.addDirectory("Image folder", "");                                // str 1

Dialog.addMessage("--- files ---");
Dialog.addString("File extensions (comma separated)", ".tif, .lsm, .czi");     // str 1
Dialog.addToSameRow();
Dialog.addString("Skip names containing",
    "_Projected, _Mask, _cleared, _montage");                            // str 2
Dialog.addString("Keyword that splits the two sets", "");               // str 3
Dialog.addToSameRow();
Dialog.addString("Also require the name to contain", "");                // str 4
Dialog.addString("Window / save name", "Comparison");                    // str 5

Dialog.addMessage("--- what to show and how to arrange it ---");
Dialog.addChoice("Which images", newArray(
    cg_PICK_ALL, cg_PICK_KEY, cg_PICK_NOKEY), cg_PICK_ALL);                          // cho 1
Dialog.addToSameRow();
Dialog.addChoice("One row per", newArray(
    cg_ROW_GENO, cg_ROW_GENOKEY, cg_ROW_GENOANIM, cg_ROW_ANIMAL, cg_ROW_KEY,
    cg_ROW_ALL3, cg_ROW_NONE),
    cg_ROW_GENO);                                                           // cho 2
Dialog.addString("Row order (these first, in this order)", "WT, KO");    // str 6
Dialog.addToSameRow();
Dialog.addString("Column order (matches file OR folder name)", "");      // str 7
Dialog.addNumber("Columns (only if no grouping)", 4);                    // num 1
Dialog.addToSameRow();
Dialog.addNumber("Scale each image by", 0.5);                            // num 2
Dialog.addToSameRow();
Dialog.addNumber("Gap between tiles (px)", 6);                           // num 3

Dialog.addMessage("--- zoom / crop ---");
Dialog.addChoice("Region to show", newArray(
    cg_CROP_NONE, cg_CROP_MID, cg_CROP_ROI), cg_CROP_NONE);                          // cho 3
Dialog.addNumber("Crop width (px, 0 = auto)", 0);                        // num 4
Dialog.addToSameRow();
Dialog.addNumber("Crop height (px, 0 = auto)", 0);                       // num 5
Dialog.addString("ROI file name contains", "RC_boundary");               // str 8
Dialog.addToSameRow();
Dialog.addNumber("Margin around the ROI (px)", 30);                      // num 6

Dialog.addMessage("--- z ---");
Dialog.addChoice("Z handling", newArray(
    "keep the z-stack (one slider for all)",
    "max projection (flatten)"),
    "keep the z-stack (one slider for all)");                            // cho 4

Dialog.addMessage("--- labels ---");
Dialog.addChoice("Tile label", newArray(
    "full file name", "name without extension",
    "everything after the animal number", "first two words"),
    "name without extension");                                           // cho 5
Dialog.addToSameRow();
Dialog.addChoice("Label colour", newArray(
    "white", "yellow", "cyan", "black", "red"), "white");                // cho 6
Dialog.addToSameRow();
Dialog.addNumber("Label font size", 16);                                 // num 7

Dialog.addMessage("--- channel colours (in channel order) ---");
Dialog.addString("Channel LUTs",
    "Blue, Green, Red, Grays, Cyan, Magenta, Yellow");                   // str 9

Dialog.addCheckbox("Open the Channels tool when done", true);            // chk 1
Dialog.addToSameRow();
Dialog.addCheckbox("Outline each tile", true);                           // chk 2
Dialog.addToSameRow();
Dialog.addCheckbox("Save the result as TIFF", false);                    // chk 3
Dialog.show();

cg_root    = Dialog.getString();    // str 1
if (cg_root == "" || !File.exists(cg_root)) { showMessage("Pick an image folder."); return; }
if (!endsWith(cg_root, File.separator)) cg_root = cg_root + File.separator;
extText    = Dialog.getString();    // str 2
skipText   = Dialog.getString();    // str 2
keyword    = Dialog.getString();    // str 3
nameFilt   = Dialog.getString();    // str 4
outName    = Dialog.getString();    // str 5
rowOrderTxt= Dialog.getString();    // str 6
colOrderTxt= Dialog.getString();    // str 7
cropRoiTxt = Dialog.getString();    // str 8
lutText    = Dialog.getString();    // str 9

nCols     = Dialog.getNumber();     // num 1
scale     = Dialog.getNumber();     // num 2
gap       = Dialog.getNumber();     // num 3
cropW     = Dialog.getNumber();     // num 4
cropH     = Dialog.getNumber();     // num 5
roiMargin = Dialog.getNumber();     // num 6
fontSize  = Dialog.getNumber();     // num 7

whichSet  = Dialog.getChoice();     // cho 1
rowMode   = Dialog.getChoice();     // cho 2
cropMode  = Dialog.getChoice();     // cho 3
zMode     = Dialog.getChoice();     // cho 4
labelMode = Dialog.getChoice();     // cho 5
labelCol  = Dialog.getChoice();     // cho 6

openChan  = Dialog.getCheckbox();   // chk 1
drawGrid  = Dialog.getCheckbox();   // chk 2
saveTif   = Dialog.getCheckbox();   // chk 3

if (scale <= 0) scale = 1;
if (nCols < 1)  nCols = 1;
if (gap   < 0)  gap   = 0;

doCrop  = (cropMode != cg_CROP_NONE);
byGroup = (rowMode != cg_ROW_NONE);
flatten = (zMode == "max projection (flatten)");

// extension list
parts = split(extText, ",");
cg_extList = newArray(0);
for (e = 0; e < parts.length; e++) {
    t = toLowerCase(String.trim(parts[e]));
    if (t == "") continue;
    if (!startsWith(t, ".")) t = "." + t;
    cg_extList = Array.concat(cg_extList, t);
}
if (cg_extList.length == 0) cg_extList = newArray(".tif", ".lsm", ".czi");

// names to skip - derived files like *_C2_Projected.tif live beside the
// originals, and with .tif enabled they would otherwise be picked up
skipParts = split(skipText, ",");
skipList = newArray(0);
for (e = 0; e < skipParts.length; e++) {
    t = String.trim(skipParts[e]);
    if (t != "") skipList = Array.concat(skipList, toLowerCase(t));
}

// -------------------------------------------------------------------------
//  2 - collect and sort the files
// -------------------------------------------------------------------------
print("\\Clear");
print("=== Side-by-side comparison grid ===");
print("Folder  : " + cg_root);
print("Keyword : " + keyword);
print("Showing : " + whichSet);
print("Rows    : " + rowMode);

cg_imgPaths = newArray(0);
cg_scanDir(cg_root);

keep = newArray(0);
nSkipped = 0;
for (i = 0; i < cg_imgPaths.length; i++) {
    nm = File.getName(cg_imgPaths[i]);
    hasKey = false;
    if (keyword != "")
        hasKey = (indexOf(toUpperCase(nm), toUpperCase(keyword)) >= 0);

    if (whichSet == cg_PICK_KEY   && !hasKey) continue;
    if (whichSet == cg_PICK_NOKEY &&  hasKey) continue;
    if (nameFilt != "" &&
        indexOf(toLowerCase(nm), toLowerCase(nameFilt)) < 0) continue;

    skipIt = false;
    for (e = 0; e < skipList.length; e++)
        if (indexOf(toLowerCase(nm), skipList[e]) >= 0) { skipIt = true; break; }
    if (skipIt) { nSkipped++; continue; }

    keep = Array.concat(keep, cg_imgPaths[i]);
}
cg_imgPaths = keep;

n = cg_imgPaths.length;
print("Matched " + n + " image(s).");
if (nSkipped > 0) print("Skipped " + nSkipped + " by the skip list.");
if (n == 0) exit("No images matched.\nCheck the keyword, the filter and the extension.");

// natural sort, so 2 comes before 10 and genotypes group together
keys = newArray(n);
for (i = 0; i < n; i++) {
    k = cg_natKey(File.getName(cg_imgPaths[i]));
    keys[i] = k + "\t" + cg_imgPaths[i];
}
Array.sort(keys);
for (i = 0; i < n; i++) {
    f = split(keys[i], "\t");
    cg_imgPaths[i] = f[1];
}

// -------------------------------------------------------------------------
//  3 - inspect every image first (sizes, channels, slices, bit depth)
// -------------------------------------------------------------------------
setBatchMode(true);

maxW = 0; maxH = 0; maxC = 0; maxZ = 0; bd = 0;
okPaths = newArray(0);
srcW = newArray(0); srcH = newArray(0);     // each image's own size
ctrX = newArray(0); ctrY = newArray(0);     // where to centre the crop
boxW = 0; boxH = 0;                          // biggest ROI bounding box seen
nNoRoi = 0;

for (i = 0; i < n; i++) {
    showProgress(i, n);
    run("Bio-Formats Importer",
        "open=[" + cg_imgPaths[i] + "] autoscale color_mode=Default " +
        "view=Hyperstack stack_order=XYCZT");
    if (nImages == 0) { print("  [fail] " + File.getName(cg_imgPaths[i])); continue; }
    getDimensions(w, h, c, z, t);
    if (w > maxW) maxW = w;
    if (h > maxH) maxH = h;
    if (c > maxC) maxC = c;
    if (flatten) z = 1;
    if (z > maxZ) maxZ = z;
    if (bitDepth() > bd) bd = bitDepth();

    cx = w / 2;  cy = h / 2;
    if (cropMode == cg_CROP_ROI) {
        rp = cg_findRoiFor(File.getParent(cg_imgPaths[i]) + File.separator,
                        cg_stripExt(File.getName(cg_imgPaths[i])), cropRoiTxt);
        if (rp != "") {
            run("Select None");
            open(rp);
            if (selectionType() >= 0) {
                getSelectionBounds(bx, by, bw, bh);
                cx = bx + bw / 2;
                cy = by + bh / 2;
                if (bw > boxW) boxW = bw;
                if (bh > boxH) boxH = bh;
            }
            run("Select None");
        } else {
            nNoRoi++;
            print("  [no ROI] " + File.getName(cg_imgPaths[i]) + " - using the centre");
        }
    }

    okPaths = Array.concat(okPaths, cg_imgPaths[i]);
    srcW = Array.concat(srcW, w);
    srcH = Array.concat(srcH, h);
    ctrX = Array.concat(ctrX, cx);
    ctrY = Array.concat(ctrY, cy);
    close("*");
}
cg_imgPaths = okPaths;
n = cg_imgPaths.length;
if (n == 0) { setBatchMode(false); exit("No images could be opened."); }

// ---- settle on ONE crop size, so every tile shows the same field of view ----
if (doCrop) {
    if (cropW <= 0) {
        if (cropMode == cg_CROP_ROI && boxW > 0) cropW = boxW + 2 * roiMargin;
        else                                  cropW = floor(maxW / 2);
    }
    if (cropH <= 0) {
        if (cropMode == cg_CROP_ROI && boxH > 0) cropH = boxH + 2 * roiMargin;
        else                                  cropH = floor(maxH / 2);
    }
    if (cropW > maxW) cropW = maxW;
    if (cropH > maxH) cropH = maxH;
    maxW = cropW;
    maxH = cropH;
    print("Crop      : " + cropW + " x " + cropH + " px from each image");
    if (cropMode == cg_CROP_ROI)
        print("            centred on '" + cropRoiTxt + "' ROIs"
              + "   (" + nNoRoi + " without one)");
}

tileW = floor(maxW * scale);
tileH = floor(maxH * scale);
if (tileW < 1) tileW = 1;
if (tileH < 1) tileH = 1;

// ---- work out the grid ----
groups  = newArray(0);     // one entry per row, when grouping
rowOf   = newArray(n);
colOf   = newArray(n);

if (byGroup) {
    for (i = 0; i < n; i++) {
        g = cg_rowLabel(File.getName(cg_imgPaths[i]), rowMode, keyword);
        r = cg_indexOfStr(groups, g);
        if (r < 0) { groups = Array.concat(groups, g); r = groups.length - 1; }
        rowOf[i] = r;
    }
    // column = running count within the row
    print("Row label from each file:");
    for (i = 0; i < n && i < 12; i++)
        print("   " + File.getName(cg_imgPaths[i]) + "   ->   '"
              + cg_rowLabel(File.getName(cg_imgPaths[i]), rowMode, keyword) + "'");
    if (n > 12) print("   ... and " + (n - 12) + " more");

    // put the preferred labels first, in the order the user listed them,
    // then everything else in the order it was found
    pref = split(rowOrderTxt, ",");
    newOrder = newArray(0);
    if (String.trim(rowOrderTxt) != "") print("Row order:");
    for (q = 0; q < pref.length; q++) {
        tk = String.trim(pref[q]);
        if (tk == "") continue;
        gotIt = 0;
        for (g = 0; g < groups.length; g++) {
            if (cg_indexOfNum(newOrder, g) >= 0) continue;
            if (cg_labelStartsWith(groups[g], tk)) {
                newOrder = Array.concat(newOrder, g);
                gotIt++;
            }
        }
        warn2 = "";
        if (gotIt == 0) warn2 = "   <-- no row has this label";
        print("   '" + tk + "'  " + gotIt + " row(s)" + warn2);
    }
    for (g = 0; g < groups.length; g++)
        if (cg_indexOfNum(newOrder, g) < 0) newOrder = Array.concat(newOrder, g);

    // old row index -> new row index
    remap = newArray(groups.length);
    for (q = 0; q < newOrder.length; q++) remap[newOrder[q]] = q;

    sorted = newArray(groups.length);
    for (q = 0; q < newOrder.length; q++) sorted[q] = groups[newOrder[q]];
    groups = sorted;
    for (i = 0; i < n; i++) rowOf[i] = remap[rowOf[i]];

    // columns: natural file order by default, but a preference list can
    // pull matching names to the front of their row
    colPref = split(colOrderTxt, ",");
    colHits  = newArray(colPref.length);
    colLoose = newArray(colPref.length);
    counts = newArray(groups.length);
    for (r = 0; r < groups.length; r++) {
        inRow = newArray(0);
        for (i = 0; i < n; i++) if (rowOf[i] == r) inRow = Array.concat(inRow, i);

        ordered = newArray(0);
        for (q = 0; q < colPref.length; q++) {
            tk = String.trim(colPref[q]);
            if (tk == "") continue;
            hit = 0;
            // pass 1: whole-word match, so "0.1" does NOT also pull in
            // "0.1-1.0". The path is relative to the chosen folder, so a
            // folder name counts as well as the file name.
            for (m = 0; m < inRow.length; m++) {
                idx = inRow[m];
                if (cg_indexOfNum(ordered, idx) >= 0) continue;
                relPath = substring(cg_imgPaths[idx], lengthOf(cg_root));
                if (cg_hasWord(relPath, tk)) {
                    ordered = Array.concat(ordered, idx);
                    hit++;
                }
            }
            // pass 2: nothing matched as a word, so fall back to substring
            if (hit == 0) {
                for (m = 0; m < inRow.length; m++) {
                    idx = inRow[m];
                    if (cg_indexOfNum(ordered, idx) >= 0) continue;
                    relPath = substring(cg_imgPaths[idx], lengthOf(cg_root));
                    if (indexOf(toUpperCase(relPath), toUpperCase(tk)) >= 0) {
                        ordered = Array.concat(ordered, idx);
                        hit++;
                    }
                }
                if (hit > 0) colLoose[q] = 1;
            }
            colHits[q] = colHits[q] + hit;
        }
        for (m = 0; m < inRow.length; m++)
            if (cg_indexOfNum(ordered, inRow[m]) < 0)
                ordered = Array.concat(ordered, inRow[m]);

        for (m = 0; m < ordered.length; m++) colOf[ordered[m]] = m;
        counts[r] = inRow.length;
    }
    gridRows = groups.length;
    gridCols = 0;
    for (r = 0; r < counts.length; r++) if (counts[r] > gridCols) gridCols = counts[r];
    if (colOrderTxt != "") {
        print("Column order:");
        for (q = 0; q < colPref.length; q++) {
            tk = String.trim(colPref[q]);
            if (tk == "") continue;
            warn = "";
            if (colHits[q] == 0) warn = "   <-- matched nothing";
            else if (colLoose[q] == 1) warn = "   (substring match)";
            print("   '" + tk + "'  " + colHits[q] + " tile(s)" + warn);
        }
    }
    print("Final row order (top to bottom):");
    for (r = 0; r < groups.length; r++)
        print("   " + (r + 1) + ". " + groups[r] + "   (" + counts[r] + " image(s))");
} else {
    // no rows, so the whole sequence is ordered. Whichever order field
    // the user filled in is used - column first, then row.
    seqPref = colOrderTxt;
    if (String.trim(seqPref) == "") seqPref = rowOrderTxt;

    all = newArray(0);
    for (i = 0; i < n; i++) all = Array.concat(all, i);
    if (String.trim(seqPref) != "") {
        print("Tile order (no grouping):");
        all = cg_prefOrder(all, seqPref);
    }

    gridCols = nCols;
    gridRows = floor((n + gridCols - 1) / gridCols);
    for (k = 0; k < all.length; k++) {
        i = all[k];
        rowOf[i] = floor(k / gridCols);
        colOf[i] = k % gridCols;
    }
}

rowLabW = 0;
if (byGroup) rowLabW = 110;          // left margin that holds the row name

labelBand = fontSize + 6;
cellW = tileW + gap;
cellH = tileH + labelBand + gap;
canW  = rowLabW + gridCols * cellW + gap;
canH  = gridRows * cellH + gap;

est = canW * canH * maxC * maxZ * (bd / 8) / 1024 / 1024;
print("Grid      : " + gridCols + " x " + gridRows
      + "   tile " + tileW + " x " + tileH);
print("Hyperstack: " + canW + " x " + canH
      + "   C=" + maxC + "  Z=" + maxZ + "  " + bd + "-bit");
print("Estimated memory: " + d2s(est, 0) + " MB");

if (est > 2000) {
    setBatchMode(false);
    Dialog.create("That is a big image");
    Dialog.addMessage("The combined hyperstack would be about "
        + d2s(est, 0) + " MB.\n \n"
        + "Fiji may run out of memory. Reduce the scale factor,\n"
        + "use the max projection option, or filter to fewer files.");
    Dialog.addCheckbox("Build it anyway", false);
    Dialog.show();
    if (!Dialog.getCheckbox()) exit("Cancelled - try a smaller scale.");
    setBatchMode(true);
}

// -------------------------------------------------------------------------
//  4 - build the canvas and drop each image into it
// -------------------------------------------------------------------------
depthStr = "" + bd + "-bit";
if (bd == 24) depthStr = "RGB";
newImage("GRID", depthStr + " black", canW, canH, maxC, maxZ, 1);
grid = getImageID();

labels   = newArray(n);
labelX   = newArray(n);
labelY   = newArray(n);

for (i = 0; i < n; i++) {
    showProgress(i, n);
    name = File.getName(cg_imgPaths[i]);

    run("Bio-Formats Importer",
        "open=[" + cg_imgPaths[i] + "] autoscale color_mode=Default " +
        "view=Hyperstack stack_order=XYCZT");
    src = getTitle();
    getDimensions(w, h, c, z, t);

    if (flatten && z > 1) {
        run("Z Project...", "projection=[Max Intensity]");
        if (isOpen(src)) { selectWindow(src); close(); }
        src = getTitle();
        getDimensions(w, h, c, z, t);
    }

    if (bitDepth() != bd) run(depthStr);

    // crop a fixed-size box, centred where the inspection pass decided,
    // clamped so the box never runs off the edge of the image
    if (doCrop) {
        cxp = ctrX[i];  cyp = ctrY[i];
        bw2 = cropW;    bh2 = cropH;
        if (bw2 > w) bw2 = w;
        if (bh2 > h) bh2 = h;
        x0 = round(cxp - bw2 / 2);
        y0 = round(cyp - bh2 / 2);
        if (x0 < 0) x0 = 0;
        if (y0 < 0) y0 = 0;
        if (x0 + bw2 > w) x0 = w - bw2;
        if (y0 + bh2 > h) y0 = h - bh2;
        makeRectangle(x0, y0, bw2, bh2);
        run("Crop");
        run("Select None");
        getDimensions(w, h, c, z, t);
    }

    if (scale != 1) {
        run("Scale...", "x=" + scale + " y=" + scale
            + " z=1.0 interpolation=Bilinear average process create title=SCALED");
        if (isOpen(src)) { selectWindow(src); close(); }
        src = getTitle();
        getDimensions(w, h, c, z, t);
    }

    ox = rowLabW + gap + colOf[i] * cellW;
    oy = gap + rowOf[i] * cellH + labelBand;

    // copy slice by slice so channel and z positions line up exactly
    for (cc = 1; cc <= c && cc <= maxC; cc++) {
        for (zz = 1; zz <= z && zz <= maxZ; zz++) {
            selectWindow(src);
            if (c > 1 || z > 1) Stack.setPosition(cc, zz, 1);
            run("Select All");
            run("Copy");

            selectImage(grid);
            if (maxC > 1 || maxZ > 1) Stack.setPosition(cc, zz, 1);
            makeRectangle(ox, oy, w, h);
            run("Paste");
            run("Select None");      // commits the paste
        }
    }

    if (isOpen(src)) { selectWindow(src); close(); }

    labels[i] = cg_makeLabel(name, labelMode);
    labelX[i] = ox + 2;
    labelY[i] = gap + rowOf[i] * cellH + fontSize + 1;

    print("  [" + (i + 1) + "/" + n + "] " + name
          + "   -> row " + (rowOf[i] + 1) + ", col " + (colOf[i] + 1));
}

// -------------------------------------------------------------------------
//  5 - labels, grid lines, display
// -------------------------------------------------------------------------
selectImage(grid);
run("Select None");
Overlay.remove;
setFont("SansSerif", fontSize, "bold antialiased");
setColor(labelCol);

for (i = 0; i < n; i++) Overlay.drawString(labels[i], labelX[i], labelY[i]);

if (byGroup) {
    setFont("SansSerif", fontSize + 3, "bold antialiased");
    for (r = 0; r < groups.length; r++)
        Overlay.drawString(groups[r], 4,
                           gap + r * cellH + labelBand + floor(tileH / 2));
    setFont("SansSerif", fontSize, "bold antialiased");
}

if (drawGrid) {
    setColor(labelCol);
    for (i = 0; i < n; i++) {
        ox = rowLabW + gap + colOf[i] * cellW;
        oy = gap + rowOf[i] * cellH + labelBand;
        Overlay.drawRect(ox, oy, tileW, tileH);
    }
}
Overlay.show;

rename(outName);
if (maxC > 1) {
    Stack.setDisplayMode("composite");
    run("Make Composite");
}

setBatchMode(false);
selectWindow(outName);
setLocation(20, 60);
run("Select None");

// ImageJ gives a new composite its own default LUTs (red, green, blue,
// gray...), which is why channel colours looked swapped. Set them here.
if (maxC > 1) {
    lutParts = split(lutText, ",");
    for (c = 1; c <= maxC; c++) {
        Stack.setChannel(c);
        if (c <= lutParts.length) {
            ln = cg_lutName(String.trim(lutParts[c - 1]));
            if (ln != "") run(ln);
        }
    }
    Stack.setChannel(1);
    print("Channel LUTs: " + lutText);
}

if (maxC > 1 && openChan) run("Channels Tool...");

if (saveTif) {
    p = cg_root + outName + ".tif";
    saveAs("Tiff", p);
    rename(outName);
    print("Saved: " + p);
}

print("");
print("=== Done ===");
print(n + " image(s) tiled into one hyperstack.");
print("The z-slider and the Channels tool now control every sample at once.");
print("Brightness/Contrast (Ctrl+Shift+C) also applies to all of them.");


// =========================================================================
//  functions
// =========================================================================



// What each ROW stands for.




// Look for "<base>_...<match>....roi" beside the image, preferring a
// Reviewed copy. The base must be followed by "_", otherwise image "1"
// would match "1-2_RC_boundary.roi".


// true when the row label IS the token, or begins with "<token> "


// plain colour word -> the LUT command ImageJ actually has


// true when the token is a whole word of the path: folder names and the
// space-separated parts of the file name, extension removed.
// Word matching is what keeps "0.1" from also matching "0.1-1.0".


// Reorder a list of image indices by a preference list. Each token is
// matched as a whole WORD of the path first (so "0.1" does not also take
// "0.1-1.0"), falling back to a substring match if the word test finds
// nothing. Anything unmatched keeps its existing order, at the end.






// zero-pad digit runs so "2" sorts before "10".
// NOT called pad(): that name collides with ImageJ's built-in IJ.pad().
}

function cg_findRoiFor(d, base, match) {
    cand = newArray(
        d + "Output_Max_Intensity" + File.separator + "Reviewed" + File.separator,
        d + "Reviewed" + File.separator,
        d + "Output_Max_Intensity" + File.separator,
        d);
    best = ""; bestScore = -1;
    for (c = 0; c < cand.length; c++) {
        if (!File.exists(cand[c])) continue;
        inRev = (indexOf(toLowerCase(cand[c]),
                 File.separator + "reviewed" + File.separator) >= 0);
        fl = getFileList(cand[c]);
        for (k = 0; k < fl.length; k++) {
            if (!endsWith(toLowerCase(fl[k]), ".roi")) continue;
            ok = nm_hasBase(fl[k], base);
            if (ok == 0) continue;
            if (match != "" && indexOf(fl[k], match) < 0) continue;
            score = 0;
            if (inRev) score = score + 4;
            if (indexOf(toLowerCase(fl[k]), "reviewed") >= 0) score = score + 2;
            score = score + (cand.length - c);
            if (score > bestScore) { bestScore = score; best = cand[c] + fl[k]; }
        }
    }
    return best;
}

function cg_hasWord(rel, tk) {
    t = toUpperCase(String.trim(tk));
    r = toUpperCase(rel);
    r = replace(r, "/", " ");
    r = replace(r, "\\\\", " ");
    w = split(r, " ");
    for (k = 0; k < w.length; k++) {
        ww = w[k];
        if (endsWith(ww, ".LSM") || endsWith(ww, ".TIF") || endsWith(ww, ".TIFF")
            || endsWith(ww, ".CZI") || endsWith(ww, ".ND2") || endsWith(ww, ".LIF"))
            ww = substring(ww, 0, lastIndexOf(ww, "."));
        if (ww == t) return true;
    }
    return false;
}

function cg_indexOfNum(arr, v) {
    for (k = 0; k < arr.length; k++) if (arr[k] == v) return k;
    return -1;
}

function cg_indexOfStr(arr, s) {
    for (k = 0; k < arr.length; k++) if (arr[k] == s) return k;
    return -1;
}

function cg_labelStartsWith(label, token) {
    L = toUpperCase(label);
    T = toUpperCase(token);
    if (L == T) return true;
    if (startsWith(L, T + " ")) return true;
    return false;
}

function cg_lutName(c) {
    c = toLowerCase(c);
    if (c == "blue")    return "Blue";
    if (c == "green")   return "Green";
    if (c == "red")     return "Red";
    if (c == "gray" || c == "grey" || c == "grays" || c == "greys")
                        return "Grays";
    if (c == "cyan")    return "Cyan";
    if (c == "magenta") return "Magenta";
    if (c == "yellow")  return "Yellow";
    if (c == "none" || c == "")  return "";
    return "";
}

function cg_makeLabel(name, mode) {
    if (mode == "full file name") return name;
    b = cg_stripExt(name);
    if (mode == "name without extension") return b;
    tok = split(b, " ");
    if (mode == "everything after the animal number") {
        if (tok.length <= 2) return b;
        out = tok[2];
        for (k = 3; k < tok.length; k++) out = out + " " + tok[k];
        return out;
    }
    if (tok.length >= 2) return tok[0] + " " + tok[1];
    return b;
}

function cg_natKey(s) {
    out = "";
    cur = "";
    for (c = 0; c < lengthOf(s); c++) {
        ch = substring(s, c, c + 1);
        if (indexOf("0123456789", ch) >= 0) {   // string-safe digit test:
                                                // ch >= "0" would force the
                                                // interpreter to parse ch as
                                                // a number and fail on letters
            cur = cur + ch;
        } else {
            if (cur != "") { out = out + IJ.pad(parseInt(cur), 8); cur = ""; }
            out = out + toLowerCase(ch);
        }
    }
    if (cur != "") out = out + IJ.pad(parseInt(cur), 8);
    return out;
}

function cg_prefOrder(idx, prefTxt) {
    pref = split(prefTxt, ",");
    out = newArray(0);
    for (q = 0; q < pref.length; q++) {
        tk = String.trim(pref[q]);
        if (tk == "") continue;
        hit = 0;
        for (m = 0; m < idx.length; m++) {
            i = idx[m];
            if (cg_indexOfNum(out, i) >= 0) continue;
            rel = substring(cg_imgPaths[i], lengthOf(cg_root));
            if (cg_hasWord(rel, tk)) { out = Array.concat(out, i); hit++; }
        }
        if (hit == 0) {
            for (m = 0; m < idx.length; m++) {
                i = idx[m];
                if (cg_indexOfNum(out, i) >= 0) continue;
                rel = substring(cg_imgPaths[i], lengthOf(cg_root));
                if (indexOf(toUpperCase(rel), toUpperCase(tk)) >= 0) {
                    out = Array.concat(out, i); hit++;
                }
            }
        }
        print("   order token '" + tk + "' matched " + hit + " file(s)");
    }
    for (m = 0; m < idx.length; m++)
        if (cg_indexOfNum(out, idx[m]) < 0) out = Array.concat(out, idx[m]);
    return out;
}

function cg_rowLabel(name, mode, keyword) {
    b = cg_stripExt(name);
    tok = split(b, " ");
    geno = ""; anim = "";
    if (tok.length > 0) geno = tok[0];
    if (tok.length > 1) anim = tok[1];
    hasKey = false;
    if (keyword != "")
        hasKey = (indexOf(toUpperCase(b), toUpperCase(keyword)) >= 0);
    kw = "other";
    if (hasKey) kw = keyword;

    if (mode == cg_ROW_ANIMAL)  return anim;
    if (mode == cg_ROW_GENO)    return geno;

    // with no keyword set, the keyword modes have nothing to split on,
    // so they collapse to the sensible non-keyword equivalent
    if (keyword == "") {
        if (mode == cg_ROW_GENOKEY) return geno;
        if (mode == cg_ROW_KEY)     return "all";
        if (mode == cg_ROW_ALL3)    return geno + " " + anim;
    }

    if (mode == cg_ROW_GENOKEY) return geno + " " + kw;
    if (mode == cg_ROW_KEY)    return kw;
    if (mode == cg_ROW_ALL3)   return geno + " " + anim + " " + kw;
    return geno + " " + anim;                 // ROW_GENOANIM, the default
}

function cg_scanDir(d) {
    list = getFileList(d);
    for (k = 0; k < list.length; k++) {
        if (endsWith(list[k], "/") || endsWith(list[k], File.separator)) {
            cg_scanDir(d + list[k]);
        } else {
            low = toLowerCase(list[k]);
            for (e = 0; e < cg_extList.length; e++) {
                if (endsWith(low, cg_extList[e])) {
                    cg_imgPaths = Array.concat(cg_imgPaths, d + list[k]);
                    break;
                }
            }
        }
    }
}

function cg_stripExt(name) {
    d = lastIndexOf(name, ".");
    if (d > 0) { out = substring(name, 0, d); return out; }
    return name;
}

function nm_hasBase(fileName, base) {
    f = nm_norm(fileName);
    b = nm_norm(base);
    if (f == b) return 1;
    if (startsWith(f, b + "_")) return 1;
    if (startsWith(f, b + ".")) return 1;
    return 0;
}

function nm_norm(s) {
    t = toUpperCase(String.trim(replace(s, " ", "_")));
    while (indexOf(t, "__") >= 0) t = replace(t, "__", "_");
    while (startsWith(t, "_")) t = substring(t, 1);
    while (endsWith(t, "_"))   t = substring(t, 0, lengthOf(t) - 1);
    return t;
}
