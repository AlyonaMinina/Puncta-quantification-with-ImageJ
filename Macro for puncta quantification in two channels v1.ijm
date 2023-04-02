//This macro processes a fodler with .czi images to quantify number of puncta per 10 um2 within user-selected ROIs. For each aimge, ROIs are saved as.zip files and qunatifications is saved as .csv file
//NB!! Requires presence of the DefaultROI.zip file in the original folder with .czi files!!

//Step by step:
	//1. Create a folder with .czi images selected for analysis (do not export them as other file formats!)
	//2. Copy the DefaultROI.zip into the same folder. If needed one can modify default ROI number and size/position-> resave the file with the same name into the same directory
	//3. Drag and drop macro file into imageJ to have access to the code
	//4. Load the macro it will open one image at a time and wait for the user to adjust ROI position size.
	//5. Before clicking "ok" it is advisable to double check if and then will proceed with finding maxima and saving data 
	//6. If needed adjust the "prominence" value in the Line 64 to not include noise and not exclude the puncta
	//7. After all ROIs are adjusted and Finding maxima prominence is verified -> click ok. The macro will process all ROIs present in the ROIManager. The ROI.zip file will be saved for each image file individually, while quantification data will be compiled into a single file.csv file with area in um2, puncta and puncta/10 um2 



//Clear the log window if it was open
	if (isOpen("Log")){
		selectWindow("Log");
		run("Close");
	}
	
print("Welcome to the puncta quantification macro!");
print("Please select the folder with images for analysis");

//Find the orignal directory and create a new one for Results
	original_dir = getDirectory("Select a directory");
	output_dir = original_dir +"Results" + File.separator;
	File.makeDirectory(output_dir);

// Get a list of all the files in the directory
	file_list = getFileList(original_dir);


//create a shorter list contiaiing . czi files only
	czi_list = newArray(0);
	for(z = 0; z < file_list.length; z++) {
		if(endsWith(file_list[z], ".czi")) {
			czi_list = Array.concat(czi_list, file_list[z]);
			}
		}
print(czi_list.length + " images were detected for analysis");
print("");

Table.create("Image Results");
// Loop through the list of . czi files
	for (i = 0; i < czi_list.length; i++){
	 path = original_dir + czi_list[i];
	 run("Bio-Formats Windowless Importer",  "open=path");
		      
//get the image file title and remove the extension from it    
	title = getTitle();
	a = lengthOf(title);
	b = a-4;
	short_name = substring(title, 0, b);
	print ("Processing image " + i+1 + " out of " + czi_list.length + ":");
	print(title);
	print("");
					
//adjust the ROIs for each micrographs
	run("ROI Manager...");
	//make sure ROI Maneger is clean of any additional ROIs
		roiManager("reset");
		
	//Draw ROIs in the middle of the image
	 	Image_width = getWidth();
		Image_height = getHeight();
		ROI_height = Image_height/8;
	    ROI_width = ROI_height/2;
		
		//coordinates for the top left corner of the first ROI
		x_coordinate = Image_width/2 - 2*ROI_width;
	    y_coordinate = 15;
	    
		//Draw 10 identical ROIs   placed in the middle of the image
	    k = 0;
	    for (k = 0; k < 5; k++) {
	    makeRectangle(x_coordinate, k*ROI_height + y_coordinate, ROI_width, ROI_height);
	    roiManager("Add");
	    roiManager("Select", k);
        roiManager("Rename", k+1);
        }
        for (k = 6; k < 11; k++) {
	    makeRectangle(x_coordinate + ROI_width, (k-6)*ROI_height + y_coordinate, ROI_width, ROI_height);
	    roiManager("Add");
	    roiManager("Select", k-1);
        roiManager("Rename", k);
        }
        
       // roiManager("Open", original_dir + "DefaultRoiSet.zip");
		roiManager("Show All");
		roiManager("Show All with labels");
		
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
			
//Qunatify puncta in the GFP channel. NB!!! if needed change the prominence for Maxima find in th eline below!
			setSlice(1);
			run("Find Maxima...", "prominence=30 output=Count");
			puncta = getResult("Count",  0);
			Table.set("Number of puncta in the GFP channel", current_last_row, puncta, "Image Results");
			Table.set("Number of GFP puncta per 10 um2", current_last_row, 10*puncta/area, "Image Results");
			run("Clear Results");
			
			
//Qunatify puncta in the RFP channel. NB!!! if needed change the prominence for Maxima find in th eline below!			
			setSlice(2);
			run("Find Maxima...", "prominence=25 output=Count");
			puncta = getResult("Count",  0);
			Table.set("Number of puncta in the RFP channel", current_last_row, puncta, "Image Results");
			Table.set("Number of RFP puncta per 10 um2", current_last_row, 10*puncta/area, "Image Results");			
			run("Clear Results");
			
		//calculate the percentage of GFP-positive RFP puncta (for Sanjana's marker lines)
			G = Table.get("Number of puncta in the GFP channel", current_last_row,"Image Results");
			R = Table.get("Number of puncta in the RFP channel", current_last_row,"Image Results");
			Table.set("% of GFP-positive RFP puncta", current_last_row, G*100/R, "Image Results");	
			}

//Save maxima quantification as .csv file and ROIs as a .zip file
			roiManager("Save", output_dir + short_name +"_ROIs.zip");
			run("Close All");
			roiManager("reset");
			run("Clear Results");
	}		
//Save the quantification results into a .csv table file
  Table.save(output_dir + "Puncta quantification" + ".csv");
 
// a feable attempt to close those pesky ImageJ windows. "Image results" tends to hang around anyways			
	run("Close All");
	roiManager("reset");
	run("Clear Results");
	selectWindow("Image Results");
	run("Close");
	selectWindow("Results");
	run("Close");
	selectWindow("ROI Manager");
	run("Close");
 
//final message
   print(" ");
   print("All Done!");
   print("Your quantification results are saved in the folder " + output_dir);
   print(" "); 
   print(" ");
   print("Alyona Minina. 2023");