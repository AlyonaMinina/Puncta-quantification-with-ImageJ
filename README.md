# ImageJ macro scripts for puncta quantification

These short scripts are designed to aid semi-automated puncta quantification on .czi microscopy images (can be easily modified for Leica images as well). In our group we use such assay to count autophagosomes or autophagic bodies in plant cells.
The scripts can be also implemented to count organelles such as Golgi apparatus, TGN, MVBs, mitochondria, peroxisomes etc.

Currently there are two macro files: to quantify puncta in a single or in two fluorescent channels.



**Step by step:**
1. Put all images that you wish to analyze into a single folder
2. Download the macro file and drag&drop it into ImageJ -> the script will open in the Editor window
3. Click on "Run"
4. Follow the macro to open the folder from the Step 1
5. If needed edit the number and dimensions for ROIs to be analyzed on each image
6. Adjust ROIs sizes and positions
7. It is recommended to double check the prominence value for each channel that you wish to analyze by manually using Find Maxima option (on at several images/ROIs of the dataset)-> If needed edit the default prominence values in Line 11 and 12 of the macro
7. Hit ok-> macro will process all ROIs for the current image and loop to the next image
8. Repeat steps 6-7 for each image in your folder. Macro will generate a Results subfolder in the directory selected in the Step 4, it will contain ROIs sets for each of the analyzed images with corresponding names and one .csv table with combined quantification for al images. The file will contain information on image name, ROI number, ROI area in um2, puncta number/ROI and per um2. 

<p align="center"> <a href="https://youtu.be/4rSlMzSEKe8"><img src="https://github.com/AlyonaMinina/Puncta-quantification-with-IamgeJ/blob/main/Images/Youtube%20preview.PNG" width = 480> </img></a></p>
