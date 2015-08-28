
#pragma rtGlobals=1		// Use modern global access method.
#Include <Concatenate waves>		//this also Includes <Strings as Lists>
//full paths on mac should start with (e.g.): "Macintosh HD:Users:katrinamacleod:Documents"
//#Include "WavetoList procs"
//#Include "kate analysis procs v2"
//#Include "GrabCursors"

#Include <Waves Average>
//#Include <ANOVA>
//#Include <AllStatsProcedures>
//  EvokTrainAnalysisProcs_v3.1
////////////////////////////////////////////////
//  Version 3:  new implementations
//  1) uses exponential decay of previous EPSC to estimate baseline.  Completed: 3 Feb 2005
//   User must make independent estimate of decay tau, then apply to analysis via panel.
//  2) reports PP and SS significant differences from initial amplitude    Completed:  jan 2005
/////This program is designed to analyze trains of responses from sets of trials plotted in one graph.  
// Assumes multiple trials and averages across trials . 
// Version 3_1:  
//   Adds double exponential fit option. 
// Version 3_2:
// FIxed bug in double expt fit;  Added option to do cumulative exp decay; updated panel design;
// button to zero trace baselines;  button to smooth traces; gray out unneeded variable controls for single expt;
// to do:  button to load dbl exponential fit parameters
// button to analyze inital psc kinetics.

menu "Kill Windows"
	"Kill Evoked Analysis Graphs & Tables",Kill_EvPSCAnalysis_Windows()
end

menu "Initialize Panels"
	"Initialize Evoked Analysis Panel",Init_extractwaves()
end

menu "Meta Analysis Macros"
	"Plot  Summary Train Data",PlotDataSS()
	"Compare Initial EPSCs across Trains",PlotInitialPSC()
	"Compare EPSCs within Trains", StatsCompareWithinTrains()
end
//
//function LoadPlotAndAverageEvRec()
////procedure to quickly load & plot sets of data (sets & trials) & do within window Averaging
//// designed for IV files, larger # of sets.   EvRec_20Nov07c1s0_A0_0
//	string ctrlname
//	string fileNameStr
//	String  totalStr
//	variable j=0
//	variable i=0
//	variable k=0
//	variable conditionStart=0
//	variable conditionEnd=5			/// "condition" here is recovery interval, indicated by suffix "_X"
//	variable trialStart  = 0			// multiple trials of same conditions, indiciated by "_AX"
//	variable 	trialNum 
//	variable	trialEnd  = 4		// catch is, have to be same # of trials each set.
//	variable setStart =4		// collect multiple sets if necessary
//	variable setEnd =4
//	string  basename = "EvPMW_11Dec09c1s"
//	string trialtag = "_A"
//	string AveBaseName="TraceAvg_s4_"
//	string TempAvgWaveName
//	string ErrorName = "errorwave"
//	variable AvgIndex=0
//	string TempWaveList=""
//	SVAR pathnameStr = root:LoadDataPanel:pathnameStr	// use path & endtag from Load panel
//	SVAR endtag   = root:LoadDataPanel:endtag
//	Dowindow/K AverageWaveOverlay
//	Display as "Average Waves"
//	Dowindow/C AverageWaveOverlay
//	
//	k=conditionStart
//	do
//		display
//		i=setStart
//		do
//			//if(i==1)
//			//	trialEnd=2
//			//endif
//			j=trialStart
//			do
//				fileNameStr=basename +num2str(i) + trialtag+ num2str(j) + "_" + num2str(k)
//				//	print "Loading " + filenameStr
//				TotalStr=pathnameStr+filenamestr+endtag
//				//LoadWave/H/A/O/Q TotalStr
//				//if (WaveExists($filenamestr))
//					appendtograph $filenamestr
//					TempWaveList+=fileNameStr+";"
//				//endif
//				j+=1
//			while(j<=trialEnd)
//		
//			i+=1
//		while(i<=SetEnd)
//		TempAvgWaveName=AveBaseName+num2str(AvgIndex)	// amending temporarily to get 2x index (0,2,4,etc)
//		fWaveAverage(TempWaveList, 1, 1, TempAvgWaveName, ErrorName)
//		AppendtoGraph /W=AverageWaveOverlay $TempAvgWaveName
//		AvgIndex+=1
//		TempWaveList=""
//	k+=1
//	while(k<=conditionEnd)
//
//
//end


proc PlotInitialPSC()
	string baseName  = "PeakStimNum_"			// each wave contains different trial's response to Stim 1, stim 2, stim 3 etc.
	string wName = ""
	Make/n=1/O  FrequencyWave
	FrequencyWave={10,33,100,143,200}
	variable numFreq = numpnts(FrequencyWave)
	variable i=0
	Dowindow/K CompareInitialPSCs
	edit 
	Dowindow/C CompareInitialPSCs
	do
		wName =baseName+"0_" + num2str(frequencyWave[i]) + "Hz"
		AppendtoTable $wName
		i+=1
	while(i<numFreq)
	Do1wayANOVAOnWindow("CompareInitialPSCs", 1, 0, 0, 0, 0)
end

proc StatsCompareWithinTrains()
	// get lists of stim waves, compare with anova & pairwise:  is there signif. PP, SS, recov?
	// do all train freq, all stimuli.
	string baseName  = "PeakStimNum_"			// each wave contains different trial's response to Stim 1, stim 2, stim 3 etc.
	string wName = ""
	variable numstim	= 11				// include recovery stimulus
	Make/N=1/O FrequencyWave
	FrequencyWave={10,33,100,143,200}
	variable numFreq = numpnts(FrequencyWave)
	variable i=0
	variable j
	string Temp_WaveList
	variable DoTukey =1
	variable DoSNK =0
	variable DoDunnett =0
	variable ControlItem =0
	variable DoLevene =0
	variable numberinList
	string WindowName
	do
		j=0
		Temp_WaveList=""
		WindowName= "AnovaReport_" + num2str(frequencyWave[i]) + "Hz"
		Dowindow/K $WindowName
		do
			wName =baseName + num2str(j) +"_" + num2str(frequencyWave[i]) + "Hz"
			Temp_WaveList+= wName +";"
			j+=1
		while(j<numStim)
		//print Temp_WaveList
		numberinList= ItemsInList(Temp_WaveList)
		if(numberinList>1)
		//	Do1wayANOVA(Temp_WaveList, DoTukey, DoSNK, DoDunnett, ControlItem, DoLevene)
			//Do1WayANOVAReport(Temp_WaveList)
			Dowindow/C $WindowName
		else
			break "Wrong number of items in list"
		endif
	
	i+=1
	while(i<numFreq)

end


proc plotDataSS()
	Make/O/n=6  SS_wave_avg, SS_wave_sd,NrmSS_avg,NrmSS_SD, unityline
	Make/O/n=1 frequencywave
	FrequencyWave={5,10,20,50,100}
	
	variable numfreq = numpnts(frequencywave)
	unityline=1
	string tempAvgStr,tempSDSTr,NormAvgStr,NormSDStr
	dowindow/K AmpStimWindow
	Display/W=(100,200,300,400) as "Average Amplitude vs Stimulus waves"
	dowindow/C AmpStimWindow
	dowindow/K NrmAmpStimWindow
	Display/W=(300,200,600,400) as "Normalized Amplitude vs Stimulus waves"
	dowindow/C NrmAmpStimWindow
	dowindow/K SS_table
	edit frequencywave,SS_wave_avg, SS_wave_sd,NrmSS_avg,NrmSS_SD
	ModifyTable format=3, digits=4,size=10,width=70,width[0]=20,format[0]=1,format[1]=1
	dowindow/C SS_table
	
	dowindow/K AvgDataTableWindow
	Display/W=(400,300,500,500) as "Avg Data Table"
	dowindow/C AvgDataTableWindow
	variable i=0
	do
		tempAvgStr="Avg_" + num2str(frequencywave[i]) + "Hz"
		tempSDSTr="SD_" + num2str(frequencywave[i]) + "Hz"
		NormAvgStr = "Nrm_"+ num2str(frequencywave[i]) + "Hz"
		NormSDStr = "NrmSD_"+ num2str(frequencywave[i]) + "Hz"
		AppendtoGraph/W=AmpStimWindow $tempAvgStr
		Duplicate /O $tempAvgStr,$NormAvgStr
		Duplicate/O $tempSDSTr,$NormSDStr
		$NormAvgStr=$NormAvgStr/$tempAvgStr[0]
		$NormSDStr=$NormSDStr/$tempSDStr[0]
		AppendtoGraph/W=NrmAmpStimWindow $NormAvgStr
		WaveSTats/Q /R=[7,9 ]$tempAvgStr     ///  Takes steady state as avg stim#7-9
		SS_wave_avg[i]=V_avg
		SS_wave_sd[i]=V_sdev
		WaveSTats/Q /R=[7,9 ]$NormAvgStr  ///  Takes steady state as avg stim#7-9
		NrmSS_avg[i]=V_avg
		NrmSS_sd[i]=V_sdev
		
		dowindow/F AvgDataTableWindow
		appendtotable $tempAvgStr,$tempSDSTr
		i+=1
	while(i<numfreq)
	Dowindow/F AmpStimWindow
	execute "ColorStyleMacro()"
	label bottom "Stimulus#"
	label left "Amplitude (nA)"
	SetAxis/A/E=1 left
	ModifyGraph mode=4
	Dowindow/F NrmAmpStimWindow
	execute "ColorStyleMacro()"
	label bottom "Stimulus#"
	label left "Relative Amplitude"
	legend /E=1/A=RC
	SetAxis/A/E=1 left
	ModifyGraph mode=4, grid(left)=1
	dowindow/K AmpSSWindow
	Display/W=(500,200,700,400) SS_wave_avg vs frequencywave as "Steady State plot"
	label bottom "Frequency (Hz)"
	SetAxis/A/E=1 bottom
	label left "Steady State Amplitude (nA)"
	SetAxis/A/E=1 left
	legend
	ModifyGraph mode=4, marker=19, Rgb=(0,0,0)
	dowindow/C AmpSSWindow
	dowindow/K NrmAmpSSWindow
	Display/W=(500,200,700,400) NrmSS_avg vs frequencywave as "NormalizedSteady State plot"
	ErrorBars NrmSS_avg Y,wave=(NrmSS_SD,NrmSS_SD)
	label bottom "Frequency (Hz)"
	SetAxis/A/E=1 bottom
	label left "Steady State Relative Amplitude"
	SetAxis/A/E=1 left
	legend
	ModifyGraph mode=4, marker=19,Rgb=(0,0,0)
	Appendtograph unityline vs frequencywave
	ModifyGraph rgb(unityline)=(2000,2000,2000), lstyle(unityline)=2
	dowindow/C NrmAmpSSWindow
	
	Dowindow/K SSLayout
	NewLayout  /P=portrait
	Dowindow/C SSLayout
	appendlayoutobject /D=1 /F=0 /R=(80,150,250,350) /T=1 graph AmpStimWindow
	appendlayoutobject /D=1 /F=0 /R=(250,150,540,350) /T=1 graph NrmAmpStimWindow
	appendlayoutobject/D=1 /F=0 /R=(80,350,250,550) /T=1 graph AmpSSWindow
	appendlayoutobject/D=1 /F=0 /R=(250,350,480,550) graph NrmAmpSSWindow
	appendlayoutobject/D=1  /R=(80,570,450,700)  table SS_table

end

