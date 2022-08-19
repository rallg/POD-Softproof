# POD-Softproof
Visualize book cover image in CMYK at 240% ink limit, for print-on-demand.

Print-On-Demand (POD) services often print your book cover using standard
CMYK inks, but with 240% ink limit. This technology has a smaller color space
than the colors available to most modern computer and tablet screens.
So, if you design a beautiful, flashy cover, you may be disappointed by
the printed result.

POD-Softproof offers the 'softproof' shell script. It works on Linux,
Windows WLS (Linux Subsystem), and presumably Mac/BASH. A Windows BAT
script may be added in the future.

To use 'softproof' you must have the ImageMagick program installed.

You do not need to compile anything. Simply place POD-Softproof somewhere
in your home directory. Then enter its directory. If necessary, grant
executable permission to 'softproof'. Then test it:

``./softproof example``

Then open file 'view-softproof.html' in a web browser. You will see the
original example image, side-by-side with a softproof image. The softproof
image has its colors changed to emulate CMYK at 240% ink limit.

For more details, `./softproof -h` provides help.

