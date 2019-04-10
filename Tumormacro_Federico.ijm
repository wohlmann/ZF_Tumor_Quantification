//getting file and Dir List:
dir1 = getDirectory("Choose source directory "); 		//request source dir via window
list = getFileList(dir1);								//read file list
dir2 = getDirectory("Choose destination directory ");	//request destination dir via window
CACHE = dir2 + "CACHE" + File.separator;
File.makeDirectory(CACHE);
Dialog.create("Analysis options");
Dialog.addChoice(" Analysis Type: ", newArray("bacteria", "tumor"), "bacteria");
Dialog.addChoice(" relevant Channel: ", newArray("Automatic (2C vs. 3 C)", "C1-", "C2-","C3-","C4-"), "Automatic (2 vs. 3 C)");
Dialog.addCheckbox("set detection parameters", false);
Dialog.addCheckbox("Step-by-Step analysis", false);
Dialog.addCheckbox("use batch mode ", true);
Dialog.addCheckbox("save Quality Control Images", true);
Dialog.show;
Meth = Dialog.getChoice();
RelC = Dialog.getChoice();
ADV = Dialog.getCheckbox();
step = Dialog.getCheckbox();
batch = Dialog.getCheckbox();
QC = Dialog.getCheckbox();
if(QC==true){
	QCF = dir2 + "QC" + File.separator;
File.makeDirectory(QCF);
}
if(ADV==true){
	Dialog.create("Tresholding options");
	Dialog.addChoice("  Thresholding Method: ", newArray("Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"), "RenyiEntropy");
	Dialog.addToSameRow();
	Dialog.addCheckbox("dark background ", true);
	Dialog.addSlider("Threshold Min:", 0, 65535, 289);
	Dialog.addToSameRow();
	Dialog.addSlider("Threshold Max:", 0, 65535, 65535);
	Dialog.addMessage("_________________________________________________________________________________________");
	Dialog.addMessage("ROI detection:");
	Dialog.addCheckbox("include holes ", true);
	Dialog.addSlider("Size Min:", 0, 10000000, 50);
	Dialog.addToSameRow();
	Dialog.addSlider("Size Max:", 0, 10000000, 10000000);
	Dialog.addSlider("Circularity Min:", 0.000, 1.000, 0.001);
	Dialog.addToSameRow();
	Dialog.addSlider("Circularity Max:", 0.000, 1.000, 0.999);
	//Dialog.addMessage("_________________________________________________________________________________________");
	//Dialog.addSlider("  detection background", 1.00, 200, 80); //for later addition
	Dialog.show;
	TRm = Dialog.getChoice();
	dark = Dialog.getCheckbox();
	TRA = Dialog.getNumber();
	TRB = Dialog.getNumber();
	INC = Dialog.getCheckbox();
	if(INC==true){
		INC="include";
	}
		else{
			INC="";
		}
	PDA = Dialog.getNumber();
	PDB = Dialog.getNumber();
	if(PDB==10000000){
		PDB="infinity";
	}
	PCA = Dialog.getNumber();
	PCB = Dialog.getNumber();
	//BGmean = Dialog.getNumber();	//for later addition
}	else{
		if(Meth=="tumor"){
			TRm = "RenyiEntropy";
			dark = true;
			TRA = 289;
			TRB = 65535;
			INC = "include";
			PDA = 50;
			PDB = "infinity";
			PCA = 0.001;
			PCB = 1.000;
			//BGmean=80;			//for later addition
		}
			else if(Meth=="bacteria"){
				TRm = "RenyiEntropy";
				dark = true;
				TRA = 180;
				TRB = 65535;
				INC = "include";
				PDA = 10;
				PDB = "infinity";
				PCA = 0.001;
				PCB = 1.000;
				//BGmean=80;		//for later addition
			}
			else{
				//moar?
			}
	}
