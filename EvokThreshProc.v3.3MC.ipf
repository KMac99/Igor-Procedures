#pragma rtGlobals=1		// Use modern global access method.

//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\kate analysis procs"
////EvThreshAcquire v.3.2MC.ipf
// updated to use multiclamp
///  Evoked PSC response data Acquisition.
// updated feb28,2012 to default to multiclamp amplifiers, nidaq-mx driver & Tools

// update 04/15/03  to accomodate two amplifiers & selection of signals.
// Requires WavesAverage Wavemetrics proc and WavetoList procs, but since these are already called 
// by NIDAQ routine, don't include them here.
// updated 2/29/03  to include calculating success rate/potency online and running IR 
////////////////////////////////////////////////

Menu "Initialize Procedures"
	"Initialize EvokThresh Acq Parameters",Init_EvokThresh_AcqControlPanel()
end

Menu "Kill Windows"
	"Kill EvokThresh Acq Graphs",Kill_EvThresh_windows()
end



Proc Init_EvokThresh_AcqControlPanel()
	// Check to see whether Globals Folder exists (i.e., that the InitializeDataAcquisition procedure 
	// has been run & common global variables exist
	if( DataFolderExists("root:DataAcquisitionVar"))	
		
		DoWindow/K EvThresh_rawDataDisplay
		DoWindow/K EvThresh_InpResDisplay
		DoWindow /K EvThresh_HoldCurrDisplay
		DoWindow /K EvThresh_VoltDisplay
		if( !DataFolderExists("root:EvokThresh"))
			String dfSave=GetDataFolder(1)	
			NewDataFolder /O/S root:EvokThresh		// Create folder forvariables
			KillWaves /a/z								// clean out folder & start from scratch
			killvariables /a/z		
			killstrings /a/z
			
			///  create variables for signal selection:
			//string/G Voltage_signal	=	 "PrimaryOutCh1"	
			string/G Input_signal	=	 "PrimaryOutCh1"	
			//String/G Current_signal	= 	"SecondaryOutCh1"
			String/G Monitor_signal	= 	"SecondaryOutCh1"
			String/G OutputCell_Signal	=	"Command"
			string/G OutputStim_Signal	=	 "Extracellular SIU1"

			//String/G  Voltage_Monitor 		// string to be matched to find voltage channel
			//String/G  current_Monitor		// string to be matched to find current channel

			variable /G 	EvThresh_CmdVolt					=  0	// command voltage,V (absolute)
			variable /G EvThresh_CmdVolt_on			= 0.1
			variable/G EvThresh_CmdVolt_off			= 0.4	
			variable /G EvThresh_AcqLength		= 	0.61		// total length of acquisition wave, sec
			Variable /G EvThresh_TrialISI				=   1		// seconds between steps
			variable /G EvThresh_CalcIRCheck			=	1		// Calculate real-time Input resistance ?
			variable /G EvThresh_DispHoldCurrCheck	=	1		// measure & display holding current
			variable /G EvThresh_DispCmdVoltCheck	=	1		// measure & display real voltage
			Variable /G EvThresh_RepeatCheck		=	1		// Repeat sets?
			//Variable/G EvThresh_NumTrialRepeats		=	2	// number of times to repeat trials within  a set
			Variable /G EvThresh_NumSetRepeats		=	1		// number of times to repeat sets
			Variable /G EvThresh_SetNum			=	0		// Label each set 
			//to average the set traces
			variable /G EvThresh_Averagecheck	=	0
			variable /G EvThresh_nextAvg			=	0
			string /G EvThresh_AvgBasename	:=	"EvTh_" + root:DataAcquisitionVar:baseName  +"_avg" +num2str(EvThresh_nextAvg)// Averaging waves basename
			//
			variable/G EvThresh_NumPulses		= 1		
			variable /G EvThresh_InterPulseInterval = 0.010			//  in seconds
			variable/G EvThresh_StimFrequency	:= 1/EvThresh_Interpulseinterval
			Variable /G EvThresh_StimBuffer =  0.2		// time after IR test to place stimulus (sec)
			Variable /G EvThresh_StimDuration =  0.0004	// duration of electrical stimulus (sec;  e.g. 100microsec)
			Variable /G EvThresh_StartAmplitude =1		// volts
			
			Variable /G EvThresh_NumLevels =7		// 
			Variable /G EvThresh_LevelAmplitude=0.5	// volts
			variable/G EvThresh_LevelPercent := 100*EvThresh_LevelAmplitude/EvThresh_StartAmplitude	// provide as % to help determine levels
			Variable /G EvThresh_EndAmplitude  := (EvThresh_NumLevels-1)*EvThresh_LevelAmplitude + EvThresh_StartAmplitude		// calculate from prior 3 variables
			Variable /G EvThresh_ExpectedLatency = 0.003			// for online psc analysis
			Variable/G EvThresh_LatencyWindow = 0.001		// for finding peak
			variable /G EvThresh_PkDirection = 1		// 1 = positive; 2=negative; 3 = no direction, do simple level estimate
			variable/G EvThresh_PkAverageWindow = 0.0002		// time over which to average pk measure
		
			Variable/G EvThresh_baselinewindow	= 0.001		// check that baseline window is greater than latency window
		
			Variable /G EvThresh_Biphasic	=	1			// 1 = yes, biphasic; 0= no, monophasic
			Variable/G EvThresh_InvertStim	= 0
			//  Add popup section to choose stimulation wave:	
			String /G EvThresh_StimWaveName := "SIU_set"  + num2str(EvThresh_setnum)		// create a default evoked wave
			String 	/G EvThresh_Basename			:=	"EvTh_" +root:DataAcquisitionVar:baseName + "s" + num2str(EvThresh_setnum)	// Acquisition waves basename
			String /G EvThresh_PathName = "EvThreshPath"
			
			Variable /G EvThresh_yaxis1_VC	=	-0.5		// nA  plotwindow negative in Vclamp
			variable /G EvThresh_yaxis2_VC	=	0.2		//nA   plotwindow positive in Vclamp
			Variable /G EvThresh_yaxis1_CC	=	-0.01	// V, plotwindow negative in Current clamp
			variable /G EvThresh_yaxis2_CC	=	0.02		//V plotwindow positive in Current clamp
			
			Execute "EvokThreshAcq_ControlPanel()"
			SetDataFolder dfSave	
		else
			Execute "EvokThreshAcq_ControlPanel()"
		endif
		SaveExperiment
		NewPath /C/M="Choose folder for Evoked Threshold files"/O/Q/Z EvThreshPath
	else
		Print "You must first initialize global variables with procedure 'InitializedDataAcquisition()' "
	endif
end

Window EvokThreshAcq_ControlPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(676,207,1435,687)
	ModifyPanel cbRGB=(65280,32768,32768), frameStyle=3
	ShowTools
	SetDrawLayer UserBack
	SetDrawEnv fillpat= 65,fillfgc= (65280,65280,32768)
	DrawRRect 11,4,427,37
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 115,28,"Find Evoked Threshold - Multiclamp"
	DrawLine 76,62,370,62
	DrawLine 73,115,367,115
	DrawLine 77,171,380,171
	DrawLine 46,376,409,376
	SetDrawEnv fname= "Times New Roman"
	DrawText 17,318,"PSP/PSC amplitude analysis:"
	DrawLine 44,297,403,297
	DrawText 546,251,"Vclamp"
	DrawText 546,318,"Iclamp"
	SetVariable EvThresh_BasenameSetVar,pos={13,42},size={265,16},title="Acquisition Waves Basename"
	SetVariable EvThresh_BasenameSetVar,value= root:EvokThresh:EvThresh_Basename
	SetVariable SetRepeatSetVar,pos={17,91},size={206,16},title="Number of times to repeat set :   "
	SetVariable SetRepeatSetVar,limits={1,100,1},value= root:EvokThresh:EvThresh_NumSetRepeats
	SetVariable SetNumSetVar,pos={294,42},size={118,16},title="Current Set #"
	SetVariable SetNumSetVar,value= root:EvokThresh:EvThresh_SetNum
	Button EvThresh_AcquireButton,pos={26,382},size={243,33},proc=Acq_EvThresh_data,title="Acquire"
	PopupMenu SelectOutSignalPopup,pos={20,448},size={202,21},proc=EvTh_UpdateoutSignalProc,title="Cmd Output Signal (cell)"
	PopupMenu SelectOutSignalPopup,mode=2,popvalue="Command",value= #"root:NIDAQBoardVar:OutputNamesString"
	PopupMenu SelectOutStimPopup,pos={15,418},size={241,21},proc=EvTh_OutStimSigPopMenuProc,title="Stimulus Output Signal   "
	PopupMenu SelectOutStimPopup,mode=4,popvalue="Extracellular SIU1",value= #"root:NIDAQBoardVar:OutputNamesString"
	PopupMenu SelectInputSignalPopup,pos={303,387},size={168,21},proc=EvTh_UpdateInputSignalProc,title="Input Signal"
	PopupMenu SelectInputSignalPopup,mode=2,popvalue="PrimaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	PopupMenu SelectMonitorSignalPopup,pos={282,419},size={147,21},proc=EvTh_SecondaryPopMenuProc,title="Monitor"
	PopupMenu SelectMonitorSignalPopup,mode=3,popvalue="PrimaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	SetVariable TrialISISetVar,pos={234,92},size={135,16},title="Trial ISI (sec)      "
	SetVariable TrialISISetVar,limits={0.1,60,0.1},value= root:EvokThresh:EvThresh_TrialISI
	CheckBox CalcIRCheck,pos={11,121},size={151,14},disable=2,proc=EvThresh_CalcIRCheckProc,title="Calculate Input Resistance?"
	CheckBox CalcIRCheck,value= 1
	CheckBox DispHoldCurrCheck,pos={180,120},size={134,14},disable=2,proc=EvThresh_DispHoldCurrCheckProc,title="Display Holding Current?"
	CheckBox DispHoldCurrCheck,value= 1
	CheckBox DispCmdVoltCheck,pos={328,119},size={138,14},disable=2,proc=EvThresh_DispCmdVoltCheckProc,title="Display baseline voltage?"
	CheckBox DispCmdVoltCheck,value= 1
	SetVariable AcqLengthSetVar,pos={18,71},size={180,16},title="Length per trial (sec)"
	SetVariable AcqLengthSetVar,limits={0.001,100,0.5},value= root:EvokThresh:EvThresh_AcqLength
	SetVariable CmdVoltSetVar,pos={425,71},size={175,16},title="Command voltage (V)"
	SetVariable CmdVoltSetVar,limits={-0.2,0.2,0.01},value= root:EvokThresh:EvThresh_CmdVolt
	SetVariable StimDurSetVar,pos={13,195},size={200,16},title="SIU Stim Duration (sec)"
	SetVariable StimDurSetVar,limits={1e-05,0.01,5e-05},value= root:EvokThresh:EvThresh_StimDuration
	SetVariable LowAmpSetVar,pos={18,222},size={146,16},title="start Amplitude (V)"
	SetVariable LowAmpSetVar,limits={0.1,10,1},value= root:EvokThresh:EvThresh_StartAmplitude
	SetVariable StimBufferSetVar,pos={225,196},size={238,16},title="Stimulus Delay (sec)"
	SetVariable StimBufferSetVar,value= root:EvokThresh:EvThresh_StimBuffer
	CheckBox SIUBiphasicCheck,pos={188,179},size={64,14},proc=EvTh__BiphasicCheckProc,title="Biphasic?"
	CheckBox SIUBiphasicCheck,value= 1
	SetVariable StimWaveNameSetVar,pos={11,179},size={164,16},proc=EvTh__BiphasicCheckProc,title="SIU Stim Wave Name"
	SetVariable StimWaveNameSetVar,value= root:EvokThresh:EvThresh_StimWaveName
	SetVariable NumPulsesSetVar,pos={333,228},size={169,16},title="# pulse in train             "
	SetVariable NumPulsesSetVar,limits={1,100,1},value= root:EvokThresh:EvThresh_NumPulses
	SetVariable setvar2,pos={333,248},size={170,16},title="InterPulse Interval (sec)"
	SetVariable setvar2,limits={0.001,0.1,0.01},value= root:EvokThresh:EvThresh_InterPulseInterval
	ValDisplay valdisp0,pos={332,267},size={172,14},title="Frequency (Hz)             "
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #" root:EvokThresh:EvThresh_StimFrequency"
	CheckBox AvgCheck,pos={11,143},size={107,14},proc=EvThresh_AvgCheckProc,title="Average Repeats?"
	CheckBox AvgCheck,value= 1
	SetVariable AvNameSetVar,pos={124,143},size={283,16},title="Average Waves Basename:"
	SetVariable AvNameSetVar,value= root:EvokThresh:EvThresh_AvgBasename
	SetVariable nextAvgSetVar,pos={410,144},size={87,16},title="avg tick:"
	SetVariable nextAvgSetVar,limits={0,100,1},value= root:EvokThresh:EvThresh_nextAvg
	SetVariable NumLevelsSetVar,pos={17,256},size={148,16},title="Number of levels     "
	SetVariable NumLevelsSetVar,limits={1,100,1},value= root:EvokThresh:EvThresh_NumLevels
	SetVariable LatencyPkSetVar,pos={268,307},size={219,16},title="Expected Latency to Peak (sec)"
	SetVariable LatencyPkSetVar,limits={0.0001,0.1,0.002},value= root:EvokThresh:EvThresh_ExpectedLatency
	SetVariable PeakFindWinSetVar,pos={25,346},size={189,16},title="Peak finding window (sec)"
	SetVariable PeakFindWinSetVar,limits={0.0001,0.01,0.0005},value= root:EvokThresh:EvThresh_LatencyWindow
	PopupMenu PeakDirPopup,pos={50,322},size={155,21},proc=EvTh_UpdatePeakDir,title="Peak Direction"
	PopupMenu PeakDirPopup,mode=1,popvalue="Negative",value= #"\"Negative;Positive;no peak\""
	SetVariable BaselineWinSetVar,pos={267,327},size={206,16},title="Baseline averaging window"
	SetVariable BaselineWinSetVar,limits={0.0001,1,0.001},value= root:EvokThresh:EvThresh_PkAverageWindow
	SetVariable PkAvgWinSetVar,pos={268,346},size={206,16},title="Peak averaging window    "
	SetVariable PkAvgWinSetVar,limits={1e-05,0.1,0.0001},value= root:EvokThresh:EvThresh_PkAverageWindow
	CheckBox InvertStimCheck,pos={274,178},size={87,14},proc=EvTh_InvertStimCheckProc,title="Invert Stimulus"
	CheckBox InvertStimCheck,value= 1
	SetVariable LevelAmp_setvar,pos={18,237},size={147,16},title="Step amplitude (V) "
	SetVariable LevelAmp_setvar,limits={0.01,10,0.1},value= root:EvokThresh:EvThresh_LevelAmplitude
	ValDisplay stepamp_pct_valdisp,pos={182,239},size={66,14},title="(as % )"
	ValDisplay stepamp_pct_valdisp,limits={0,0,0},barmisc={0,2000}
	ValDisplay stepamp_pct_valdisp,value= #" root:EvokThresh:EvThresh_LevelPercent"
	ValDisplay EndAmp_valDisp,pos={18,276},size={146,14},title="end Amplitude (V)     "
	ValDisplay EndAmp_valDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay EndAmp_valDisp,value= #" root:EvokThresh:EvThresh_EndAmplitude"
	SetVariable CmdVoltOn,pos={174,276},size={50,16},limits={10,0,0.1},value= _NUM:0
	SetVariable CmdVoltOnTime,pos={414,87},size={186,16},title="Time On (s)"
	SetVariable CmdVoltOnTime,limits={0,10,0.1},value= root:EvokThresh:EvThresh_CmdVolt_on
	SetVariable CmdVoltOnTime1,pos={620,87},size={81,16},title="off (s)"
	SetVariable CmdVoltOnTime1,limits={0,10,0.1},value= root:EvokThresh:EvThresh_CmdVolt_off
	SetVariable Yplot_VC2,pos={605,246},size={98,16},title="nA below"
	SetVariable Yplot_VC2,value= root:EvokThresh:EvThresh_yaxis1_VC
	SetVariable Yplot_VC3,pos={605,225},size={98,16},title="nA above"
	SetVariable Yplot_VC3,value= root:EvokThresh:EvThresh_yaxis2_VC
	SetVariable Yplot_VC4,pos={600,294},size={98,16},title="V above"
	SetVariable Yplot_VC4,value= root:EvokThresh:EvThresh_yaxis2_CC
	SetVariable Yplot_VC5,pos={601,320},size={98,16},title="V below"
	SetVariable Yplot_VC5,value= root:EvokThresh:EvThresh_yaxis1_CC
	GroupBox Yaxissettings,pos={524,203},size={195,167},title="Yaxis settings"