function plotDataRecov()
	Make/O/n=1 frequencywave,RecoveryWave
	FrequencyWave={200}
	RecoveryWave = {10,20,30,50,100,200}
	//RecoveryWave = {10,20,30,50,100,200,500,1000,2000,4000}
	variable SEM=1			// 0, plot SD; 1, plot SEM
	variable RecoveryStimNum = 10			// which stim is Recovery?
	variable NumTrials
	variable numfreq = numpnts(frequencywave)
	variable numRecovInt  =numpnts(RecoveryWave)
	Make/O/N=(numfreq)/T  RecoveryWaveNames
	Make/O/n=(numRecovInt)  unityline
	unityline=1
		string tempAvgStr,tempSDSTr,NormAvgStr,NormSDStr, tempStr
	 tempStr = "PeakStimNum_" + num2str(RecoveryStimNum) +  "_" + num2str(frequencywave[0]) + "Hz_r" +num2str(recoveryWave[0]) +"_ac"
	 NumTrials=numpnts($tempStr)
	//print tempStr
	//print "numTrials", numTrials
	dowindow/K AmpStimWindow		// graph 1
	Display/W=(100,200,300,400) as "Average Amplitude vs Stimulus waves"
	dowindow/C AmpStimWindow
		dowindow/K NrmAmpStimWindow  // graph 2
		Display/W=(300,200,600,400) as "Normalized Amplitude vs Stimulus waves"
		dowindow/C NrmAmpStimWindow
			dowindow/K AmpRecWindow		// new graph 3
			Display/W=(500,200,700,400)  as "Recovery plot"
			dowindow/C AmpRecWindow
					dowindow/K NrmAmpRecWindow  // new graph 4
					Display/W=(500,200,700,400)  as "Normalized Recovery plot"
					//Appendtograph unityline vs RecoveryWave
					//ModifyGraph rgb(unityline)=(2000,2000,2000), lstyle(unityline)=2
					dowindow/C NrmAmpRecWindow
					
	dowindow/K Rec_table  		// table 1
	edit RecoveryWave as "Avg EPSC vs Recov Interval"
	Execute/Z "ModifyTable format=3, digits=3,size=10,width=40,width[0]=20,format[0]=1,format[1]=1"
	dowindow/C Rec_table
		dowindow/K Rec2_table  		// table 2
		edit RecoveryWave as "Nrm Avg EPSC vs Recov Interval"
		Execute/Z "ModifyTable format=3, digits=3,size=10,width=45,width[0]=20,format[0]=1,format[1]=1"
		dowindow/C Rec2_table
			Dowindow/K PeakStatsTable   // table 3
			edit  as "All Recovery Responses over trials"
			Dowindow/c PeakStatsTable
				dowindow/K AvgDataTableWindow	// table 4
				Edit as "EPSCs vs stimulus"
				dowindow/C AvgDataTableWindow
	variable initialPSC
	variable i=0
	variable j=0
	string TempRecwavNameStr1,TempRecwavNameStr2,TempRecwavNameStr3,TempRecwavNameStr4
	string TempRecwavNameStr5
	do
		j=0
		TempRecwavNameStr1= "RecovAvg_" +  num2str(frequencywave[i]) + "Hz"
		TempRecwavNameStr2= "RecovSD_" +  num2str(frequencywave[i]) + "Hz"
		TempRecwavNameStr3= "NrmRecovAvg_" +  num2str(frequencywave[i]) + "Hz"
		TempRecwavNameStr4= "NrmRecovSD_" +  num2str(frequencywave[i]) + "Hz"
		TempRecwavNameStr5= "NrmRecovSEM_" +  num2str(frequencywave[i]) + "Hz"
		Make/O/N=(numRecovInt) $TempRecwavNameStr1, $TempRecwavNameStr2,$TempRecwavNameStr3,$TempRecwavNameStr4,$TempRecwavNameStr5
		dowindow/F Rec_table
		appendtotable $TempRecwavNameStr1, $TempRecwavNameStr2
		dowindow/F Rec2_table 
		appendtotable $TempRecwavNameStr3,$TempRecwavNameStr4
		WAVE Rec_wave_avg = $TempRecwavNameStr1
		WAVE Rec_wave_sd = $TempRecwavNameStr2
		WAVE NrmRec_avg= $TempRecwavNameStr3
		WAVE  NrmRec_sd= $TempRecwavNameStr4
		WAVE  NrmRec_sem= $TempRecwavNameStr5
		do
			// if save as "Avg_200Hz_r10", etc:
			tempAvgStr="Avg_" + num2str(frequencywave[i]) + "Hz_r" +num2str(recoveryWave[j])
			tempSDSTr="SD_" + num2str(frequencywave[i]) + "Hz_r" +num2str(recoveryWave[j])
			NormAvgStr = "Nrm_"+ num2str(frequencywave[i]) + "Hz_r" +num2str(recoveryWave[j])
			NormSDStr = "NrmSD_"+ num2str(frequencywave[i]) + "Hz_r" +num2str(recoveryWave[j])
			TempStr= "PeakStimNum_" + num2str(RecoveryStimNum) +  "_" + num2str(frequencywave[i]) + "Hz_r" +num2str(recoveryWave[j])
			// if saved as "Avg_i5_r10", etc::
			//tempAvgStr="Avg_i" + num2str(1000/frequencywave[i]) + "_r" +num2str(recoveryWave[j])
			//tempSDSTr="SD_i" + num2str(1000/frequencywave[i]) + "_r" +num2str(recoveryWave[j])
			//NormAvgStr = "Nrm_i"+ num2str(1000/frequencywave[i]) + "_r" +num2str(recoveryWave[j])
			//NormSDStr = "NrmSD_i"+ num2str(1000/frequencywave[i]) + "_r" +num2str(recoveryWave[j])
			//TempStr= "PeakStimNum_" + num2str(RecoveryStimNum) +  "_i" + num2str(1000/frequencywave[i]) + "_r" +num2str(recoveryWave[j])
			//print "Finding ", tempAvgStr,tempSDSTr,NormAvgStr,NormSDStr
			 NumTrials=numpnts($tempStr)
			Dowindow/F PeakStatsTable
			appendtotable $TempStr
			AppendtoGraph/W=AmpStimWindow $tempAvgStr
			Duplicate /O $tempAvgStr,$NormAvgStr
			Duplicate/O $tempSDSTr,$NormSDStr,$TempRecwavNameStr5
			wave tempavgwv = $tempAvgStr
			wave tempsdwv = $tempSDSTr
			initialPSC=tempavgwv[0]
			Wave nwaveavg = $NormAvgStr
			wave nwavesd = $NormSDStr
			nwaveavg/=initialPSC
			nwavesd/=initialPSC
			AppendtoGraph/W=NrmAmpStimWindow $NormAvgStr
			//WaveSTats/Q /R=[9,9 ]$tempAvgStr     ///  Takes steady state as avg stim#9-9   ///// simplify?
			Rec_wave_avg[j]=tempavgwv[RecoveryStimNum]
			Rec_wave_sd[j]=tempsdwv[RecoveryStimNum]
			//WaveSTats/Q /R=[9,9 ]$NormAvgStr  ///  Takes steady state as avg stim#9-9
			NrmRec_avg[j]=nwaveavg[RecoveryStimNum]
			NrmRec_sd[j]=abs(nwavesd[RecoveryStimNum])		// remove negative value
			NrmRec_sem[j]=NrmRec_sd[j]/sqrt(NumTrials)			// calculate SEM from SD
			dowindow/F AvgDataTableWindow
			appendtotable $tempAvgStr,$tempSDSTr
			j+=1
		while(j<numRecovInt)
		Appendtograph/W=AmpRecWindow Rec_wave_avg vs RecoveryWave
		Dowindow/F NrmAmpRecWindow 
		//print "appending to graph   ", TempRecwavNameStr3
		Appendtograph NrmRec_avg  vs RecoveryWave  ///W=NrmAmpRecWindow 
		if(SEM)
		ErrorBars $TempRecwavNameStr3, Y wave=($TempRecwavNameStr5,$TempRecwavNameStr5)
		else
		ErrorBars $TempRecwavNameStr3, Y wave=($TempRecwavNameStr4,$TempRecwavNameStr4)
		endif
		i+=1
	while(i<numfreq)
  	Dowindow/F AmpStimWindow		// adjust existing graph 1
	execute "ColorStyleMacro()"
	label bottom "Stimulus#"
	label left "Amplitude (nA)"
	SetAxis/A/E=1 left
	ModifyGraph mode=4
		Dowindow/F NrmAmpStimWindow// adjust existing graph 2
		execute "ColorStyleMacro()"
		label bottom "Stimulus#"
		label left "Relative Amplitude"
		legend /E=1/A=RC
		SetAxis/A/E=1 left
	
			dowindow/F AmpRecWindow		// adjust graph 3
			label bottom "Recovery Interval (ms)"
			SetAxis/A/E=1 bottom
			label left "Recovery Amplitude (nA)"
			SetAxis/A/E=1 left
			legend 
			ModifyGraph mode=4, marker=19
			execute "ColorStyleMacro()"
				dowindow/F NrmAmpRecWindow  // adjust graph 4
				label bottom  "Recovery Interval (ms)"
				SetAxis/A/E=1 bottom
				label left "Recovery Relative Amplitude"
				SetAxis/A/E=1 left
				legend  /E=1/A=RC
				ModifyGraph mode=4, marker=19
				execute "ColorStyleMacro()"
				ModifyGraph mode=4, grid(left)=1
				if(SEM)
					textbox  /N=textbox1 "+/- SEM"
				else
					textbox  /N=textbox1 "+/- SD"
				endif
					dowindow/F Rec_Table
					Execute/Z "ModifyTable format=3, digits=3,size=10,width=90,width[0]=20,width[1]=44,format[0]=1,format[1]=1"
					dowindow/F Rec2_Table
					Execute/Z "ModifyTable format=3, digits=3,size=10,width=95,width[0]=20,width[1]=44,format[0]=1,format[1]=1"
					
					dowindow/F PeakStatsTable
					Execute/Z "ModifyTable format=3, digits=3,size=10,width=134,width[0]=20,format[0]=1"
	Dowindow/K RecLayout
	NewLayout  /P=portrait
	Dowindow/C RecLayout
	appendlayoutobject /D=1 /F=0 /R=(40,40,250,220) /T=1 graph AmpStimWindow
	appendlayoutobject /D=1 /F=0 /R=(250,40,580,220) /T=1 graph NrmAmpStimWindow
	appendlayoutobject/D=1 /F=0 /R=(40,240,250,410) /T=1 graph AmpRecWindow
	appendlayoutobject/D=1 /F=0 /R=(250,240,580,410) graph NrmAmpRecWindow
	appendlayoutobject/D=1  /R=(80,420,540,580)  table Rec_Table
	appendlayoutobject/D=1  /R=(80,580,540,740)  table Rec2_Table

end




