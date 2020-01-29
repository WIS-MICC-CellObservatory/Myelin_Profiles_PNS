// @string(choices=("Segment", "Update"), style="list") runMode
// @File (style="open") file_name
// @boolean scaleDownFlag
// @int scaleDownFactor
// @boolean checkForExistingScaleDownFile
// @boolean saveScaleDownFileFlag
// @File (style="open") IlastikExecutableLocation
// @File (style="open") IlastikClassifierName
// @int MaxRAMMB
// @boolean checkForExistingIlastikOutputFile
// @boolean createColorCodeGRatioImagesFlag
// @boolean batchModeFlag

/* 
 *  GRatio_StitchedImage_PNS_singleFile
 *  
 *  Segment mature isolated myelin rings from stitched serialEM images and quantify their g-ratio
 *  The macro relies on pixel classification with Ilastik, it assumes that the given classifier was trained to predict myelin (first class) vs background (second class)
 *  Note that this macro is designed to segment isolated myelin rings eg from PNS and it is not suitable for cases in which you have touching rings (eg CNS)
 *  
 *  Workflow
 *  =========
 *  1. Open selected image
 *  2. Optionally downsample the image (or look for saved downsampled image)
 *  3. Apply Ilastik pixels classification to get Probability map (and save it to output folder)
 *  4. Threshold the mayelin prediction probabilities to get binary mask of candidate myelin pixels
 *  5. Candidate myelin segments are were extracted using connected component analysis (AnalyzeParticles) 
 *  6. To make sure that only closed ring-like segments are taken into account candidate ring segments are further filtered based on 
 *     - myelin-segment size (MinEmptyRingSegmentSize>3.8 um^2), 
 *     - inner –hole area (MinInnerRingSize>7.6 um^2), 
 *     - inner hole circularity (MinInnerRingCircularity>0.1) 
 *     - outer ring circularity (MinRingSegmentCircularity>0.1), and 
 *     - area fraction (MaxRingSegmentRoiFractionArea<90%) . 
 *  7. Twisted rings are discarded by filtering out segments with more than one hole. 
 *  8. Inner and outer contours are extracted from each segment and used for calculating the inner and outer area. 
 *  9. G-ratio is then calculated for each ring as the ratio between the equivalent inner and outer diameters.  
 *  10. The ROIs are renamed and sorted so that the ROI name is prefxed with the ring identity (Rnnnn-) and the type of ROI ("I-" for inner/ "O-" for outer)
 *  11. The macro saves the following output files for each image (eg with name FN) in a subfolder (ResultsSubFolder) under the original folder location:  
 *  	- Inner and outer ring ROIs (FN_InnerOuterRoiSet.zip)
 *  	- The original image with overlay of the segmented rings (FN_InnerOuterOverlay.tif), Inner ring is colored in magenta (InnerRoiColor), outer ring in green (OuterRoiColor) 
 *  	- Result table with (FN_FinalResults.csv) : one line for each ring with the following information
 *  		* name of outer and inner ROis, 
 *  		* area of inner and outer rings and their ratio (AreaGRatio), 
 *  		* the equivalent diamters and their ratio (DiameterGRatio)
 *  	- Images of the segmented rings color-coded by the GRatio value (FN__DiameterGRatio_Flatten.tif, FN_AreaGRatio_Flatten.tif) 
 *  	  Apearance of the color-coded images can be changed by setting Min/Max values and colomap (aka LUT) 
 *  	
 *  Usage Instructions
 *  ==================
 *  Make sure Fiji Ilastik Plugin is installed in your Fiji (see dependencies below)
 *  Drag and Drop the Macro into Fiji 
 *  Click "Run" , this will envoke a window asking you to set parameters: 
 *  - Set RunMode to "Segment"
 *  - Use Browse to select the File_name to analyze
 *  - Set downscale parameters if needed 
 *  - Set the location of executable (ilastik.exe in the ilastik installation folder)
 *  - Set the location of the ilastik pixel classifier (XX.ilp)
 *  
 *  Click OK to run. Note that the files are quite big so analysis may take a lot of time
 *  (you may be asked to select the *ilastik.exe file location* and than to choose *Probabilities* as your target ilastik classification)
 *  
 *  To save time when processing again already-processed file and changing only Fiji parameters, 
 *  you can use previous ilastik clasification by checking "CheckForExistingIlastikOutputFile"
 *  
 *  
 *  Manual Correction
 *  =================
 *  The above automatic process segment correctly most of the rings. 
 *  Further manual correction is supported by switching from Segment Mode to Update Mode.   
 *  In Update mode the macro skips the segmentation stages (2-7), instead it gets the segmented ROIS from a file, 
 *  find matching pairs of inne/outer ROIs (based on their names) and calculate the updated G-ratio. 
 *  The ROIs are read either from manually corrected file (FN_InnerOuterRoiSet_Manual.zip if exist) or otherwise from the original file (FN_InnerOuterRoiSet.zip)
 *  see further instructions below 
 *  
 *  Manual Correction Instructions
 *  ==============================
 *  - Open the original image (FN)
 *  - make sure there is no RoiManager open
 *  - drag-and-drop the "FN_InnerOuterRoiSet.zip" into Fiji main window 
 *  - in RoiManager: make sure that "Show All" is selected. Ususaly it is more conveinient to unselect Labels 
 *  
 *  Select A ROI
 *  ------------
 *  - You can select a ROI from the ROIManager or with long click inside a ring to select its outer ROI (with the Hand-Tool selected in Fiji main window), 
 *    this will highlight the (outer) ROI in the RoiManager, the matching inner Roi is just above it
 *    
 *  Delete falsely detected objects
 *  -------------------------------
 *  - select a ROI
 *  - click "Delete" to delete a ROI. it is better to delete both Inner and Outer ROI's 
 *  
 *  Fix segmentation error 
 *  ----------------------
 *  - select a ROI
 *  - you can update it eg by using the brush tool (deselecting Show All may be more convnient) 
 *  - Hold the shift key down and it will be added to the existing selection. Hold down the alt key and it will be subracted from the existing selection
 *  - click "Update"
 *  
 *  - otherwise you can delete the ROI (see above) and draw another one instead (see below)
 *  
 *  Add non-detected Ring
 *  ---------------------
 *  - a ring is represented by 2 ROIs: one that follows the outer mayelin contour (outer ROI), and one that follow the inner myelin or axon (inner ROI)
 *    to add a ring, you need to create both inner and outer ROIs
 *    
 *  - You can draw a ROI using one of the drawing tools 
 *  - an alternative can be using the Wand tool , you'll need to set the Wand tool tolerance first by double clicking on the wand tool icon. 
 *  see also: https://imagej.nih.gov/ij/docs/tools.html
 *  
 *  - click 't' from the keyboard or "Add" from RoiManger to add it to the RoiManager 
 *  - go to the the very end of the RoiManager , select the newly created ROI and click "Rename", add "I-" or "O-" (capital o) for Inner or outer ring respectively.
 *    **naming ROIs correctly is crucial** for the update mode to work correctly 
 *  - when drawing outer Roi- just draw the outer contour, 
 *  
 *  Save ROIs
 *  ---------
 *  when done with all corrections make sure to 
 *  - from the RoiManager, click "Deselect" 
 *  - from the RoiManager, click "More" and then "Save" , save the updated file into a file named as the original Roi file with suffix "_Manual":  
 *    "FN_InnerOuterRoiSet_Manual.zip", using correct file name is crucial
 *    
 *  Run in Update Mode
 *  ------------------
 *  - when done with correction run the macro again, and change "RunMode" to be "Update" (instead of "Segment"
 *  
 *  
 *  
 *  Notes Regarding Ilastik Classifier
 *  ==================================
 *  - If your data include images with different contrast, make sure to include  representative images of all conditions When training the classifier
 *  - It is assumed that processed image (after optional rescaling) has pixel size which is 
 *    up to 20% (PixelSizeCheckFactor) different from the pixel size used for training the Ilastik classifier (PixelSizeUsedForIlastik)
 *  
 *  Dependencies 
 *  ============
 *  - ImageJ/Fiji: https://imagej.net/Citing
 *  - Ilastik pixel classifier (ilastik-1.3.3post1)" https://www.ilastik.org/ 
 *  - Ilastik Fiji Plugin (add "Ilastik" to your selected Fiji Update Sites)
 *  - MorphoLibJ plugin (add "IJPB-plugins" to your selected Fiji Update Sites), see: https://imagej.net/MorphoLibJ 
 */
 
