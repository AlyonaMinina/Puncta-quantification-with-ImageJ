//This macro processes a folder with .czi images to quantify number of puncta per 10 um2 within user-selected ROIs. For each image, ROIs are saved as.zip files and quantifications is saved as .csv file

//Step by step:
	//1. Create a folder with .czi images selected for analysis (do not export them as other file formats!)
	//2. Drag and drop macro file into imageJ to have access to the code
	//3. If needed edit the default number of ROIs and their dimensions in the dialog window
	//4. The macro will open one image at a time and wait for the user to adjust ROI position size.
	//5. Before clicking "ok" it is advisable to double check if finding maxima prominence value is optimal for your image. If needed adjust the "prominence" value in the Lines 11 and 12 to not include noise and not exclude the puncta
	//7. After all ROIs are adjusted and Finding maxima prominence is verified -> click ok. The macro will process all ROIs present in the ROI Manager. The ROI.zip file will be saved for each image file individually, while quantification data will be compiled into a single file.csv contining information about image name, ROI number, ROI area in um2, puncta number and puncta number/10 um2 

prominence_for_Channel_1 = 10;
prominence_for_Channel_2 = 40;

//Clear the log window if it was open
	if (isOpen("Log")){
		selectWindow("Log");
		run("Close");
	}
	
//Print the unnecessary greeting
	print(" ");
	print("Welcome to the puncta quantification macro!");
	print(" ");
	print("Please select the folder with images for analysis");
	print(" ");

//Find the original directory and create a new one for quantification results
	original_dir = getDirectory("Select a directory");
	original_folder_name = File.getName(original_dir);
	output_dir = original_dir +"Results" + File.separator;
	File.makeDirectory(output_dir);

// Get a list of all the files in the directory
	file_list = getFileList(original_dir);

//Create a shorter list contiaiing . czi files only
	czi_list = newArray(0);
	for(z = 0; z < file_list.length; z++) {
		if(endsWith(file_list[z], ".czi")) {
			czi_list = Array.concat(czi_list, file_list[z]);
		}
	}
	
//kindly remind the user how many images theiy put into their folder
	print(czi_list.length + " images were detected for analysis");
	print("");

//Request info from the user about the number and dimensions of the ROIs they wish to analyze
	Channel_1 = "GFP";	  
	Channel_2 = "RFP";
	number_of_ROIs = 10;
	ROI_height = 20;
	ROI_width = 10;
	
	Dialog.create("Please provide ROIs parameters for your images");
	Dialog.addString("Channel 1 name:", Channel_1);
	Dialog.addToSameRow();
	Dialog.addString("Channel 2 name:", Channel_2);
	Dialog.addNumber("Number of ROIs to be analyzed on each image:", number_of_ROIs);
	Dialog.addNumber("Dimensions of ROIs. ROI height in um:", ROI_height);
	//Dialog.addToSameRow();
	Dialog.addNumber("ROI width in um:", ROI_width);
	Dialog.show();
	Channel_1 = Dialog.getString();
	Channel_2 = Dialog.getString();
	number_of_ROIs = Dialog.getNumber();
	ROI_height = Dialog.getNumber();
	ROI_width = Dialog.getNumber();	

//Create the table for all results
	Table.create("Image Results");
	
//Loop analysis through the list of . czi files
	for (i = 0; i < czi_list.length; i++){
		path = original_dir + czi_list[i];
		run("Bio-Formats Windowless Importer",  "open=path");
		      
//Get the image file title and remove the extension from it    
		title = getTitle();
		a = lengthOf(title);
		b = a-4;
		short_name = substring(title, 0, b);
		
//Print for the user what image is being processed
		print ("Processing image " + i+1 + " out of " + czi_list.length + ":");
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

//Draw ROIs of the user-provided number and dimensions
		for (no_roi = 0; no_roi < number_of_ROIs; no_roi++) {
			    makeRectangle(x_coordinate, y_coordinate, ROI_width, ROI_height);
			    run("Specify...", "width=ROI_width height=ROI_height x=x_coordinate y=y_coordinate slice=1 scaled");
		        roiManager("Add");
			    roiManager("Select", no_roi);
		        roiManager("Rename", no_roi + 1);
		        roiManager("Show All");
				roiManager("Show All with labels");
				}
			
//Wait for the user to adjust the ROIs size and position
		waitForUser("Adjust each ROI, then hit OK"); 
						
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
			setSlice(1);
			run("Find Maxima...", "prominence=prominence_for_Channel_1 output=Count");
			puncta = getResult("Count",  0);
			Column_1 = "Number of " + Channel_1 + " puncta in the ROI";
			Table.set(Column_1, current_last_row, puncta, "Image Results");
			Column_2 = "Number of "+ Channel_1 + " puncta per 10 um2";
			Table.set(Column_2, current_last_row, 10*puncta/area, "Image Results");
			run("Clear Results");
			
			
//Quantify puncta on the first channel of the image. NB!!! if needed, change the prominence for Find Maxima in the line 12
			setSlice(2);
			run("Find Maxima...", "prominence=prominence_for_Channel_2 output=Count");
			puncta = getResult("Count",  0);
			Column_3 =  "Number of " + Channel_2 + " puncta in the ROI";
			Table.set(Column_3, current_last_row, puncta, "Image Results");
			Column_4 = "Number of "+ Channel_2 + " puncta per 10 um2";
			Table.set(Column_4, current_last_row, 10*puncta/area, "Image Results");			
			run("Clear Results");
			
//Calculate the percentage of GFP-positive RFP puncta (for Sanjana's marker lines)
			Ch1 = Table.get(Column_1, current_last_row,"Image Results");
			//ParseInt is needed, because Mac OS retrieves values from the table as strings
			Ch1_Int = parseInt(Ch1);
			Ch2 = Table.get(Column_2, current_last_row,"Image Results");
			Ch2_Int = parseInt(Ch2);
			percent = Ch1_Int*100/Ch2_Int;
			Column_5 = "% of "+ Channel_2 + " puncta positive for " + Channel_1;
			Table.set(Column_5, current_last_row, percent, "Image Results");	
			}

//Save maxima quantification as .csv file and ROIs as a .zip file
			roiManager("Save", output_dir + short_name +"_ROIs.zip");
			run("Close All");
			roiManager("reset");
			run("Clear Results");
	}		

//Save the quantification results into a .csv table file
	Table.save(output_dir + "Puncta quantification for " + original_folder_name + ".csv");
 
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
