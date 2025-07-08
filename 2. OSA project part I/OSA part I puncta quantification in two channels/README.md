# ImageJ macro scripts for puncta quantification

</br>
</br>

This macro carries out semi-automated puncta quantification on .czi (Carl Zeiss Image) microscopy images or .tif image files.
To use this macro for Leica microscopy images, please export them as tifs first. You can do this in bulk using the dedicated ImageJ macro "Processing Leica CLSM project file for vacFRAP.ijm".
</br> </br> </br></br> </br>

The macro was designed to count mCherry-labelled autophagic bodies and quantify the uptake of GFP-labelled organellar markers by autophagy.

**Step by step Instructions:**

1. Put all images you wish to analyze into a single folder.

2. It is recommended to first test the prominence value and Gaussian blur value for each channel you wish to analyze by manually using the Find Maxima option (on several images/ROIs of the dataset).

3.  Download the macro file and drag & drop it into ImageJ -> the script will open in the Editor window.

4. Click "Run."

5. Follow the macro instructions to open the folder containing the images for analysis.

6. If needed, edit suggested by macro number and dimensions for ROIs to be analyzed on each image. Note: The macro will record the area for each ROI and express the number of puncta per 10 µm².

7. Adjust ROI sizes and positions to capture only vacuolar areas.

8. Click "OK" -> The macro will process all ROIs for the current image and then loop to the next image.

7. The macro will generate a time-stamped "IJM results yyyymmdd-hhmmss" subfolder in the original directory and save the following:

   - ROI sets for each analyzed image.
   - A subfolder for each analyzed image with ROI previews showing the positions of detected puncta.
   - A single .csv table with combined quantification for all analyzed images. The table will include:
   - Image name, file path, ROI number, and ROI area in µm².
   - Puncta number for each channel expressed per ROI and per µm². 
   - The ratio of puncta number detected in Channel 1/Channel 2 and Channel 2/Channel 1.

    Note: If you are not satisfied with the quality of puncta detection, you can run the macro again on the same folder (as in Step 1) and select different prominence and Gaussian blur values. The macro will automatically load the ROIs saved in the latest macro run and offer the user an option to re-adjust the ROIs. If you do not wish to readjust the ROIs for each image again, you can comment out the line that starts with "Wait for user."
