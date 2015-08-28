#pragma rtGlobals=1		// Use modern global access method.
//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\WavetoList procs"
//#include "WavetoList procs"
#include <Waves Average>
////FiringCurrentRelationProcs v.3.6MC  :
// now adding new
// v3.5  added prepulse step, directly specify on/off times of prepulse & step
//  v3.4  re-added voltage measure vs trial #  to watch membrane voltage over course of expt
//v3.3 added prepulse variables - prepulse duration adds time to wave acquired, prepulse step applies a single
//   current step prior to the FI relation set of steps 
// v3.2added option to set noise seed to user input value in order to get replicatable noise stimuli
// added wave to save noise level values 
// updated to default to Multiclamp amplifiers
// updated  for new PCs, and nidaq-mx drivers, and nidaqMX Tools   20july2010
// New protocol:  adding noise to the step currents as in  Higgs, et al. 2006
// Rewrote protocol to acquire from low step to high step, looping through noise values and trial# at each
// step before going to next step.
// updated 4/15/03 to accomodate choosing different amplifier.
// updates 4/26/03 to do online analysis of VI curve.
// fixed Evoked stim output bug.  10/6/03

Menu "Initialize Procedures"
	"Initialize FI Relation Parameters",Init_FIRelationControlPanel()
	
end

Menu "Kill Windows"
	"Kill FI Data Acq Graphs",Kill_FI_windows()
end


Proc Init_FIRelationControlPanel()
	// Check to see whether Globals Folder exists (i.e., that the InitializeDataAcquisition procedure 
	// has been run & common global variables exist
	if( DataFolderExists("root:DataAcquisitionVar"))	
		String dfSave=GetDataFolder(1)
		NewDataFolder /O/S root:FIRelation			// Create folder for FI variables
		DoWindow/K FI_rawDataDisplay
		DoWindow/K FI_AvgWaveDisplay
		DoWindow/K FI_RatevsCurrDisplay		
		DoWindow/K FI_VICurveDisplay		
		KillWaves /a/z								// clean out folder & start from scratch
		killvariables /a/z		
		killstrings /a/z
		///  create variables for signal selection:
		string/G Voltage_signal	=	 "PrimaryOutCh1"	
		String/G Current_signal	= 	"SecondaryOutCh1"
		String/G Output_Signal	=	"Command"
		string/G StimOutput_Signal	=	 "_none_"
		//
		
		Variable /G FI_BeforeAfterBuff = 	0.400	//  time before & after step, ms
		Variable /G  FI_StepPulseOn	=  0.6
		Variable /G  FI_StepPulseOff	=  1
		Variable /G FI_StepLength		:=	FI_StepPulseOff-FI_StepPulseOn//sec		// longer default for noise expts
		Variable /G FI_PosMostStep		=	0.35	//nA
		Variable /G FI_NumberSteps		=	6		// # steps in current step protocol
		Variable /G FI_CurrentPerStep		=    0.1	//nA
		Variable /G FI_NegMostStep		:=	FI_PosMostStep - (FI_CurrentPerStep*(FI_NumberSteps-1))//nA
		
		
		Variable /G FI_PrepulseStep		=  0		// in nA
		Variable /G  FI_SetPulseOn	=  0.4
		Variable /G  FI_SetPulseOff	=  0.6
		Variable /G FI_PrepulseDur		:=	FI_SetPulseOff-FI_SetPulseOn	// in sec
		Variable/G FI_TotalWaveLength := 2*FI_BeforeAfterBuff+FI_StepPulseOff
		//Variable/G FI_TotalWaveLength := 3*FI_BeforeAfterBuff+FI_StepLength+FI_PrepulseDur
		Variable /G FI_ISI					=   3		// seconds between steps
		Variable /G FI_RepeatCheck		=	1		// Repeat sets?
		Variable /G FI_NumRepeats		=	1		// Repeat # times
		Variable /G FI_SetNum			=	0		// Label each set of current steps
		String 	/G FI_Basename			:=	"FI_" +root:DataAcquisitionVar:baseName + "s" + num2str(FI_setnum)	// Acquisition waves basename
		Variable /G FI_AverageCheck	=	1		// Calculate averages?
		variable /G FI_nextAvg			=	0
		string 	/G FI_AvgBasename		:=	"FI_" + root:DataAcquisitionVar:baseName  +"_avg" +num2str(FI_nextAvg)// Averaging waves basename
		Variable /G FI_CalcFICheck		=	0			// plot Firing Curve check	
		variable /G FI_SpikeThresh		=	0		// Threshold for counting spikes
		Variable /G FI_FRWindow1		= FI_StepPulseOn
		Variable /G FI_FRWindow2		= FI_StepPulseOff
		// VI curve analysis
		variable /G FI_PlotVICurveCheck1	=  1	// plot VI curve #1 check
		variable /G FI_VIMeasure_t1		=  0.080	// seconds after onset
		variable /G FI_PlotVICurveCheck2	=  1	// plot VI curve #1 check
		variable /G FI_VIMeasure_t2		=  0.190	// seconds after onset
		//
		// Evoked stim parameters:
		variable /G FI_UseEvokStimCheck = 0		// send an evoked stimulus to an SIU during Steps
		string /G FI_EvokStimWaveName = ""	
		string /G FI_DefaultStimWaveName = "FI_EvStimWave0"
		// Noise stim parameters:  SIGNAL - main noise stimulus
		Variable /G FI_NoiseCheck 	=	1	// 0 don't add noise; 1 add noise
		Variable /G  FI_NoiseSD		=   	0.001	// initialize with 0.1 (nA)
		Variable /G FI_NoiseTarget	=    1	// target voltage SD in mV
		Variable /G	FI_NoiseExpTau	=   0.003	// (sec)exponential filter of noise time constant (default 3ms)
		Variable /G FI_NoisetestLength		:=  FI_StepLength		// (sec)  length of test noise stimulus for adjustment
		Variable /G  FI_NoiseVmSD	=	0		// measured voltage SD; initialize to 0
		Variable /G FI_NoiseSeed		=	0		// seeds the noise generation to particular number; initial to random
		Variable /G FI_FreezeNoiseCheck	= 0		//  Check to keep noise waveform constant
		String /G FI_RangeNoiseLevels	= "0;"	// make wave containg range of noise levels (Sigma)
		String /G FI_NoiseWFName	=	"FI_NoiseWF"	// default name for base noise waveform
		//  Adding option to add in corrupting noise on top of signal:
		Variable /G FI_VariableNoiseCheck 	=	0	// 0 don't add noise; 1 add noise
		Variable /G FI_VariableNoiseRatio = 1		// ratio of corruptive noise over normal noise
		Variable /G FI_VariableNoiseSD  := FI_NoiseSD*FI_VariableNoiseRatio
		//
		Variable /G FI_StepDirectionCheck = 0  // sets direction of step increment:  1 = high to low; 0 = low to high
		variable/G FI_DefaultNumstim		= 1
		Variable/G FI_DefaultDelay		= FI_BeforeAfterBuff + 0.100	// time stim to occur 100ms into step
		Variable/G FI_defaultEvStimFreq	= 1	
		String /G FI_PathName = "FIPath"
		
		Execute "FI_ControlPanel()"
		SetDataFolder dfSave
		SaveExperiment
		NewPath /C/M="Choose folder for FI files"/O/Q/Z FIPath
	else
		Print "You must first initialize global variables with procedure 'InitializedDataAcquisition()' "
	endif
end

