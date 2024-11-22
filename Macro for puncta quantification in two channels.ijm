//Alyona Minina. Uppsala.2024
//Clear the log window if it was open
	if (isOpen("Log")){
		selectWindow("Log");
		run("Close");
	}
	
//Print the unnecessary greeting
	print(" ");
	print("Welcome to the macro for autophagic body density measurement in two fluorescent channels!");
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

//Request info from the user about the number and dimensions of the ROIs they wish to analyze
	Channel_1 = "GFP";	  
	Channel_2 = "RFP";
	number_of_ROIs = 5;
	ROI_height = 20;
	ROI_width = 10;
	prominence_for_Channel_1 = 70;
	prominence_for_Channel_2 = 70;
	
	Dialog.create("Please provide ROIs parameters for your images");
	Dialog.addString("Channel 1 name:", Channel_1);
	Dialog.addToSameRow();
	Dialog.addString("Channel 2 name:", Channel_2);
	Dialog.addNumber("Prominence value for Ch1:", prominence_for_Channel_1);
	Dialog.addToSameRow();
	Dialog.addNumber("Prominence value for Ch2:", prominence_for_Channel_2);
	Dialog.addNumber("Number of ROIs to be analyzed on each image:", number_of_ROIs);
	Dialog.addNumber("Dimensions of ROIs. ROI height in um:", ROI_height);
	//Dialog.addToSameRow();
	Dialog.addNumber("ROI width in um:", ROI_width);
	Dialog.show();
	Channel_1 = Dialog.getString();
	prominence_for_Channel_1 = Dialog.getNumber();
	Channel_2 = Dialog.getString();
	prominence_for_Channel_2 = Dialog.getNumber();
	number_of_ROIs = Dialog.getNumber();
	ROI_height = Dialog.getNumber();
	ROI_width = Dialog.getNumber();	
	print("The analysis will be performed using prominnce value for Ch1 = " + prominence_for_Channel_1 + " and for Ch2 = " + prominence_for_Channel_2 + "," );
	print(number_of_ROIs + " ROIs will be analyzed per image, which is equivalent to " + ROI_height*ROI_width*number_of_ROIs + " um2 of total analyzed area per image");
	print(" ");	
	print(" ");

//Create the table for all results
	Table.create("Image Results");
	
