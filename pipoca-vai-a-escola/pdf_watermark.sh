#!/bin/bash

# Script to convert PDF to watermarked PNGs and then to a scaled PDF

# --- Configuration Defaults ---
WATERMARK_TEXT="DRAFT"
WATERMARK_COLOR="grey" # You can use color names (e.g., "red", "blue") or hex codes (e.g., "#808080")
WATERMARK_FONT="Arial" # Choose a font available on your system (e.g., "Arial", "Liberation-Sans", "Helvetica")
WATERMARK_FONT_SIZE=100 # Adjust as needed for initial text size
WATERMARK_OPACITY=20 # Percentage (0-100)
WATERMARK_ANGLE=45 # Angle for diagonal watermark (degrees)
DEFAULT_OUTPUT_SCALE=1.0 # Default scale for the final PDF images (e.g., 1.0 for 100%, 0.5 for 50%)

# --- Check for Dependencies ---
command -v pdftoppm >/dev/null 2>&1 || { echo >&2 "Error: pdftoppm (poppler-utils) is not installed. Aborting."; exit 1; }
command -v convert >/dev/null 2>&1 || { echo >&2 "Error: ImageMagick (convert) is not installed. Aborting."; exit 1; }
command -v img2pdf >/dev/null 2>&1 || { echo >&2 "Error: img2pdf is not installed. Aborting."; exit 1; }

# --- Usage ---
if [ -z "$1" ]; then
    echo "Usage: $0 <input_pdf_file> [scale_factor]"
    echo "  This script converts a PDF to watermarked PNG images (one per page),"
    echo "  then creates a new PDF with those images. The images can be scaled."
    echo "  If no scale_factor is provided, a default of ${DEFAULT_OUTPUT_SCALE} (100%) is used."
    exit 1
fi

INPUT_PDF="$1"
# Get the scale factor from the second argument, or use the default
OUTPUT_SCALE=${2:-$DEFAULT_OUTPUT_SCALE}

# Input validation for scale factor
if (( $(echo "$OUTPUT_SCALE <= 0" | bc -l) )); then
    echo "Error: Scale factor must be a positive number greater than 0."
    exit 1
fi

FILENAME=$(basename -- "$INPUT_PDF")
FILENAME_NOEXT="${FILENAME%.*}"
OUTPUT_DIR="${FILENAME_NOEXT}_watermarked_pages"
WATERMARKED_IMAGES_PREFIX="${OUTPUT_DIR}/page_watermarked_"
SCALED_IMAGES_PREFIX="${OUTPUT_DIR}/page_scaled_"
FINAL_PDF="${FILENAME_NOEXT}_watermarked_scaled_${OUTPUT_SCALE//./_}.pdf" # Add scale to filename

# --- Create Output Directory ---
mkdir -p "$OUTPUT_DIR" || { echo >&2 "Error: Could not create directory $OUTPUT_DIR. Aborting."; exit 1; }

echo "Processing PDF: $INPUT_PDF"
echo "Using scale factor: $OUTPUT_SCALE"

# --- 1. Convert PDF to PNGs ---
echo "Step 1/5: Converting PDF pages to PNG images..."
# Ensure the output directory is part of the path for pdftoppm
pdftoppm -png "$INPUT_PDF" "$OUTPUT_DIR/page" || { echo >&2 "Error: pdftoppm failed. Aborting."; rm -rf "$OUTPUT_DIR"; exit 1; }
# pdftoppm creates files like page-1.png, page-2.png, etc.

# --- 2. Create the Watermark Image (once) ---
echo "Step 2/5: Creating the watermark overlay image..."
# Get dimensions of the first page to create a suitable watermark image
FIRST_PAGE_IMG=$(ls "$OUTPUT_DIR"/page-*.png | head -n 1)
if [ ! -f "$FIRST_PAGE_IMG" ]; then
    echo >&2 "Error: No PNG images found to determine page dimensions. Aborting."; rm -rf "$OUTPUT_DIR"; exit 1;