var ChosenOutputType = "Probabilities";
var ResultsSubFolder = "Results";

var SetPixelSize = 1; //1; // if the image is already scaled no need to do this, set the value to 0, scaling is using the parameters below
var PixelSize = 7.588; //8.83; // nm
var PixelUnit = "nm";
var PixelSizeUsedForIlastik = 7.588 // nm 
var PixelSizeCheckFactor = 1.2; //1.1;
var saveIlastikOutputFileFlag = 1;

// Segmentation Parameters
var MinRingSegmentSize = 7600; // nm^2  (= 1000 pixels with original downscale by 2)
var MinRingSegmentCircularity=0.1;
var MaxRingSegmentRoiFractionArea = 90; 
var MinEmptyRingSegmentSize=3800 // nm^2 (=500 pixels with original downscale by 2)
var MinInnerRingSize = 7600; // nm^2  (= 1000 pixels with original downscale by 2)
var MinInnerRingCircularity = 0.1;

var saveInnerLabelMapFlag = 0;
var saveRingLabelMapFlag = 0;
var saveDebugFiles = 0;

// Overlay parameters
var InnerRoiColor= "magenta";
var OuterRoiColor= "green";
var	FlattenOverlayFlag = 1;

// Parameters for color coded images 
var	AreaGRatio_MinVal = 0.1; //0.4;
var	AreaGRatio_MaxVal = 1;
var	AreaGRatio_LUTName = "Fire";
var AreaGRatio_DecimalVal = 2;
var	DiameterGRatio_MinVal = 0.4; // 0.6;
var	DiameterGRatio_MaxVal = 1;
var	DiameterGRatio_LUTName = "Fire";
var DiameterGRatio_DecimalVal = 2;
var	ZoomFactorForCalibrationBar = 8; // 2;

