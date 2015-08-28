#pragma rtGlobals=1		// Use modern global access method.
///   IVRelProcsv.2.1MC
//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\WavetoList procs"
//#include "WavetoList procs"
#include <Waves Average>
///IVRelationProcs v.2.1
// 03/06/2012  updated to use Multiclamp amplifier
// 10/06/03   copied FIRelation proc to be identical IV proc v2.1

	Menu "Initialize Procedures"
	"Initialize IV Relation Parameters",Init_IVRelationControlPanel()
end

Menu "Kill Windows"
"Kill IV Data Acq Graphs",Kill_IV_windows()
end


Proc Init_IVRelationControlPanel()
	// Check to see whether Globals Folder exists (i.e., that the InitializeDataAcquisition procedure 
	// has been run & common global variables exist
	if( DataFolderExists("root:DataAcquisitionVar"))	
		String dfSave=GetDataFolder(1)
		NewDataFolder /O/S root:IVRelation			// Create folder for IV variables
		DoWindow/K IV_rawDataDisplay
		DoWindow/K IV_AvgWaveDisplay
		DoWindow/K IV_RatevsCurrDisplay		
		DoWindow/K IV_IVCurveDisplay		
		KillWaves /a/z								// clean out folder & start from scratch
		killvariables /a/z		
		killstrings /a/z
		///  create variables for signal selection:
//		string/G Voltage_signal	=	 "10Vm"	
//		String/G Current_signal	= 	"ScaledOutput"
//		String/G Output_Signal	=	"Ext Command (front)"
//		string/G StimOutput_Signal	=	 "Extracellular SIU1"
		
		string/G Voltage_signal	=	 "SecondaryOutCh1"	
		String/G Current_signal	= 	"PrimaryOutCh1"
		String/G Output_Signal	=	"Command"
		string/G StimOutput_Signal	=	 "Extracellular SIU1"
		//
		Variable /G IV_StepLength		=	1		//sec
		Variable /G IV_BeforeAfterBuff = 	0.200	//  time before & after step, ms
		VAriable /G IV_PrePulseStepAmplitude = 0.00	// set prepulse conditioning potential
		Variable /G IV_NegMostStep		=	-0.010	//V
		Variable /G IV_PosMostStep		=	0.11		//V
		Variable /G IV_NumberSteps	=	2		// # steps in current step protocol
		Variable /G IV_CurrentPerStep:=(IV_PosMostStep-IV_NegMostStep)/(IV_NumberSteps-1)
		Variable /G IV_ISI				=   2		// seconds between steps
		Variable /G IV_RepeatCheck		=	1		// Repeat sets?
		Variable /G IV_NumRepeats		=	1		// Repeat # times
		Variable /G IV_SetNum			=	0		// Label each set of current steps
		String 	/G IV_Basename			:=	"IV_" +root:DataAcquisitionVar:baseName + "s" + num2str(IV_setnum)	// Acquisition waves basename
		Variable /G IV_AverageCheck	=	1		// Calculate averages?
		variable /G IV_nextAvg			=	0
		string 	/G IV_AvgBasename		:=	"IV_" + root:DataAcquisitionVar:baseName  +"_avg" +num2str(IV_nextAvg)// Averaging waves basename
		Variable /G IV_CalcIVCheck		=	0			// plot IVCurve check	
		variable /G IV_SpikeThresh		=	0		// Threshold for counting spikes
		// VI curve analysis
		variable /G IV_PlotIVCurveCheck1	=  1	// plot VI curve #1 check
		variable /G IV_IVMeasure_t1		=  0.790	// seconds after onset
		variable /G IV_PlotIVCurveCheck2	=  1	// plot VI curve #1 check
		variable /G IV_IVMeasure_t2		=  0.802	// seconds after onset
		variable/G IV_MeasAvgWindow		= 0.001	// seconds over which to average current to make measurements
		variable/G IV_Plot_t2minust1		= 1	// plot delta current (e.g., PSC size)
		//
		
		variable /G IV_UseEvokStimCheck = 1		// send an evoked stimulus to an SIU during Steps
		string /G IV_EvokStimWaveName = "StimCF"	
		string /G IV_DefaultStimWaveName = "IV_EvStimWave0"
		variable/G IV_DefaultNumstim		= 1
		Variable/G IV_DefaultDelay		= IV_BeforeAfterBuff + 0.100	// time stim to occur 100ms into step
		Variable/G IV_defaultEvStimFreq	= 1	
		variable /G dataDisplay_x1 = 0.998
		variable/G dataDisplay_x2 = 1.01
		variable /G dataDisplay_y1 = -2.0		// nA , absolute
		variable/G dataDisplay_y2 = 4.0		// nA
		Execute "IV_ControlPanel()"
		SetDataFolder dfSave
		SaveExperiment
		NewPath /C/M="Choose folder for IV files"/O/Q/Z IVPath
	else
		Print "You must first initialize global variables with procedure 'InitializedDataAcquisition()' "
	endif
end