Window FI_ControlPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(212,350,1133,821)
	ModifyPanel cbRGB=(51664,44236,58982)
	ShowTools
	SetDrawLayer UserBack
	SetDrawEnv fillpat= 15,fillfgc= (32768,54615,65535)
	DrawRRect 427,4,12,30
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 15,28,"Firing-Current Relation Control Panel Multiclamp v3.6"
	SetDrawEnv fillpat= 0
	DrawRect 356,116,401,141
	DrawLine 356,127,341,127
	DrawLine 403,128,415,128
	DrawLine 359,124,400,124
	DrawLine 359,134,400,134
	DrawText 687,397,"[Corrupt/Frozen]"
	SetVariable NumStepsSetVar,pos={52,183},size={136,16},title="Number of Steps "
	SetVariable NumStepsSetVar,limits={1,50,1},value= root:FIRelation:FI_NumberSteps
	SetVariable PosMostStepSetVar_1,pos={23,116},size={177,16},title="Positive Most Step (nA)"
	SetVariable PosMostStepSetVar_1,limits={-1,10,0.05},value= root:FIRelation:FI_PosMostStep
	SetVariable FI_BasenameSetVar,pos={13,36},size={265,16},title="Acquisition Waves Basename"
	SetVariable FI_BasenameSetVar,value= root:FIRelation:FI_Basename
	SetVariable RepeatSetVar,pos={185,78},size={126,16},title="# trials/step/noise:"
	SetVariable RepeatSetVar,limits={1,100,1},value= root:FIRelation:FI_NumRepeats
	SetVariable SetNumSetVar,pos={293,35},size={118,16},title="Current Set #"
	SetVariable SetNumSetVar,value= root:FIRelation:FI_SetNum
	Button FI_AcquireButton,pos={14,296},size={118,50},proc=Acq_FI_data,title="Acquire"
	PopupMenu SelectOutSignalPopup,pos={472,65},size={178,21},proc=FI_UpdateoutSignalProc,title="Output Step Signal"
	PopupMenu SelectOutSignalPopup,mode=2,popvalue="Command",value= #"root:NIDAQBoardVar:OutputNamesString"
	PopupMenu SelectInputSignalPopup,pos={477,22},size={186,21},proc=FI_UpdateVoltSignalProc,title="Vm Input Signal"
	PopupMenu SelectInputSignalPopup,mode=2,popvalue="PrimaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	SetVariable ISISetVar,pos={186,58},size={135,16},title="ISI (sec)           "
	SetVariable ISISetVar,limits={0.1,60,0.1},value= root:FIRelation:FI_ISI
	SetVariable SpikeThreshSetVar,pos={281,303},size={160,16},title="Spike threshold (V)"
	SetVariable SpikeThreshSetVar,limits={-0.1,0.1,0.01},value= root:FIRelation:FI_SpikeThresh
	CheckBox CalcFICheck,pos={184,304},size={79,14},proc=FI_CalcFICheckProc,title="Plot FI Curve"
	CheckBox CalcFICheck,value= 1
	PopupMenu SelectOutStimPopup,pos={497,154},size={241,21},proc=FI_UpdateStimSignalProc,title="Stimulus Output Signal   "
	PopupMenu SelectOutStimPopup,mode=4,popvalue="Extracellular SIU1",value= #"root:NIDAQBoardVar:OutputNamesString"
	CheckBox StimOutCheck,pos={504,115},size={157,14},proc=FI_StimoutCheckProc,title="Use Evoked Stimulus Wave?"
	CheckBox StimOutCheck,value= 0
	PopupMenu ChooseEvokStimWavePopup,pos={523,129},size={106,21},proc=FI_ChooseEvokStimWaveProc,title=" "
	PopupMenu ChooseEvokStimWavePopup,mode=2,popvalue="StimWave_1",value= #"Wavelist(\"*\",\";\",\"\")"
	GroupBox Box1,pos={10,91},size={434,114},title="Variable Steps"
	GroupBox Box3,pos={471,97},size={337,88},title="Synaptic Stimuli"
	GroupBox Box4,pos={470,1},size={257,93},title="Signals"
	PopupMenu FI_CurrentSigMonitorPopup,pos={474,43},size={222,21},proc=FI_UpdateCurrSignalProc,title="Current Input Signal"
	PopupMenu FI_CurrentSigMonitorPopup,mode=3,popvalue="SecondaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	SetVariable SetBufferVar,pos={10,57},size={144,16},title="PreBuffer time"
	SetVariable SetBufferVar,limits={0.1,1,0.1},value= root:FIRelation:FI_BeforeAfterBuff
	SetVariable CurrentPerStepSetVar,pos={85,138},size={119,16},title="nA/ step    "
	SetVariable CurrentPerStepSetVar,limits={0,10,0.05},value= root:FIRelation:FI_CurrentPerStep
	ValDisplay NegMostStepValDisplay,pos={21,161},size={179,14},title="Negative  Most Step (nA)"
	ValDisplay NegMostStepValDisplay,limits={0,0,0},barmisc={0,1000}
	ValDisplay NegMostStepValDisplay,value= #" root:FIRelation:FI_NegMostStep"
	CheckBox StimNoiseCheck,pos={526,302},size={78,14},proc=FI_NoiseCheckProc,title="Apply noise?"
	CheckBox StimNoiseCheck,value= 1
	SetVariable SetNoiseSD,pos={513,224},size={132,16},title="Set Noise SD"
	SetVariable SetNoiseSD,limits={0,10,0.01},value= root:FIRelation:FI_NoiseSD
	ValDisplay NoiseVmSDResultDisplay,pos={507,247},size={179,14},title="Vm SD result (mV)"
	ValDisplay NoiseVmSDResultDisplay,limits={0,0,0},barmisc={0,1000}
	ValDisplay NoiseVmSDResultDisplay,value= #" root:FIRelation:FI_NoiseVmSD"
	Button NoiseCalibrationButton,pos={522,265},size={150,20},proc=RunNoiseCalibrationProc,title="RunNoiseCalibration"
	SetVariable NoiseLevelSet,pos={606,300},size={185,16},title="Noise Levels to Test"
	SetVariable NoiseLevelSet,value= root:FIRelation:FI_RangeNoiseLevels
	CheckBox StepDirectionCheckBox,pos={219,116},size={100,14},proc=StepDirectionCheckProc,title="Step High to Low"
	CheckBox StepDirectionCheckBox,value= 0
	SetVariable NoiseFilter_setvar,pos={688,271},size={146,16},title="Filter Tau (sec)"
	SetVariable NoiseFilter_setvar,limits={0,inf,0.001},value= root:FIRelation:FI_NoiseExpTau
	CheckBox FreezeNoiseCheckBox,pos={667,220},size={132,14},proc=FI_FreezeNoiseCheckProc,title="Freeze Noise Waveform"
	CheckBox FreezeNoiseCheckBox,value= 1
	SetVariable FI_PathnameSetVar1,pos={740,24},size={126,16},title="Path Name"
	SetVariable FI_PathnameSetVar1,value= root:FIRelation:FI_PathName
	SetVariable NoiseSeedsetvar,pos={701,244},size={131,16},title="Noise Seed [0-1]"
	SetVariable NoiseSeedsetvar,limits={0,1,1},value= root:FIRelation:FI_NoiseSeed
	SetVariable SetBufferVar2,pos={23,232},size={161,16},title="Set Step Amplitude (nA)"
	SetVariable SetBufferVar2,limits={-10,10,0.05},value= root:FIRelation:FI_PrepulseStep
	GroupBox Box5,pos={497,202},size={346,125},title="Noise calibration"
	GroupBox Box2,pos={7,207},size={443,81},title="Set Step (Prepulse or Postpulse)"
	ValDisplay StepLength,pos={222,184},size={157,14},title="Step Length (sec)"
	ValDisplay StepLength,limits={0,0,0},barmisc={0,1000}
	ValDisplay StepLength,value= #"root:FIRelation:FI_StepLength"
	SetVariable StepOn_setvar,pos={223,146},size={177,16},title="Step Pulse On (sec)"
	SetVariable StepOn_setvar,limits={0,inf,0.1},value= root:FIRelation:FI_StepPulseOn
	SetVariable StepOn_setvar1,pos={220,164},size={177,16},title="Step Pulse Off (sec)"
	SetVariable StepOn_setvar1,limits={0,inf,0.1},value= root:FIRelation:FI_StepPulseOff
	SetVariable SetStepOn_setvar2,pos={194,227},size={177,16},title="Set Pulse On (sec)"
	SetVariable SetStepOn_setvar2,limits={0.1,inf,0.1},value= root:FIRelation:FI_SetPulseOn
	SetVariable SetPulseoff_setvar3,pos={195,242},size={177,16},title="Set Pulse Off (sec)"
	SetVariable SetPulseoff_setvar3,limits={0,inf,0.1},value= root:FIRelation:FI_SetPulseOff
	ValDisplay SetStepLength1,pos={190,265},size={157,14},title="Set Step Length (sec)"
	ValDisplay SetStepLength1,limits={0,0,0},barmisc={0,1000}
	ValDisplay SetStepLength1,value= #"root:FIRelation:FI_PrepulseDur"
	SetVariable FIAnwin1_setvar2,pos={177,330},size={188,16},title="Analysis Window (sec)  From:"
	SetVariable FIAnwin1_setvar2,limits={0,inf,0.1},value= root:FIRelation:FI_FRWindow1
	SetVariable FIAnwin1_setva01,pos={373,329},size={86,16},title="to:"
	SetVariable FIAnwin1_setva01,limits={0,inf,0.1},value= root:FIRelation:FI_FRWindow2
	GroupBox Box6,pos={147,287},size={343,64},title="FI Curve Analysis"
	GroupBox Noisecorruptbox,pos={496,340},size={329,100},title="Noise Corruption"
	CheckBox FreezeNoiseCheckBox1,pos={667,220},size={132,14},proc=FI_FreezeNoiseCheckProc,title="Freeze Noise Waveform"
	CheckBox FreezeNoiseCheckBox1,value= 1
	CheckBox CorruptNoiseCheckBox2,pos={520,364},size={85,14},proc=FI_CorruptNoiseCheckProc,title="Corrupt Noise "
	CheckBox CorruptNoiseCheckBox2,value= 0
	SetVariable SetVariableNoiseRatio,pos={521,385},size={153,16},title="Corruption Noise Ratio"
	SetVariable SetVariableNoiseRatio,limits={0,10,0.1},value= root:FIRelation:FI_VariableNoiseRatio
	ValDisplay CorruptNoiseSDResultDisplay,pos={523,408},size={179,14},title="Corrupt Noise SD (nA)"
	ValDisplay CorruptNoiseSDResultDisplay,limits={0,0,0},barmisc={0,1000}
	ValDisplay CorruptNoiseSDResultDisplay,value= #"root:FIRelation:FI_VariableNoiseSD"
EndMacro

Function FI_UpdateVoltSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Voltage_Signal=root:FIRelation:Voltage_Signal	
	Voltage_Signal=popStr
	print "Changing FI voltage signal to ", Voltage_Signal
End

Function FI_UpdateCurrSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Current_Signal=root:FIRelation:Current_Signal	
	Current_Signal=popStr
	print "Changing FI Current_Signal to ", Current_Signal
End

Function FI_UpdateoutSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Output_Signal=root:FIRelation:Output_Signal	
	Output_Signal=popStr
	print "Changing FI Output_Signal to ", Output_Signal
End

Function FI_UpdateStimSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR StimOutput_Signal=root:FIRelation:StimOutput_Signal	
	StimOutput_Signal=popStr
	print "Changing FI StimOutput_Signal to ", StimOutput_Signal
End

Function FI_ChooseEvokStimWaveProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR FI_EvokStimWaveName= root:FIRelation:FI_EvokStimWaveName
	FI_EvokStimWaveName =  popStr
End

Function StepDirectionCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FI_StepDirectionCheck =  root:FIRelation:FI_StepDirectionCheck
	FI_StepDirectionCheck = checked
	print "Changing step direction check to " num2str(FI_StepDirectionCheck)
End

Function FI_AvgCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FI_AverageCheck =  root:FIRelation:FI_AverageCheck
	FI_AverageCheck = checked
	print "Changing avg check to " num2str(FI_AverageCheck)
End

Function FI_CalcFICheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FI_CalcFICheck =  root:FIRelation:FI_CalcFICheck
	FI_CalcFICheck = checked
	print "Changing FI calculate check to " num2str(FI_CalcFICheck)
End

Function FI_StimoutCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FI_UseEvokStimCheck =  root:FIRelation:FI_UseEvokStimCheck
	FI_UseEvokStimCheck = checked
	print "Changing UseEvokStimCheck to " num2str(FI_UseEvokStimCheck)
End


function Acq_FI_data(ctrlname) 		: ButtonControl
	string ctrlname
	print  "****Starting Acq_FI_data"
	//// Make sure the experiment is saved and therefore named
	if (StringMatch(IgorInfo(1),"Untitled"))	
		Print "\tAborting -- experiment not saved!"
		SetDataFolder root:
		Abort "You'd better save your experiment first!"
	endif
	Kill_FI_windows()	
	string dfsave=GetDataFolder(1)
	SetDataFolder root:FIRelation	
	String AcqString, WFOutString
	String CommandStr
	variable FI_AvgWindow	=0.010		// sec, window over which to average voltage measurement for VI curve
	variable StartTicks,elapsedTicks
	variable StartingSetNumber,EndingSetNumber
	variable i=0
	Variable j=0
	variable k=0
	Variable LeftPos=30					// variables for positioning graph windows for this module
	Variable TopPos=60
	Variable Graph_Height=200
		variable Graph_Width = 350
	variable Graph_grout = 15
	variable graph_grout_vert	=	20
	variable offsetTick=0
	Variable Voltage_Channel
	Variable Voltage_IndBoardGain
	Variable Voltage_AmpGain
	Variable Current_Channel
	//Variable Current_IndBoardGain
	Variable  Current_AmpGain
	Variable DAC_out_Channel
	Variable DAC_out_AmpGain
	//variable DAC_out_Channel2
	variable	EvokStimOut_Channel
	variable EvokStimOut_AmpGain
	
	String textboxStr
	variable textboxID
	//print "2)  Loaded local variables"
	/// Need to get proper selection of Voltage_Signal,current_Signal,Output_Signal,StimOutputSignal
	SVAR Voltage_Signal =  root:FIRelation:Voltage_Signal	// string to be matched to find voltage channel
	SVAR current_Signal=  root:FIRelation:current_Signal	// string to be matched to find current channel
	SVAR Output_Signal =  root:FIRelation:Output_Signal			// string to be matched to find DAC output to drive current step 
	SVAR StimOutputSignal=  root:FIRelation:StimOutput_Signal
	//
	SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
	If(stringmatch(NowMulticlampMode, "V-Clamp"))
			SetDataFolder root:
			Abort "Use Multiclamp Commander to ensure mode is set to  ' I-Clamp' and update NIDAQ Switchboard"
	endif

