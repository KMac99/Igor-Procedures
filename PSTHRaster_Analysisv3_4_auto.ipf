#pragma rtGlobals=1		// Use modern global access method.


function LoadMyIgorDataAllSub()	//copy & paste into command window
	//this function requires having "LoadDataPanel" procedure compiled & initialized
       variable Step_start= 2
	variable Step_end= 6
	variable noiselev_start= 0
	variable noiselev_end=0
	variable	Trialnum_start=0
	variable trialnum_end =2
	variable loadflag=1
	variable plotflag=1
	variable FRanalyzeflag=1
	
	SVAR  basename = root:LoadDataPanel:basename
	SVAR pathnameStr = root:LoadDataPanel:pathnameStr
	SVAR filesuffix = root:LoadDataPanel:filesuffix
	SVAR endtag   = root:LoadDataPanel:endtag
	variable StepNum=Step_end-Step_start+1
	variable NoiseNum=noiselev_end-noiselev_start+1
	string avgnm, sdnm
	string fileNameStr
	String  totalStr
	string titleStr
	variable i,j,k
	
	if(FRanalyzeflag)
		Make/N=(StepNum,NoiseNum)/O  FR_MeanLine, FR_SDLine	// make wave to hold mean firing rates across steps,noise levels
		Make/N=(StepNum)/O StepLevels 
		StepLevels=x
		edit StepLevels,FR_MeanLine  as "Mean FR data Table"
		Edit StepLevels,FR_SDLine as "FR SD data Table"
	endif
	
	i=Step_start
	do
		//print "  Step level ",num2str(i)
		j=noiselev_start
		do
			//print "            Noise level ",num2str(j)
			titleStr=basename + num2str(i) + "_n"+num2str(j) 
			if(FRanalyzeflag)
					Dowindow/K titleStr
					Display as titleStr
					Dowindow/C titleStr
			elseif(plotflag)
					Display as titleStr
			endif
			k=Trialnum_start
			do
				fileNameStr=basename + num2str(i) + "_n"+num2str(j) +"_" + num2str(k) 
				if(loadflag)
					TotalStr=pathnameStr+filenamestr+endtag
					LoadWave/H/A/O/Q TotalStr
				endif
				if(plotflag)
					appendtograph $fileNameStr
					DoUpdate
				endif
				k+=1
			while(k<=trialnum_end)
			if(FRanalyzeflag)
				MakePSTH2_auto(titleStr)
				avgnm= titleStr+ "FRAvg"
				sdnm= titleStr + "FRSD"
				wave avw=$avgnm
				wave sdw=$sdnm
				FR_MeanLine[i][j]=avw[0]
				FR_SDLine[i][j]=sdw[0]
			endif
			j+=1
		while(j<=noiselev_end)
		
		i+=1
	while(i<=Step_end)
	
	if(FRanalyzeflag)
		DoWindow/K FRSummary
		Display FR_MeanLine[][0] vs StepLevels   as basename  //copy paste this section to re-plot FI curve
		Appendtograph  FR_MeanLine[][1] vs StepLevels 
		Appendtograph FR_MeanLine[][2] vs StepLevels 
		Modifygraph rgb[2]=(0,65500,0),rgb[1]=(0,0,65500)
		ErrorBars FR_MeanLine#0 Y,wave=(FR_SDLine[*][0],FR_SDLine[*][0])
		ErrorBars FR_MeanLine#1 Y,wave=(FR_SDLine[*][1],FR_SDLine[*][1])
		ErrorBars FR_MeanLine#2 Y,wave=(FR_SDLine[*][2],FR_SDLine[*][2])
		label left "Firing Rate (Hz)"
		label bottom "Step #"
		Legend
		DoWindow/C FRSummary
	endif
end