function Do_EvokPSCAnalysis(ctrlname)	: Buttoncontrol
	string ctrlname
	Print "*******Starting Do_EvPSCAnalys at time: " + time()
	SVAR inWavebasename	=	root:Evokanalysis:inWavebasename

	SVAR subwavebase		=	root:Evokanalysis:subwavebase
	SVAR AvgWavebase=  root:Evokanalysis:AvgWavebase
	NVAR sublength				=	root:Evokanalysis:sublength
	NVAR preStim		=	root:Evokanalysis:preStim
	NVAR dobaselinesubtract = root:EvokAnalysis:dobaselinesubtract
	NVAR dobaselinefit = root:EvokAnalysis:dobaselinefit
	NVAR baselineFit_single = root:evokanalysis:baselineFit_single  //
	NVAR baselineFit_double = root:evokanalysis:baselineFit_double//
	NVAR baselineFitCheck_cumuldecay= root:evokanalysis:baselineFit_double
	variable ExpFitTau, ExptFit_Aprime, peaksDelta
	NVAR ExpFitBase_delta  =  root:EvokAnalysis:ExpFitBase_delta
	//NVAR ExpFitBase_tau  =  root:EvokAnalysis:ExpFitBase_tau
	
		NVAR ExpFitBase_tau1  =  root:EvokAnalysis:ExpFitBase_tau1//
			NVAR ExpFitBase_tau2  =  root:EvokAnalysis:ExpFitBase_tau2//
		NVAR ExpFitA1  =  root:EvokAnalysis:ExpFitA1//
			NVAR ExpFitA2  =  root:EvokAnalysis:ExpFitA2//
			variable A1,A2
	NVAR ExpFity0  = 	 root:evokanalysis:ExpFity0
	NVAR RecoveryPulseCheck = root:EvokAnalysis:RecoveryPulseCheck
	NVAR latencyEstimate	=	root:EvokAnalysis:latencyEstimate
	NVAR numStim	=root:EvokAnalysis:numStim	// probably don't need
	NVAR StimFreq	=root:EvokAnalysis:StimFreq	// probably don't need
	NVAR delayfirst	=root:EvokAnalysis:delayfirst
	nVAR  PeakDir = root:EvokAnalysis:PeakDir
	SVAR ExptTitle = root:EvokAnalysis:ExptTitle
	NVAR Baseline_x1 = root:EvokAnalysis:Baseline_x1
	NVAR Baseline_x2 = root:EvokAnalysis:Baseline_x2
	NVAR ArtifactCorrectionCheck = root:EvokAnalysis:ArtifactCorrectionCheck
	ControlInfo /W=EvokPSCAnalysisPanel DoArtifactCorrectionCheck			//force this check box
	ArtifactCorrectionCheck=V_value
	if(preStim<Baseline_x1)
		preStim=Baseline_x1
		print "Setting preStimulus acquisition time to be => baseline measure time"
	endif
	NVAR Pk_window_x1= root:EvokAnalysis:Pk_window_x1
	NVAR Pk_Window_X2= root:EvokAnalysis:Pk_Window_X2
	NVAR Pk_avg_window= root:EvokAnalysis:Pk_avg_window
	string wlist,w
	string  inWave			// basename of wave to be analyzed
	variable appendsubwaves=1
	string  appwavename		//
	variable numtrials
	variable  findpeaks
	variable WfResolution
	variable subtractln
	variable  findstart
	variable   findend
	variable tStart
	variable tEnd
	variable mnstart
	variable mnend
	variable i, j, t,mn,pkX,k
	variable pkbiggest
	// recovery step varaibles:
	variable r1,r2,dorecovery
	///
	if(ArtifactCorrectionCheck)
		print "including: correcting for Artifact"
		WAVE/Z ArtifactCorrectionWave = root:ArtifactCorrectionWave
		if( !WaveExists(ArtifactCorrectionWave) )
			Abort "You must have created an ArtifactCorrectionWave, or uncheck 'Use Artifact Correction'"
		endif
	endif
	//
	Notebook EvokedAnalysis_Log ruler=Title, text="\rStarting Train Analysis of Data from Top Graph\r"
	Notebook EvokedAnalysis_Log ruler=Normal, text ="\t" +Date() + "  " + time() + "\r\r"
	WAVE stimTimes = root:StimTimes
	string templist
	templist=ConvertNumWavetoList(StimTimes)
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tAnalyzing for " + num2str(numpnts(StimTimes)) + "  events at times: " + templist

		Notebook EvokedAnalysis_Log ruler=Normal, text="\r\t**************Analysis Parameters"
		Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tAverage output waves basename:     " + AvgWavebase
		if(dobaselinesubtract)
			Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tDoing simple baseline subtraction"
			Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tBaseline measured from:   " + num2str(baseline_x1) + " to " + num2str(baseline_x2) + " ms"
		endif
		if(dobaselinefit)
		  	Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tDoing exp baseline fit and subtraction"
		  	if(baselineFitCheck_cumuldecay)
		  		Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\t \tEstimating cumulative decays"
		  	endif
		  	if(baselineFit_single)
				Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\t\tBaseline extrapolated using single time constant tauy1:   " + num2str(ExpFitBase_tau1)  + " sec"
			else
				Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\t\tBaseline extrapolated using double time constants of tau1: " + num2str(ExpFitBase_tau1)+  "  and  tau2: " +  num2str(ExpFitBase_tau2)+ " sec"
				Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\t \tAmplitudes of  A1:" + num2str(ExpFitA1)+  "and A2: " +  num2str(ExpFitA2)

			endif
		endif	
		if(ArtifactCorrectionCheck)
			Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tDoing artifact correction"
		endif
		Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tNumber of stimuli in train    " + num2str(numStim)
		Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tStimulus frequency     " + num2str(StimFreq) + "  Hz"
		Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tLatency to peak     " + num2str(latencyEstimate)  + " ms"
		Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tPeak Direction     " + num2str(PeakDir)
		Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tPeak finding window from:  "  + num2str(Pk_window_x1) + "ms before, to " +num2str(Pk_window_x2) + "ms after" 
		Notebook EvokedAnalysis_Log ruler=Normal, text ="\r\tPeak averaged over " + num2str(Pk_avg_window) + " ms"

	///  Find input wave names from top graph:
	RemoveFromGraph/Z ShowStimTimes		// remove if already on there	
	wlist = WaveList(inWaveBasename+"*",";","WIN:")	
	//print wlist
	numtrials = Itemsinlist(wlist,";")
	w= StringFromList(0,wlist,";")
	WfResolution = Deltax($w)	// get resolution from input wave
	variable ExpFitBase_deltaPnts = ExpFitBase_delta*wfResolution
	//print "ExpFitBase_delta in points  ",  num2str(ExpFitBase_deltaPnts)
	/// Noise analysis	 - grab a section prior to first stimulus to compute noisiness in the data; for failure analysis.
	variable noise_x1= StimTimes[0]-0.006
	variable noise_x2= noise_x1+0.005
	NVAR SDcriterion	= root:EvokAnalysis:SDcriterion  // 1 for 1sd;2 for 2sd; 3 for 3sd
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tCompute Noise level from " + num2str(noise_x1) + " sec to " + num2str(noise_x2) + " of data  wave, each trial"
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tFailure criterion: " + num2str(SDcriterion) + " sd above noise"
	NVAR AltPeakFinding = root:EvokAnalysis:AltPeakFinding
	Variable LeftPos=50					// variables for positioning graph windows for this module
	Variable TopPos=80
	Variable Graph_Height=200
	variable Graph_Width = 150
	variable Graph_grout = 15
	Make/N=4/O PeakDataDisplay_pos,SubWaveDisplay_pos
	PeakDataDisplay_pos={LeftPos,TopPos,LeftPos+graph_Width,TopPos+Graph_Height}
	SubWaveDisplay_pos={LeftPos,TopPos+Graph_Height+Graph_grout,LeftPos+graph_Width,TopPos+2*Graph_Height+Graph_grout}
// graph across top left


//****** Subwave acquisition

	DoWindow/K SubWaveDisplay
	Display /W=(SubWaveDisplay_pos[0],SubWaveDisplay_pos[1],SubWaveDisplay_pos[2],SubWaveDisplay_pos[3]) as "Initial Peak Waves Display"
	DoWindow /C SubWaveDisplay
	string tempstr
	
	variable tempvar= sublength/wfResolution
	if(wfResolution==0)
		Abort "wfresolution not good"
	endif
	print sublength, wfresolution,tempvar
	Make/T/O/N=(numtrials,numstim) subWaveName
	//print "** Creating subwave Names:   "
	i=0;k=0
	do
		k=0
		w=stringfromlist(i,wlist,";")
		do
			
			tempstr= subwavebase + w  + "_" + num2str(k)
			subWaveName[i][k]= tempstr
			//print subwavename[i][k]
			Make/N= (tempvar)/O  $tempstr
			SetScale /P x, 0, WfResolution , "sec" $tempstr
			if(k==0)
			Appendtograph $tempstr		// plot only the initial response
			endif
			k+=1
		while(k<numstim)
		i+=1
	while(i<numtrials)
	ModifyGraph axisEnab(left)={0,0.5}
	Label left "Initial Peak amplitudes"
	Label Bottom "Time"
	
	string commandstr = "ColorstyleMacro()"
	Execute commandstr
	
	// plot the initial subwaves of each trial - to determine if trials are depressing response.
	string PeakbyPos_basename = "PeakStimNum_"
	string FailbyPos_basename = "FailStimNum_"
	Make/O/N=(numStim)/T	PeakbyPosition_TextWaves, FailbyPosition_TextWaves
	Dowindow/K PeakbyPositition_Table
	Edit
	Dowindow/C PeakbyPositition_Table
	i=0
	do
		PeakbyPosition_TextWaves[i]=PeakbyPos_basename + num2str(i)+ "_" + AvgWavebase
		FailbyPosition_TextWaves[i]= FailbyPos_basename+ num2str(i)+ "_" + AvgWavebase
		Make/O/N=(numtrials) $PeakbyPosition_TextWaves[i], $FailbyPosition_TextWaves[i]
		AppendtoTable $PeakbyPosition_TextWaves[i],$FailbyPosition_TextWaves[i]
		if(i==0)
			Dowindow/K PeakbyPosition_Graph
			display $PeakbyPosition_TextWaves[i]
			legend
			Dowindow/C PeakbyPosition_Graph
		else
			appendtograph $PeakbyPosition_TextWaves[i]
		endif
		i+=1
	while(i<numStim)
	Dowindow/F SubWaveDisplay
	appendtograph/w=SubWaveDisplay /L=L2/T $PeakbyPosition_TextWaves[0]
	ModifyGraph axisEnab(L2)={0.6,1},freePos(L2)=5,mode($PeakbyPosition_TextWaves[0])=3,marker($PeakbyPosition_TextWaves[0])=14
	ModifyGraph manTick(top)={0,1,0,0},manMinor(top)={0,50}
	Label top, "trial sequence"

//*****  Peak Finding Parameters & plot peak waves
	findStart = Latencyestimate -Pk_window_x1+preStim		  	// sum of baseline_length preceding stim, plus latency to peak, minus peak finding window segment
	findEnd  = Latencyestimate + Pk_Window_X2+preStim      // 1 ms after expected peak
	DoWindow/K ErrorRateDisplay
	Display /W=(PeakDataDisplay_pos[0],PeakDataDisplay_pos[1],PeakDataDisplay_pos[2],PeakDataDisplay_pos[3]) as "Error Rate Display"
	DoWindow /C ErrorRateDisplay
	DoWindow/K AvgPeakDataDisplay
	Display /W=(PeakDataDisplay_pos[0],PeakDataDisplay_pos[1]+300,PeakDataDisplay_pos[2],PeakDataDisplay_pos[3]) as "Average Peak Data Display"
	DoWindow /C AvgPeakDataDisplay
	
	DoWindow/K PeakDataDisplay
	Display /W=(PeakDataDisplay_pos[0],PeakDataDisplay_pos[1],PeakDataDisplay_pos[2],PeakDataDisplay_pos[3]) as "Peak Data Display"
	DoWindow /C PeakDataDisplay
		Dowindow /K EvokedTable1
	Edit as "Peak Values & failures"
	dowindow/C EvokedTable1

	Make/T/O/N=(numTrials) PkWaveName,F_PkWavename, abPkWavename,xPkWavename,bPkWavename
	// PkWaveName= peaks, baseline subtracted;  F_PkWavename = failures; abPkWavename = absolute peak level
	// xPkWavename= x-location of peaks;    bPkWavename= baseline level for each peak
	i=0
	do
		w=stringfromlist(i,wlist,";")
		pkwavename[i] = "Pk_" + w
		F_pkwavename[i]="fPk_" +w
		abPkWavename[i]="abPk_" + w
		xPkWavename[i]="xPk_" + w
		bPkWavename[i]="bPk_" + w
		Make/O /N=(numstim)  $pkwavename[i] ,$F_pkwavename[i],$abPkWavename[i],$xPkWavename[i],$bPkWavename[i]
		AppendtoGraph $Pkwavename[i]
		AppendtoTable $pkwavename[i] ,$F_pkwavename[i]
		//appendtoTable $abPkWavename[i],$xPkWavename[i],$bPkWavename[i]
		i+=1
	while(i<numTrials)
	Commandstr = "ColorstyleMacro()"
	Execute commandstr
	ModifyGraph mode=4,marker=15
	label Left "Peak amplitude"
	Label bottom "Stim position in train"
	ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,50}
	string pkboxtext= num2str(stimFreq) + " Hz"
	TextBox /F=0 /A=RT  pkboxtext
	string PkWavelist
	 PkWavelist=ConvertTextWavetoList(PkWavename)
	 string failuresWAvelist
	 failuresWaveList = convertTextWavetoList(f_Pkwavename)
	 
	 /////
	 Make/O/N=(numtrials) NoiseLevel
	// dowindow/K NoiseTable
	//Edit NoiseLevel as "Noise Criterion for Failure estimate"
	//DoWindow/C NoiseTable
	
	 