//var batchModeFlag = 0;
var cleanupFlag = 1;

// global variables, used throughout the macro
var origName; 
var origNameNoExt;
var actualOrigName;  		// either orig or downscale
var actualOrigNameNoExt;  	// either orig or downscale
var origDir;
var resFolder;
//var suffixStr; 

//======== Main code ===========================

initTime = getTime();
Initialization();

OpenFile(file_name, scaleDownFlag, scaleDownFactor, saveScaleDownFileFlag, ResultsSubFolder, checkForExistingScaleDownFile);

// Generate/get Ilastik Pixel Probabilities
if (matches(runMode,"Segment")) {
	GetIlastikPixelProb(actualOrigName, actualOrigNameNoExt, checkForExistingIlastikOutputFile);
}

// Segment Rings / Read segmented rings & Calculate GRatio save results
SegmentAndMeasureRings(actualOrigName, actualOrigNameNoExt, resFolder);

if(cleanupFlag) Cleanup();
print("Done !");
	
//======== End of Main Code ====================


//===============================================================================================================
function OpenFile(file_name, scaleDownFlag, scaleDownFactor, saveScaleDownFileFlag, ResultsSubFolder, checkForExistingScaleDownFile)
{
	// Open the file	
	if (endsWith(file_name, ".tif") || endsWith(file_name, ".mrc"))
		open(file_name);
	else if (matches(file_name, ".h5")) 
	{
		run("Import HDF5", "select=["+file_name+"] datasetname=[/data: uint16] axisorder=tzyxc");
	} else {
		exit("Only .tif .mrc or .h5 are valid input files")
	}
	
	origName = getTitle();
	//origNameNoExt = replace(origName, InputFileExtension, "");
	origNameNoExt = File.nameWithoutExtension();
	origNameNoExt = replace(origNameNoExt, "-", "_");
	origNameNoExt = replace(origNameNoExt, " ", "_");
	origDir = File.directory;
	resFolder = origDir + File.separator + ResultsSubFolder + File.separator; 
	File.makeDirectory(resFolder);

	// Set PixelSize
	if (SetPixelSize)
		setVoxelSize(PixelSize, PixelSize, PixelSize, PixelUnit);

	
	// Scale down if needed
	if (scaleDownFlag)
	{
		found = 0;
		scaleDownFactorForScale = 1 / scaleDownFactor;		
		scaleDownNameNoExt = origNameNoExt+"_downscale"+scaleDownFactor;
		if (checkForExistingScaleDownFile)
		{
			if (File.exists(resFolder+scaleDownNameNoExt+".tif"))
			{
				print("Reading existing downscale file: ", resFolder+scaleDownNameNoExt+".tif");
				open(resFolder+scaleDownNameNoExt+".tif");
				found = 1;
			}
		}
		if (found == 0)
		{
			print("Scaling down file by factor: ", scaleDownFactorForScale);
			run("Scale...", "x="+scaleDownFactorForScale+" y="+scaleDownFactorForScale+" interpolation=Bilinear average create");
		}
		rename(scaleDownNameNoExt);

		// compare Pixelsize to the one used for Ilastik training
		getVoxelSize(width, height, depth, unit);
		if (width != height)
			exit("Pixel width and height are different: ", width, height);
		if ((width >  PixelSizeUsedForIlastik * PixelSizeCheckFactor) || (width <  PixelSizeUsedForIlastik / PixelSizeCheckFactor))
			exit("Pixel Size ("+width+" "+unit+") is different from the one used for Ilastik Training ("+PixelSizeUsedForIlastik+" "+PixelUnit+")\nPlease double check the settings of  PixelSize  parameter OR Use scaling !");

		if ((saveScaleDownFileFlag) && (found == 0))
		{
			print("Saving down scaled file to: ",resFolder+scaleDownNameNoExt+".tif");
			saveAs("Tiff", resFolder+scaleDownNameNoExt+".tif");
			rename(scaleDownNameNoExt);
		}
		actualOrigName = scaleDownNameNoExt;
		actualOrigNameNoExt = scaleDownNameNoExt;
	}
	else {
		actualOrigName = origName;
		actualOrigNameNoExt = origNameNoExt;
	}
}


