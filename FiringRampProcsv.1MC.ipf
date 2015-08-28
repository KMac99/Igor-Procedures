#pragma rtGlobals=1		// Use modern global access method.
//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\WavetoList procs"
//#include "WavetoList procs"
#include <Waves Average>
// Renamed FiringRampProc v1MC
////FiringCurrentRelationProcs v.3.3MC  :  
// updated to be able to generate ramped current steps instead of normal current steps
// updated to default to Multiclamp amplifiers
// updated  for new PCs, and nidaq-mx drivers, and nidaqMX Tools   20july2010
// New protocol:  adding noise to the step currents as in  Higgs, et al. 2006
// Rewrote protocol to acquire from low step to high step, looping through noise values and trial# at each
// step before going to next step.
// updated 4/15/03 to accomodate choosing different amplifier.
// updates 4/26/03 to do online analysis of VI curve.
// fixed Evoked stim output bug.  10/6/03

Menu "Initialize Procedures"
	"Initialize FI Ramp Relation Parameters",Init_FIRampControlPanel()
	
end

Menu "Kill Windows"
	"Kill FI Ramp Data Acq Graphs",Kill_FIR_windows()
end

function ButtonCreateRampstep(ctrlName):  ButtonControl
	String ctrlName
	string dfsave=GetDataFolder(1)
	SetDataFolder root:FIRamp // FIRamp
	NVAR FIR_StepLength				=root:FIRamp:FIR_StepLength			// in sec
	NVAR FIR_ShallowSlope			=root:FIRamp:FIR_ShallowSlope		//in nA
	NVAR FIR_LargestSlope			=root:FIRamp:FIR_LargestSlope
	NVAR FIR_NumberSteps			=root:FIRamp:FIR_NumberSteps
	NVAR FIR_SlopeChangePerStep	=root:FIRamp:FIR_SlopeChangePerStep		// in nA
	
	NVAR FIR_ton						=root:FIRamp:FIR_ton
	NVAR FIR_plateauLength			=root:FIRamp:FIR_plateauLength
	NVAR FIR_stepbase				=root:FIRamp:FIR_stepbase
	NVAR FIR_stepup					=root:FIRamp:FIR_stepup
	NVAR FIR_toff_max				=root:FIRamp:FIR_toff_max
	NVAR AcqResolution				=  root:DataAcquisitionVar:AcqResolution
	NVAR DAC_out_AmpGain 		 =  root:DataAcquisitionVar:DAC_out_AmpGain
	variable i=0
	variable t_rampend
	
	Variable LeftPos=30					// variables for positioning graph windows for this module
	Variable TopPos=60
	Variable Graph_Height=200
	variable Graph_Width = 350
	variable Graph_grout = 15
	variable graph_grout_vert	=	20
	string str
// error check
	if(FIR_ShallowSlope<=0)

			SetDataFolder root:
			str = "ShallowSlope must be a positive value.  Reset parameters to fix.   ShallowSlope =   "+ num2str(FIR_ShallowSlope)
			Abort str
	endif
		
		// Get rid of waves from previous preview
	DoWindow/K FIR_PreviewOutputWaves
	WAVE/Z/T PreviewRampNamesWave =root:FIRamp:PreviewRampNamesWave
	if(Waveexists(PreviewRampNamesWave))
		do
			str=PreviewRampNamesWave[i]
			KillWaves/Z $str
			i+=1
		while(i<numpnts(PreviewRampNamesWave))
	endif
	 	
		// Preview display
	Make/N=4/O FIR_OutputWaves_pos
	FIR_OutputWaves_pos={LeftPos+graph_width+Graph_grout,TopPos,LeftPos+2*graph_Width+Graph_Grout,TopPos+Graph_Height}	// graph top right
	Make/O/N=(FIR_NumberSteps)/T	PreviewRampNamesWave
	Make/O/N=(FIR_NumberSteps) PreviewStepsWave
	Make/O/N=(FIR_StepLength*AcqResolution)  tempwave0
	SetScale /P x 0, 1/AcqResolution, "sec", tempwave0
	
	
		Display /W=(FIR_OutputWaves_pos[0],FIR_OutputWaves_pos[1],FIR_OutputWaves_pos[2],FIR_OutputWaves_pos[3]) as "FI Output Waves - Preview"		
		doWindow /C FIR_PreviewOutputWaves
	i=0	
		do
			tempwave0=0
				
				PreviewStepsWave[i]=(FIR_LargestSlope-i*FIR_SlopeChangePerStep)	// high to low
				//print PreviewStepsWave[i]
				t_rampend=FIR_ton + (FIR_stepup-FIR_stepbase)/PreviewStepsWave[i]
				//print t_rampend
				tempwave0[x2pnt(tempwave0,0),x2pnt(tempwave0,FIR_ton)]=FIR_stepbase
				tempwave0[x2pnt(tempwave0,FIR_ton),x2pnt(tempwave0,t_rampend)]=(x-FIR_ton)*PreviewStepsWave[i]
				tempwave0[x2pnt(tempwave0,t_rampend),x2pnt(tempwave0,t_rampend+FIR_plateauLength)]=FIR_stepup
				tempwave0[(x2pnt(tempwave0,t_rampend+FIR_plateauLength)-5),x2pnt(tempwave0,FIR_StepLength)]=0		// return to 0
			PreviewRampNamesWave[i]= "Ramp_" + num2str(i) 
			Duplicate /O tempWave0, $PreviewRampNamesWave[i]
			AppendToGraph $PreviewRampNamesWave[i]
			
			i+=1
		while(i<FIR_NumberSteps)
		
		Label left "Command current (nA)"
		Label bottom "Time (sec)"
	SetDataFolder root:			// return to root 
		
end