EndMacro

function Acq_EvThresh_data(ctrlname) 		: ButtonControl
	string ctrlname
	//// Make sure the experiment is saved and therefore named
	Print "\r\r  STARTING Evok Threshold Proc"
	if (StringMatch(IgorInfo(1),"Untitled"))	
		Print "\tAborting -- experiment not saved!"
		SetDataFolder root:
		Abort "You'd better save your experiment first!"
	endif
	Kill_EvThresh_windows()	
	string dfsave=GetDataFolder(1)
	SetDataFolder root:EvokThresh	
	// make these SVARs:
	string LocalMode =""
	
		
//	SVAR Voltage_Monitor =  root:EvokThresh:Voltage_signal	// string to be matched to find voltage channel
//	SVAR current_Monitor=  root:EvokThresh:Current_signal	// string to be matched to find current channel
	
	//SVAR Voltage_Signal =  root:EvokThresh:Voltage_Signal	// string to be matched to find voltage channel
	//SVAR current_Signal=  root:EvokThresh:current_Signal	// string to be matched to find current channel
	SVAR Input_Signal =  root:EvokThresh:Input_Signal	// string to be matched to find input channel (
	SVAR Monitor_Signal=  root:EvokThresh:Monitor_Signal	// string to be matched to find monitor channel
	
	
	SVAR OutputCell_Signal =  root:EvokThresh:OutputCell_Signal			// string to be matched to find DAC output to drive current step 
	SVAR OutputStim_Signal=  root:EvokThresh:OutputStim_Signal
	
	SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
//	If(stringmatch(NowMulticlampMode, "V-Clamp"))
//			SVAR Input_Signal=  root:EvokThresh:Current_signal
//	else	// if "I-Clamp"
//			SVAR Input_Signal=  root:EvokThresh:Voltage_signal
//	endif
//

//	SVAR Current_AxClMode 	=root:NIDAQBoardVar:Current_AxClMode
//	NVAR  Current_AxClGain	=root:NIDAQBoardVar:Current_AxClGain
//	ControlInfo  /W=EvokThreshAcq_ControlPanel SelectVoltInputSignalPopup
//	Voltage_monitor = S_value
//	ControlInfo  /W=EvokThreshAcq_ControlPanel SelectCurrInputSignalPopup
//	Current_monitor = S_value
//	ControlInfo  /W=EvokThreshAcq_ControlPanel SelectInputSignalPopup
//	Input_Signal = S_value
//	ControlInfo  /W=EvokThreshAcq_ControlPanel SelectOutStimPopup
//	if(V_flag)
//		OutputStim_Signal = S_value
//		//print "OutputStimSignal = " + outputstim_signal
//	else
//		print "control does not exist"
//	endif
//	ControlInfo  /W=EvokThreshAcq_ControlPanel SelectOutCellPopup
//	if(V_flag)
//		OutputCell_Signal=S_value
//		//print "OutputCellSignal = " + OutputCell_Signal
//	else
//		print "control does not exist"
//	endif
	String AcqString=""
	String WFOutString=""
	String CommandStr=""
	Variable Input_Channel
	Variable Input_IndBoardGain
	Variable Input_AmpGain
	Variable Monitor_Channel
	Variable Monitor_IndBoardGain
	Variable  Monitor_AmpGain
	Variable DACcell_out_Channel
	Variable DACcell_out_AmpGain
	Variable DACstim_out_Channel
	Variable DACstim_out_AmpGain
	
	
	variable err
	variable StartTicks,elapsedTicks
	Variable BeforeBuff = 0.100	//  time before test pulse , sec
	variable StartingSetNumber,EndingSetNumber
	variable i=0
	Variable j=0
	variable k=0
	string DoColorStyle = "ColorStyleMacro()"

	Make/N=4/O EvThresh_PSCDisplay_pos,EvThresh_rawDataDisplay_pos,EvThresh_AvgWaveDisplay_pos,EvThresh_InpResDisplay_pos,EvThresh_HoldCurrDisplay_pos,EvThresh_VoltDisplay_pos,EvThresh_OutputWavesDisplay_pos,EvThresh_allDataDisplay_pos
	Make/N=4/O EvThresh_Table2_pos,EvThresh_Table1_pos,EvThresh_HoldParamDisplay_pos
	Variable LeftPos=50					// variables for positioning graph windows for this module
	Variable TopPos=50
	Variable Graph_Height=150
	variable Graph_Width = 220
	variable Graph_grout = 25
// graph across top left
	EvThresh_rawDataDisplay_pos={LeftPos,TopPos,LeftPos+graph_Width,TopPos+Graph_Height}
// graph 2nd from top, left
	EvThresh_AvgWaveDisplay_pos={LeftPos,TopPos+Graph_Height+Graph_Grout,LeftPos+graph_Width,TopPos+2*Graph_Height+Graph_Grout}
// graph 2nd from bottom left
	EvThresh_allDataDisplay_pos={LeftPos,TopPos+2*Graph_Height+2*Graph_Grout,LeftPos+graph_Width,TopPos+2.5*Graph_Height+2*Graph_Grout}	
// next column
	LeftPos+=graph_width+Graph_grout
	Graph_Height=140
	Graph_Width = 220
// Combined Graph	
	EvThresh_HoldParamDisplay_pos={LeftPos,TopPos,LeftPos+graph_Width,TopPos+Graph_Height}	
// graph middle, bottom-  make this one a bit bigger
	EvThresh_PSCDisplay_pos={LeftPos,TopPos+Graph_Height+Graph_Grout,LeftPos+2*graph_Width,TopPos+3*Graph_Height+Graph_Grout}
// next column
	LeftPos+=graph_width+Graph_grout
	Graph_Height=140
//graph top, far right
	EvThresh_OutputWavesDisplay_pos ={LeftPos,TopPos,LeftPos+Graph_Width,TopPos+Graph_Height}
	Leftpos+=200
	Toppos+=200
// Tables display
	EvThresh_Table1_pos={LeftPos,TopPos,LeftPos+graph_Width,TopPos+Graph_Height}
	Toppos+=50
	Leftpos+=50
	EvThresh_Table2_pos={LeftPos,TopPos,LeftPos+graph_Width,TopPos+Graph_Height}
	
// Update Telegraphs:  verify I-clamp, update scaled output gain, write to notebook the readouts
//print Input_Signal
//	if(stringmatch(Input_Signal,"ScaledOutput"))
//		//Execute "UpdateTelegraphs()"
//		//print "getting TG globals"
//		NVAR Current_TG_Gain	=	root:NIDAQBoardVar:Current_TG_Gain		
//		SVAR  Current_TG_Mode=	root:NIDAQBoardVar:Current_TG_Mode
//		SVAR Current_ScaledOutType=root:NIDAQBoardVar:Current_ScaledOutType
//		NVAR Current_TG_Filter	=root:NIDAQBoardVar:Current_TG_Filter
//		NVAR current_TG_Capac	=root:NIDAQBoardVar:current_TG_Capac	
//		LocalMode=	Current_TG_Mode
//		if(  (! stringmatch(Current_TG_Mode,"V-Clamp")) &&  (! stringmatch(Current_TG_Mode,"I-Clamp Normal")) && (! stringmatch(Current_TG_Mode,"I-Clamp Fast")) )		// in future, use in both V-Cl and I-Cl
//			SetDataFolder root:
//			Abort "Amplifier must be set in'V-Clamp' or 'I-Clamp'"
//		endif
//		if(  stringmatch(Current_TG_Mode,"V-Clamp")  )
		
		If(stringmatch(NowMulticlampMode, "V-Clamp"))
			NVAR EvThresh_IRamp		=	root:DataAcquisitionVar:IRpulse_amp_VC	// input resistance test pulse, V (e.g. -5mV)
			NVAR EvThresh_IRdur		=	root:DataAcquisitionVar:IRpulse_dur_VC		// test pulse duration, sec (e.g., 10ms)
		else
			NVAR EvThresh_IRamp		=	root:DataAcquisitionVar:IRpulse_amp_IC	// input resistance test pulse, A (e.g. -0.05nA)
			NVAR EvThresh_IRdur		=	root:DataAcquisitionVar:IRpulse_dur_IC
		endif