//	SVAR Current_AxClMode 	=root:NIDAQBoardVar:Current_AxClMode
//	NVAR  Current_AxClGain	=root:NIDAQBoardVar:Current_AxClGain
//	//
	NVAR UseEvokStimCheck 	=	root:FIRelation:FI_UseEvokStimcheck
	NVAR FI_NoiseCheck		=		root:FIRelation:FI_NoiseCheck
	//print "3) Loaded SVAR & NVAR signals"

// determine correct channel #s for Scaled out (voltage), I output
	//Print "Getting Nidaq ADC/DAC globals"
	NVAR AcqResolution					=  root:DataAcquisitionVar:AcqResolution
	WAVE ADC_ChannelWave			=root:NIDAQBoardVar:ADC_ChannelWave
	WAVE ADC_SignalWave				=root:NIDAQBoardVar:ADC_SignalWave
	//WAVE ADC_IndBoardGainWave		=root:NIDAQBoardVar:ADC_IndBoardGainWave
	WAVE ADC_AmpGainWave			=root:NIDAQBoardVar:ADC_AmpGainWave

	WAVE DAC_SignalWave				=root:NIDAQBoardVar:DAC_SignalWave
	WAVE DAC_Channel_Wave			=root:NIDAQBoardVar:DAC_Channel_Wave
	WAVE DAC_AmpGain_ICl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	
	// Check Evok stimulus control info
	SVAR EvokStimWaveName=  root:FIRelation:FI_EvokStimWaveName
	NVAR UseEvokStimCheck =  root:FIRelation:FI_UseEvokStimCheck
	NVAR BeforeAfterBuff =  root:FIRelation:FI_BeforeAfterBuff
	//BeforeAfterBuff=0.400
	controlinfo  /W=FI_ControlPanel StimOutCheck
	UseEvokStimCheck=V_Value	
	controlinfo /W=FI_ControlPanel ChooseEvokStimWavePopup
	EvokStimWaveName=S_value
	//print "Using evoked stimulus Wave:  " + EvokStimWaveName
	if(stringmatch(EvokStimWaveName,"none"))
		UseEvokStimCheck=0
	endif

// find  channels;determine current amplifier gains for output & input waves;determine individual board gains for input waves
	//print "determining channels & gains"
	string ADCsignalList = ConvertTextWavetoList(ADC_SignalWave)
	string DACsignalList = ConvertTextWavetoList(DAC_SignalWave)
	Voltage_Channel=whichListItem(Voltage_Signal, ADCsignalList)				// channel is equivalent to position in List
	current_Channel=WhichlistItem(current_Signal, ADCsignalList)
	DAC_out_Channel=WhichlistItem(Output_Signal, DACsignalList)
	if(UseEvokStimCheck)
		print "Stim out signal= ", StimOutputSignal
		EvokStimOut_Channel= WhichListItem(StimOutputSignal,DACSignalList)
		EvokStimOut_AmpGain=1
	endif
	if((Voltage_Channel==-1)  || (current_Channel==-1) || (DAC_out_Channel==-1)  )			// check that all have channels
		commandstr = "you must select  channels containing  "+Voltage_Signal +"," +  current_Signal + ", and " + Output_Signal 
		SetDataFolder root:
		Abort commandstr
	endif 
	if(UseEvokStimCheck  & (EvokStimOut_Channel==-1))			// check that all have channels
		commandstr = "you must select  channels containing  "+ StimOutputSignal
		SetDataFolder root:
		Abort commandstr
	endif 
	
	Voltage_AmpGain= ADC_AmpGainWave[Voltage_Channel]
	Current_AmpGain=ADC_AmpGainWave[Current_Channel]
	DAC_out_AmpGain=DAC_AmpGain_ICl_Wave[DAC_out_Channel]
	

	
	//print "4) completed channels and gains"
	//////////////////////////////////////////////////////////////



	Make/N=4/O FI_rawDataDisplay_pos,FI_NowWaveDisplay_pos,FI_RatevsCurrDisplay_pos,FI_OutputWaves_pos,FI_VoltvsCurrDisplay_pos
	FI_rawDataDisplay_pos={LeftPos,TopPos,LeftPos+graph_Width,TopPos+Graph_Height}		// graph in top left
	FI_NowWaveDisplay_pos={LeftPos,TopPos+Graph_Height+Graph_Grout_vert,LeftPos+graph_Width,TopPos+2*Graph_Height+Graph_Grout_vert}	// graph bottom left
	FI_OutputWaves_pos={LeftPos+graph_width+Graph_grout,TopPos,LeftPos+2*graph_Width+Graph_Grout,TopPos+Graph_Height}	// graph top right
	FI_RatevsCurrDisplay_pos={LeftPos+graph_width+Graph_grout,TopPos+Graph_Height+Graph_Grout_vert,LeftPos+2*graph_Width+Graph_Grout,TopPos+2*Graph_Height+Graph_Grout_vert}//graph bottom right
	FI_VoltvsCurrDisplay_pos={LeftPos+graph_width+Graph_grout,TopPos+2*Graph_Height+2*Graph_Grout_vert,LeftPos+2*graph_Width+Graph_Grout,TopPos+3*Graph_Height+2*Graph_Grout_vert}//graph bottom right

// write F-I panel parameters to notebook
// all the panel variables:
	//print "Getting FI panel parameters"

	NVAR FI_StepPulseOn  			=root:FIRelation:FI_StepPulseOn
	NVAR FI_StepPulseOff			=root:FIRelation:FI_StepPulseOff
	NVAR FI_StepLength				=root:FIRelation:FI_StepLength			// in sec
	NVAR FI_NegMostStep			=root:FIRelation:FI_NegMostStep		//in nA
	NVAR FI_PosMostStep			=root:FIRelation:FI_PosMostStep
	NVAR FI_NumberSteps			=root:FIRelation:FI_NumberSteps
	NVAR FI_CurrentPerStep			=root:FIRelation:FI_CurrentPerStep		// in nA
	
	NVAR FI_SetPulseOn				=root:FIRelation:FI_SetPulseOn
	NVAR  FI_SetPulseOff			= root:FIRelation:FI_SetPulseOff
	NVAR FI_PrepulseDur				=root:FIRelation:FI_PrepulseDur
	NVAR FI_PrepulseStep			=root:FIRelation:FI_PrepulseStep
	NVAR FI_TotalWaveLength		=root:FIRelation:FI_TotalWaveLength
	NVAR FI_ISI					=root:FIRelation:FI_ISI					// in sec
	NVAR FI_RepeatCheck			=root:FIRelation:FI_RepeatCheck
	NVAR FI_NumRepeats			=root:FIRelation:FI_NumRepeats
	NVAR FI_SetNum				=root:FIRelation:FI_SetNum
	SVAR FI_Basename				=root:FIRelation:FI_Basename
	SVAR Basename					=root:DataAcquisitionVar:baseName
	String Local_Basename			=	"FI_" +baseName + "s" + num2str(FI_SetNum)	// recalculate a local basename
	NVAR FI_AverageCheck			=root:FIRelation:FI_AverageCheck
	NVAR FI_nextAvg				=root:FIRelation:FI_nextAvg
	SVAR FI_AvgBasename			=root:FIRelation:FI_AvgBasename
	NVAR FI_CalcFICheck			=root:FIRelation:FI_CalcFICheck
	NVAR FI_SpikeThresh			=root:FIRelation:FI_Spikethresh
	NVAR FI_PlotVICurveCheck1		=root:FIRelation:FI_PlotVICurveCheck1
	NVAR FI_VIMeasure_t1			=root:FIRelation:FI_VIMeasure_t1
	NVAR FI_PlotVICurveCheck2		=root:FIRelation:FI_PlotVICurveCheck2
	NVAR FI_VIMeasure_t2			=root:FIRelation:FI_VIMeasure_t2
	NVAR FI_FRWindow1		=root:FIRelation:FI_FRWindow1
	NVAR FI_FRWindow2		=root:FIRelation:FI_FRWindow2
		// new:  noise stim params
	NVAR FI_NoiseSD	 =  root:FIRelation:FI_NoiseSD	
	NVAR FI_NoiseTarget	 =  root:FIRelation:FI_NoiseTarget
	NVAR	FI_NoiseExpTau	 =  root:FIRelation:FI_NoiseExpTau
	NVAR FI_NoisetestLength		 =  root:FIRelation:FI_NoisetestLength
	NVAR FI_NoiseVmSD	 =  root:FIRelation:FI_NoiseVmSD
	SVAR  FI_RangeNoiseLevels =  root:FIRelation:FI_RangeNoiseLevels  // feb11
	print "Noise Levels  :" ,FI_RangeNoiseLevels
	SVAR FI_NoiseWFName =  root:FIRelation:FI_NoiseWFName
	NVAR FI_FreezeNoiseCheck = root:FIRelation:FI_FreezeNoiseCheck
	NVAR FI_NoiseSeed  =  root:FIRelation:FI_NoiseSeed
	controlinfo /W=FI_ControlPanel NoiseSeedsetvar
	FI_NoiseSeed=V_value
	// Variable noise parameters
	NVAR FI_VariableNoiseCheck 	=	 root:FIRelation:FI_VariableNoiseCheck
	NVAR FI_VariableNoiseRatio =  root:FIRelation:FI_VariableNoiseRatio
	NVAR FI_VariableNoiseSD =  root:FIRelation:FI_VariableNoiseSD
	print "  FI_VariableNoiseSD =", FI_VariableNoiseSD
	variable  FI_VarianceNormFactor = 1+sqrt(FI_VariableNoiseRatio)  // normalize the summed signal+corruption back to original variance, instead of sum of variances
		
		
	NVAR FI_StepDirectionCheck  =  root:FIRelation:FI_StepDirectionCheck
	Variable totalWavePoints = AcqResolution * (FI_TotalWaveLength)
	string TextStamp = FI_basename