Proc Init_FIRampControlPanel()
	// Check to see whether Globals Folder exists (i.e., that the InitializeDataAcquisition procedure 
	// has been run & common global variables exist
	if( DataFolderExists("root:DataAcquisitionVar"))	
		String dfSave=GetDataFolder(1)
		NewDataFolder /O/S root:FIRamp			// Create folder for FI variables
		DoWindow/K FIR_rawDataDisplay
		DoWindow/K FIR_AvgWaveDisplay
		DoWindow/K FIR_RatevsCurrDisplay		
		DoWindow/K FIR_VICurveDisplay		
		KillWaves /a/z								// clean out folder & start from scratch
		killvariables /a/z		
		killstrings /a/z
		///  create variables for signal selection:
		string/G Voltage_signal	=	 "PrimaryOutCh1"	
		String/G Current_signal	= 	"SecondaryOutCh1"
		String/G Output_Signal	=	"Command"
		string/G StimOutput_Signal	=	 "_none_"
		//
		//Variable /G FIR_StepLength		=	2	//sec		// longer default for noise expts
		Variable /G FIR_AfterBuff = 	0.050	//  time after step to continue  acquisition

		//Use former variables in ramped stim
		Variable /G FIR_LargestSlope		=	10	//nA/sec  formerly FIR_PosMostStep
		Variable /G FIR_NumberSteps		=	10		// # steps in current step protocol
		Variable /G FIR_SlopeChangePerStep		=    1	//nA/sec*step  formerly FIR_CurrentPerStep
													// error check that slope ~= 0, leads to infinite step length
		// Additional variables for ramped
		variable /G FIR_ton					= 	0.2	// sec,   equivalent to FIR_BeforeAfterBuff
		variable /G FIR_plateauLength		=    0.2	// sec,  time length of step following ramp
		variable /G  FIR_stepbase			=    0		//nA initial conditioning "pre" step prior to ramp, default zero
		variable /G FIR_stepup				=	0.2		// nA, target plateau step reached at end of ramp

		Variable /G FIR_ShallowSlope		:=	FIR_LargestSlope - (FIR_SlopeChangePerStep*(FIR_NumberSteps-1))//nA/sec  formerly  FIR_NegMostStep
		variable /G FIR_toff_max			:= 	FIR_ton+ 	(FIR_stepup-FIR_stepbase)/FIR_ShallowSlope    // longest ramp time
		
		Variable /G FIR_StepLength			:=	FIR_ton+ 	(FIR_stepup-FIR_stepbase)/FIR_ShallowSlope+FIR_plateauLength+FIR_AfterBuff	//sec, set to be longest ramp + 2*FIR_ton; error check in aquisition must <some limit
		 
		 // variable for running
		Variable /G FIR_ISI					=   3		// seconds between steps
		Variable /G FIR_RepeatCheck		=	1		// Repeat sets?
		Variable /G FIR_NumRepeats		=	1		// Repeat # times
		Variable /G FIR_SetNum			=	0		// Label each set of current steps
		String 	/G FIR_Basename			:=	"FIR_" +root:DataAcquisitionVar:baseName + "s" + num2str(FIR_setnum)	// Acquisition waves basename
		Variable /G FIR_AverageCheck	=	1		// Calculate averages?
		variable /G FIR_nextAvg			=	0
		string 	/G FIR_AvgBasename		:=	"FIR_" + root:DataAcquisitionVar:baseName  +"_avg" +num2str(FIR_nextAvg)// Averaging waves basename
		Variable /G FIR_CalcFICheck		=	0			// plot Firing Curve check	
		variable /G FIR_SpikeThresh		=	0		// Threshold for counting spikes
		// VI curve analysis
		variable /G FIR_PlotVICurveCheck1	=  1	// plot VI curve #1 check
		variable /G FIR_VIMeasure_t1		=  0.080	// seconds after onset
		variable /G FIR_PlotVICurveCheck2	=  1	// plot VI curve #1 check
		variable /G FIR_VIMeasure_t2		=  0.190	// seconds after onset
		//
		// Evoked stim parameters:
		variable /G FIR_UseEvokStimCheck = 0		// send an evoked stimulus to an SIU during Steps
		string /G FIR_EvokStimWaveName = ""	
		string /G FIR_DefaultStimWaveName = "FIR_EvStimWave0"
		// Noise stim paramters:
		Variable /G FIR_NoiseCheck 	=	0	// 0 don't add noise; 1 add noise
		Variable /G  FIR_NoiseSD		=   	0.001	// initialize with 0.1 (nA)
		Variable /G FIR_NoiseTarget	=    1	// target voltage SD in mV
		Variable /G	FIR_NoiseExpTau	=   0.003	// (sec)exponential filter of noise time constant (default 3ms)
		Variable /G FIR_NoisetestLength		=  1		// (sec)  length of test noise stimulus for adjustment
		Variable /G  FIR_NoiseVmSD	=	0		// measured voltage SD; initialize to 0
		Variable /G FIR_NoiseSeed		=	0		// seeds the noise generation to particular number; initial to random
		Variable /G FIR_FreezeNoiseCheck	= 0		//  Check to keep noise waveform constant
		String /G FIR_RangeNoiseLevels	= "0"	// make wave containg range of noise levels (Sigma)
		String /G FIR_NoiseWFName	=	"FIR_NoiseWF"	// default name for base noise waveform
		
		
		Variable /G FIR_StepDirectionCheck = 1  // sets direction of step increment:  1 = high to low; 0 = low to high
		variable/G FIR_DefaultNumstim		= 1
		Variable/G FIR_DefaultDelay		= FIR_ton + 0.100	// time stim to occur 100ms into step
		Variable/G FIR_defaultEvStimFreq	= 1	
		String /G FIR_PathName = "FIRPath"
		
		Execute "FIR_ControlPanel()"
		SetDataFolder dfSave
		SaveExperiment
		NewPath /C/M="Choose folder for FI Ramp files"/O/Q/Z FIRPath
	else
		Print "You must first initialize global variables with procedure 'InitializedDataAcquisition()' "
	endif
end


Window FIR_ControlPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(580,68,1065,542)
	ModifyPanel cbRGB=(32768,65280,32768)
	ShowTools
	SetDrawLayer UserBack
	SetDrawEnv fillpat= 15,fillfgc= (32768,54615,65535)
	DrawRRect 427,4,12,30
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 37,29,"Ramped Firing-Current Control Panel v3.3"
	SetVariable StepLengthSetVar,pos={12,71},size={136,16},title="Step Length (sec)"
	SetVariable StepLengthSetVar,limits={0.01,10,0.1},value= root:FIRamp:FIR_StepLength
	SetVariable NumStepsSetVar,pos={178,128},size={136,16},title="Number of Steps "
	SetVariable NumStepsSetVar,limits={1,50,1},value= root:FIRamp:FIR_NumberSteps
	SetVariable PosMostStepSetVar_1,pos={166,70},size={177,16},title="Steepest Slope (nA/sec)"
	SetVariable PosMostStepSetVar_1,limits={-1,inf,0.05},value= root:FIRamp:FIR_LargestSlope
	SetVariable FIR_BasenameSetVar,pos={13,36},size={265,16},title="Acquisition Waves Basename"
	SetVariable FIR_BasenameSetVar,value= root:FIRamp:FIR_Basename
	SetVariable RepeatSetVar,pos={15,128},size={126,16},title="# trials/step/noise:"
	SetVariable RepeatSetVar,limits={1,100,1},value= root:FIRamp:FIR_NumRepeats
	SetVariable SetNumSetVar,pos={293,35},size={118,16},title="Current Set #"
	SetVariable SetNumSetVar,value= root:FIRamp:FIR_SetNum
	Button FIR_AcquireButton,pos={19,277},size={181,29},proc=Acq_FIR_data,title="Acquire"
	PopupMenu SelectOutSignalPopup,pos={68,380},size={178,21},proc=FIR_UpdateoutSignalProc,title="Output Step Signal"
	PopupMenu SelectOutSignalPopup,mode=2,popvalue="Command",value= #"root:NIDAQBoardVar:OutputNamesString"
	PopupMenu SelectInputSignalPopup,pos={73,337},size={186,21},proc=FIR_UpdateVoltSignalProc,title="Vm Input Signal"
	PopupMenu SelectInputSignalPopup,mode=2,popvalue="PrimaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	SetVariable ISISetVar,pos={16,109},size={135,16},title="ISI (sec)           "
	SetVariable ISISetVar,limits={0.1,60,0.1},value= root:FIRamp:FIR_ISI
	SetVariable SpikeThreshSetVar,pos={108,254},size={160,16},title="Spike threshold (V)"
	SetVariable SpikeThreshSetVar,limits={-0.1,0.1,0.01},value= root:FIRamp:FIR_SpikeThresh
	CheckBox CalcFICheck,pos={21,255},size={79,14},proc=FIR_CalcFICheckProc,title="Plot FI Curve"
	CheckBox CalcFICheck,value= 1
	GroupBox Box1,pos={9,54},size={430,259},title="Steps"
	GroupBox Box4,pos={56,319},size={257,93},title="Multiclamp Signals"
	PopupMenu FIR_CurrentSigMonitorPopup,pos={70,358},size={222,21},proc=FIR_UpdateCurrSignalProc,title="Current Input Signal"
	PopupMenu FIR_CurrentSigMonitorPopup,mode=3,popvalue="SecondaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	SetVariable RampOnVar,pos={14,91},size={144,16},title="Ramp Delay (sec)"
	SetVariable RampOnVar,limits={0.1,1,0.1},value= root:FIRamp:FIR_ton
	SetVariable SlopePerStepSetVar,pos={224,88},size={119,16},title="nA/ sec per step  "
	SetVariable SlopePerStepSetVar,limits={0,10,0.05},value= root:FIRamp:FIR_SlopeChangePerStep
	ValDisplay ShallowSlopeValDisplay,pos={163,109},size={179,14},title="Shallowest Slope (nA/sec)"
	ValDisplay ShallowSlopeValDisplay,limits={0,0,0},barmisc={0,1000}
	ValDisplay ShallowSlopeValDisplay,value= #"root:FIRamp:FIR_ShallowSlope"
	CheckBox StepDirectionCheckBox,pos={325,127},size={100,14},proc=StepDirectionCheckProc,title="Step High to Low"
	CheckBox StepDirectionCheckBox,value= 0
	SetVariable FIR_StepbasesetVar,pos={17,156},size={164,16},title="Start Current Level (nA)"
	SetVariable FIR_StepbasesetVar,limits={-10,inf,1},value= root:FIRamp:FIR_stepbase
	SetVariable FIR_StepPlateausetVar1,pos={17,177},size={164,16},title="End Current Level (nA)"
	SetVariable FIR_StepPlateausetVar1,limits={-10,10,0.1},value= root:FIRamp:FIR_stepup
	Button PreviewStepsButton,pos={351,76},size={77,44},proc=ButtonCreateRampstep,title="Preview Steps"
	SetVariable setvar0,pos={190,177},size={178,16},title="Step Plateau Length"
	SetVariable setvar0,limits={0.1,10,0.1},value= root:FIRamp:FIR_plateauLength
	SetVariable FIR_PathnameVar1,pos={299,433},size={127,16},title="Path Name"
	SetVariable FIR_PathnameVar1,value= root:FIRamp:FIR_PathName