//	else
//		LocalMode = Current_AxClMode
//		if(stringmatch(Input_Signal,"AxCl_10Vm"))
//			NVAR EvThresh_IRamp		=	root:DataAcquisitionVar:AxCl_IRpulse_amp_IC	// input resistance test pulse, A (e.g. -0.05nA)
//			NVAR EvThresh_IRdur		=	root:DataAcquisitionVar:AxCl_IRpulse_dur_IC
//		else
//			if(stringmatch(Input_Signal,"AxCl_Iout"))
//				NVAR EvThresh_IRamp		=	root:DataAcquisitionVar:AxCl_IRpulse_amp_VC	// input resistance test pulse, A (e.g. -0.05nA)
//				NVAR EvThresh_IRdur		=	root:DataAcquisitionVar:AxCl_IRpulse_dur_VC
//			else
//				//SetDataFolder root:
//				//Abort "Something wrong with choice of Input_Signal:  must be ScaledOutput,AxCl_10Vm, or AxCl_Iout"		
//			endif	
//		endif	
//	endif	
	// determine correct channel #s for Scaled out (voltage), I output
	
		
	//Print "Getting Nidaq ADC/DAC globals"
	NVAR AcqResolution=  root:DataAcquisitionVar:AcqResolution
	WAVE ADC_ChannelWave			=root:NIDAQBoardVar:ADC_ChannelWave
	WAVE ADC_SignalWave				=root:NIDAQBoardVar:ADC_SignalWave
	WAVE ADC_IndBoardGainWave		=root:NIDAQBoardVar:ADC_IndBoardGainWave
	WAVE ADC_AmpGainWave			=root:NIDAQBoardVar:ADC_AmpGainWave

	WAVE DAC_SignalWave				=root:NIDAQBoardVar:DAC_SignalWave
	WAVE DAC_Channel_Wave			=root:NIDAQBoardVar:DAC_Channel_Wave
	WAVE DAC_AmpGain_VCl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_VCl_Wave
	WAVE DAC_AmpGain_ICl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	

	print "DAC gains ICl:",  DAC_AmpGain_ICl_Wave
	print "DAC gains VCl:",  DAC_AmpGain_VCl_Wave
	Variable DAC_CellOut_Channel
	Variable DAC_CellOut_AmpGain
	Variable DAC_StimOut_Channel = 1		// set to DAC1 for now
	variable DAC_StimOut_AmpGain =1		// set to 1; always?  default?
	
	//NVAR BoardID =	root:NIDAQBoardVar:Boardid
	// find  channels;determine current amplifier gains for output & input waves;determine individual board gains for input waves
	//print "determining channels & gains"
//	string ADCsignalList = ConvertTextWavetoList(ADC_SignalWave)
//	string DACsignalList = ConvertTextWavetoList(DAC_SignalWave)
//	if (stringmatch(LocalMode,"V-Clamp")  |  stringmatch(LocalMode,"VClamp"))  // if in V-Clamp
//		Monitor_Channel=whichListItem(Voltage_Monitor, ADCsignalList)				// channel is equivalent to position in List
//	else
//		Monitor_Channel=whichListItem(Current_Monitor, ADCsignalList)
//	endif
//	Input_Channel=WhichlistItem(Input_Signal, ADCsignalList)
//	DAC_CellOut_Channel=WhichlistItem(Outputcell_Signal, DACsignalList)
//	//Print "DAC_CellOut_channel ,  ", num2str(DAC_CellOut_Channel)
//	DAC_StimOut_Channel=WhichlistItem(OutputStim_Signal, DACsignalList)
//	if((Monitor_Channel==-1)  || (input_Channel==-1) )			// check that all have channels
//		commandstr = "you must select  channels containing  "+Voltage_Monitor +"or " +  current_Monitor +"," + OutputStim_Signal 
//		SetDataFolder root:
//		Abort "channel problem "  
//	endif 
//	Monitor_AmpGain= ADC_AmpGainWave[Monitor_Channel]
//	Input_AmpGain=ADC_AmpGainWave[Input_Channel]
//	if(  stringmatch(LocalMode,"V-Clamp") )		// if amplifier is in Voltage Clamp
//		DAC_CellOut_AmpGain=DAC_AmpGain_VCl_Wave[DAC_CellOut_Channel]
//		//print "Setting DAC_Cellout Vclamp gain", DAC_CellOut_AmpGain
//	else
//		if(  stringmatch(LocalMode,"I-Clamp Normal") ||  stringMatch(LocalMode,"I-Clamp Fast"  ) ||  stringMatch(LocalMode,"I-Clamp"  ))	// if amplifier is in Current Clamp
//			DAC_CellOut_AmpGain=DAC_AmpGain_ICl_Wave[DAC_CellOut_Channel]
//			//print "Setting DAC_Cellout Iclamp gain", DAC_CellOut_AmpGain
//		else
//			commandstr = "amplifier must be in  V-Clamp, I-Clamp Normal,  or I-Clamp Fast"
//			SetDataFolder root:
//			Abort commandstr
//		endif
//	endif
//	monitor_IndBoardGain= ADC_IndBoardGainWave[Monitor_channel]
//	input_IndBoardGain=ADC_IndBoardGainWave[input_Channel]

// find  channels;determine current amplifier gains for output & input waves;determine individual board gains for input waves
	//print "determining channels & gains"
	string ADCsignalList = ConvertTextWavetoList(ADC_SignalWave)
	//print ADCsignalList
	string DACsignalList = ConvertTextWavetoList(DAC_SignalWave)
	//print DACsignalList
	Input_Channel=whichListItem(Input_signal, ADCsignalList)				// channel is equivalent to position in List
	Monitor_Channel=WhichlistItem(Monitor_signal, ADCsignalList)
	DAC_CellOut_Channel=WhichlistItem(OutputCell_Signal, DACsignalList)
	DAC_StimOut_Channel=WhichlistItem(OutputStim_Signal, DACsignalList)
	
	if((Input_Channel==-1)  || (Monitor_Channel==-1)  )			// check that all have channels
		commandstr = "you must select  channels containing  "+Input_signal +"," +  Monitor_signal 
		SetDataFolder root:
		Abort commandstr
	endif 
	if((DAC_CellOut_Channel==-1) || (DAC_StimOut_Channel==-1))			// check that all have channels
		commandstr = "you must select  channels containing  "+ OutputCell_Signal + ", and " + OutputStim_Signal 
		SetDataFolder root:
		Abort commandstr
	endif 
	
	Input_AmpGain= ADC_AmpGainWave[Input_Channel]
	Monitor_AmpGain=ADC_AmpGainWave[Monitor_Channel]

	DAC_StimOut_AmpGain=DAC_AmpGain_ICl_Wave[DAC_StimOut_Channel]		// actually doesn't get used here - set to 1
	If(stringmatch(NowMulticlampMode, "V-Clamp"))
		DAC_CellOut_AmpGain=DAC_AmpGain_VCl_Wave[DAC_CellOut_Channel]
		print "getting DACcell_out_AmpGain for voltage clamp:", DACcell_out_AmpGain
	else
		DAC_CellOut_AmpGain=DAC_AmpGain_ICl_Wave[DAC_CellOut_Channel]
		print "getting DACcell_out_AmpGain for current clamp:", DACcell_out_AmpGain
	endif
// write EvokThresh panel parameters to notebook
// all the panel variables:
	//print "Getting Evoked PSC panel parameters"
	NVAR EvThresh_CmdVolt				=	root:EvokThresh:EvThresh_CmdVolt
	NVAR EvThresh_CmdVolt_on			=	root:EvokThresh:EvThresh_CmdVolt_on	
	NVAR EvThresh_CmdVolt_off				=	root:EvokThresh:EvThresh_CmdVolt_off	
	
	NVAR EvThresh_SetNum				=	root:EvokThresh:EvThresh_SetNum
	SVAR EvThresh_Basename				=	root:EvokThresh:EvThresh_Basename
	SVAR Basename						=	root:DataAcquisitionVar:baseName
	String Local_Basename				=	"EvTh_" +baseName + "s" + num2str(EvThresh_SetNum)	// recalculate a local basename
	NVAR EvThresh_AcqLength				=	root:EvokThresh:EvThresh_AcqLength
	NVAR EvThresh_TrialISI				=	root:EvokThresh:EvThresh_TrialISI					// in sec
	//NVAR EvThresh_NumTrialRepeats		=	root:EvokThresh:EvThresh_NumTrialRepeats
	NVAR EvThresh_NumSetRepeats		=	root:EvokThresh:EvThresh_NumSetRepeats
	NVAR EvThresh_SetNum				=	root:EvokThresh:EvThresh_SetNum
	NVAR EvThresh_RepeatCheck			=	root:EvokThresh:EvThresh_RepeatCheck
	NVAR EvThresh_CalcIRCheck			=	root:EvokThresh:EvThresh_CalcIRCheck
	NVAR EvThresh_DispHoldCurrCheck	=	root:EvokThresh:EvThresh_DispHoldCurrCheck
	NVAR EvThresh_DispCmdVoltCheck	=	root:EvokThresh:EvThresh_DispCmdVoltCheck
	SVAR EvThresh_StimwaveName			=	root:EvokThresh:EvThresh_StimwaveName
	NVAR EvThresh_StimBuffer = root:EvokThresh:EvThresh_StimBuffer	// time after IR test to place stimulus (sec);  now absolute delay
	NVAR EvThresh_StimDuration = root:EvokThresh:EvThresh_StimDuration 	// duration of electrical stimulus (sec;  e.g. 100microsec)
	NVAR EvThresh_InterPulseInterval = root:EvokThresh:EvThresh_InterPulseInterval
	NVAR EvThresh_numPulses =root:EvokThresh:EvThresh_numPulses
	NVAR EvThresh_stimfrequency=root:EvokThresh:EvThresh_stimfrequency
	variable x1,x2,x3,x4
	variable p1,p2,p3,p4
	NVAR EvThresh_StartAmplitude =root:EvokThresh:EvThresh_StartAmplitude
	NVAR EvThresh_EndAmplitude =root:EvokThresh:EvThresh_EndAmplitude
	NVAR EvThresh_NumLevels =root:EvokThresh:EvThresh_NumLevels
	NVAR EvThresh_LevelAmplitude =root:EvokThresh:EvThresh_LevelAmplitude
	if(numtype(EvThresh_LevelAmplitude)!= 0)
		EvThresh_LevelAmplitude =0
	endif
	NVAR Latency = root:EvokThresh:EvThresh_ExpectedLatency
	NVAR EvThresh_LatencyWindow = root:EvokThresh:EvThresh_LatencyWindow
	NVAR EvThresh_PkDirection = root:EvokThresh:EvThresh_PkDirection
	NVAR EvThresh_PkAverageWindow = root:EvokThresh:EvThresh_PkAverageWindow
	NVAR baselinewindow =  root:EvokThresh:EvThresh_baselinewindow
	if (baselinewindow<latency)
		baselinewindow = latency
		//SetDataFolder root:
		//Abort "Baseline window must be greater than expected latency"
	endif
	
	NVAR EvThresh_yaxis1_VC	= root:EvokThresh:EvThresh_yaxis1_VC	// nA  plotwindow negative in Vclamp
	NVAR EvThresh_yaxis2_VC	= root:EvokThresh:EvThresh_yaxis2_VC		//nA   plotwindow positive in Vclamp
	NVAR EvThresh_yaxis1_CC	= root:EvokThresh:EvThresh_yaxis1_CC	// V, plotwindow negative in Current clamp
	NVAR EvThresh_yaxis2_CC	 = root:EvokThresh:EvThresh_yaxis2_CC		//V plotwindow positive in Current clamp
	
	
	NVAR EvThresh_Biphasic	=	root:EvokThresh:EvThresh_Biphasic
	NVAR EvThresh_InvertStim	=	root:EvokThresh:EvThresh_InvertStim
	NVAR EvThresh_AverageCheck	=	root:EvokThresh:EvThresh_AverageCheck
	NVAR EvThresh_nextAvg	=	root:EvokThresh:EvThresh_nextAvg
	SVAR EvThresh_AvgBasename 	=	root:EvokThresh:EvThresh_AvgBasename
	variable Le= (EvThresh_numPulses-1)*(EvThresh_InterPulseInterval+EvThresh_StimDuration)+ 2*EvThresh_StimBuffer+2*BeforeBuff
	if( EvThresh_AcqLength  <= Le)
		SetDataFolder root:
		Commandstr=" The acquisition total length must be greater than " + num2str(Le) + " seconds long"
		abort commandStr
	endif
	Variable totalWavePoints = AcqResolution *EvThresh_AcqLength
	StartingSetNumber=EvThresh_SetNum
// Write to notebook channels & gains
	Notebook Parameter_Log ruler=Title, text="\r\rStarting Evoked Threshold Data Acquisition" +"\r"
	Notebook Parameter_Log ruler=Normal, text ="\t" +Date() + "  " + time() + "\r\r"
	Notebook Parameter_Log ruler=Normal, text ="\tStimulation through SIU:  \t" + OutputStim_Signal
	Notebook Parameter_Log ruler=normal, text="\r\tAcquisition Resolution (samples/sec) :\t" + num2str(AcqResolution)
	Notebook Parameter_Log ruler =normal, text="\r\tTotal Wave Length (sec): \t" + num2str(EvThresh_AcqLength )
	Notebook Parameter_Log ruler=normal, text="\r\tAcquisition  is in \t" + LocalMode + " mode"