//	if(UseEvokStimCheck)
//		// save stim wave as a local wave, annoted to belong to this set of FI curves:
//		string EvokStimOutName = Local_Basename + "stim"		// unique to this set
//		WAVE /Z EvokStimWave=root:$EvokStimWaveName
//		if( !waveexists(EvokStimWave))
//			SetDataFolder root:
//			abort "No Wave " + evokStimWaveName + " exists (check folders)"
//		else
//			Duplicate/O  EvokStimWave, $EvokStimOutName		// duplicate the stim wave to modify for our use here (see below)
//			//print "Chosen Stimulus wave is " + EvokStimWaveName
//		endif
//
//		if( numpnts($EvokStimOutName)== totalWavePoints)
//			// "looks ok"
//		else
//			if( numpnts($EvokStimOutName)> totalWavePoints )
//				totalWavePoints=numpnts($EvokStimOutName)
//			else
//				insertpoints numpnts($EvokStimOutName),((totalwavepoints)-numpnts($EvokStimOutName)),  $EvokStimOutName
//				//print "Enlarging the stimulus wave " + EvokStimOutName + " by " + num2str(((totalwavepoints)-numpnts($EvokStimOutName))) + "points"
//				//abort "# of points in " + EvokStimWaveName + " ( " + num2str(numpnts(EvokStimWave)) + ") must equal acquisition waves # points (" + num2str(totalWavePoints) + ")"
//			endif
//		endif
//		///  Show the Stimulus wave:
//		DoWindow/K EvokStimDisplay
//		display/W=(FI_OutputWaves_pos[0],FI_OutputWaves_pos[3]+20,FI_OutputWaves_pos[2],FI_OutputWaves_pos[3]+120)  $EvokStimOutName  as "Evoked Stimulus Output waveform"
//		legend
//		Dowindow/C EvokStimDisplay
//	endif 
	StartingSetNumber=FI_SetNum
// Write to notebook channels & gains
	Notebook Parameter_Log ruler=Title, text="\r\rStarting Firing-current Data Acquisition" +"\r"
	Notebook Parameter_Log ruler=Normal, text ="\tFiringCurrentRelationProcs v.3.5MC  \r\r"
	Notebook Parameter_Log ruler=Normal, text ="\t" +Date() + "  " + time() + "\r\r"
	Notebook Parameter_Log ruler=normal, text="\r\tAcquisition Resolution (samples/sec) :\t" + num2str(AcqResolution)
	Notebook Parameter_Log ruler=normal, text="\r\tVoltage signal : \t"  + Voltage_Signal  +" on channel " +num2str(Voltage_Channel)
	Notebook Parameter_Log ruler=normal, text="\r\tVoltage signal amplifier gain : " + num2str(Voltage_ampGain) 
	Notebook Parameter_Log ruler =normal, text="\r\tCurrent signal : \t"  + current_Signal+" on channel " +num2str(current_Channel)
	Notebook Parameter_Log ruler =normal, text="\r\tCurrent  signal amplifier gain : " + num2str(Current_ampGain)
	Notebook Parameter_Log ruler =normal, text="\r\tOutput to:  \t"  + Output_Signal+" on channel " +num2str(DAC_out_Channel)
	Notebook Parameter_Log ruler =normal, text="\r\tOutput amplifier gain : \t" + num2str(DAC_out_AmpGain)
//	if(UseEvokStimCheck)
//		Notebook Parameter_Log ruler =normal, text="\r\tUsing template stimulus wave: \t" +EvokStimWaveName
//		Notebook Parameter_Log ruler =normal, text="\r\tSaving actual stimulus wave for this set: \t" +EvokStimOutName
//	endif
	Notebook Parameter_Log ruler =normal, text="\r\tBasename for acquired waves: \t" +Local_Basename
	if(FI_AverageCheck)
		Notebook Parameter_Log ruler =normal, text="\r\tAveraging across repeats of sets:  named:\t"   + FI_AvgBasename
	endif
	Notebook Parameter_Log ruler =normal, text="\r\tNegative most step level (nA): \t" + num2str(FI_NegMostStep)
	Notebook Parameter_Log ruler =normal, text="\r\tPositive most step level (nA): \t" +num2str(FI_PosMostStep)
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of steps per set: \t" +num2str(FI_NumberSteps)
	Notebook Parameter_Log ruler =normal, text="\r\tCurrent per step (nA): \t" +num2str(FI_CurrentPerStep)
	Notebook Parameter_Log ruler =normal, text="\r\tFI_StepPulseOn  : \t" +num2str(FI_StepPulseOn)
	Notebook Parameter_Log ruler =normal, text="\r\tFI_StepPulseOff	 : \t" +num2str(FI_StepPulseOff)
	Notebook Parameter_Log ruler =normal, text="\r\tStep Length (sec): \t" + num2str(FI_StepLength)
	
	if(FI_VariableNoiseCheck)
	 	Notebook Parameter_Log ruler =normal, text="\r\tAdding noise corruption to noise signal\t"  
		Notebook Parameter_Log ruler =normal, text="\r\tNoise corruption ratio (noise:signal)\t" + num2str(  FI_VariableNoiseRatio )
		Notebook Parameter_Log ruler =normal, text="\r\tNoise corruption s.d. \t"   + num2str( FI_VariableNoiseSD)
		//Notebook Parameter_Log ruler =normal, text="\r\tVariance normalization factor \t"   + num2str( FI_VarianceNormFactor)
	endif
	
	Notebook Parameter_Log ruler =normal, text="\r\tFI_SetPulseOn  : \t" +num2str(FI_SetPulseOn)
	Notebook Parameter_Log ruler =normal, text="\r\tFI_SetPulseOff	 : \t" +num2str(FI_SetPulseOff)
		Notebook Parameter_Log ruler =normal, text="\r\tPrepulse Duration \t" +num2str(FI_PrepulseDur)
		Notebook Parameter_Log ruler =normal, text="\r\tPrepulse  step (nA): \t" +num2str(FI_PrepulseStep)
		
	Notebook Parameter_Log ruler =normal, text="\r\tTotal Wave Length (sec): \t" + num2str(FI_TotalWaveLength)	
	Notebook Parameter_Log ruler =normal, text="\r\tInter-stimulus interval (sec):\t" +num2str(FI_ISI)
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of times to repeat: \t" +num2str(FI_NumRepeats) + "\r"

	
// OUTPUT WAVE CREATION:  create once, reuse each iteration.		// feb11
	//print "Creating output waves"
	if(FI_ISI <= (FI_TotalWaveLength+0.200))	// check that ISI is long enough (200ms extra room)	
		SetDataFolder root:
		Abort "ISI must be longer than "  + num2str((FI_TotalWaveLength +0.200))
	endif
	
	DoWindow /K FI_OutputWaves
	Display /W=(FI_OutputWaves_pos[0],FI_OutputWaves_pos[1],FI_OutputWaves_pos[2],FI_OutputWaves_pos[3]) as "FI Output Waves- All"
	DoWindow /C FI_OutputWaves
	
	Make/O/N=1 Wave_SetNoiseLevels		// turn string in panel into wave with numerical noise levels
	variable	FI_NumNoiseLevels	=0	// count noise levels; initialize to 0
	string tempStr
	i=0
	do
		tempStr = stringfromlist(i,FI_RangeNoiseLevels,";")
		if (strlen(tempStr)==0)
			break
		endif
		Wave_SetNoiseLevels[i]={str2num(tempStr)}
		i+=1
		FI_NumNoiseLevels+=1
	while (1)
	String StepWavesName = Local_Basename + "_Steps"		// &&
	Make/O/N=(FI_NumberSteps) $StepWavesName
	WAVE StepsWave = $StepWavesName
	Make/T/N=(FI_NumberSteps,FI_NumNoiseLevels)/O OutNames_Wave		// 2D wave containing stim out names
	Make/T/N=(FI_NumberSteps,FI_NumRepeats,FI_NumNoiseLevels)/O VoltageAcqNames_Wave, currentAcqNames_Wave	//3D waves containing acquired data names
	//Make/T/N=(FI_NumberSteps,FI_NumRepeats,FI_NumNoiseLevels)/O StimCommandAcqNames_Wave
	Make /N=( totalWavePoints)/O tempwave0
	
	
	SetScale /P x 0, (1/AcqResolution), "sec",  tempwave0
	tempwave0=0

	//print "DAC_outGain  "  +  num2str(DAC_out_AmpGain)
	// generate noise to add to stimulus:
	if(FI_NoiseCheck)
		Duplicate /O tempwave0, noisewave, unitstep
		Make /N=( AcqResolution/100)/O NoiseExpFilter	// make a filter only as long as we need (1/100 of a sec= 10ms)
		SetScale /P x 0, (1/AcqResolution), "sec",  NoiseExpFilter
		NoiseExpFilter =exp(-x/FI_NoiseExpTau)	// make filter of similar amplitude as gauss noise.
		
		//if(FI_FreezeNoiseCheck==0)