EndMacro

Function FIR_UpdateVoltSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Voltage_Signal=root:FIRamp:Voltage_Signal	
	Voltage_Signal=popStr
	print "Changing FI voltage signal to ", Voltage_Signal
End

Function FIR_UpdateCurrSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Current_Signal=root:FIRamp:Current_Signal	
	Current_Signal=popStr
	print "Changing FI Current_Signal to ", Current_Signal
End

Function FIR_UpdateoutSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Output_Signal=root:FIRamp:Output_Signal	
	Output_Signal=popStr
	print "Changing FI Output_Signal to ", Output_Signal
End

Function FIR_UpdateStimSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR StimOutput_Signal=root:FIRamp:StimOutput_Signal	
	StimOutput_Signal=popStr
	print "Changing FI StimOutput_Signal to ", StimOutput_Signal
End

//Function FIR_ChooseEvokStimWaveProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//	SVAR FIR_EvokStimWaveName= root:FIRamp:FIR_EvokStimWaveName
//	FIR_EvokStimWaveName =  popStr
//End

//Function StepDirectionCheckProc(ctrlName,checked) : CheckBoxControl
//	String ctrlName
//	Variable checked
//	NVAR FIR_StepDirectionCheck =  root:FIRamp:FIR_StepDirectionCheck
//	FIR_StepDirectionCheck = checked
//	print "Changing step direction check to " num2str(FIR_StepDirectionCheck)
//End

Function FIR_AvgCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FIR_AverageCheck =  root:FIRamp:FIR_AverageCheck
	FIR_AverageCheck = checked
	print "Changing avg check to " num2str(FIR_AverageCheck)
End

Function FIR_CalcFICheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR FIR_CalcFICheck =  root:FIRamp:FIR_CalcFICheck
	FIR_CalcFICheck = checked
	print "Changing FI calculate check to " num2str(FIR_CalcFICheck)
End



function Acq_FIR_data(ctrlname) 		: ButtonControl
	string ctrlname
	print  "****Starting Acq_FIR_data"
	//// Make sure the experiment is saved and therefore named
	if (StringMatch(IgorInfo(1),"Untitled"))	
		Print "\tAborting -- experiment not saved!"
		SetDataFolder root:
		Abort "You'd better save your experiment first!"
	endif
	Kill_FIR_windows()	
	string dfsave=GetDataFolder(1)
	SetDataFolder root:FIRamp	
	String AcqString, WFOutString
	String CommandStr
	variable FIR_AvgWindow	=0.010		// sec, window over which to average voltage measurement for VI curve
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
	Variable Current_IndBoardGain
	Variable  Current_AmpGain
	Variable DAC_out_Channel
	Variable DAC_out_AmpGain
	//variable DAC_out_Channel2
	variable	EvokStimOut_Channel
	variable EvokStimOut_AmpGain
	//print "2)  Loaded local variables"
	/// Need to get proper selection of Voltage_Signal,current_Signal,Output_Signal,StimOutputSignal
	SVAR Voltage_Signal =  root:FIRamp:Voltage_Signal	// string to be matched to find voltage channel
	SVAR current_Signal=  root:FIRamp:current_Signal	// string to be matched to find current channel
	SVAR Output_Signal =  root:FIRamp:Output_Signal			// string to be matched to find DAC output to drive current step 
	SVAR StimOutputSignal=  root:FIRamp:StimOutput_Signal
	//
	SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
	If(stringmatch(NowMulticlampMode, "V-Clamp"))
			SetDataFolder root:
			Abort "Use Multiclamp Commander to ensure mode is set to  ' I-Clamp' and update NIDAQ Switchboard"
	endif

//	SVAR Current_AxClMode 	=root:NIDAQBoardVar:Current_AxClMode
//	NVAR  Current_AxClGain	=root:NIDAQBoardVar:Current_AxClGain
//	//
//	NVAR UseEvokStimCheck 	=	root:FIRamp:FIR_UseEvokStimcheck
//	NVAR FIR_NoiseCheck		=		root:FIRamp:FIR_NoiseCheck
	//print "3) Loaded SVAR & NVAR signals"
// Update Telegraphs:  verify I-clamp, update scaled output gain, write to notebook the readouts
	If(stringmatch(Voltage_signal,"ScaledOutput"))
	//	Execute "UpdateTelegraphs()"
		//print "getting TG globals"
		NVAR Current_TG_Gain	=	root:NIDAQBoardVar:Current_TG_Gain		
		SVAR  Current_TG_Mode=	root:NIDAQBoardVar:Current_TG_Mode
		SVAR Current_ScaledOutType=root:NIDAQBoardVar:Current_ScaledOutType
		NVAR Current_TG_Filter	=root:NIDAQBoardVar:Current_TG_Filter
		NVAR current_TG_Capac	=root:NIDAQBoardVar:current_TG_Capac			
		if(   stringmatch(Current_ScaledOutType,"Current") || stringmatch(Current_ScaledOutType,"I=0") )
			SetDataFolder root:
			Abort "Axopatch Amplifier must be set in' I-Clamp Normal' or' I-Clamp Fast'"
		endif
		else
//		if(stringmatch(Voltage_signal,"AxCl_10vm"))
//			if(   !stringmatch(Current_AxClMode,"Iclamp") & !stringmatch(Current_AxClMode,"I-clamp"))
//				SetDataFolder root:
//				Abort "Axoclamp amplifier must be set in' I-Clamp' "
//			endif
//		endif
	endif
// determine correct channel #s for Scaled out (voltage), I output
	//Print "Getting Nidaq ADC/DAC globals"
	NVAR AcqResolution					=  root:DataAcquisitionVar:AcqResolution
	WAVE ADC_ChannelWave			=root:NIDAQBoardVar:ADC_ChannelWave
	WAVE ADC_SignalWave				=root:NIDAQBoardVar:ADC_SignalWave
	WAVE ADC_IndBoardGainWave		=root:NIDAQBoardVar:ADC_IndBoardGainWave
	WAVE ADC_AmpGainWave			=root:NIDAQBoardVar:ADC_AmpGainWave

	WAVE DAC_SignalWave				=root:NIDAQBoardVar:DAC_SignalWave
	WAVE DAC_Channel_Wave			=root:NIDAQBoardVar:DAC_Channel_Wave
	WAVE DAC_AmpGain_ICl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	
	// Check Evok stimulus control info
//	SVAR EvokStimWaveName=  root:FIRamp:FIR_EvokStimWaveName
//	NVAR UseEvokStimCheck =  root:FIRamp:FIR_UseEvokStimCheck
//	//NVAR BeforeAfterBuff =  root:FIRamp:FIR_BeforeAfterBuff
	//BeforeAfterBuff=0.400
//	controlinfo  /W=FIR_ControlPanel StimOutCheck
//	UseEvokStimCheck=V_Value	
//	controlinfo /W=FIR_ControlPanel ChooseEvokStimWavePopup
//	EvokStimWaveName=S_value
//	//print "Using evoked stimulus Wave:  " + EvokStimWaveName
//	if(stringmatch(EvokStimWaveName,"none"))
//		UseEvokStimCheck=0
//	endif

// find  channels;determine current amplifier gains for output & input waves;determine individual board gains for input waves
	//print "determining channels & gains"
	string ADCsignalList = ConvertTextWavetoList(ADC_SignalWave)
	string DACsignalList = ConvertTextWavetoList(DAC_SignalWave)
	Voltage_Channel=whichListItem(Voltage_Signal, ADCsignalList)				// channel is equivalent to position in List
	current_Channel=WhichlistItem(current_Signal, ADCsignalList)
	DAC_out_Channel=WhichlistItem(Output_Signal, DACsignalList)
