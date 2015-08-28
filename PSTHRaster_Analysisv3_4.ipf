#pragma rtGlobals=1		// Use modern global access method.

#Include <Concatenate waves>		//this also Includes <Strings as Lists>
//#Include "WavetoList procs"
//
////  Plot waves in single window
///// Use LoadData function to plot waves
//
//// "rePlot" to plot them offset if desired.
//// Use Macro pulldown menu choice "Replot waves" to see individual waves in figure
//
//// 18june10  added raster plotting.
// 15Mar11 added ISI calculation function
//


Function MakePSTH2()
	String basename = "w02Sep14c1s4"	// choose shorter basename for saving analysis files
	variable startX=2			//  Start time for analysis		default:  0.4 sec   (400 ms, onset of stimulus)
	variable endX = 6	//  End time for analysis		default:  4.4 sec   (offset of stimulus)
	variable FIan_SpikeThresh  = 0		// Threshold crossing for spike detection, in Volts    default:  0  
	variable minWidth = 0.002		//  expected spike width, exclusion window for finding the next spike, in sec    default:   0.002 sec (2 ms)
	variable GetSpikePeaks = 1		//  1=use the spike peak for spike time, 0=use the threshold crossing for spike time  new default to get peaks
	
	variable GetSpikeThreshold = 0		// 1=run algorithm to find spike onset, at deflection point; 0=don't run algorithm
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
	//Kill_MakePSTH_windows()
	string  destName 	// name for multi-dimensional wave containing spiketimes
	string FiringRatesName, AvgFRName, SDFRName, VmName, AvgVmName, SDVmName
	
	string  w1,w
	variable index =0
	
	variable numWaves 
	variable WaveLength 
	
	variable BinWidth=0.01	// PSTH bin width, in sec          default: 0.01 sec   (10 ms)
	// get list of all waves in top window 
	w1 = WaveList("*",";","WIN:")	
	//print w1
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
		if(index==0)
			dowindow/K SpikeTimesCheck
			display/W=(50,550,500,750 )  $w
			Dowindow/C SpikeTimesCheck
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
			setaxis bottom startX, endX	//startX+2	// show first 100ms
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
	dowindow/K SpikeTimesTable
	edit STWN, STWN_r
	dowindow/C SpikeTimesTable
			dowindow/F SpikeTimesCheck
			appendtograph/R STWN_r[][0] vs STWN[][0]
			setaxis/A/E=1 right 
			modifygraph mode[1]=1, rgb[1]=(1,16019,65535)
	
		
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
		dowindow/K SpikeThreshTable
		edit ThreshWave,ThreshTimesWave
		dowindow/C SpikeThreshTable
		
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
	dowindow/K RasterWIndow
	Display/W=(50,250,500,530 ) STWN_r vs STWN 
	modifygraph mode=3, marker=10
	label left "Trial number descending"
	label bottom "Time (sec)"
	setaxis bottom startX,endX
	dowindow/C RasterWIndow
	
	// Make histogram of spike times.
	Make/O/N=1 PSTH_output=0
	histogram/B={startX,binWidth,numbins} ConcatSpikeTimes, PSTH_output		// histogram has 20 ms bins, X20 bins

	Dowindow/K PSTHGraph
	display/W=(520,540,1000,740 ) PSTH_output
	ModifyGraph mode=5,usePlusRGB=1,hbFill=2,rgb=(0,0,0),plusRGB=(30583,30583,30583)
	setaxis bottom startX,endX
	label left "#Spikes/bin"
	label bottom "Time (sec)"
	DOwindow/C PSTHGraph
	
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
		
		
	DoWindow/K RateVsTrialWindow
	Display/W=(520,50,1000,250 ) FiringRates
	ModifyGraph mode=4,  axRGB(left)=(65280,0,0),tlblRGB(left)=(65280,0,0), alblRGB(left)=(65280,0,0)
	Setaxis left 0,100
	label left "Firing Rate (Hz)"
	label bottom "Trial#"
	Dowindow/C RateVsTrialWindow
		 
	WaveStats/Q Vm
	AvgVm= V_avg
	SDVm= V_sdev
	Appendtograph/R Vm
	ModifyGraph mode[1]=4, rgb[1]=(0, 0, 65000),  axRGB(right)=(0,0,65280),tlblRGB(right)=(0,0,65280), alblRGB(right)=(0,0,65280)
	Setaxis right -0.100, -0.030
	label right  "Holding Voltage (V)"

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

	Dowindow/K ISIHGraph
	display/W=(520,270,1000,520 ) ISIH_output
	ModifyGraph mode=5,usePlusRGB=1,hbFill=2,rgb=(52428,1,1),plusRGB=(52428,1,1)
	//setaxis bottom 0,0.02
	label left "#Intervals/bin"
	label bottom "Interspike Interval (sec)"
	DOwindow/C ISIHGraph

	Edit $AvgFRName,$SDFRName, $AvgVmName, $SDVmName, $FiringRatesName,$VmName

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