//*******************MAIN BODY PROGRAM	
	print "Starting main body of program; wave list :" + wlist
		if (strlen(wlist)==0)
			Abort "missing list of waves from graph; make sure graph is top window"
		endif

	i=0	
	do 			// Loop through trials
		w= StringFromList(i,wlist,";")
		//print "Starting trial # " + num2str(i)  + " now on " +  w
		if (strlen(w)==0)
			Abort "missing wave;  end of list?  terminating macro"
		endif
	
		WAVE tempInW  = $w
		duplicate/O tempInW, inw	  // duplicate so as not to alter original wave	
		if(ArtifactCorrectionCheck)
			inW-=ArtifactCorrectionWave //  subtract the wave for artifact correction up front
		endif
		//set whole wave baseline = 0				
		mn = mean(Inw, stimtimes[0]-0.01,stimtimes[0]-0.002)		// find mean values just prior to first stim artifact, between 10ms and 2 ms before
		inw -= mn						// subtract the baseline
		//print "Original Baseline for  " + w + " = " + num2str(mn)
		if(i==0)
			dowindow/K originalWaveWindow
			display $w
			dowindow/C originalWaveWindow	
		else
			appendtograph $w
		endif
	// find trial noise level by measuring sdev of  5 msbaseline segment before initial stimulus artifact	
	WaveStats/Q/R=(noise_x1,noise_x2) $w
	NoiseLevel[i]= V_sdev*SDcriterion			// account for offsest due to stim artifact
	//print Pkwavename[i]
		/// Cut inwave into subwaves	
		k=0	
		do			// Loop through stimuli	
		//print subwavename[i][k]
			//print "Trial " + num2str(i) + ", Stimulus " + num2str(k)
			WAVE sb = $(subWaveName[i][k])
			WAVE pkamps= $(Pkwavename[i])
			WAVE fpkamps=$(F_pkwavename[i])
			WAVE abPkamps = $(abPkWavename[i])
			WAVE xPkamps = $(xPkWavename[i])
			WAVE bPkamps = $(bPkWavename[i])
			Wave Pkbystim = $PeakbyPosition_TextWaves[k]
			t=stimTimes[k] -preStim				// get subwave starting at stimTime - preStim time.
			//print "     stimtime is " + num2str(t)
			//print "     point position is " + num2str(x2pnt(inW,t))
			sb = inW[p+x2pnt(inW,t)] 
			if(k==0)
				Dowindow/K Sub_window
				display sb
				Modifygraph rgb($(subWaveName[i][k]))=(21760,21760,21760)
				Dowindow/C Sub_window
			else
				appendtograph/W=Sub_window sb
				Modifygraph rgb($(subWaveName[i][k]))=(21760,21760,21760)
			endif
			//*****************// Peak finding routine.
			// use baseline-subtracted subwave
			//print "Finding peak in subwave window from " + num2str(findstart) + " to " + num2str(findend)
			Duplicate /O sb, tempSmoothsb
			Smooth  5,  tempSmoothsb
			if(PeakDir==3)
				pkX=LatencyEstimate
			else
				if(PeakDir==1)
					findpeak/B=2 /N/M=-1e-3/Q/R=(findStart,findEnd) tempSmoothsb		// negative-going peak, at least -1pA
				else
					if(PeakDir==2)
						findpeak/B=2 /M=2e-5/Q/R=(findStart,findEnd) tempSmoothsb		// positive-going peak, at least 0.02 mV
					endif
				endif
				if(V_flag)			/// if no peak is found:
					print "no peak found with findpeak;  using alternative measure"
					// variable to determine how to measure if no peak is found:  AltPeakFinding
					if(AltPeakFinding)		/// if "use latency"				
							WaveStats /Q/R=(findStart,findEnd) tempSmoothSb
						if(PeakDir==1)
							pkX= V_minLoc	// find min for negative peak finding
						else					// assume positive peak is only alternative
							pkX=V_maxLoc	// find max for positive peak finding
						endif
					else						// if "find max/min  over range"
						pkX =LatencyEstimate +preStim		
					endif	
				else
					pkX= V_PeakLoc
				endif
			endif
			////Now we can finally measure the peak (absolute, no baselinesubtraction):
			//print "Measuring peak at x= " + num2str(pkX)
			xPkamps[k]= pkX
			if(x2pnt(sb,pkX-Pk_avg_window/2 )==x2pnt(sb,pkX+Pk_avg_window/2 ))  // check that pkX+-Pk_avg_window/2 is not actually same point
				abPkamps[k]=sb[pkX]	// if it is, just take that value at Pkx
			else
				abPkamps[k]=mean(sb, pkX-Pk_avg_window/2, pkX+Pk_avg_window/2)	// take mean of 0.2-ms window
			endif
			
			//*****************// Baseline subtraction routine, simple:
			if (dobaselinesubtract)							
				mn = mean(sb, preStim-baseline_x1,preStim-baseline_x2)		// find mean values just prior to stim artifact, 
				sb-= mn						// subtract the baseline to make subwave start at baseline
				bPkamps[k]=mn			// save baseline level data
				pkamps[k] =   abPkamps[k]  - bPkamps[k] // calculate baseline subtracted peak amplitude
			endif
			//*****************// Baseline subtraction routine, exponential fit:
			if (dobaselinefit)		
				if(baselineFit_single)
					A1=1		// only uses first time constant in panel variable
					A2=0		// eliminates second exponential in equation below
				else
					A1=ExpFitA1		// otherwise use amplitudes given in panel(default 1 and 0, single expoential)
					A2=ExpFitA2
				endif
				if(k==0)
					bPkamps[k]=0		// first stim, baseline is zero
				else
					if( RecoveryPulseCheck && (k==numStim-1))  
						bPkamps[k]=mean(sb, preStim-0.0015,preStim-0.0006)	// this is probably  not necessary - expt fit/cumul fit will take care of it.
					else
						peaksDelta  = stimtimes[k]-stimtimes[k-1]  //simpler to alternative of using actual peak times:  peaksDelta  =xPkamps[k]-xPkamps[k-1] 
						if(baselineFitCheck_cumuldecay)  // calculate cumulative decay prior to this stimulus
						
							Make/O/N=(k-1) v1,v2,v3,v4
							v1=stimtimes[k] 
							v2=stimtimes[p]
							v2=v1-v2
							v3=  abPkamps[p]
							
							v4=ExpFity0+ v3*(A1* exp(-v2/ExpFitBase_tau1)  +  A2* exp(-v2/ExpFitBase_tau2) )
							bPkamps[k]   =sum(v4)
						else  // do simple decay
							bPkamps[k]   = ExpFity0+ abPkamps[k-1] *(A1* exp(-peaksDelta/ExpFitBase_tau1)  +  A2* exp(-peaksDelta/ExpFitBase_tau2) )   
						endif
					endif
				
				endif
				pkamps[k] =   abPkamps[k]  - bPkamps[k] // calculate baseline subtracted peak amplitude
				
			endif
				
				//print "	  Baseline is : " + num2str(bPkamps[k])	
				//print "      Absolute peak amplitude is :  "  + num2str(abPkamps[k])
				//print "      Baseline subtracted peak amplitude is :  "  + num2str(pkamps[k])	
				
			/////////////Determine if peak counts as an event or if it is a failure:
			if(PeakDir==1)	
				if(pkamps[k]> -abs(NoiseLevel[i]))
					fpkamps[k]=0    // note failure
				else
					fpkamps[k]=1
				endif
			else
				if(PeakDir==2)
					if(pkamps[k]< abs(NoiseLevel[i]))
						fpkamps[k]=0
					else
						fpkamps[k]=1
					endif
				else
					if(PeakDir==3)
						if(   pkamps[k]>0  &  pkamps[k]<abs(NoiseLevel[i]) )
							fpkamps[k]=0
						else
							if( pkamps[k]<0  & pkamps[k]> -abs(NoiseLevel[i]))
								fpkamps[k]=0
							else
								fpkamps[k]=1
							endif
						endif
					endif
				endif
			endif
			
			Pkbystim[i]=pkamps[k]
			k+=1
		while (k<numStim)			//  End of loop through stimuli	
	//	Dowindow/F Sub_window
	//	appendtograph abpkamps vs xPkamps
	//	appendtograph bpkamps vs xpkamps
		//ModifyGraph mode($bPkWavename[i])=3,marker($bPkWavename[i])=0, rgb($bPkWavename[i])=(0,0,65280)
		//ModifyGraph mode($abPkWavename[i])=3,marker($abPkWavename[i])=8, rgb($abPkWavename[i])=(0,0,65280)
		dowindow/F originalWaveWindow
		//duplicate/O xPkamps, origxPkamps
		xPkamps+=stimTimes-preStim			// convert xvalue from subwave x to total, original wave x.
		appendtograph abpkamps vs xPkamps
		appendtograph bpkamps vs xPkamps
		ModifyGraph mode($bPkWavename[i])=3,marker($bPkWavename[i])=0, rgb($bPkWavename[i])=(0,0,65280)
		ModifyGraph mode($abPkWavename[i])=3,marker($abPkWavename[i])=8, rgb($abPkWavename[i])=(0,0,65280)
		setaxis bottom (Stimtimes[0]-0.002), (stimtimes[numStim-1]+0.01)
		WaveStats/Q abpkamps 
		pkbiggest = min(V_min, pkbiggest)		// assumes negative peak
		setaxis left pkbiggest, 0.1
		i+=1
	while (i<numtrials)		// End of loop through trials
	
	///  Do statistical analyses:  PP and SS:
	 WAVE a_wave = $PeakbyPosition_TextWaves[0]
	WAVE b_wave = $PeakbyPosition_TextWaves[1]
	Wavestats /Q a_wave
	variable Initial_amp=V_avg
	variable Initial_sd = V_sdev
	Wavestats /Q b_wave
	variable Second_amp=V_avg
	variable Second_sd = V_sdev
	variable PP_ratio = Second_amp/Initial_amp
	//variable/C  StatComplex
	// variable PP_pvalue 
	 WAVE a_wave = $PeakbyPosition_TextWaves[0]
	WAVE b_wave = $PeakbyPosition_TextWaves[1]
	//print statTTest(0, a_wave,b_wave)
	statsTTest /Q a_wave,b_wave  //Compare first stim versus second stim, unpaired ttest. updated for 2007 igor on Mac
	//PP_pvalue = W_StatsTTest[
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\t**************Analysis results"
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tInitial PSC amplitude: " + num2str(Initial_amp) + " +- " + num2str(Initial_sd)
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tSecond PSC amplitude: " + num2str(Second_amp) + " +- " + num2str(Second_sd)
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tPaired Pulse Ratio: "  + num2str(PP_ratio) 
	//Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tPaired pulse ratio p-value ="+ num2str(PP_pvalue)
	if (numStim>2)
		
		variable LastStim
		if(RecoveryPulseCheck)
			lastStim = numStim-2
			variable RecovStim = numStim-1
		else
		 	LastStim = numStim-1
		endif
		//variable SS_pvalue 	
		WAVE c_wave = $PeakbyPosition_TextWaves[LastStim]
		Wavestats /Q c_wave
		variable Last_amp=V_avg
		variable Last_sd = V_sdev
		variable SS_ratio = Last_amp/Initial_amp
		//StatComplex =statTTest(0, a_wave,c_wave)  //Compare first stim versus last stim, unpaired ttest.
		//SS_pvalue= imag(StatComplex)
		print "Last stim is ", LastStim
		Notebook EvokedAnalysis_Log ruler=Normal, text="\r\t  Last PSC amplitude: " + num2str(Last_amp) + " +- " + num2str(Last_sd)
		Notebook EvokedAnalysis_Log ruler=Normal, text="\r\t  Last/Initial PSC Ratio: "  + num2str(SS_ratio) 
	//	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\t  Last/initial ratio p-value ="+ num2str(SS_pvalue)
		if(RecoveryPulseCheck)
			variable Recov_pvalue 
			WAVE d_wave = $PeakbyPosition_TextWaves[RecovStim]
			Wavestats /Q d_wave
			variable Recov_amp=V_avg
			variable Recov_sd = V_sdev
			variable Recov_ratio = Recov_amp/Initial_amp
			//StatComplex =statTTest(0, a_wave,d_wave)  //Compare first stim versus Recov stim, unpaired ttest.
			//Recov_pvalue= imag(StatComplex)
			//print "Recov stim is ", RecovStim
			Notebook EvokedAnalysis_Log ruler=Normal, text="\r\t    Recovery PSC amplitude: " + num2str(Recov_amp) + " +- " + num2str(Recov_sd)
			Notebook EvokedAnalysis_Log ruler=Normal, text="\r\t    Recovery/Initial PSC Ratio: "  + num2str(Recov_ratio) 
			//Notebook EvokedAnalysis_Log ruler=Normal, text="\r\t    Recovery/initial ratio p-value ="+ num2str(Recov_pvalue)
		endif	
	endif
	
	// find average of peakwaves
	Variable ErrorType=1		// 0 = none; 1 = S.D.; 2 = Conf Int; 3 = Standard Error
	Variable ErrorInterval=1// if ErrorType == 1, # of S.D.'s; ErrorType == 2, Conf. Interval
	string AveName="Avg_" + AvgWavebase
	string ErrorName="SD_" + AvgWavebase
	string FailureRateName = "FailRate_" + AvgWavebase
	string failureRateNameErr="FR_err"
	fWaveAverage(PkWavelist, 1, 1,AveName, ErrorName)			// from wavemetrics procs <Waves Average>
	Dowindow /F PeakDataDisplay
	AppendtoGraph $AveName
	ErrorBars /T=2/L=2 $AveName,Y wave=($ErrorName,$ErrorName)
	ModifyGraph mode($AveName)=4,marker($AveName)=16,rgb($AveName)=(0,0,0),lsize($AveName)=2
	Dowindow /F AvgPeakDataDisplay
	AppendtoGraph $AveName
	ErrorBars /T=2/L=2 $AveName,Y wave=($ErrorName,$ErrorName)
	ModifyGraph mode($AveName)=4,marker($AveName)=16,rgb($AveName)=(0,0,0),lsize($AveName)=2
	label Left "Peak amplitude"
	Setaxis/A/E=1 left 
	Label bottom "Stim position in train"
	ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,50}
	TextBox /F=0 /A=RT  pkboxtext
	/// Routine to determine failures
	// create: wave of failure rate vs stim position
	// plot:  failure rate vs stim position
	fWaveAverage(failuresWaveList, 1, 1,FailureRateName,failureRateNameErr)
	WAVE FRate= $FailureRateName
	FRate=(1-FRate)
	// Report Failure rates:
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tInitial PSC Failure Rate " + num2str(Frate[0])
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tSecond PSC Failure Rate " + num2str(Frate[1])
	if(numStim>2)
		Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tLast PSC Failure Rate " + num2str(Frate[lastStim])
		if(RecoveryPulseCheck)
			Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tRecovery PSC Failure Rate " + num2str(Frate[RecovStim])
		endif
	endif
	//
	Dowindow /F ErrorRateDisplay
	AppendtoGraph $FailureRateName 
	ModifyGraph mode( $FailureRateName)=4,marker( $FailureRateName)=16,rgb($FailureRateName)=(0,0,0),lsize($FailureRateName)=2
	SetAxis left 0,1
	Label left "Failure Rate"
	Label bottom "Stim position in train"
	ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,50}
	string failboxtext= "Criterion:  >" + num2str(SDcriterion) + " s.d. baseline noise"
	TextBox /F=0 /A=RT  failboxtext
	
	///  Create tables:
	DoWindow/K AverageTable
	Edit $Avename,$ErrorName,$FailureRateName as "Data Table of Averages"
	DoWindow/C AverageTable
	
	
	///Make averages of subwaves:
	string sub_avgwavenamebase = "s_avg_stim"
	string sub_avgwavename
	Dowindow/K S_avg_Display
	Display as "Average Evoked Responses, by stimulus#"
	Dowindow/C S_avg_Display
	i=0	// stim # marker
	
	do
		WAVE bPkamps = $(bPkWavename[i])
		k=0 // trial # marker  - start with first trial
		sub_avgwavename=sub_avgwavenamebase + num2str(i)	+ "_" + num2str(stimFreq) +"Hz"	// avg wave for first stimulus
		//print "Averaging for " + sub_avgWavename
		Duplicate /O $(subwavename[k][i]), $sub_avgwavename
		WAVE avgTempwave= 	$sub_avgwavename
		avgTempwave-=bPkamps[k]			// subtract baseline
		do
			k+=1
			WAVE subTempwave = $(subwavename[k][i])
			avgTempwave	+=subTempwave
		while(k<numtrials)
		//print "done stimulus " + num2str(i) + "  through trial " + num2str(k)
		avgTempwave/=k
		AppendtoGraph avgTempWave
		if(i==0)
			ModifyGraph lsize($sub_avgWavename)=2,zero=1
		endif
		i+=1
	while(i<numstim)
	Execute "ColorStyleMacro()"
	string S_avg_displaytextbox= "Average evoked responses, consecutive stimuli"
	TextBox /F=0 /A=RT  S_avg_displaytextbox
	WaveStats /Q $AveName
	if(PeakDir==1)
		Setaxis left  1.5*V_min, -0.5*V_min
	endif
	if(PeakDir==2)
		Setaxis left -0.5*V_max, 1.5*V_max
	endif
	
	///Update some graph display properties:
	DoWindow /F SubWaveDisplay
	Setaxis /A/E=1 L2
	WaveStats /Q $PeakbyPosition_TextWaves[0]
	if(PeakDir==1)
		Setaxis left  1.5*V_min, -0.5*V_min
	endif
	if(PeakDir==2)
		Setaxis left -0.5*V_max, 1.5*V_max
	endif