//	if(UseEvokStimCheck)
//		print "Stim out signal= ", StimOutputSignal
//		EvokStimOut_Channel= WhichListItem(StimOutputSignal,DACSignalList)
//		EvokStimOut_AmpGain=1
//	endif
	if((Voltage_Channel==-1)  || (current_Channel==-1) || (DAC_out_Channel==-1)  )			// check that all have channels
		commandstr = "you must select  channels containing  "+Voltage_Signal +"," +  current_Signal + ", and " + Output_Signal 
		SetDataFolder root:
		Abort commandstr
	endif 
//	if(UseEvokStimCheck  & (EvokStimOut_Channel==-1))			// check that all have channels
//		commandstr = "you must select  channels containing  "+ StimOutputSignal
//		SetDataFolder root:
//		Abort commandstr
//	endif 
	
	Voltage_AmpGain= ADC_AmpGainWave[Voltage_Channel]
	Current_AmpGain=ADC_AmpGainWave[Current_Channel]
	DAC_out_AmpGain=DAC_AmpGain_ICl_Wave[DAC_out_Channel]
	
//	Voltage_IndBoardGain= ADC_IndBoardGainWave[Voltage_Channel]
//	Current_IndBoardGain=ADC_IndBoardGainWave[Current_Channel]
	
	//print "4) completed channels and gains"
	//////////////////////////////////////////////////////////////



	Make/N=4/O FIR_rawDataDisplay_pos,FIR_NowWaveDisplay_pos,FIR_RatevsCurrDisplay_pos,FIR_OutputWaves_pos,FIR_VoltvsCurrDisplay_pos
	FIR_rawDataDisplay_pos={LeftPos,TopPos,LeftPos+graph_Width,TopPos+Graph_Height}		// graph in top left
	FIR_NowWaveDisplay_pos={LeftPos,TopPos+Graph_Height+Graph_Grout_vert,LeftPos+graph_Width,TopPos+2*Graph_Height+Graph_Grout_vert}	// graph bottom left
	FIR_OutputWaves_pos={LeftPos+graph_width+Graph_grout,TopPos,LeftPos+2*graph_Width+Graph_Grout,TopPos+Graph_Height}	// graph top right
	FIR_RatevsCurrDisplay_pos={LeftPos+graph_width+Graph_grout,TopPos+Graph_Height+Graph_Grout_vert,LeftPos+2*graph_Width+Graph_Grout,TopPos+2*Graph_Height+Graph_Grout_vert}//graph bottom right
	FIR_VoltvsCurrDisplay_pos={LeftPos+graph_width+Graph_grout,TopPos+2*Graph_Height+2*Graph_Grout_vert,LeftPos+2*graph_Width+Graph_Grout,TopPos+3*Graph_Height+2*Graph_Grout_vert}//graph bottom right

// write F-I panel parameters to notebook
// all the panel variables:
	//print "Getting FI panel parameters"
	NVAR FIR_StepLength				=root:FIRamp:FIR_StepLength			// in sec
	NVAR FIR_ShallowSlope			=root:FIRamp:FIR_ShallowSlope		//in nA
	NVAR FIR_LargestSlope			=root:FIRamp:FIR_LargestSlope
	NVAR FIR_NumberSteps			=root:FIRamp:FIR_NumberSteps
	NVAR FIR_SlopeChangePerStep	=root:FIRamp:FIR_SlopeChangePerStep		// in nA
	
	NVAR FIR_ton						=root:FIRamp:FIR_ton
	NVAR FIR_plateauLength			=root:FIRamp:FIR_plateauLength
	NVAR FIR_stepbase				=root:FIRamp:FIR_stepbase
	NVAR FIR_stepup					=root:FIRamp:FIR_stepup
	NVAR FIR_toff_max				=root:FIRamp:FIR_toff_max
	
	NVAR FIR_ISI					=root:FIRamp:FIR_ISI					// in sec
	NVAR FIR_RepeatCheck			=root:FIRamp:FIR_RepeatCheck
	NVAR FIR_NumRepeats			=root:FIRamp:FIR_NumRepeats
	NVAR FIR_SetNum				=root:FIRamp:FIR_SetNum
	SVAR FIR_Basename				=root:FIRamp:FIR_Basename
	SVAR Basename					=root:DataAcquisitionVar:baseName
	String Local_Basename			=	"FIR_" +baseName + "s" + num2str(FIR_SetNum)	// recalculate a local basename
	NVAR FIR_AverageCheck			=root:FIRamp:FIR_AverageCheck
	NVAR FIR_nextAvg				=root:FIRamp:FIR_nextAvg
	SVAR FIR_AvgBasename			=root:FIRamp:FIR_AvgBasename
	NVAR FIR_CalcFICheck			=root:FIRamp:FIR_CalcFICheck
	NVAR FIR_SpikeThresh			=root:FIRamp:FIR_Spikethresh
	NVAR FIR_PlotVICurveCheck1	=root:FIRamp:FIR_PlotVICurveCheck1
	NVAR FIR_VIMeasure_t1			=root:FIRamp:FIR_VIMeasure_t1
	NVAR FIR_PlotVICurveCheck2	=root:FIRamp:FIR_PlotVICurveCheck2
	NVAR FIR_VIMeasure_t2			=root:FIRamp:FIR_VIMeasure_t2
		// new:  noise stim params
	NVAR FIR_NoiseSD	 =  root:FIRamp:FIR_NoiseSD	
	NVAR FIR_NoiseTarget	 =  root:FIRamp:FIR_NoiseTarget
	NVAR	FIR_NoiseExpTau	 =  root:FIRamp:FIR_NoiseExpTau
	NVAR FIR_NoisetestLength		 =  root:FIRamp:FIR_NoisetestLength
	NVAR FIR_NoiseVmSD	 =  root:FIRamp:FIR_NoiseVmSD
	SVAR  FIR_RangeNoiseLevels =  root:FIRamp:FIR_RangeNoiseLevels  // feb11
	print "Noise Levels  :" ,FIR_RangeNoiseLevels
	SVAR FIR_NoiseWFName =  root:FIRamp:FIR_NoiseWFName
	NVAR FIR_FreezeNoiseCheck = root:FIRamp:FIR_FreezeNoiseCheck
	NVAR FIR_NoiseSeed  =  root:FIRamp:FIR_NoiseSeed
	
	NVAR FIR_StepDirectionCheck  =  root:FIRamp:FIR_StepDirectionCheck
	Variable totalWavePoints = AcqResolution * ( FIR_StepLength)
	string TextStamp = FIR_basename
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
//		display/W=(FIR_OutputWaves_pos[0],FIR_OutputWaves_pos[3]+20,FIR_OutputWaves_pos[2],FIR_OutputWaves_pos[3]+120)  $EvokStimOutName  as "Evoked Stimulus Output waveform"
//		legend
//		Dowindow/C EvokStimDisplay
//	endif 
	StartingSetNumber=FIR_SetNum
// Write to notebook channels & gains
	Notebook Parameter_Log ruler=Title, text="\r\rStarting Ramped Firing-current Data Acquisition" +"\r"
	Notebook Parameter_Log ruler=Normal, text ="\t" +Date() + "  " + time() + "\r\r"
	Notebook Parameter_Log ruler=normal, text="\r\tAcquisition Resolution (samples/sec) :\t" + num2str(AcqResolution)
	Notebook Parameter_Log ruler=normal, text="\r\tVoltage signal : \t"  + Voltage_Signal  +" on channel " +num2str(Voltage_Channel)
	Notebook Parameter_Log ruler=normal, text="\r\tVoltage signal amplifier gain : " + num2str(Voltage_ampGain) + "\t and board gain : " + num2str(Voltage_IndBoardGain)
	Notebook Parameter_Log ruler =normal, text="\r\tCurrent signal : \t"  + current_Signal+" on channel " +num2str(current_Channel)
	Notebook Parameter_Log ruler =normal, text="\r\tCurrent  signal amplifier gain : " + num2str(Current_ampGain)+ "\t and board gain : " + num2str(Current_IndBoardGain)
	Notebook Parameter_Log ruler =normal, text="\r\tOutput to:  \t"  + Output_Signal+" on channel " +num2str(DAC_out_Channel)
	Notebook Parameter_Log ruler =normal, text="\r\tOutput amplifier gain : \t" + num2str(DAC_out_AmpGain)
