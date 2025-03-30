// USAGE: Use in FIJI
//
// Author: Marnie L Maddock (University of Wollongong)
// mmaddock@uow.edu.au, mlm715@uowmail.edu.au
// 5.07.2024
/* Copyright 2024 Marnie Maddock

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * Instructions
 *  Use for .tif images
 *  Images that have no cells (all black for example, will have the error: No window with "Results" found. Remove this black image from the dataset.
	Press run
	
*/

// Fresh Start
roiManager("reset");
roiManager("Show None");

// Set up
dir1 = getDirectory("Choose Source Directory of images");
resultsDir = dir1+"CSV_results/"; // Specify file path to make new directory within dir1
resultsDir2 = dir1+"ROI_images/"; // Specify file path to make new directory within dir1
File.makeDirectory(resultsDir); // Create a directory within dir1 called CSV_results
File.makeDirectory(resultsDir2); // Create a directory within dir1 called ROI_images
list = getFileList(dir1);


// Prompt the user to specify channel names
Dialog.create("Specify Channel Names");
Dialog.addString("Name for Nuclei channel (e.g., DAPI):", "DAPI");
Dialog.addString("Name for channel that should localise with the nuclei (e.g., SOX10):", "SOX10");
Dialog.show();

// Get the user-specified channel names
C1_name = Dialog.getString();
C2_name = Dialog.getString();

// Prompt user to specify channel order
Dialog.create("Specify Channel Numbers");
Dialog.addNumber("Channel number for " + C1_name, 1);
Dialog.addNumber("Channel number for " + C2_name, 2);
Dialog.addCheckbox("Transmitted light channel present?", true);
Dialog.addNumber("Channel number for transmitted light", 3);
Dialog.addCheckbox("Keep transmitted light channel open?", false);
Dialog.show();

// Get the channel numbers
C1_num = Dialog.getNumber();
C2_num = Dialog.getNumber();
hasTrans = Dialog.getCheckbox();
TL_num = Dialog.getNumber();
keep_transmitted = Dialog.getCheckbox();

// Preprocessing settings
Dialog.create("Select Pre-processing Options");
Dialog.addCheckbox("Median Filter", true);
Dialog.addNumber("Median Filter Radius. Ignore option if N/A", 3);
Dialog.addCheckbox("Unsharp Mask", false);
Dialog.addNumber("Unsharp Mask Radius. Ignore option if N/A", 1);
Dialog.addNumber("Unsharp Mask Weight. Ignore option if N/A", 0.6);
Dialog.addCheckbox("Watershed", true);
Dialog.show();

// Save options
median_filter = Dialog.getCheckbox();
median_filter_radius = Dialog.getNumber();
unsharp_mask = Dialog.getCheckbox();
unsharp_radius = Dialog.getNumber();
unsharp_weight = Dialog.getNumber();
watershed = Dialog.getCheckbox();

// Threshold settings
Dialog.create("Adaptive Threshold Settings");
Dialog.addNumber("Block size", 341);
Dialog.addNumber("Then Subtract", -49);
Dialog.show();

// Save options
block_num = Dialog.getNumber();
subtract_num = Dialog.getNumber();

// Analyze Particles Options
Dialog.create("Analyze Particles Settings");
Dialog.addNumber("Minimum Particle Size:", 0);
Dialog.addNumber("Minimum Circularity:", 0.00);
Dialog.addNumber("Maximum Circularity:", 1.00);
Dialog.show();

// Retrieve the values
min_size = Dialog.getNumber();
min_circularity = Dialog.getNumber();
max_circularity = Dialog.getNumber();

// Build the options string using the numbers supplied
ap_options = "size=" + min_size + "-Infinity circularity=" + min_circularity + "-" + max_circularity + " show=Overlay display exclude clear summarize overlay add";


// Start Batch Processing of .tif files
processFolder(dir1);
function processFolder(dir1) {
    list = getFileList(dir1);
    list = Array.sort(list);
    for (i = 0; i < list.length; i++) {
        if (endsWith(list[i], ".tif")) {
            processFile(dir1, resultsDir, list[i]);
        }
    }
} 