//	Notebook Parameter_Log ruler=normal, text="\r\tInput (" + Current_ScaledOutType + ") signal : \t"  + Input_Signal  +" on channel " +num2str(Input_Channel)
//	Notebook Parameter_Log ruler=normal, text="\r\tInput ("    +Current_ScaledOutType + ") signal amplifier gain : \t" + num2str(Input_ampGain)
//	Notebook Parameter_Log ruler=normal, text="\r\t                           board gain : \t" + num2str(Input_IndBoardGain)
//	
//	If(stringmatch(NowMulticlampMode, "V-Clamp"))
//		Notebook Parameter_Log ruler=normal, text="\r\tMonitoring voltage signal : \t"  + Voltage_Monitor  +" on channel " +num2str(Monitor_Channel)
//		Notebook Parameter_Log ruler=normal, text="\r\tVoltage signal amplifier gain : \t" + num2str(Monitor_ampGain) 
//		Notebook Parameter_Log ruler=normal, text="\r\t                           board gain : \t" + num2str(Monitor_IndBoardGain)
//	else
//		Notebook Parameter_Log ruler =normal, text="\r\tMonitoring current signal : \t"  + current_Monitor+" on channel " +num2str(Monitor_Channel)
//		Notebook Parameter_Log ruler =normal, text="\r\tCurrent  signal amplifier gain \t: " + num2str(Monitor_ampGain) 
//		Notebook Parameter_Log ruler=normal, text="\r\t                           board gain : \t" + num2str(Monitor_IndBoardGain)
//	endif
	Notebook Parameter_Log ruler =normal, text="\r\tOutput to cell to:  \t"  + Outputcell_Signal+" on channel " +num2str(DAC_CellOut_Channel)
	Notebook Parameter_Log ruler =normal, text="\r\tOutput to cell amplifier gain : \t" + num2str(DACcell_out_AmpGain)
	Notebook Parameter_Log ruler =normal, text="\r\tBasename for acquired waves: \t" +Local_Basename
	Notebook Parameter_Log ruler =normal, text="\r\tInter-trial interval (sec):\t" +num2str(EvThresh_TrialISI)
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of times to repeat set: \t" +num2str(EvThresh_NumSetRepeats) + "\r"
	Notebook Parameter_Log ruler =normal, text="\r\tStimulus parameters:"
	Notebook Parameter_Log ruler =normal, text="\r\t     Number of pulses:  \t"  + num2str(EvThresh_numpulses)
	if(EvThresh_numpulses>1)
		Notebook Parameter_Log ruler =normal, text="\r\t     Inter-pulse interval if train: \t" + num2str(EvThresh_interpulseinterval)
		Notebook Parameter_Log ruler =normal, text="\r\t     Stimulus frequency (Hz):  \t" + num2str(EvThresh_stimfrequency)
	endif
	Notebook Parameter_Log ruler =normal, text="\r\t     Stimulus start intensity (V): \t" + num2str(EvThresh_StartAmplitude)
	Notebook Parameter_Log ruler =normal, text="\r\t     Stimulus end intensity (V):\t " + num2str(EvThresh_EndAmplitude)
	Notebook Parameter_Log ruler =normal, text="\r\t     Number of  intensity steps :\t " + num2str(EvThresh_NumLevels)
	Notebook Parameter_Log ruler =normal, text="\r\t     Intensity step amplitude (V/step):\t " + num2str(EvThresh_LevelAmplitude)
	Notebook Parameter_Log ruler =normal, text="\r\t     Stimulus Duration (sec): \t" + num2str(EvThresh_Stimduration)
	if(EvThresh_Biphasic)
		Notebook Parameter_Log ruler =normal, text="\r\t     Stimulus is biphasic. "
	endif	
	if(	EvThresh_CmdVolt!=0)
		Notebook Parameter_Log ruler =normal, text="\r\tCommand Voltage (mV): \t" + num2str(EvThresh_CmdVolt*1000)
	endif
	//Notebook Parameter_Log ruler =normal, text="\r\tNumber of trials per set: \t" +num2str(EvThresh_NumTrialRepeats) + "\r"
	if(EvThresh_CalcIRCheck)
		Notebook Parameter_Log ruler =normal, text="\r\tInput resistance parameters:"
		Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse amplitude "
		If(stringmatch(NowMulticlampMode, "V-Clamp"))
			Notebook Parameter_Log ruler =normal, text="(mV):"
		else
			Notebook Parameter_Log ruler =normal, text="(pA):"
		endif
		Notebook Parameter_Log ruler =normal, text= "\t"+num2str(EvThresh_IRamp*1000)+"\r\t    Test pulse duration (ms):\t"+ num2str(EvThresh_IRdur*1000)
	endif
	

// Acquisition wave names wave creation:
	Make/T/N=(EvThresh_NumLevels,EvThresh_NumSetRepeats)/O  InputAcqNames_Wave, MonitorAcqNames_Wave // contains the names of the acquired waves
//Make/T/N=(EvThresh_NumLevels*EvThresh_NumSetRepeats)/O  currentAcqNames_Wave, VoltAcqNames_Wave // contains the names of the acquired waves
// OUTPUT WAVE CREATION:  Going to CELL create once, reuse each iteration.
// only need to create one output wave (for IR test pulse) per set:	
	//print "Creating output waves"
	if(EvThresh_TrialISI <= (EvThresh_AcqLength+0.200))	// check that ISI is long enough (200ms extra room)	
		SetDataFolder root:
		Abort "ISI must be longer than "  + num2str(EvThresh_AcqLength+0.200)
	endif
	Make/O/T/N=(EvThresh_NumSetRepeats)/O OuttoCellNames_Wave
	Make /N=( totalWavePoints)/O tempwaveOut
	SetScale /P x 0, (1/AcqResolution), "sec",  tempwaveOut
	tempwaveOut=0 //EvThresh_CmdVolt			// is command voltage absolute or relative?  if relative, need to measure volt cmd & change to difference
	DoWindow /K EvThresh_OutputWavesDisplay
	Display /W=(EvThresh_OutputWavesDisplay_pos[0],EvThresh_OutputWavesDisplay_pos[1],EvThresh_OutputWavesDisplay_pos[2],EvThresh_OutputWavesDisplay_pos[3]) as "EvThresh Output Waves"
	DoWindow /C EvThresh_OutputWavesDisplay
	i=0
	print "DAC_CellOut_AmpGain " , DAC_CellOut_AmpGain  //  DAC_cellOut_AmpGain
	Do	
		tempwaveOut[x2pnt(tempwaveOut,BeforeBuff),x2pnt(tempwaveOut,(BeforeBuff+EvThresh_IRdur))]=EvThresh_IRamp
		tempwaveOut[x2pnt(tempwaveOut,EvThresh_CmdVolt_on),x2pnt(tempwaveOut,EvThresh_CmdVolt_off)]=EvThresh_CmdVolt
		
	
		tempwaveOut/=DAC_CellOut_AmpGain		//  divide by gain  in V/V
		AppendToGraph tempwaveOut
		//print DAC_Cellout_ampgain/1000
		OuttoCellNames_Wave[i]="Ev_OutputtoCellWave_s" + num2str(i)
		Duplicate /O tempwaveOut, $OuttoCellNames_Wave[i]
		AppendToGraph $OuttoCellNames_Wave[i]
		i+=1
	while(i<EvThresh_NumSetRepeats)	
	
	
// OUTPUT WAVE CREATION:  Going to SIU:
//create a basic stimulation output wave:
	// make wave to contain amplitude levels:
	Make /N=( totalWavePoints)/O tempwave0
	SetScale /P x 0, (1/AcqResolution), "sec",  tempwave0
	String SIUOutLevelsName = "EvTh_StimOutLevels_" + num2str(EvThresh_setnum)
	Make/O/N=(EvThresh_NumLevels) EvThresh_StimOutputLevels,$SIUOutLevelsName
	Make/O/T/N=(EvThresh_NumLevels) SIUTicksText
	EvThresh_StimOutputLevels=EvThresh_startAmplitude+p*EvThresh_LevelAmplitude
	Duplicate /O EvThresh_StimOutputLevels, $SIUOutLevelsName				// klugey; to save a record of what the stim levels were for each set; 
	string stimlist = Convertnumwavetolist(EvThresh_StimOutputLevels)
	NumWavetoTextWave(EvThresh_StimOutputLevels)
	Notebook Parameter_Log ruler =normal, text="\r\tStimulus Level amplitudes (V output):         " + stimlist		
	// check acq wave length
	if ( (BeforeBuff+EvThresh_IRdur+2*EvThresh_StimBuffer)> numpnts(tempwave0) )
		print "Stimulus time buffer = "  + num2str(EvThresh_Stimbuffer)  + "sec"
		print "Acquisition length = " + num2str(EvThresh_AcqLength) + "sec"
		SetDataFolder root:
		abort "Acquisition wave length must be longer, or the stimulus time buffer must be shorter"
	endif
	Make/T/N=(EvThresh_NumLevels)/O OutStimNames_Wave		// Text wave to contain output wave names:
	Make/T/N=(EvThresh_NumLevels)/O VoltageAcqNames_Wave, currentAcqNames_Wave	//3D waves containing acquired data names

	DoWindow /F EvThresh_OutputWavesDisplay
	variable off_set=0
	variable flip
	variable EvThreshStimDur_biPoints,EvThr_IPI_points
	EvThr_IPI_points=EvThresh_Interpulseinterval  * AcqResolution		// convert to points
	if(EvThresh_Biphasic)	
		EvThreshStimDur_biPoints=  floor(EvThresh_stimduration/3 * AcqResolution)	// length in x (sec) * resolution (points/sec) = points
		//print "# points in Stim wave step  :", num2str(EvThreshStimDur_biPoints)
	endif
	if(EvThresh_InvertStim)
		flip=1
	else
		flip=-1
	endif
	j=0
	do
		//x1=BeforeBuff+EvThresh_IRdur+EvThresh_StimBuffer	// first time, this is 1st onset
		x1=EvThresh_StimBuffer	// use as delay
		p1=x2pnt(tempwave0,x1)
		if(EvThresh_Biphasic)
			x2=x1+ EvThresh_stimduration/3	// for biphasic stimulation  // change to use calculate # points & use points evenly
			x3=x2+ EvThresh_stimduration/3	
			x4=x3+EvThresh_stimduration/3
			p2=p1+EvThreshStimDur_biPoints-1
			p3=p2+EvThreshStimDur_biPoints+1
			p4=p3+EvThreshStimDur_biPoints-1
			//print " points are:  " ,p1,p2,p3,p4
		else
			x2=x1+ EvThresh_stimduration	
			p2=x2pnt(tempwave0,x2)		
		endif
		tempwave0=0
		i=0
		do
			//print num2str(EvThresh_StimOutputLevels[j])
			//tempwave0[x2pnt(tempwave0,x1),x2pnt(tempwave0,(x2))]= flip*EvThresh_StimOutputLevels[j]
			tempwave0[p1,p2]= flip*EvThresh_StimOutputLevels[j]		// use points
			if(EvThresh_Biphasic)
				//tempwave0[x2pnt(tempwave0,x3)+1,x2pnt(tempwave0,(x4))]=flip*(-1)*EvThresh_StimOutputLevels[j]
				tempwave0[p3,p4]=flip*(-1)*EvThresh_StimOutputLevels[j]
				p3+= EvThr_IPI_points
				p4+=EvThr_IPI_points
				//x3+=EvThresh_Interpulseinterval
				//x4+=EvThresh_Interpulseinterval
			endif	
			p1+=EvThr_IPI_points
			p2+=EvThr_IPI_points
			//x1+=EvThresh_InterPulseInterval
			//x2+=EvThresh_Interpulseinterval		
			i+=1
		while(i<EvThresh_numPulses)
		OutStimNames_Wave[j]= EvThresh_StimWaveName + "_" +num2str(j)
		Duplicate /O tempWave0, $OutStimNames_Wave[j]
		Appendtograph /R $OutStimNames_Wave[j]
		off_set=EvThresh_InterpulseInterval*0.1*j
		Modifygraph rgb($OutStimNames_Wave[j])=(30000,0,65525), offset($OutStimNames_Wave[j])={off_set,0}
		j+=1
	while(j<EvThresh_NumLevels)
	variable InitStimTime =EvThresh_StimBuffer
	variable Pkx = InitStimTime + Latency
	variable Nsx =  InitStimTime-baselinewindow- Latency