Function MakePSTH2_auto(groupname)
	string groupname
	Dowindow/F groupname
	variable plotsuppression=0	// 1=plot, 0 = don't plot
	String basename = groupname	// choose shorter basename for saving analysis files
	variable startX=0.55			//  Start time for analysis		default:  0.4 sec   (400 ms, onset of stimulus)
	variable endX =1.1		//  End time for analysis		default:  4.4 sec   (offset of stimulus)
	variable FIan_SpikeThresh  = 0		// Threshold crossing for spike detection, in Volts    default:  0  
	variable minWidth = 0.002		//  expected spike width, exclusion window for finding the next spike, in sec    default:   0.002 sec (2 ms)
	variable GetSpikePeaks = 1		//  1=use the spike peak for spike time, 0=use the threshold crossing for spike time  new default to get peaks
	
	variable GetSpikeThreshold = 0			// 1=run algorithm to find spike onset, at deflection point; 0=don't run algorithm
	variable VoltAccelThresh =	100		//  voltage acceleration used to designate spike threshold in mV/sec^2, default: 100, user adjust
	Prompt basename, "Enter basename for files:"
	//Prompt BinWidth," BinWidth for histogram (sec):"
	Prompt startX,"time to begin counting spikes (sec)"
	Prompt endX,"time to end counting spikes (sec)"
	Prompt FIan_SpikeThresh, "Spike Threshold (V)"
	Prompt minWidth, "Spike Width (sec)"
	prompt GetSpikePeaks, "Find spike peak times (1=yes, 0=no)"
	prompt GetSpikeThreshold,  "Find spike threshold (1=yes, 0=no)"
	prompt VoltAccelThresh,  "Voltage acceleration for spike threshold (mV/sec^2)"
	DoPrompt "Enter parameters ", basename,startX,endX,FIan_SpikeThresh,minWidth, GetSpikePeaks,GetSpikeThreshold,VoltAccelThresh
	if(V_flag)
		return -1			// user cancelled
	endif
	NVAR flag=root:flag
	Kill_MakePSTH_windows()
	string  destName 	// name for multi-dimensional wave containing spiketimes
	string FiringRatesName, AvgFRName, SDFRName, VmName, AvgVmName, SDVmName
	
	string  w1,w
	variable index =0
	
	variable numWaves 
	variable WaveLength 
	
	variable BinWidth=0.01	// PSTH bin width, in sec          default: 0.01 sec   (10 ms)
	// get list of all waves in top window 
	Dowindow/F groupname
	print groupname
	w1 = WaveList("*",";","WIN:")	
	print w1
	numWaves = ItemsInlist(w1)
	WaveLength= rightx(w1)		// gets length assuming starts at zero;  approximate, last x number is actually n-1
	//
	variable analysisLength= endX-StartX
	variable numbins = analysisLength/binWidth
	print "****************************************Running MakePSTH with Params: ", Time()
	Print "FIan_SpikeThresh   =", FIan_SpikeThresh
	Print "startX   =", startX
	Print "endX   =", endX
	Print "minWidth   =", minWidth
	// Make destination wave for spike times based on basename
	string destNamebase= basename
	//destNamebase=StringFromList(0, w1,";")  // alternative:  based on the first source wave.
	destName = destNamebase + "_spkTimes"
	//print destName
	//Wave dest = $destName
	// Make destination wave for firing rate based on the first source wave.
	FiringRatesName = destNamebase +"FR"
	AvgFRName= destNamebase+ "FRAvg"
	SDFRName= destNamebase + "FRSD"
	VmName=destNamebase + "Vm"
	AvgVmName = destNamebase + "VmAvg"
	SDVmName = destNamebase + "VmSD"
	Make/O/N=(numWaves) $FiringRatesName, $VmName	// make a wave to contain each train's firing rates
	WAVE FiringRates = $FiringRatesName
	WAVE Vm= $VmName
	Make/N=1/O $AvgFRName, $SDFRName, $AvgVmName, $SDVmName
	WAVE AvgFR=$AvgFRName
	WAVE SDFR= $SDFRName
	WAVE AvgVm = $AvgVmName
	WAVE SDVm=$SDVmName
	/// PSTH graph variable
	variable TempNumSpikes
	
	Make/O/N=(numwaves) NumberofSpikes
	string SpikeTimesWaveName = destNamebase+"raster"
	string SpikeTimesWaveName_ra_indx = destNamebase +"rindex"
	string PSTHWaveName= destNamebase+"PSTH"
	
	if(GetSpikeThreshold)
		//string SpikePkTimesWaveName =  destNamebase +"_rasterPk"
		string SpikeThresholdsName = destNamebase +"VmTh"
		string SpikeThresholdsXName = destNamebase+"rastTh"
	endif 
	
	string ISIwavename = destNamebase+ "Int"
	
	
	// LOOP
	string tempName, tempName2,tempName3,tempName4
	Make/T/O/N=(numWaves) ListofTempLevelsNames,ListofTempLevelsNames3,ListofTempLevelsNames4
	//Make/O/N=1 ConcatSpikeTimes
	////ConcatSpikeTimes=1
	
	if(GetSpikePeaks)
		print "Getting spike times from spike peaks"
	else
		print  "Getting spike times from threshold crossing"
	endif
	do
		w = StringFromList( index,w1, ";")
		if (strlen(w)==0)
			break
		endif
		WAVE wn = 	$w	// get first wave
		if(plotsuppression)
			if(index==0)
				dowindow/K SpikeTimesCheck
				display/W=(50,550,500,750 )  $w
				Dowindow/C SpikeTimesCheck
			endif
		endif
		// measure baseline voltage
		Vm[index]= mean(wn,0,startX)
		
		tempName = "temp_" + num2str(index)
		ListofTempLevelsNames[index] = tempName
		//print w	
		//print ListofTempLevelsNames[index],  tempName
		FindSpikeTimes2(w,  tempName,FIan_SpikeThresh,startX,endX,minWidth, GetSpikePeaks)		// pass function (sourcewave, destwave, threshold)
		WAVE temp =  $tempName
		NumberofSpikes[index]=numpnts(temp)
		FiringRates[index]=NumberofSpikes[index]/analysisLength
		
		if(index==0)
			Duplicate /O temp,ConcatSpikeTimes
		else
			//print "concatenating"
			ConcatenateWaves("ConcatSpikeTimes", tempName)			// concatenaute all spike times into single wave
			
		endif
		variable NrmF
		if(GetSpikeThreshold)
		
			tempName3="temp3_" + num2str(index)
			tempName4="temp4_" + num2str(index)
			ListofTempLevelsNames3[index]=tempName3
			ListofTempLevelsNames4[index]=tempName4
		
			FindSpikeThresh(w,tempName3,tempName4,VoltAccelThresh, minWidth,tempName)
		
	
			
			//if(index==0)
				WAVE tmpNm4=$tempName4
				WAVE tmpNm3=$tempName3
			// plot thresholds against trace
			

			DoWindow/K CheckThresholdsWindow
			Display /W=(50,50,1000,450 )  wn
			appendtograph tmpNm4 vs tmpNm3
			Modifygraph mode[1]=3,marker[1]=19,rgb[1]=(0,0,65535), axisEnab(left)={0.4,1}
			
			appendtograph /R DiffDifftemp
			Modifygraph rgb[2]=(0,65535,0),  axisEnab(right)={0,0.6}
			setaxis bottom startX, startX+0.3	// show first 100ms
			DoWindow/C CheckThresholdsWindow
			DoUpdate
			DoWindow/F CheckThresholdsWindow
			variable ContinueAnalysis = 0
			Prompt ContinueAnalysis, "Continue with the next wave", popup, "Yes;No"
			DoPrompt "Continue analysis Dialog",ContinueAnalysis
			if(ContinueAnalysis==1)
				//print "*****Continuing with analysis"
			else
				print "******************************Ending "
				break
			endif
		
			//endif
		endif
		
		index +=1
	while(1)
	// Try converting text wave to list, then concatenating it.
	//	string TempNamesList
	//	TempNamesList = ConvertTextWavetoList(ListofTempLevelsNames)
	//	print "here is temp names list",TempNamesList
	//	ConcatenateWavesInList("MySpikeTimes", "TempNamesList")
	// Convert list of temp waves into one multi-dim wave
	WaveStats /Q NumberofSpikes
	variable MaxNumSpikes = V_max
	Make/O/N=(MaxNumSpikes,numWaves)	 $SpikeTimesWaveName,$SpikeTimesWaveName_ra_indx	// 2-d wave to contain all spike times.
	WAVE STWN = $SpikeTimesWaveName
	WAVE STWN_r=$SpikeTimesWaveName_ra_indx
	STWN=NAN		// clears possible old values out of waves - not really necessary bc overwrote...
	STWN_r=NaN
	index =0
	print "writing spikes time to raster wave     ", SpikeTimesWaveName
	do
		WAVE tmp= $ListofTempLevelsNames[index]
		STWN[0,numpnts(tmp)-1][index]=tmp[p]
		STWN_r[0,numpnts(tmp)-1][index]=numwaves-index
		Killwaves/Z $ListofTempLevelsNames[index]
		index+=1
	while(index<numwaves)
		if(plotsuppression) //
	dowindow/K SpikeTimesTable
	edit STWN, STWN_r
	dowindow/C SpikeTimesTable
			dowindow/F SpikeTimesCheck
			appendtograph/R STWN_r[][0] vs STWN[][0]
			setaxis/A/E=1 right 
			modifygraph mode[1]=1, rgb[1]=(1,16019,65535)
	
		endif  //
	if(GetSpikeThreshold)
		// repeat for spike thresholds
		print MaxNumSpikes, numWaves
		Make/O/N=(MaxNumSpikes,numWaves)	 $SpikeThresholdsName,$SpikeThresholdsXName	// 2-d wave to contain all spike times.
		print " writing  to " , SpikeThresholdsName
		WAVE ThreshWave = $SpikeThresholdsName
		WAVE ThreshTimesWave=$SpikeThresholdsXName
		//ThreshWave=NAN
		//ThreshTimesWave=NaN
		print ListofTempLevelsNames3
		index =0
		do
			WAVE tmp3= $ListofTempLevelsNames3[index]
			ThreshTimesWave[0,numpnts(tmp3)-1][index]=tmp3[p]
			WAVE tmp4= $ListofTempLevelsNames4[index]
			ThreshWave[0,numpnts(tmp4)-1][index]=tmp4[p]
			//KillWaves /Z tmp3,tmp4
			index+=1
		while(index<numwaves)
			if(plotsuppression)
		dowindow/K SpikeThreshTable
		edit ThreshWave,ThreshTimesWave
		dowindow/C SpikeThreshTable
		endif