/////  DO layouts ready to print:
	Dowindow/F AverageTable
	Execute "ModifyTable format=3, digits=4,size=10,width=70,width[0]=20,format[0]=1"
	Dowindow/K EvokedLayout1
	NewLayout  /P=portrait/W=(40,40,350,500) as "EvokedLayout1"
	TextBox /F=0 /A=MT/x=-5/y=1  ExptTitle
	TextBox /F=0/A=MT/x=-7/y=3  AvgWAvebase
	AppendLayoutObject /D=1 /F=0 /R=(80,100,250,320) /T=1 graph SubWaveDisplay
	AppendLayoutObject /D=1 /F=0 /R=(80,320,270,480) /T=1  graph PeakDataDisplay
	AppendLayoutObject /D=1 /F=0 /R=(290,470,530,560) /T=1  graph ErrorRateDisplay
	AppendLayoutObject /D=1 /F=0 /R=(290,300,530,460) /T=1  graph avgPeakDataDisplay
	AppendLayoutObject /D=1 /F=0 /R=(280,100,530,290) /T=1  graph S_avg_Display
	AppendLayoutObject /D=1 /F=0 /R=(290,560,540,740) /T=1  table AverageTable
	Dowindow/C EvokedLayout1
	
	
	//Dowindow/K EvokedLayout2
	//NewLayout  /P=portrait/W=(200,200,600,700) as  "EvokedLayout2"
	//TextBox /F=0 /A=MT/x=-5/y=1 ExptTitle
	//AppendLayoutObject /D=1 /F=0 /R=(100,60,440,260) /T=1  table AverageTable

	//Dowindow/C EvokedLayout2
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tNumber of trials: " + num2str(numtrials)
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\r\tEnd EvokedTrainAnalysis**********************\r\r"
	
	Dowindow/F Sub_window
	dowindow/F originalWaveWindow
end				// End of 'extractwaves' macro	
//**********************************//
	
function GrabStimTimes(ctrlname) : Buttoncontrol
	string ctrlname
	string wlist, w,windowList
	SVAR inWavebasename	=	root:Evokanalysis:inWavebasename
	NVAR StartX			=	root:Evokanalysis:StartX
	NVAR EndX				=	root:Evokanalysis:EndX
	NVAR artifactLevel	=	root:EvokAnalysis:artifactLevel
	NVAR numStim	=root:EvokAnalysis:numStim	
	NVAR StimFreq	=root:EvokAnalysis:StimFreq	
	NVAR delayfirst	=root:EvokAnalysis:delayfirst
	NVAR RecoveryPulseCheck = root:EvokAnalysis:RecoveryPulseCheck
	Make/O StimTimes
	RemoveFromGraph/Z ShowStimTimes		// remove if already on there
	SetDataFolder root:
	//SetDataFolder root:EvokPMW:
	windowlist=WinList("*",";","WIN:")
	wlist = WaveList("*",";","WIN:")	
	w= StringFromList(0,wlist,";")
	if (strlen(w)==0)
		Abort "Missing waves?  make sure waves are in root folder"
	endif
	print "taking Stim times from wave" + w + "in top graph window " + wlist
	Wave stimwave = $w
	FindLevels  /D=StimTimes /M=0.0015 /N=200   /R=(startX,endX) stimwave, artifactlevel  // Stim freq must be <1kHz
	numStim=V_Levelsfound
	DelayFirst=StimTimes[0]
	if(RecoveryPulseCheck)
		StimFreq=( NumStim-2) /   ( StimTimes[numpnts(StimTimes)-2] - stimTimes[0] )
	else
		StimFreq=( NumStim-1) /   ( StimTimes[numpnts(StimTimes)-1] - stimTimes[0] )
	endif
	if(StimFreq>1)
		StimFreq=round(StimFreq)
	endif
	Make/O/N=(numStim) ShowStimTimes = ArtifactLevel	
	AppendToGraph ShowStimTimes vs stimtimes; ModifyGraph mode(showstimtimes)=3, rgb(showstimtimes)=(0,0,65000),marker(ShowStimTimes)=16
	DoWindow/K StimTimesTable
	
	Edit/W=(100,400,250,700) stimtimes
	DoWindow/C StimTimesTable
	Notebook EvokedAnalysis_Log ruler=Normal, text="\rGrabbing Stimulation Times from Top Graph"
	Notebook EvokedAnalysis_Log text="\r\tWave used to extract times:\t" + w
	Notebook EvokedAnalysis_Log text="\r\tExtracting stimuli from x =   " + num2str(Startx) + "  to " + num2str(endx) + " sec"
	Notebook EvokedAnalysis_Log text="\r\tFirst stimulus at:\t" + num2str(stimtimes[0]) + " sec"
	Notebook EvokedAnalysis_Log text="\r\tLast stimulus at:\t" + num2str(StimTimes[numpnts(StimTimes)-1]) + " sec"
	Notebook EvokedAnalysis_Log text="\r\tNumber of stimuli found:\t" + num2str(NumStim)
	Notebook EvokedAnalysis_Log text="\r\tAverage stimulus frequency:\t" + num2str(StimFreq) + "  Hz\r\r"

	
