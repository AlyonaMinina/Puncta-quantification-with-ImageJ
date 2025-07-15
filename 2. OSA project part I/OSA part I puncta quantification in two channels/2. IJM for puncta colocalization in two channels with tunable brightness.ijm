//Alyona Minina. Uppsala. 2025

//Clear the log window if it was open
	if (isOpen("Log")){
		selectWindow("Log");
		run("Close");
	}
	
//Print the unnecessary greeting
	print(" ");
	print("Welcome to the IJM for puncta quantification in two fluorescent channels!");
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
	

// Check for previous runs results
	r_list = newArray();
	file_list = getFileList(original_dir);                           // Get a list of all files and folders in the directory

	for (f = 0; f < file_list.length; f++) {                         // First, check and add "Results" folder at the start of the list if it exists
	    if (startsWith(file_list[f], "Results")) {
	        r_list = Array.concat(r_list, file_list[f]);             // Add "Results" to the beginning of the list
    	}
	}

	for (f = 0; f < file_list.length; f++) {                        // Then loop through the rest of the directories and add any folders starting with "IJM results"
	    if (startsWith(file_list[f].trim(), "IJM results")) {       // Ensure no leading/trailing spaces
	        r_list = Array.concat(r_list, file_list[f]);
    	}
	}
	
	if(r_list.length>0) {
		if(r_list.length == 1){
			previous_run_dir = original_dir + "Results" + File.separator;
		} else {
			previous_run = substring(r_list[r_list.length-1], 0, 28);
			previous_run_dir = original_dir + previous_run + File.separator;
		}
	}

//create an output directory with a time stamp

	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);    // Get the current date and time components
	
	month = month +1;
	if(month < 10) {                            
		month = "0" + month;                                                          //make sure the time stamp has the same length ndependent on the date/time
	}
	if(dayOfMonth < 10){
		dayOfMonth = "0" + dayOfMonth;
	}
	if(hour < 10){
	hour = "0" + hour;
	}
	if(minute < 10){
	minute = "0" + minute;
	}
	if(second < 10){
	second = "0" + second;
	}

	timestamp = "" + year + "" + month + "" + dayOfMonth + "-" + hour + "" + minute + "" + second;      // Format and print the timestamp without leading zeros in the day and month
	
	output_dir = original_dir + "IJM results " + timestamp + File.separator;
	File.makeDirectory(output_dir);


// Get a list of all image files in the original directory
	file_list = getFileList(original_dir);

	if (image_format == ".czi") {                                                                //If user selected .czi format, create a shorter list contiaiing .czi files only
		image_list = newArray(0);
		for(z = 0; z < file_list.length; z++) {
			if(endsWith(file_list[z], ".czi")) {
				image_list = Array.concat(image_list, file_list[z]);
			}
		 }

	 	if(image_list.length == 0){                                                          		//abort the macro if no files of the correct format were found
	    print("No '.czi' files found in the selected folder. Stopping the macro.");
	    exit();
		} 
	}

	if (image_format == ".tif") {                                                                 //If user selected .tif format, create a shorter list contiaiing .tif files only
		image_list = newArray(0);
		for(z = 0; z < file_list.length; z++) {
			if(endsWith(file_list[z], ".tif")) {
				image_list = Array.concat(image_list, file_list[z]);
			}
		 }
	 	if(image_list.length == 0){                                                                        
	    print("No '.tif' files found in the selected folder. Stopping the macro.");    		     //abort the macro if no files of the correct format were found
	    exit();
		}
	}

// Tell user how many images will be analyzed by the macro
	print(image_list.length + "  '" + image_format + "' images were detected for analysis");


