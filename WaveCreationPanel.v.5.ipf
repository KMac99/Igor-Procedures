#pragma rtGlobals=1		// Use modern global access method.
//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\WavetoList procs"
#include <Waves Average>
//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\kate analysis procs"
///WaveCreationPanel v.4.ipf
// Updated 20july2010 for new NIDAQmx Tools.
///  Panel for creating common use stimulation waves.
//  9/7/05  expanded to create sets of constant frequency trains at once; quicker to make sets, and alter all amplitudes.
// 7/26/06  updated to select as arbitrary wave containing stimulus times to use as 'template' for stimulus train.  
//              Usually "_t'" waves from previously generated waves but could be any named wave.
//                 Facilitates resetting amplitudes on random waves previously generated without changing stim timing.
// 7/30/06	corrected a problem with times wave; changed random train generation so first stim is same delay as CF trains.  Added notebook annotation for 

Menu "Initialize Procedures"
	"Initialize WaveCreationPanel",Init_WaveCreationPanel()
end

Menu "Kill Windows"
	"Kill WaveCreation Windows",Kill_WaveCreationPanel_windows()
end

Proc Init_WaveCreationPanel()
	// Check to see whether Globals Folder exists (i.e., that the InitializeDataAcquisition procedure 
	// has been run & common global variables exist
	if( DataFolderExists("root:DataAcquisitionVar"))	
		DoWindow/K WaveCreationPanel
		if( !DataFolderExists("root:WaveCreation"))
			String dfSave=GetDataFolder(1)	
			NewDataFolder /O/S root:WaveCreation		// Create folder forvariables
			KillWaves /a/z								// clean out folder & start from scratch
			killvariables /a/z		
			killstrings /a/z
			variable /G WaveCreation_Length			= 3.5	// total length of acquisition wave, sec
			Variable /G WaveCreation_Delay 			=  0.6				//delay before first stimulus (sec)
			variable / G WaveCreation_Gain			= 1
			Variable /G UseSquarePulseCheck			=1
			Variable /G UseAlphaCheck				=0
			Variable /G WavetypeVar					=0		// what kind of output wave (SIU, VCmd, Curr Cmd)
			// Alpha params:
			variable /G AlphaAmplitude_nA				= 0.05			// applied Current clamp signal
			variable /G AlphaAmplitude_V				= -0.005			// applied Voltage clamp signal
			variable /G tau1							= 0.001			// in sec
			variable /G tau2							= 0.002			// in sec
			//Stim pulse params:
			Variable /G WaveCreation_StimDuration 	=  0.0004	// duration of electrical stimulus (sec;  e.g. 100microsec)
			Variable /G SquarePulse_Amplitude_V		= 1			// amplitude in V of Stim output
			Variable /G SquarePulse_Amplitude_nA		= .05			// amplitude in nA of Stim output
	
			Variable /G WaveCreation_Biphasic			= 1			// 1 = yes, biphasic; 0= no, monophasic
			Variable/G WaveCreation_InvertStim		= 1
			//Uniform freq params:
			variable/G WaveCreation_NumPulses		= 10		
			variable /G WaveCreation_InterPulseInterval 	= 0.010			//  in seconds
			variable/G WaveCreation_StimFrequency	:= 1/WaveCreation_Interpulseinterval
			Variable/G   WC_UseUniformFreqTrainCheck = 0
			variable/G WC_UseRecoveryPulseCheck	= 1
			variable/G  WC_RecoveryDelay				= 2		// sec	
			//Set of uniform freq params:
			Variable/G   WC_UseSetofTrainCheck 		= 1
			string /G WC_SetofIntervals				= "20;5"	// msec
			string /G  WC_SetofFreq					= ""					// Hz	
			///  Use same number of pulses, recovery check, and recovery delay.
			// Random train params:
			Variable/G   WC_UseRandomTrainCheck 	= 0
			string/G  WaveCreation_RandomType		= "Gaussian"
			variable/G WaveCreation_AvgFreq			= 25		// Hz
			variable/G WaveCreation_MinInterval		= 0.005		// sec
			// Use selected wave (loading arbitrary set of intervals)
			Variable/G WC_UseSelectWaveCheck

			//String 	/G WaveCreation_BasenameUni		:=	"StimWave_" + num2str(WaveCreation_StimFrequency) + "Hz"
			STring /G WaveCreation_BasenameRand  :=	"StimWave_" + num2str(WaveCreation_AvgFreq) + "Hz" +WaveCreation_RandomType
			String /G WaveCreation_BasenameUni		=	"StimCF" 
			string /G WaveCreation_RenameSelect		= "StimWave1"
			String/G WaveCreation_Basename := WaveCreation_BasenameUni
			//possibly useful later to make sets of waves, or waves with command offset going to cell:
			//variable /G 	WaveCreation_CmdVolt		=  0	// command voltage,V (absolute)
			//Variable /G WaveCreation_StartAmplitude =0.1		// volts
			//Variable /G WaveCreation_EndAmplitude =5			// volts
			//Variable /G WaveCreation_NumLevels 		=5		// 
			//Variable /G WaveCreation_LevelAmplitude	:= (WaveCreation_EndAmplitude-WaveCreation_StartAmplitude)/(WaveCreation_NumLevels-1)		// volts
			String /G OutputStim_Signal	= "ExtracellularSIU"   		//  possibly output signal
			Execute "WaveCreationPanel()"
			SetDataFolder dfSave	
			Execute "CreateNullStimWave()"
		else
			DoWindow/K WaveCreationPanel
			Execute "WaveCreationPanel()"
		endif
		SaveExperiment
		//NewPath /C/M="Choose folder for Waves Created"/O/Q/Z WaveCreatedPath
	else
		Print "You must first initialize global variables with procedure 'InitializedDataAcquisition()' "
	endif