//	if(UseEvokStimCheck)
//		Notebook Parameter_Log ruler =normal, text="\r\tUsing template stimulus wave: \t" +EvokStimWaveName
//		Notebook Parameter_Log ruler =normal, text="\r\tSaving actual stimulus wave for this set: \t" +EvokStimOutName
//	endif
	Notebook Parameter_Log ruler =normal, text="\r\tBasename for acquired waves: \t" +Local_Basename
	if(FIR_AverageCheck)
		Notebook Parameter_Log ruler =normal, text="\r\tAveraging across repeats of sets:  named:\t"   + FIR_AvgBasename
	endif
	Notebook Parameter_Log ruler =normal, text="\r\tSteepest Slope (nA/sec): \t" + num2str(FIR_LargestSlope)
	Notebook Parameter_Log ruler =normal, text="\r\tShallowest Slope (nA/sec): \t" +num2str(FIR_ShallowSlope)
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of steps per set: \t" +num2str(FIR_NumberSteps)
	Notebook Parameter_Log ruler =normal, text="\r\tSlope change per step (nA): \t" +num2str(FIR_SlopeChangePerStep)
	Notebook Parameter_Log ruler =normal, text="\r\tStarting step (nA): \t" +num2str(FIR_stepbase)
	Notebook Parameter_Log ruler =normal, text="\r\tPlateau (ending) step (nA): \t" +num2str(FIR_stepup)
	Notebook Parameter_Log ruler =normal, text="\r\tRamp starts at: \t" +num2str(FIR_ton)
	Notebook Parameter_Log ruler =normal, text="\r\tLongest ramp ends at: \t" +num2str(FIR_toff_max)
	
	
	Notebook Parameter_Log ruler =normal, text="\r\tStep Length (sec): \t" + num2str(FIR_StepLength)
	Notebook Parameter_Log ruler =normal, text="\r\tTotal Wave Length (sec): \t" + num2str(FIR_StepLength )	
	Notebook Parameter_Log ruler =normal, text="\r\tInter-stimulus interval (sec):\t" +num2str(FIR_ISI)
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of times to repeat: \t" +num2str(FIR_NumRepeats) + "\r"

	
// OUTPUT WAVE CREATION:  create once, reuse each iteration.		// feb11
	//print "Creating output waves"
	if(FIR_ISI <= (FIR_StepLength + 0.2))	// check that ISI is long enough (200ms extra room)	
		SetDataFolder root:
		Abort "ISI must be longer than "  + num2str((FIR_StepLength + 0.2))
	endif
	
	DoWindow /K FIR_OutputWaves
	Display /W=(FIR_OutputWaves_pos[0],FIR_OutputWaves_pos[1],FIR_OutputWaves_pos[2],FIR_OutputWaves_pos[3]) as "FI Output Waves- All"
	DoWindow /C FIR_OutputWaves
	
//	Make/O/N=1 Wave_SetNoiseLevels		// turn string in panel into wave with numerical noise levels
//	variable	FIR_NumNoiseLevels	=0	// count noise levels; initialize to 0
	string tempStr
	//i=0
//	do
//		tempStr = stringfromlist(i,FIR_RangeNoiseLevels,";")
//		if (strlen(tempStr)==0)
//			break
//		endif
//		Wave_SetNoiseLevels[i]={str2num(tempStr)}
//		i+=1
//		FIR_NumNoiseLevels+=1
//	while (1)
	String StepWavesName = Local_Basename + "_Steps"		// &&
	Make/O/N=(FIR_NumberSteps) $StepWavesName
	WAVE StepsWave = $StepWavesName
//	Make/T/N=(FIR_NumberSteps,FIR_NumNoiseLevels)/O OutNames_Wave		// 2D wave containing stim out names
//	Make/T/N=(FIR_NumberSteps,FIR_NumRepeats,FIR_NumNoiseLevels)/O VoltageAcqNames_Wave, currentAcqNames_Wave	//3D waves containing acquired data names
	Make/T/N=(FIR_NumberSteps)/O OutNames_Wave		// 1D wave containing stim out names
	Make/T/N=(FIR_NumberSteps,FIR_NumRepeats)/O VoltageAcqNames_Wave, currentAcqNames_Wave	//2D waves containing acquired data names


	Make /N=( totalWavePoints)/O tempwave0
	
	
	SetScale /P x 0, (1/AcqResolution), "sec",  tempwave0
	tempwave0=0

	//print "DAC_outGain  "  +  num2str(DAC_out_AmpGain)
	// generate noise to add to stimulus:
//	if(FIR_NoiseCheck)
//		Duplicate /O tempwave0, noisewave, unitstep
//		Make /N=( AcqResolution/100)/O NoiseExpFilter	// make a filter only as long as we need (1/100 of a sec= 10ms)
//		SetScale /P x 0, (1/AcqResolution), "sec",  NoiseExpFilter
//		NoiseExpFilter =exp(-x/FIR_NoiseExpTau)	// make filter of similar amplitude as gauss noise.
//		
//
//		print "Using noise waveform from last calibration run"
//		SetRandomSeed FIR_NoiseSeed 	// setting randomseed to a certain number means frozen noise; for gnoise line below
//
//		
//		noisewave = gnoise(FIR_NoiseSD)		//  Re-calculate noise based on frozen noise
//		convolve NoiseExpFilter,noisewave		// filter the noise
//		unitstep=0
//		unitstep[x2pnt(unitstep,FIR_ton),x2pnt(unitstep,FIR_StepLength)]=1
//		noisewave*=unitstep
//	endif
	
	//variable FIR_StepDirectionCheck	=0		// 1= option to run positive most step to negative, 0 goes negative to positive
		// add pull down menu to panel
		variable t_rampend
//	j=0
//	do
		i=0	
		do
			tempwave0=0
			//tempwave0[x2pnt(tempwave0,BeforeAfterBuff-.005),x2pnt(tempwave0,BeforeAfterBuff)]=0.5   // insert pre-step
			if(FIR_StepDirectionCheck)	
				StepsWave[i]=(FIR_LargestSlope-i*FIR_SlopeChangePerStep)	// high to low
				t_rampend=FIR_ton + (FIR_stepup-FIR_stepbase)/StepsWave[i]
				tempwave0[x2pnt(tempwave0,0),x2pnt(tempwave0,FIR_ton)]=FIR_stepbase
				tempwave0[x2pnt(tempwave0,FIR_ton),x2pnt(tempwave0,t_rampend)]=(x-FIR_ton)*StepsWave[i]
				tempwave0[x2pnt(tempwave0,t_rampend),x2pnt(tempwave0,t_rampend+FIR_plateauLength)]=FIR_stepup
				tempwave0[x2pnt(tempwave0,t_rampend+FIR_plateauLength),x2pnt(tempwave0,FIR_StepLength)]=0
				
				
				
				
			else
				StepsWave[i]=  (FIR_LargestSlope+i*FIR_SlopeChangePerStep)	// low to high
				t_rampend=FIR_ton + (FIR_stepup-FIR_stepbase)/StepsWave[i]
				tempwave0[x2pnt(tempwave0,0),x2pnt(tempwave0,FIR_ton)]=FIR_stepbase
				tempwave0[x2pnt(tempwave0,FIR_ton),x2pnt(tempwave0,t_rampend)]=(x-FIR_ton)*StepsWave[i]
				tempwave0[x2pnt(tempwave0,t_rampend),x2pnt(tempwave0,t_rampend+FIR_plateauLength)]=FIR_stepup
				tempwave0[x2pnt(tempwave0,t_rampend+FIR_plateauLength),x2pnt(tempwave0,FIR_StepLength)]=0
			endif
//			if(FIR_NoiseCheck)
//				tempwave0+=noisewave*Wave_SetNoiseLevels[j]	  // add scaled noise
//			endif
		
			tempWave0/=DAC_out_AmpGain		//  gain nA/V
			//tempWave0*=2
			OutNames_Wave[i]= Local_Basename+"Out_step" + num2str(i) 
			Duplicate /O tempWave0, $OutNames_Wave[i]
			AppendToGraph $OutNames_Wave[i]
			CommandStr = "Save/O/C/P=FIRPath " +OutNames_Wave[i]
			Execute CommandStr	
			
			i+=1
		while(i<FIR_NumberSteps)