menu "Analysis"
	//"Generate PSTH from traces in Window",MakePSTH()
	"Generate PSTH from traces in Window",MakePSTH2()

end

Menu "Kill Windows"
	"Kill Make PSTH Analysis Graphs",Kill_MakePSTH_windows()
	"Kill all tables", KillAllTables()
end

function Kill_MakePSTH_windows()
	DoWindow/K RasterWIndow;DoWindow/K PSTHGraph
	DoWindow/K RateVsTrialWindow;DoWindow /K CheckThresholdsWindow;
	DoWindow/K  SpikeTimesCheck; DoWindow /K ISIHGraph
end

function KillAllTables()
	string tablelist = Winlist("*",";", "WIN:2")	
	string wn
	variable i=0
	do
	wn= stringfromlist(i,tablelist,";")
	if( strlen(wn) == 0 )
			break
	endif
	dowindow /K $wn
	i+=1
	while(1)
end
	
	

function plotThresholds(ThreshWaveName,ThreshTimesName)
	string ThreshWaveName
	string ThreshTimesName
	WAVE  ThreshWave = $ThreshWaveName
	WAVe   ThX = $ThreshTimesName
	variable numtrains = dimsize(ThreshWave,1)
	variable index=0
	Display
	do
	

		Appendtograph ThreshWave[][index] vs ThX[][index]
		//modifygraph mode=1  //  mode =1 for vertical tick, mode=2 for dots
		//modifygraph mode=3, marker = 10, msize=1	// marker = 10 for vertical tick
		modifygraph mode=4, marker = 19, msize=1	// marker =19 for circle, adjust size	
		//Modifygraph offset[index]={0,1.2*index}, rgb=(0,0,0) 
		SetAxis left -0.1, 0.02
		setaxis bottom 0, 5
		label left "Voltage (mV)"
		label bottom "Time (sec)"
		index+=1;
	while(index<NumTrains)
end



function plotRaster(mywavename)
	// mywavename is string containing the wave
	// assumes a 1D or 2D wave containing spike times in columns, each column representing a trial.
	// generates "OnesforRaster" wave for plotting; need to rename
	string mywavename
	Wave mywave = $mywavename
	string oneswave = "o_" + mywavename
	Duplicate /O mywave, $oneswave
	wave onesforraster=$oneswave
	
	onesforraster=1
	variable numtrains = dimsize(mywave,1)
	variable index=0
	display
	do
		Appendtograph OnesforRaster[][index] vs mywave[][index]
		//modifygraph mode=1  //  mode =1 for vertical tick, mode=2 for dots
		//modifygraph mode=3, marker = 10, msize=1	// marker = 10 for vertical tick
		modifygraph mode=3, marker = 19, msize=1	// marker =19 for circle, adjust size	
		Modifygraph offset[index]={0,1.2*index}, rgb[index]=(0,0,0) 
		SetAxis/A/E=1 left
		index+=1;
	while(index<NumTrains)
	