//			SetRandomSeed 0		// need to randomize enoise!
//			FI_NoiseSeed= round(10000*abs(enoise(1)))	/10000	// otherwise create new NoiseSeed to generate new random waveform
//			print "Getting new noise wave form, seed =" ,FI_NoiseSeed
//		else
//			print "Freezing noise - using same Seed", FI_NoiseSeed
//		endif
		print "Using noise waveform from last calibration run"
		SetRandomSeed FI_NoiseSeed 	// setting randomseed to a certain number means frozen noise; for gnoise line below

		
		noisewave = gnoise(FI_NoiseSD)		//  Re-calculate noise based on frozen noise
		convolve NoiseExpFilter,noisewave		// filter the noise
		unitstep=0
		unitstep[x2pnt(unitstep,FI_StepPulseOn),x2pnt(unitstep,FI_StepPulseOff)]=1
		noisewave*=unitstep
	endif
	
	//variable FI_StepDirectionCheck	=0		// 1= option to run positive most step to negative, 0 goes negative to positive
		// add pull down menu to panel
	j=0
	do
		i=0	
		do
			tempwave0=0
			//tempwave0[x2pnt(tempwave0,BeforeAfterBuff),x2pnt(tempwave0,BeforeAfterBuff+FI_PrepulseDur)]=FI_PrepulseStep  // insert pre-step
			tempwave0[x2pnt(tempwave0,FI_SetPulseOn),x2pnt(tempwave0,FI_SetPulseOff)]=FI_PrepulseStep  // insert pre-step
			
			if(FI_StepDirectionCheck)	
				StepsWave[i]=(FI_PosMostStep-i*FI_currentPerStep)	// high to low
				tempwave0[x2pnt(tempwave0,FI_StepPulseOn),x2pnt(tempwave0,FI_StepPulseOff)]=(FI_PosMostStep-i*FI_currentPerStep)
			else
				StepsWave[i]=(FI_NegMostStep+i*FI_currentPerStep)	// low to high
				tempwave0[x2pnt(tempwave0,FI_StepPulseOn),x2pnt(tempwave0,FI_StepPulseOff)]=(FI_NegMostStep+i*FI_currentPerStep)
			endif
			if(FI_NoiseCheck)
				tempwave0+=noisewave*Wave_SetNoiseLevels[j]	  // add scaled noise
			endif
		
			tempWave0/=DAC_out_AmpGain		//  gain nA/V
			//tempWave0*=2
			OutNames_Wave[i][j]= Local_Basename+"Out_step" + num2str(i) + "_n" + num2str(j)
			Duplicate /O tempWave0, $OutNames_Wave[i][j]
			//AppendToGraph $OutNames_Wave[i][j]
			CommandStr = "Save/O/C/P=FIPath " +OutNames_Wave[i][j]
			Execute CommandStr	
			
			i+=1
		while(i<FI_NumberSteps)
		j+=1
	while(j<FI_NumNoiseLevels)
	
	String NoiseLevelsWaveName = Local_Basename + "_NoiseLev"		// &&
	Duplicate/O Wave_SetNoiseLevels,  $NoiseLevelsWaveName
	CommandStr = "Save/O/C/P=FIPath " +NoiseLevelsWaveName
			Execute CommandStr		
		Modifygraph rgb=(0,0,0)	// make them all black; later make current stim red
		Label left "Command current (actual*0.5 nA)"
		Label bottom "Time (sec)"
		
		
			CommandStr = "Save/O/C/P=FIPath " +StepWavesName
			Execute CommandStr							// Quick! Before the computer crashes!!!
// REAL TIME ANALYSES:


	//Set up for plotting of voltage traces
		//DoWindow/K FI_AllWaveDisplay
	//	Display /W=(FI_AllWaveDisplay_pos[0],FI_AllWaveDisplay_pos[1],FI_AllWaveDisplay_pos[2],FI_AllWaveDisplay_pos[3])  as " Acquired Waves per Step"	
	//	Label left "Voltage (V)"
	//	Label bottom "Time (sec)"
	//	doWindow /C FI_AllWaveDisplay
		DoUpdate
	
		

// FIRING RATE ANALYSIS: create names for firing rate wave  for current level waves;
//if numRepeats> 2, create waves for average&sd.
// Create Window to plot it.
	DoWindow/K FI_RatevsCurrDisplay
	Display /W=(FI_RatevsCurrDisplay_pos[0],FI_RatevsCurrDisplay_pos[1],FI_RatevsCurrDisplay_pos[2],FI_RatevsCurrDisplay_pos[3])  as "FI Relation: Rate vs Current"	
	doWindow /C FI_RatevsCurrDisplay
	controlInfo /W=FI_ControlPanel CalcFICheck
	FI_CalcFICheck=V_value
	if(FI_CalcFICheck)
		//print "Setting up for FI curve analysis", num2str(FI_CalcFICheck)
		variable simplethresh = 0.02					// simple voltage threshold to cross to determine spike
		variable minWidth	= 0.003				// minimum time (sec) between threshold crossings (determines max FR detectable)	
		i=0	// per noise
		do
			
			
			// text wave to keep track of FR waves
			Make/T/O/N=(FI_NumRepeats, FI_NumNoiseLevels )  FRNames	// 2d text wave rows: trial #, columns: noiselevels)
			Make/T/O/N=(FI_NumNoiseLevels )  FRAvgNames, FRSDNames	// 2d text wave rows: trial #, columns: noiselevels)
			j=0 // per trial repeat
			do	
				tempStr=Local_Basename  + "_FR_n"	+num2str(i) 	+ "_"	+num2str(j) 		// one wave for each trial,each noise
				//string CurrLevWave_Name=Local_Basename + "_CurrLev"						
				Make/O/N=(FI_NumberSteps) $tempStr=0//,$CurrLevWave_Name //VICurve1Wave_Name,VIcurve2Wave_Name
				FRNames[j][i] = tempStr
				appendtograph $FRNames[j][i] vs StepsWave
				Modifygraph rgb($FRNames[j][i])=((4-i)*25000,0,i*65000),  lstyle($FRNames[j][i])=7,mode($FRNames[j][i])=4,marker($FRNames[j][i])= 8
				print "appending to rate vs current graph ", tempStr
				j+=1
			while(j<FI_NumRepeats)
			Label left "Firing Rate (spikes/sec)"
			Label bottom "Current level (nA from Vm)"
			Modifygraph  lblPos(left)=40,live=1
			//Modifygraph lstyle=7,mode=4,marker= 8
			setAxis/A/E=1 left
			//edit FRNames
			tempStr = Local_Basename  + "_FRAvg_n"	+num2str(i)		// one average FR wave per noise level
			Make/O/N=(FI_NumRepeats) $tempStr	
			FRAvgNames[i]=tempStr
			appendtograph $FRAvgNames[i] vs StepsWave
			Modifygraph lstyle( $FRAvgNames[i])=0,mode( $FRAvgNames[i])=4,marker( $FRAvgNames[i])= 16,rgb( $FRAvgNames[i])=((4-i)*25000,0,i*65000)
			//print "appending to rate vs current graph ", tempStr
			tempStr = Local_Basename  + "_FRSD_n"	+num2str(i)		// one average FR wave per noise level
			Make/O/N=(FI_NumRepeats) $tempStr	
			FRSDNames[i]=tempStr
			i+=1
		while(i<FI_NumNoiseLevels)	
		
	
	endif
	
	
	variable FI_PlotExptVariablesCheck =1
	string MemVoltWave_Name
	MemVoltWave_Name=Local_Basename  + "_Vm"	
	variable TotalTrials = FI_NumberSteps*FI_NumRepeats*FI_NumNoiseLevels
	Make/O/N=(TotalTrials) $MemVoltWave_Name
	WAVE Vm = $MemVoltWave_Name
	Vm=0
	if(FI_PlotExptVariablesCheck)
			DoWindow/K FI_MemVoltvsTrialsDisplay
			Display /W=(FI_VoltvsCurrDisplay_pos[0],FI_VoltvsCurrDisplay_pos[1],FI_VoltvsCurrDisplay_pos[2],FI_VoltvsCurrDisplay_pos[3]) $MemVoltWave_Name as "Voltage vs Trials"	
			DoWindow/C FI_MemVoltvsTrialsDisplay
			Label left "Baseline Voltage (V)"
			Label bottom "Trial #"
			Modifygraph  lblPos(left)=40,live=1
			Modifygraph lstyle($MemVoltWave_Name)=0,mode($MemVoltWave_Name)=4,marker($MemVoltWave_Name) =16,rgb($MemVoltWave_Name)  =  (0,0,65500)
			setAxis left  -0.1, -0.03
			
		endif
	
	
	
//		if(FI_PlotVICurveCheck1)
//			DoWindow/K FI_VICurveDisplay
//			Display /W=(FI_VoltvsCurrDisplay_pos[0],FI_VoltvsCurrDisplay_pos[1],FI_VoltvsCurrDisplay_pos[2],FI_VoltvsCurrDisplay_pos[3]) $VICurve1Wave_Names[0] vs $CurrLevWave_Names[0] as "Voltage vs Current"	
//			DoWindow/C FI_VICurveDisplay
//			Label left "Voltage (V)"
//			Label bottom "Current level (nA from Vm)"
//			Modifygraph  lblPos(left)=40,live=1
//			Modifygraph lstyle($VICurve1Wave_Names[0])=7,mode($VICurve1Wave_Names[0])=4,marker($VICurve1Wave_Names[0]) =5,rgb($VICurve1Wave_Names[0])  =  (0,0,65500)
//		endif
//		if(FI_PlotVICurveCheck2)
//			DoWindow/F FI_VICurveDisplay
//			Appendtograph  $VICurve2Wave_Names[0] vs $CurrLevWave_Names[0]
//			print VICurve2Wave_Names[0]
//			Modifygraph lstyle($VICurve2Wave_Names[0])=6,mode($VICurve2Wave_Names[0])=4,marker($VICurve2Wave_Names[0]) = 6,rgb($VICurve2Wave_Names[0])  =  (0,65500,0)
//		endif
//		if(FI_NumRepeats>1)
//			string Name_FRWaveAvg, Name_CurrLevWaveAvg,Name_FRWaveSD, Name_CurrLevWaveSD
////			string Name_V1LevAvg, Name_V2LevAvg, Name_V1LevSD, Name_V2LevSD
//
//			i=0
//			do
//			
//				Name_FRWaveAvg=Local_Basename + "_FRateAvg_n" + num2str(i)			// create names & waves for averages of realtime analysis
//				Name_CurrLevWaveAvg=Local_Basename +"_CurrLevAvg_n" + num2str(i)		//  make separate waves for each noise vs current step average
//				Name_FRWaveSD=Local_Basename + "_FRateSD_n" + num2str(i)
//				Name_CurrLevWaveSD=Local_Basename +"_CurrLevSD_n" + num2str(i)
////			Name_V1LevAvg=Local_Basename +"V1LevAvg"
////			Name_V2LevAvg=Local_Basename +"V2LevAvg"
////			Name_V1LevSD=Local_Basename +"V1LevSD"
////			Name_V2LevSD=Local_Basename +"V2LevSD"
//				Make /O/N=(FI_NumberSteps) $Name_FRWaveAvg,$Name_CurrLevWaveAvg,$Name_FRWaveSD,$Name_CurrLevWaveSD
//				doWindow /F FI_RatevsCurrDisplay
//				AppendToGraph $Name_FRWaveAvg vs $Name_CurrLevWaveAvg
//				ModifyGraph lsize($Name_FRWaveAvg)=2,mode($Name_FRWaveAvg)=4, marker($Name_FRWaveAvg) =1
//				i+=1
//			while(i<FI_NumNoiseLevels)
			
//			Make /O/N=(FI_NumberSteps) $Name_V1LevAvg,$Name_V2LevAvg  ,$Name_V1LevSD  ,  $Name_V2LevSD
//			DoWindow /F FI_VICurveDisplay 
//			AppendToGraph $Name_V1LevAvg vs $Name_CurrLevWaveAvg
//			ModifyGraph lsize($Name_V1LevAvg)=2,mode($Name_V1LevAvg)=4, marker($Name_V1LevAvg) =16,rgb($Name_V1LevAvg)  =  (0,0,65500)
//			AppendToGraph $Name_V2LevAvg vs $Name_CurrLevWaveAvg
//			ModifyGraph lsize($Name_V2LevAvg)=2,mode($Name_V2LevAvg)=4, marker($Name_V2LevAvg) =17,rgb($Name_V2LevAvg) = (0,65500,0)
	//	endif