// REAL TIME ANALYSES:
/// check if to average raw waves themselves, if so create average wave:  Create Window to plot it
// averaging for each stim level, across sets/repeats.
	ControlInfo /W=EvokThreshAcq_ControlPanel AvgCheck
	//print  V_flag
	EvThresh_AverageCheck=V_value
	//print "EvThresh_averagecheck is" , num2str(EvThresh_AverageCheck)
	DoWindow/K EvThresh_AvgWaveDisplay
	if(EvThresh_AverageCheck)
		//print "setting up for averaging of waves across sets"
		string AvWave_VoltName,AvWave_CurrName
		Make/O/N=(EvThresh_NumLevels)/T tempWavesName_1,tempWavesName_2 // make for each stim amp level to be average individually
		tempwave0=0
		i=0
		do	
			tempWavesName_1[i]="temp_Curr_sum_" + num2str(i)
			tempWavesName_2[i]=EvThresh_AvgBasename + "_"	+num2str(i)	
			Duplicate /O tempWave0, $tempWavesName_1[i], $tempWavesName_2[i]
			if(i==0)
				Display /W=(EvThresh_AvgWaveDisplay_pos[0],EvThresh_AvgWaveDisplay_pos[1],EvThresh_AvgWaveDisplay_pos[2],EvThresh_AvgWaveDisplay_pos[3])$tempWavesName_2[i] as "Evoked Average Acquired Waves"	
			else
				appendtograph /L=left $tempWavesName_2[i]
			endif	
			i+=1
		while(i<EvThresh_NumLevels)
		If(stringmatch(NowMulticlampMode, "V-Clamp"))
			Label left "Current (nA)"
		else
			Label left "Voltage (V)"
		endif
		Label bottom "Time (sec)"
		Execute DoColorStyle
		x1=EvThresh_StimBuffer-EvThresh_interpulseinterval
		x2=x1+(EvThresh_numpulses+2)*EvThresh_interpulseinterval
		SetAxis bottom x1,x2
		
		doWindow /C EvThresh_AvgWaveDisplay
		DoUpdate
	endif	
	// Measure Initial PSC/PSP  ; calculate & plot.
	//controlInfo /W=EvokThreshAcq_ControlPanel CalcIRCheck   // add check box  later
	//EvThresh_CalcIRCheck=V_value
	DoWindow/K EvThresh_PSCDisplay
	//	print "EvThresh_CalcIRCheck = " + num2str(EvThresh_CalcIRCheck)
	variable findStart,findEnd,minlevel,baseline	
	Make/T/O/N=(EvThresh_NumSetRepeats) PSCWave_Names,Noise_Names, Fail_Names,ScWave_names
	PSCWave_Names[0]=Local_Basename  + "_PSC"			// one for each set (local_basename includes set#)	
	Noise_Names[0]=Local_Basename + "_Ns"
	Fail_Names[0]= Local_Basename + "_Fa"
	ScWave_names[0]=Local_Basename + "_Sc"
	string av_PSCName,av_NsName,av_FAName,err_PSCName,av_SCName,err_SCName
	av_PSCName = "av_set" +  num2str(EvThresh_SetNum) + "_PSC"				// use for names abbreviated to set#
	err_PSCName = "SD_set" + num2str(EvThresh_SetNum) +"_PSC"
	av_NsName = "av_set" + num2str(EvThresh_SetNum) + "_Ns"
	av_FaName = "av_set" + num2str(EvThresh_SetNum) + "_Fa"
	av_SCName = "av_set" +  num2str(EvThresh_SetNum) + "_SC"				// use for names abbreviated to set#
	err_SCName = "SD_set" + num2str(EvThresh_SetNum) +"_SC"
	Make/O/N=(EvThresh_NumLevels) $PSCWave_Names[0],$Noise_Names[0], $Fail_Names[0],$ScWave_names[0]
	Dowindow /k EvThresh_Table1		
	Edit /W=(EvThresh_Table1_pos[0],EvThresh_Table1_pos[1],EvThresh_Table1_pos[2],EvThresh_Table1_pos[3]) EvThresh_StimOutputLevels,$PSCWave_Names[k],$Noise_Names[k],$Fail_Names[k],$ScWave_names[0]
	Dowindow /C EvThresh_Table1
	Make/O/N=(EvThresh_NumLevels) $av_PSCName, $av_NsName, $av_FAName,$av_SCName				// create waves for real-time analysis each set
	Make/O/N=(EvThresh_NumLevels) sum_PSC,sum_Fa,sum_Ns,sum_Sc,sum_SC
	WAVE av_PSC = $av_PSCName
	WAVE av_Fa = $av_FaName
	WAVE av_Ns=$av_NsName
	WAVE av_Sc=$av_SCName	
	sum_PSC=0
	av_Psc=0
	sum_Ns =0
	av_Ns=0
	sum_fa=0
	av_Fa=0
	sum_Sc=0
	av_Sc=0
	// plot PSC amplitudes versus SIU stim levels:
	Display /W=(EvThresh_PSCDisplay_pos[0],EvThresh_PSCDisplay_pos[1],EvThresh_PSCDisplay_pos[2],EvThresh_PSCDisplay_pos[3]) $PSCWave_Names[0] vs  $SIUOutLevelsName   as "PSC Amplitude Display : " + Local_Basename	
	Modifygraph  mode=3,live=1,rgb($PSCWave_Names[0])=(1,3,39321),marker($PSCWave_Names[0])=5
	//	ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
	ModifyGraph manTick=0, userticks(bottom)={EvThresh_StimOutputLevels,EvThresh_StimOutputLevels_txt}
	Appendtograph $av_PSCName vs  $SIUOutLevelsName
	ModifyGraph  rgb($av_PSCName)=(1,3,39321), mode($av_PSCName)=0, lstyle($av_PSCName)=2
	Appendtograph $av_SCName vs  $SIUOutLevelsName
	ModifyGraph  rgb($av_SCName)=(1,3,39321), mode($av_SCName)=4, marker($av_SCName)=16,lsize($av_SCName)=2
	SetAxis /E=1/A left
	If(stringmatch(NowMulticlampMode, "V-Clamp"))
		Label left "PSC amplitude (nA)"
	else
		Label left "PSP amplitude (V)"
	endif
	ModifyGraph axRGB(left)=(1,3,39321),tlblRGB(left)=(1,3,39321),alblRGB(left)=(1,3,39321)
	Appendtograph /R $av_FaName vs  $SIUOutLevelsName
	label right "Failure Rate "
	ModifyGraph axRGB(right)=(65535,0,0),tlblRGB(right)=(65535,0,0),alblRGB(right)=(65535,0,0)
	ModifyGraph rgb($av_FaName)=(65535,0,0), mode($av_FaName)=4, marker($av_FaName)=8, live=1
	Label bottom "Stim amplitude Level (V)"
	doWindow /C EvThresh_PSCDisplay
	DoUpdate
	Notebook Parameter_Log ruler =normal, text="\r\tPeak finding parameters"
	Notebook Parameter_Log ruler =normal, text="\r\t  PSC/PSP expected latency (ms): \t" + num2str(1000*latency)
	Notebook Parameter_Log ruler =normal, text="\r\t  Peak finding window (ms): \t" + num2str(1000*EvThresh_latencywindow)
	ControlInfo /W=EvokThreshAcq_ControlPanel PeakDirPopup
	Notebook Parameter_Log ruler =normal, text="\r\t  Peak Direction: \t" + S_value
	Notebook Parameter_Log ruler =normal, text="\r\t  Peak averaging window (ms): \t" + num2str(1000*EvThresh_PkAverageWindow)
	Notebook Parameter_Log ruler =normal, text="\r\t  Baseline averaging window (ms): \t" + num2str(1000*baselinewindow)
// Measure Input resistance for each trial; calculate & plot.
	//controlInfo /W=EvokThreshAcq_ControlPanel CalcIRCheck
	//EvThresh_CalcIRCheck=V_value
	print "EvThresh_CalcIRCheck = " + num2str(EvThresh_CalcIRCheck)
	controlInfo /W=EvokThreshAcq_ControlPanel DispHoldCurrCheck
	EvThresh_DispHoldCurrCheck=V_value
//	print "EvThresh_DispHoldCurrCheck = " + num2str(EvThresh_DispHoldCurrCheck)
	controlInfo /W=EvokThreshAcq_ControlPanel DispCmdVoltCheck
	EvThresh_DispCmdVoltCheck=V_value
//	print "EvThresh_DispCmdVoltCheck = " + num2str(EvThresh_DispCmdVoltCheck)
// if any of above, then create one window for all three measures:
	if ( (EvThresh_CalcIRCheck==1) || (EvThresh_DispHoldCurrCheck==1) || (EvThresh_DispCmdVoltCheck==1) )
		DoWindow /K Holding_parameters
		Display /W=(EvThresh_HoldParamDisplay_pos[0],EvThresh_HoldParamDisplay_pos[1],EvThresh_HoldParamDisplay_pos[2],EvThresh_HoldParamDisplay_pos[3])   as "Holding for " + Local_Basename
		DoWindow /C Holding_parameters
	endif
	if(EvThresh_CalcIRCheck)
		//print "Setting up for input resistance calculations", num2str(EvThresh_CalcIRCheck)
		Make/T/O/N=(EvThresh_NumSetRepeats) IRWave_Names
		string RunIRName = Local_basename + "_runIR"
		IRWave_Names[0]=Local_Basename  + "_IR"			// one for each set (local_basename includes set#)	
		Make/O/N=(EvThresh_NumLevels) $IRWave_Names[0]					// create waves for real-time analysis each set
		Make/O/N=(EvThresh_NumLevels*EvThresh_NumSetRepeats) $RunIRName
		DoWindow/F Holding_parameters
		AppendtoGraph /L $IRWave_Names[0]  
		Label left "Input Resistance (MOhms)"
		ModifyGraph axisEnab(left)={0,0.25}, axRGB(left)=(64768,0,0),tlblRGB(left)=(64768,0,0), alblRGB(left)=(64768,0,0)
		Modifygraph marker($IRWave_Names[0])=19,rgb($IRWave_Names[0])=(65000,0,0)
		SetAxis /A/E=1 left 
		Modifygraph  lblPos(left)=40
			Dowindow/K Running_IRDisplay
			Display/W=(EvThresh_HoldParamDisplay_pos[0],EvThresh_HoldParamDisplay_pos[1],EvThresh_HoldParamDisplay_pos[2],EvThresh_HoldParamDisplay_pos[3]) as "Running IR Display"
			Dowindow/C Running_IRDisplay
			Appendtograph/W=Running_IRDisplay  $RunIRName
			Modifygraph mode($RunIRName)=3,marker($RunIRName)=19,rgb($RunIRName)=(655000,0,0)
			WAVE runningIRValues=$RunIRName
			RunningIRValues=nan	// initialize as not a number
	endif
// Measure Holding current and actual voltage levels: 
// Create Window to plot it.
///HOLDING CURRENT:	
	DoWindow /F Holding_parameters
	if(EvThresh_DispHoldCurrCheck)
		//print "Setting up for holding current measures", num2str(EvThresh_DispHoldCurrCheck)
		Make/T/O/N=(EvThresh_NumSetRepeats) HCWave_Names
		HCWave_Names[0]=Local_Basename  + "_HC"					// one for each set (local_basename includes set#)
		Make/O/N=(EvThresh_NumLevels) $HCWave_Names[0]					// create waves for real-time analysis each set
		Appendtograph/W=Holding_parameters /R $HCWave_Names[0]
		Label right "Holding current (nA)"
		Modifygraph  marker($HCWave_Names[0])=16,rgb($HCWave_Names[0])=(0,12800,52224)	
		ModifyGraph axisEnab(right)={0.35,0.60},axRGB(right)=(0,12800,52224),tlblRGB(right)=(0,12800,52224),alblRGB(right)=(0,12800,52224)
		SetAxis /A/E=2 right		// sym around zero
		Modifygraph  lblPos(right)=40, zero(right)=2
	endif
/// VOLTAGE :	
	if(EvThresh_DispCmdVoltCheck)
		//print "Setting up for voltage measure", num2str(EvThresh_DispCmdVoltCheck)
		Make/T/O/N=(EvThresh_NumSetRepeats) VoltLevWave_Names	// one for each set (local_basename includes set#)						
		VoltLevWave_Names[0]=Local_Basename + "_VL"   
		Make/O/N=(EvThresh_NumLevels) $VoltLevWave_Names[0]					// create waves for real-time analysis each set
		AppendtoGraph/W= Holding_parameters /L=L2 $VoltLevWave_Names[0]
		Label L2 "Voltage (V)"
		Modifygraph  marker($VoltLevWave_Names[0])=17,rgb($VoltLevWave_Names[0])=(0,39168,0)		
		ModifyGraph axisEnab(L2)={0.70,0.95},axRGB(L2)=(0,39168,0),tlblRGB(L2)=(0,39168,0),alblRGB(L2)=(0,39168,0)
		SetAxis /A/E=1 L2	// autoscale from zero
		ModifyGraph freePos(L2)=0,  lblPos(L2)=50,zero(right)=2	
	endif
	if ( (EvThresh_CalcIRCheck==1) || (EvThresh_DispHoldCurrCheck==1) || (EvThresh_DispCmdVoltCheck==1) )
		ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
		ModifyGraph axisEnab(bottom)={0.05,0.95}
		Label bottom "Trials"
		ModifyGraph msize=3,mode=4,live=1
		Doupdate
	endif