end

function plotRaster_multi(mywavename, offset)
	// mywavename is string containing the wave
	// assumes a 1D or 2D wave containing spike times in columns, each column representing a trial.
	string mywavename
	variable offset
	Wave mywave = $mywavename
	string oneswave = "o_" + mywavename
	Duplicate /O mywave, $oneswave
	wave onesforraster=$oneswave
	onesforraster=1
	
	variable numtrains = dimsize(mywave,1)
	variable index=0
	if(offset==0)
		display
	endif
	
	do
		
		Appendtograph onesforraster[][index] vs mywave[][index]
		//modifygraph mode=1  //  mode =1 for vertical tick, mode=2 for dots
		//modifygraph mode=3, marker = 10, msize=1	// marker = 10 for vertical tick
		modifygraph mode=3, marker = 19, msize=1	// marker =19 for circle, adjust size	
		Modifygraph offset[offset+index]={0,1.2*(offset+index)}// rgb=(0,0,0) 
		SetAxis/A/E=1 left
		index+=1;
	while(index<NumTrains)
	
end


function RegularityAnalysis2(sourcewavename)
	string sourcewavename
	// sourcewave is literal of existing wave, destwavename is a string to create new wave
	Wave sourcewave = $sourcewavename
	string str 
	String destwavename="isi_stats"
		 plotRaster(sourcewavename)
		  PSTHfromSpikeTimes("sourcewave")
	Duplicate/O sourcewave Times
	Duplicate /O Times Intervals
	variable binsize 	// 0.1 ms binsize
	variable time_start = 0.2	// choose time window to look over
	variable time_end = 2
	variable timewin = time_end-time_start
	variable numbins 
	variable i=0
	do
	Intervals[][i]=Times[p+1][i]
	i+=1
	while(i<dimsize(Intervals,1))
	Intervals-=times
	DeletePoints (dimsize(Intervals,0)-1),1, Intervals, Times
	Wavestats /Q Intervals
	Dowindow/K IntervalsTable
	edit Textwave, $destwavename, Intervals
	Dowindow/C IntervalsTable
	str = sourcewavename + "_intervals"
	Duplicate/O Intervals, $str
	// grand mean/sd of  all isi's
	Make/N=3/O $destwavename
	wave d=$destwavename
	d[0]=V_avg
	d[1]=V_sdev
	d[2]=V_sdev/V_avg
	Make/N=3/O/T Textwave = {"mean", "sd", "CV"}

	//Dowindow/K IntervalsTable