//			DoWindow/K CheckThresholdsWindow
//			string firstw = StringFromList( 1,w1, ";")
//			Display /W=(50,50,1000,450 )  $firstw
//			appendtograph ThreshWave[][0] vs ThreshTimesWave[][0]
//			//Modifygraph mode[1]=3,marker[1]=19,rgb[1]=(0,0,65535), axisEnab(left)={0.4,1}
//			
//			//appendtograph /R DiffDifftemp
//			//Modifygraph rgb[2]=(0,65535,0),  axisEnab(left)={0,0.6}
//			//setaxis bottom startX, startX+0.3	// show first 100ms
//			DoWindow/C CheckThresholdsWindow
	endif

	//Edit /W=(50,600,500,800 ) STWN   as "Spike Times Table"
	//	dowindow/C SpikeTimesTable
	//  now plot as raster
	
		if(plotsuppression)
	dowindow/K RasterWIndow
	Display/W=(50,250,500,530 ) STWN_r vs STWN 
	modifygraph mode=3, marker=10
	label left "Trial number descending"
	label bottom "Time (sec)"
	setaxis bottom startX,endX
	dowindow/C RasterWIndow
	endif
	// Make histogram of spike times.
	Make/O/N=1 PSTH_output=0
	histogram/B={startX,binWidth,numbins} ConcatSpikeTimes, PSTH_output		// histogram has 20 ms bins, X20 bins
	if(plotsuppression)
	Dowindow/K PSTHGraph
	display/W=(520,540,1000,740 ) PSTH_output
	ModifyGraph mode=5,usePlusRGB=1,hbFill=2,rgb=(0,0,0),plusRGB=(30583,30583,30583)
	setaxis bottom startX,endX
	label left "#Spikes/bin"
	label bottom "Time (sec)"
	DOwindow/C PSTHGraph
	endif
	// Write to Notebook  to be added
	//	if(Exists("PSTHLog")==0)
	//		NewNotebook/N=PSTHLog/F=1/V=1/W=(75,130,522,358) as "PSTHLog "
	//		Notebook PSTHLog text="\t Beginning PSTH analysis Time: "+Time()+"\r\r"
	//	endif
	//		Notebook PSTHLog ruler=Normal, text="\r\t Using Waves from Top Graph"
	//		Notebook PSTHLog text="\r\t " + w1
	//		Notebook PSTHLog text="\r\t  Firing Rates saved as wave named:  " + FiringRatesName
	//
	//		Notebook PSTHLog text="\r\t Average Firing Rate saved as wave Named" + AvgFRName 
	//		Notebook PSTHLog text="\r\t    SD saved as wave named" + SDFRName
	//		Notebook PSTHLog text="\r\t Spike times for each trial saved as wave Named" + SpikeTimesWaveName
	//		Notebook PSTHLog text="\r\t Binned PSTH data saved as wave Named" + PSTHWaveName
	WaveStats/Q FiringRates
	AvgFR=V_avg
	SDFR=V_sdev
		
		if(plotsuppression)	
	DoWindow/K RateVsTrialWindow
	Display/W=(520,50,1000,250 ) FiringRates
	ModifyGraph mode=4,  axRGB(left)=(65280,0,0),tlblRGB(left)=(65280,0,0), alblRGB(left)=(65280,0,0)
	Setaxis left 0,100
	label left "Firing Rate (Hz)"
	label bottom "Trial#"
	Dowindow/C RateVsTrialWindow
		endif 
	WaveStats/Q Vm
	AvgVm= V_avg
	SDVm= V_sdev
		if(plotsuppression)
	Appendtograph/R Vm
	ModifyGraph mode[1]=4, rgb[1]=(0, 0, 65000),  axRGB(right)=(0,0,65280),tlblRGB(right)=(0,0,65280), alblRGB(right)=(0,0,65280)
	Setaxis right -0.100, -0.030
	label right  "Holding Voltage (V)"