end
	
function Appendwaves(dest,basename)
	string  dest,basename
	string wlist,matchstr
	
	matchstr=basename + "*"
	wlist = WaveList(matchstr,";","")
	//print wlist
	Concatenatewavesinlist(dest, wlist)
	display /W=(200,100,720,240) $dest 
	Textbox/F=0/M/A=RB basename
end

proc MakeAverageDummies(basename)
	string basename,aa,bb,cc,dd
	
	aa="nrm_" +basename
	bb="nrmerr_" +basename
	cc="pkomean_" +basename
	dd="pkoerr_" +basename
	Make/N=15/D/O  $aa,$bb,$cc,$dd
	$aa=0;$bb=0;$cc=0;$dd=0
	
end



	
	
Macro Init_extractwaves()
	silent 1;
	string dfsave=getDataFolder(1)
	NewDataFolder /O/S root:EvokAnalysis
	KillWaves/a/z
	Killvariables /a/z
	killstrings /a/z
	string cellnum			//
	string setnum			// 
	string/G inWavebasename	= ""	//
	string /G subwavebase	:= "s_" + inWavebasename	// basename for subwaves
	variable/G StimFreq	= 1	// probably don't need
	string /G AvgWavebase := num2str(StimFreq) + "Hz"   
	variable /G sublength	=	0.015
	variable /G preStim = 0.005		// length of trace to acquire prior to stimulus (instead of using baseline)
	variable /G dobaselinesubtract	=	0
	variable /G dobaselinefit  =1		//intialize to use baseline exp fit
	variable /G baselineFit_single=1			// initialize to use single exp fit
	variable /G baselineFit_double=0	// initialize to not use double
	variable /G baselineFit_cumuldecay=0	// initialize to not use cumulative decay
	variable /G ExpFitA1 = 1		// default to 1 for single exp
	variable /G ExpFitA2	= 0		// default to 0 for single exp
	variable /G ExpFity0  =0.01	// offset variable for double exp
	variable /G StartX	=	0.597
	variable /G EndX	=	10		// option to go to end of wave without error
	variable /G artifactLevel	=	0.1		// in nA
	variable /G latencyEstimate	=	0.002		// in sec
	variable/G numStim		//
	string /G ExptTitle 
	variable/G delayfirst
	variable /G PeakDir		=	1
	string/G PeakDirPopStr	=	"Negative Pk; Positive Pk; no peak"
	// simple baseline subtraction parameters:
	variable/G Baseline_x1 = 0.0004		// sec prior to stim artifact to start baseline measure
 	variable/G Baseline_x2 = 0.0002	// sec prior to stim artifact to end baseline measure
	// exp fit baseline subtraction parameters:
	variable /G ExpFitBase_delta  = 0.001		// time after EPSC peak to fit expt function for extrapolating baseline
	variable/G ExpFitBase_tau1 = 0.0002
	variable/G ExpFitBase_tau2 = 0.001
	// peak finding
	variable/G Pk_window_x1=0.0003	// sec prior to peak latency estimate to start peak find window
	variable/G Pk_Window_X2= 0.0011	// sec after peak latency estimate to end peak find window
	variable/G Pk_avg_window=0.0002		//  sec over which to average the peak measure
	variable /G RecoveryPulseCheck = 0			// 0, unchecked if no recovery pulse; 1, check, if there is a recovery pulse (assumes it is last stim)
	variable /G SDcriterion	= 3  // for failure analysis; noise level to beat: 1 for 1sd;2 for 2sd; 3 for 3sd
	variable /G AltPeakFinding = 0	// choice of method to measure 'peak' amplitude if peak finding fails.
	variable /G ArtifactCorrectionCheck = 0	// Whether to use artifact correction
	DoWindow /K EvokPSCAnalysisPanel
	
		// Create Notebook for all parameters:
	DoWindow/K EvokedAnalysis_Log
	
	///Prompt for  title for layouts:
	Execute "GetTitle()"
	//
	NewNotebook/N=EvokedAnalysis_Log/F=1/V=1/W=(75,130,522,358) as "Evoked Analysis Log "
	Notebook EvokedAnalysis_Log defaultTab=36, statusWidth=238,pageMargins={72,72,72,72}
	Notebook EvokedAnalysis_Log showruler=0,rulerUnits=1,updating={1,216000}
	Notebook EvokedAnalysis_Log newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={16,32,400+3*8192,450+8192*2}, rulerDefaults={"Geneva",10,0,(0,0,0)}
	Notebook EvokedAnalysis_Log newRuler=TabRow, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={16,32,80,100,148}, rulerDefaults={"Geneva",10,0,(0,0,0)}
	Notebook EvokedAnalysis_Log newRuler=TextRow, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={16,32,450+8192*2}, rulerDefaults={"Geneva",10,0,(0,0,0)}
	Notebook EvokedAnalysis_Log newRuler=ImageRow, justification=1, margins={0,0,468}, spacing={0,0,0}, tabs={16,32,450+8192*2}, rulerDefaults={"Geneva",10,0,(0,0,0)}
	Notebook EvokedAnalysis_Log newRuler=Title, justification=0, margins={0,0,538}, spacing={0,0,0}, tabs={}, rulerDefaults={"Helvetica",18,0,(0,0,0)}
	Notebook EvokedAnalysis_Log ruler=Title, text="Starting up the Evoked Analysis software :  EvokTrainAnalysisProcs_v3\r"
	Notebook EvokedAnalysis_Log ruler=Normal, text="\r\tDate: "+Date()+"\r"
	Notebook EvokedAnalysis_Log text="\tTime: "+Time()+"\r\r"
	Execute "EvokPSCAnalysisPanel()"
	 SetDataFolder dfsave
end

function GetTitle()
	String GetTitleStr
	SVAR ExptTitle= root:EvokAnalysis:ExptTitle
	GetTitleStr=ExptTitle
	Prompt  GetTitleStr,"Enter Title String for Labelling Graphs & Layouts"
	DoPrompt "", GetTitleStr
	ExptTitle=GetTitleStr
end

Window EvokPSCAnalysisPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(987,61,1574,727)
	ModifyPanel cbRGB=(49151,65535,65535)
	ShowTools
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (16385,65535,65535)
	DrawRect 11,134,547,197
	SetDrawEnv fillfgc= (16385,65535,65535)
	DrawRect 11,199,547,232
	SetDrawEnv fillfgc= (16385,65535,65535)
	DrawRect 12,236,550,405
	SetDrawEnv fillfgc= (16385,65535,65535)
	DrawRect 11,564,547,606
	SetDrawEnv fillfgc= (16385,65535,65535)
	DrawRect 11,411,549,560
	SetDrawEnv fillfgc= (49151,65535,49151)
	DrawRRect 42,6,520,30
	SetDrawEnv fsize= 14
	DrawText 118,26,"Evoked response analysis  v. 3_3"
	SetDrawEnv fillfgc= (16385,65535,65535)
	DrawRect 11,36,531,131
	SetDrawEnv fname= "Arial Black"
	DrawText 20,155,"Wave Selection & subselection"
	SetDrawEnv fsize= 10
	DrawText 40,98,"Results:"
	DrawText 208,263,"Simple Subtraction"
	SetDrawEnv fname= "Arial Black"
	DrawText 19,435,"Peak Measurements"
	DrawText 316,475,"Peak finding windows:"
	SetDrawEnv fname= "Arial Black"
	DrawText 19,593,"Failure Analysis Criterion"
	SetDrawEnv fname= "Arial Black"
	DrawText 21,226,"Artifact correction"
	SetDrawEnv fname= "Arial Black"
	DrawText 56,264,"Baseline Subtraction"
	SetDrawEnv fname= "Arial Black"
	DrawText 18,59,"Extract Stimulus Times"
	SetDrawEnv fname= "Arial Black"
	DrawText 54,312,"Exp Decay Subtraction"
	SetVariable SubWaveLengthSetVar,pos={23,157},size={188,16},title="Length of subwave (sec)"
	SetVariable SubWaveLengthSetVar,limits={0.01,1,0.02},value= root:EvokAnalysis:sublength
	SetVariable InWaveBasename,pos={225,141},size={300,16},title="Input waves from top graph matching:"
	SetVariable InWaveBasename,limits={-inf,inf,0},value= root:EvokAnalysis:inWavebasename
	SetVariable SubwavebasenameSetVar,pos={219,158},size={170,16},title="Sub wave basename"
	SetVariable SubwavebasenameSetVar,limits={-inf,inf,0},value= root:EvokAnalysis:subwavebase
	Button GetTimesButton,pos={377,42},size={109,31},proc=GrabStimTimes,title="Get stim times"
	SetVariable ArtLevelSetVar,pos={208,44},size={132,16},title="Artifact Level"
	SetVariable ArtLevelSetVar,value= root:EvokAnalysis:artifactLevel
	SetVariable StartXSetVar,pos={68,65},size={136,16},title="From x1 (sec)"
	SetVariable StartXSetVar,limits={0,30,0.1},value= root:EvokAnalysis:StartX
	SetVariable EndXSetVar,pos={215,65},size={124,16},title="to x2 (sec) "
	SetVariable EndXSetVar,limits={0.01,30,0.1},value= root:EvokAnalysis:EndX
	SetVariable LatencyEstSetVar,pos={28,502},size={209,16},title="Estimate of synaptic latency"
	SetVariable LatencyEstSetVar,limits={0.0001,0.1,0.0002},value= root:EvokAnalysis:latencyEstimate
	CheckBox baselineSubCheck,pos={31,247},size={21,14},proc=ToggleBaselineSubProc,title=" "
	CheckBox baselineSubCheck,value= 0
	Button DoAnalysisButton,pos={23,611},size={124,50},proc=Do_EvokPSCAnalysis,title="Go"
	ValDisplay NumStimValDisp,pos={46,107},size={77,14},title="# stimuli"
	ValDisplay NumStimValDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay NumStimValDisp,value= #" root:EvokAnalysis:numStim"
	ValDisplay firstStimdelay,pos={133,107},size={136,14},title="First Stim is at x:"
	ValDisplay firstStimdelay,limits={0,0,0},barmisc={0,1000}
	ValDisplay firstStimdelay,value= #" root:EvokAnalysis:delayFirst"
	ValDisplay StimFreq,pos={279,107},size={131,14},title="Ave train frequency"
	ValDisplay StimFreq,limits={0,0,0},barmisc={0,1000}
	ValDisplay StimFreq,value= #" root:EvokAnalysis:StimFreq"
	PopupMenu PeakDirPopup,pos={37,438},size={96,21},proc=UpdatePeakDir
	PopupMenu PeakDirPopup,mode=1,popvalue="Negative Pk",value= #"root:EvokAnalysis:PeakDirPopStr"
	SetVariable setvar0,pos={53,269},size={227,16},title="Start, sec prior to stim"
	SetVariable setvar0,limits={-1,1,0.001},value= root:EvokAnalysis:Baseline_x1
	SetVariable setvar1,pos={293,268},size={227,16},title="End, sec prior to stim   "
	SetVariable setvar1,limits={-1,1,0.0001},value= root:EvokAnalysis:Baseline_x2
	SetVariable setvar2,pos={24,463},size={267,16},title="Start, sec prior to expected peak latency"
	SetVariable setvar2,limits={0,0.1,0.0001},value= root:EvokAnalysis:Pk_window_x1
	SetVariable setvar3,pos={27,484},size={267,16},title="End, sec after expected peak latency     "
	SetVariable setvar3,limits={0,0.1,0.0005},value= root:EvokAnalysis:Pk_Window_X2
	SetVariable setvar4,pos={311,483},size={194,16},title="Averaging window, sec"
	SetVariable setvar4,limits={1e-05,0.1,0.0001},value= root:EvokAnalysis:Pk_avg_window
	SetVariable setvar5,pos={193,429},size={231,16},title="Pk_average Wave Basename"
	SetVariable setvar5,fSize=10,fStyle=1,value= root:EvokAnalysis:AvgWavebase
	CheckBox RecovPulseCheck,pos={276,87},size={153,14},proc=RecovPulseCheckProc,title="Is last stim a recovery pulse?"
	CheckBox RecovPulseCheck,value= 0
	PopupMenu popup0,pos={201,580},size={178,21},proc=SDCriterionPopMenuProc,title="greater than #SD noise"
	PopupMenu popup0,mode=3,popvalue="3 s.d.",value= #"\"1 s.d.;2 s.d.;3 s.d.\""
	PopupMenu AltPeakFindingPopUp,pos={100,532},size={229,21},proc=AltPkFindPopMenuProc,title="Alt. Method of pk measure "
	PopupMenu AltPeakFindingPopUp,mode=1,popvalue="Use Latency",value= #"\"Use Latency; Find min/max in pk find window\""
	SetVariable PreStimSetVAr,pos={23,176},size={187,16},title="Acquire secs before stim"
	SetVariable PreStimSetVAr,limits={0.001,1,0.001},value= root:EvokAnalysis:preStim
	Button GetArtifactSub_Button,pos={177,209},size={158,16},proc=Artifact_CreateSubtractionWave,title="Calculate Artifact Wave"
	CheckBox DoArtifactCorrectionCheck,pos={143,211},size={16,14},proc=Artifact_CorrCheckProc,title=""
	CheckBox DoArtifactCorrectionCheck,value= 0
	CheckBox baselineFitCheck,pos={27,297},size={16,14},proc=ToggleBaselineFitProc,title=""
	CheckBox baselineFitCheck,value= 1
	SetVariable ExpFitBaseTauSetVar,pos={206,320},size={130,16},title="Exp Fit tau 1"
	SetVariable ExpFitBaseTauSetVar,labelBack=(65535,65535,65535)
	SetVariable ExpFitBaseTauSetVar,limits={0.0001,1,0.0005},value= root:EvokAnalysis:ExpFitBase_tau1
	CheckBox baselineFitCheck_double,pos={117,322},size={73,14},proc=ToggleDoubleFitProc,title="Double Exp"
	CheckBox baselineFitCheck_double,value= 1
	SetVariable ExpFitBaseTauSetVar2,pos={208,342},size={130,16},title="Exp Fit tau 2"
	SetVariable ExpFitBaseTauSetVar2,labelBack=(65535,65535,65535),fStyle=0
	SetVariable ExpFitBaseTauSetVar2,limits={0.0001,1,0.0005},value= root:EvokAnalysis:ExpFitBase_tau2
	CheckBox baselineFitCheck_single,pos={47,322},size={69,14},proc=ToggleSingleFitProc,title="SIngle Exp"
	CheckBox baselineFitCheck_single,value= 0
	SetVariable ExpFitA1SetVar,pos={350,319},size={73,16},title="A1"
	SetVariable ExpFitA1SetVar,labelBack=(65535,65535,65535),fStyle=0
	SetVariable ExpFitA1SetVar,value= root:EvokAnalysis:ExpFitA1
	SetVariable ExpFitA2SetVar,pos={350,340},size={73,16},title="A2"
	SetVariable ExpFitA2SetVar,labelBack=(65535,65535,65535),fStyle=0
	SetVariable ExpFitA2SetVar,value= root:EvokAnalysis:ExpFitA2
	SetVariable ExpY0_setVar,pos={436,320},size={78,16},title="y0"
	SetVariable ExpY0_setVar,labelBack=(65535,65535,65535),fStyle=0
	SetVariable ExpY0_setVar,value= root:EvokAnalysis:ExpFity0
	CheckBox baselineFitCheck_cumuldecay,pos={47,339},size={152,14},proc=ToggleCumulDecayProc,title="Cumulative decay estimation"
	CheckBox baselineFitCheck_cumuldecay,value= 1
	Button buttonZerobaselines,pos={233,174},size={148,18},proc=EvAnalysis_ZeroBaseline,title="Zero Wave Baselines"
	Button buttonSmooth,pos={396,174},size={118,19},proc=EvAnalysis_Smooth,title="Smooth Waves"
	Button NewArtifactCorrectionButton,pos={355,206},size={180,20},proc=Artifact_RecreateCorrection,title="Update w/ New Stim Times"
	Button NewArtifactCorrectionButton,fSize=11
	Button buttonTraceAverage,pos={36,371},size={148,18},proc=AverageWavesInWindowButton,title="Trace Average"
	Button buttonStdEPSC,pos={198,372},size={148,18},proc=ExtractStdPSCButton,title="Create EPSC Standard"
	Button buttonLoadExpParam,pos={363,372},size={148,18},proc=EnterDblExpValues,title="Enter Dbl Exp Params"