Window IV_ControlPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(758,97,1507,384)
	ModifyPanel cbRGB=(48896,65280,65280)
	ShowTools
	SetDrawLayer UserBack
	SetDrawEnv fillpat= 2,fillfgc= (32768,32768,65280)
	DrawRRect 427,4,12,30
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 42,26,"Current-Voltage (IV) Relation Control Panel"
	SetDrawEnv fillpat= 0
	DrawRect 369,75,414,100
	DrawLine 369,86,354,86
	DrawLine 416,87,428,87
	SetDrawEnv fsize= 9
	DrawText 272,227,"(relative to onset)"
	SetVariable StepLengthSetVar,pos={12,71},size={136,16},title="Step Length (sec)"
	SetVariable StepLengthSetVar,limits={0.01,10,0.1},value= root:IVRelation:IV_StepLength
	SetVariable NegMostStepSetVar,pos={166,90},size={178,16},title="Negative Most Step (V)"
	SetVariable NegMostStepSetVar,limits={-1,1,0.01},value= root:IVRelation:IV_NegMostStep
	SetVariable NumStepsSetVar,pos={13,90},size={136,16},title="Number of Steps "
	SetVariable NumStepsSetVar,limits={1,50,1},value= root:IVRelation:IV_NumberSteps
	SetVariable PosMostStepSetVar_1,pos={166,70},size={177,16},title="Positive Most Step (V)"
	SetVariable PosMostStepSetVar_1,limits={-1,1,0.01},value= root:IVRelation:IV_PosMostStep
	ValDisplay VoltPerStepValDisplay,pos={166,113},size={226,14},title="Voltage (V)/Step"
	ValDisplay VoltPerStepValDisplay,font="Courier",format="%g"
	ValDisplay VoltPerStepValDisplay,limits={0,0,0},barmisc={0,60}
	ValDisplay VoltPerStepValDisplay,value= #" root:IVRelation:IV_CurrentPerStep"
	SetVariable IV_BasenameSetVar,pos={13,36},size={265,16},title="Acquisition Waves Basename"
	SetVariable IV_BasenameSetVar,value= root:IVRelation:IV_Basename
	SetVariable RepeatSetVar,pos={38,172},size={126,16},title="# to repeat set :"
	SetVariable RepeatSetVar,limits={1,100,1},value= root:IVRelation:IV_NumRepeats
	CheckBox AvgCheck,pos={18,189},size={107,14},disable=2,proc=IV_AvgCheckProc,title="Average Repeats?"
	CheckBox AvgCheck,value= 1
	SetVariable AvNameSetVar,pos={130,190},size={249,16},title="Average Waves Basename:"
	SetVariable AvNameSetVar,value= root:IVRelation:IV_AvgBasename
	SetVariable SetNumSetVar,pos={293,35},size={118,16},title="Current Set #"
	SetVariable SetNumSetVar,value= root:IVRelation:IV_SetNum
	Button IV_AcquireButton,pos={461,225},size={181,29},proc=Acq_IV_data,title="Acquire"
	PopupMenu SelectOutSignalPopup,pos={467,70},size={178,21},proc=IV_UpdateoutSignalProc,title="Output Step Signal"
	PopupMenu SelectOutSignalPopup,mode=2,popvalue="Command",value= #"root:NIDAQBoardVar:OutputNamesString"
	PopupMenu SelectInputSignalPopup,pos={457,50},size={203,21},proc=IV_UpdateVoltSignalProc,title="Vm Input Signal"
	PopupMenu SelectInputSignalPopup,mode=3,popvalue="SecondaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	SetVariable ISISetVar,pos={18,113},size={135,16},title="ISI (sec)           "
	SetVariable ISISetVar,limits={0.1,60,0.1},value= root:IVRelation:IV_ISI
	SetVariable nextAvgSetVar,pos={275,173},size={87,16},title="avg tick:"
	SetVariable nextAvgSetVar,limits={0,100,1},value= root:IVRelation:IV_nextAvg
	PopupMenu SelectOutStimPopup,pos={435,152},size={241,21},proc=IV_UpdateStimSignalProc,title="Stimulus Output Signal   "
	PopupMenu SelectOutStimPopup,mode=4,popvalue="Extracellular SIU1",value= #"root:NIDAQBoardVar:OutputNamesString"
	CheckBox StimOutCheck,pos={445,113},size={157,14},proc=IV_StimoutCheckProc,title="Use Evoked Stimulus Wave?"
	CheckBox StimOutCheck,value= 0
	PopupMenu ChooseEvokStimWavePopup,pos={494,128},size={81,21},proc=IV_ChooseEvokStimWaveProc,title=" "
	PopupMenu ChooseEvokStimWavePopup,mode=1,popvalue="_none_",value= #"Wavelist(\"*\",\";\",\"\")"
	GroupBox Box1,pos={6,54},size={428,98},title="Steps"
	GroupBox Box2,pos={7,155},size={427,126},title="Reps"
	GroupBox Box3,pos={441,95},size={259,83},title="Stimuli"
	GroupBox Box4,pos={440,2},size={257,93},title="Signals"
	PopupMenu IV_CurrentSigMonitorPopup,pos={453,22},size={205,21},proc=IV_UpdateCurrSignalProc,title="Current Input Signal"
	PopupMenu IV_CurrentSigMonitorPopup,mode=2,popvalue="PrimaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	CheckBox IV1CheckBox,pos={14,211},size={132,14},disable=2,title="Plot Current1 vs Voltage"
	CheckBox IV1CheckBox,value= 1
	SetVariable I1_time_SetVar,pos={151,211},size={117,16},title="t delay"
	SetVariable I1_time_SetVar,limits={0,10,0.05},value= root:IVRelation:IV_IVMeasure_t1
	CheckBox IV2CheckBox,pos={13,233},size={132,14},disable=2,title="Plot Current2 vs Voltage"
	CheckBox IV2CheckBox,value= 1
	SetVariable I2_time_SetVar01,pos={150,230},size={117,16},title="t delay"
	SetVariable I2_time_SetVar01,limits={0,1,0.0001},value= root:IVRelation:IV_IVMeasure_t2
	SetVariable SetBufferVar,pos={17,132},size={144,16},title="PreBuffer time"
	SetVariable SetBufferVar,limits={0.1,1,0.1},value= root:IVRelation:IV_BeforeAfterBuff
	SetVariable setvar0,pos={269,230},size={150,16},title="Measure window (s)"
	SetVariable setvar0,limits={0.0001,0.1,0.0001},value= root:IVRelation:IV_MeasAvgWindow
	SetVariable setvar1,pos={169,133},size={200,16},title="Prepulse amplitude (v)"
	SetVariable setvar1,limits={-0.5,0.5,0.01},value= root:IVRelation:IV_PrePulseStepAmplitude
	SetVariable setvar2,pos={444,185},size={131,16}
	SetVariable setvar2,limits={0,inf,0.05},value= root:IVRelation:dataDisplay_x1
	SetVariable setvar3,pos={442,203},size={134,16}
	SetVariable setvar3,limits={0,inf,0.05},value= root:IVRelation:dataDisplay_x2
	SetVariable setvar4,pos={584,187},size={116,16},title="_y1 (absol nA)"
	SetVariable setvar4,limits={-10,0,0.5},value= root:IVRelation:dataDisplay_y1
	SetVariable setvar5,pos={583,204},size={120,16},title="_y2 (absol nA)"
	SetVariable setvar5,limits={0,10,0.5},value= root:IVRelation:dataDisplay_y2
	CheckBox PlotDeltaCurrCheckbox,pos={13,256},size={98,14},disable=2,title="Plot delta current"
	CheckBox PlotDeltaCurrCheckbox,value= 1
EndMacro

Function IV_UpdateVoltSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Voltage_Signal=root:IVRelation:Voltage_Signal	
	Voltage_Signal=popStr
	print "Changing IV voltage signal to ", Voltage_Signal
End

Function IV_UpdateCurrSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Current_Signal=root:IVRelation:Current_Signal	
	Current_Signal=popStr
	print "Changing IV Current_Signal to ", Current_Signal
End

Function IV_UpdateoutSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Output_Signal=root:IVRelation:Output_Signal	
	Output_Signal=popStr
	print "Changing  IV Output_Signal to ", Output_Signal
End

Function IV_UpdateStimSignalProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR StimOutput_Signal=root:IVRelation:StimOutput_Signal	
	StimOutput_Signal=popStr
	print "Changing  IV StimOutput_Signal to ", StimOutput_Signal
End

Function IV_ChooseEvokStimWaveProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR IV_EvokStimWaveName= root:IVRelation:IV_EvokStimWaveName
	IV_EvokStimWaveName =  popStr
End


Function IV_AvgCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR IV_AverageCheck =  root:IVRelation:IV_AverageCheck
	IV_AverageCheck = checked
	print "Changing avg check to " num2str(IV_AverageCheck)
End

Function IV_CalcFICheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR IV_CalcFICheck =  root:IVRelation:IV_CalcFICheck
	IV_CalcFICheck = checked
	print "Changing  IVcalculate check to " num2str(IV_CalcFICheck)
End

Function IV_StimoutCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR IV_UseEvokStimCheck =  root:IVRelation:IV_UseEvokStimCheck
	IV_UseEvokStimCheck = checked
	print "Changing UseEvokStimCheck to " num2str(IV_UseEvokStimCheck)
End