endif
	//		
	CalcISI2(STWN, ISIwavename)
	WAVE ISIWN = $ISIwavename
	// Make histogram of intervals 
	Make/O/N=1 ISIH_output=0
	Duplicate/O   $ISIwavename,  IntConcat
	//edit IntConcat
	variable	m=dimsize(ISIWN,0)
	variable	n=dimsize(ISIWN,1)
	//print "redimensioning ", num2str(m), " by ", num2str(n) , "  wave to 1D"
	redimension /N=(m*n) IntConcat
	
	binWidth=0.001
	numbins=100
	histogram/B={0,binWidth,numbins} IntConcat, ISIH_output		// histogram has 0.5 ms bins, X400 bins, 20 ms range
	if(plotsuppression)
	Dowindow/K ISIHGraph
	display/W=(520,270,1000,520 ) ISIH_output
	ModifyGraph mode=5,usePlusRGB=1,hbFill=2,rgb=(52428,1,1),plusRGB=(52428,1,1)
	//setaxis bottom 0,0.02
	label left "#Intervals/bin"
	label bottom "Interspike Interval (sec)"
	DOwindow/C ISIHGraph

	Edit $AvgFRName,$SDFRName, $AvgVmName, $SDVmName, $FiringRatesName,$VmName
endif

	if(flag==0)
	edit $AvgFRName as "All AVg FR"
	Dowindow/C AllFRTable
	flag=1
	else
	appendtotable /W=AllFRTable   $AvgFRName
	endif
	
	
	print "\t Mean firing rate:  " + num2str(AvgFR[0]) +" +- " + num2str(SDFR[0]) +   " Hz "  
	print "\t Mean holding voltage:  " + num2str(1000*AvgVm[0]) +" +- "  +  num2str(1000*SDVm[0]) +" mV "  
		 
	print "\t Firing Rates saved as wave named :  " + FiringRatesName
	print "\t Average Firing Rate saved as wave named  : " + AvgFRName 
	print "\t    SD saved as wave named :  " + SDFRName
	print "\t  Spike times for each trial saved as wave named : " + SpikeTimesWaveName
	print "\t  Binned PSTH data saved as wave named :   " + PSTHWaveName
	dowindow/F RasterWIndow
	
	//clean up
	//Killwaves ListofTempLevelsNames, ListofTempLevelsNames3,ListofTempLevelsNames4, W_FindLevels
end