run("Close All");
print("\\Clear");
print("Reset: log, Results, ROI Manager");
run("Clear Results");
updateResults;
roiManager("reset");
while (nImages>0) {
			selectImage(nImages);
			close();
}
if (batch==true){
	setBatchMode(true);
	print("_");
	print("running in batch mode");
}
//counter for report
N=0;
IMG=0;
nImg=0;
//start loop:
print("_");
getDateAndTime(year, month, week, day, hour, min, sec, msec);
print("Starting analysis at: "+day+"/"+month+"/"+year+" :: "+hour+":"+min+":"+sec+"");
print("_");
print("analysis type = "+Meth+"");
if(ADV==true){
	print("using user defined values for Thresholding and detection");
}
print("_");
for (i=0; i<list.length; i++) {						//set i=0, count nuber of list items, enlagre number +1 each cycle, start cycle at brackets
	path = dir1+list[i];							//path location translated for code
	print("start processing of "+path+"");
	print("_");
	print("exporting images from *.lif to single *.tif files:");
	run("Bio-Formats Importer", "open=[path] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT open_all_series");
	N=N+1;
	nImg=(nImg+nImages);
	while (nImages>0) {
			selectImage(nImages);
			titleS= getTitle;
			saveAs("tif", CACHE+titleS+".tif");
			close();
			print("exported image "+titleS+"");
			print("_");
	}
	print("finished exporting single files");
	print("_");
}
listS = getFileList(CACHE);
		for (j=0; j<listS.length; j++) {
			pathS = CACHE+listS[j];
			run("Bio-Formats Windowless Importer", "open=[pathS]autoscale color_mode=Default view=[Standard ImageJ] stack_order=Default");
			title1= getTitle;
			title2 = File.nameWithoutExtension;
			IMG=IMG+1;
			print("ANALYSING IMAGE "+IMG+" of "+nImg+"");
			print("analysing image "+title1+":");
			roiManager("reset");
			selectWindow(title1);
			if(RelC=="Automatic (2C vs. 3 C)"){
				Stack.getDimensions(wi,he,ch,sl,fr);
				if(ch==3){
					Cx="C2-";
				}
					else if (ch==2){
						Cx="C1-";
					}
						else{
							exit("ERROR: invalid channel order in image "+title1+"");
						}
			}
				else{
					Cx=RelC;
				}
			print("analysing channel "+Cx+" (setting: "+RelC+")");
			print("_");
			selectWindow(title1);
			run("Split Channels");
			selectWindow(""+Cx+""+title1+"");
			run("Duplicate...", " ");
			if(step==true){
				setBatchMode("show");
				waitForUser("image"+title1+", channel to be analysed");
			}
			print("thresholding method: "+TRm+", with min "+TRA+" and max "+TRB+"");
			setAutoThreshold(""+TRm+"");
			setThreshold(TRA, TRB);
			if(dark==true){
				setOption("BlackBackground", true);
			}
			if(step==true){
				setBatchMode("show");
				waitForUser("tresholded image"+title1+"");
			}
			run("Convert to Mask");
			run("Make Binary");
			if(step==true){
				setBatchMode("show");
				waitForUser("binary for image"+title1+"");
			}
			print("ROI detection values: size="+PDA+"-"+PDB+", circularity="+PCA+"-"+PCB+"");
			run("Analyze Particles...", "size="+PDA+"-"+PDB+" circularity="+PCA+"-"+PCB+" "+INC+" add");
			if(step==true){
				setBatchMode("show");
				waitForUser("ROI image"+title1+"");
			}
			ROIc = roiManager("count");
			if (ROIc==0) {
				print("NO ROI DETECTED for image "+title1+", generating artifical Value");
				makeRectangle(100, 100, 50, 50);
				roiManager("Add");
				roiManager("select", newArray());
				run("Clear", "slice");
			}
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
			selectWindow(""+Cx+""+title1+"");
			roiManager("Select", 0);
			run("Set Measurements...", "area integrated redirect=None decimal=4");
			print("measuring");
			run("Measure");
			if(step==true){
				setBatchMode("show");
				waitForUser("measured image"+title1+"");
			}
			setResult("filename", nResults-1, title1);
			updateResults();
			if(QC == true){
				print("saving QC image");
				selectWindow(""+Cx+""+title1+"");
				run("Enhance Contrast", "saturated=0.45");
				roiManager("Select", 0);
				run("Flatten");
				saveAs("Gif", QCF+title2+"_QC_.gif");
			}
			print("_");
			while (nImages>0) {
				selectImage(nImages);
    			close();
    		}
    	}
print("saving results");
print("_");
saveAs("Results", ""+dir2+"/Results.xls");
print("deleting cache files");
print("_");
list = getFileList(CACHE);
for (i=0; i<list.length; i++) {
	ok = File.delete(CACHE+list[i]);
	ok = File.delete(CACHE);
}
//report
print("finished analysis at: "+day+"/"+month+"/"+year+" :: "+hour+":"+min+":"+sec+"");
print("_");
waitForUser("Summary"," Processed "+N+" files and "+IMG+" images. See Folder: "+dir2+"");
//JW_10.04.19
