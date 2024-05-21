//Alyona Minina. Uppsala.2024
//Clear the log window if it was open
if (isOpen("Log")){
	selectWindow("Log");
	run("Close");	
}

// Create the table for Autophagic bodies density
Density_table = "Autophagic bodies density";
Table.create(Density_table);
Column_1 = "File name";
Column_2 = "ROI number";
Column_3 = "Area of the ROI in um2";
Column_4 = "Autophagic bodies count";
Column_5 = "Number of Autophagic bodies per 10 um2";

// Print the unnecessary greeting
print(" ");
print("Welcome to the macro for autophagic body density measurement in a single fluorescent channel!");
print(" ");
print("This macro can be used for follwoing formats: .czi (Carl Zeiss Image) or .tif image files");
print(" ");
print(" ");


// ask user for the desired file format. It is kept as a dialog instead of automated detection, due to the frequent error of keeping extra tiff files in the analysis folder (despite the printed warning)
Dialog.create("Image file format");
Dialog.addMessage("Please select the format of the images used for this analysis. Hit ok to proceed to selecting the folder with the images.");
Dialog.addChoice("Image file format:", newArray(".czi", ".tif"));
Dialog.show();
image_format = Dialog.getChoice();

// Find the original directory and create a new one for quantification results
original_dir = getDirectory("Select a directory");
original_folder_name = File.getName(original_dir);
output_dir = original_dir +"Results" + File.separator;
File.makeDirectory(output_dir);


// Get a list of all files in the directory
file_list = getFileList(original_dir);


//If user selected .czi format, create a shorter list contiaiing .czi files only
if (image_format == ".czi") {
	image_list = newArray(0);
	for(z = 0; z < file_list.length; z++) {
		if(endsWith(file_list[z], ".czi")) {
			image_list = Array.concat(image_list, file_list[z]);
		}
	 }
	//abort the macro if no files of the correct format were found
 	if(image_list.length == 0){
    print("No '.czi' files found in the selected folder. Stopping the macro.");
    // Stop the macro execution
    exit();
	} 
}

//If user selected .tif format, create a shorter list contiaiing .tif files only
if (image_format == ".tif") {
	image_list = newArray(0);
	for(z = 0; z < file_list.length; z++) {
		if(endsWith(file_list[z], ".tif")) {
			image_list = Array.concat(image_list, file_list[z]);
		}
	 }
	//abort the macro if no files of the correct format were found
 	if(image_list.length == 0){
    print("No '.tif' files found in the selected folder. Stopping the macro.");
    // Stop the macro execution
    exit();
	}
}

// Tell user how many images will be analyzed by the macro
print(image_list.length + " " + image_format + " images were detected for analysis");
print("");
print(" ");

// Request info from the user about the number and dimensions of the ROIs they wish to analyze
number_of_ROIs = 5;
ROI_height = 20;
ROI_width = 10;
prominence = 50;

Dialog.create("Please provide ROIs parameters for your images");
Dialog.addNumber("Number of ROIs to be analyzed on each image:", number_of_ROIs);
Dialog.addNumber("Dimensions of ROIs. ROI height in um:", ROI_height);
Dialog.addNumber("ROI width in um:", ROI_width);
Dialog.addNumber("Prominence value for 'Find maxima'", prominence);
Dialog.show();

number_of_ROIs = Dialog.getNumber();
ROI_height = Dialog.getNumber();
ROI_width = Dialog.getNumber();	
prominence = Dialog.getNumber();	

print("The analysis will be performed with the prominence value for the 'Find maxima' = " + prominence + ",");
print("measuring " + number_of_ROIs + " ROIs per image, wich equates to " + ROI_height*ROI_width*number_of_ROIs + " um2 of total area per image.");
print(" ");
print(" ");

// Loop analysis through the list of image files

