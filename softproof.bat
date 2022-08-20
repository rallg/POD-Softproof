@echo OFF

REM softproof.bat
REM Main repository: github.com/rallg/POD-Softproof
REM This is a Windows batch command script.
REM FREE SOFTWARE, WITHOUT WARRANTY EXPRESS OR IMPLIED. USE AT OWN RISK.
REM Copyright 2018, 2022 Robert Allgeyer.
REM This file may be used, distributed and/or modified under the
REM conditions of the MIT License.

set thisver="0.1.2" REM Script version.

set vermsg="version %thisver%."
set usagemsg1="Usage: softproof.bat YourImage"
set usagemsg2="Help: softproof.bat -h"

if "%~0" != "%CD%\softproof.bat" (
	echo "Error. You must run this script from within POD-Softproof folder."
	echo "In other words, use softproof.bat not C:\path\to\softproof.bat."
	exit "2"
)

if "%1" == "" (
  echo "%usagemsg1%"
  echo "%usagemsg2%"
  exit
)

if "%1" == "-v" "]" || [ "%1" == "-V" (
  echo "%vermsg%"
  exit
)


set h1="Script 'softproof.bat' emulates CMYK print at 240% ink limit."
set h2="This is the technology often used for print-on-demand book covers."
set h3="Invoke as softproof.bat YourImage [from within POD-Softproof folder]."
set h4="For an example:  softproof.bat example"
set h5="Requires 'ImageMagick' program."
set h6="1) YourImage is its case-sensitive filename with extension."
set h7="   It will not be changed. Must use an RGB color space."
set h8="   May be jpg, png, or tif format. Not pdf, svg, or other."
set h9="   You may use absolute or relative path to YourImage,"
set h10="   or place a copy in the same folder as this script."
set h11="2) This script creates two output files in 'working' folder:"
set h12="   File 'reference.jpg' is a [scaled] copy of YourImage."
set h13="   File 'softproof.jpg' is 'reference.jpg', but colors transformed"
set h14="   to those expected from a CMYK press, with 240% ink limit."
set h15="3) Both 'reference.jpg' and 'softproof.jpg' are in the same sRGB"
set h16="   color space. You may compare them side-by-side by opening"
set h17="   file 'view-softproof.html' in a web browser."
set h18="4) If you see unacceptable color changes, the best solution is to"
set h19="   re-design YourImage using colors that can be printed."
set h20="   See the accompanying documentation for examples."
set h21="5) The results you see are only guidelines. More accurate results"
set h22="   would require a calibrated monitor, and actual color profiles"
set h23="   for monitor and printer, which you do not have."

if "%1" == "-h" "]" || [ "%1" == "-H" (
	echo "%h1%"
	echo "%h2%"
	echo "%h3%""
	echo "%h4%"
	echo "%h5%"
	echo "%h6%"
	echo "%h7%"
	echo "%h8%"
	echo "%h9%"
	echo "%h10%"
	echo "%h11%"
	echo "%h12%"
	echo "%h13%"
	echo "%h14%"
	echo "%h15%"
	echo "%h16%"
	echo "%h17%"
	echo "%h18%"
	echo "%h19%"
	echo "%h20%"
	echo "%h21%"
	echo "%h22%"
	echo "%h23%"
	exit
)

if not exist "resource\srgb.icc" || not exist "resource\inklimit240.icc" (
  echo "Error. Did not find both color profiles in 'resource' folder."
  echo "Needs 'resource\srgb.icc' and 'resource\inklimit240.icc'."
  exit "2"
)


if not exist "working" mkdir "working"

REM Find input file:
set input="%~1"
if "%input%" == "example" (
	set input="resource\example.png"
)

if not exist "%input%" (
	echo "Error. File %input% not found."
	exit "2"
)

REM Check for ImageMagick:
set im="imagemagick\"
if not exist %im%magick (
	set im=""
)
%im%magick -version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
	echo "Error. ImageMagick program is not installed."
	exit "2"
)

echo "Working..."


REM Get image width:
%im%magick identify -format %w %input% > working\temp.txt
set /p fw=<working\temp.txt

REM Get image type:
%im%magick identify -format %r %input% > working\temp.txt
set /p it<working\temp.txt
del working\temp.txt
echo "%it%" | findstr "RGB" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
	echo "Error. Input image is not in RGB colorspace."
	exit "2"
)

REM If input has attached color profile, get it:
%im%magick convert %input% working\temp.icc 2>nul
if %ERRORLEVEL% NEQ 0 (
	del /S working\temp.icc REM Possible zero-byte file, if error.
)

REM Create a copy, downscaled if necessary, with metadata removed:
if %fw% GTR 1440 (
	%im%magick convert -strip -resize 960x %input% working\temp.png
	set e="%ERRORLEVEL%"
	if %e% NEQ 0 (
		CALL :discardall
	)
) else (
	%im%magick convert -strip %input% working\temp.png
	set e="%ERRORLEVEL%"
	if %e% NEQ 0 (
		CALL :discardall
	)
)
set "input="

REM Create reference image, with sRGB color profile:
if exist working\temp.icc (
	set how=-profile working\temp.icc -profile resource\srgb.icc
	%im%magick mogrify %how% working\temp.png
	set e="%ERRORLEVEL%"
	set %e% NEQ 0 (
		CALL :discardall
	)
) else (
	%im%magick mogrify -profile resource\srgb.icc working\temp.png
	set e="%ERRORLEVEL%"
	if %e% NEQ 0 (
		CALL :discardall
	)
)
%im%magick convert -quality 100 working\temp.png working\reference.jpg
set e="%ERRORLEVEL%"
if %e% NEQ 0 (
	CALL :discardall
)

REM Convert to temporary CMYK at 240% ink limit, then re-convert to sRGB:
set how=-profile resource\srgb.icc -profile resource\inklimit240.icc
%im%magick convert -quality 100 %how% working\temp.png working\temp.jpg
set e="%ERRORLEVEL%"
set %e% NEQ 0 (
	CALL :discardall
)
set how=-profile resource\inklimit240.icc -profile resource\srgb.icc
%im%magick convert -quality 100 %how% working\temp.jpg working\softproof.jpg
set e="%ERRORLEVEL%"
if %e% NEQ 0 (
	CALL :discardall
)

REM Cleanup:
del  working\temp.icc working\temp.png working\temp.jpg
echo "DONE. Open 'view-softproof.html' in browser."

GOTO :EOF

:discardall
	del /S "working"
	if not exist "working" mkdir "working"
	exit "%e%"
exit /B

:EOF
REM end of file