//===============================================================================================================
function GetIlastikPixelProb(imageName, imageNameNoExt, checkForExistingIlastikOutputFile)
{
	selectWindow(imageName);
	getVoxelSize(width, height, depth, unit);

	found = 0;
	IlastikOutFile = imageNameNoExt+"_outProbabilities.h5";
	if (checkForExistingIlastikOutputFile)
	{
		if (File.exists(resFolder+IlastikOutFile))
		{
			print("Reading existing Ilastik output ...");
			run("Import HDF5", "select=["+resFolder+IlastikOutFile+"] datasetname=[/data: uint16] axisorder=tzyxc");
			found = 1;
		}
	}
	if (found == 0)
	{
		// run Ilastik Pixel Classifier - first channel is ring / second channel is background
		print("Running Ilastik Pixel classifier...");
		run("Run Pixel Classification Prediction", "saveonly=false projectfilename=["+IlastikClassifierName+"] inputimage=["+imageName+"] chosenoutputtype=Probabilities");		
	}
	rename("outProbabilities");
	setVoxelSize(width, height, depth, unit);
	if (saveIlastikOutputFileFlag)
	{
		print("Saving Ilastik Pixel classifier output...");
		run("Export HDF5", "select=["+resFolder+IlastikOutFile+"] exportpath=["+resFolder+IlastikOutFile+"] datasetname=data compressionlevel=0 input="+"outProbabilities");	
		rename("outProbabilities");
	}
}