for (i = 0; i < image_list.length; i++) {
	path = original_dir + image_list[i];
	run("Bio-Formats Windowless Importer",  "open=path");
		      
	// Get the image file title and remove the extension from it    
	title = getTitle();
	a = lengthOf(title);
	b = a-4;
	short_name = substring(title, 0, b);
			
	// Print for the user what image is being processed
	print ("Processing image " + i+1 + " out of " + image_list.length + ":");
	print(title);
	print("");
							
	// Start ROI Manager to set up user-guided ROIs
	run("ROI Manager...");
	
	// Make sure ROI Manager is clean of any previously used ROIs
	roiManager("reset");
	
	// Obtain coordinates to draw ROIs in the center of the image
	x = getWidth()/2;
	toScaled(x);
	x_coordinate =  parseInt(x);
	
	y = getHeight()/2;
	toScaled(y);
	y_coordinate =  parseInt(y);
	
	//Draw ROIs of the user-provided number and dimensions. Automatically load in already existing ROIs for the image (if not desired, comment out lines 107-114 and the line 124.
	ROIset = output_dir + short_name + "_ROIs.zip";
	f = File.exists(ROIset);
		if(f>0){ 
		roiManager("Open", ROIset);
		roiManager("Show All");
		roiManager("Show All with labels");
		}
	else {
		for (no_roi = 0; no_roi < number_of_ROIs; no_roi++) {
			    makeRectangle(x_coordinate, y_coordinate, ROI_width, ROI_height);
			    run("Specify...", "width=ROI_width height=ROI_height x=x_coordinate y=y_coordinate slice=1 scaled");
		        roiManager("Add");
			    roiManager("Select", no_roi);
		        roiManager("Rename", no_roi + 1);
		        roiManager("Show All");
				roiManager("Show All with labels");
				}
			}
	//Wait for the user to adjust the ROIs size and position
		waitForUser("Adjust each ROI, then hit OK"); 
				
	//Perform segmentation and particle analysis for each ROI and save the results into a custom table
	run("ROI Manager...");
	ROI_number = roiManager("count");
	for ( r=0; r<ROI_number; r++ ) {
		selectWindow(title);
		roiManager("Select", r);
		current_last_row = Table.size(Density_table);
		Table.set(Column_1, current_last_row, short_name, Density_table);
		Table.set(Column_2, current_last_row, r+1, Density_table);
		
		//Measure and log the area of the current ROI	
		run("Set Measurements...", "area redirect=None decimal=3");
		run("Measure");
		ROI_area = getResult("Area", 0);
		Table.set(Column_3, current_last_row, ROI_area, Density_table);
		run("Clear Results");
				
		// Duplicate ROI and quantify autophagic bodies within it
		setSlice(1);
		run("Duplicate...", "duplicate channels=1");
		rename("Micrograph");
		run("Duplicate...", " ");
		rename("Segmentation");
		run("8-bit");
		run("Enhance Contrast...", "saturated=0.35");
		run("Find Maxima...", "prominence="+ prominence +" exclude strict output=Count");
		//save particles areas as a .csv file
		AB_count = getResult("Count");
		Table.set(Column_4, current_last_row, AB_count, Density_table);
		run("Clear Results");
		//create a segmented image
		run("Find Maxima...", "prominence="+ prominence +" exclude output=[Point Selection]");
		run("Flatten");
		selectWindow("Micrograph");
		run("RGB Color");
		Table.save(output_dir + "Autophagic bodies density macro results for experiment " + original_folder_name + ".csv");
		
		//log particles number into the Autophagic bodies density table
		AB_count = Table.get(Column_4, current_last_row, Density_table);
		ROI_area = Table.get(Column_3, current_last_row, Density_table);
		Table.set(Column_5, current_last_row, 10*AB_count/ROI_area, Density_table);
		run("Clear Results");
		Table.save(output_dir + "Autophagic bodies density macro results for experiment " + original_folder_name + ".csv");		
		
		//Save thersholding results
		run("Combine...", "stack1=Micrograph stack2=Segmentation-1");
		segmentation_dir = output_dir + short_name + File.separator;
		File.makeDirectory(segmentation_dir);
		saveAs("Tiff", segmentation_dir + "Segmentation results for ROI " + (r+1) + ".tif");
		
		}	
	
		//Save ROIs as a .zip file
		roiManager("Save", output_dir + short_name +"_ROIs.zip");
		run("Close All");
		roiManager("reset");
		run("Clear Results");		
	}		

//Save the quantification results into a .csv table file
Table.save(output_dir + "Autophagic bodies density macro results for experiment " + original_folder_name + ".csv");

 
//A feeble attempt to close those pesky ImageJ windows		
run("Close All");
roiManager("reset");

if (isOpen("Results")){
	selectWindow("Results");
	run("Close");
	}
if (isOpen("Summary")){
	selectWindow("Summary");
	run("Close");
	}
if (isOpen("Autophagic bodies density")){
	selectWindow("Autophagic bodies density");
	run("Close");
	}	
	
if (isOpen("ROI Manager")){
	selectWindow("ROI Manager");
	run("Close");
	}	
 
//Print the final message
print(" ");
print("All Done!");
print("Your quantification results are saved in the folder " + output_dir);
print(" "); 
print(" ");
print("Alyona Minina. 2024.");

//Save the log
selectWindow("Log");
saveAs("Text", output_dir + "Analysis summary.txt");