//		j+=1
//	while(j<FIR_NumNoiseLevels)
		Modifygraph rgb=(0,0,0)	// make them all black; later make current stim red
		Label left "Command current (=actual/0.4nA)"
		Label bottom "Time (sec)"
		
		
			CommandStr = "Save/O/C/P=FIRPath " +StepWavesName
			Execute CommandStr							// Quick! Before the computer crashes!!!
// REAL TIME ANALYSES:


	//Set up for plotting of voltage traces
		//DoWindow/K FIR_AllWaveDisplay
	//	Display /W=(FIR_AllWaveDisplay_pos[0],FIR_AllWaveDisplay_pos[1],FIR_AllWaveDisplay_pos[2],FIR_AllWaveDisplay_pos[3])  as " Acquired Waves per Step"	
	//	Label left "Voltage (V)"
	//	Label bottom "Time (sec)"
	//	doWindow /C FIR_AllWaveDisplay
		DoUpdate
	
		

// FIRING RATE ANALYSIS: create names for firing rate wave  for current level waves;
//if numRepeats> 2, create waves for average&sd.
// Create Window to plot it.
	DoWindow/K FIR_RatevsCurrDisplay
	Display /W=(FIR_RatevsCurrDisplay_pos[0],FIR_RatevsCurrDisplay_pos[1],FIR_RatevsCurrDisplay_pos[2],FIR_RatevsCurrDisplay_pos[3])  as "FI Relation: Rate vs Current"	
	doWindow /C FIR_RatevsCurrDisplay
	controlInfo /W=FIR_ControlPanel CalcFICheck
	FIR_CalcFICheck=V_value
	if(FIR_CalcFICheck)
		//print "Setting up for FI curve analysis", num2str(FIR_CalcFICheck)
		variable simplethresh = 0.02					// simple voltage threshold to cross to determine spike
		variable minWidth	= 0.001					// minimum time (sec) between threshold crossings (determines max FR detectable)	
	//	i=0	// per noise
	//	do
			
			
			// text wave to keep track of FR waves
			//Make/T/O/N=(FIR_NumRepeats, FIR_NumNoiseLevels )  FRNames	// 2d text wave rows: trial #, columns: noiselevels)
		//	Make/T/O/N=(FIR_NumNoiseLevels )  FRAvgNames, FRSDNames	// 2d text wave rows: trial #, columns: noiselevels)
			Make/T/O/N=(FIR_NumRepeats )  FRNames	// 2d text wave rows: trial #, columns: noiselevels)
			Make/T/O/N=(1 )  FRAvgNames, FRSDNames	// 2d text wave rows: trial #, columns: noiselevels)
			j=0 // per trial repeat
			do	
				tempStr=Local_Basename  + "_FR_"		+num2str(j) 		// one wave for each trial,each noise
				//string CurrLevWave_Name=Local_Basename + "_CurrLev"						
				Make/O/N=(FIR_NumberSteps) $tempStr=0//,$CurrLevWave_Name //VICurve1Wave_Name,VIcurve2Wave_Name
				FRNames[j]= tempStr
				appendtograph $FRNames[j] vs StepsWave
				//Modifygraph rgb($FRNames[j])=((4-i)*25000,0,i*65000),  lstyle($FRNames[j])=7,mode($FRNames[j])=4,marker($FRNames[j])= 8
				print "appending to rate vs current graph ", tempStr
				j+=1
			while(j<FIR_NumRepeats)
			Modifygraph lstyle=3,mode=4,marker= 16
			Label left "Firing Rate (spikes/sec)"
			Label bottom "Current level (nA from Vm)"
			Modifygraph  lblPos(left)=40,live=1
			//Modifygraph lstyle=7,mode=4,marker= 8
			setAxis/A/E=1 left
			//edit FRNames
			tempStr = Local_Basename  + "_FRAvg"			// one average FR wave per noise level
			Make/O/N=(FIR_NumRepeats) $tempStr	
			FRAvgNames[0]=tempStr
			appendtograph $FRAvgNames[0] vs StepsWave
			
			Modifygraph lstyle( $FRAvgNames[0])=0,mode( $FRAvgNames[0])=4,marker( $FRAvgNames[0])= 16,rgb( $FRAvgNames[0])=(0,0,0) , lstyle( $FRAvgNames[0])=0
			//print "appending to rate vs current graph ", tempStr
			tempStr = Local_Basename  + "_FRSD"		// one average FR wave per noise level
			Make/O/N=(FIR_NumRepeats) $tempStr	
			FRSDNames[0]=tempStr
		//	i+=1
		//while(i<FIR_NumNoiseLevels)	
	
	endif
	
//		if(FIR_PlotVICurveCheck1)
//			DoWindow/K FIR_VICurveDisplay
//			Display /W=(FIR_VoltvsCurrDisplay_pos[0],FIR_VoltvsCurrDisplay_pos[1],FIR_VoltvsCurrDisplay_pos[2],FIR_VoltvsCurrDisplay_pos[3]) $VICurve1Wave_Names[0] vs $CurrLevWave_Names[0] as "Voltage vs Current"	
//			DoWindow/C FIR_VICurveDisplay
//			Label left "Voltage (V)"
//			Label bottom "Current level (nA from Vm)"
//			Modifygraph  lblPos(left)=40,live=1
//			Modifygraph lstyle($VICurve1Wave_Names[0])=7,mode($VICurve1Wave_Names[0])=4,marker($VICurve1Wave_Names[0]) =5,rgb($VICurve1Wave_Names[0])  =  (0,0,65500)
//		endif
//		if(FIR_PlotVICurveCheck2)
//			DoWindow/F FIR_VICurveDisplay
//			Appendtograph  $VICurve2Wave_Names[0] vs $CurrLevWave_Names[0]
//			print VICurve2Wave_Names[0]
//			Modifygraph lstyle($VICurve2Wave_Names[0])=6,mode($VICurve2Wave_Names[0])=4,marker($VICurve2Wave_Names[0]) = 6,rgb($VICurve2Wave_Names[0])  =  (0,65500,0)
//		endif
//		if(FIR_NumRepeats>1)
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
//				Make /O/N=(FIR_NumberSteps) $Name_FRWaveAvg,$Name_CurrLevWaveAvg,$Name_FRWaveSD,$Name_CurrLevWaveSD
//				doWindow /F FIR_RatevsCurrDisplay
//				AppendToGraph $Name_FRWaveAvg vs $Name_CurrLevWaveAvg
//				ModifyGraph lsize($Name_FRWaveAvg)=2,mode($Name_FRWaveAvg)=4, marker($Name_FRWaveAvg) =1
//				i+=1
//			while(i<FIR_NumNoiseLevels)
			
//			Make /O/N=(FIR_NumberSteps) $Name_V1LevAvg,$Name_V2LevAvg  ,$Name_V1LevSD  ,  $Name_V2LevSD
//			DoWindow /F FIR_VICurveDisplay 
//			AppendToGraph $Name_V1LevAvg vs $Name_CurrLevWaveAvg
//			ModifyGraph lsize($Name_V1LevAvg)=2,mode($Name_V1LevAvg)=4, marker($Name_V1LevAvg) =16,rgb($Name_V1LevAvg)  =  (0,0,65500)
//			AppendToGraph $Name_V2LevAvg vs $Name_CurrLevWaveAvg
//			ModifyGraph lsize($Name_V2LevAvg)=2,mode($Name_V2LevAvg)=4, marker($Name_V2LevAvg) =17,rgb($Name_V2LevAvg) = (0,65500,0)
	//	endif