end

Function CreateNullStimWave()		// Creates a null stim wave (0 amplitude)
	NVAR WaveCreation_Length	=	root:WaveCreation:WaveCreation_Length
	NVAR AcqResolution=  root:DataAcquisitionVar:AcqResolution
	string NullWaveName = "_none_"
	
	Make/O/N=(WaveCreation_Length*AcqResolution)  $NullWaveName
	SetScale /P x 0, (1/AcqResolution), "sec", $NullWaveName
	WAVE NullStimWave = $NullWaveName
	NullStimWave=0
end		
		
		
		
Function NoiseTypePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR WaveCreation_RandomType=root:WaveCreation:WaveCreation_RandomType
	WaveCreation_RandomType=popStr
End

Window WaveCreationPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(828,72,1421,498)
	ModifyPanel cbRGB=(65280,65280,32768)
	ShowTools
	SetDrawLayer UserBack
	SetDrawEnv fillpat= 65,fillfgc= (65280,65280,32768)
	DrawRRect 11,4,232,34
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 31,29,"Wave Creation Panel v.5"
	DrawText 47,182,"Uniform single frequency train"
	DrawText 351,242,"Recovery Pulse"
	DrawText 48,315,"Random Train"
	DrawLine 14,160,437,160
	DrawLine 32,227,237,227
	DrawText 35,99,"Square pulse"
	DrawText 264,100,"Alpha function"
	DrawText 54,251,"Set of uniform freq trains"
	DrawLine 19,290,442,290
	DrawLine 17,359,440,359
	Button WaveCreation_MakeWavesButton,pos={318,7},size={219,26},proc=MakeWaves,title="Make Waves"
	SetVariable LengthSetVar,pos={19,38},size={180,16},title="Length of wave (sec)"
	SetVariable LengthSetVar,limits={0.001,100,0.5},value= root:WaveCreation:WaveCreation_Length
	SetVariable StimDurSetVar,pos={12,118},size={200,16},title="Stim Pulse Duration (sec)"
	SetVariable StimDurSetVar,limits={1e-05,0.1,5e-05},value= root:WaveCreation:WaveCreation_StimDuration
	SetVariable AmpSetVar,pos={13,101},size={122,16},title="Amplitude (V)"
	SetVariable AmpSetVar,limits={-1,10,1},value= root:WaveCreation:SquarePulse_Amplitude_V
	SetVariable StimBufferSetVar,pos={17,61},size={238,16},title="Delay before initial Stimulus (sec)"
	SetVariable StimBufferSetVar,limits={0,inf,0.1},value= root:WaveCreation:WaveCreation_Delay
	CheckBox SIUBiphasicCheck,pos={36,139},size={64,14},proc=WC__BiphasicCheckProc,title="Biphasic?"
	CheckBox SIUBiphasicCheck,value= 1
	SetVariable StimWNameUniSetVar,pos={299,180},size={236,16},title="Base Wave Name"
	SetVariable StimWNameUniSetVar,value= root:WaveCreation:WaveCreation_BasenameUni
	SetVariable NumPulsesSetVar,pos={327,206},size={169,16},title="# pulse in train             "
	SetVariable NumPulsesSetVar,limits={1,100,1},value= root:WaveCreation:WaveCreation_NumPulses
	SetVariable setvar2,pos={40,189},size={170,16},title="InterPulse Interval (sec)"
	SetVariable setvar2,limits={0.001,1,0.001},value= root:WaveCreation:WaveCreation_InterPulseInterval
	ValDisplay valdisp0,pos={41,208},size={172,14},title="Frequency (Hz)             "
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #" root:WaveCreation:WaveCreation_StimFrequency"
	CheckBox InvertStimCheck,pos={106,139},size={87,14},proc=WC_InvertCheckProc,title="Invert Stimulus"
	CheckBox InvertStimCheck,value= 1
	SetVariable RecovDelaySetVar,pos={353,246},size={140,16},title="Delay (sec)"
	SetVariable RecovDelaySetVar,limits={0,100,0.05},value= root:WaveCreation:WC_RecoveryDelay
	CheckBox RecovPulseCheck,pos={335,228},size={16,14},proc=UseRecovCheckProc,title=""
	CheckBox RecovPulseCheck,value= 1
	CheckBox UseUniformFreqTrainCheck,pos={31,167},size={16,14},proc=UseUniFreqCheckProc,title=""
	CheckBox UseUniformFreqTrainCheck,value= 0
	CheckBox UseRandomTrainCheck,pos={31,300},size={16,14},proc=UseRandomTrainCheckProc,title=""
	CheckBox UseRandomTrainCheck,value= 0
	PopupMenu RandTrainTypePopup,pos={22,325},size={81,21},proc=NoiseTypePopMenuProc
	PopupMenu RandTrainTypePopup,mode=2,popvalue="Gaussian",value= #"\"Poisson;Gaussian\""
	SetVariable RandTrainFreqSetVar,pos={107,327},size={169,16},title="Average Frequency (Hz)"
	SetVariable RandTrainFreqSetVar,limits={0,1000,1},value= root:WaveCreation:WaveCreation_AvgFreq
	SetVariable RandTrainMinIntSetVar,pos={278,325},size={170,16},title="Minimum interval (sec)"
	SetVariable RandTrainMinIntSetVar,limits={0,1,0.001},value= root:WaveCreation:WaveCreation_MinInterval
	SetVariable StimWNameRandSetVar,pos={150,299},size={277,16},title="Wave Name to be created"
	SetVariable StimWNameRandSetVar,value= root:WaveCreation:WaveCreation_BasenameRand
	CheckBox UseSetTrainsCheckBox,pos={27,234},size={16,14},proc=UseSetofUniFreqCheckProc,title=""
	CheckBox UseSetTrainsCheckBox,value= 1
	CheckBox UseAlphaCheckBox,pos={247,86},size={16,14},proc=UseAlphaCheckProc,title=""
	CheckBox UseAlphaCheckBox,value= 0
	SetVariable setvar0,pos={268,104},size={122,16},title="Amplitude (V)"
	SetVariable setvar0,limits={-0.1,0.1,0.005},value= root:WaveCreation:AlphaAmplitude_V
	SetVariable setvar1,pos={278,124},size={101,16},title="onset tau"
	SetVariable setvar1,limits={0.001,1,0.001},value= root:WaveCreation:tau1
	SetVariable setvar101,pos={383,123},size={101,16},title="offset tau"
	SetVariable setvar101,limits={0.001,1,0.001},value= root:WaveCreation:tau2
	PopupMenu OutSignalSelectPopup,pos={264,42},size={165,21},proc=GetDACOutGain,title="OutputSelection"
	PopupMenu OutSignalSelectPopup,mode=1,popvalue="Command",value= #"\"ExtracellularSIU;Command\""
	ValDisplay valdisp1,pos={364,64},size={105,14},title="DAC gain:"
	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp1,value= #"root:WaveCreation:WaveCreation_Gain"
	SetVariable setvar3,pos={396,103},size={84,16},title="(nA)"
	SetVariable setvar3,limits={0,1,0.01},value= root:WaveCreation:AlphaAmplitude_nA
	SetVariable setvar4,pos={138,101},size={80,16},title="(nA)"
	SetVariable setvar4,value= root:WaveCreation:SquarePulse_Amplitude_nA
	SetVariable StimWNameUniSetVar0101,pos={26,255},size={236,16},title="list of intervals"
	SetVariable StimWNameUniSetVar0101,value= root:WaveCreation:WC_SetofIntervals
	PopupMenu WaveSelectPopup,pos={57,365},size={284,21},title="Select an Arbitrary Pulse Timing Wave"
	PopupMenu WaveSelectPopup,mode=47,popvalue="StimRand1_t",value= #"Wavelist(\"*\",\";\",\"\")"
	SetVariable SelectWaveStimSetVar,pos={42,393},size={223,16},title="Rename"
	SetVariable SelectWaveStimSetVar,value= root:WaveCreation:WaveCreation_RenameSelect
	CheckBox UseSelectWaveCheck,pos={35,369},size={16,14},proc=UseSelectWaveCheckProc,title=""
	CheckBox UseSelectWaveCheck,value= 0