/////////////////////////////	
	variable step_VL,step_HC
	variable temp_VLdelta,temp_HCdelta	
	variable Ns_mean, Ns_stdev
	variable tally
	tempwave0=0
	k=0			// loop variable for number of set repeats
	i=0  // loop variable for number of trials
	Notebook Parameter_Log ruler =normal, text="\r\r"
	do												// loop for each Set Iteration	
		// create waves for acquiring current & voltage data; create at beginning of each iteration & step Loop
		//print Local_Basename
		if(k>0)
			if ( (EvThresh_CalcIRCheck==1) || (EvThresh_DispHoldCurrCheck==1) || (EvThresh_DispCmdVoltCheck==1) )
				IRWave_Names[k]=Local_Basename  + "_IR"	// one for each set (local_basename includes set#)
				HCWave_Names[k]=Local_Basename  + "_HC"	
				VoltLevWave_Names[k]=Local_Basename + "_VL"  
				Make/O/N=(EvThresh_NumLevels) $IRWave_Names[k],$HCWave_Names[k],$VoltLevWave_Names[k]
				DoWindow/F Holding_parameters;	
				if(EvThresh_CalcIRCheck)
					AppendtoGraph /L /W=Holding_parameters $IRWave_Names[k]
					Modifygraph marker($IRWave_Names[k])=19,rgb($IRWave_Names[k])=(65000,0,0)
				endif
				if(EvThresh_DispHoldCurrCheck || EvThresh_CalcIRCheck)			// need for IR calc also
					AppendtoGraph /R /W=Holding_parameters $HCWave_Names[k]
					Modifygraph  marker($HCWave_Names[k])=16,rgb($HCWave_Names[k])=(0,12800,52224)	
				endif
				if(EvThresh_DispCmdVoltCheck || EvThresh_CalcIRCheck)				// need for IR calc also
					AppendtoGraph/R=L2 /W=Holding_parameters  $VoltLevWave_Names[k]	
					Modifygraph  marker($VoltLevWave_Names[k])=17,rgb($VoltLevWave_Names[k])=(0,39168,0)
				endif	
				ModifyGraph msize=3,mode=3,live=1
			endif
			// set up for PSC calculation:
			//for peak finding:
			If(stringmatch(NowMulticlampMode, "V-Clamp"))
				PSCWave_Names[k]=Local_Basename  + "_PSC"			// one for each set (local_basename includes set#)	
				minlevel = 2e-9		// minimum level to accept as peak, 2pA in Vclamp
			else
				PSCWave_Names[k]=Local_Basename  + "_PSP"	
				minlevel = 2e-3		// or 0.2mV  in Current clamp
			endif
			ScWave_names[k]=Local_Basename  + "_SC"	
			Noise_Names[k]=Local_Basename + "_Ns"
			Fail_Names[k]= Local_Basename + "_Fa"
			Make/O/N=(EvThresh_NumLevels) $PSCWave_Names[k],$Noise_Names[k],$Fail_Names[k],$ScWave_names[k]
			DoWindow /F Table1
			AppendToTable  $PSCWave_Names[k],$Noise_Names[k],$Fail_Names[k],$ScWave_names[k]
			DoWindow/F EvThresh_PSCDisplay;	
			AppendtoGraph /W=EvThresh_PSCDisplay $PSCWave_Names[k] vs  $SIUOutLevelsName
			Modifygraph  mode($PSCWave_Names[k])=3,live=1,rgb($PSCWave_Names[k])=(1,3,39321),marker($PSCWave_Names[k])=5
			ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
			DoUpdate
		endif
			
		Wave temp_IR = $IRWave_Names[k]
		Wave temp_psc = $PSCWave_Names[k]
		Wave temp_Ns = $Noise_Names[k]
		Wave temp_Fa = $Fail_Names[k]
		Wave temp_HC=$HCWave_Names[k]
		Wave temp_VL=	$VoltLevWave_Names[k]
		Wave temp_sc = $SCWave_Names[k]
		temp_psc=0
		temp_Ns=0
		temp_Fa=0
		temp_IR=nan
		temp_HC=nan
		temp_VL=nan
		temp_sc=nan
		if(  (Waveexists(temp_psc)==0)  ||   (Waveexists(temp_IR)==0)  ||  (Waveexists(temp_HC)==0) ||   (Waveexists(temp_VL)==0)||   (Waveexists(temp_Ns)==0) ||   (Waveexists(temp_Fa)==0) ||  (Waveexists(temp_sc)==0)  )
			print "temp_HC or temp_IR or temp_VL or temp_Fa or temp_Ns  or temp_psc does not exist"		
		endif
		j=0
		do
			If(stringmatch(NowMulticlampMode, "V-Clamp"))
				MonitorAcqNames_Wave[j][k]=Local_Basename + "_V" + num2str(j)			// in vclamp, input is current("A"), monitor is voltage ("V")
				InputAcqNames_Wave[j][k]=Local_Basename + "_A" + num2str(j)
			else
				MonitorAcqNames_Wave[j][k]=Local_Basename + "_A" + num2str(j)		// in iclamp, the reverse
				InputAcqNames_Wave[j][k]=Local_Basename + "_V" + num2str(j)
			endif
			duplicate /O tempwave0, $MonitorAcqNames_Wave[j][k]
			duplicate /O tempwave0, $InputAcqNames_Wave[j][k]

			j+=1
		while(j<EvThresh_numLevels)		// creates entire set of names at once for each set
		//Wave VoltAcqWave=$MonitorAcqNames_Wave[0]
		//Wave CurrAcqWave=$InputAcqNames_Wave[0]
		//  create window for real-time raw data display:
		DoWindow/K EvThresh_rawDataDisplay	
		Display /W=(EvThresh_rawDataDisplay_pos[0],EvThresh_rawDataDisplay_pos[1],EvThresh_rawDataDisplay_pos[2],EvThresh_rawDataDisplay_pos[3]) $InputAcqNames_Wave[0]  as   "Evoked PSC Acq waves: " + Local_Basename 
		If(stringmatch(NowMulticlampMode, "V-Clamp"))
			Label left "Current (nA)"
		else
			Label left "Voltage (V)"
		endif
		Label bottom "Time (sec)"
		//SetAxis/A // L2 -0.2,0
		x1=EvThresh_StimBuffer-EvThresh_interpulseinterval
		x2=x1+(EvThresh_numpulses+2)*EvThresh_interpulseinterval
		SetAxis bottom x1,x2
		Execute DoColorStyle
		Modifygraph  lblPos(left)=40,live=1		// positions the label of left axes properly
		doWindow /C EvThresh_rawDataDisplay	
		// Make variables to acquire a temperature measure, once at the beginning of each set.  
		variable TempGain = 0.1	// gain on the T2 output is 100mV/degC
		variable CurrentTempDegC
		//string TempAcqString = "TemperatureGrabWave,7,1"
		string TempAcqString = "TemperatureGrabWave,3"			//** need to fix to get right temperature probe channel on panel
		Make /O/N=100 TemperatureGrabWave
		SetScale /P x 0, (1/AcqResolution), "sec",  TemperatureGrabWave
		mysimpleAcqRoutine("",TempAcqString)
		TemperatureGrabWave/=TempGain
		CurrentTempDegC=mean(TemperatureGrabWave,-inf,inf)	
		///
		DoUpdate	
		j=0
		Notebook Parameter_Log ruler =subhead, text="\r  Beginning set # " + num2str(EvThresh_setnum) + " at " + time()
		Notebook Parameter_Log ruler =normal, text="\r\tRecording chamber temperature (T2) : \t" + num2str(CurrentTempDegC) + " deg C"
		do											// begin within set trials loop
			StartTicks=ticks
			print "Beginning trial # ", num2str(j)
			
			// send waves to nidaq
			//AcqString=MonitorAcqNames_Wave[j][k]+"," +num2str(Monitor_Channel)+ "," + num2str(Monitor_IndBoardGain)
			//AcqString+=";" +InputAcqNames_Wave[j][k]+"," +num2str(Input_Channel) + "," + num2str(Input_IndBoardGain)
			///  Errors here if channels are out of order (i.e. input channel is #1 followed by monitor channel  #0)  need code to order list.
		AcqString=InputAcqNames_Wave[j][k]+"," +num2str(Input_Channel) + ";" 
			AcqString+=MonitorAcqNames_Wave[j][k]+"," +num2str(Monitor_Channel) + ";" 
//			
		//	AcqString=VoltageAcqNames_Wave[k][j][i] +"," +num2str(Voltage_Channel)
		//	AcqString+=";" +currentAcqNames_Wave[k][j][i]+"," +num2str(Current_Channel) 
		//	