EndMacro

Function ArtCorrCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR ArtifactCorrectionCheck = root:evokanalysis:artifactCorrectionCheck
	ArtifactCorrectionCheck=checked
	print "Art Corr Check = " + num2str(ArtifactCorrectionCheck)
End

Function ToggleBaselineSubProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR dobaselinesubtract = root:evokanalysis:dobaselinesubtract
	NVAR dobaselinefit = root:evokanalysis:dobaselinefit
	dobaselinesubtract=checked
	if(dobaselinesubtract)
		print "Do simple baseline subtraction " 
		dobaselinefit=0			// uncheck baselinefit variable
	else
		print "Do baseline exp fit  " 
		dobaselinefit=1			// uncheck baselinefit variable
	endif
	Checkbox baselineFitCheck, value=dobaselinefit
End


Function ToggleBaselineFitProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR dobaselinefit = root:evokanalysis:dobaselinefit
	NVAR dobaselinesubtract = root:evokanalysis:dobaselinesubtract
	dobaselinefit=checked
	if(dobaselinefit)
		print "Do baseline exp fit  " 
		dobaselinesubtract=0			// uncheck baselinefit variable	
	else
		print "Do simple baseline subtraction" 
		dobaselinesubtract=1			// uncheck baselinefit variable
	endif
	Checkbox baselineSubCheck, value=dobaselinesubtract
End
 
function UpdatePeakDir(ctrlname,popnum,popstr) : PopupMenucontrol
	string ctrlname
	variable popnum
	string popstr
	NVAR PeakDir = root:EvokAnalysis:PeakDir
	PeakDir=popnum
end


Function RecovPulseCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR RecoveryPulseCheck = root:EvokAnalysis:RecoveryPulseCheck
	RecoveryPulseCheck=checked
End



Function SDCriterionPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR SDCriterion = root:EvokAnalysis:SDcriterion
	print num2str(popnum)
	SDcriterion = popNum

End

Function AltPkFindPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR AltPeakFinding = root:EvokAnalysis:AltPeakFinding
	AltPeakFinding = popNum-1
	
End


function PlotSubwaves(ctrlname) : Buttoncontrol
	string ctrlname
	NVAR numStim
	NVAR numtrials
	WAVE subwavename
end



function Kill_EvPSCAnalysis_Windows()
	Dowindow/K  S_avg_Display
	Dowindow/K AverageTable
	Dowindow/K EvokedTable1
	Dowindow/K NoiseTable
	Dowindow/K ErrorRateDisplay
	Dowindow/K AvgPeakDataDisplay
	Dowindow/K PeakDataDisplay
	Dowindow/K SubWaveDisplay
	Dowindow/K StimTimesTable
	DoWindow/K Evokedlayout1
	DoWindow/K Evokedlayout2
	Dowindow/K PeakbyPositition_Table
	Dowindow/K PeakbyPosition_Graph
	Dowindow/K originalWaveWindow
	Dowindow/K Sub_window
		Dowindow/k ArtifactCorrectionWaveDisplay
	Dowindow/k StimTimespulseDisplay
	Dowindow/K ShowTempArtifact
end




//////////////////  Artifact correction  routines:
////need data file in top window
/// need preselected artifact wave (average of waves that failed) what if there were no failures?
// artifact wave should be x-scaled around zero at the artifact onset (same as in Do Evoked; from Stimtimes)
// convolve that artifact wave with the wave below which is a StimTimes pulse wave
function Artifact_CreateSubtractionWave(ctrlname): buttoncontrol
	string ctrlname
	variable whichStim=1
	variable lengthPrePost=0.005
	Prompt whichStim,"Make sure selected set of data waves are in top Graph;Enter Stimulus # to use to calculate artifact:"
	Prompt lengthPrePost,"#seconds before & after Stimulus to include:"
	DoPrompt "Enter parameters to calculate Artifact Correction Wave", whichStim,lengthPrePost
	if(V_flag)
		return -1			// user cancelled
	endif
	//PromptforArtifactParams(whichStim,lengthPrePost)
	string wlist,w,windowlist,mywindow
	variable i=0,j=0
	string ArtKernalWaveName="Artifact_Kernel"
	//String ArtCorrWaveName = "ArtifactCorrectionWave"
	WAVE stimtimes = root:stimtimes
	windowlist=WinList("*",";","WIN:1")
	mywindow=StringFromList(0, windowlist, ";"  )
	wlist=Wavelist("*",";","WIN:")
	w=Stringfromlist(0,wlist,";")
	
	duplicate/O $w, StimTimesPulseWave
	StimTimesPulseWave=0
	do 
		j=Stimtimes[i]
		StimTimesPulseWave[x2pnt(StimTimesPulseWave,j)]=1
		i+=1
	while(i<numpnts(StimTimes))
	Dowindow/k StimTimespulseDisplay
	Display StimTimesPulseWave as "Stim Times pulse wave"
	Dowindow/C StimTimespulseDisplay
	Artifact_GetKernal(wlist,StimTimes[whichStim],lengthPrePost,ArtKernalWaveName)	// use this list, stimtime, & buffer pre/post length to calculate the stim artifact model
	duplicate/O StimTimesPulseWave, ArtifactCorrectionWave
	Convolve/A $ArtKernalWaveName, ArtifactCorrectionWave
	Dowindow/k ArtifactCorrectionWaveDisplay
	Display ArtifactCorrectionWave as "Artifact Correction Wave"
	Dowindow/C ArtifactCorrectionWaveDisplay
	Dowindow/F $mywindow
	RemoveFromgraph/Z ArtifactCorrectionWave
	Appendtograph ArtifactCorrectionWave
	ModifyGraph rgb(ArtifactCorrectionWave)=(3,52428,1)
	TextBox/C/N=text0/F=0/A=MT/E "\\K(3,52428,1)Artifact Correction Wave"
	Print "*****Calculated Artifact Correction Wave  named: ArtifactCorrectionWave "
	print "     using waves  from top window " +mywindow + " :  \r" + wlist
end

function Artifact_RecreateCorrection(ctrlname): buttoncontrol
	string ctrlname
	//variable whichStim=1
//	variable lengthPrePost=0.005
//	Prompt whichStim,"Make sure selected set of data waves are in top Graph;Enter Stimulus # to use to calculate artifact:"
//	Prompt lengthPrePost,"#seconds before & after Stimulus to include:"
//	DoPrompt "Enter parameters to calculate Artifact Correction Wave", whichStim,lengthPrePost
//	if(V_flag)
//		return -1			// user cancelled
//	endif
	//PromptforArtifactParams(whichStim,lengthPrePost)