EndMacro

Function WC__BiphasicCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR WaveCreation_Biphasic =  root:WaveCreation:WaveCreation_Biphasic
	WaveCreation_Biphasic = checked
	print "Changing biphasic check to " num2str(WaveCreation_Biphasic)
End

Function WC_InvertCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR WaveCreation_InvertStim =  root:WaveCreation:WaveCreation_InvertStim
	WaveCreation_InvertStim = checked
	print "Changing invert check to " num2str(WaveCreation_InvertStim)
End

Function UseSelectWaveCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR UseSelectWave = root:WaveCreation:WC_UseSelectWaveCheck
	NVAR UseUniFreq = root:WaveCreation:WC_UseUniformFreqTrainCheck
	NVAR UseRandTrain = root:WaveCreation:WC_UseRandomTrainCheck
	NVAR UseSetofTrainCheck = root:WaveCreation:WC_UseSetofTrainCheck
	SVAR WaveCreation_BasenameUni = root:WaveCreation:WaveCreation_BasenameUni
	UseSelectWave=checked
	print "Changing UseSelectWave check to " num2str(UseSelectWave)
	if(UseSelectWave)
		UseRandTrain=0		// if checking yes to Uniform, uncheck Random
		UseSetofTrainCheck=0	//  uncheck set of trains
		UseUniFreq=0
		//print "  Changing useRand check to " num2str(UseRandTrain)
	else
		//UseRandTrain=1		// if unchecking Uniform, check yes to Random
		//print "  Changing useRand check to " num2str(UseRandTrain)
	endif
	Dowindow/F WaveCreationPanel
	CheckBox UseRandomTrainCheck,value= UseRandTrain			// redraw checkboxes to update changes
	CheckBox UseSetTrainsCheckBox,value=UseSetofTrainCheck
	CheckBox UseUniformFreqTrainCheck,value= UseUniFreq	
End

Function UseSetofUniFreqCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	print ctrlName
	print checked
	NVAR UseSelectWave = root:WaveCreation:WC_UseSelectWaveCheck
	NVAR UseUniFreq = root:WaveCreation:WC_UseUniformFreqTrainCheck
	NVAR UseRandTrain = root:WaveCreation:WC_UseRandomTrainCheck
	NVAR UseSetofTrainCheck = root:WaveCreation:WC_UseSetofTrainCheck
	SVAR WaveCreation_BasenameUni = root:WaveCreation:WaveCreation_BasenameUni
	UseSetofTrainCheck=checked
	print "Changing UseSetofTrainCheck to " num2str(UseSetofTrainCheck)
	if(UseSetofTrainCheck)
		UseRandTrain=0		// if checking yes to Uniform, uncheck Random
		UseUniFreq=0		//  uncheck uniform freq
		UseSelectWave=0
		print "  Changing UseUniFreq to " num2str(UseUniFreq)
		print "  Changing UseRandTrain to " num2str(UseRandTrain)
	else
		//UseRandTrain=1		// if unchecking Uniform, check yes to Random
		//print "  Changing useRand check to " num2str(UseRandTrain)
	endif
	Dowindow/F WaveCreationPanel
	CheckBox UseUniformFreqTrainCheck,value= UseUniFreq	
	CheckBox UseRandomTrainCheck,value= UseRandTrain		// redraw checkboxes to update changes
	CheckBox UseSelectWaveCheck,value= UseSelectWave