//			if(Input_Channel>Monitor_Channel)
//				Abort "Input channels should be in reverse order"
//			endif
//			if(DAC_CellOut_channel==-1)
//				WFOutString = OutStimNames_Wave[j] + "," + num2str(DAC_StimOut_Channel)
//				print "No IR test output selected in Nidaq board, running without it"
//			else
				if(DAC_StimOut_Channel>DAC_CellOut_Channel)	// Channels must be sent to NIDAQ in ascending order, e.g. 0 first, 1 second
						WFOutString=OuttoCellNames_Wave[j] + "," + num2str(DAC_CellOut_Channel)+ ";"
						WFOutString += OutStimNames_Wave[j] + "," + num2str(DAC_StimOut_Channel)+ ";"
				else
					WFOutString = OutStimNames_Wave[j] + "," + num2str(DAC_StimOut_Channel)+ ";"
					WFOutString+=OuttoCellNames_Wave[j] + "," + num2str(DAC_CellOut_Channel)+ ";"
				endif
			
			print "       passed acq  strings: " ,AcqString
			print "            passed wf  strings: " , WFOutString
			mySimpleAcqRoutine(WFOutString,AcqString)
			
	
			// save waves to hard drive
			CommandStr = "Save/O/C/P=EvThreshPath " +InputAcqNames_Wave[j][k] +","+MonitorAcqNames_Wave[j][k]
			Execute CommandStr	
			
				
				Wave MonitorAcqWave= $MonitorAcqNames_Wave[j][k]
				Wave InputAcqWave=$InputAcqNames_Wave[j][k]
		
			if( (Waveexists(MonitorAcqWave)==0)  ||  (Waveexists(InputAcqWave)==0) )
				print "MonitorAcqWave or InputAcqWave does not exist"
			endif	
		MonitorAcqWave/=Monitor_AmpGain
		InputAcqWave/=Input_AmpGain
		
			// display  raw voltage & current data		-->> raw data window
			if(j==0)
				DoWindow/K EvThresh_rawDataDisplay
				Display /W=(EvThresh_rawDataDisplay_pos[0],EvThresh_rawDataDisplay_pos[1],EvThresh_rawDataDisplay_pos[2],EvThresh_rawDataDisplay_pos[3]) $InputAcqNames_Wave[j][k]  as   "Evoked PSC Acq waves: " + Local_Basename 
				If(stringmatch(NowMulticlampMode, "V-Clamp"))
					Label left "Current (nA)"
				else
					Label left "Voltage (V)"
				endif
				Label bottom "Time (sec)"
				SetAxis bottom x1,x2
				Execute DoColorStyle
				Modifygraph  lblPos(left)=40,live=1		// positions the label of left axes properly
				doWindow /C EvThresh_rawDataDisplay
			else
				DoWindow/F EvThresh_rawDataDisplay
				appendtoGraph  InputAcqWave
			endif
			modifygraph rgb=(0,0,0)			
			variable y1
			//y1=mean(InputAcqWave,-inf,inf)
			y1=mean(InputAcqWave,InitStimTime-0.02,InitStimTime-0.002)  // measure baseline prior to stimulus (-20ms to -2ms)
			
			
			//print y1
			If(stringmatch(NowMulticlampMode, "V-Clamp"))			/////////////////////////////*************** setaxis left  individual graph
				SetAxis left  y1+EvThresh_yaxis1_VC, y1+EvThresh_yaxis2_VC		// nA
			else
				setaxis left y1+EvThresh_yaxis1_CC, y1+EvThresh_yaxis2_CC	// V
			endif
			// accumulate to one graph:			
			if(j==0)
				DoWindow /K EvThresh_allTracesDisplay
				Display/W=(EvThresh_allDataDisplay_pos[0],EvThresh_allDataDisplay_pos[1],EvThresh_allDataDisplay_pos[2],EvThresh_allDataDisplay_pos[3]) InputAcqWave as "Single Set Traces"
				Dowindow /C EvThresh_allTracesDisplay
			else
				Dowindow/F EvThresh_allTracesDisplay
				AppendtoGraph InputAcqWave
			endif
			Execute DoColorStyle
			
			If(stringmatch(NowMulticlampMode, "V-Clamp"))			/////////////////////////////*************** setaxis left  overlay graph
				SetAxis left  y1+EvThresh_yaxis1_VC, y1+EvThresh_yaxis2_VC		// nA
			else
				setaxis left y1+EvThresh_yaxis1_CC, y1+EvThresh_yaxis2_CC	// V
			endif
			//ModifyGraph rgb($InputAcqNames_Wave[j][k])=(0,0,0 )
			//ModifyGraph rgb($MonitorAcqNames_Wave[j][k])=(0,0,0 )
			DoUpdate			
			//REAL TIME ANALYSIS: AVERAGING voltage and current traces across set repeats:
			if(EvThresh_AverageCheck)	
				WAVE Sum_Inputwave=$tempWavesName_1[j]
				WAVE Avg_Inputwave=$tempwavesName_2[j]
				if ( (Waveexists(Sum_Inputwave)==0)   ||  (Waveexists(Avg_Inputwave)==0))
					print "  Sum_Curr or Avg_Curr does not exist"
				endif			
				Sum_Inputwave+=InputAcqWave		// k+1 should be number of set repeats;  provides running average
				Avg_Inputwave=Sum_Inputwave/(k+1)
				DoWindow/F EvThresh_AvgWaveDisplay
				ModifyGraph live=1
				If(stringmatch(NowMulticlampMode, "V-Clamp"))			/////////////////////////////*************** setaxis left  overlay graph
					SetAxis left  y1+EvThresh_yaxis1_VC, y1+EvThresh_yaxis2_VC		// nA
				else
					setaxis left y1+EvThresh_yaxis1_CC, y1+EvThresh_yaxis2_CC	// V
				endif
			endif			
			//REAL TIME ANALYSIS: Calculating Initial PSC amplitude, tally running average:				
			findStart=InitStimtime+Latency-EvThresh_LatencyWindow
			findEnd=InitStimtime+Latency+EvThresh_LatencyWindow
			baseline = mean(InputAcqWave, InitStimtime-baselinewindow,Initstimtime-0.0005)
			if(EvThresh_PkDirection==3)
				PkX=InitStimtime+Latency
			else
				if(EvThresh_PkDirection==1)
					findpeak/N/M= (-1*(minlevel))/Q/R=(findStart,findEnd) InputAcqWave
				else
					if(EvThresh_PkDirection==2)
						findpeak /N/M=(minlevel)/Q/R=(findStart,findEnd) InputAcqWave
					endif
				endif
				if(V_flag)
					pkx=InitStimtime+Latency
				else
					pkX=V_PeakLoc
				endif
			endif	
			temp_PSC[j]=mean(InputAcqWave,Pkx-(EvThresh_PkAverageWindow/2), Pkx+(EvThresh_PkAverageWindow/2))	- baseline
			temp_Ns[j]= mean(InputAcqWave, Nsx-(EvThresh_PkAverageWindow/2),Nsx+(EvThresh_PkAverageWindow/2))	- baseline// comparable 1ms wide noise measure
			WaveStats /Q /R = (Nsx-Latency,Nsx) InputAcqWave	// get the s.d. of the noise period across ~5ms - to be used to determine failures
			//baselineSD=V_sdev 			// baselineSD is a temporary variable
			if(abs(temp_PSC[j])> 3*abs(V_sdev))	// if the PSC is greater than 3xs.d. of baseline noise, count as event.
			//if(abs(temp_PSC[j])> 30)	//debugging option
				temp_Fa[j]=0			// failure? no
				temp_sc[j]=temp_psc[j]
			else
				temp_Fa[j]=1			// failure? yes   use 1's b/c failure rate is 0 for no failure
			endif
			//print  "PSC amplitude " + Num2str(j) + num2str( temp_PSC[j])
			//print "Noise amplitude" + Num2str(j) + num2str( temp_Ns[j])
			DoWindow/F EvThresh_PSCDisplay
			ModifyGraph live=1
			//REAL TIME ANALYSIS: Measure baseline holding current:
			If(stringmatch(NowMulticlampMode, "V-Clamp"))
				WAVE currwave= InputAcqWave
				WAVE voltwave= MonitorAcqWave
			else
				WAVE voltwave= InputAcqWave
				WAVE currwave= MonitorAcqWave
			endif
			if(EvThresh_DispHoldcurrCheck || EvThresh_CalcIRCheck)		// need to measure for IR calculation anyway
				temp_HC[j]=mean(currwave, 0.010,BeforeBuff-0.010)			// 10 ms from start to 10 ms before IR pulse
				print "Holding/measured current baseline", temp_HC[j]
				DoWindow /F Holding_parameters;ModifyGraph msize=2
			endif
			//REAL TIME ANALYSIS: Measure baseline voltage:
			if(EvThresh_DispCmdVoltCheck || EvThresh_CalcIRCheck)		// need to measure for IR calculation anyway
				temp_VL[j]=mean(voltwave, 0.010,BeforeBuff-0.010)		// 3 ms from start to 3 ms before IR pulse
				print  "Holding/measured voltage baseline",temp_VL[j]
				DoWindow /F Holding_parameters;ModifyGraph msize=2
			endif
			//REAL TIME ANALYSIS: Calculate & plot input resistance:			mV/nA = MOhm
			if(EvThresh_CalcIRCheck)	
						
				If(stringmatch(NowMulticlampMode, "V-Clamp"))		// measure current step, Voltage step is given by IR amplitude
					step_HC = mean(currwave, BeforeBuff+EvThresh_IRdur-0.005,BeforeBuff+EvThresh_IRdur-0.001)	
					temp_HCdelta=( step_HC - temp_HC[j] )	// if in volt clamp, measure current step, in nA
					temp_VLdelta= EvThresh_IRamp	// voltage is step applied
				else
						// measure voltage step, current step is given by IR amplitude
					step_VL =mean(voltwave, BeforeBuff+EvThresh_IRdur-0.005,BeforeBuff+EvThresh_IRdur-0.001 )
					temp_VLdelta=( step_VL-temp_VL[j])   // convert from V to mV
					temp_HCdelta = EvThresh_IRamp		// if in current clamp, set to intended current step  (can't accurately measure small current step with monitor output
				endif
				temp_IR[j]=1000*temp_VLdelta/temp_HCdelta		// 1000*V/nA= MOhms
				runningIRValues[tally]=temp_IR[j]
				print "Volt step, " , num2str(temp_VLdelta)," , Current step, ", num2str(temp_HCdelta)
				print "  Input resistance, " , num2str(temp_IR[j])
				DoWindow/F Holding_parameters;	Doupdate
				ModifyGraph msize=2
				DOwindow/F running_IRDisplay
