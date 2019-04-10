run("Clear Results");
updateResults;
roiManager("reset");
while (nImages>0) {
			selectImage(nImages);
			close();
}

			Dialog.create("advanced options");
		//get values for particle detection:
		  	Dialog.addMessage(" Particle Thresholding:");
		  	Dialog.addChoice("Particle Thresholding Method: ", newArray("Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"), "Otsu");
		  	Dialog.addToSameRow();
		  	Dialog.addCheckbox("dark background ", true);
		  	Dialog.addSlider("Threshold Min:", 0, 65535, 161);
		  	Dialog.addToSameRow();
		  	Dialog.addSlider("Threshold Max:", 0, 65535, 65535);




//getting file and Dir List:
dir1 = getDirectory("Choose source directory "); 		//request source dir via window
list = getFileList(dir1);								//read file list
dir2 = getDirectory("Choose destination directory ");	//request destination dir via window
//waitForUser("Number of files","convert "+list.length+" files?\nPress Esc to abort");	//check if correct number of files
CACHE = dir2 + "CACHE" + File.separator;
File.makeDirectory(CACHE);
//counter for report
N=0;													//set # of converted images=0
IMG=0;
//start loop:
for (i=0; i<list.length; i++) {						//set i=0, count nuber of list items, enlagre number +1 each cycle, start cycle at brackets
	path = dir1+list[i];							//path location translated for code
	run("Bio-Formats Importer", "open=[path] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT open_all_series");	
	N=N+1;
	while (nImages>0) {
			selectImage(nImages);
			titleS= getTitle;
			saveAs("tif", CACHE+titleS+".tif");
			close();
	}
}
listS = getFileList(CACHE);
		for (j=0; j<listS.length; j++) {
			pathS = CACHE+listS[j];
			run("Bio-Formats Windowless Importer", "open=[pathS]autoscale color_mode=Default view=[Standard ImageJ] stack_order=Default");
			title1= getTitle;
			IMG=IMG+1;	
			roiManager("reset");
			selectWindow(title1);
			run("Split Channels");
			selectWindow("C2-"+title1+"");
			run("Duplicate...", " ");
			setAutoThreshold("RenyiEntropy dark");
			setThreshold(289, 65535);
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Analyze Particles...", "size=50-Infinity include add");
			roiManager("Select", newArray());
			ROIc = roiManager("count");
			if (ROIc!=1) {
				roiManager("select", newArray());
				roiManager("Combine");
				roiManager("Add");
			}
			ROIc = roiManager("count");
			while (ROIc!=1) {
				roiManager("select", 0);
				roiManager("delete");
				ROIc = roiManager("count");
			}
			selectWindow("C2-"+title1+"");
			roiManager("Select", 0);
			run("Set Measurements...", "area integrated redirect=None decimal=4");
			run("Measure");
			setResult("filename", nResults-1, title1);
			updateResults();
			while (nImages>0) { 
				selectImage(nImages); 
    			close(); 
    		} 
    	} 

//close all windows to clean up for next round
saveAs("Results", ""+dir2+"/Results.xls");

//report
waitForUser("Summary"," The results of "+N+" files and "+IMG+" are ready my lord");

//JW_12.03.19