End

Function UseUniFreqCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR UseSelectWave = root:WaveCreation:WC_UseSelectWaveCheck
	NVAR UseUniFreq = root:WaveCreation:WC_UseUniformFreqTrainCheck
	NVAR UseRandTrain = root:WaveCreation:WC_UseRandomTrainCheck
	NVAR UseSetofTrainCheck = root:WaveCreation:WC_UseSetofTrainCheck
	SVAR WaveCreation_BasenameUni = root:WaveCreation:WaveCreation_BasenameUni
	UseUniFreq=checked
	print "Changing UseUniFreq check to " num2str(UseUniFreq)
	if(UseUniFreq)
		UseRandTrain=0		// if checking yes to Uniform, uncheck Random
		UseSetofTrainCheck=0	//  uncheck set of trains
		UseSelectWave=0
		//print "  Changing useRand check to " num2str(UseRandTrain)
	else
		//UseRandTrain=1		// if unchecking Uniform, check yes to Random
		//print "  Changing useRand check to " num2str(UseRandTrain)
	endif
	Dowindow/F WaveCreationPanel
	CheckBox UseRandomTrainCheck,value= UseRandTrain			// redraw checkboxes to update changes
	CheckBox UseSetTrainsCheckBox,value=UseSetofTrainCheck
	CheckBox UseSelectWaveCheck,value= UseSelectWave
End

Function UseRandomTrainCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR UseSelectWave = root:WaveCreation:WC_UseSelectWaveCheck
	NVAR UseRandTrain = root:WaveCreation:WC_UseRandomTrainCheck
	NVAR UseUniFreq = root:WaveCreation:WC_UseUniformFreqTrainCheck
	NVAR UseSetofTrainCheck = root:WaveCreation:WC_UseSetofTrainCheck
	SVAR WaveCreation_BasenameRand = root:WaveCreation:WaveCreation_BasenameRand
	UseRandTrain = checked
	print "Changing useRand check to " num2str(UseRandTrain)
	if(UseRandTrain)
		UseUniFreq=0		// if checking yes to Rand, uncheck Uniform
		UseSetofTrainCheck=0	//  uncheck set of trains
		UseSelectWave=0
		//print "  Changing UseUniFreq check to " num2str(UseUniFreq)
	else
		//UseUniFreq=1		// if unchecking Rand, check yes to Uniform
		//print "  Changing UseUniFreq check to " num2str(UseUniFreq)
	endif
	Dowindow/F WaveCreationPanel
	CheckBox UseUniformFreqTrainCheck,value= UseUniFreq		// redraw checkboxes to update changes
	CheckBox UseSetTrainsCheckBox,value=UseSetofTrainCheck
	CheckBox UseSelectWaveCheck,value= UseSelectWave
End

Function UseRecovCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR UseRecov = root:WaveCreation:WC_UseRecoveryPulseCheck
	UseRecov=checked
	print "Changing UseRecov check to " num2str(UseRecov)

End

function Kill_WaveCreation_windows()
	DoWindow/K WaveCreation_Display	
end
	


function MakeWaves(ctrlname) 		: ButtonControl
	string ctrlname
	//// Make sure the experiment is saved and therefore named
	if (StringMatch(IgorInfo(1),"Untitled"))	
		Print "\tAborting -- experiment not saved!"
		SetDataFolder root:
		Abort "You'd better save your experiment first!"
	endif
	string dfsave=GetDataFolder(1)
	SetDataFolder root:WaveCreation
	NVAR AcqResolution=  root:DataAcquisitionVar:AcqResolution
	NVAR BoardID =	root:NIDAQBoardVar:Boardid
	SVAR OutputStim_Signal	=	 root:WaveCreation:OutputStim_Signal
	NVAR WavetypeVar 		= 	root:WaveCreation:WavetypeVar
	String CommandStr
	variable err	
	variable i=0
	Variable j=0
	variable k=0
	string DoColorStyle = "ColorStyleMacro()"
	Make/N=4/O WC__StimWaveDisplay_pos
	Variable LeftPos=364				// variables for positioning graph windows for this module
	Variable TopPos=310
	Variable rightPos =704
	Variable Graph_Height=150
	//variable Graph_Width = 220
	//variable Graph_grout = 10
	WC__StimWaveDisplay_pos={LeftPos,TopPos,RightPos,TopPos+Graph_Height}
	variable x1,x2,x3,x4
	variable flip