function Acq_IV_data(ctrlname) 		: ButtonControl
	string ctrlname
	print  "****Starting Acq_IV_data"
	//// Make sure the experiment is saved and therefore named
	if (StringMatch(IgorInfo(1),"Untitled"))	
		Print "\tAborting -- experiment not saved!"
		SetDataFolder root:
		Abort "You'd better save your experiment first!"
	endif
	Kill_IV_windows()	
	string dfsave=GetDataFolder(1)
	SetDataFolder root:IVRelation	
	String AcqString, WFOutString
	String CommandStr
	variable StartTicks,elapsedTicks
	variable StartingSetNumber,EndingSetNumber
	variable i=0
	Variable j=0
	variable k=0
	Variable LeftPos=20					// variables for positioning graph windows for this module
	Variable TopPos=60
	Variable Graph_Height=140
	variable Graph_Width = 200
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
	SVAR Voltage_Signal =  root:IVRelation:Voltage_Signal	// string to be matched to find voltage channel
	SVAR current_Signal=  root:IVRelation:current_Signal	// string to be matched to find current channel
	SVAR Output_Signal =  root:IVRelation:Output_Signal			// string to be matched to find DAC output to drive current step 
	SVAR StimOutputSignal=  root:IVRelation:StimOutput_Signal
	//
	SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
	If(stringmatch(NowMulticlampMode, "I-Clamp"))
			SetDataFolder root:
			Abort "Use Multiclamp Commander to ensure mode is set to  ' V-Clamp' and update NIDAQ Switchboard"
	endif
	//
	NVAR UseEvokStimCheck 	=	root:IVRelation:IV_UseEvokStimcheck
	//print "3) Loaded SVAR & NVAR signals"
// Update Telegraphs:  verify I-clamp, update scaled output gain, write to notebook the readouts
//	If(stringmatch(Current_signal,"ScaledOutput"))
//		//	Execute "UpdateTelegraphs()"
//		print "getting TG globals"
//		NVAR Current_TG_Gain	=	root:NIDAQBoardVar:Current_TG_Gain		
//		SVAR  Current_TG_Mode=	root:NIDAQBoardVar:Current_TG_Mode
//		SVAR Current_ScaledOutType=root:NIDAQBoardVar:Current_ScaledOutType
//		NVAR Current_TG_Filter	=root:NIDAQBoardVar:Current_TG_Filter
//		NVAR current_TG_Capac	=root:NIDAQBoardVar:current_TG_Capac			
//		if(   stringmatch(Current_ScaledOutType,"Voltage")  )
//			SetDataFolder root:
//			Abort "Axopatch Amplifier must be set in' V-Clamp' '"
//		endif
//	else
//		if(stringmatch(Current_signal,"AxCl_10vm"))
//			if(   !stringmatch(Current_AxClMode,"Vclamp") )
//				SetDataFolder root:
//				Abort "Axoclamp amplifier must be set in' V-Clamp' "
//			endif
//		endif
//	endif
// determine correct channel #s for Scaled out (voltage), I output
	Print "Getting Nidaq ADC/DAC globals"
	NVAR AcqResolution=  root:DataAcquisitionVar:AcqResolution
	WAVE ADC_ChannelWave			=root:NIDAQBoardVar:ADC_ChannelWave
	WAVE ADC_SignalWave				=root:NIDAQBoardVar:ADC_SignalWave
	WAVE ADC_IndBoardGainWave		=root:NIDAQBoardVar:ADC_IndBoardGainWave
	WAVE ADC_AmpGainWave			=root:NIDAQBoardVar:ADC_AmpGainWave
	WAVE DAC_SignalWave				=root:NIDAQBoardVar:DAC_SignalWave
	WAVE DAC_Channel_Wave			=root:NIDAQBoardVar:DAC_Channel_Wave
	WAVE DAC_AmpGain_VCl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_VCl_Wave
	
	// Check Evok stimulus control info
	SVAR EvokStimWaveName=  root:IVRelation:IV_EvokStimWaveName
	NVAR UseEvokStimCheck =  root:IVRelation:IV_UseEvokStimCheck
	NVAR BeforeAfterBuff =  root:IVRelation:IV_BeforeAfterBuff
	//BeforeAfterBuff=0.400
	controlinfo  /W=IV_ControlPanel StimOutCheck
	UseEvokStimCheck=V_Value	
	controlinfo /W=IV_ControlPanel ChooseEvokStimWavePopup
	EvokStimWaveName=S_value
	print "Using evoked stimulus Wave:  " + EvokStimWaveName
	if(stringmatch(EvokStimWaveName,"none"))
		UseEvokStimCheck=0
	endif

// find  channels;determine current amplifier gains for output & input waves;determine individual board gains for input waves
	print "determining channels & gains"
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
	DAC_out_AmpGain=DAC_AmpGain_VCl_Wave[DAC_out_Channel]
	

	
	//print "4) completed channels and gains"
	//////////////////////////////////////////////////////////////



	Make/N=4/O IV_rawDataDisplay_pos,IV_AvgWaveDisplay_pos,IV_RatevsCurrDisplay_pos,IV_OutputWaves_pos,IV_VoltvsCurrDisplay_pos
	IV_rawDataDisplay_pos={LeftPos,TopPos,LeftPos+graph_Width,TopPos+2*Graph_Height}		// graph in top left
	IV_OutputWaves_pos={LeftPos,TopPos+2*Graph_Height+Graph_Grout_vert,LeftPos+graph_Width,TopPos+2.5*Graph_Height+Graph_Grout_vert}	// graph bottom left
	IV_AvgWaveDisplay_pos={LeftPos+graph_width+Graph_grout,TopPos,LeftPos+2*graph_Width+Graph_Grout,TopPos+2*Graph_Height}	// graph top right
	IV_VoltvsCurrDisplay_pos={LeftPos+2*graph_width+2*Graph_grout,TopPos,LeftPos+3.5*graph_Width+2*Graph_Grout,TopPos+1.5*Graph_Height+Graph_Grout_vert}//graph bottom right