//===============================================================================================================
function SegmentAndMeasureRings(imageName, imageNameNoExt, resDir)
{
	SuffixStr = "";
	
	if (matches(runMode, "Segment")) 
	{
		print("SegmentAndMeasureRings: Starting Segment Mode ...");
		selectWindow("outProbabilities");
	
		// Segment Rings from the 
		run("Duplicate...", "title=RingMask duplicate channels=1");
		run("Duplicate...", "title=Orig");
		
		selectWindow("RingMask");
		setThreshold(128, 255);
		run("Convert to Mask");
		// fine smooth of the smooth the border to make sure we have 8-connected object
		run("Dilate");
		run("Erode");
		
		selectWindow("RingMask");
		// We use include holes, because this way closed rings can be easily seprated from the other objects, by their fraction area
		// the area measured is the area of the outer ring including the hole
		run("Analyze Particles...", "size="+MinRingSegmentSize+"-Infinity circularity="+MinRingSegmentCircularity+"-1.00 display exclude clear include add");
	
		nRoi = roiManager("count");
		// Delete non-ring Rois
		for (n = nRoi-1; n >= 0; n--)
		{	
			roiManager("Select",n);
			roiFractionArea = getResult("%Area", n);
			//roiCirc = getResult("Circ.", n);
			//if ((roiFractionArea > 90) || (roiCirc < 0.1))
			if (roiFractionArea > MaxRingSegmentRoiFractionArea)
			{
				roiManager("Delete");
			}
		}
		
		//-------------------------------------------------------------------------------------//
		// We now have only Outer Ring Rois, but we need to find their inner Rois, pair them and measure 
		//-------------------------------------------------------------------------------------//
		nOuterRoi = roiManager("count");
		//-------------------------------------------------------------------------------------//
		// Find pairs of Rois
		//-------------------------------------------------------------------------------------//
	
		// Create label mask using updated inner ROIs only , reload all ROis afterward
		roiManager("Deselect");
		roiManager("Combine");
		run("Create Mask");
		rename("FullRings");
	
		selectWindow("RingMask");
		run("Select None");
		roiManager("Show None");
		run("Analyze Particles...", "size="+MinEmptyRingSegmentSize+"-Infinity circularity=0.0-1.00 show=Masks exclude");
		run("Invert LUT");	
		rename("EmptyRings");
		
		imageCalculator("AND create", "FullRings","EmptyRings");
		selectWindow("Result of FullRings");
		rename("EmptyRingsClean");
	
		imageCalculator("Subtract create", "FullRings","EmptyRingsClean");
		selectWindow("Result of FullRings");
		rename("InnerRings");
		run("Analyze Particles...", "size="+MinInnerRingSize+"-Infinity circularity="+MinInnerRingCircularity+"-1.00 show=[Count Masks] exclude add");
		selectWindow("Count Masks of InnerRings");	
		rename("LabeledInnerRings");
		labelMaskIm = getImageID();
	
		run("Clear Results");
		run("Set Measurements...", "area min perimeter shape area_fraction display redirect=None decimal=3");
		roiManager("Measure");	
	
	}
	else { // Update mode
		print("SegmentAndMeasureRings: Starting Update Mode ...");
		baseRoiName = resDir+imageNameNoExt+"_InnerOuterRoiSet";
		manualROIFound = OpenExistingROIFile(baseRoiName);
		if (manualROIFound) 
			SuffixStr = "_Manual";
		else
			SuffixStr = "";

		// create labeled Image
		createLabelMaskFromRoiManager_byText (imageName, "LabeledInnerRings", "I-");
		selectWindow("LabeledInnerRings");
		labelMaskIm = getImageID();
		run("Set Measurements...", "area min perimeter shape area_fraction display redirect=None decimal=3");
		roiManager("Measure");	
		time2 = initTime; // For debugging
	}
	if (saveInnerLabelMapFlag) 
	{
		selectWindow("LabeledInnerRings");
		saveAs("Tiff", resFolder+imageNameNoExt+"_InnerLabel"+SuffixStr+".tif");
		rename("LabeledInnerRings");
	}
			
	//-------------------------------------------------------------------------------------//
	// Find Matched ROIs of Myelin (Outer ROI) and Axon (Inner ROI)
	//-------------------------------------------------------------------------------------//
	nPairs = 0;
	nRoi = roiManager("count");

	roiTypeA = newArray(nRoi); 		// 0=inner, 1=outer  - do we need this ?
	roiNameA = newArray(nRoi); 		// name of each Roi
	roiNewNameA = newArray(nRoi); 	// new name of each Roi - with prefix of Rnnnn_ where nnnn stands for the pair number
	roiActiveA = newArray(nRoi); 	// is Roi Used either inner/outer
	countMaskValA = newArray(nRoi); // countMask value of inner idx
	roiAreaA = newArray(nRoi); 		// Roi Area
	if (matches(runMode, "Segment")) 
	{
		for (n = 0; n < nOuterRoi; n++)
		{	
			roiManager("Select",n);
			roiName=call("ij.plugin.frame.RoiManager.getName", n);
			roiNameA[n] = roiName;
			countMaskValA[n] = getResult("Max", n);
			roiAreaA[n] = getResult("Area", n);
			roiTypeA[n] = 1; // Outer
		}
		for (n = nOuterRoi; n < nRoi; n++)
		{	
			roiManager("Select",n);
			roiName=call("ij.plugin.frame.RoiManager.getName", n);
			roiNameA[n] = roiName;
			countMaskValA[n] = getResult("Max", n);
			roiAreaA[n] = getResult("Area", n);
			roiTypeA[n] = 0; // Inner
		}
	}
	else // "Update" mode
	{
		nOuterRoi = 0;
		nInnerRoi = 0;
		for (n = 0; n < nRoi; n++)
		{	
			roiManager("Select",n);
			roiName=call("ij.plugin.frame.RoiManager.getName", n);
			roiNameA[n] = roiName;
			if (indexOf(roiName, "O-") != -1)
			{
				nOuterRoi = nOuterRoi + 1;				
				roiTypeA[n] = 1; // Outer
			}
			else if (indexOf(roiName, "I-") != -1)
			{
				nInnerRoi = nInnerRoi + 1;
				roiTypeA[n] = 0; // Inner
			}
			countMaskValA[n] = getResult("Max", n);
			roiAreaA[n] = getResult("Area", n);
			//print(n,roiName,roiTypeA[n],countMaskValA[n],roiAreaA[n]);
		}
	}
	outerRoiIdxA = newArray(nOuterRoi); // Matched indexes for each pair - Outer
	innerRoiIdxA = newArray(nOuterRoi); // Matched indexes for each pair - Inner
	
	//-------------------------------------------------------------------------------------//
	// Print out GRatio for all outer Rois and save the table
	//-------------------------------------------------------------------------------------//
	if (saveDebugFiles)
	{
		saveAs("Results", resDir+imageNameNoExt+"_AllRoiResults"+SuffixStr+".csv");
	}
	IJ.renameResults("Results","Orig"+"_AllRoiResults.csv"); // rename results table for saving it from being overwritten by other "Results"

	//-------------------------------------------------------------------------------------//
	// Find Matched ROIs of Myelin (Outer ROI) and Axon (Inner ROI)
	// - Share the same inner label
	// - Only one inner label for each outer label. 
	// - Outer label with more than one inner label is discarded
	//-------------------------------------------------------------------------------------//
	selectImage(labelMaskIm);
	roiManager("Deselect");
	roiManager("Show None");
	run("Select None");
	getStatistics(areaCM, meanCM, minCM, maxCM);	 

	if (matches(runMode, "Segment")) 
	{
		nPairs = 0;
		for (n = 0; n < nOuterRoi; n++)
		{
			// find most frequent non-zero value of the countMask within the given outer Roi
			// check if outer ring include more than one inner roi
			valid = IsValidOuterROI(n, maxCM);
  
			outerIdx = n;
			outCountMaskVal = countMaskValA[n];
			found = 0;
			innerIdx = -1;
			if ((outCountMaskVal >= 0) && (valid==1))
			{
				m = nOuterRoi;
				do {
					inCountMaskVal = countMaskValA[m];
					if (inCountMaskVal == outCountMaskVal)
					{
						innerIdx = m;
						found = 1;
					}
					//print(n, outCountMaskVal, m, inCountMaskVal, innerIdx);
					m++;
				} while ( (m < nRoi) && (found==0))
			}
			if (found==1)
			{
				SetPair(nPairs, outerIdx, innerIdx, outerRoiIdxA, innerRoiIdxA, roiNameA, roiNewNameA, roiActiveA);
				nPairs++;
				
			} // if (found)
		} // for n
	}
	// ToDo: merge with the process for Segment mode
	else // "Update" mode, 
	{
		nPairs = 0;
		for (n = 0; n < nRoi; n++)
		{
			if (roiTypeA[n] == 1) // Outer
			{
				valid = IsValidOuterROI(n, maxCM);
				
				outerIdx = n;
				outCountMaskVal = countMaskValA[n];
				found = 0;
				innerIdx = -1;
				if ((outCountMaskVal >= 0) && (valid==1))
				{
					m = 0;
					do {
						if (roiTypeA[m] == 0) // Inner
						{
							inCountMaskVal = countMaskValA[m];
							if (inCountMaskVal == outCountMaskVal)
							{
								innerIdx = m;
								found = 1;
							}
							//print(n, outCountMaskVal, m, inCountMaskVal, innerIdx);
						}
						m++;
					} while ( (m < nRoi) && (found==0))
				}
				if (found==1)
				{
					SetPair(nPairs, outerIdx, innerIdx, outerRoiIdxA, innerRoiIdxA, roiNameA, roiNewNameA, roiActiveA);
					nPairs++;
				} // if (found)
			} //if Outer
		} // for n

		// sort the Rois which have new names now, to put inner and outer Rois together
		roiManager("sort");
	}
	saveAs("Results", resDir+imageNameNoExt+"_FinalResults"+SuffixStr+".csv");
	updateResults();
	
	if (matches(runMode, "Segment")) 
	{
		//-------------------------------------------------------------------------------------//
		// Delete all non-relevant Rois, and save the Rois of inner/Outer only 
		// Deletion and saving is done only in Segment mode
		//-------------------------------------------------------------------------------------//
		for (n = nRoi-1; n >= 0; n--)
		{	
			roiManager("Select",n);
			if (roiActiveA[n] == 0)
			{
				roiManager("Delete");
			}
		} 
	
		// sort the Rois which have new names now, to put inner and outer Rois together
		roiManager("sort");
		// save Outer-Inner Rois
		roiManager("Save", resDir+imageNameNoExt+"_InnerOuterRoiSet.zip");
	} 

	// save image with overlay ROIs
	SaveOverlayImage(imageName, imageNameNoExt, "_InnerOuterOverlay"+SuffixStr+".tif", resDir, FlattenOverlayFlag);

	// Now add Ring Rois - note that the inner/outer rings are sorted now
	nRoi = roiManager("count");
	newId = nRoi;
	for (n = 0; n < nPairs; n++)
	{
		innerId = 2*n;
		outerId = 2*n+1;
		roiName=call("ij.plugin.frame.RoiManager.getName", innerId);
		roiManager("Select", newArray(innerId,outerId));
		roiManager("XOR");
		roiManager("Add");
		roiManager("select", newId);
		newName = replace(roiName, "I-", "R-");
		roiManager("rename", newName);
		newId++;
	}
	createLabelMaskFromRoiManager_byRange (imageName, "LabeledRing",nRoi, newId, nRoi);
	if (saveRingLabelMapFlag) 
	{
		selectWindow("LabeledRing");
		saveAs("Tiff", resFolder+imageNameNoExt+"_RingLabel"+SuffixStr+".tif");
		rename("LabeledRing");
	}

	// Create and save color coded images
	if (createColorCodeGRatioImagesFlag) 
	{
		CreateAndSaveColorCodeImage("LabeledRing", "Results", resFolder, imageNameNoExt, "AreaGRatio", SuffixStr, AreaGRatio_MinVal, AreaGRatio_MaxVal, AreaGRatio_DecimalVal, ZoomFactorForCalibrationBar, AreaGRatio_LUTName);
		CreateAndSaveColorCodeImage("LabeledRing", "Results", resFolder, imageNameNoExt, "DiameterGRatio", SuffixStr, DiameterGRatio_MinVal, DiameterGRatio_MaxVal, DiameterGRatio_DecimalVal, ZoomFactorForCalibrationBar, DiameterGRatio_LUTName);
	}	
	// save All Rois
	if (saveDebugFiles)
	{
		roiManager("Save", resDir+imageNameNoExt+"_AllRoiSet"+SuffixStr+".zip");
	}
} // end of SegmentAndMeasureRings