// write Wave Creation panel parameters to notebook
// all the panel variables:

			
	NVAR WaveCreation_Length			=	root:WaveCreation:WaveCreation_Length
	NVAR WaveCreation_Delay 			= 	root:WaveCreation:WaveCreation_Delay		
	Variable Delay 						= WaveCreation_Delay						// appears in random trains - why ?? remove
	NVAR WaveCreation_Gain 			= 	root:WaveCreation:WaveCreation_Gain
	NVAR WaveCreation_StimDuration 		= 	root:WaveCreation:WaveCreation_StimDuration 	// duration of electrical stimulus (sec;  e.g. 100microsec)
	NVAR WaveCreation_Biphasic			=	root:WaveCreation:WaveCreation_Biphasic
	NVAR WaveCreation_InvertStim		=	root:WaveCreation:WaveCreation_InvertStim
	// Uniform Freq Params
	NVAR WaveCreation_stimfrequency	= 	root:WaveCreation:WaveCreation_stimfrequency
	NVAR WaveCreation_InterPulseInterval 	= 	root:WaveCreation:WaveCreation_InterPulseInterval
	NVAR WaveCreation_numPulses 		= 	root:WaveCreation:WaveCreation_numPulses
	NVAR WC_UseUniformFreqTrainCheck	=	root:WaveCreation:WC_UseUniformFreqTrainCheck	
	NVAR WC_UseRecoveryPulseCheck	=	root:WaveCreation:WC_UseRecoveryPulseCheck	
	NVAR WC_UseSelectWaveCheck		=	root:WaveCreation:WC_UseSelectWaveCheck
	NVAR WC_RecoveryDelay				=	root:WaveCreation:WC_RecoveryDelay		// sec	
	///Set of freq params
	NVAR WC_UseSetofTrainCheck 		= 	root:WaveCreation:WC_UseSetofTrainCheck
	SVAR WC_SetofIntervals				= 	root:WaveCreation:WC_SetofIntervals
	SVAR WC_SetofFreq					= 	root:WaveCreation:WC_SetofFreq
	WC_SetofFreq =""
	/// Load alpha params
	NVAR UseSquarePulseCheck			=	root:WaveCreation:UseSquarePulseCheck
	NVAR UseAlphaCheck				=	root:WaveCreation:UseAlphaCheck
	NVAR SquarePulse_Amplitude_V		= 	root:WaveCreation:SquarePulse_Amplitude_V
	NVAR SquarePulse_Amplitude_nA		= 	root:WaveCreation:SquarePulse_Amplitude_nA

	NVAR AlphaAmplitude_nA				=	root:WaveCreation:AlphaAmplitude_nA
	NVAR AlphaAmplitude_V				=	root:WaveCreation:AlphaAmplitude_V
	NVAR  tau1							=	root:WaveCreation:tau1
	NVAR tau2							=	root:WaveCreation:tau2
	
	// Random train params:
	NVAR  WC_UseRandomTrainCheck	=	root:WaveCreation:WC_UseRandomTrainCheck 	
	SVAR  WaveCreation_RandomType		=	root:WaveCreation:WaveCreation_RandomType		
	NVAR  WaveCreation_AvgFreq			=	root:WaveCreation:WaveCreation_AvgFreq		
	NVAR  WaveCreation_MinInterval		=	root:WaveCreation:WaveCreation_MinInterval	
	
	print "Starting Wave Creation Routine    " + time()
	//print "     creating "  + stimWaveName
	variable minimumPostStimBuffer		= 0.050		// require that there be at least 50 ms after last stimulus
	
	If(WC_UseSetofTrainCheck ||  WC_UseUniformFreqTrainCheck)
		variable Le= (WaveCreation_numPulses-1)*(WaveCreation_InterPulseInterval+WaveCreation_StimDuration)+ WaveCreation_Delay+minimumPostStimBuffer
		if(WC_UseRecoverypulseCheck)
			Le+=WC_RecoveryDelay
		endif
		if( WaveCreation_Length  <= Le)
			SetDataFolder root:
			Commandstr=" The total length must be greater than " + num2str(Le) + " seconds long"
			abort commandStr
		endif
	endif
	
	Variable totalWavePoints = AcqResolution *WaveCreation_Length
//  check that interstim interval is > stimduration
/// Create stimulus wave names
	SetDataFolder root:
	

	
	if(WC_UseSetofTrainCheck)
		SVAR StimwaveNameBase		=	root:WaveCreation:WaveCreation_Basename
		variable NumSetIntervals			=	 itemsinlist(WC_SetofIntervals,";")
		variable index =0
		string string_interval
		variable temp_freqvar
		variable temp_interval
		String StimTimesWaveName
		Make/T/O/N=(numsetIntervals)	SetTrainsStimWavenames, SetStimTimesWaveNames
		do
			string_interval=stringfromlist(index,WC_SetofIntervals,";")
			temp_interval=str2num(string_interval )
			temp_freqvar= round(1000/temp_interval)
			WC_SetofFreq+= num2str(temp_freqvar) +";"
			SetTrainsStimWavenames[index]	=	Stimwavenamebase + "_"+ num2str(temp_freqvar) + "Hz"
			SetStimTimesWaveNames[index]	=	SetTrainsStimWavenames[index] + "_t"
			print SetTrainsStimWavenames[index],SetStimTimesWaveNames[index]
			Make/O/N=(totalWavePoints)   $(SetTrainsStimWavenames[index])
			SetScale /P x 0, (1/AcqResolution), "sec",  $(SetTrainsStimWavenames[index])
			Make/O/n=1 $SetStimTimesWaveNames[index]
			index+=1
		while(index<NumSetIntervals)
	else
		if(WC_UseSelectWaveCheck)																		////////////////////////newly added 7/26/06
			controlinfo  WaveSelectPopup					// Popup selects wave containing (arbitrary) pulse times
			if(V_flag)
				string currentwaveselected =S_value
			else
				abort "missing wave selection"
			endif
			WAVE currentWaveSelect = root:$currentwaveselected
			edit currentWaveSelect
			variable WaveSelectNumPulses = numpnts(currentWaveSelect)			// how many pulses = # of pnts in selected intervals wave
			Wavestats /Q currentwaveSelect
			variable WaveSelectTotLength = V_max 		// total length must be at least sum of intervals
			
			if( WaveCreation_Length  < WaveSelectTotLength)
				SetDataFolder root:
				Commandstr=" The total length must be greater than " + num2str(WaveSelectTotLength) + " seconds long"
				abort commandStr
			endif
			//controlInfo SelectWaveStimSetVar
			SVAR StimwaveName		=	root:WaveCreation:WaveCreation_RenameSelect	
			StimTimesWaveName =StimwaveName +"_t"	
			duplicate /O currentWaveSelect, $StimTimesWaveName
			appendtotable $StimTimesWaveName
			Make/O/N=(totalWavePoints)   $StimwaveName
			SetScale /P x 0, (1/AcqResolution), "sec",  $StimwaveName
		
		else
			if(WC_UseUniformFreqTrainCheck)
				SVAR StimwaveName		=	root:WaveCreation:WaveCreation_BasenameUni
			else
				SVAR StimwaveName		=	root:WaveCreation:WaveCreation_BasenameRand	// if Random wave only other choice right now
				String StimIntWaveName = StimwaveName +"_int"		
				Make/O/N=1   $StimIntWaveName
			endif
			
			 StimTimesWaveName = StimwaveName +"_t"		
			Make/O/N=(totalWavePoints)   $StimwaveName
			SetScale /P x 0, (1/AcqResolution), "sec",  $StimwaveName
			Make/O/n=1 $StimTimesWaveName
		endif
		
	endif
	
