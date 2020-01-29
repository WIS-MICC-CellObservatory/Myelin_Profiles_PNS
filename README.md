# Segmentation and Quantification of mature isolated Myelin Profiles from serialEM of PNS 

## Overview

Segment mature isolated myelin profiles from stitched serialEM images and quantify their g-ratio
The macro relies on pixel classification with Ilastik, it assumes that the given classifier was trained to predict myelin (first class) vs background (second class)
Note that this macro is designed to segment isolated myelin rings eg from PNS and it is not suitable for cases in which you have touching rings (eg CNS)

Written by: Ofra Golani at MICC Cell Observatory, Weizmann Institute of Science

In collaboration with Anya Vainshtein and Elior Peles, Weizmann Institute of Science

This macro was used in: 
> Precise spatiotemporal control of nodal Na+ channels clustering by bone morphogenetic protein-1 (BMP-1)/tolloid (TLD)-like proteinases
> Yael Eshed-Eisenbach1, Jerome Devaux3, Anna Vainshtein1, Ofra Golani2, Se-Jin Lee4, Konstantin Feinberg1, Natasha Sukhanov1,Daniel S Greenspan5, Keiichiro Susuki6, Matthew N. Rasband7, and Elior Peles


Software package: Fiji (ImageJ)

Workflow language: ImageJ macro

## Workflow

1. Open selected image
2. Optionally downsample the image (or look for saved downsampled image)
3. Apply Ilastik pixels classification to get Probability map (and save it to output folder)
4. Threshold the mayelin prediction probabilities to get binary mask of candidate myelin pixels
5. Candidate myelin segments are were extracted using connected component analysis (AnalyzeParticles) 
6. To make sure that only closed ring-like segments are taken into account, the candidate segments are further filtered based on 
   - myelin-segment size (MinEmptyRingSegmentSize>3.8 um^2), 
   - axon area (MinInnerRingSize>7.6 um^2), 
   - axon circularity (MinInnerRingCircularity>0.1) 
   - outer profile circularity (MinRingSegmentCircularity>0.1), and 
   - area fraction (MaxRingSegmentRoiFractionArea<90%) . 
7. Twisted profiles are discarded by filtering out segments with more than one hole. 
8. Inner and outer contours are extracted from each segment and used for calculating the inner and outer area. 
9. G-ratio is then calculated for each profile as the ratio between the equivalent inner and outer diameters.  
10. The ROIs are renamed and sorted so that the ROI name is prefxed with the profile identity (Rnnnn-) and the type of ROI ("I-" for inner/ "O-" for outer)

## Output

The macro saves the following output files for each image (eg with name FN) in a subfolder (ResultsSubFolder) under the original folder location:  
- Inner and outer profile ROIs (FN_InnerOuterRoiSet.zip)
- The original image with overlay of the segmented profiles (FN_InnerOuterOverlay.tif), Inner profile is colored in magenta (InnerRoiColor), outer profile in green (OuterRoiColor) 
- Result table with (FN_FinalResults.csv) : one line for each profile with the following information
	* name of outer and inner ROis, 
	* area of inner and outer profiles and their ratio (AreaGRatio), 
	* the equivalent diamters and their ratio (DiameterGRatio)
- Images of the segmented profiles color-coded by the GRatio value (FN__DiameterGRatio_Flatten.tif, FN_AreaGRatio_Flatten.tif) 
  Apearance of the color-coded images can be changed by setting Min/Max values and colomap (aka LUT) 

## Dependencies
- Fiji: https://imagej.net/Fiji
- Ilastik pixel classifier (ilastik-1.3.3post1) https://www.ilastik.org/ 
- Ilastik Fiji Plugin 
- MorphoLibJ plugin: https://imagej.net/MorphoLibJ 

To install them in Fiji:
 - Help=>Update
 - Click “Manage Update sites”
 - Check “Ilastik”
 - Check “IJPB-plugins”
 - Click “Close”
 - Click “Apply changes”

## Usage Instructions