fi

IMG_WIDTH=$(identify -format "%w" "$FIRST_PAGE_IMG")
IMG_HEIGHT=$(identify -format "%h" "$FIRST_PAGE_IMG")

WATERMARK_IMG_PATH="${OUTPUT_DIR}/_watermark_overlay.png"

# Create a transparent image with the text, rotate it, and set opacity
# We create a text image much larger than the page to ensure it covers diagonally
# Then we tile it to cover the entire page
convert -size "${IMG_WIDTH}x${IMG_HEIGHT}" xc:transparent \
        -gravity center \
        -pointsize "$WATERMARK_FONT_SIZE" \
        -font "$WATERMARK_FONT" \
        -fill "${WATERMARK_COLOR}" \
        -annotate "$WATERMARK_ANGLE" "$WATERMARK_TEXT" \
        -trim +repage \
        -alpha set -channel A -evaluate Set "$WATERMARK_OPACITY%" \
        "$WATERMARK_IMG_PATH" || { echo >&2 "Error: Could not create watermark image. Aborting."; rm -rf "$OUTPUT_DIR"; exit 1; }

# Resize the single watermark text image if needed to fit for tiling, or just tile it
# A simpler approach is to create a pattern that can be tiled across the page
# Let's create a single instance that is somewhat large and rotated, then tile it.

# A more robust way to create a repeating diagonal watermark:
# 1. Create a transparent canvas
# 2. Draw the text on it
# 3. Rotate it
# 4. Use -tile to create a repeating pattern
# 5. Overlay this pattern.

# Let's try to make a pattern first, then compose.
# Calculate text size to dynamically adjust canvas for pattern
TEXT_WIDTH=$(identify -format "%w" "label:$WATERMARK_TEXT" -pointsize "$WATERMARK_FONT_SIZE" -font "$WATERMARK_FONT" null:)
TEXT_HEIGHT=$(identify -format "%h" "label:$WATERMARK_TEXT" -pointsize "$WATERMARK_FONT_SIZE" -font "$WATERMARK_FONT" null:)

# Create a tileable watermark pattern
# We make the canvas roughly the size of the text itself, plus some padding,
# then rotate it and repeat.
# A common strategy is to make the watermark image slightly larger than the text,
# and then use composite's -tile.

# Let's try a simpler approach by drawing the text multiple times in a larger transparent image
# which will then be composed.
# Calculate diagonal length of the page to ensure watermark covers it
DIAG_LENGTH=$(echo "sqrt($IMG_WIDTH^2 + $IMG_HEIGHT^2)" | bc -l)
# Make watermark canvas slightly larger than diagonal to ensure full coverage after rotation
WATERMARK_CANVAS_SIZE=$(echo "$DIAG_LENGTH * 1.2" | bc)
WATERMARK_CANVAS_SIZE_INT=$(printf "%.0f" "$WATERMARK_CANVAS_SIZE")


# Create a temporary single watermark text image with transparency
TEMP_WATERMARK_TEXT_PATH="${OUTPUT_DIR}/_temp_watermark_text.png"
convert -background none \
        -gravity center \
        -pointsize "$WATERMARK_FONT_SIZE" \
        -font "$WATERMARK_FONT" \
        -fill "${WATERMARK_COLOR}" \
        label:"$WATERMARK_TEXT" \
        -rotate "$WATERMARK_ANGLE" \
        -channel A -evaluate Set "$WATERMARK_OPACITY%" \
        "$TEMP_WATERMARK_TEXT_PATH" || { echo >&2 "Error: Could not create temporary watermark text. Aborting."; rm -rf "$OUTPUT_DIR"; exit 1; }


# Use `composite` with `-tile` to create the repeating watermark overlay
# The base image for the watermark overlay should be the same size as the page.
WATERMARK_OVERLAY_PATH="${OUTPUT_DIR}/_watermark_tile_overlay.png"