// write panel parameters to notebook
// all the panel variables:
	//print "Getting  IV panel parameters"
	NVAR IV_PrePulseStepAmplitude	=root:IVRelation:IV_PrePulseStepAmplitude
	NVAR IV_StepLength				=root:IVRelation:IV_StepLength			// in sec
	NVAR IV_NegMostStep			=root:IVRelation:IV_NegMostStep		//in nA
	NVAR IV_PosMostStep			=root:IVRelation:IV_PosMostStep
	NVAR IV_NumberSteps			=root:IVRelation:IV_NumberSteps
	NVAR IV_CurrentPerStep			=root:IVRelation:IV_CurrentPerStep		// in nA
	NVAR IV_ISI						=root:IVRelation:IV_ISI					// in sec
	NVAR IV_RepeatCheck			=root:IVRelation:IV_RepeatCheck
	NVAR IV_NumRepeats			=root:IVRelation:IV_NumRepeats
	NVAR IV_SetNum				=root:IVRelation:IV_SetNum
	SVAR IV_Basename				=root:IVRelation:IV_Basename
	SVAR Basename					=root:DataAcquisitionVar:baseName
	String Local_Basename			=	"IV_" +baseName + "s" + num2str(IV_SetNum)	// recalculate a local basename
	NVAR IV_AverageCheck			=root:IVRelation:IV_AverageCheck
	NVAR IV_nextAvg				=root:IVRelation:IV_nextAvg
	SVAR IV_AvgBasename			=root:IVRelation:IV_AvgBasename
	NVAR IV_CalcFICheck			=root:IVRelation:IV_CalcFICheck
	NVAR IV_SpikeThresh			=root:IVRelation:IV_Spikethresh
	NVAR IV_PlotIVCurveCheck1		=root:IVRelation:IV_PlotIVCurveCheck1
	NVAR IV_IVMeasure_t1			=root:IVRelation:IV_IVMeasure_t1
	NVAR IV_PlotIVCurveCheck2		=root:IVRelation:IV_PlotIVCurveCheck2
	NVAR IV_IVMeasure_t2			=root:IVRelation:IV_IVMeasure_t2
	NVAR IV_Plot_t2minust1			=root:IVRelation:IV_Plot_t2minust1
	//variable IV_Plot_t2minust1=1
	
	NVAR IV_AvgWindow				=root:IVRelation:IV_MeasAvgWindow
	
	NVAR DataDisplay_x1	=	root:IVRelation:DataDisplay_x1
	NVAR DataDisplay_x2	=	root:IVRelation:DataDisplay_x2
	NVAR DataDisplay_y1	=	root:IVRelation:DataDisplay_y1
	NVAR DataDisplay_y2	=	root:IVRelation:DataDisplay_y2
	//SetAxis bottom dataDisplay_x1,dataDisplay_x2
	//variable IV_AvgWindow	=0.010		// sec, window over which to average voltage measurement for VI curve
	Variable totalWavePoints = AcqResolution * (3*BeforeAfterBuff + IV_StepLength)
	string TextStamp = IV_basename
	if(UseEvokStimCheck)
		// save stim wave as a local wave, annoted to belong to this set of  IV curves:
		string EvokStimOutName = Local_Basename + "stim"		// unique to this set
		WAVE /Z EvokStimWave=root:$EvokStimWaveName
		if( !waveexists(EvokStimWave))
			SetDataFolder root:
			abort "No Wave " + evokStimWaveName + " exists (check folders)"
		else
			Duplicate/O  EvokStimWave, $EvokStimOutName		// duplicate the stim wave to modify for our use here (see below)
			//print "Chosen Stimulus wave is " + EvokStimWaveName
		endif

		if( numpnts($EvokStimOutName)== totalWavePoints)
			// "looks ok"
		else
			if( numpnts($EvokStimOutName)> totalWavePoints )
				totalWavePoints=numpnts($EvokStimOutName)
			else
				insertpoints numpnts($EvokStimOutName),((totalwavepoints)-numpnts($EvokStimOutName)),  $EvokStimOutName
				//print "Enlarging the stimulus wave " + EvokStimOutName + " by " + num2str(((totalwavepoints)-numpnts($EvokStimOutName))) + "points"
				//abort "# of points in " + EvokStimWaveName + " ( " + num2str(numpnts(EvokStimWave)) + ") must equal acquisition waves # points (" + num2str(totalWavePoints) + ")"
			endif
		endif
		///  Show the Stimulus wave:
		DoWindow/K EvokStimDisplay
		display/W=(IV_OutputWaves_pos[0],IV_OutputWaves_pos[3]+20,IV_OutputWaves_pos[2],IV_OutputWaves_pos[3]+120)  $EvokStimOutName  as "Evoked Stimulus Output waveform"
		legend
		Dowindow/C EvokStimDisplay
	endif 
	StartingSetNumber=IV_SetNum
// Write to notebook channels & gains
	Notebook Parameter_Log ruler=Title, text="\r\rStarting IV Data Acquisition" +"\r"
	Notebook Parameter_Log ruler=Normal, text ="\t" +Date() + "  " + time() + "\r\r"
	Notebook Parameter_Log ruler=normal, text="\r\tAcquisition Resolution (samples/sec) :\t" + num2str(AcqResolution)
	Notebook Parameter_Log ruler=normal, text="\r\tVoltage signal : \t"  + Voltage_Signal  +" on channel " +num2str(Voltage_Channel)
	Notebook Parameter_Log ruler=normal, text="\r\tVoltage signal amplifier gain : " + num2str(Voltage_ampGain) + "\t and board gain : " + num2str(Voltage_IndBoardGain)
	Notebook Parameter_Log ruler =normal, text="\r\tCurrent signal : \t"  + current_Signal+" on channel " +num2str(current_Channel)
	Notebook Parameter_Log ruler =normal, text="\r\tCurrent  signal amplifier gain : " + num2str(Current_ampGain)+ "\t and board gain : " + num2str(Current_IndBoardGain)
	Notebook Parameter_Log ruler =normal, text="\r\tOutput to:  \t"  + Output_Signal+" on channel " +num2str(DAC_out_Channel)
	Notebook Parameter_Log ruler =normal, text="\r\tOutput amplifier gain : \t" + num2str(DAC_out_AmpGain)
	if(UseEvokStimCheck)
		Notebook Parameter_Log ruler =normal, text="\r\tUsing template stimulus wave: \t" +EvokStimWaveName
		Notebook Parameter_Log ruler =normal, text="\r\tSaving actual stimulus wave for this set: \t" +EvokStimOutName
	endif
	Notebook Parameter_Log ruler =normal, text="\r\tBasename for acquired waves: \t" +Local_Basename
	if(IV_AverageCheck)
		Notebook Parameter_Log ruler =normal, text="\r\tAveraging across repeats of sets:  named:\t"   + IV_AvgBasename
	endif
	Notebook Parameter_Log ruler =normal, text="\r\tNegative most step level (V): \t" + num2str(IV_NegMostStep)
	Notebook Parameter_Log ruler =normal, text="\r\tPositive most step level (V): \t" +num2str(IV_PosMostStep)
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of steps per set: \t" +num2str(IV_NumberSteps)
	Notebook Parameter_Log ruler =normal, text="\r\tVoltage per step (V): \t" +num2str(IV_CurrentPerStep)
	Notebook Parameter_Log ruler =normal, text="\r\tPrepulse step amplitude (V): \t" +num2str(IV_PrePulseStepAmplitude)
	Notebook Parameter_Log ruler =normal, text="\r\tStep Length (sec): \t" + num2str(IV_StepLength)
	Notebook Parameter_Log ruler =normal, text="\r\tTotal Wave Length (sec): \t" + num2str(IV_StepLength + 3*BeforeAfterBuff)	
	Notebook Parameter_Log ruler =normal, text="\r\tInter-stimulus interval (sec):\t" +num2str(IV_ISI)
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of times to repeat: \t" +num2str(IV_NumRepeats) 
	Notebook Parameter_Log ruler =normal, text="\r\tAnalysis of Current at time t1: \t "+num2str(IV_IVMeasure_t1)
	if( IV_PlotIVCurveCheck2)
		Notebook Parameter_Log ruler =normal, text="\r\tAnalysis of Current at time t2: \t "+num2str(IV_IVMeasure_t2)
	endif
	if( IV_Plot_t2minust1)
		Notebook Parameter_Log ruler =normal, text="\r\tAnalysis of difference t2-t1: \t "
	endif
	Notebook Parameter_Log ruler =normal, text="\r\tAnalysis of Current averaging window (s): \t "+num2str(IV_AvgWindow) + "\r"
	
	