Make sure Fiji Ilastik Plugin is installed in your Fiji (see dependencies below)
Drag and Drop the Macro into Fiji 
Click "Run" , this will envoke a window asking you to set parameters: 
- Set RunMode to "Segment"
- Use Browse to select the File_name to analyze
- Set downscale parameters if needed 
- Set the location of executable (ilastik.exe in the ilastik installation folder)
- Set the location of the ilastik pixel classifier (XX.ilp)
  
Click OK to run. Note that the files are quite big so analysis may take a lot of time
(you may be asked to select the *ilastik.exe file location* and than to choose *Probabilities* as your target ilastik classification)
  
To save time when processing again already-processed file and changing only Fiji parameters, you can use previous ilastik clasification by checking "CheckForExistingIlastikOutputFile"

## Manual Correction

The above automatic process segment correctly most of the profiles. 
Further manual correction is supported by switching from Segment Mode to Update Mode.   
In Update mode the macro skips the segmentation stages (2-7), instead it gets the segmented ROIS from a file, 
find matching pairs of inne/outer ROIs (based on their names) and calculate the updated G-ratio. 
The ROIs are read either from manually corrected file (FN_InnerOuterRoiSet_Manual.zip if exist) or otherwise from the original file (FN_InnerOuterRoiSet.zip)
  
### Manual Correction Instructions
- Open the original image (FN)
- Make sure there is no RoiManager open
- Drag-and-drop the "FN_InnerOuterRoiSet.zip" into Fiji main window 
- In RoiManager: make sure that "Show All" is selected. Ususaly it is more conveinient to unselect Labels 
  
#### Select A ROI
- You can select a ROI from the ROIManager or with long click inside a ring to select its outer ROI (with the Hand-Tool selected in Fiji main window), 
   this will highlight the (outer) ROI in the RoiManager, the matching inner Roi is just above it
    
#### Delete falsely detected objects
- Select a ROI
- Click "Delete" to delete a ROI. it is better to delete both Inner and Outer ROI's 
  
#### Fix segmentation error 
- Select a ROI
- You can update it eg by using the brush tool (deselecting Show All may be more convnient) 
- Hold the shift key down and it will be added to the existing selection. Hold down the alt key and it will be subracted from the existing selection
- Click "Update"
  
- Otherwise you can delete the ROI (see above) and draw another one instead (see below)
 
#### Add non-detected Ring
- A myelin profile is represented by 2 ROIs: one that follows the outer mayelin contour (outer ROI), and one that follow the inner myelin or axon (inner ROI)
  to add a profile, you need to create both inner and outer ROIs
    
- You can draw a ROI using one of the drawing tools 
- An alternative can be using the Wand tool , you'll need to set the Wand tool tolerance first by double clicking on the wand tool icon. 
see also: https://imagej.nih.gov/ij/docs/tools.html
  
- click 't' from the keyboard or "Add" from RoiManger to add it to the RoiManager 
- go to the the very end of the RoiManager , select the newly created ROI and click "Rename", add "I-" or "O-" (capital o) for Inner or outer profile respectively.
   **naming ROIs correctly is crucial** for the update mode to work correctly 
- when drawing outer Roi- just draw the outer contour, 
  
#### Save ROIs
- When done with all corrections make sure to 
- From the RoiManager, click "Deselect" 
- From the RoiManager, click "More" and then "Save" , save the updated file into a file named as the original Roi file with suffix "_Manual": "FN_InnerOuterRoiSet_Manual.zip", using correct file name is crucial
    
#### Run the macro in Update Mode
- When done with correction run the macro again, and change "RunMode" to be "Update" (instead of "Segment"
  
## Notes Regarding Ilastik Classifier

- If your data include images with different contrast, make sure to include  representative images of all conditions When training the classifier
- It is assumed that processed image (after optional rescaling) has pixel size which is up to 20% (PixelSizeCheckFactor) different from the pixel size used for training the Ilastik classifier (PixelSizeUsedForIlastik)
 