/////////////////////////////	
	tempwave0=0
	String PriorTrace=""
	String PriorOutTrace=""
		DoWindow/K FIR_rawDataDisplay	
		Display /W=(FIR_rawDataDisplay_pos[0],FIR_rawDataDisplay_pos[1],FIR_rawDataDisplay_pos[2],FIR_rawDataDisplay_pos[3])  as "FI Ramp Raw Acquired Waves"
		Label left "Voltage (V)"
		Label bottom "Time (sec)"
		doWindow /C FIR_rawDataDisplay
		
		DoWindow/K FIR_NowWaveDisplay	
		Display /W=(FIR_NowWaveDisplay_pos[0],FIR_NowWaveDisplay_pos[1],FIR_NowWaveDisplay_pos[2],FIR_NowWaveDisplay_pos[3])  as "FI  Ramp Raw Acquired Waves- Most Recent"
		Label left "Voltage (V)"
		Label bottom "Time (sec)"
		doWindow /C FIR_NowWaveDisplay
		
		DoWindow/K FIR_NowOutputWaves	
		Display /W=(FIR_OutputWaves_pos[0],FIR_OutputWaves_pos[1],FIR_OutputWaves_pos[2],FIR_OutputWaves_pos[3]) as "FI  Ramp Output Waves - Now"		
		Label left "Command current (=actual/0.4 nA)"
		Label bottom "Time (sec)"
		doWindow /C FIR_NowOutputWaves
		
	k=0			// loop variable for steps OUTERMOST LOOP
	do												// loop for each Set Iteration
		print "Beginning step  number:", num2str(k)

		 print "           DC step level (nA):  ", num2str(StepsWave[k])
		// create waves for acquiring current & voltage data; create at beginning of each iteration & step Loop
		//print Local_Basename
//	
//	
//			
//				Appendtograph /W=FIR_RatevsCurrDisplay $FRWave_Names[k] vs $CurrLevWave_Names[k]
//				Modifygraph /W=FIR_RatevsCurrDisplay lstyle($FRWave_Names[k])=7,mode($FRWave_Names[k])=4,marker($FRWave_Names[k]) = 8
////				Appendtograph /W=FIR_VICurveDisplay $VICurve1Wave_Names[k] vs $CurrLevWave_Names[k]
////				Appendtograph /W=FIR_VICurveDisplay $VICurve2Wave_Names[k] vs $CurrLevWave_Names[k]
////				Modifygraph  /W=FIR_VICurveDisplay lstyle($VICurve1Wave_Names[k])=7,mode($VICurve1Wave_Names[k])=4,marker($VICurve1Wave_Names[k]) =5,rgb($VICurve1Wave_Names[k])  =  (0,0,65500)
////				Modifygraph /W=FIR_VICurveDisplay lstyle($VICurve2Wave_Names[k])=6,mode($VICurve2Wave_Names[k])=4,marker($VICurve2Wave_Names[k]) = 6,rgb($VICurve2Wave_Names[k])  =  (0,65500,0)
//
//	
//			

//			if( (Waveexists(temp_FRate)==0)  ||  (Waveexists(temp_Currlev)==0) )
//				print "temp_FRate or Temp_currlev does not exist"
//			endif
//		endif
		
			

		//  create window for real-time raw data display:
	
		//// Make variables to acquire a temperature measure, once at the beginning of each set.  
		variable TempGain = 0.1	// gain on the T2 output is 100mV/degC
		variable CurrentTempDegC
		//string TempAcqString = "TemperatureGrabWave,7,1"
		string TempAcqString = "TemperatureGrabWave,2"
		Make /O/N=100 TemperatureGrabWave
		SetScale /P x 0, (1/AcqResolution), "sec",  TemperatureGrabWave
		print "Getting temperature data"
		mysimpleAcqRoutine("",TempAcqString)
		TemperatureGrabWave/=TempGain
		CurrentTempDegC=mean(TemperatureGrabWave,-inf,inf)
		print "CurrentTempDegC=  ", CurrentTempDegC
		Notebook Parameter_Log ruler =normal, text="\r\t  Recording chamber temperature (T2) : \t" + num2str(CurrentTempDegC) + " degrees C"
		///
		//offsetTick=0		// reset offset for plotting raw voltage data	
		DoUpdate	
		j=0
		do	// Loop through trial repeats
										
	//	i=0 
	//	do  // Loop through noise levels 
		
			StartTicks=ticks
			print "Beginning step loop ", num2str(j)
			// send waves to nidaq
			
			VoltageAcqNames_Wave[k][j] =  Local_Basename + "_V" + num2str(k)	+  "_" + num2str(j)	
			currentAcqNames_Wave[k][j]=Local_Basename + "_A" + num2str(k)	+ "_" + num2str(j)	
			duplicate /O tempwave0, $VoltageAcqNames_Wave[k][j]
			duplicate /O tempwave0, $currentAcqNames_Wave[k][j]
			DoWindow /F FIR_NowOutputWaves
			Appendtograph $OutNames_Wave[k]
			Label left "Command current (=actual/0.4 nA)"
			Label bottom "Time (sec)"
			Modifygraph rgb($OutNames_Wave[k])=(65000,0,0)		// make current output stimulus red
			if(strlen(PriorOutTrace) > 0)
				RemoveFromGraph $PriorOutTrace
			endif
			PriorOutTrace=OutNames_Wave[k]
			DoUpdate
			
			//AcqString=VoltageAcqNames_Wave[k][j][i] +"," +num2str(Voltage_Channel)+ "," + num2str(Voltage_IndBoardGain)
			//AcqString+=";" +currentAcqNames_Wave[k][j][i]+"," +num2str(Current_Channel) + "," + num2str(Current_IndBoardGain)
			
			AcqString=VoltageAcqNames_Wave[k][j] +"," +num2str(Voltage_Channel)
			AcqString+=";" +currentAcqNames_Wave[k][j]+"," +num2str(Current_Channel) 
			WFOutString=OutNames_Wave[k]+ "," + num2str(DAC_Out_Channel)
//			if(UseEvokStimCheck)
//				WFOutString+= ";" + EvokStimOutName +"," +  num2str(EvokStimOut_Channel)
//			endif
			print "sending acq strings  ",  AcqString, WFOutSTring
			mySimpleAcqRoutine(WFOutString,AcqString)
			
			// condition acquired waves according to amplifier gains
			
			Wave VoltAcqWave=$VoltageAcqNames_Wave[k][j]
			Wave CurrAcqWave=$currentAcqNames_Wave[k][j]
			if( (Waveexists(VoltAcqWave)==0)  ||  (Waveexists(CurrAcqWave)==0) )
				print "VoltAcqWave or CurrAcqWave does not exist"
			endif
			VoltAcqWave/=Voltage_AmpGain	
			CurrAcqWave/=Current_AmpGain
			// save waves to hard drive
			CommandStr = "Save/O/C/P=FIRPath " +VoltageAcqNames_Wave[k][j]  +","+currentAcqNames_Wave[k][j]
			Execute CommandStr							// Quick! Before the computer crashes!!!
	
			// display  raw voltage & current data		-->> FI raw data window
			DoWindow /F FIR_NowWaveDisplay
			appendtoGraph $VoltageAcqNames_Wave[k][j]
			Label left "Voltage (V)"
			Label bottom "Time (sec)"
			if(strlen(PriorTrace) > 0)
				RemoveFromGraph $PriorTrace
			endif
			DoUpdate
			
			DoWindow /F  FIR_rawDataDisplay
			if(strlen(PriorTrace) > 0)
				//RemoveFromGraph $PriorTrace
				Modifygraph rgb=(0,0,0)		// set old traces to black
			endif
			appendtoGraph $VoltageAcqNames_Wave[k][j]
			Label left "Voltage (V)"
			Label bottom "Time (sec)"
	
			PriorTrace=VoltageAcqNames_Wave[k][j]
			
			//DoWindow /F FIR_AllWaveDisplay
			//appendtoGraph $VoltageAcqNames_Wave[k][j][i] 
			DoUpdate
			//REAL TIME ANALYSIS: AVERAGING voltage and current traces across set repeats:
//			if(FIR_AverageCheck)	
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
//				DoWindow/F FIR_AvgWaveDisplay
//				ModifyGraph live=1
//			endif
			//REAL TIME ANALYSIS: FI CURVE 
						Wave temp_FRate = $FRNames[j]		// get FR wave name for this trial, this noise level
			//WAVE temp_CurrLev= $CurrLevWave_Name