convert -size "${IMG_WIDTH}x${IMG_HEIGHT}" xc:transparent \
        tile:"$TEMP_WATERMARK_TEXT_PATH" \
        -background none \
        -gravity center \
        -composite "$WATERMARK_OVERLAY_PATH" || { echo >&2 "Error: Could not create tiled watermark overlay. Aborting."; rm -rf "$OUTPUT_DIR"; exit 1; }

# Remove the temporary single watermark text image
rm "$TEMP_WATERMARK_TEXT_PATH"


# --- 3. Add Watermark to PNGs ---
echo "Step 3/5: Adding watermark to PNG images..."
for img in "$OUTPUT_DIR"/page-*.png; do
    if [ -f "$img" ]; then
        # Extract page number for consistent naming
        page_num=$(echo "$img" | grep -oP 'page-\K[0-9]+(?=\.png)')
        output_watermarked_img="${WATERMARKED_IMAGES_PREFIX}${page_num}.png"
        echo "  - Watermarking $img -> $output_watermarked_img"
        # Compose the original image with the watermark overlay
        composite "$WATERMARK_OVERLAY_PATH" "$img" -gravity center "$output_watermarked_img" || { echo >&2 "Error: ImageMagick (composite) failed for $img. Aborting."; rm -rf "$OUTPUT_DIR"; exit 1; }
    fi
done

# --- 4. Scale Down Watermarked Images ---
# Only scale if OUTPUT_SCALE is not 1.0 (to avoid unnecessary processing)
if (( $(echo "$OUTPUT_SCALE != 1.0" | bc -l) )); then
    echo "Step 4/5: Scaling watermarked images to ${OUTPUT_SCALE}x..."
    # Prepare an array for scaled images
    SCALED_IMAGES=()
    for img in "$WATERMARKED_IMAGES_PREFIX"*.png; do
        if [ -f "$img" ]; then
            page_num=$(echo "$img" | grep -oP 'page_watermarked_\K[0-9]+(?=\.png)')
            output_scaled_img="${SCALED_IMAGES_PREFIX}${page_num}.png"
            echo "  - Scaling $img -> $output_scaled_img"
            convert "$img" -resize "$(echo "$OUTPUT_SCALE * 100" | bc)%" "$output_scaled_img" || { echo >&2 "Error: ImageMagick (convert) failed during scaling for $img. Aborting."; rm -rf "$OUTPUT_DIR"; exit 1; }
            SCALED_IMAGES+=("$output_scaled_img")
        fi
    done
else
    echo "Step 4/5: Skipping scaling as scale factor is 1.0 (100%)."
    # If no scaling, use the watermarked images directly for the final PDF
    SCALED_IMAGES=("$WATERMARKED_IMAGES_PREFIX"*.png)
fi

# Sort the images numerically (important for correct page order)
IFS=$'\n' SCALED_IMAGES=($(sort -V <<<"${SCALED_IMAGES[*]}"))
unset IFS

# --- 5. Create New PDF from Scaled Images ---
echo "Step 5/5: Creating final PDF: $FINAL_PDF from images..."
img2pdf "${SCALED_IMAGES[@]}" -o "$FINAL_PDF" || { echo >&2 "Error: img2pdf failed. Please check the image dimensions and ensure they are not too small (below 3x3 pixels effectively). Aborting."; rm -rf "$OUTPUT_DIR"; exit 1; }

echo "Done! The new watermarked and scaled PDF is: $FINAL_PDF"
echo "Temporary files are located in: $OUTPUT_DIR"
echo "You can remove the temporary directory if you no longer need the intermediate images: rm -rf $OUTPUT_DIR"
echo "Also removing the watermark overlay image: rm $WATERMARK_OVERLAY_PATH"
rm "$WATERMARK_OVERLAY_PATH" # Clean up the final watermark overlay image