function processFile(dir1, resultsDir, file){

	open(dir1 + File.separator + file); // Open file within dir1

			title = getTitle(); //Save name of image to title
			run("Set Measurements...", "limit display add redirect=None decimal=8"); // Set what measurements are required for analyze particles i.e. counts only
			
			Stack.getDimensions(width, height, channels, slices, frames); // Get the dimensions of the image
			
			// Check if the image has multiple Z slices
			if (slices > 1) {
			    // If there are multiple slices, create a max projection
			    run("Z Project...", "projection=[Max Intensity]");
			    rename(title); // Rename the max projection to not include "MAX_"
			} 
			// Split the channels
			run("Split Channels");
			
			// Loop through channels 1 to 5
			for (i = 1; i <= 5; i++) {
			    keep = false;
			    // Check if this channel is one of the ones the user wants to keep
			    if (i == C1_num) {
			        keep = true;
			    }
			    if (i == C2_num) {
			        keep = true;
			    }
			    if (hasTrans && keep_transmitted && i == TL_num) {
			        keep = true;
			    }
			    // If this channel is not selected, close it if open
			    if (!keep) {
			        winName = "C" + i + "-" + title;
			        if (isOpen(winName)) {
			            close(winName);
			        }
			    }
			}

			// Create an array of channels you want to pre-process (for example, C1 and C2)
			channelsToProcess = newArray(C1_num, C2_num);
			
						
			for (i = 0; i < channelsToProcess.length; i++) {
			    channel = channelsToProcess[i];
			    // Select the current channel's window, e.g., "C1-<title>" or "C2-<title>"
			    selectWindow("C" + channel + "-" + title);
			    
				// Pre-processing of image
				if (median_filter) {
	    			run("Median...", "radius=" + median_filter_radius);
				}
				
				if (unsharp_mask) {
					run("Unsharp Mask...", "radius=" + unsharp_radius + " mask=" + unsharp_weight);
				}
	
				run("adaptiveThr ", "using=Mean from=" + block_num + " then=" + subtract_num); // Threshold image using adaptive thresholding. The numbers specified can be optimised for your own image by going to Plugins --> Adaptive Thresholding
				if (watershed) {
	    			run("Watershed");
				} // Watershed segments cells close together
			}
			wait(3000);
			
			// ===== Nuclei Positive Cell Analysis =====
			// Select the nuclei channel
			selectWindow("C" + C1_num + "-" + title);
			run("Analyze Particles...", ap_options);

			// If the image is not black, a results window will appear with Nuclei counts
			    if (isOpen("Results")) {
			        selectWindow("Results");
			        close("Results"); // Per cell results are not needed, as only need counts per image
			    }
			// Wait to give computer time to close Results
			wait(1000);
			
			// Select Summary window
			if (isOpen("Summary")) {
				selectWindow("Summary");
				// Use Table.applyMacro() to manipulate the table and rename columns
				code = ""; // No need to apply any macro code in this case
				Table.applyMacro(code);
				// Rename the columns
				Table.renameColumn("Slice", "Image");
				Table.renameColumn("Count", C1_name +"+ve cells");
				Table.deleteColumn("Total Area");
				Table.deleteColumn("Average Size");
				Table.deleteColumn("%Area");
				
				saveAs("Results", resultsDir + File.separator + C1_name + "_summary_" + title +".csv"); // Save Nuclei counts
				close(C1_name + "_summary_" + title + ".csv");
			}
			wait(500); // Ensure enough time for computer to save file

			// Co-localisation using Image Calculator
			imageCalculator("AND create", "C" + C1_num + "-" + title,"C" + C2_num + "-" + title); // This creates a new image containing only the overlapping regions of the two channels
			
			// Check if the resulting image from the AND operation exists
			if (isOpen("Result of C" + C1_num + "-" + title)) {
				wait(500);
				selectWindow("Result of C" + C1_num + "-" + title);
				 // Run Analyze Particles on the resulting image to count how many cells are co-localised
				run("Analyze Particles...", ap_options);
				wait(1000);  // Ensure enough time for computer to compute image calculator
				
				selectWindow("Summary");
				// Use Table.applyMacro() to manipulate the table
				code = ""; // No need to apply any macro code in this case
				Table.applyMacro(code);
				// Rename the columns
				Table.renameColumn("Slice", "Image");
				Table.renameColumn("Count", C1_name + " +ve & " + C2_name + " +ve cells");
				Table.deleteColumn("Total Area");
				Table.deleteColumn("Average Size");
				Table.deleteColumn("%Area");
				
				saveAs("Results", resultsDir + File.separator + "Coloc_summary_" + title +".csv"); // Save colocalisation counts
				close("Coloc_summary_" + title + ".csv");
			
				wait(500); // Give time to save results
			
				// Save region of interest images specifying what cells got counted
				selectWindow("Result of C" + C1_num + "-" + title);
				saveAs("Tiff", resultsDir2 + File.separator + "Coloc_image_" + title + ".tif");
				close();
				close("Coloc_image_" + title + ".tif");
			}
		// Save region of interest images specifying what cells got counted
		selectWindow("C" + C1_num + "-" + title);
		saveAs("Tiff", resultsDir2 + C1_name + "_" + title + ".tif");
		
		// Close remaining images
		close(C1_name + "_" + title + ".tif");
		close("C2-" + title);
			
}