//			WAVE temp_V1Lev = $VICurve1Wave_Names[k]
//			WAVE temp_V2Lev = $VICurve2Wave_Names[k]
//			
				//calculating firing rate versus current, for each set:
				FindLevels /Q/P/M=(minWidth)/R=(FIR_ton,FIR_StepLength)  VoltAcqWave, FIR_SpikeThresh
				if (V_Flag==2)
					//print "found no spikes"
					temp_FRate[k]=0			// if no spikes, set to 0
				else
					temp_FRate[k]=  V_LevelsFound/FIR_StepLength		// firing rate is #spikes/duration of step
					//  offset trace by 100mV
					//if(FIR_CalcFICheck)
					DoWindow/F FIR_RawDatadisplay
					print "offsetting ", VoltageAcqNames_Wave[k][j], "by ", offsetTick
					ModifyGraph offset($VoltageAcqNames_Wave[k][j]) = {0,offsetTick*0.1}
					offsetTick+=1
					DoUpdate
					
					//endif
				endif			
				//temp_CurrLev[j] = DAC_out_AmpGain*mean($OutNames_Wave[j],BeforeAfterBuff,(BeforeAfterBuff+FIR_StepLength))  // actual  intended output current applied
				//temp_CurrLev[j] = mean(CurrAcqWave,BeforeAfterBuff+0.003,(BeforeAfterBuff+FIR_StepLength))	// current level for this step, discounting the rise time of ~3ms
				DoWindow/F FIR_RateVsCurrDisplay
				ModifyGraph live=1
				// Calculating VI1 and VI2
//				Temp_v1lev[j] = mean(VoltAcqWave,BeforeAfterBuff+FIR_VIMeasure_t1 , BeforeAfterBuff+FIR_VIMeasure_t1 + FIR_AvgWindow)- mean(VoltAcqWave, 0.001 ,  BeforeAfterBuff-0.005)
//				Temp_v2lev[j] = mean(VoltAcqWave,BeforeAfterBuff+FIR_VIMeasure_t2 , BeforeAfterBuff+FIR_VIMeasure_t2 + FIR_AvgWindow)- mean(VoltAcqWave, 0.001 ,  BeforeAfterBuff-0.005)
			CommandStr = "Save/O/C/P=FIRPath "+ FRNames[j] 	// Save the FR wave in the home path right away!
			Execute CommandStr
			do									//waste time between runs according to ISI
				elapsedTicks=ticks-StartTicks
			while((elapsedTicks/60.15)<FIR_ISI)		
			//i+=1
		//	while(i<FIR_NumNoiseLevels)
			j+=1
		while(j<FIR_NumRepeats)
		// do averaging for each step (does this repeatedly to show progress)
		
		
			
	if(FIR_CalcFICheck)
		if(FIR_NumRepeats>1)
			print "Averaging FI curves and VI curves across sets"
			variable errortype=1			// 1=sd; 2=conf int; 3=se; 0=none)
			variable errorinterval=1		// # of sd's	
			variable a, b 
			string FR_list, TempFRAvgName, TempFRSDName
			//a=0
			//do
				FR_list = FRNames[0]+";"
				b=0
				do 
					FR_list+=FRNames[b] +";"
					b+=1
				while(b<FIR_NumRepeats)
				TempFRAvgName = FRAvgNames[ 0 ]
				TempFRSDName = FRSDNames [0 ]
				fWaveAverage(FR_list,errortype,errorinterval,TempFRAvgName,TempFRSDName)
				CommandStr = "Save/O/C/P=FIRPath "+ TempFRAvgName +"," +	TempFRSDName 
				Execute CommandStr		// Save it!	
	
		//		a+=1	
		//	while(a<FIR_NumNoiseLevels)
//			Notebook  Parameter_Log ruler =normal, text="\r\rCalculated FI curve averages across set#" +num2str(StartingSetNumber) + "-" +num2str(EndingSetNumber)
//			Notebook  Parameter_Log ruler =normal, text="\r\tAverages of Firing rates:\t" +Name_FRWaveAvg + "+/-" + Name_FRWaveSD
//			Notebook  Parameter_Log ruler =normal, text="\r\tAverages of current steps:\t" +Name_CurrLevWaveAvg + "+/-" + Name_CurrLevWaveSD

		endif
	endif
		
		
		// insert dialog box here to continue with next level or abort 

		k+=1
		
		if(FIR_StepDirectionCheck==0)		// only ask if going from low to high steps
			if(k<FIR_NumberSteps)		// don't ask if this is the last step
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
			
	while(k<FIR_NumberSteps)	
	



	
		
		/////	

		Notebook  Parameter_Log ruler =normal, text="\r\rCompleted Set#" + num2str(FIR_SetNum)
		Notebook  Parameter_Log ruler =normal, text="\r\tAcquired voltage traces:\t" +VoltageAcqNames_Wave[0] +"-" + num2str(FIR_Numbersteps)
		Notebook  Parameter_Log ruler =normal, text="\r\tAcquired actual current traces:\t" + currentAcqNames_Wave[0]+ "-" + num2str(FIR_Numbersteps)
//		if(FIR_CalcFICheck)
//			Notebook  Parameter_Log ruler =normal, text="\r\tFI curve for this set, firing rates:\t" + FRWave_Name
//			Notebook  Parameter_Log ruler =normal, text="\r\tFI curve for this set, current steps:\t" + CurrLevWave_Name
//		endif
		FIR_SetNum+=1			// update set#
		Local_Basename			=	"FIR_" +baseName + "s" + num2str(FIR_SetNum)	// recalculate basename


	EndingSetNumber=StartingSetNumber+k
	// END OF SET ANALYSIS FOR FI CURVE:    average spikes & current levels & plot mean +- s.d. -->>  
	

	

	// END OF MACRO CLEAN-UP:
	print "Cleaning up"
	FIR_Basename= Local_Basename			// update global FI basename
	//dowindow /K FIR_outputWaves
	KillWaves/Z tempWave0				// kill output waves & all other temporary & non-essential waves

	KillWaves/Z currentAcqNames_Wave,voltageAcqNames_Wave,OutNames_Wave,TemperatureGrabWave
	KillWaves/Z  tempWavesName_1,tempWavesName_2,tempWavesName_3,tempWavesName_4
	KillWaves /Z currLevWave_Names,FRWave_Names,W_FindLevels
	killWaves/Z FIR_OutputWaves_pos,FIR_RatevsCurrDisplay_pos,FIR_AvgWaveDisplay_pos,FIR_rawDataDisplay_pos
	Notebook  Parameter_Log ruler =normal, text="\r\r"
	Dowindow/K FIR_Layout
	NewLayout /P=portrait /w=(80,40,400,450) as TextStamp
	variable LeftEdge=85
	variable topedge=85
	variable GraphWidth=225
	variable GraphHeight=100
	//if(FIR_numberSteps>2)
		Appendlayoutobject /T=1/F=0/R=(leftEdge,topEdge,leftEdge+graphWidth,topEdge+3.5*GraphHeight) graph FIR_rawDataDisplay
//	else
		Appendlayoutobject /T=1/F=0/R=(leftEdge+graphWidth,topEdge,leftEdge+2*graphWidth+20,topEdge+2.5*GraphHeight) graph FIR_RateVsCurrDisplay
//	endif
	//Appendlayoutobject /T=1/F=0/R=(leftEdge+graphWidth,topEdge+2.5*GraphHeight,leftEdge+2*graphWidth+20,topEdge+3.3*GraphHeight) graph FIR_OutputWaves

	 GraphWidth=450
	 GraphHeight=100
	Appendlayoutobject /T=1/F=0/R=(leftEdge,topEdge+3.5*GraphHeight,leftEdge+0.5*graphWidth,topEdge+6*GraphHeight) graph  FIR_OutputWaves
	//Appendlayoutobject /T=1/F=0/R=(leftEdge+0.5*graphWidth,topEdge+3.5*GraphHeight,leftEdge+graphWidth,topEdge+6*GraphHeight) graph FIR_VICurveDisplay
	Dowindow/C FIR_Layout
	//Execute "StampExptDate() "
	TextBox/A=MT /E/F=0/A=MT/X=0.00/Y=0.00 TextStamp
	Dowindow/B FIR_Layout
	Notebook Parameter_Log text="\rCompleted run:\tTime: "+Time()+"\r\r"
	Notebook  Parameter_Log ruler =normal, text="\r\r"	
	SetDataFolder root:			// return to root 
end		

function Kill_FIR_windows()
	DoWindow/K FIR_rawDataDisplay;DoWindow/K FIR_NowOutputWaves; ;DoWindow/K FIR_PreviewOutputWaves
	DoWindow/K FIR_RatevsCurrDisplay;DoWindow /K FIR_OutputWaves;DoWindow/K FIR_VICurveDisplay
	DoWindow/K  FIR_Layout;DoWindow/K EvokStimDisplay;DoWindow/K FIR_NowWaveDisplay
end
	