// Write to notebook channels & gains
	Notebook Parameter_Log ruler=Title, text="\r\rStarting WaveCreation v.3 routine" +"\r"
	Notebook Parameter_Log ruler=Normal, text ="\t" +Date() + "  " + time() + "\r\r"
	
	Notebook Parameter_Log ruler=Normal, text ="\r\tExpected signal:  \t" + OutputStim_Signal
	Notebook Parameter_Log ruler=normal, text="\r\t Resolution (samples/sec) :\t" + num2str(AcqResolution)
	Notebook Parameter_Log ruler =normal, text="\r\tTotal Wave Length (sec): \t" + num2str(WaveCreation_Length )
	Notebook Parameter_Log ruler =normal, text="\r\tStimulus Wave Creation parameters:"
	Notebook Parameter_Log ruler =normal, text="\r\t     Delay before first pulse (sec):  \t"  + num2str(WaveCreation_Delay)
	if(WC_UseUniformFreqTrainCheck||WC_UseSetofTrainCheck )
		Notebook Parameter_Log ruler =normal, text="\r\t Using Train(s) of Constant Frequency "
		Notebook Parameter_Log ruler =normal, text="\r\t     Number of pulses:  \t"  + num2str(WaveCreation_numpulses)
		if(WaveCreation_numpulses>1)
			if(WC_UseSetofTrainCheck)
				Notebook Parameter_Log ruler =normal, text="\r\t    Number of frequency train sets  (ms): \t" +  num2str(NumSetIntervals)
				Notebook Parameter_Log ruler =normal, text="\r\t    Set of inter-pulse intervals  (ms): \t" + 	WC_SetofIntervals
				Notebook Parameter_Log ruler =normal, text="\r\t     Set of stimulus frequencies (Hz):  \t" +	WC_SetofFreq
			else
				Notebook Parameter_Log ruler=Normal, text ="\tName of wave to be created: \t" +StimwaveName	
				Notebook Parameter_Log ruler =normal, text="\r\t     Inter-pulse interval of train (sec): \t" + num2str(WaveCreation_interpulseinterval)
				Notebook Parameter_Log ruler =normal, text="\r\t     Stimulus frequency (Hz):  \t" + num2str(WaveCreation_stimfrequency)
			endif
		endif
		if(WC_UseRecoveryPulseCheck)
			Notebook Parameter_Log ruler =normal, text="\r\t     Recovery pulse at delay of (sec):  \t"  + num2str(WC_RecoveryDelay)
		endif
	endif
	if(WC_UseRandomTrainCheck)
		Notebook Parameter_Log ruler=Normal, text ="\tName of wave to be created: \t" +StimwaveName	
		Notebook Parameter_Log ruler =normal, text="\r\t Using Random Train of type :" + WaveCreation_RandomType			
		Notebook Parameter_Log ruler =normal, text="\r\t    Average frequency (Hz):  \t" + num2str( WaveCreation_AvgFreq)			
		Notebook Parameter_Log ruler =normal, text="\r\t    Minimum interval between pulses (sec): \t" + num2str(WaveCreation_MinInterval)		
	endif
	if(WC_UseSelectWaveCheck)
		Notebook Parameter_Log ruler=Normal, text ="\tName of wave to be created: \t" +StimwaveName	
		Notebook Parameter_Log ruler =normal, text="\r\t Selected Wave used as template :" + currentwaveselected			
	endif
	if(UseSquarePulseCheck)
		Notebook Parameter_Log ruler =normal, text="\r\t     Pulse Duration (sec): \t" + num2str(WaveCreation_Stimduration)
		if(WaveCreation_Biphasic)
			Notebook Parameter_Log ruler =normal, text="\r\t     Pulse is biphasic. "
		endif
		Notebook Parameter_Log ruler =normal, text="\r\t     Pulse Amplitude (V): \t" + num2str(SquarePulse_Amplitude_V)
	endif
	if(UseAlphaCheck)
		Notebook Parameter_Log ruler =normal, text="\r\tUsing alpha function pulse:"
		Notebook Parameter_Log ruler =normal, text="\r\t   amplitude: " + num2str(AlphaAmplitude_nA)
		Notebook Parameter_Log ruler =normal, text="\r\t   onset tau: " + num2str(1000*tau1) + " ms, offset tau: " + num2str(1000*tau2) + " ms\r"
	endif

	
	
	

	///////////////////////////////////////////////////////////// Create Basic waveform: square pulse or alpha function
	// Create square wave base waveform:
	variable Amplitude
	string labeltext = "(mV)"
	if(UseSquarePulseCheck)
		print "square pulse"
		if(WavetypeVar==2)
			Amplitude=SquarePulse_Amplitude_nA
			labeltext = "(pA)"
			print num2str(amplitude) + labeltext
		else
			Amplitude=SquarePulse_Amplitude_V
			print num2str(amplitude) + labeltext
			if(WavetypeVar==1 )
				if( (abs(Amplitude)>=0.06))		// make sure don't accidentally use large voltage meant for SIU on cell directly in Vclamp
					SetDatafolder root:
					Abort "Must use smaller amplitude wave for Vclamp voltage step signal - don't fry the cell!"
				endif
			endif
		endif
		Make/O/N=(WaveCreation_stimduration*AcqResolution) BaseWaveform
		SetScale /P x 0, (1/AcqResolution), "sec", BaseWaveform
		BaseWaveform=0
		variable StimDur_BiPoints
		variable p1,p2,p3,p4
		if(WaveCreation_Biphasic)
			StimDur_BiPoints=floor(WaveCreation_stimduration/3  * AcqResolution)
			print "# points in Stim wave step  :", num2str(StimDur_BiPoints)
		endif
		if(WaveCreation_InvertStim)
			flip=-1
		else
			flip=1
		endif
		x1=0
		p1=0
		if(WaveCreation_Biphasic)					// change to use calculate # points & use points evenly
			x2=x1+ WaveCreation_stimduration/3	// for biphasic stimulation
			x3=x2+ WaveCreation_stimduration/3	
			x4=x3+WaveCreation_stimduration/3
			p2=p1+StimDur_BiPoints-1
			p3=p2+StimDur_BiPoints+1
			p4=p3+StimDur_BiPoints-1
			print " points are:  " ,p1,p2,p3,p4
			BaseWaveform[p1,p2]= flip*Amplitude
			BaseWaveform[p3,p4]=flip*(-1)*Amplitude
		else
			x2=x1+ WaveCreation_stimduration
			p2=x2pnt(BaseWaveform,x2)
			BaseWaveform[p1,p2]= flip*Amplitude
		endif
	endif
	// Create alpha wave waveform:
	if(UseAlphaCheck)
		if(WavetypeVar==2)
			Amplitude=AlphaAmplitude_nA
			labeltext = "(pA)"
		else
			Amplitude=AlphaAmplitude_V
		endif
		print num2str(amplitude) + labeltext
	
		variable alphaDuration =5*(tau1+tau2)			// guessing that 3x onset + offset taus will cover waveform
		Make/O/N=(alphaDuration*AcqResolution) BaseWaveform
		SetScale /P x 0, (1/AcqResolution), "sec", BaseWaveform
		BaseWaveform=Amplitude*(exp(-x/tau2)*(1-exp(-x/tau1)))
	endif
	// OUTPUT WAVE CREATION:  Going to SIU:
	variable LocalInterval
	variable numLoops
	index=0
	do
		if(WC_UseSetofTrainCheck)
			string_interval=stringfromlist(index,WC_SetofIntervals,";")
			localinterval = str2num(string_interval)/1000			// convert ms to sec
			print "interval : " + num2str(localinterval)
			numLoops=NumSetIntervals
			print SetTrainsStimWavenames[index]
			WAVE tempStimWave =$SetTrainsStimWavenames[index]
			Wave timesWave=$SetStimTimesWaveNames[index]
			
		else
			localinterval = WaveCreation_InterPulseInterval
			numLoops=1
			WAVE tempStimWave = $StimwaveName
			Wave timesWave= $StimTimesWaveName
			wave intwave =  $StimIntWaveName
		endif
		print "numloops:   " + num2str(numLoops)
		tempStimWave=0
		/// If using the uniform frequency wave type:		
		if(WC_UseUniformFreqTrainCheck || WC_UseSetofTrainCheck)  //

			x1=WaveCreation_Delay// first time, this is 1st onset
			i=0
			do
				tempStimWave[x2pnt(tempStimWave,x1)]= 1
				timesWave[i]={x1}
				x1+=localinterval       //WaveCreation_InterPulseInterval
				i+=1
			while(i<WaveCreation_numPulses)
			// append recovery pulse:
			if(WC_UseRecoverypulseCheck)
				x1+=WC_RecoveryDelay-localinterval     //WaveCreation_InterPulseInterval
				tempStimWave[x2pnt(tempStimWave,x1)]= 1
				timesWave[i]={x1}
			endif
		else
			if(WC_UseRandomTrainCheck)			/// If using random wave train
				variable Rand_interval=0
				x1=WaveCreation_Delay			// make first stim at same initial delay as other waves; not using 'Delay' variable??
				tempStimWave[x2pnt(tempStimWave,x1)]= 1
				timesWave[0]={x1}
				i=1		// move on to next stim
				do
					do
						if(stringmatch(WaveCreation_RandomType, "Poisson"))
								SetDataFolder root:
								Abort "pnoise doesn't work in Igor 6 - need to edit WaveCreationPanel v.4 to update"
							//Rand_interval = (pnoise(1000/WaveCreation_AvgFreq))/1000	// choose something between 0 and some max		
						else
							if(stringmatch(WAveCreation_RandomType,"Gaussian"))
								Rand_interval = 		1/WaveCreation_AvgFreq  +gnoise(1/(WaveCreation_AvgFreq))
							else
								SetDataFolder root:
								Abort "you must select a type of random distribution"
							endif
						endif
					while(Rand_interval<WaveCreation_MinInterval)		// this line keeps the numbers greater than some minimum
					//print Rand_interval
					
					x1+= Rand_interval			
					if(x1<WaveCreation_Length-minimumPostStimBuffer-WaveCreation_StimDuration)	//use if not too late in wave; otherwise, let do loop go out.
						intwave[i-1]={rand_interval}		//  second stim, first interval
						timesWave[i]={x1}			// second time 
						tempStimWave[x2pnt(tempStimWave,x1)]= 1
					endif
					i+=1
				while(x1<WaveCreation_Length-minimumPostStimBuffer-WaveCreation_StimDuration)	
			else
				if(WC_UseSelectWaveCheck)	
					i=0
					do
						tempStimWave[ x2pnt(tempStimWave, timesWave[i]) ] = 1
						//intwave[i]=timesWave[i+1]-timesWave[i]
						i+=1
					while(i<numpnts(tempStimWave))
					display tempStimWave
				else
					SetDataFolder root:
					Abort "You must select what type of Stimulus Train you would like"
				endif
			endif
		
			//Edit timesWave
		endif
	
		//////////////////////////////////////////////////////Convolve timing wave with basewave:
		Convolve/A BaseWaveform, tempStimWave
	
		if(Amplitude==0) 		// if amplitude is 0 this doesn't work; special case of square pulse & 0 ampl:
			tempStimWave=0
		endif
		Duplicate/O tempStimWave, TempIntendedWave
		tempStimWave/=WaveCreation_Gain
		TempIntendedWave*=1000
		if(index==0)
			DoWindow /K WaveCreation_Display
			Display /W=(WC__StimWaveDisplay_pos[0],WC__StimWaveDisplay_pos[1],WC__StimWaveDisplay_pos[2],WC__StimWaveDisplay_pos[3])  as "Wave Creation Result"
			
			Dowindow/C WaveCreation_Display
		endif
		AppendtoGraph tempStimWave
		//label right "DAC out wave (V)" 
	
		//TextBox/C/N=text1/F=0/A=MT/E StimwaveName
		index+=1
		print index
	while(index<numLoops)
	legend
	Label left "Stimulus wave " 
	if(WC_UseSetofTrainCheck)
		Execute "ColorStyleMacro()"
		Execute "ReplotData(" + num2str(2.5*Amplitude) + ")"
	endif
	if(WC_UseRandomTrainCheck)	
		Dowindow/K IntervalHist
		Make/O/N=1 destIntervalHist
		intwave*=1000
		Histogram /B={0,2,200} intwave, destIntervalHist
		display destIntervalHist
		textbox StimwaveName
		label bottom "Interpulse Interval (ms)"
		Dowindow/C IntervalHist
		WaveStats intwave
		Dowindow/K IntWaveNumbers
		edit intwave
		Dowindow/C IntWaveNumbers
		display intwave
	endif
	Notebook  Parameter_Log ruler =normal, text="\r\r"
	SetDataFolder dfsave
