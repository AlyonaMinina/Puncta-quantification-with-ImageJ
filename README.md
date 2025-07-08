# ImageJ macro scripts for puncta quantification

</br>
</br>
 
<b>!! Please reference the study [(Zou et al., 2025)](https://www.nature.com/articles/s41467-024-55754-1) when using these scipts!! </b>
  
</br>
</br>

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14506480.svg)](https://doi.org/10.5281/zenodo.14506480)



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
9. Macro will generate a Results subfolder in the directory selected in the Step 5 with:
- ROIs sets for each analyzed image
- For each analyzed image a subfolder with ROI previews showing also positions of detected puncta
- A single .csv table with combined quantification for all analyzed images. The file will contain information on image name, ROI number, ROI area in um2, puncta number per ROI and per um2.
10. NB! if you are not satisfied with the quality of puncta detection using selected prominence values, you can run maro again on the same folder, select different prominence values. For each image macro will automaitcally load ROIs placed and adjusted in the previous run.
</br>
</br>
<p align="center"> <a href="https://youtu.be/4rSlMzSEKe8"><img src="https://github.com/AlyonaMinina/Puncta-quantification-with-ImageJ/blob/49cfcafc2e313ad38ca87ff43301bf85631d89d2/1.%20Original%20scripts/Images/Youtube%20preview.PNG" width = 480> </img></a></p>
