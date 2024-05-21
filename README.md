# ImageJ macro scripts for puncta quantification

These short scripts are designed to aid semi-automated puncta quantification on .czi (Carl Zeiss Image) microscopy images or on .tif image files.
To use this macro for Leica microscopy images, please export them first as tifs. You can do it in bulk using the dedicated ImageJ macro  ["Processing Leica CLSM project file for vacFRAP.ijm"](https://github.com/AlyonaMinina/Connectivity-Index)
</br>
</br>
In our group we use such assay to count autophagosomes or autophagic bodies in plant cells.
The scripts can be also implemented to count organelles such as Golgi apparatus, TGN, MVBs, mitochondria, peroxisomes etc.

Currently there are two macro files: to quantify puncta in a single or in two fluorescent channels.



**Step by step:**
1. Put all images that you wish to analyze into a single folder
2. It is recommended to first test the prominence value for each channel that you wish to analyze by manually using Find Maxima option (on at several images/ROIs of the dataset)
3. Download the macro file and drag&drop it into ImageJ -> the script will open in the Editor window
4. Click on "Run"
5. Follow the macro to open the folder from the Step 1
6. If needed edit the number and dimensions for ROIs to be analyzed on each image
7. Adjust ROIs sizes and positions
8. Hit ok-> macro will process all ROIs for the current image and loop to the next image
8. Macro will generate a Results subfolder in the directory selected in the Step 5 with:
- ROIs sets for each analyzed image
- For each analyzed image a subfolder with ROI previews showing also positions of detected puncta
- A single .csv table with combined quantification for all analyzed images. The file will contain information on image name, ROI number, ROI area in um2, puncta number per ROI and per um2.
</br>
</br>
<p align="center"> <a href="https://youtu.be/4rSlMzSEKe8"><img src="https://github.com/AlyonaMinina/Puncta-quantification-with-IamgeJ/blob/main/Images/Youtube%20preview.PNG" width = 480> </img></a></p>