//				if(tally==3)
//					variable IRav=mean(RunningIRVAlues,0,3)
//					setaxis left IRav-(0.2*IRav),IRav+(0.2*IRav)
//					modifygraph grid(left)=1
//				endif
				Doupdate
			endif
			do									//waste time between runs according to ISI
				elapsedTicks=ticks-StartTicks
			while((elapsedTicks/60.15)<EvThresh_TrialISI)	
			//print "time between " + num2str(elapsedTicks/60.15)
			j+=1
			tally+=1
		while(j<EvThresh_numLevels)
		// tally up averages :
		sum_PSC += temp_PSC			
		av_PSC=  sum_PSC/(k+1)	
		
		sum_Ns += temp_Ns		
		av_Ns=  sum_Ns/(k+1)
		 
		sum_Fa+=temp_Fa
		Av_Fa=sum_Fa/(k+1)	
		/////////////////////////
		//sum_sc+=temp_sc	// sum of all successes; problem with summing nan waves... maybe should set to zero
		j=0
		do
			if(temp_sc[j]!=nan)
				 sum_sc[j]+=temp_sc[j]
			endif
			 j+=1
		while(j<EvThresh_numLevels)
		j=0
		do
			
			av_sc[j]=sum_sc[j]/(k+1-sum_Fa[j])	//k+1 : number of sets so far; sum_Fa[j]: number of failures so far for jth level; difference provides number of successes
			j+=1
		while(j<EvThresh_numLevels)
		
		If(stringmatch(NowMulticlampMode, "V-Clamp"))
			Notebook  Parameter_Log ruler =normal, text="\r\tAcquired input current traces:\t" + InputAcqNames_Wave[0]+ "-" + num2str(EvThresh_numLevels-1)
			Notebook  Parameter_Log ruler =normal, text="\r\tAcquired monitor voltage traces:\t" +MonitorAcqNames_Wave[0] +"-" + num2str(EvThresh_numLevels-1)
		else
			Notebook  Parameter_Log ruler =normal, text="\r\tAcquired input voltage traces:\t" + InputAcqNames_Wave[0]+ "-" + num2str(EvThresh_numLevels-1)
			Notebook  Parameter_Log ruler =normal, text="\r\tAcquired monitor current traces:\t" +MonitorAcqNames_Wave[0] +"-" + num2str(EvThresh_numLevels-1)
		endif
		// Save per set analysis waves:
		if(EvThresh_CalcIRCheck)
			CommandStr = "Save/O/C/P=EvThreshPath "+ IRWave_Names[k] 	// Save the acquired wave in the home path right away!
			Execute CommandStr
			Notebook  Parameter_Log ruler =normal, text="\r\tInput Resistance measures for this set:\t" + IRWave_Names[k]
			WaveStats/Q $IRWave_Names[k]
			Notebook Parameter_Log ruler =normal, text="\r\t  Average Input Resistance (MOhm): " + num2str(V_avg) + " +/-" + num2str(V_sdev) + "  s.d."
			print "\r\t  Average Input Resistance (MOhm): " + num2str(V_avg) + " +/-" + num2str(V_sdev) + "  s.d."
		endif
		if(EvThresh_DispHoldCurrCheck)
			CommandStr = "Save/O/C/P=EvThreshPath "+ HCWave_Names[k] 	// Save the acquired wave in the home path right away!
			Execute CommandStr
			Notebook  Parameter_Log ruler =normal, text="\r\tHolding current measures for this set:\t" +  HCWave_Names[k] 
			WaveStats /Q $HCWave_Names[k] 
			Notebook Parameter_Log ruler =normal, text="\r\t   Average Holding current (nA): " + num2str(V_avg*10e+9) + " +/-" + num2str(V_sdev*10e+9) + "  s.d."
		endif
		if(EvThresh_DispCmdVoltCheck)
			CommandStr = "Save/O/C/P=EvThreshPath "+ VoltLevWave_Names[k] 	// Save the acquired wave in the home path right away!
			Execute CommandStr
			Notebook  Parameter_Log ruler =normal, text="\r\tBaseline voltage measures for this set:\t" + VoltLevWave_Names[k] 
			WaveStats/Q   $VoltLevWave_Names[k] 	 
			Notebook Parameter_Log ruler =normal, text="\r\t   Average Baseline voltage (mV): " + num2str(V_avg*1000) + " +/-" + num2str(V_sdev*1000) + "  s.d."
		endif
		
		CommandStr = "Save/O/C/P=EvThreshPath "+ PSCWave_Names[k] 	// Save the acquired wave in the home path right away!
		Execute CommandStr
		Notebook  Parameter_Log ruler =normal, text="\r\tPSC/PSP measure for this set:\t" +  PSCWave_Names[k]
		CommandStr = "Save/O/C/P=EvThreshPath "+ SCWave_Names[k] 	// Save the acquired wave in the home path right away!
		Execute CommandStr
		Notebook  Parameter_Log ruler =normal, text="\r\tSucces/potency measure for this set:\t" +  SCWave_Names[k]
		Notebook  Parameter_Log ruler =normal, text="\r\tFailures measure for this set:\t" +  Fail_Names[k]	
		Notebook  Parameter_Log ruler =normal, text="\r\t\t\t\t\tCompleted Set #" + num2str(EvThresh_SetNum) + " at " + time()
		/////	
		Notebook  Parameter_Log ruler =normal, text="\r"
		string text1 = "Evoked Threshold Acquisition & analysis for " + local_Basename
		EvThresh_SetNum+=1			// update set#
		Local_Basename			=	"EvTh_" +baseName + "s" + num2str(EvThresh_SetNum)	// recalculate basename
		k+=1	
		DoWindow/F Holding_parameters
		//Modifygraph rgb=(43520,43520,43520)	// gray out previous sets
	while(k<EvThresh_numsetRepeats)	
	
	// plot individual trials by stim level
	LeftPos-=100
	Make /T/O/n=(EvThresh_numlevels) EvTh_plotWinNames
	j=0
	do
		EvTh_plotWinNames[j]="EvThWin_" + inputAcqNames_Wave[j][k]
		k=0
		do
			if (k==0)
				Display /W=(LeftPos,TopPos+Graph_Height+Graph_grout,LeftPos+graph_Width,TopPos+2*Graph_Height+Graph_grout) $InputAcqNames_Wave[j][k]
				Textbox /E/A=MT/F=0 InputAcqNames_Wave[j][k]	
				Dowindow/C $EvTh_plotWinNames[j]
			else
				AppendtoGraph  $InputAcqNames_Wave[j][k]
			endif
			LeftPos+=2
			k+=1
		while(k<EvThresh_numsetRepeats)
		
		If(stringmatch(NowMulticlampMode, "V-Clamp"))		
				SetAxis left  y1+EvThresh_yaxis1_VC, y1+EvThresh_yaxis2_VC		// nA
			else
				setaxis left y1+EvThresh_yaxis1_CC, y1+EvThresh_yaxis2_CC	// V
			endif
			
		SetAxis bottom x1,x2
		j+=1
	while(j<EvThresh_numlevels)
	// Save trace averages:
	if(EvThresh_AverageCheck)
		Notebook  Parameter_Log ruler =normal, text="\r\t\tAverages of input traces per level, across sets:\t"
		i=0
		do
			CommandStr = "Save/O/C/P=EvThreshPath "+tempwavesName_2[i] 
			Execute commandStr
			Notebook  Parameter_Log ruler =normal, text="\r\t\t  " + tempwavesName_2[i] 
			i+=1
		while(i<EvThresh_NumLevels)
	endif
	Notebook  Parameter_Log ruler =normal, text="\r\tStimulus level wave  :\t" + SIUOutLevelsName
	Notebook  Parameter_Log ruler =normal, text="\r\tAverage PSC wave across sets:\t  " + av_PSCName
	Notebook  Parameter_Log ruler =normal, text="\r\t                        +- error wave:\t  " +err_PSCName
		Notebook  Parameter_Log ruler =normal, text="\r\tAverage success/potency wave across sets:\t  " + av_SCName
	Notebook  Parameter_Log ruler =normal, text="\r\t                        +- error wave:\t  " +err_SCName

	Notebook  Parameter_Log ruler =normal, text="\r\tFailure rate wave :\t  " +av_FAName
	// Recalculate Pk averages +- Stdev after all sets have run
	string PSCwaveList  = ConvertTextWavetoList(PSCWave_Names)
	variable ErrorType=1	// 0 = none; 1 = S.D.; 2 = Conf Int; 3 = Standard Error
	Variable ErrorInterval=1 // if ErrorType == 1, # of S.D.'s; ErrorType == 2, Conf. Interval
	string AveName= av_PSCName
	string ErrorName=err_PSCName
	fWaveAverage(PSCwaveList, ErrorType, ErrorInterval, AveName, ErrorName)  // overwrites running average
	DOwindow /F EvThresh_PSCDisplay
	//ErrorBars /L=2/T=2  $av_PSCName, Y, wave=($err_PSCname,$err_PSCName)
	Dowindow /k EvThresh_Table2
	Edit/W=(EvThresh_Table2_pos[0],EvThresh_Table2_pos[1],EvThresh_Table2_pos[2],EvThresh_Table2_pos[3]) EvThresh_StimOutputLevels,$av_PscName, $err_PSCName,$av_FaName,$av_NsName
	Dowindow /C EvThresh_Table2
	
	// Recalculate success averages +- Stdev after all sets have run
	string SCwaveList  = ConvertTextWavetoList(SCWave_Names)
	AveName= av_SCName
	ErrorName=err_SCName
	fWaveAverage(SCwaveList, ErrorType, ErrorInterval, AveName, ErrorName)  // overwrites running average
	DOwindow /F EvThresh_PSCDisplay
	ErrorBars /L=2/T=2  $av_SCName, Y, wave=($err_SCname,$err_SCName)
	DOwindow /F EvThresh_Table2
	appendtotable $av_SCName,$err_SCName
	// Write average data points to notebook:
	WAVE SIU = $SIUOutLevelsName
	WAVE avpsc=$av_PSCName
	WAVE errpsc=$err_PSCname
	WAVE avsc=$av_SCName
	WAVE errsc=$err_SCname
	WAVE fa=$av_FaName
	i=0
	do
		Notebook  Parameter_Log ruler =normal, text="\r\r Stim Level = " + num2str(SIU[i])
		Notebook  Parameter_Log ruler =normal, text=" \t   Amplitude = " +  num2str(avpsc[i]) + " +- " + num2str(errpsc[i])
		Notebook  Parameter_Log ruler =normal, text=" \t   Potency (excl fail) = " +  num2str(avsc[i]) + " +- " + num2str(errsc[i])
		Notebook  Parameter_Log ruler =normal, text="\t    Failure Rate = " + num2str(fa[i])
		i+=1
	while(i<EvThresh_NumLevels)	
	EndingSetNumber=StartingSetNumber+k

	EvThresh_nextAvg+=1							// update variable so not to overwrite previous averages
	EvThresh_AvgBasename		=	"EvTh_" + baseName  +"_avg" +num2str(EvThresh_nextAvg)	// update name
	
	///////////Create Layouts of graphs & tables:
	variable LO_left=80
	variable LO_top=50
	variable LO_width=300
	variable LO_height=370
	////// don't do first three layouts now
	if(0)
	Dowindow/K EvThresh_Layout0
	NewLayout  /P=portrait/w=(LO_left,LO_top,LO_left+LO_width,LO_top+LO_height) 
	Modifylayout units=1
	Appendlayoutobject /F=0 graph EvThresh_rawDataDisplay   //"/R" positions the object in layout; at 100%, total page is 0,0 to 8.5,11 (portrait)
	Appendlayoutobject /F=0 graph EvThresh_AvgWaveDisplay
	Appendlayoutobject/F=0 graph EvThresh_allTracesDisplay
	Execute "Tile/A=(3,1)/W=(100,100,500,600)"
	TextBox/A=MT /E/F=0/A=MT/X=0.00/Y=0.00 text1
	Dowindow/C EvThresh_Layout0
	Dowindow/K EvThresh_Layout1
	LO_left+=20
	LO_top+=20
	NewLayout  /P=portrait /w=(LO_left,LO_top,LO_left+LO_width,LO_top+LO_height) 
	Appendlayoutobject /F=0 graph Holding_parameters
	Appendlayoutobject /F=0 graph EvThresh_OutputWavesDisplay
	Execute "Tile/A=(3,1)/W=(100,100,500,750)"
	TextBox /E/F=0/A=MT/X=0.00/Y=0.00 text1
	Dowindow/C EvThresh_Layout1	
	Dowindow/K EvThresh_Layout2
	LO_left=20
	LO_top=80
	LO_width=300
	LO_height=420
	NewLayout   /P=portrait/w=(LO_left,LO_top,LO_left+LO_width,LO_top+LO_height) 
	Appendlayoutobject /F=0 graph EvThresh_PSCDisplay
	Appendlayoutobject /F=0 graph EvThresh_AvgWaveDisplay
	Appendlayoutobject table EvThresh_Table2
	ModifyLayout columns(EvThresh_Table2)= 6,rows(EvThresh_Table2)=EvThresh_numlevels
	Execute "Tile/A=(3,1)/W=(100,100,500,750)"
	TextBox /A=MT/E/F=0/X=0.00/Y=0.00 text1
	//ModifyLayout mag=1
	Dowindow/C EvThresh_Layout2
	
		//  do layout 3 below now:
	
	Dowindow/K EvThresh_Layout3
	LO_left+=100
	NewLayout  /P=portrait /w=(LO_left,LO_top,LO_left+LO_width,LO_top+LO_height) 
	j=0
	do			
		Appendlayoutobject /F=0 graph $EvTh_plotWinNames[j]		
		j+=1
	while(j<EvThresh_numlevels)
	Appendlayoutobject /F=0 graph EvThresh_AvgWaveDisplay
	Execute "Tile/A=(3,3)/W=(80,100,550,550)"
	
	Appendlayoutobject /F=0/R=(100,550,500,720) graph EvThresh_PSCDisplay
	TextBox /A=MT/E/F=0/X=0.00/Y=0.00 text1
	//ModifyLayout mag=1
	Dowindow/C EvThresh_Layout3
	//DoWindow/B EvThresh_layout0;DoWindow/B EvThresh_layout1;DoWindow/B EvThresh_Table1
	//DoWindow/B EvThresh_layout2;DoWindow/B EvThresh_Layout3
	endif	
	DoWindow/F EvThresh_PSCDisplay
	Dowindow/F  EvThresh_Table2
	DoWindow/F EvThresh_AvgWaveDisplay
	// END OF MACRO CLEAN-UP:
	print "Cleaning up"
	EvThresh_Basename= Local_Basename			// update global FI basename
	KillWaves/Z tempWave0,temp_psc,temp_Ns,temp_Fa,temp_IR,temp_HC,temp_VL	// kill output waves & all other temporary & non-essential waves
	i=0
	do
		KillWaves/Z $OuttocellNames_Wave[i]
		i+=1
	while(i<EvThresh_numsetRepeats)
	do	
		KillWaves/Z $tempWavesName_1[i]
		i+=1
	while(i<EvThresh_numlevels)
	killwaves /Z sum_PSC,sum_Fa,sum_Ns
	KillWaves/Z EvThresh_OutputWavesDisplay_pos,EvThresh_VoltDisplay_pos,EvThresh_HoldCurrDisplay_pos
	KillWaves/Z InputAcqNames_Wave,VoltLevWave_Names,OuttocellNames_Wave
	killwaves /Z IRWave_Names,HCWave_Names,VLWave_Names,TemperatureGrabWave
	killWaves/Z EvThresh_OutputWaves_pos,EvThresh_HoldCurrDisplay,EvThresh_VoltDisplay,EvThresh_rawDataDisplay_pos,EvThresh_InpResDisplay_pos
	SetDataFolder root:			// return to root 
	Notebook Parameter_Log text="\r\r  Completed run:\tTime: "+Time()+"\r\r"
	
	Notebook  Parameter_Log ruler =normal, text="\r\r"
end		


	

Function EvTh_VoltMonPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Voltage_Monitor =  root:EvokThresh:Voltage_Monitor
	Voltage_Monitor=popstr
	print "Changing EvokThresh Voltage_Monitor to", Voltage_Monitor
End

Function EvTh_CurrMonPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Current_Monitor =  root:EvokThresh:Current_Monitor
	Current_Monitor=popstr
	print "Changing EvokThresh Current_Monitor to", Current_Monitor
End

Function EvTh_InputSigPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Input_signal =  root:EvokThresh:Input_signal
	Input_signal=popstr
	print "Changing EvokThresh Input_signal to", Input_signal
End

Function EvTh_OutStimSigPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR OutputStim_Signal =  root:EvokThresh:OutputStim_Signal
	OutputStim_Signal=popstr
	print "Changing EvokThresh OutputStim_Signal to", OutputStim_Signal
End

Function EvTh_CellOutSigPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR OutputCell_signal =  root:EvokThresh:OutputCell_signal
	OutputCell_signal=popstr
	print "Changing EvokThresh OutputCell_signal to", OutputCell_signal
End

function EvTh_UpdatePeakDir(ctrlname,popnum,popstr) : PopupMenucontrol
	string ctrlname
	variable popnum
	string popstr
	NVAR EvThresh_PkDirection = root:EvokThresh:EvThresh_PkDirection
	EvThresh_PkDirection=popnum
	print "Changing pk directon to " num2str(EvThresh_PkDirection)
end

Function EvTh__BiphasicCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvThresh_Biphasic =  root:EvokThresh:EvThresh_Biphasic
	EvThresh_Biphasic = checked
	print "Changing biphasic check to " num2str(EvThresh_Biphasic)
End

Function EvTh_InvertStimCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvThresh_InvertStim =  root:EvokThresh:EvThresh_InvertStim
	EvThresh_InvertStim = checked
	print "Changing invert check to " num2str(EvThresh_InvertStim)
End

Function EvThresh_AvgCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvThresh_AverageCheck =  root:EvokThresh:EvThresh_AverageCheck
	EvThresh_AverageCheck = checked
	//print "Changing avg check to " num2str(EvThresh_AverageCheck)
End

Function EvThresh_DispHoldCurrCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvThresh_DispHoldCurrCheck =  root:EvokThresh:EvThresh_DispHoldCurrCheck
	EvThresh_DispHoldCurrCheck = checked
	//print "Changing display holding check to " num2str(EvThresh_DispHoldCurrCheck)
End

Function EvThresh_DispCmdVoltCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvThresh_DispCmdVoltCheck =  root:EvokThresh:EvThresh_DispCmdVoltCheck
	EvThresh_DispCmdVoltCheck = checked
	//print "Changing display command voltage check to " num2str(EvThresh_DispCmdVoltCheck)
End

Function EvThresh_CalcIRCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvThresh_CalcIRCheck =  root:EvokThresh:EvThresh_CalcIRCheck
	EvThresh_CalcIRCheck = checked
	//print "Changing RI calculate check to " num2str(EvThresh_CalcIRCheck)
End

function Kill_EvThresh_windows()
	DoWindow/K EvThresh_rawDataDisplay;
	DoWindow/K Holding_Parameters
	DoWindow/K EvThresh_InpResDisplay;
	DoWindow /K EvThresh_HoldCurrDisplay;
	DoWindow /K EvThresh_VoltDisplay
	Dowindow/K EvThresh_OutputWavesDisplay
	Dowindow/K EvThresh_allTracesDisplay
	Dowindow/K EvThresh_layout0
	Dowindow/K EvThresh_layout1
	Dowindow/K EvThresh_layout2
	Dowindow/K EvThresh_Layout3
	DoWindow/K EvThresh_AvgWaveDisplay
	DoWindow/K EvThresh_PSCDisplay
	DoWindow/K EvThresh_Table1
	DoWindow/K EvThresh_Table2
	DOwindow/K Running_IRDisplay
	WAVE/Z/T EvTh_plotWinNames =  root:EvokThresh:EvTh_plotWinNames
	NVAR/Z EvTh_numlevels=  root:EvokThresh:EvThresh_numlevels
	if( NVAR_exists(EvTh_numlevels) && Waveexists(EvTh_plotWinNames)  )
		string name
		variable i=0
		do
			name=EvTh_plotWinNames[i]
			DoWindow/K $name
			print "killing " + name
			i+=1
		while(i<EvTh_numlevels)
	endif
	 	
end
	


Function EvTh_SecondaryPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Monitor_Signal =  root:EvokThresh:Monitor_Signal
	Monitor_Signal=popstr
	print "Changing EvokThresh Monitor Signal", Monitor_Signal
End