//	edit Textwave, $destwavename, Intervals
//	Dowindow/C IntervalsTable
	
	
	
	
	
	// to make things easier unwrap matrices and rank sort
	duplicate/O Times,Times_srt
	duplicate/O Intervals, Intervals_srt
	variable rows= dimsize(Times,0)
	variable columns = dimsize(Times,1)
	Redimension /N=(rows*columns) Times_srt, Intervals_srt
	Sort Times_srt,Times_srt, Intervals_srt
	//Edit Times_srt,Times_srt, Intervals_srt
	
	// make standard ISI histogram
			Make/O/N=1 ISIH_output=0
			binsize=0.002	// 
			Wavestats /Q Intervals_srt
			numbins = V_max/binsize
			histogram/B={0,binsize,numbins} Intervals_srt, ISIH_output		// histogram has 20 ms bins, X20 bins
			Dowindow/K ISIHGraph
			display/W=(550,50,950,250 ) ISIH_output
			ModifyGraph mode=5,usePlusRGB=1,hbFill=2,rgb=(0,0,0),plusRGB=(30583,30583,30583)
			label left "#/bin"
			label bottom "Interspike Interval (sec)"
			DOwindow/C ISIHGraph
			string CVreport = "\Z14 grand CV = " + num2str(d[2])
			TextBox/C/N=text1/F=0/A=RC/X=5.52/Y=20.62 CVreport
	///

	// bins isi's according to the first spike time of the pair 
	// matching matrices Times and Intervals
	
	//print numbins
	binsize=0.005	// 
	numbins = timewin/binsize
	
	Make /N=(numbins)/O  isi_v_time,isisd_v_time,cv_v_time,bin_wave,bin_wave_pnts  // waves of time-evolving isi (mean, sd, cv across trials)
	Make/N=1/O isicv_average	// average CV of isi vs time over whole time window
	bin_wave=time_start+p*binsize
	bin_wave_pnts[0]=0
	Edit isi_v_time,isisd_v_time,cv_v_tim
	//print bin_wave[0], " bin starts at ", bin_wave_pnts[0]
	i=1
	do
		
		FindLevel /Q/P   Times_srt, bin_wave[i]  ///R=(time_start,time_end) find point values where wave value (time) greater than time bin value
		if(V_flag==0)
			bin_wave_pnts[i]=ceil(V_LevelX)
			//print bin_wave[i], " bin starts at ", bin_wave_pnts[i]
			Wavestats/Q  /R=[bin_wave_pnts[i-1], bin_wave_pnts[i]]	Intervals_srt // get intervals that correspond to these times
	
			isi_v_time[i-1]= V_avg
			isisd_v_time[i-1]= V_sdev
			cv_v_time[i-1]= V_sdev/V_avg
		endif
		i+=1
	while(i<numbins)
	
	Make/N=1/O BinnedMeanCV
	Wavestats /Q cv_v_time
	BinnedMeanCV[0]= V_avg
	string CVreport2 =  "\Z14 binned mean CV  = " + num2str(BinnedMeanCV[0])
	
	
	DoWindow/K ISIvTimeGraph
	variable winwidth=450
	variable winhght = 230
	DoWindow/K ISIvTimeGraph
	display /W=(30,30,30+winwidth,30+winhght) isi_v_time vs bin_wave
	appendtograph isisd_v_time vs bin_wave
	Modifygraph rgb(isi_v_time)=(0,0,0), mode=0,lstyle(isisd_v_time)=2,rgb(isisd_v_time)=(29524,1,58982)
	setaxis bottom 0,2
	label bottom, "Time (sec)"
	label left, "ISI (sec)"
	legend
	DoWindow/C ISIvTimeGraph

	DoWindow/K CVvTimeGraph
	display /W=(30,90+winhght,30+winwidth,90+2*winhght) cv_v_time vs bin_wave
	
	Modifygraph rgb(cv_v_time)=(29524,1,58982), mode=0
	setaxis bottom 0,2
	setaxis left 0,1
	label bottom, "Time (sec)"
	label left, "CV/bin"
	legend
		
	TextBox/C/N=text1/F=0/A=RC/X=5.52/Y=20.62 CVreport2
	DoWindow/C CVvTimeGraph
	str = sourcewavename + "_isi"
	Duplicate /O isi_v_time ,$str
	str = sourcewavename + "_isisd"
	Duplicate /O isisd_v_time ,$str
	str = sourcewavename + "_isibins"
	Duplicate /O bin_wave ,$str
	
end