//Request info from the user about the number and dimensions of the ROIs they wish to analyze
	Ch1 = "GFP";	  
	Ch2 = "RFP";
	number_of_ROIs = 3;
	ROI_height = 20;
	ROI_width = 10;
	prominence_for_Ch1 = 40;
	prominence_for_Ch2 = 30;
	Gaussian_Ch1 = 0.07;
	Gaussian_Ch2 = 0.07;
	threshold_um = 0.5;
	brightness = 0.5;

	
	Dialog.create("Please provide ROIs parameters for your images");
	Dialog.addString("Channel 1 name:", Ch1);
	Dialog.addToSameRow();
	Dialog.addString("Channel 2 name:", Ch2);
	Dialog.addNumber("Prominence value for Ch1:", prominence_for_Ch1);
	Dialog.addToSameRow();
	Dialog.addNumber("Prominence value for Ch2:", prominence_for_Ch2);
	Dialog.addNumber("Gaussian blur value for Ch1:", Gaussian_Ch1);
	Dialog.addToSameRow();
	Dialog.addNumber("Gaussian blur value for Ch2:", Gaussian_Ch2);
	Dialog.addMessage("");  
	Dialog.addNumber("Number of ROIs to be analyzed on each image:", number_of_ROIs);
	Dialog.addNumber("Dimensions of ROIs. ROI height in um:", ROI_height);
	Dialog.addNumber("ROI width in um:", ROI_width);
	Dialog.addMessage("");  
	Dialog.addNumber("Colocalization treshold in um:", threshold_um);
	Dialog.addNumber("Brightness adjustment:", brightness);

	
	Dialog.show();
	
	Ch1 = Dialog.getString();
	Ch2 = Dialog.getString();
	prominence_for_Ch1 = Dialog.getNumber();
	prominence_for_Ch2 = Dialog.getNumber();
	Gaussian_Ch1 = Dialog.getNumber();
	Gaussian_Ch2 = Dialog.getNumber();
	number_of_ROIs = Dialog.getNumber();
	ROI_height = Dialog.getNumber();
	ROI_width = Dialog.getNumber();	
	threshold_um = Dialog.getNumber();	
	print(" The analysis is performed using \n Prominence value for Ch1 = " + prominence_for_Ch1 + " and for Ch2 = " + prominence_for_Ch2 + "\n Gaussian blur value for Ch1 = " + Gaussian_Ch1 + " and for Ch2 = " + Gaussian_Ch2 + "\n Colocalization threshold = " + threshold_um + " um" + "\n Brightness adjustment factor = " + brightness);	
	print(" ");	
	print(" ");

//Create the table for all results
	Table.create("Image Results");
	