/////////////////////////////	
	tempwave0=0
	String PriorTrace=""
	String PriorOutTrace=""
		DoWindow/K FI_rawDataDisplay	
		Display /W=(FI_rawDataDisplay_pos[0],FI_rawDataDisplay_pos[1],FI_rawDataDisplay_pos[2],FI_rawDataDisplay_pos[3])  as "FI Raw Acquired Waves"
		Label left "Voltage (V)"
		Label bottom "Time (sec)"
		doWindow /C FI_rawDataDisplay
		
		DoWindow/K FI_NowWaveDisplay	
		Display /W=(FI_NowWaveDisplay_pos[0],FI_NowWaveDisplay_pos[1],FI_NowWaveDisplay_pos[2],FI_NowWaveDisplay_pos[3])  as "FI Raw Acquired Waves- Most Recent"
		Label left "Voltage (V)"
		Label bottom "Time (sec)"
		doWindow /C FI_NowWaveDisplay
		
		DoWindow/K FI_NowOutputWaves	
			if(FI_VariableNoiseCheck)
			Display /W=(FI_OutputWaves_pos[0],FI_OutputWaves_pos[1],FI_OutputWaves_pos[2],FI_OutputWaves_pos[3]) as "Frozen Noise Wave (uncorrupted)"
			else
				Display /W=(FI_OutputWaves_pos[0],FI_OutputWaves_pos[1],FI_OutputWaves_pos[2],FI_OutputWaves_pos[3]) as "FI Output Waves - Now"
			endif
		Label left "Command current (actual /2 )"
	
			
		Label bottom "Time (sec)"
		doWindow /C FI_NowOutputWaves
		variable AllTrialNum =0
	k=0			// loop variable for steps OUTERMOST LOOP
	do												// loop for each Set Iteration
		print "Beginning step  number:", num2str(k)

		 print "           DC step level (nA):  ", num2str(StepsWave[k])
		// create waves for acquiring current & voltage data; create at beginning of each iteration & step Loop
		//print Local_Basename
//	
//	
//			
//				Appendtograph /W=FI_RatevsCurrDisplay $FRWave_Names[k] vs $CurrLevWave_Names[k]
//				Modifygraph /W=FI_RatevsCurrDisplay lstyle($FRWave_Names[k])=7,mode($FRWave_Names[k])=4,marker($FRWave_Names[k]) = 8
////				Appendtograph /W=FI_VICurveDisplay $VICurve1Wave_Names[k] vs $CurrLevWave_Names[k]
////				Appendtograph /W=FI_VICurveDisplay $VICurve2Wave_Names[k] vs $CurrLevWave_Names[k]
////				Modifygraph  /W=FI_VICurveDisplay lstyle($VICurve1Wave_Names[k])=7,mode($VICurve1Wave_Names[k])=4,marker($VICurve1Wave_Names[k]) =5,rgb($VICurve1Wave_Names[k])  =  (0,0,65500)
////				Modifygraph /W=FI_VICurveDisplay lstyle($VICurve2Wave_Names[k])=6,mode($VICurve2Wave_Names[k])=4,marker($VICurve2Wave_Names[k]) = 6,rgb($VICurve2Wave_Names[k])  =  (0,65500,0)

//			if( (Waveexists(temp_FRate)==0)  ||  (Waveexists(temp_Currlev)==0) )
//				print "temp_FRate or Temp_currlev does not exist"
//			endif
//		endif
		
			

		//  create window for real-time raw data display:
	
		//// Make variables to acquire a temperature measure, once at the beginning of each set.  
		variable TempGain = 0.1	// gain on the T2 output is 100mV/degC
		variable CurrentTempDegC
		
		string TempAcqString = "TemperatureGrabWave,3"
		Make /O/N=100 TemperatureGrabWave
		SetScale /P x 0, (1/AcqResolution), "sec",  TemperatureGrabWave
		print "Getting temperature data"
		mysimpleAcqRoutine("",TempAcqString)
		TemperatureGrabWave/=TempGain
		CurrentTempDegC=mean(TemperatureGrabWave,-inf,inf)
		print "CurrentTempDegC=  ", CurrentTempDegC
		//Notebook Parameter_Log ruler =normal, text="\r\t  Recording chamber temperature (T2) : \t" + num2str(CurrentTempDegC) + " degrees C"
		///
		//offsetTick=0		// reset offset for plotting raw voltage data	
		DoUpdate	
		j=0
		do	// Loop through trial repeats
										
		i=0 
		do  // Loop through noise levels 
		
			StartTicks=ticks
			print "Beginning step loop ", num2str(j)
			// send waves to nidaq
			
			VoltageAcqNames_Wave[k][j][i]  =  Local_Basename + "_V" + num2str(k)	+ "_n" + num2str(i) + "_" + num2str(j)	
			currentAcqNames_Wave[k][j][i]=Local_Basename + "_A" + num2str(k)	+ "_n" + num2str(i) + "_" + num2str(j)	
			
			duplicate /O tempwave0, $VoltageAcqNames_Wave[k][j][i] 
			duplicate /O tempwave0, $currentAcqNames_Wave[k][j][i]
			DoWindow /F FI_NowOutputWaves
			Appendtograph $OutNames_Wave[k][i]
			Label left "Command current (actual*0.5 nA)"
			Label bottom "Time (sec)"
			Modifygraph rgb($OutNames_Wave[k][i] )=(65000,0,0)		// make current output stimulus red
			if(strlen(PriorOutTrace) > 0)
				RemoveFromGraph $PriorOutTrace
			endif
			PriorOutTrace=OutNames_Wave[k][i] 
			DoUpdate
			if(FI_VariableNoiseCheck)
				print "running variable noise additive to noisy signal"
				Wave Tempout = $OutNames_Wave[k][i] 
				Duplicate /O Tempout, varnoisewave, VaroutWave
				varnoisewave=0
				SetRandomSeed 0
				varnoisewave = gnoise(FI_VariableNoiseSD)		//  new unfrozen noise to be added
				convolve NoiseExpFilter,varnoisewave		// filter the noise
				varnoisewave*=unitstep  // limit to step length
				varnoisewave*=Wave_SetNoiseLevels[i]			// scale to noise level		
				VaroutWave=Tempout+varnoisewave  // need to rescale to reduce the variance to equalize to original s.d. of signal!!!
				//VaroutWave/= FI_VarianceNormFactor		// doesn't work - scales DC level too...
				//Display varnoisewave, VaroutWave,Tempout
				//modifygraph rgb[0]=(65330,0,0),rgb[1]=(0,65330,0),rgb[2]=(0,0,65330)
				WFOutString="VaroutWave," + num2str(DAC_Out_Channel)
			else
				WFOutString=OutNames_Wave[k][i] + "," + num2str(DAC_Out_Channel)
				
			endif
			
			AcqString=VoltageAcqNames_Wave[k][j][i] +"," +num2str(Voltage_Channel)
			AcqString+=";" +currentAcqNames_Wave[k][j][i]+"," +num2str(Current_Channel) 
			//WFOutString=OutNames_Wave[k][i] + "," + num2str(DAC_Out_Channel)

			print "sending acq strings  ",  AcqString, WFOutSTring
			mySimpleAcqRoutine(WFOutString,AcqString)
			
			// condition acquired waves according to amplifier gains
			
			Wave VoltAcqWave=$VoltageAcqNames_Wave[k][j][i] 
			Wave CurrAcqWave=$currentAcqNames_Wave[k][j][i]
			if( (Waveexists(VoltAcqWave)==0)  ||  (Waveexists(CurrAcqWave)==0) )
				print "VoltAcqWave or CurrAcqWave does not exist"
			endif
			VoltAcqWave/=Voltage_AmpGain	
			CurrAcqWave/=Current_AmpGain
			// save waves to hard drive
			CommandStr = "Save/O/C/P=FIPath " +VoltageAcqNames_Wave[k][j][i]  +","+currentAcqNames_Wave[k][j][i]
			Execute CommandStr							// Quick! Before the computer crashes!!!
			DoWindow /F FI_OutputWaves
			appendtoGraph $currentAcqNames_Wave[k][j][i] 
			Label left "Command current- Actual"
			Label bottom "Time (sec)"
			Modifygraph rgb($OutNames_Wave[k][i] )=(65000,0,0)		// make current output stimulus red
	
	
			// display comman current data		-->> FI raw data window
			DoWindow /F FI_NowWaveDisplay
			appendtoGraph $VoltageAcqNames_Wave[k][j][i] 
			//appendtoGraph $currentAcqNames_Wave[k][j][i] 
			Label left "Voltage (V)"
			Label bottom "Time (sec)"
			if(strlen(PriorTrace) > 0)
				RemoveFromGraph $PriorTrace
			endif
			DoUpdate
			// display  raw voltage & current data		-->> FI raw data window
			DoWindow /F  FI_rawDataDisplay
			if(strlen(PriorTrace) > 0)
				//RemoveFromGraph $PriorTrace
				Modifygraph rgb=(0,0,0)		// set old traces to black
			endif
			appendtoGraph $VoltageAcqNames_Wave[k][j][i] 
			//appendtoGraph $currentAcqNames_Wave[k][j][i] 
			Label left "Voltage (V)"
			Label bottom "Time (sec)"
	
			PriorTrace=VoltageAcqNames_Wave[k][j][i] 
			
			//DoWindow /F FI_AllWaveDisplay
			//appendtoGraph $VoltageAcqNames_Wave[k][j][i] 
			DoUpdate
			//REAL TIME ANALYSIS: AVERAGING voltage and current traces across set repeats:
//			if(FI_AverageCheck)	
//				WAVE Sum_Volt=$tempWavesName_1[j]
//				WAVE Sum_Curr=$tempWavesName_2[j]
//				WAVE Avg_Volt	= $tempwavesName_3[j]
//				WAVE Avg_Curr=$tempwavesName_4[j]
//				if( (Waveexists(Sum_Volt)==0)  ||  (Waveexists(Sum_Curr)==0) || (Waveexists(Avg_Volt)==0)  ||  (Waveexists(Avg_Curr)==0))
//					print "Sum_Volt or Sum_Curr or Avg_Volt or Avg_Currdoes not exist"
//				endif			
//				Sum_Volt+=VoltAcqWave
//				Sum_Curr+=CurrAcqWave
//				Avg_Volt=Sum_volt/(k+1)		// k+1 should be number of sets;  provides running average
//				Avg_Curr=Sum_Curr/(k+1)
//				DoWindow/F FI_AvgWaveDisplay
//				ModifyGraph live=1
//			endif
			//REAL TIME ANALYSIS: FI CURVE 
						Wave temp_FRate = $FRNames[j][i]		// get FR wave name for this trial, this noise level
			//WAVE temp_CurrLev= $CurrLevWave_Name