function RegularityAnalysis(sourcewavename)
	// sourcewave is literal of existing wave, destwavename is a string to create new wave
	string sourcewavename
	Wave sourcewave= $sourcewavename
	String destwavename
		 plotRaster(sourcewavename)
		//  PSTHfromSpikeTimes("sourcewave")
	Duplicate/O sourcewave Times
	Duplicate /O Times Intervals
	variable i=0
	do
	Intervals[][i]=Times[p+1][i]
	i+=1
	while(i<dimsize(Intervals,1))
	Intervals-=times
	DeletePoints (dimsize(Intervals,0)-1),1, Intervals
	Wavestats /Q Intervals
	
	// grand mean/sd of  all isi's
	Make/N=3/O $destwavename
	wave d=$destwavename
	d[0]=V_avg
	d[1]=V_sdev
	d[2]=V_sdev/V_avg
	Make/N=3/O/T Textwave = {"mean", "sd", "CV"}

	Dowindow/K IntervalsTable
	edit Textwave, $destwavename, Intervals
	Dowindow/C IntervalsTable
	
	
	// bins isi's according to the first spike time of the pair 
	// matching matrices Times and Intervals
	variable binsize = 0.1	// 0.1 ms binsize
	variable time_start = 0.2	// choose time window to look over
	variable time_end = 0.5
	variable timewin = time_end-time_start
	variable numbins = timewin/binsize
	Make /N=(numbins)/O  isi_v_time,isisd_v_time,cv_v_time  // waves of time-evolving isi (mean, sd, cv across trials)
	Make/N=1/O isicv_average, d1,d2	// average CV of isi vs time over whole time window
	
	Make/N=(numbins)/O bin_wave 
	bin_wave=time_start+p*binsize
	i=0
	do
		FindLevels /D=d1 /P/Q  /R=(time_start,time_end) Times, bin_wave[i]  // find point values where wave value (time) greater than time bin value
		FindLevels /D=d2 /P/Q  /R=(time_start,time_end) waveName, bin_wave[i]	// find which ones of these are also less than next bin value
		Make/N=(numpnts(d2))/O SelectPoints, SelectIntervals
		SelectPoints = Times[d1[d2]] 	// get point values for times   bin1<times<bin2
		SelectIntervals = Intervals[SelectPoints]		// get intervals that correspond to these times
		Wavestats/Q SelectIntervals
		isi_v_time[i]= V_avg
		isisd_v_time[i]= V_sdev
		cv_v_time[i]= V_sdev/V_avg
	
		i+=1
	while(i<numbins)
	
end

function   CalcISI2(sourcewave,destwavename)
	// rewrote to return full matrix of intervals, not just avgs
	Wave sourcewave
	String destwavename
	string IntervalsAvgname = destwavename + "_avg"
	Duplicate/O sourcewave Times
	Duplicate /O Times Intervals
	variable i=0
	do
	Intervals[][i]=Times[p+1][i]
	i+=1
	while(i<dimsize(Intervals,1))
	Intervals-=times
	DeletePoints (dimsize(Intervals,0)-1),1, Intervals	// trim down to N-1 points
	Wavestats /Q Intervals
	DeletePoints (dimsize(Times,0)-1),1, Times // trim down to N-1 points
	Make/N=3/O $IntervalsAvgname
	wave d=$IntervalsAvgname
	d[0]=V_avg
	d[1]=V_sdev
	d[2]=V_sdev/V_avg
	Make/N=3/O/T Textwave = {"mean", "sd", "CV"}

	duplicate/O Intervals, $destwavename

	Dowindow/K IntervalsTable
	edit Textwave, $IntervalsAvgname,$destwavename
	Dowindow/C IntervalsTable




end


function   CalcISI(sourcewave,destwavename)
	// returns the avg, sd , se values in destwavename
	Wave sourcewave
	String destwavename
	string Intervalswavename = destwavename + "_allInt"
	Duplicate/O sourcewave Times
	Duplicate /O Times Intervals
	variable i=0
	do
	Intervals[][i]=Times[p+1][i]
	i+=1
	while(i<dimsize(Intervals,1))
	Intervals-=times
	DeletePoints (dimsize(Intervals,0)-1),1, Intervals	// trim down to N-1 points
	Wavestats /Q Intervals
	DeletePoints (dimsize(Times,0)-1),1, Times // trim down to N-1 points
	Make/N=3/O $destwavename
	wave d=$destwavename
	d[0]=V_avg
	d[1]=V_sdev
	d[2]=V_sdev/V_avg
	Make/N=3/O/T Textwave = {"mean", "sd", "CV"}

	duplicate/O Intervals, $Intervalswavename

	Dowindow/K IntervalsTable
	edit Textwave, $destwavename,$Intervalswavename
	Dowindow/C IntervalsTable