//	string wlist,w,windowlist,mywindow
	variable i=0,j=0
	string ArtKernalWaveName="Artifact_Kernel"
	//String ArtCorrWaveName = "ArtifactCorrectionWave"
	WAVE stimtimes = root:stimtimes
//	windowlist=WinList("*",";","WIN:1")
//	mywindow=StringFromList(0, windowlist, ";"  )
//	wlist=Wavelist("*",";","WIN:")
//	w=Stringfromlist(0,wlist,";")
	
	//duplicate/O $w, StimTimesPulseWave
	WAVe  StimTimesPulseWave
	
	StimTimesPulseWave=0
	do 
		j=Stimtimes[i]
		StimTimesPulseWave[x2pnt(StimTimesPulseWave,j)]=1
		i+=1
	while(i<numpnts(StimTimes))
//	Dowindow/k StimTimespulseDisplay
//	Display StimTimesPulseWave as "Stim Times pulse wave"
//	Dowindow/C StimTimespulseDisplay
//	GetstimArtifactModel(wlist,StimTimes[whichStim-1],lengthPrePost,ArtKernalWaveName)	// use this list, stimtime, & buffer pre/post length to calculate the stim artifact model
	duplicate/O StimTimesPulseWave, ArtifactCorrectionWave
	Convolve/A $ArtKernalWaveName, ArtifactCorrectionWave
	Dowindow/k ArtifactCorrectionWaveDisplay
	Display ArtifactCorrectionWave as "Artifact Correction Wave"
	Dowindow/C ArtifactCorrectionWaveDisplay
	legend
	Print "*****Re-Calculated Artifact Correction Wave with updatad Stimtimes  named: ArtifactCorrectionWave "
	//print "     using waves  from top window " +mywindow + " :  \r" + wlist
end


function Artifact_Prompt()
	variable whichStim=1
	variable lengthPrePost=0.005
	Prompt whichStim,"Enter Stimulus # to use to calculate artifact:"
	Prompt lengthPrePost,"#seconds before & after Stimulus to include:"
	DoPrompt "Enter parameters to calculate Artifact Correction Wave; make sure selected set of data waves are in top Graph", whichStim,lengthPrePost
	
end



function Artifact_GetKernal(wlist,whichStimTime,lengthPrePost,AveName)
	string wlist
	variable whichStimTime
	variable lengthPrePost
	string AveName
	
	variable baseline,deltx
	Variable ErrorType=0	// 0 = none; 1 = S.D.; 2 = Conf Int; 3 = Standard Error
	Variable ErrorInterval=1// if ErrorType == 1, # of S.D.'s; ErrorType == 2, Conf. Interval
	string ErrorName="" 
	fWaveAverage(wlist, ErrorType, ErrorInterval,AveName, ErrorName)			// from wavemetrics procs <Waves Average>
	CropOneWave(AveName,whichStimTime-lengthPrePost,whichStimTime+lengthPrePost)	// crop around chosen stimtime
	WAVE temp=$AveName
	//Smooth 1, temp				// gaussian smooth once
	//baseline=mean(temp,lengthPrePost-0.003,lengthPrePost-0.0015)
	//print "baseline subtraction " + num2str(baseline)
	//temp-=baseline				// subtract a baseline
	deltx = deltax(temp)	// get delta x scaling
	SetScale/P x -lengthPrePost,deltx,"", temp	// rescale to make wave symetrical around zero
	Dowindow/K ShowTempArtifact
	Display $AveName as "Artifact Kernal"
	Dowindow/C ShowTempArtifact
	
end


Function ToggleSingleFitProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR baselineFit_single = root:evokanalysis:baselineFit_single
	NVAR baselineFit_double = root:evokanalysis:baselineFit_double
	baselineFit_single=checked
	if(baselineFit_single)
		print "Do single exp fit  " 
		baselineFit_double=0			// uncheck baselineFit_double variabl
		SetVariable ExpFitBaseTauSetVar2 disable=2, fstyle=2,labelBack=(43690,43690,43690)  // gray out these variables - clearly not used.
		SetVariable ExpFitA1SetVar disable=2, fstyle=2,labelBack=(43690,43690,43690)
		SetVariable ExpFitA2SetVar disable=2, fstyle=2,labelBack=(43690,43690,43690)
		SetVariable ExpY0_setVar disable=2, fstyle=2,labelBack=(43690,43690,43690)
	else
		print "Do double exp fit" 
		baselineFit_double=1			// uncheck baselineFit_single variable	
		SetVariable ExpFitBaseTauSetVar2 disable=0,fstyle=0,labelBack=(65535,65535,65535)  // re-enable   these variables -
		SetVariable ExpFitA1SetVar disable=0,fstyle=0,labelBack=(65535,65535,65535)
		SetVariable ExpFitA2SetVar disable=0,fstyle=0,labelBack=(65535,65535,65535)
		SetVariable ExpY0_setVar disable=0,fstyle=0,labelBack=(65535,65535,65535)
	endif
	Checkbox baselineFitCheck_double, value=baselineFit_double  // uncheck double checkbox
End


Function ToggleDoubleFitProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR baselineFit_single = root:evokanalysis:baselineFit_single
	NVAR baselineFit_double = root:evokanalysis:baselineFit_double
	baselineFit_double=checked
	if(baselineFit_double)
		print "Do double exp fit  " 
		baselineFit_single=0			// uncheck baselineFit_single variable	
		SetVariable ExpFitBaseTauSetVar2 disable=0,fstyle=0,labelBack=(65535,65535,65535)  // re-enable   these variables -
		SetVariable ExpFitA1SetVar disable=0,fstyle=0,labelBack=(65535,65535,65535)
		SetVariable ExpFitA2SetVar disable=0,fstyle=0,labelBack=(65535,65535,65535)
		SetVariable ExpY0_setVar disable=0,fstyle=0,labelBack=(65535,65535,65535)
	else
		print "Do single exp fit" 
		baselineFit_single=1			// check baselineFit_double variable
		SetVariable ExpFitBaseTauSetVar2 disable=2, fstyle=2,labelBack=(43690,43690,43690)  // gray out these variables - clearly not used.
		SetVariable ExpFitA1SetVar disable=2, fstyle=2,labelBack=(43690,43690,43690)
		SetVariable ExpFitA2SetVar disable=2, fstyle=2,labelBack=(43690,43690,43690)
		SetVariable ExpY0_setVar disable=2, fstyle=2,labelBack=(43690,43690,43690)
	endif
	Checkbox baselineFitCheck_single, value=baselineFit_single	// uncheck single checkbox
End

Function ToggleCumulDecayProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR baselineFit_cumuldecay = root:evokanalysis:baselineFit_cumuldecay
	baselineFit_cumuldecay=checked
	if(baselineFit_cumuldecay)
		print "estimating cumulative decay for baseline fitting " 
		
	else
		print "simple decay for baseline fitting" 
	endif

End


function EvAnalysis_ZeroBaseline(ctrlName)	: ButtonControl	// zero baseline just prior to first stim
		String ctrlName
	string wlist, wn
	variable  index=0,m
	NVAR startX = root:evokanalysis:StartX
	wlist=WaveList("Ev*",";","WIN:")	
	do
		wn=Stringfromlist(index,wlist,";")		
		if (strlen(wn)==0)
			break
		endif
		WAVE w=$wn
		m=mean($wn,(StartX-0.001),StartX)
		w -=m
		index +=1
	while(1)	
end


function EvAnalysis_Smooth(ctrlName)	: ButtonControl	// binomial smoothing of waves, level 5; bounce; overwrite source
		String ctrlName
	string wlist, wn
	variable  index=0,m
	
	wlist=WaveList("Ev*",";","WIN:")	
	do
		wn=Stringfromlist(index,wlist,";")		
		if (strlen(wn)==0)
			break
		endif
		WAVE w=$wn
		
		Smooth  5,w  
		index +=1
	while(1)	
end

function AverageWavesInWindowButton(ctrlname) : Buttoncontrol
	string ctrlname
	SVAR AvgWavebase=  root:Evokanalysis:AvgWavebase
	string  destName = "TraceAvg_" + AvgWavebase
	string wn, w1
	variable index =0		
	w1 = WaveList("*",";","WIN:")			
	wn = GetStrFromList(w1, 0, ";")
	Duplicate /O $wn, $destName		
	Wave dest = $destName
	dest = 0
		
	do
		wn = GetStrFromList(w1,index,";")
		if (strlen(wn) == 0)
			break
		endif
		Wave source = $wn
		dest += source
		index += 1
	while (1)
	dest /= index
	DoWindow /K AvgTraceWindow 
	Display dest as "Average Trace"
	DoWindow/C AvgTraceWindow
end

function ExtractStdPSCButton(ctrlname) : Buttoncontrol
	string ctrlname
	SVAR AvgWavebase=  root:Evokanalysis:AvgWavebase
	string  destName = "StdEPSC_" + AvgWavebase
	string wn, w1
	variable index =0	
	variable xcsrPos=xcsr(A)	
	//print xcsrPos
	//NVAR sublength=  root:Evokanalysis:sublength
	//NVAR prestim=  root:Evokanalysis:prestim
	variable prestim = xcsrPos-0.005
	variable poststim = xcsrPos+0.05
	variable NrmAmp 
	variable xdeltx 
	variable startx
	RemoveFromGraph/Z ShowStimTimes
	w1 = WaveList("EvPMW*",";","WIN:")			
	wn = GetStrFromList(w1, 0, ";")
	
	Duplicate /O $wn, temp
	temp = 0
	do
		wn = GetStrFromList(w1,index,";")
		if (strlen(wn) == 0)
			break
		endif
		Wave source = $wn
		temp += source
		index += 1
	while (1)
	temp /= index
	Duplicate /O/R=(prestim, poststim) temp, $destName		
	Wave dest = $destName
	
	ZeroBaseline()		// Calls kate analysis procs v2.1
	NrmAmp=mean(temp,(xcsrPos-0.0001),(xcsrPos+0.0001))
	//print NrmAmp
	dest/=-NrmAmp
	DoWindow /K StdEPSCWindow 
	Display /W=(24,310,454,552) dest as "Standard EPSC"
	SetAxis left -1.2,0.5
	DoWindow/C StdEPSCWindow 
	xdeltx = deltax(dest)	
	startx=leftx(dest)-xcsrPos 
	SetScale/P x startx,xdeltx,"s", dest
	Cursor A, $destName, 0
	Cursor B, $destName, rightx(dest)
	DoDblExpCurveFit()  // Calls GrabCursors Procs
	
end

function EnterDblExpValues(ctrlname):  buttoncontrol
	string ctrlname
	Wave CoefGuess =root:CoefGuess
	NVAR ExpFity0	=root:EvokAnalysis:ExpFity0
	NVAR ExpFitA1= root:EvokAnalysis:ExpFitA1
	NVAR ExpFitBase_tau1=	root:EvokAnalysis:ExpFitBase_tau1
	NVAR ExpFitA2 =root:EvokAnalysis:ExpFitA2
	NVAR ExpFitBase_tau2= root:EvokAnalysis:ExpFitBase_tau2

	ExpFity0= CoefGuess[0]
	 ExpFitA2= Abs(CoefGuess[1])
	ExpFitBase_tau2= 1/CoefGuess[2]
	ExpFitA1 =Abs( CoefGuess[3])
	ExpFitBase_tau1 = 1/CoefGuess[4]
	DoUpdate
	

end

Function Artifact_CorrCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR ArtifactCorrectionCheck = root:evokanalysis:artifactCorrectionCheck
	ArtifactCorrectionCheck=checked
	print "Art Corr Check = " + num2str(ArtifactCorrectionCheck)
End