//			WAVE temp_V1Lev = $VICurve1Wave_Names[k]
//			WAVE temp_V2Lev = $VICurve2Wave_Names[k]
//			
				//calculating firing rate versus current, for each set:
				FindLevels /Q/P/EDGE=1/M=(minWidth)/R=(FI_FRWindow1,FI_FRWindow2)  VoltAcqWave, FI_SpikeThresh
				if (V_Flag==2)
					//print "found no spikes"
					temp_FRate[k]=0			// if no spikes, set to 0
				else
					temp_FRate[k]=  V_LevelsFound/(FI_FRWindow2-FI_FRWindow1)		// firing rate is #spikes/duration of step
					//  offset trace by 100mV
					//if(FI_CalcFICheck)
					DoWindow/F FI_RawDatadisplay
					print "offsetting ", VoltageAcqNames_Wave[k][j][i], "by ", offsetTick
					ModifyGraph offset($VoltageAcqNames_Wave[k][j][i] ) = {0,offsetTick*0.1}
					offsetTick+=1
					DoUpdate
					
					//endif
				endif			
				//temp_CurrLev[j] = DAC_out_AmpGain*mean($OutNames_Wave[j],BeforeAfterBuff,(BeforeAfterBuff+FI_StepLength))  // actual  intended output current applied
				//temp_CurrLev[j] = mean(CurrAcqWave,BeforeAfterBuff+0.003,(BeforeAfterBuff+FI_StepLength))	// current level for this step, discounting the rise time of ~3ms
				DoWindow/F FI_RateVsCurrDisplay
				
				ModifyGraph live=1
				// calculate baseline membrane voltage
				Vm[AllTrialNum] =  mean(VoltAcqWave, 0.001 ,  0.05)  // measure baseline from 1ms to 50ms time
				DoWindow/F FI_MemVoltvsTrialsDisplay
				ModifyGraph live=1
				textbox /N=Vmreport/K
				textboxStr = "\Z12 Vm =  "+ num2str(1000*Vm[AllTrialNum] ) + "   mV"
				textbox /N=Vmreport/A=RT  textboxStr
			
			Doupdate /W=FI_RateVsCurrDisplay
				// Calculating VI1 and VI2
//				Temp_v1lev[j] = mean(VoltAcqWave,BeforeAfterBuff+FI_VIMeasure_t1 , BeforeAfterBuff+FI_VIMeasure_t1 + FI_AvgWindow)- mean(VoltAcqWave, 0.001 ,  BeforeAfterBuff-0.005)
//				Temp_v2lev[j] = mean(VoltAcqWave,BeforeAfterBuff+FI_VIMeasure_t2 , BeforeAfterBuff+FI_VIMeasure_t2 + FI_AvgWindow)- mean(VoltAcqWave, 0.001 ,  BeforeAfterBuff-0.005)
			CommandStr = "Save/O/C/P=FIPath "+ FRNames[j][i] 	// Save the FR wave in the home path right away!
			Execute CommandStr
			do									//waste time between runs according to ISI
				elapsedTicks=ticks-StartTicks
			while((elapsedTicks/60.15)<FI_ISI)		
			i+=1
			AllTrialNum+=1
			while(i<FI_NumNoiseLevels)
			j+=1
		while(j<FI_NumRepeats)
		// do averaging for each step (does this repeatedly to show progress)
		
		CommandStr = "Save/O/C/P=FIPath "+ MemVoltWave_Name
				Execute CommandStr		// Save it!	
		
			
	if(FI_CalcFICheck)
		if(FI_NumRepeats>1)
			print "Averaging FI curves and VI curves across sets"
			variable errortype=1			// 1=sd; 2=conf int; 3=se; 0=none)
			variable errorinterval=1		// # of sd's	
			variable a, b 
			string FR_list, TempFRAvgName, TempFRSDName
			a=0
			do
				FR_list = FRNames[0][a] +";"
				b=0
				do 
					FR_list+=FRNames[b][a] +";"
					b+=1
				while(b<FI_NumRepeats)
				TempFRAvgName = FRAvgNames[ a ]
				TempFRSDName = FRSDNames [ a ]
				fWaveAverage(FR_list,errortype,errorinterval,TempFRAvgName,TempFRSDName)
				CommandStr = "Save/O/C/P=FIPath "+ TempFRAvgName +"," +	TempFRSDName 
				Execute CommandStr		// Save it!	
	
				a+=1	
			while(a<FI_NumNoiseLevels)
//			Notebook  Parameter_Log ruler =normal, text="\r\rCalculated FI curve averages across set#" +num2str(StartingSetNumber) + "-" +num2str(EndingSetNumber)
//			Notebook  Parameter_Log ruler =normal, text="\r\tAverages of Firing rates:\t" +Name_FRWaveAvg + "+/-" + Name_FRWaveSD
//			Notebook  Parameter_Log ruler =normal, text="\r\tAverages of current steps:\t" +Name_CurrLevWaveAvg + "+/-" + Name_CurrLevWaveSD

		endif
	endif
		
		
		// insert dialog box here to continue with next level or abort 

		k+=1
		
		if(FI_StepDirectionCheck==0)		// only ask if going from low to high steps
			if(k<FI_NumberSteps)		// don't ask if this is the last step
				variable ContinueStep = 0
//				Prompt ContinueStep, "Continue with the next current step level", popup, "Yes;No"
//				DoPrompt "Next Step Choice Dialog",ContinueStep
//				if(ContinueStep==1)
//					print "*****Continuing with next step"
//				else
//					print "******************************Ending data acquisition"
//					break
//				endif
			endif
		endif
			
	while(k<FI_NumberSteps)	
	



	
		
		/////	

		Notebook  Parameter_Log ruler =normal, text="\r\rCompleted Set#" + num2str(FI_SetNum)
		Notebook  Parameter_Log ruler =normal, text="\r\tAcquired voltage traces:\t" +VoltageAcqNames_Wave[0] +"-" + num2str(FI_Numbersteps)
		Notebook  Parameter_Log ruler =normal, text="\r\tAcquired actual current traces:\t" + currentAcqNames_Wave[0]+ "-" + num2str(FI_Numbersteps)
//		if(FI_CalcFICheck)
//			Notebook  Parameter_Log ruler =normal, text="\r\tFI curve for this set, firing rates:\t" + FRWave_Name
//			Notebook  Parameter_Log ruler =normal, text="\r\tFI curve for this set, current steps:\t" + CurrLevWave_Name
//		endif
		FI_SetNum+=1			// update set#
		Local_Basename			=	"FI_" +baseName + "s" + num2str(FI_SetNum)	// recalculate basename


	EndingSetNumber=StartingSetNumber+k
	// END OF SET ANALYSIS FOR FI CURVE:    average spikes & current levels & plot mean +- s.d. -->>  
	

	

	// END OF MACRO CLEAN-UP:
	print "Cleaning up"
	FI_Basename= Local_Basename			// update global FI basename
	//dowindow /K FI_outputWaves
	KillWaves/Z tempWave0				// kill output waves & all other temporary & non-essential waves

	KillWaves/Z currentAcqNames_Wave,voltageAcqNames_Wave,OutNames_Wave,TemperatureGrabWave
	KillWaves/Z  tempWavesName_1,tempWavesName_2,tempWavesName_3,tempWavesName_4
	KillWaves /Z currLevWave_Names,FRWave_Names,W_FindLevels
	killWaves/Z FI_OutputWaves_pos,FI_RatevsCurrDisplay_pos,FI_AvgWaveDisplay_pos,FI_rawDataDisplay_pos
	Notebook  Parameter_Log ruler =normal, text="\r\r"
	Dowindow/K FI_Layout
	NewLayout /P=portrait /w=(80,40,400,450) as TextStamp
	variable LeftEdge=85
	variable topedge=85
	variable GraphWidth=225
	variable GraphHeight=100
	//if(FI_numberSteps>2)
		Appendlayoutobject /T=1/F=0/R=(leftEdge,topEdge,leftEdge+graphWidth,topEdge+3.5*GraphHeight) graph FI_rawDataDisplay
//	else
		Appendlayoutobject /T=1/F=0/R=(leftEdge+graphWidth,topEdge,leftEdge+2*graphWidth+20,topEdge+2.5*GraphHeight) graph FI_RateVsCurrDisplay
//	endif
	//Appendlayoutobject /T=1/F=0/R=(leftEdge+graphWidth,topEdge+2.5*GraphHeight,leftEdge+2*graphWidth+20,topEdge+3.3*GraphHeight) graph FI_OutputWaves

	 GraphWidth=450
	 GraphHeight=100
	Appendlayoutobject /T=1/F=0/R=(leftEdge,topEdge+3.5*GraphHeight,leftEdge+0.5*graphWidth,topEdge+6*GraphHeight) graph  FI_OutputWaves
	//Appendlayoutobject /T=1/F=0/R=(leftEdge+0.5*graphWidth,topEdge+3.5*GraphHeight,leftEdge+graphWidth,topEdge+6*GraphHeight) graph FI_VICurveDisplay
	Dowindow/C FI_Layout
	//Execute "StampExptDate() "
	TextBox/A=MT /E/F=0/A=MT/X=0.00/Y=0.00 TextStamp
	Dowindow/B FI_Layout
	Notebook Parameter_Log text="\rCompleted run:\tTime: "+Time()+"\r\r"
	Notebook  Parameter_Log ruler =normal, text="\r\r"	
	SetDataFolder root:			// return to root 
end		

function Kill_FI_windows()
	DoWindow/K FI_rawDataDisplay;DoWindow/K FI_NowOutputWaves
	DoWindow/K FI_RatevsCurrDisplay;DoWindow /K FI_OutputWaves;DoWindow/K FI_VICurveDisplay
	DoWindow/K  FI_Layout;DoWindow/K EvokStimDisplay;DoWindow/K FI_NowWaveDisplay
end
	
Function FI_NoiseCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FI_NoiseCheck =  root:FIRelation:FI_NoiseCheck
	FI_NoiseCheck = checked
	print "Changing FI_NoiseCheck to " num2str(FI_NoiseCheck)
End

Function FI_FreezeNoiseCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FI_FreezeNoiseCheck =  root:FIRelation:FI_FreezeNoiseCheck
	FI_FreezeNoiseCheck = checked
	print "Changing FI_FreezeNoiseCheck to " num2str(FI_FreezeNoiseCheck)