// OUTPUT WAVE CREATION:  create once, reuse each iteration.
	variable PrePrestep = 0.2		// time before prestep; default used to be 0.01 (10ms)
	print "Creating output waves"
	if(IV_ISI <= (2*BeforeAfterBuff + IV_StepLength +0.200))	// check that ISI is long enough (200ms extra room)	
		SetDataFolder root:
		Abort "ISI must be longer than "  + num2str((2*BeforeAfterBuff + IV_StepLength +0.200))
	endif
	Make/T/N=(IV_NumberSteps)/O OutNames_Wave, VoltageAcqNames_Wave, currentAcqNames_Wave
	Make/N=(IV_NumberSteps)/O VoltStepLevelWave_calculated
	Make /N=( totalWavePoints)/O tempwave0
	SetScale /P x 0, (1/AcqResolution), "sec",  tempwave0
	tempwave0=0
	DoWindow /K IV_OutputWaves
	Display /W=(IV_OutputWaves_pos[0],IV_OutputWaves_pos[1],IV_OutputWaves_pos[2],IV_OutputWaves_pos[3]) as "IV Output Waves"
	DoWindow /C IV_OutputWaves
	print "DAC_outGain  "  +  num2str(DAC_out_AmpGain)
	do
		tempwave0=0
		VoltStepLevelWave_calculated[i]=(IV_NegMostStep+ i*IV_currentPerStep)
		tempwave0[x2pnt(tempwave0,PrePrestep),x2pnt(tempwave0,BeforeAfterBuff)-1]=IV_PrePulseStepAmplitude   // insert pre-step
		tempwave0[x2pnt(tempwave0,BeforeAfterBuff),x2pnt(tempwave0,(BeforeAfterBuff+IV_StepLength))]=(IV_NegMostStep+ i*IV_currentPerStep)
		tempWave0/=DAC_out_AmpGain		//  gain nA/V
		//tempWave0*=2
		OutNames_Wave[i]="IV_OutputWave_" + num2str(i)
		Duplicate /O tempWave0, $OutNames_Wave[i]
		AppendToGraph $OutNames_Wave[i]		
		i+=1
	while(i<IV_NumberSteps)

// REAL TIME ANALYSES:
/// check if to average raw waves themselves, if so create average wave:  Create Window to plot it
	ControlInfo /W=IV_ControlPanel AvgCheck
	IV_AverageCheck=V_value
	//print "IV_averagecheck is" , num2str(IV_AverageCheck)
	DoWindow/K IV_AvgWaveDisplay;DoWindow/K IV_AvgVoltWaveDisplay
	if(IV_AverageCheck)
		print "setting up for averaging of waves across sets"
		string AvWave_VoltName,AvWave_CurrName
		Make/O/N=(IV_NumberSteps)/T tempWavesName_1,tempWavesName_2,tempWavesName_3,tempWavesName_4
		tempwave0=0
		i=0
		do
			tempWavesName_1[i]="temp_Volt_sum_" + num2str(i)
			tempWavesName_2[i]="temp_Curr_sum_" + num2str(i)
			tempWavesName_3[i]=IV_AvgBasename + "_V"	+num2str(i)
			tempWavesName_4[i]=IV_AvgBasename + "_A"+num2str(i)	
			
			Duplicate /O tempWave0, $tempWavesName_1[i],$tempWavesName_2[i],$tempWavesName_3[i],$tempWavesName_4[i]	
			if(i==0)
				dowindow/K IV_AvgVoltWaveDisplay
				Display /W=(IV_AvgWaveDisplay_pos[0],IV_AvgWaveDisplay_pos[1],IV_AvgWaveDisplay_pos[2],IV_AvgWaveDisplay_pos[3]) $tempWavesName_4[i] as "IV Average Acquired Waves"	
				doWindow /C IV_AvgWaveDisplay
				Label left "Current (nA)"
				Label bottom "Time (sec)"
				Display /W=(IV_AvgWaveDisplay_pos[0],IV_AvgWaveDisplay_pos[1],IV_AvgWaveDisplay_pos[2],IV_AvgWaveDisplay_pos[3]) $tempWavesName_3[i] as "IV Avg Voltage Wave Acquired"
				dowindow/C IV_AvgVoltWaveDisplay
				Label left "Voltage (V)"
				Label bottom "Time (sec)"
			else
				appendtograph/W=IV_AvgWaveDisplay  $tempWavesName_4[i]		// show current wave
				appendtograph/W=IV_AvgVoltWaveDisplay $tempWavesName_3[i]
			endif	
			i+=1
		while(i<IV_NumberSteps)
		//ModifyGraph axisEnab(L2)={0,.4},freePos(L2)=0, axisEnab(left)={0,0.35}		
		//Modifygraph  lblPos(left)=40, lblPos(L2)=40	// positions the label of left axes properly
		DoUpdate
	endif
		

//  ANALYSIS: create names for voltage level waves;
//if numRepeats> 2, create waves for average&sd.
// Create Window to plot it.

	print "Setting up for IV curve analysis"
	Make/T/O/N=(IV_NumRepeats)VoltLevWave_Names, IVCurve1Wave_Names
	VoltLevWave_Names[0]=Local_Basename + "_VoltLev"
	IVCurve1Wave_Names[0]=Local_Basename + "_I1Lev"
	Make/O/N=(IV_NumberSteps) $VoltLevWave_Names[0],$IVCurve1Wave_Names[0]
	if( IV_PlotIVCurveCheck2)
		Make/T/O/N=(IV_NumRepeats) IVcurve2Wave_Names
		IVcurve2Wave_Names[0]=Local_Basename + "_I2Lev"
		Make/O/N=(IV_NumberSteps) 	$IVcurve2Wave_Names[0]	
		if(IV_Plot_t2minust1)
			Make/T/O/N=(IV_NumRepeats) IV_deltaCurrWave_Names
			IV_deltaCurrWave_Names[0]=Local_Basename + "_deltaCurr"
			Make/O/N=(IV_NumberSteps) 	$IV_deltaCurrWave_Names[0]	
		endif
		
	endif
	
	
	
	DoUpdate
	// make temporary avg_xaxis
	WAVE temp_VoltLevels = $VoltLevWave_Names[0]
	temp_VoltLevels=0
		
	if(IV_NumRepeats>1)	
		string Name_VoltLevWaveAvg,Name_voltLevWaveSD,Name_I1LevAvg,Name_I1LevSD
		Name_VoltLevWaveAvg=Local_Basename +"_VoltLevAvg"
		Name_voltLevWaveSD=Local_Basename +"_VoltLevSD"
		Name_I1LevAvg=Local_Basename +"I1LevAvg"
		Name_I1LevSD=Local_Basename +"I1LevSD"
		Make /O/N=(IV_NumberSteps) $Name_VoltLevWaveAvg,$Name_VoltLevWaveSD,$Name_I1LevAvg,$Name_I1LevSD
		if( IV_PlotIVCurveCheck2)
			string Name_I2LevAvg,Name_I2LevSD
			Name_I2LevAvg=Local_Basename +"I2LevAvg"
			Name_I2LevSD=Local_Basename +"I2LevSD"
			Make /O/N=(IV_NumberSteps) $Name_I2LevAvg  ,  $Name_I2LevSD
			if(IV_Plot_t2minust1)
				string Name_deltaCurrAvg,Name_deltaCurrSD
				Name_deltaCurrAvg=Local_Basename +"deltaCurrAvg"
				Name_deltaCurrSD=Local_Basename +"deltaCurrSD"
				Make /O/N=(IV_NumberSteps) $Name_deltaCurrAvg  ,  $Name_deltaCurrSD
			endif
		endif
		WAVE temp_VoltLevelsAvg = $Name_VoltLevWaveAvg
		temp_VoltLevelsAvg=0	// temporary, will be overwritten later	
	endif
	//if(IV_PlotIVCurveCheck1)
	DoWindow/K IV_IVCurveDisplay
	Display /W=(IV_VoltvsCurrDisplay_pos[0],IV_VoltvsCurrDisplay_pos[1],IV_VoltvsCurrDisplay_pos[2],IV_VoltvsCurrDisplay_pos[3]) $IVCurve1Wave_Names[0] vs $VoltLevWave_Names[0] as "Current vs Voltage"	
	DoWindow/C IV_IVCurveDisplay
	Label left "\Z09Current (nA) \K(0,0,65500)t1, \K(0,65500,0)t2"
	Label bottom  "Voltage level (V)"
	Modifygraph  lblPos(left)=40,live=1
	Modifygraph lstyle($IVCurve1Wave_Names[0])=7,mode($IVCurve1Wave_Names[0])=4,marker($IVCurve1Wave_Names[0]) =5,rgb($IVCurve1Wave_Names[0])  =  (0,0,65500)
	//endif
	if(IV_PlotIVCurveCheck2)
		DoWindow/F IV_IVCurveDisplay
		Appendtograph  $IVcurve2Wave_Names[0] vs $VoltLevWave_Names[0]
		print IVcurve2Wave_Names[0]
		Modifygraph lstyle($IVcurve2Wave_Names[0])=6,mode($IVcurve2Wave_Names[0])=4,marker($IVcurve2Wave_Names[0]) = 6,rgb($IVcurve2Wave_Names[0])  =  (0,65500,0)
		if(IV_Plot_t2minust1)
			Appendtograph/R  $IV_deltaCurrWave_Names[0] vs $VoltLevWave_Names[0]
			print IV_deltaCurrWave_Names[0]
			Modifygraph lstyle($IV_deltaCurrWave_Names[0])=8,mode($IV_deltaCurrWave_Names[0])=4,marker($IV_deltaCurrWave_Names[0]) = 8,rgb($IV_deltaCurrWave_Names[0])  =  (65500,0,0)
			label right "\K(65500,0,0)\Z09Delta Current, t2-t1 (nA)"
			Modifygraph zero(right)=1,zero(bottom)=1
		endif

	endif
	if(IV_NumRepeats>1)	
		DoWindow /F IV_IVCurveDisplay 
		AppendToGraph $Name_I1LevAvg vs  $Name_VoltLevWaveAvg
		ModifyGraph lsize($Name_I1LevAvg)=2,mode($Name_I1LevAvg)=4, marker($Name_I1LevAvg) =16,rgb($Name_I1LevAvg)  =  (0,0,65500)
		if(IV_PlotIVCurveCheck2)
			AppendToGraph $Name_I2LevAvg vs   $Name_VoltLevWaveAvg
			ModifyGraph lsize($Name_I2LevAvg)=2,mode($Name_I2LevAvg)=4, marker($Name_I2LevAvg) =17,rgb($Name_I2LevAvg) = (0,65500,0)
			if(IV_Plot_t2minust1)
				AppendToGraph/R $Name_deltaCurrAvg vs   $Name_VoltLevWaveAvg
				ModifyGraph lsize($Name_deltaCurrAvg)=2,mode($Name_deltaCurrAvg)=4, marker($Name_deltaCurrAvg) =17,rgb($Name_deltaCurrAvg) = (65500,0,0)
			endif
		endif
	endif
		
	