end		


Function UseSquarepulseCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR UseSquarepulse = root:WaveCreation:UseSquarepulseCheck
	NVAR UseAlpha = root:WaveCreation:UseAlphaCheck
	SVAR WaveCreation_BasenameUni = root:WaveCreation:WaveCreation_BasenameUni
	UseSquarepulse=checked
	print "Changing UseSquarepulse to " num2str(UseSquarepulse)
	if(UseSquarepulse)
		UseAlpha=0		// if checking yes to Uniform, uncheck Random
		print "  Changing UseAlphacheck to " num2str(UseAlpha)
	else
		UseAlpha=1		// if unchecking Uniform, check yes to Random
		print "  Changing UseAlpha check to " num2str(UseAlpha)
	endif
	Dowindow/F WaveCreationPanel
	CheckBox UseAlphaCheckBox,value= UseAlpha
End

Function UseAlphaCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR UseSquarepulse = root:WaveCreation:UseSquarepulseCheck
	NVAR UseAlpha = root:WaveCreation:UseAlphaCheck
	SVAR WaveCreation_BasenameUni = root:WaveCreation:WaveCreation_BasenameUni
	UseAlpha=checked
	print "Changing UseAlpha to " num2str(UseAlpha)
	if(UseAlpha)
		UseSquarepulse=0		// if checking yes to Uniform, uncheck Random
		print "  Changing UseSquarepulse to " num2str(UseSquarepulse)
	else
		UseSquarepulse=1		// if unchecking Uniform, check yes to Random
		print "  Changing UseSquarepulse check to " num2str(UseSquarepulse)
	endif
	Dowindow/F WaveCreationPanel
	CheckBox UseSquarepulseCheckBox,value= UseSquarepulse