//===============================================================================================================

// find most frequent non-zero value of the countMask within the given outer Roi
// check if outer ring include more than one inner roi
// return 1 if valid, 0 otherwise
function IsValidOuterROI(n, maxCM)
{ 
	valid = 1;
	roiManager("Select",n);
	nBins = maxCM + 10;
	getHistogram(values, counts, nBins, 0, nBins);
	nLabels = 0;
	for (j = 1; j < nBins; j++)
	{
		if (counts[j] > 0)
			nLabels++;
	}
	if ((nLabels == 0) || (nLabels > 1)) // no counts or more than one inner Roi
		valid = 0;
	return valid;
}
	

//===============================================================================================================
function SetPair(pairIdx, OuterIdx, innerIdx, outerRoiIdxA, innerRoiIdxA, roiNameA, roiNewNameA, roiActiveA)
{
	outerRoiIdxA[pairIdx] = OuterIdx;
	innerRoiIdxA[pairIdx] = innerIdx;

	prefix = "R"+IJ.pad(pairIdx+1,4)+"-";
	roiNewNameA[outerIdx] = prefix + "O-"+roiNameA[outerIdx];
	roiNewNameA[innerIdx] = prefix + "I-"+roiNameA[innerIdx];
	//print(nPairs, outerIdx, roiNameA[outerIdx], roiNewNameA[outerIdx], innerIdx, roiNameA[innerIdx], roiNewNameA[innerIdx]);
	roiActiveA[outerIdx] = 1;
	roiActiveA[innerIdx] = 1;

	roiManager("Select",outerIdx);
	roiManager("Set Color", OuterRoiColor);
	roiManager("Set Line Width", 2);
	roiManager("rename", roiNewNameA[outerIdx]);
	
	roiManager("Select",innerIdx);
	roiManager("Set Color", InnerRoiColor);
	roiManager("Set Line Width", 2);
	roiManager("rename", roiNewNameA[innerIdx]);

	outerAreaRoiGR = roiAreaA[innerIdx] / roiAreaA[outerIdx];
	
	effeciveOuterDiameter = 2 * sqrt(roiAreaA[outerIdx] / PI);
	effeciveInnerDiameter = 2 *sqrt(roiAreaA[innerIdx] / PI);
	outerDiameterRoiGR = effeciveInnerDiameter / effeciveOuterDiameter;

	//print(outerIdx, innerIdx, prefix,", NewName:Outer=",roiNewNameA[outerIdx],", NewName:Inner=", roiNewNameA[innerIdx]);
	outName=roiNewNameA[outerIdx];
	inName=roiNewNameA[innerIdx];
	setResult("OuterLabel", nResults, outName); 
	setResult("InnerLabel", nResults-1, inName); 
	setResult("outerCountMaskValue", nResults-1, countMaskValA[outerIdx]); 
	setResult("innerCountMaskValue", nResults-1, countMaskValA[innerIdx]); 
	setResult("InnerArea", nResults-1, roiAreaA[innerIdx]); 
	setResult("OuterArea", nResults-1, roiAreaA[outerIdx]); 
	setResult("AreaGRatio", nResults-1, outerAreaRoiGR); 
	setResult("eInnerDiameter", nResults-1, effeciveInnerDiameter); 
	setResult("eOuterDiameter", nResults-1, effeciveOuterDiameter); 
	setResult("DiameterGRatio", nResults-1, outerDiameterRoiGR); 
}