End



Function RunNoiseCalibrationProc(ctrlName) : ButtonControl
	String ctrlName
	// code here to generate noise current stimulus, inject into neuron, measure resulting
	// direct copy of main ACq routine, but without any capacity for AxoClamp (assumes AxoPatch)
	// SD of the membrane voltage
	NVAR FI_NoiseSD	 =  root:FIRelation:FI_NoiseSD	
	NVAR FI_NoiseTarget	 =  root:FIRelation:FI_NoiseTarget
	NVAR	FI_NoiseExpTau	 =  root:FIRelation:FI_NoiseExpTau
	// set to main panel step length:
	//variable FI_NoisetestLength		 =  2	// try setting test length to 100ms - otherwise fluctuations involtge override noise stim.
		NVAR FI_NoisetestLength		 =root:FIRelation:FI_StepLength
		NVAR FI_StepPulseOn= root:FIRelation:FI_StepPulseOn
		NVAR  FI_StepPulseOff= root:FIRelation:FI_StepPulseOff
		
	NVAR FI_NoiseVmSD	 =  root:FIRelation:FI_NoiseVmSD
	SVAR FI_NoiseWFName =  root:FIRelation:FI_NoiseWFName
	
	NVAR FI_FreezeNoiseCheck = root:FIRelation:FI_FreezeNoiseCheck
	NVAR   AcqResolution  =  root:DataAcquisitionVar:AcqResolution
		NVAR BeforeAfterBuff =  root:FIRelation:FI_BeforeAfterBuff
	NVAR FI_StepLength=  root:FIRelation:FI_StepLength
	NVAR FI_PrepulseDur=  root:FIRelation:FI_PrepulseDur
	NVAR FI_TotalWaveLength=  root:FIRelation:FI_TotalWaveLength
	String AcqString, WFOutString
	Variable totalWavePoints = AcqResolution * (FI_TotalWaveLength)
	// copied from Acq macro:
	string dfsave=GetDataFolder(1)
	SetDataFolder root:FIRelation
	string commandstr
	Variable Voltage_Channel
	//Variable Voltage_IndBoardGain
	Variable Voltage_AmpGain
	Variable Current_Channel
	//Variable Current_IndBoardGain
	Variable  Current_AmpGain
	Variable DAC_out_Channel
	Variable DAC_out_AmpGain
	/// Need to get proper selection of Voltage_Signal,current_Signal,Output_Signal,StimOutputSignal
	SVAR Voltage_Signal =  root:FIRelation:Voltage_Signal	// string to be matched to find voltage channel
	SVAR current_Signal=  root:FIRelation:current_Signal	// string to be matched to find current channel
	SVAR Output_Signal =  root:FIRelation:Output_Signal			// string to be matched to find DAC output to drive current step 
//If(stringmatch(Voltage_signal,"ScaledOutput"))
//	//	Execute "UpdateTelegraphs()"
////		print "getting TG globals"
////		NVAR Current_TG_Gain	=	root:NIDAQBoardVar:Current_TG_Gain		
////		SVAR  Current_TG_Mode=	root:NIDAQBoardVar:Current_TG_Mode
////		SVAR Current_ScaledOutType=root:NIDAQBoardVar:Current_ScaledOutType
////		NVAR Current_TG_Filter	=root:NIDAQBoardVar:Current_TG_Filter
////		NVAR current_TG_Capac	=root:NIDAQBoardVar:current_TG_Capac			
//		if(   stringmatch(Current_ScaledOutType,"Current") || stringmatch(Current_ScaledOutType,"I=0") )
//			SetDataFolder root:
//			Abort "Axopatch Amplifier must be set in' I-Clamp Normal' or' I-Clamp Fast'"
//		endif

//		
//	endif
// determine correct channel #s for Scaled out (voltage), I output
	Print "Getting Nidaq ADC/DAC globals"
	//NVAR AcqResolution=  root:DataAcquisitionVar:AcqResolution
	WAVE ADC_ChannelWave			=root:NIDAQBoardVar:ADC_ChannelWave
	WAVE ADC_SignalWave				=root:NIDAQBoardVar:ADC_SignalWave
	WAVE ADC_IndBoardGainWave		=root:NIDAQBoardVar:ADC_IndBoardGainWave
	WAVE ADC_AmpGainWave			=root:NIDAQBoardVar:ADC_AmpGainWave

	WAVE DAC_SignalWave				=root:NIDAQBoardVar:DAC_SignalWave
	WAVE DAC_Channel_Wave			=root:NIDAQBoardVar:DAC_Channel_Wave
	WAVE DAC_AmpGain_ICl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	
	// Check Evok stimulus control info
	SVAR EvokStimWaveName=  root:FIRelation:FI_EvokStimWaveName
	NVAR UseEvokStimCheck =  root:FIRelation:FI_UseEvokStimCheck

	
	print "determining channels & gains"
	string ADCsignalList = ConvertTextWavetoList(ADC_SignalWave)
	string DACsignalList = ConvertTextWavetoList(DAC_SignalWave)
	Voltage_Channel=whichListItem(Voltage_Signal, ADCsignalList)				// channel is equivalent to position in List
	current_Channel=WhichlistItem(current_Signal, ADCsignalList)
	DAC_out_Channel=WhichlistItem(Output_Signal, DACsignalList)
	if((Voltage_Channel==-1)  || (current_Channel==-1) || (DAC_out_Channel==-1)  )			// check that all have channels
		commandstr = "you must select  channels containing  "+Voltage_Signal +"," +  current_Signal + ", and " + Output_Signal 
		SetDataFolder root:
		Abort commandstr
	endif 
	Voltage_AmpGain= ADC_AmpGainWave[Voltage_Channel]
	print "voltage channel gain",Voltage_AmpGain
	Current_AmpGain=ADC_AmpGainWave[Current_Channel]
	DAC_out_AmpGain=DAC_AmpGain_ICl_Wave[DAC_out_Channel]
	
	//Voltage_IndBoardGain= ADC_IndBoardGainWave[Voltage_Channel]
	//Current_IndBoardGain=ADC_IndBoardGainWave[Current_Channel]

	
	Doupdate
	NVAR FI_NoiseSeed  =  root:FIRelation:FI_NoiseSeed
	controlinfo /W=FI_ControlPanel NoiseSeedsetvar
	FI_NoiseSeed=V_value
	
	if(FI_FreezeNoiseCheck==0)
		SetRandomSeed 0		// need to randomize enoise!
		FI_NoiseSeed= round(10000*abs(enoise(1)))	/10000	// otherwise create new NoiseSeed to generate new random waveform
		print "Getting new noise wave form, seed =" ,FI_NoiseSeed
	else
		print "Freezing noise - using same Seed", FI_NoiseSeed
	endif
	SetRandomSeed FI_NoiseSeed 	// setting randomseed to a certain number means frozen noise; for gnoise line below

	Make /N=( totalWavePoints)/O tempwave_n
	SetScale /P x 0, (1/AcqResolution), "sec", tempwave_n
	tempwave_n=0
	Duplicate/O tempwave_n, noisewave, noisewavefiltered,unitstep
	Make /N=( AcqResolution/100)/O NoiseExpFilter	// make a filter only as long as we need (1/100 of a sec= 10ms)
	SetScale /P x 0, (1/AcqResolution), "sec",  NoiseExpFilter
	NoiseExpFilter =exp(-x/FI_NoiseExpTau)	// make filter . 
	noisewave = FI_NoiseSD*gnoise(1)		//  
	convolve NoiseExpFilter,noisewave		// filter the noise
	unitstep=0
	unitstep[x2pnt(unitstep,FI_StepPulseOn),x2pnt(unitstep,FI_StepPulseOff) ]=1
	noisewavefiltered=noisewave*unitstep
	
	noisewavefiltered/=DAC_out_AmpGain		//  gain nA/V
	Dowindow/K NoiseStim_Window
	display noisewavefiltered  //,NoiseExpFilter
	legend
	label left "Current noise stim (nA)"
	Dowindow/C NoiseStim_Window
	
		string VoltageAcqName="testNoiseAcq_Vm" 
		string	currentAcqName="testNoiseAcq_A" 
			duplicate /O tempwave_n, $VoltageAcqName
			duplicate /O tempwave_n, $currentAcqName
			//AcqString=VoltageAcqName+"," +num2str(Voltage_Channel)+ "," + num2str(Voltage_IndBoardGain)
			//AcqString+=";" +currentAcqName+"," +num2str(Current_Channel) + "," + num2str(Current_IndBoardGain)
			AcqString=VoltageAcqName+"," +num2str(Voltage_Channel)
			AcqString+=";" +currentAcqName+"," +num2str(Current_Channel)
			WFOutString="noisewavefiltered," + num2str(DAC_Out_Channel)
			//print acqString
			//print WFOutString
			mySimpleAcqRoutine(WFOutString,AcqString)
			// condition acquired waves according to amplifier gains
			
			
			Wave VoltAcqWave=$VoltageAcqName
			Wave CurrAcqWave=$currentAcqName
			VoltAcqWave/=Voltage_AmpGain	
			CurrAcqWave/=Current_AmpGain
			
			doWindow/K NoiseCalibration_Vm_Window
			Display/W=(20,280,450,450) VoltAcqWave
			legend
			label left "Membrane Voltage (V)"
			doWindow/C NoiseCalibration_Vm_Window
			
			// measure SD of membrane voltage
			Wavestats/Q/R=[x2pnt(unitstep,FI_StepPulseOn),x2pnt(unitstep,FI_StepPulseOff)] VoltAcqWave
			print "SD of membrane voltage is", 1000*V_sdev, "  mV"
			FI_NoiseVmSD=1000*V_sdev
	
End




Function EvTh_UpdateoutSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR OutputCell_Signal=root:EvokThresh:OutputCell_Signal	
	OutputCell_Signal=popStr
	print "Changing Evok Thresh OutputCell_Signal to ", OutputCell_Signal
End

Function EvTh_UpdateInputSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Input_Signal=root:EvokThresh:Input_Signal	
	Input_Signal=popStr
	print "Changing Ev Threshd input signal to ", Input_Signal
End

Function FI_VariableNoiseCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FI_VariableNoiseCheck =  root:FIRelation:FI_VariableNoiseCheck
	FI_VariableNoiseCheck = checked
	print "Changing FI_VariableNoiseCheck to " num2str(FI_VariableNoiseCheck)
End

Function FI_CorruptNoiseCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FI_VariableNoiseCheck =  root:FIRelation:FI_VariableNoiseCheck
	FI_VariableNoiseCheck = checked
	print "Changing FI_VariableNoiseCheck to " num2str(FI_VariableNoiseCheck)
End