End

Function GetDACOutGain(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	print popStr
	NVAR WaveCreation_Gain = root:WaveCreation:WaveCreation_Gain
	NVAR WavetypeVar 	= 	root:WaveCreation:WavetypeVar			// 0=siu;1=vclamp; 2=iclamp
	// poplist: "ExtracellularSIU;Command"
	NVAR MuCl_Command_VCl= root:NIDAQBoardVar:MuCl_Command_VCl
	NVAR MuCl_Command_ICl= root:NIDAQBoardVar:MuCl_Command_ICl
	SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
	
	// need to get Iclamp vs Vclamp setting from NIDAQBoardVar
	if(popNum==1)
		WaveCreation_Gain =1
		WavetypeVar=0
	else
		if(popNum==2)
			if(  stringmatch(NowMulticlampMode,"V-clamp"))
				print "Mode is ", NowMulticlampMode
				WaveCreation_Gain = MuCl_Command_VCl
				WavetypeVar=1
			else
				if(  stringmatch(NowMulticlampMode,"I-clamp"))
					WaveCreation_Gain = MuCl_Command_ICl
					WavetypeVar=2
					print "Mode is ", NowMulticlampMode
				else
					print "Error in determining mode - check NIDAQ Switchboard Control and re-select mode"
				endif
			endif
		endif
	endif
	print "changing to wavetype var " + num2str(wavetypeVar) + "  with gain of :"  + num2str(WaveCreation_Gain)
	
End