// Code to combine all the saved files into one summary file called combined_summary
concatSummaryFiles(resultsDir, C1_name +"_summary_", C1_name + "_summary_combined.csv");
concatSummaryFiles(resultsDir, "Coloc_summary_", "Coloc_summary_combined.csv");
combineSideBySide(resultsDir + C1_name + "_summary_combined.csv", resultsDir + "Coloc_summary_combined.csv", resultsDir + "Combined_summary.csv");

function concatSummaryFiles(dir, prefix, outputFileName) {
    fileList = getFileList(dir);
    outputFile = dir + outputFileName;

    // Create or clear the output file
    File.saveString("Summary Data\n", outputFile);

    firstFile = true;
    for (i = 0; i < fileList.length; i++) {
        if (startsWith(fileList[i], prefix)) {
            path = dir + fileList[i];
            fileContent = File.openAsString(path);

            // Split the file content into lines
            lines = split(fileContent, "\n");
            if (firstFile) {
                // Keep the header for the first file
                contentToAppend = "";
                for (j = 0; j < lines.length; j++) {
                    if (lengthOf(trim(lines[j])) > 0) { // Skip empty lines
                        contentToAppend += lines[j] + "\n";
                    }
                }
                firstFile = false;
            } else {
                // Skip the first line (header) for subsequent files
                contentToAppend = "";
                for (j = 1; j < lines.length; j++) {
                    if (lengthOf(trim(lines[j])) > 0) { // Skip empty lines
                        contentToAppend += lines[j] + "\n";
                    }
                }
            }

            // Append content only if it's not empty
            if (lengthOf(contentToAppend) > 0) {
                File.append(contentToAppend, outputFile);
            }
        }
    }
}

function combineSideBySide(file1, file2, outputFile) {
    // Read both files
    content1 = File.openAsString(file1);
    content2 = File.openAsString(file2);

    // Split into lines
    lines1 = split(content1, "\n");
    lines2 = split(content2, "\n");

    // Find the maximum length
    maxLength = lines1.length;
    if (lines2.length > maxLength) {
        maxLength = lines2.length;
    }

    // Create combined content
    combinedContent = "";
    for (i = 0; i < maxLength; i++) {
        if (i < lines1.length) {
            line1 = lines1[i];
        } else {
            line1 = "";
        }

        if (i < lines2.length) {
            line2 = lines2[i];
        } else {
            line2 = "";
        }

        combinedContent += line1 + "," + line2 + "\n";
    }

    // Save combined content to output file
    File.saveString(combinedContent, outputFile);
}

close("*");
close("Results");
exit("Done");