//===============================================================================================================
// createLabelMaskFromRoiManager - Create Labeled Image using firstId-lastID ROis from ROI Manager, apply scaling of the original image
function createLabelMaskFromRoiManager_byRange (ImName, labeledName,firstId, lastId, labelOffset)
{
	selectWindow(ImName);
	getVoxelSize(width, height, depth, unit);
	newImage(labeledName, "16-bit black", getWidth(), getHeight(), 1);
	//newImage("labeling", "16-bit black", getWidth(), getHeight(), 1);

	for (id = firstId; id < lastId; id++) {
		roiManager("select", id);
		index = id - labelOffset;
		setColor(index+1);
		fill();
	}
	roiManager("Deselect");
	run("Select None");
	// apply scaling of original image
	setVoxelSize(width, height, depth, unit);
	
	resetMinAndMax();
	run("glasbey");
}


//===============================================================================================================
// createLabelMaskFromRoiManager - Create Labeled Image using firstId-lastID ROis from ROI Manager, apply scaling of the original image
function createLabelMaskFromRoiManager_byText (ImName, labeledName, TextStr)
{
	selectWindow(ImName);
	getVoxelSize(width, height, depth, unit);
	newImage(labeledName, "16-bit black", getWidth(), getHeight(), 1);
	//newImage("labeling", "16-bit black", getWidth(), getHeight(), 1);

	nRoi = roiManager("count");
	index = 0;
	for (id = 0; id < nRoi; id++) {
		roiName=call("ij.plugin.frame.RoiManager.getName", id);
		if (indexOf(roiName, TextStr) != -1)
		{
			roiManager("select", id);
			index = index+1;
			setColor(index);
			fill();
		}
	}
	roiManager("Deselect");
	run("Select None");
	// apply scaling of original image
	setVoxelSize(width, height, depth, unit);
	
	resetMinAndMax();
	run("glasbey");
}

