#!/bin/sh

# softproof.sh
# Main repository: github.com/rallg/POD-Softproof
# This is a Linux shell script.
# FREE SOFTWARE, WITHOUT WARRANTY EXPRESS OR IMPLIED. USE AT OWN RISK.
# Copyright 2022 Robert Allgeyer.
# This file may be used, distributed and/or modified under the
# conditions of the MIT License.

thisver="0.1.4" # Version.

vermsg="version $thisver."
usagemsg="Usage: ./softproof.sh YourImage\nHelp: ./softproof.sh -h\n"

if [ "$1" = "" ] ; then printf "$usagemsg" ; exit ; fi
if [ "$1" = "-v" ] || [ "$1" = "-V" ] ; then echo "$vermsg" ; exit ; fi

h="Script 'softproof.sh' emulates CMYK print at 240% ink limit.\n"
h="${h}This is the technology often used for print-on-demand book covers.\n"
h="${h}Invoke as ./softproof.sh YourImage (from within its own directory).\n"
h="${h}For an example:  ./softproof.sh example\n"
h="${h}Requires 'ImageMagick' program.\n"
h="${h}1) YourImage is its case-sensitive filename with extension.\n"
h="${h}   It will not be changed. Must use an RGB color space.\n"
h="${h}   May be jpg, png, or tif format. Not pdf, svg, or other.\n"
h="${h}   You may use absolute or relative path to YourImage,\n"
h="${h}   or place a copy in the same directory as this script.\n"
h="${h}2) This script creates two output files in 'working' directory:\n"
h="${h}   File 'reference.jpg' is a (scaled) copy of YourImage.\n"
h="${h}   File 'softproof.jpg' is 'reference.jpg', but colors transformed\n"
h="${h}   to those expected from a CMYK press, with 240% ink limit.\n"
h="${h}3) Both 'reference.jpg' and 'softproof.jpg' are in the same sRGB\n"
h="${h}   color space. You may compare them side-by-side by opening\n"
h="${h}   file 'view-softproof.html' in a web browser.\n"
h="${h}4) If you see unacceptable color changes, the best solution is to\n"
h="${h}   re-design YourImage using colors that can be printed.\n"
h="${h}   See the accompanying documentation for examples.\n"
h="${h}5) The results you see are only guidelines. More accurate results\n"
h="${h}   would require a calibrated monitor, and actual color profiles\n"
h="${h}   for monitor and printer, which you do not have.\n"
if [ "$1" = "-h" ] || [ "$1" = -H ] ; then printf "$h" ; exit ; fi


# Check structure of directories and required files:
if [ ! -f "resource/srgb.icc" ] || [ ! -f "resource/inklimit240.icc" ] ; then
	echo "Error. Did not find both color profiles in 'resource' folder."
	echo "Needs 'resource/srgb.icc' and 'resource/inklimit240.icc'."
	echo "Be sure to launch as ./softproof.sh from its own directory,"
	echo "not as /path/to/softproof.sh."
	exit 2
fi
mkdir -p working

# Find input file:
input="$1"
[ "$input" = "example" ] && input="resource/example.png"
[ ! -f "$input" ] && echo "Error. File $input not found." && exit 2

# Check for ImageMagick:
magick -version >/dev/null 2>&1
[ "$?" -ne 0 ] && echo "Error. ImageMagick program is not installed." && exit 2

echo "Working..."

discardall() { rm -r -f working ; mkdir -p working ; exit "$e"; }

# Get image width:
fw="$(magick identify -format %w $input)"

# Get image type:
it="$(magick identify -format %r $input)"
echo "$it" | grep "RGB" >/dev/null 2>&1
[ "$?" -ne 0 ] && echo "Error. Input image is not in RGB colorspace." && exit 2

# If input has attached color profile, get it:
magick convert "$input" working/temp.icc 2>/dev/null
[ "$?" -ne 0 ] && rm -f working/temp.icc # Possible zero-byte file, if error.

# Create a copy, downscaled if necessary, with metadata removed:
if [ "$fw" -gt 1440 ] ; then
	magick convert -strip -resize 960x "$input" working/temp.png
	e="$?" ; [ "$e" -ne 0 ] && discardall
else
	magick convert -strip "$input" working/temp.png
	e="$?" ; [ "$e" -ne 0 ] && discardall
fi
unset input

# Create reference image, with sRGB color profile:
if [ -f working/temp.icc ] ; then
	how="-profile working/temp.icc -profile resource/srgb.icc"
	magick mogrify $how working/temp.png
	e="$?" ; [ "$e" -ne 0 ] && discardall
else
	magick mogrify -profile resource/srgb.icc working/temp.png
	e="$?" ; [ "$e" -ne 0 ] && discardall
fi
magick convert -quality 100 working/temp.png working/reference.jpg
e="$?" ; [ "$e" -ne 0 ] && discardall

# Convert to temporary CMYK at 240% ink limit, then re-convert to sRGB:
how="-quality 100 -profile resource/srgb.icc -profile resource/inklimit240.icc"
magick convert $how working/temp.png working/temp.jpg
e="$?" ; [ "$e" -ne 0 ] && discardall
how="-quality 100 -profile resource/inklimit240.icc -profile resource/srgb.icc"
magick convert $how working/temp.jpg working/softproof.jpg
e="$?" ; [ "$e" -ne 0 ] && discardall

# Cleanup:
rm -f working/temp.icc working/temp.png working/temp.jpg
echo "DONE. Open 'view-softproof.html' in browser."

exit 0
## end of file