//Loop analysis through the list of . czi files
	for (i = 0; i < image_list.length; i++){
		path = original_dir + image_list[i];
		run("Bio-Formats Windowless Importer",  "open=path");
		      
//Get the image file title and remove the extension from it    
		title = getTitle();
		a = lengthOf(title);
		b = a-4;
		short_name = substring(title, 0, b);
		
//Print for the user what image is being processed
		print ("Processing image " + i+1 + " out of " + image_list.length + ":");
		print(title);
		print("");
					
//Adjust the ROIs for each micrographs
		run("ROI Manager...");
		
//Make sure ROI Manager is clean of any additional ROIs
		roiManager("reset");
	
//Obtain coordinates to draw ROIs in the center of the image
		x = getWidth()/2;
		toScaled(x);
		x_coordinate =  parseInt(x);
		
		y = getWidth()/2;
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
		//waitForUser("Adjust each ROI, then hit OK"); 
						
//Perform "Find Maxima" for each ROI and save the results into a custom table
		run("ROI Manager...");
		ROI_number = roiManager("count");
		for ( r=0; r<ROI_number; r++ ) {
			roiManager("Select", r);
			current_last_row = Table.size("Image Results");
			Table.set("File name", current_last_row, short_name, "Image Results");
			Table.set("ROI number", current_last_row, r+1, "Image Results");
			
			//just in case if Results were open from anoter analysis
			run("Clear Results");
			run("Set Measurements...", "area redirect=None decimal=3");
			run("Measure");
			area = getResult("Area", 0);
			Table.set("Area in um2", current_last_row, area, "Image Results");
			run("Clear Results");
			
//Quantify puncta on the first channel of the image. NB!!! if needed, change the prominence for Find Maxima in the line 11
			selectWindow(title);
			setSlice(1);
			run("Duplicate...", "duplicate channels=1");
			rename("Micrograph");
			run("Duplicate...", " ");
			rename("Segmentation");
			run("8-bit");
			run("Enhance Contrast...", "saturated=0.35");
			run("Find Maxima...", "prominence=prominence_for_Channel_1 output=Count");
			Ch1_puncta = getResult("Count",  0);
			Column_1 = "Number of " + Channel_1 + " puncta in the ROI";
			Table.set(Column_1, current_last_row, Ch1_puncta, "Image Results");
			Column_2 = "Number of "+ Channel_1 + " puncta per 10 um2";
			Table.set(Column_2, current_last_row, 10*Ch1_puncta/area, "Image Results");
			run("Clear Results");
			//create a segmented image
			run("Find Maxima...", "prominence="+ prominence_for_Channel_1 +" exclude output=[Point Selection]");
			run("Flatten");
			selectWindow("Micrograph");
			run("RGB Color");
			//Save thersholding results
			run("Combine...", "stack1=Micrograph stack2=Segmentation-1");
			segmentation_dir = output_dir + short_name + File.separator;
			File.makeDirectory(segmentation_dir);
			saveAs("Tiff", segmentation_dir + "Segmentation results for ROI " + (r+1) + " Ch1.tif");
			close();
			selectWindow("Segmentation");
			run("Close");
			
			
			
//Quantify puncta on the second channel of the image. NB!!! if needed, change the prominence for Find Maxima in the line 12
			selectWindow(title);
			setSlice(2);
			run("Duplicate...", "duplicate channels=1");
			rename("Micrograph");
			run("Duplicate...", " ");
			rename("Segmentation");
			run("8-bit");
			run("Enhance Contrast...", "saturated=0.35");
			run("Find Maxima...", "prominence=prominence_for_Channel_2 output=Count");
			Ch2_puncta = getResult("Count",  0);
			Column_3 =  "Number of " + Channel_2 + " puncta in the ROI";
			Table.set(Column_3, current_last_row, Ch2_puncta, "Image Results");
			Column_4 = "Number of "+ Channel_2 + " puncta per 10 um2";
			Table.set(Column_4, current_last_row, 10*Ch2_puncta/area, "Image Results");			
			run("Clear Results");
			//create a segmented image
			run("Find Maxima...", "prominence="+ prominence_for_Channel_2 +" exclude output=[Point Selection]");
			run("Flatten");
			selectWindow("Micrograph");
			run("RGB Color");
			//Save thersholding results
			run("Combine...", "stack1=Micrograph stack2=Segmentation-1");
			segmentation_dir = output_dir + short_name + File.separator;
			File.makeDirectory(segmentation_dir);
			saveAs("Tiff", segmentation_dir + "Segmentation results for ROI " + (r+1) + " Ch2.tif");
			close();
			selectWindow("Segmentation");
			run("Close");
			
			
//Calculate the percentage of GFP-positive RFP puncta (for Sanjana's marker lines)
			Ch1 = Table.get(Column_1, current_last_row,"Image Results");
			//ParseInt is needed, because Mac OS retrieves values from the table as strings
			Ch1_Int = parseFloat(Ch1);
			Ch2 = Table.get(Column_2, current_last_row,"Image Results");
			Ch2_Int = parseFloat(Ch2);
			Column_5 = Channel_1 + " to " + Channel_2 + " puncta ratio";
			Table.set(Column_5, current_last_row, Ch1_Int/Ch2_Int, "Image Results");
			Column_6 = Channel_2 + " to " + Channel_1 + " puncta ratio";
			Table.set(Column_6, current_last_row,  Ch2_Int/Ch1_Int, "Image Results");
			}

//Save maxima quantification as .csv file and ROIs as a .zip file
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
	run("Clear Results");
	selectWindow("Image Results");
	run("Close");
	selectWindow("Results");
	run("Close");
	selectWindow("ROI Manager");
	run("Close");
 
//Print the final message
   print(" ");
   print("All Done!");
   print("Your quantification results are saved in the folder " + output_dir);
   print(" "); 
   print(" ");
   print("Alyona Minina. 2023");
   
//Save the log
	selectWindow("Log");
	saveAs("Text", output_dir + "Analysis summary.txt");