//===============================================================================================================

// Clear all results, configure Ilastik, return SuffixStr
function Initialization()
{
	run("Configure ilastik executable location", "executablefilepath=["+IlastikExecutableLocation+"] numthreads=-1 maxrammb="+MaxRAMMB);	
	run("Close All");
	print("\\Clear");
	run("Options...", "iterations=1 count=1 black");
	run("Clear Results");
	roiManager("reset");
	run("Collect Garbage");
	if (isOpen("Orig"+"_AllRoiResults.csv"))
	{
		selectWindow("Orig"+"_AllRoiResults.csv");
		run("Close");
	}

	if (batchModeFlag)
	{
		print("Working in Batch Mode, processing without opening images");
		setBatchMode(true);
	}
}


//===============================================================================================================
function CreateAndSaveColorCodeImage(labeledImName, TableName, resFolder, saveName, FtrName, SuffixStr, MinVal, MaxVal, decimalVal, calibrationZoom, LUTName)
{
	selectImage(labeledImName);
	run("Assign Measure to Label", "results="+TableName+" column="+FtrName+" min="+MinVal+" max="+MaxVal);
	run(LUTName);
	run("Calibration Bar...", "location=[Upper Right] fill=White label=Black number=5 decimal="+decimalVal+" font=12 zoom="+calibrationZoom+" overlay");
	run("Flatten");
	saveAs("Tiff", resFolder+saveName+"_"+FtrName+"_Flatten"+SuffixStr+".tif");
}


//===============================================================================================================
function Cleanup()
{
	run("Close All");
	run("Clear Results");
	roiManager("reset");
	run("Collect Garbage");
	setBatchMode(false);
	if (isOpen("Orig"+"_AllRoiResults.csv"))
	{
		selectWindow("Orig"+"_AllRoiResults.csv");
		run("Close");
	}
}

//===============================================================================================================
// Open File_Manual.zip ROI file  if it exist, otherwise open  File.zip
// returns 1 if Manual file exist , otherwise returns 0
function OpenExistingROIFile(baseRoiName)
{
	roiManager("Reset");
	manaulROI = baseRoiName+"_Manual.zip";
	origROI = baseRoiName+".zip";
	if (File.exists(manaulROI))
	{
		print("opening:",manaulROI);
		roiManager("Open", manaulROI);
		manualROIFound = 1;
	} else // Manual file not found, open original ROI file 
	{
		if (File.exists(origROI))
		{
			print("opening:",origROI);
			roiManager("Open", origROI);
			manualROIFound = 0;
		} else {
			print(origROI," Not found");
			exit("You need to Run the macro in *Segment* mode before running again in *Update* mode");
		}
	}
	return manualROIFound;
}

//===============================================================================================================
function SaveOverlayImage(imageName, baseSaveName, Suffix, resDir, flattenFlag)
{
	selectImage(imageName);
	roiManager("Deselect");
	roiManager("Show None");
	roiManager("Show All without labels");
	if (flattenFlag) run("Flatten");
	saveAs("Tiff", resDir+baseSaveName+Suffix);
}