/////////////////////////////	
	tempwave0=0
	k=0			// loop variable for number of repeats
	do												// loop for each Set Iteration
		print "Beginning set iteration number:", num2str(k)
		// create waves for acquiring current & voltage data; create at beginning of each iteration & step Loop
		//print Local_Basename
	
		if(k>0)
			VoltLevWave_Names[k]=Local_Basename + "_VoltLev"
			IVCurve1Wave_Names[k]=Local_Basename + "_I1Lev"
			Make/O/N=(IV_NumberSteps) $VoltLevWave_Names[k],$IVCurve1Wave_Names[k]
			Appendtograph /W=IV_IVCurveDisplay $IVCurve1Wave_Names[k] vs $VoltLevWave_Names[k]
			Modifygraph  /W=IV_IVCurveDisplay lstyle($IVCurve1Wave_Names[k])=7,mode($IVCurve1Wave_Names[k])=4,marker($IVCurve1Wave_Names[k]) =5,rgb($IVCurve1Wave_Names[k])  =  (0,0,65500)
			if(IV_PlotIVCurveCheck2)
				IVcurve2Wave_Names[k]=Local_Basename + "_I2Lev"
				Make/O/N=(IV_NumberSteps) $IVcurve2Wave_Names[k]
				Appendtograph /W=IV_IVCurveDisplay $IVcurve2Wave_Names[k] vs $VoltLevWave_Names[k]
				Modifygraph /W=IV_IVCurveDisplay lstyle($IVcurve2Wave_Names[k])=6,mode($IVcurve2Wave_Names[k])=4,marker($IVcurve2Wave_Names[k]) = 6,rgb($IVcurve2Wave_Names[k])  =  (0,65500,0)
				if(IV_Plot_t2minust1)					
					IV_deltaCurrWave_Names[k]=Local_Basename + "_deltaCurr"
					Make/O/N=(IV_NumberSteps) $IV_deltaCurrWave_Names[k]
					print "   *********", IV_deltaCurrWave_Names[k]
					Appendtograph /W=IV_IVCurveDisplay/R  $IV_deltaCurrWave_Names[k] vs $VoltLevWave_Names[k]
					Modifygraph lstyle($IV_deltaCurrWave_Names[k])=8,mode($IV_deltaCurrWave_Names[k])=4,marker($IV_deltaCurrWave_Names[k]) = 8,rgb($IV_deltaCurrWave_Names[k])  =  (65500,0,0)
				endif
			endif
		endif			
		WAVE temp_VoltLev= $VoltLevWave_Names[k]
		WAVE temp_I1Lev = $IVCurve1Wave_Names[k]
		if( IV_PlotIVCurveCheck2)
			WAVE temp_I2Lev = $IVcurve2Wave_Names[k]
			if(IV_Plot_t2minust1)
				WAVE temp_deltaCurr = $IV_deltaCurrWave_Names[k]	
			endif
		endif
			
		if(  (Waveexists(temp_VoltLev)==0) )
			print " temp_VoltLev does not exist"
		endif
	
		j=0
		do
			VoltageAcqNames_Wave[j]=Local_Basename + "_V" + num2str(j)		
			currentAcqNames_Wave[j]=Local_Basename + "_A" + num2str(j)
			duplicate /O tempwave0, $VoltageAcqNames_Wave[j]
			duplicate /O tempwave0, $currentAcqNames_Wave[j]
			j+=1
		while(j<IV_NumberSteps)		// creates entire set of names at once for each set
		//  create window for real-time raw data display:
		DoWindow/K IV_rawDataDisplay	
		Display /W=(IV_rawDataDisplay_pos[0],IV_rawDataDisplay_pos[1],IV_rawDataDisplay_pos[2],IV_rawDataDisplay_pos[3]) $currentAcqNames_Wave[0] as "IV Raw Acquired Waves"
		//AppendToGraph /L=left $CurrentAcqNames_Wave[0]
		//ModifyGraph axisEnab(L2)={0.4,1},freePos(L2)=0, axisEnab(left)={0,0.35}
		//Label left "Voltage (V)"
		Label left "Current (nA)"
		Label bottom "Time (sec)"
		SetAxis bottom dataDisplay_x1,dataDisplay_x2
		//Modifygraph  lblPos(left)=40, lblPos(L2)=40,live=1		// positions the label of left axes properly
		doWindow /C IV_rawDataDisplay
		// Make variables to acquire a temperature measure, once at the beginning of each set.  
		variable TempGain = 0.1	// gain on the T2 output is 100mV/degC
		variable CurrentTempDegC
		string TempAcqString = "TemperatureGrabWave,2"
		Make /O/N=100 TemperatureGrabWave
		SetScale /P x 0, (1/AcqResolution), "sec",  TemperatureGrabWave
		mysimpleAcqRoutine("",TempAcqString)
		TemperatureGrabWave/=TempGain
		CurrentTempDegC=mean(TemperatureGrabWave,-inf,inf)
		Notebook Parameter_Log ruler =normal, text="\r\t  Recording chamber temperature (T2) : \t" + num2str(CurrentTempDegC) + " degrees C"
		///
		DoUpdate	
		j=0
		do											// current Step loop
			StartTicks=ticks
			//print "Beginning step loop ", num2str(j)
			// send waves to nidaq
			AcqString=currentAcqNames_Wave[j]+"," +num2str(Current_Channel) 
			AcqString+=";" +VoltageAcqNames_Wave[j]+"," +num2str(Voltage_Channel)     
			
			WFOutString=OutNames_Wave[j] + "," + num2str(DAC_Out_Channel)
			if(UseEvokStimCheck)
				WFOutString+= ";" + EvokStimOutName +"," +  num2str(EvokStimOut_Channel)
				print wfoutstring
			endif
			mySimpleAcqRoutine(WFOutString,AcqString)
			// condition acquired waves according to amplifier gains
			
			Wave VoltAcqWave=$VoltageAcqNames_Wave[j]
			Wave CurrAcqWave=$currentAcqNames_Wave[j]
			if( (Waveexists(VoltAcqWave)==0)  ||  (Waveexists(CurrAcqWave)==0) )
				print "VoltAcqWave or CurrAcqWave does not exist"
			endif
			VoltAcqWave/=Voltage_AmpGain	
			CurrAcqWave/=Current_AmpGain
			// save waves to hard drive
			CommandStr = "Save/O/C/P=IVPath " +VoltageAcqNames_Wave[j] +","+currentAcqNames_Wave[j]
			Execute CommandStr							// Quick! Before the computer crashes!!!
			if(j==0)
				Dowindow/K VoltageStepDisplay
				Display /W=(IV_OutputWaves_pos[0],IV_OutputWaves_pos[1],IV_OutputWaves_pos[2],IV_OutputWaves_pos[3])  VoltAcqWave as "Acquired voltage"
				Dowindow/C VoltageStepDisplay
			else
				appendtograph /w=VoltageStepDisplay VoltAcqWave
			endif
			
		
			if(i>1)
				// display  raw voltage & current data		-->> FI raw data window
				DoWindow/F IV_rawDataDisplay
				appendtoGraph $currentAcqNames_Wave[j]
				//appendtoGraph /L=L2 $VoltageAcqNames_Wave[j]
				DoUpdate
			endif
			//REAL TIME ANALYSIS: AVERAGING voltage and current traces across set repeats:
			if(IV_AverageCheck)	
				WAVE Sum_Volt=$tempWavesName_1[j]
				WAVE Sum_Curr=$tempWavesName_2[j]
				WAVE Avg_Volt	= $tempwavesName_3[j]
				WAVE Avg_Curr=$tempwavesName_4[j]
				if( (Waveexists(Sum_Volt)==0)  ||  (Waveexists(Sum_Curr)==0) || (Waveexists(Avg_Volt)==0)  ||  (Waveexists(Avg_Curr)==0))
					print "Sum_Volt or Sum_Curr or Avg_Volt or Avg_Currdoes not exist"
				endif			
				Sum_Volt+=VoltAcqWave
				Sum_Curr+=CurrAcqWave
				Avg_Volt=Sum_volt/(k+1)		// k+1 should be number of sets;  provides running average
				Avg_Curr=Sum_Curr/(k+1)
				DoWindow/F IV_AvgWaveDisplay
				SetAxis bottom dataDisplay_x1,dataDisplay_x2
				Setaxis left dataDisplay_y1,dataDisplay_y2
				ModifyGraph live=1
			endif
			//REAL TIME ANALYSIS:	
			temp_VoltLev[j] = mean(VoltAcqWave,BeforeAfterBuff+0.05,(BeforeAfterBuff+IV_StepLength-0.05))  // real voltage step (measured)
			//temp_VoltLev[j] -= mean(VoltAcqWave,0.001,(BeforeAfterBuff-0.005))  // subtract baseline
			print temp_VoltLev[j]
			//temp_CurrLev[j] = mean(CurrAcqWave,BeforeAfterBuff+0.003,(BeforeAfterBuff+IV_StepLength))	// current level for this step, discounting the rise time of ~3ms
			temp_I1Lev[j] = mean(CurrAcqWave,BeforeAfterBuff+IV_IVMeasure_t1 , BeforeAfterBuff+IV_IVMeasure_t1 + IV_AvgWindow)- mean(CurrAcqWave, 0.001 ,  BeforeAfterBuff-0.005)
			if( IV_PlotIVCurveCheck2)
				temp_I2lev[j] = mean(CurrAcqWave,BeforeAfterBuff+IV_IVMeasure_t2 , BeforeAfterBuff+IV_IVMeasure_t2 + IV_AvgWindow)- mean(CurrAcqWave, 0.001 ,  BeforeAfterBuff-0.005)
				if(IV_Plot_t2minust1)
					temp_deltaCurr[j] = temp_I2lev[j]  -   temp_I1lev[j]
				endif

			endif
			do									//waste time between runs according to ISI
				elapsedTicks=ticks-StartTicks
			while((elapsedTicks/60.15)<IV_ISI)		
			j+=1
		while(j<IV_numberSteps)
		
		// Save per set analysis waves:
		CommandStr = "Save/O/C/P=IVPath "+VoltLevWave_Names[k] + "," + IVCurve1Wave_Names[k]    // Save the acquired wave in the home path right away!
		Execute CommandStr
		if( IV_PlotIVCurveCheck2)
			CommandStr = "Save/O/C/P=IVPath "+ IVCurve2Wave_Names[k]   // Save the acquired wave in the home path right away!
			Execute CommandStr
			if(IV_Plot_t2minust1)
				CommandStr = "Save/O/C/P=IVPath "+ IV_deltaCurrWave_Names[k]   // Save the acquired wave in the home path right away!
				Execute CommandStr
			endif
		endif
		/////	

		Notebook  Parameter_Log ruler =normal, text="\r\rCompleted Set#" + num2str(IV_SetNum)
		Notebook  Parameter_Log ruler =normal, text="\r\tAcquired voltage traces:\t" +VoltageAcqNames_Wave[0] +"-" + num2str(IV_Numbersteps-1)
		Notebook  Parameter_Log ruler =normal, text="\r\tAcquired actual current traces:\t" + currentAcqNames_Wave[0]+ "-" + num2str(IV_Numbersteps-1)
	
		IV_SetNum+=1			// update set#
		Local_Basename			=	"IV_" +baseName + "s" + num2str(IV_SetNum)	// recalculate basename
		k+=1	
	while(k<IV_numRepeats)	
	print "completed Set repeats"
	EndingSetNumber=StartingSetNumber+k
	// END OF SET ANALYSIS FOR FI CURVE:    average spikes & current levels & plot mean +- s.d. -->>  
	
	if(IV_NumRepeats>1)
		string VLev_list=convertTextWavetoList(VoltLevWave_Names)
		string I1Lev_list=convertTextWavetoList(IVCurve1Wave_Names)
		variable errortype=1			// 1=sd; 2=conf int; 3=se; 0=none)
		variable errorinterval=1		// # of sd's	
		fWaveAverage(VLev_list,errortype,errorinterval,Name_VoltLevWaveAvg,Name_VoltLevWaveSD)
		fWaveAverage(I1Lev_list,errortype,errorinterval,Name_I1LevAvg,Name_I1LevSD)
		Dowindow/F IV_IVCurveDisplay
		ErrorBars /W=IV_IVCurveDisplay   $Name_I1LevAvg, y wave=($Name_I1LevSD ,)
		Notebook  Parameter_Log ruler =normal, text="\r\tAverages of voltage steps:\t" +Name_VoltLevWaveAvg + "+/-" + Name_VoltLevWaveSD
		Notebook  Parameter_Log ruler =normal, text="\r\tAverages of Current Response, I1:\t" +Name_I1LevAvg + "+/-" + Name_I1LevSD
		CommandStr = "Save/O/C/P=IVPath "+Name_VoltLevWaveAvg +","+Name_VoltLevWaveSD +","+Name_I1LevAvg +","+Name_I1LevSD
		Execute commandStr
		if( IV_PlotIVCurveCheck2)
			string I2Lev_list=convertTextWavetoList(IVCurve2Wave_Names)
			fWaveAverage(I2Lev_list,errortype,errorinterval,Name_I2LevAvg,Name_I2LevSD)
			ErrorBars /W=IV_IVCurveDisplay   $Name_I2LevAvg, y wave=($Name_I2LevSD ,)
			Notebook  Parameter_Log ruler =normal, text="\r\tAverages of Current Response, I2:\t" +Name_I2LevAvg + "+/-" + Name_I2LevSD
			CommandStr = "Save/O/C/P=IVPath "+Name_I2LevAvg +","+Name_I2LevSD
			Execute commandStr
			if(IV_Plot_t2minust1)
				string deltaCurr_list=convertTextWavetoList(IV_deltaCurrWave_Names)
				fWaveAverage(deltaCurr_list,errortype,errorinterval,Name_deltaCurrAvg,Name_deltaCurrSD)
				ErrorBars /W=IV_IVCurveDisplay   $Name_deltaCurrAvg, y wave=($Name_deltaCurrSD,)
				Notebook  Parameter_Log ruler =normal, text="\r\tAverages of Delta Current Response:\t" +Name_deltaCurrAvg + "+/-" + Name_deltaCurrSD
				CommandStr = "Save/O/C/P=IVPath "+Name_deltaCurrAvg +","+Name_deltaCurrSD
				Execute commandStr

			
			endif
		endif
		DoWindow/K AveragesTable 
		//Edit VoltStepLevelWave_calculated,$Name_VoltLevWaveAvg,$Name_VoltLevWaveSD,$Name_I1LevAvg,$Name_I1LevSD,$Name_I2LevAvg,$Name_I2LevSD
		Dowindow/C AveragesTable
	endif

	// Save trace averages:
	if(IV_AverageCheck)
		i=0
		do
			CommandStr = "Save/O/C/P=IVPath "+tempwavesName_3[i] +","+tempwavesName_4[i]
			Execute commandStr
			i+=1
		while(i<IV_NumberSteps)
		Notebook  Parameter_Log ruler =normal, text="\r\rCalculated traces averages across set#" +num2str(StartingSetNumber) + "-" +num2str(IV_SetNum)
		Notebook  Parameter_Log ruler =normal, text="\r\tAverages of Voltage traces:\t" +tempwavesName_3[0] +"-"+ num2str(IV_numberSteps-1) 
		Notebook  Parameter_Log ruler =normal, text="\r\tAverages of current traces:\t" +tempwavesName_4[0] +"-"+ num2str(IV_numberSteps-1) 
		IV_nextAvg+=1							// update variable so not to overwrite previous averages
		IV_AvgBasename		=	"IV_" + baseName  +"_avg" +num2str(IV_nextAvg)	// update name
	endif
	// END OF MACRO CLEAN-UP:
	print "Cleaning up, Setting IV_Basename " + IV_Basename + " to Localbasename, " + Local_Basename 
	IV_Basename= Local_Basename			// update global FI basename
	//dowindow /K IV_outputWaves
	KillWaves/Z tempWave0				// kill output waves & all other temporary & non-essential waves
	i=0
	do
		//KillWaves/Z $OutNames_Wave[i]
		if(IV_AverageCheck)
			KillWaves/Z $tempWavesName_1[i]
			KillWaves/Z $tempWavesName_2[i]
		endif
		i+=1
	while(i<IV_NumberSteps)
	KillWaves/Z currentAcqNames_Wave,voltageAcqNames_Wave,OutNames_Wave,TemperatureGrabWave
	KillWaves/Z  tempWavesName_1,tempWavesName_2,tempWavesName_3,tempWavesName_4
	KillWaves /Z VoltLevWave_Names,FRWave_Names,W_FindLevels
	killWaves/Z IV_OutputWaves_pos,IV_RatevsCurrDisplay_pos,IV_AvgWaveDisplay_pos,IV_rawDataDisplay_pos
	Notebook  Parameter_Log ruler =normal, text="\r\r"
	Dowindow/K IV_Layout
	NewLayout /P=portrait /w=(80,40,400,450) as TextStamp
	variable LeftEdge=85
	variable topedge=85
	variable GraphWidth=450
	variable GraphHeight=100
	if(IV_numberSteps<2)
		Appendlayoutobject /T=1/F=0/R=(leftEdge,topEdge,leftEdge+graphWidth,topEdge+2.5*GraphHeight) graph IV_rawDataDisplay
	else
		Appendlayoutobject /T=1/F=0/R=(leftEdge,topEdge,leftEdge+graphWidth,topEdge+2.5*GraphHeight) graph IV_AvgWaveDisplay
	endif
	Appendlayoutobject /T=1/F=0/R=(leftEdge,topEdge+2.5*GraphHeight,leftEdge+graphWidth,topEdge+3.3*GraphHeight) graph IV_OutputWaves
	Appendlayoutobject /T=1/F=0/R=(leftEdge,topEdge+3.3*GraphHeight,leftEdge+graphWidth,topEdge+6*GraphHeight) graph IV_IVCurveDisplay
	Dowindow/C IV_Layout
	//Execute "StampExptDate() "
	TextBox/A=MT /E/F=0/A=MT/X=0.00/Y=0.00 TextStamp
	Dowindow/B IV_Layout
	Notebook Parameter_Log text="\rCompleted run:\tTime: "+Time()+"\r\r"
	Notebook  Parameter_Log ruler =normal, text="\r\r"	
	SetDataFolder root:			// return to root 
end		

function Kill_IV_windows()
	DoWindow/K IV_rawDataDisplay;DoWindow/K IV_AvgWaveDisplay
	DoWindow /K IV_OutputWaves;DoWindow/K IV_IVCurveDisplay
	DoWindow/K  IV_Layout;DoWindow/K EvokStimDisplay
	Dowindow/K VoltageStepDisplay;dowindow/K IV_AvgVoltWaveDisplay
	DoWindow/K AveragesTable 
end
	