end


Function PSTHfromSpikeTimes(SpikeTimesWaveName)
// Make standard histogram from raster multiwave of spike times
	string SpikeTimesWaveName
	variable startX = 0.2
	variable endX 	= 2.2
	variable binwidth	= 0.001
	variable analysisLength= endX-StartX
	variable numbins = analysisLength/binWidth
	string dest = SpikeTimesWaveName+"_PSTH"
	ConcatenateWaves("ConcatSpikeTimes", SpikeTimesWaveName)		
	Make/O/N=1 PSTH_output=0
	histogram/B={startX,binWidth,numbins} ConcatSpikeTimes, PSTH_output		// histogram has 20 ms bins, X20 bins
	Duplicate/O PSTH_output,$dest
	Dowindow/K PSTHGraph
	display/W=(50,50,500,250 ) $dest
	ModifyGraph mode=5,usePlusRGB=1,hbFill=2,rgb=(0,0,0),plusRGB=(30583,30583,30583)
	setaxis bottom startX,endX
	label left "#Spikes/bin"
	label bottom "Time (sec)"
	TextBox/C/N=text0/F=0/A=MT SpikeTimesWaveName
	DOwindow/C PSTHGraph
	
end
	




function   FindSpikeTimes2(sourcewavename,  destwavename,spikeThreshold,startX,endX,FIan_minWidth, Type)
	string sourcewavename
	string destwavename
	variable spikeThreshold 
	variable startX // default to 0
	variable endX 
	variable FIan_minWidth// = 0.0015
	variable Type   // get spike time at hard threshold crossing itself, or the peak immediately after (to be programmed)
	variable index =0
	variable substartX = startX
	variable numSpikes 
	variable numfailed=0
	variable numfound=0
	WAVE wn= $sourcewavename
	
	variable minpeakwid = min( max(FIan_minWidth/2,0.001),  0.0025)	// 	 set peak finding to be no smaller than 1 ms
																			// nor wider than 2.5 ms
	//endx=pnt2x(wn, numpnts(wn))
	print "             Running FindSpikeTimes with Params: ", Time()
	Print "             SpikeThreshold   =", spikeThreshold, ",  startX   =", startX,  ",  endX   =", endX, ",  FIan_minWidth   =", FIan_minWidth
	FindLevels /Q/M=(FIan_minWidth)/EDGE=1/R=(startX,endX )   wn, spikeThreshold			// outputs:  V_flag, V_LevelsFound
	if (V_Flag==2)		// if no spikes found
		print "found no spikes for ", sourcewavename
		Make/O/N=(1) tempXvalues
		tempXvalues=Nan		//	set to a dummy value to return dummy wave; otherwise it's an empty wave
	else			// if spikes found
		numSpikes=V_LevelsFound		// determine how many
		print "             # spikes = ",num2str(numspikes), "  for ", sourcewavename
		//Make/O/N=(numSpikes) tempXvalues		//  make a wave the right size
		Make/O/N=(1) tempXvalues	
		do	
			if(numfailed>10)
						print "too many failed peak findings - change analysis parameters"
						
						break
			endif																// LOOP to find x values for each spike
			FindLevel /EDGE=1 /Q/R=(substartX,endX ) wn, spikeThreshold		// outputs: V_flag, V_LevelX;  removed "/EDGE=1" flag b/c incompatable with windows? won't compile.
			
			if(type)	// if finding peak of spike
				
				findpeak /Q/R=(V_LevelX,V_LevelX+FIan_minWidth) wn
				if(V_flag==0)
					if(numfound>0)
						insertpoints (numpnts(tempXvalues)), 1, tempXvalues	// add points to wave
					endif
					tempXvalues[index]=V_PeakLoc
					numfound+=1
					
					//print "found peak in spike # ", num2str(index), "  in " , sourcewavename, " at ", num2str(V_Peakloc)
				else
					print "failed to find peak in spike # ", num2str(index), "  in " , sourcewavename, " after level crossing ", num2str(V_LevelX)
					//tempXvalues[index]=NaN  // temporary enter NaN to debug
					
					numfailed+=1
					
				endif
			else
				tempXvalues[index]=V_LevelX
			
			endif
			
			substartX =V_LevelX+FIan_minWidth
			index+=1
		while(index<numSpikes)
		//print "                          # spikes gotten with FindLevel to find times", (index)
	endif	
	Duplicate/O 	tempXvalues, $destwavename		// finishes by saving values as destwavename.
	//print tempXvalues
	//DoWindow/K Spiketimes_table
	//Edit $destwavename
	//Dowindow/C Spiketimes_table
	print "Compeleted FindSpikeTImes2"