//Loop analysis through the list of image files
	for (il = 0; il < image_list.length; il++){
		path = original_dir + image_list[il];
		run("Bio-Formats Windowless Importer",  "open=path");
		
		//set scale according to the image resolution. needed later to convert threshold value into pixels, allows to analyze images of different resolution
		getPixelSize(unit, pixelWidth, pixelHeight);
		threshold = threshold_um / Math.max(pixelWidth, pixelHeight);   //just in case if pixels are not square, take in the largest value		
				
		//Get the image file title and remove the extension from it    
		title = getTitle();
		a = lengthOf(title);
		b = a-4;
		short_name = substring(title, 0, b);
		
		//Print for the user what image is being processed
		print ("Processing image " + il+1 + " out of " + image_list.length + ":");
		print(title);
		
		// attempt to equalize images with different brightness
		selectWindow(title);
		setSlice(1);
		run("Enhance Contrast...", "saturated=" + brightness);
		setSlice(2);
		run("Enhance Contrast...", "saturated=" + brightness);
		
					
		//Draw ROIs of the user-provided number and dimensions. Automatically load in already existing ROIs for the image (if not desired, comment out lines 107-114 and the line 124.
		run("ROI Manager...");
		roiManager("reset");
	
		x = getWidth()/2;                 //Obtain coordinates to draw ROIs in the center of the image
		//toScaled(x);
		x_coordinate =  parseInt(x);
		
		y = getWidth()/2;
		//toScaled(y);
		y_coordinate =  parseInt(y);

		if(r_list.length>0) {
			ROIset = previous_run_dir + short_name + "_ROIs.zip";
			f = File.exists(ROIset);
				if(f>0){ 
				roiManager("Open", ROIset);
				roiManager("Show All");
				roiManager("Show All with labels");
				} else {
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
		} else {
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
		 //Comment out the line below, while rerunning the macro, if you do not want to adjust the ROIs size and position
		setTool("rectangle");
		waitForUser("Adjust each ROI, then hit OK"); 
             				
		ROI_number = roiManager("count");                         //Make sure all ROIs are sequenatially renumbered in case if the user changed the default ROI number
		for (no_roi = 0; no_roi < ROI_number; no_roi++) {               
			roiManager("Select", no_roi);
	        roiManager("Rename", no_roi + 1);
	        roiManager("Show All");
			roiManager("Show All with labels");
		}

		newROIset = output_dir + short_name +"_ROIs.zip";      		//Save ROI set in the image subfolder
		roiManager("Deselect");
		roiManager("Save", newROIset);
		print(ROI_number + " ROIs will be analyzed for this image");
						
//Perform "Find Maxima" for each ROI and save the results in a custom table
		run("ROI Manager...");
		ROI_number = roiManager("count");
		for ( r=0; r<ROI_number; r++ ) { 			                               //load the saved ROI set for each ROI analysis. This step is needed because ROI Manager will be cleared to load maxima as rois as well
			roiManager("reset");
			roiManager("Open", newROIset);
			roiManager("Show All");
			roiManager("Show All with labels");
			selectWindow(title);
			roiManager("Select", r);	
			current_last_row = Table.size("Image Results");
			imagePath = original_dir + title;                                      //Record full file path. Setting for re-analyzing images for OSA part I
			Table.set("File path", current_last_row, imagePath, "Image Results");
			Table.set("File name", current_last_row, short_name, "Image Results");
			Table.set("ROI number", current_last_row, r+1, "Image Results");
			run("Clear Results");   			                                    //just in case if Results were open from anoter analysis
			run("Set Measurements...", "area redirect=None decimal=3");
			run("Measure");
			area = getResult("Area", 0);
			if(area == 0){                                                                			// a workaround for the inexplicable bug when area value sometimes = 0 
				print( "Area value = 0 is detected for " + short_name + " ROI " + r+1);
				run("Clear Results");
				run("Set Measurements...", "area redirect=None decimal=3");
				roiManager("Select", r);
				run("Measure");
				area = getResult("Area", 0);
			}
			Table.set("Area in um2", current_last_row, area, "Image Results");
			run("Clear Results");
			
			//Quantify puncta on the first channel of the image.
			selectWindow(title);
			setSlice(1);
			run("Duplicate...", " ");
			rename("Micrograph " + Ch1);
			run("Duplicate...", " ");
			rename("Segmentation " + Ch1);
			run("8-bit");
			run("Subtract Background...", "rolling=25");
			run("Gaussian Blur...", "sigma=" + Gaussian_Ch1 + " scaled");
			run("Enhance Contrast...", "saturated=0.35");
			run("Find Maxima...", "prominence="+ prominence_for_Ch1 +" exclude output=Count");
			Ch1_puncta = getResult("Count",  0);
			Column_1 = "Number of " + Ch1 + " puncta in the ROI";
			Table.set(Column_1, current_last_row, Ch1_puncta, "Image Results");
			Column_2 = "Number of "+ Ch1 + " puncta per 10 um2";
			Table.set(Column_2, current_last_row, 10*Ch1_puncta/area, "Image Results");
			
			//Quantify puncta on the second channel of the image.
			selectWindow(title);
			setSlice(2);
			run("Duplicate...", " ");
			rename("Micrograph " + Ch2);
			run("Duplicate...", " ");
			rename("Segmentation " + Ch2);
			run("8-bit");
			run("Subtract Background...", "rolling=25");
			run("Gaussian Blur...", "sigma=" + Gaussian_Ch2 + " scaled");
			run("Enhance Contrast...", "saturated=0.35");
			run("Find Maxima...", "prominence="+ prominence_for_Ch2 +" exclude output=Count");
			Ch2_puncta = getResult("Count",  0);
			Column_3 = "Number of " + Ch2 + " puncta in the ROI";
			Table.set(Column_3, current_last_row, Ch2_puncta, "Image Results");
			Column_4 = "Number of "+ Ch2 + " puncta per 10 um2";
			Table.set(Column_4, current_last_row, 10*Ch2_puncta/area, "Image Results");
				
			//Create a list of coordinates for maxima in Ch1 and Ch2
			selectWindow("Segmentation " + Ch1);
			run("Find Maxima...", "prominence=" + prominence_for_Ch1 + " exclude output=[Single Points]");
			setOption("BlackBackground", false);
			run("Convert to Mask");
			rename(Ch1);
			roiManager("reset");
			run("Set Measurements...", "area display redirect=None decimal=3");
			run("Analyze Particles...", "clear add");
			roiManager("List");
			
			selectWindow("Segmentation " + Ch2);
			run("Find Maxima...", "prominence=" + prominence_for_Ch2 + " exclude output=[Single Points]");
			setOption("BlackBackground", false);
			run("Convert to Mask");
			rename(Ch2);
			roiManager("reset");
			run("Set Measurements...", "area display redirect=None decimal=3");
			run("Analyze Particles...", "clear add");
			roiManager("List");
			
			Ch1_table = "Overlay Elements of " + Ch1;
			Ch2_table = "Overlay Elements of " + Ch2;
			
			Ch1_count = Table.size(Ch1_table);
			Ch2_count = Table.size(Ch2_table);

			// Create arrays to store the coordinates
			Ch1_x = newArray();
			Ch1_y = newArray();
			Ch2_x = newArray();
			Ch2_y = newArray();

			for (c1 = 0; c1 < Ch1_count; c1++) {
			    Ch1_x[c1] = Table.get("X", c1, Ch1_table);
			    Ch1_y[c1] = Table.get("Y", c1, Ch1_table);
			}
			
			for (c2 = 0; c2 < Ch2_count; c2++) {
			    Ch2_x[c2] = Table.get("X", c2, Ch2_table);
			    Ch2_y[c2] = Table.get("Y", c2, Ch2_table);
			}
			
			matching_maxima = newArray();
			matching_puncta = newArray(); // Store unique puncta (based on coordinates)

			// Loop through each Ch2 maxima and compare it with the Ch1 maxima
			for (m2 = 0; m2 < Table.size(Ch2_table); m2++) {
			
			    Ch2_x = Table.get("X", m2, Ch2_table); 			    // Get the coordinates of the Ch2 maxima
			    Ch2_y = Table.get("Y", m2, Ch2_table);
		
			    unique = "" + Ch2_x + "_" + Ch2_y;                  // Create a unique identifier for Ch2 maxima
		
			    found = false;            
			    for (mp = 0; mp < matching_puncta.length; mp++) {       // Check if this Ch2 puncta has already been counted
			        if (matching_puncta[mp] == unique) {
			            found = true;                               // Mark as found if it exists in the matching_puncta list
			            break;                                      // Exit the loop once it's found
			        }
			    }
		
			    
			    if (!found) {                                                  // If the Ch2 puncta is unique, proceed to check with Ch1
			        for (m1 = 0; m1 < Table.size(Ch1_table); m1++) { 		  // Loop through all the Ch1 maxima
		            Ch1_x = Table.get("X", m1, Ch1_table);
		            Ch1_y = Table.get("Y", m1, Ch1_table);

		            distance_x = Math.abs(Ch2_x - Ch1_x); 		             // Calculate the distance between Ch2 and Ch1 for X and Y coordinates separately
		            distance_y = Math.abs(Ch2_y - Ch1_y);
		
			            if (distance_x <= threshold && distance_y <= threshold) {   		     // If both X and Y distances are within the threshold, consider it a match
			                matching_puncta[matching_puncta.length] = unique; 		            // Store this Ch2 puncta as counted	               
			                matching_maxima[matching_maxima.length] = Ch1_x;                   // Add the matching data to the matching_maxima to an indexed array
			                matching_maxima[matching_maxima.length] = Ch1_y;
			                matching_maxima[matching_maxima.length] = Ch2_x;
			                matching_maxima[matching_maxima.length] = Ch2_y;
			                matching_maxima[matching_maxima.length] = distance_x;
			                matching_maxima[matching_maxima.length] = distance_y;
			                break; 		                                                  // Stop checking for further matches for this Ch2 punctum once a match is found: Exit the inner loop to avoid matching this Ch2 punctum again
			            }
		        	}
		    	}
			}

		Column_5 = "Number of " + Ch2 + " puncta colocalizing with " + Ch1;                  	// Add number of col-localized puncta to the table
		Table.set(Column_5, current_last_row, matching_maxima.length / 6, "Image Results");
		Column_6 = "Number of colocalizing puncta per 10 um2 ";  
		Table.set(Column_6, current_last_row, (matching_maxima.length / 6)/area, "Image Results");
		
		// If there are matching maxima, print them to the log and create a new table
		segmentation_dir = output_dir + short_name + File.separator;
		File.makeDirectory(segmentation_dir);
		
		selectWindow(Ch1);
		run("Duplicate...", " ");
		rename("Matching maxima " + Ch1);
		
		selectWindow(Ch2); 
		run("Duplicate...", " ");
		rename("Matching maxima " + Ch2);	
		
		if (matching_maxima.length > 0) {
	  	   	Table.create("Matching Maxima");             		   // Create a new table to display the matching maxima
		    for (mmx = 0; mmx < matching_maxima.length / 6; mmx++) {		    // Add the matching maxima
		        row_index = mmx;
		        Table.set(Ch1 + " X", row_index, matching_maxima[mmx * 6], "Matching Maxima");
		        Table.set(Ch1 + " Y", row_index, matching_maxima[mmx * 6 + 1], "Matching Maxima");
		        Table.set(Ch2 + " X", row_index, matching_maxima[mmx * 6 + 2], "Matching Maxima");
		        Table.set(Ch2 + " Y", row_index, matching_maxima[mmx * 6 + 3], "Matching Maxima");
	    	} 
		    Table.save( segmentation_dir + "Matching maxima coordinates for ROI " + r+1 + ".csv", "Matching Maxima");
			
			selectWindow("Matching maxima " + Ch1);  //draw circles highliting puncta colocalizing wiht Ch1
			radius = 2;                                                        
			for (mmx = 0; mmx < matching_maxima.length / 6; mmx++) {         
				Ch2_x = matching_maxima[mmx * 6 ];  
			    Ch2_y = matching_maxima[mmx * 6 + 1];  
				o_x = Ch2_x -radius; 			                           
				o_y = Ch2_y -radius;
			    makeOval(o_x, o_y, 2 * radius, 2 * radius);                 
			   	Roi.setStrokeColor("green");
				Roi.setStrokeWidth(0.2);                                 
				run("Add Selection...");
			}
				run("Flatten");
				selectWindow("Matching maxima " + Ch1);
				run("Close");
				selectWindow("Matching maxima " + Ch1 + "-1");
				rename("Matching maxima " + Ch1);
					
			selectWindow("Matching maxima " + Ch2);  //draw circles highliting puncta colocalizing wiht Ch1
			radius = 2;                                                        
			for (mmx = 0; mmx < matching_maxima.length / 6; mmx++) {         
				Ch2_x = matching_maxima[mmx * 6 + 2];  
			    Ch2_y = matching_maxima[mmx * 6 + 3];  
				o_x = Ch2_x -radius; 			                           
				o_y = Ch2_y -radius;
			    makeOval(o_x, o_y, 2 * radius, 2 * radius);                 
			   	Roi.setStrokeColor("red");
				Roi.setStrokeWidth(0.2);                                 
				run("Add Selection...");
			}
			run("Flatten");
			selectWindow("Matching maxima " + Ch2);
			run("Close");
			selectWindow("Matching maxima " + Ch2 + "-1");
			rename("Matching maxima " + Ch2);
		}
		
		//combine previews of segmentation for Ch1 and Ch2
		Rw = getWidth();
		Rh = getHeight();
		setForegroundColor(245, 245, 245);
		setBackgroundColor(245, 245, 245);
		
		selectWindow("Micrograph " + Ch1);
		run("Green");
		run("RGB Color");
		run("Canvas Size...", "width=" + Rw+2 + " height=" + Rh+2 + " position=Center");
		
		selectWindow("Segmentation " + Ch1);
		run("RGB Color");
		run("Canvas Size...", "width=" + Rw+2 + " height=" + Rh+2 + " position=Center");
		
		selectWindow(Ch1);
		run("RGB Color");
		run("Canvas Size...", "width=" + Rw+2 + " height=" + Rh+2 + " position=Center");
		
		selectWindow("Matching maxima " + Ch1);
		run("Canvas Size...", "width=" + Rw+2 + " height=" + Rh+2 + " position=Center");
		run("RGB Color");
		
		run("Combine...", "stack1=[Micrograph " + Ch1 + "] stack2=[Segmentation " + Ch1 + "]");
		rename("Combined " + Ch1);
		run("Combine...", "stack1=[Combined " + Ch1 + "] stack2=[" + Ch1 + "]");
		rename("Combined " + Ch1);
		run("Combine...", "stack1=[Combined " + Ch1 + "] stack2=[Matching maxima " + Ch1 + "]");
		rename("Combined " + Ch1);
		
		
		selectWindow("Micrograph " + Ch2);
		run("Magenta");
		run("RGB Color");
		run("Canvas Size...", "width=" + Rw+2 + " height=" + Rh+2 + " position=Center");
		
		selectWindow("Segmentation " + Ch2);
		run("RGB Color");
		run("Canvas Size...", "width=" + Rw+2 + " height=" + Rh+2 + " position=Center");
				
		selectWindow(Ch2);
		run("Canvas Size...", "width=" + Rw+2 + " height=" + Rh+2 + " position=Center");
		run("RGB Color");
		
		selectWindow("Matching maxima " + Ch2);
		run("RGB Color");
		run("Canvas Size...", "width=" + Rw+2 + " height=" + Rh+2 + " position=Center");
		
		run("Combine...", "stack1=[Micrograph " + Ch2 + "] stack2=[Segmentation " + Ch2 + "]");
		rename("Combined " + Ch2);
		run("Combine...", "stack1=[Combined " + Ch2 + "] stack2=[" + Ch2 + "]");
		rename("Combined " + Ch2);
		run("Combine...", "stack1=[Combined " + Ch2 + "] stack2=[Matching maxima " + Ch2 + "]");
		rename("Combined " + Ch2);
				
		run("Combine...", "stack1=[Combined " + Ch1 + "] stack2=[Combined " + Ch2 + "] combine");
		
		//Save combined segmentation results
		saveAs("Tiff", segmentation_dir + "Segmentation results for ROI " + (r+1) + ".tif");
		close();
		
		//close temorary windows
		roiManager("reset");
		if (isOpen("Overlay Elements of " + Ch1)){
			selectWindow("Overlay Elements of " + Ch1);
			run("Close");
		}
		if (isOpen("Overlay Elements of " + Ch2)){
			selectWindow("Overlay Elements of " + Ch2);
			run("Close");
		}
		if (isOpen("Matching Maxima")){
			selectWindow("Matching Maxima");
			run("Close");			
		}		
		if (isOpen(Ch1)){
			selectWindow(Ch2);
			run("Close");			
		}	
		if (isOpen(Ch2)){
			selectWindow(Ch2);
			run("Close");			
		}	
		if (isOpen("Matching maxima " + Ch1)){
					selectWindow("Matching maxima " + Ch1);
					run("Close");			
				}
		if (isOpen("Matching maxima " + Ch2)){
					selectWindow("Matching maxima " + Ch2);
					run("Close");			
				}
		if (isOpen("ROI Manager")){
			selectWindow("ROI Manager");
			run("Close");			
		}	
		run("Clear Results");
	}		
	
			run("Close All");
}

//Save the quantification results into a .csv table file
	Table.save(output_dir + "Puncta IJM result for " + original_folder_name + ".csv", "Image Results");
	

//A feeble attempt to close those pesky ImageJ windows		
	run("Close All");
	roiManager("reset");
	if (isOpen("Results")){
		selectWindow("Results");
		run("Close");			
			}	
	if (isOpen("Image Results")){
		selectWindow("Image Results");
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
   print("Alyona Minina. 2025");
   
//Save the log
	selectWindow("Log");
	saveAs("Text", output_dir + "Analysis summary.txt");
