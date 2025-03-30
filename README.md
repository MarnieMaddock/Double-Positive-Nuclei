# Double Positive Nuclei Automated Analysis

This is an open-source, FIJI macro that automatically counts cells that have co-localisation of a specific target within the nuclei.

## How It Works

1. **Folder of TIFF Images**: All images need to be saved as a TIFF in a folder on your computer. To automatically convert .lif files to TIFF, see https://github.com/MarnieMaddock/Lif-to-Tif.
2. **Add Adaptive Threshold Plugin**: Install Adaptive Threshold Plugin using instructions given here: https://sites.google.com/site/qingzongtseng/adaptivethreshold.
3. **Open macro in FIJI**: Drag and Drop Double-Positive-Nuclei.ijm into the FIJI console.
4. **Run**: Press Run on the macro.
5. **Automated Analysis**: The macro will ask to select the folder containing TIFF images to be analysed. A pop-up box will appear to guide users into specifying the channels that correspond to the nucleus vs target, and the names of the targets e.g. DAPI and SOX10. Co-localisation counts and ROI images will be saved in the selected folder.
6. **Output**:  Count results are saved as a .csv file. Per image results are saved (i.e. nucelus counts and co-localisation counts). A "Combined_summary" file includes all the counts for each image nuclei and co-localistaion in a summarised format. Regions of interest that are counted are saved to the ROI_images folder. Please check that the image segmentation was accurate before analysing results.

## Analysis Steps

1. **Image Pre-processing**:
   - Median Filter: To remove speckles.
   - Adaptive Threshold: To threshold the nuclei or target. Note the defaults of Mean = 341 then = -49. The numbers specified can be optimised for your own image by going to Plugins --> Adaptive Thresholding, then changing the numbers specified in the macro.
   - Watershed: Segments nearby nuclei.
2. **Count Nuclei**
3. **Count Co-localised Nuclei/target**
   - The nuclei and target channel are superimposed using the Image Calculator, outputting an image that only inlcludes overlapping pixels.
   - Count co-localised cells.
4. **Save Results**
   - Save counts and region of interest images
5. **Calculate Number of double-positive cells %**
   - (Nuclei Positive Cells/Co-localised Positive Cells) * 100
  


## Feedback and Support
If you encounter any issues or have suggestions, feel free to:

- Open an issue on this repository
- [Email Us](mlm715@uowmail.edu.au)

  
## License
Double-Positive-Nuclei project is licensed under the MIT License. See [LICENSE](https://github.com/MarnieMaddock/ProntoPCR/blob/main/LICENSE) for details.

---- 