end
	
	
	
function   FindSpikeThresh(sourcewavename, ThXname,ThVmname,DiffDiffThreshold,FIan_minWidth, SpikeTimesName)
	// given sourcewave and list of spike times, find the spike thresholds
	string sourcewavename
	string ThXname
	string ThVmname
	variable DiffDiffThreshold 
	variable FIan_minWidth// = 0.0015
	string SpikeTimesName
	variable index =0
	variable substartX 
	variable numSpikes 
	variable numfailed=0
	variable numfound=0
	variable NrmF
	WAVE wn= $sourcewavename
	WAVE times= $SpikeTimesName
	
	numSpikes = numpnts(times)
	variable minpeakwid = min( max(FIan_minWidth,0.001),  0.0025)	// 	 set peak finding to be no smaller than 1 ms
																			// nor wider than 2.5 ms
	//endx=pnt2x(wn, numpnts(wn))
	print "             Running FindSpikeThresh with Params: ", Time()
	Print "             Voltage Accel Threshold   =", DiffDiffThreshold, ", min window prior to spike time   =", minpeakwid
	
	
			KillWaves/Z Difftemp,DiffDifftemp
			differentiate wn /D=Difftemp
			Differentiate Difftemp /D=DiffDifftemp
			Smooth  5 , DiffDifftemp
		
			NrmF=mean(DiffDifftemp) 
			DiffDifftemp-=NrmF // rescale  and normalize to zero baseline
			DiffDifftemp/=1000
			
	
	Make/O/N=(numSpikes) ThresholdVmWave, ThresholdXWave
	// loops throught  spike times
	
	edit ThresholdVmWave, ThresholdXWave
	
	do
		substartX=times(index)-minpeakwid
		
		FindLevel /Q/R=(substartX,times(index)) DiffDifftemp, DiffDiffThreshold
		if(V_flag==0)
			// found peak
					if(numfound>0)
					//	insertpoints (numpnts(ThresholdVmWave)), 1, ThresholdVmWave	// add points to wave
					endif
					
					ThresholdXWave[index]=V_LevelX
					// now get the voltage at this time
					ThresholdVmWave[index]= wn[x2pnt(wn,V_LevelX)]
					
					
					numfound+=1
					
					//print "found threshold for spike # ", num2str(index),  " at ", num2str(ThresholdVmWave[index]), " Volts, and  ", num2str(V_LevelX), " sec"
				else
					print "failed to find peak in spike # ", num2str(index), "  in " , sourcewavename, " at spike time ", num2str(times(index))
					ThresholdXWave[index]=NaN  // temporary enter NaN to debug
					ThresholdVmWave[index]=NaN
					numfailed+=1
					
				endif
		index+=1
	while(index<numSPikes)
		duplicate /O ThresholdXWave, $ThXname
		duplicate /O ThresholdVmWave, $ThVmname

	
end
	
	
