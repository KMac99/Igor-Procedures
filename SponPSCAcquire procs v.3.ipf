#pragma rtGlobals=1		// Use modern global access method.
//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\WavetoList procs"
#include  "C:\Documents and Settings\All Users\Documents\Igor Shared Procedures\WavetoList procs"
#include <Waves Average>
/////SponPSCAcquire procs v.3.ipf
/////  last updated 4/16/03  to accomodate Axoclamp & signal selection
// Updated 11jan2015 to be compatible with Multiclamp amplifiers and Windows7.


Menu "Initialize Procedures"
	"Initialize SponPSC Acq Parameters",Init_SponPSC_AcqControlPanel()
end

Menu "Kill Windows"
	"Kill SponPSC Acq Graphs",Kill_SpPSC_windows()
end

Proc Init_SponPSC_AcqControlPanel()
	// Check to see whether Globals Folder exists (i.e., that the InitializeDataAcquisition procedure 
	// has been run & common global variables exist
	if( DataFolderExists("root:DataAcquisitionVar"))	
		String dfSave=GetDataFolder(1)
		NewDataFolder /O/S root:SponPsc		// Create folder for FI variables
		DoWindow/K SpPSC_rawDataDisplay
		DoWindow/K SpPSC_InpResDisplay
		DoWindow /K SpPSC_HoldCurrDisplay
		DoWindow /K SpPSC_VoltDisplay
		KillWaves /a/z								// clean out folder & start from scratch
		killvariables /a/z		
		killstrings /a/z
		String /G  Voltage_Signal = "10Vm"	// string to be matched to find voltage channel
		String /G  current_Signal="ScaledOutput"		// string to be matched to find current channel
		String  /G Output_Signal = "Ext Command (front)"			// string to be matched to find DAC output to drive current step 
		variable /G 	SpPSC_CmdVolt					=  0	// command voltage,V (absolute)
		variable /G SpPSC_InpResPulse_AmpVC		=	-0.01	// input resistance test pulse, V (e.g. -5mV)
		variable /G SpPSC_InpResPulse_AmpIC		=	-0.00005	// input resistance test pulse, A (e.g. -0.05nA)
		variable /G SpPSC_InpResPulse_Dur		=	0.020		// test pulse duration, sec (e.g., 10ms)
		variable /G SpPSC_AcqLength		= 	30		// total length of acquisition wave, sec
		Variable /G SpPSC_TrialISI				=   31		// seconds between steps
		variable /G SpPSC_CalcIRCheck			=	1		// Calculate real-time Input resistance ?
		variable /G SpPSC_DispHoldCurrCheck	=	1		// measure & display holding current
		variable /G SpPSC_DispCmdVoltCheck	=	1		// measure & display real voltage
		Variable /G SpPSC_RepeatCheck		=	1		// Repeat sets?
		Variable/G SpPSC_NumTrialRepeats		=	10	// number of times to repeat trials within  a set
		Variable /G SpPSC_NumSetRepeats		=	1		// number of times to repeat sets
		Variable /G SpPSC_SetNum			=	0		// Label each set 
		String 	/G SpPSC_Basename			:=	"sPSC_" +root:DataAcquisitionVar:baseName + "s" + num2str(SpPSC_setnum)	// Acquisition waves basename
		Variable /G ymin_VC	=   0.15				// nA, ymin = meanlevel-ymin_VC
		Variable /G ymax_VC	=   0.05				// nA, ymax = meanlevel +ymax_VC
		Variable /G ymin_IC	=   0.005				// V, ditto in current clamp
		Variable /G ymax_IC	=  0.015				// V
		Execute "SponPSCAcq_ControlPanel()"		
		SetDataFolder dfSave
		SaveExperiment
		
		NewPath /C/M="Choose folder for Spontaneous PSC files"/O/Q/Z SponPath
	else
		Print "You must first initialize global variables with procedure 'InitializedDataAcquisition()' "
	endif
end

function CreateSponPath()
	SVAR basenameStr = root:DataAcquisitionVar:basename
	print basenameStr
	string exptPathStr = "C:Data:" + basenameStr +"SponPSC"
	Newpath SponPath, exptPathStr
end

Window SponPSCAcq_ControlPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(330,149,818.25,394.25)
	ModifyPanel cbRGB=(51664,44236,58982)
	ShowTools
	SetDrawLayer UserBack
	SetDrawEnv fillpat= 15,fillfgc= (65535,65532,16385)
	DrawRRect 11,4,427,37
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 33,31,"Spontaneous PSC Acquisition Control Panel"
	DrawLine 76,62,370,62
	DrawLine 73,137,367,137
	DrawLine 80,166,374,166
	SetVariable SpPSC_BasenameSetVar,pos={13,42},size={265,16},title="Acquisition Waves Basename"
	SetVariable SpPSC_BasenameSetVar,limits={-Inf,Inf,1},value= root:SponPsc:SpPSC_Basename
	SetVariable SetRepeatSetVar,pos={19,113},size={206,16},title="Number of times to repeat set :   "
	SetVariable SetRepeatSetVar,limits={1,100,1},value= root:SponPsc:SpPSC_NumSetRepeats
	SetVariable SetNumSetVar,pos={294,42},size={118,16},title="Current Set #"
	SetVariable SetNumSetVar,limits={-Inf,Inf,1},value= root:SponPsc:SpPSC_SetNum
	Button SpPSC_AcquireButton,pos={18,172},size={96,43},proc=Acq_SpPSC_data,title="Acquire"
	PopupMenu SelectOutSignalPopup,pos={136,216},size={260,21},title="Command Output Signal"
	PopupMenu SelectOutSignalPopup,mode=2,popvalue="Ext Command (front)",value= #"\"_none_;Ext Command (front);Ext Command (rear);AxoClamp ME1ExtCmd;AxoClamp VCCmd\""
	PopupMenu SelectInputSignalPopup,pos={136,171},size={209,21},proc=Sp_CurrMonPopMenuProc,title="Current Input Signal"
	PopupMenu SelectInputSignalPopup,mode=2,popvalue="ScaledOutput",value= #"\" _none_;ScaledOutput;I output;AxCl_Iout\""
	PopupMenu SelectVoltInputSignalPopup,pos={137,193},size={173,21},proc=Sp_VoltMonPopMenuProc,title="Voltage Input Signal"
	PopupMenu SelectVoltInputSignalPopup,mode=3,popvalue="10Vm",value= #"\"_none_;ScaledOutput;10Vm;AxCl_10Vm\""
	SetVariable TrialISISetVar,pos={235,91},size={135,16},title="Trial ISI (sec)      "
	SetVariable TrialISISetVar,limits={0.1,60,0.1},value= root:SponPsc:SpPSC_TrialISI
	CheckBox CalcIRCheck,pos={9,145},size={151,14},disable=2,proc=SpPSC_CalcIRCheckProc,title="Calculate Input Resistance?"
	CheckBox CalcIRCheck,value= 1
	CheckBox DispHoldCurrCheck,pos={167,144},size={134,14},disable=2,proc=SpPSC_DispHoldCurrCheckProc,title="Display Holding Current?"
	CheckBox DispHoldCurrCheck,value= 1
	CheckBox DispCmdVoltCheck,pos={311,143},size={138,14},disable=2,proc=SpPSC_DispCmdVoltCheckProc,title="Display baseline voltage?"
	CheckBox DispCmdVoltCheck,value= 1
	SetVariable AcqLengthSetVar,pos={18,71},size={180,16},title="Length per trial (sec)"
	SetVariable AcqLengthSetVar,limits={0.001,100,0.5},value= root:SponPsc:SpPSC_AcqLength
	SetVariable TrialRepeatSetVar,pos={18,91},size={206,16},title="Number of trial repeats per set :"
	SetVariable TrialRepeatSetVar,limits={1,100,1},value= root:SponPsc:SpPSC_NumtrialRepeats
	SetVariable CmdVoltSetVar,pos={274,69},size={175,16},title="Command voltage (V)"
	SetVariable CmdVoltSetVar,limits={-0.2,0.2,0.01},value= root:SponPsc:SpPSC_CmdVolt
EndMacro

Function SpPSC_DispHoldCurrCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR SpPSC_DispHoldCurrCheck =  root:SponPSC:SpPSC_DispHoldCurrCheck
	SpPSC_DispHoldCurrCheck = checked
	print "Changing display holding check to " num2str(SpPSC_DispHoldCurrCheck)
End

Function SpPSC_DispCmdVoltCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR SpPSC_DispCmdVoltCheck =  root:SponPSC:SpPSC_DispCmdVoltCheck
	SpPSC_DispCmdVoltCheck = checked
	print "Changing display command voltage check to " num2str(SpPSC_DispCmdVoltCheck)
End

Function SpPSC_CalcIRCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR SpPSC_CalcIRCheck =  root:SponPSC:SpPSC_CalcIRCheck
	SpPSC_CalcIRCheck = checked
	print "Changing IR calculate check to " num2str(SpPSC_CalcIRCheck)
End

function Kill_SpPSC_windows()
	DoWindow/K SpPSC_rawDataDisplay;
	DoWindow/K SpPSC_InpResDisplay;
	DoWindow /K SpPSC_HoldCurrDisplay;
	DoWindow /K SpPSC_VoltDisplay
	Dowindow/K SpPSC_OutputWavesDisplay
	Dowindow/K SpPSC_allTracesDisplay
	Dowindow/K SpPSC_layout
end

Function Sp_VoltMonPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Voltage_Signal =  root:SponPSC:Voltage_Signal
	Voltage_Signal=popstr
	print "Changing SponPSC Voltage_Signal to", Voltage_Signal
End

Function Sp_CurrMonPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Current_Signal =  root:SponPSC:Current_Signal
	Current_Signal=popstr
	print "Changing SponPSC Current_Signal to", Current_Signal
End

Function Sp_InputSigPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR Output_signal =  root:SponPSC:Output_signal
	Output_signal=popstr
	print "Changing SponPSC Output_signal to", Output_signal
End



function Acq_SpPSC_data(ctrlname) 		: ButtonControl
	string ctrlname
	//// Make sure the experiment is saved and therefore named
	if (StringMatch(IgorInfo(1),"Untitled"))	
		SetDataFolder root:
		Print "\tAborting -- experiment not saved!"
		Abort "You'd better save your experiment first!"
	endif
	Kill_SpPSC_windows()	
	
	string dfsave=GetDataFolder(1)

		print "Starting Spon Acq"
	SetDataFolder root:SponPSC	
	
	// updated 2015
	String Monitor_Signal = "SecondaryOutCh1"	// string to be matched to find secondary channel
	String Input_Signal= "PrimaryOutCh1"		// string to be matched to find input channel
	String OutputCell_Signal = "Command"		// string to be matched to find DAC output to drive current step 
	String OutputStim_Signal = "Extracellular SIU1"	
	SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
	//
	variable ymin,ymax
	NVAR ymin_VC	=   root:SponPSC:ymin_VC
	NVAR ymin_IC	=   root:SponPSC:ymin_IC
	NVAR ymax_VC	=   root:SponPSC:ymax_VC
	NVAR ymax_IC	=   root:SponPSC:ymax_IC
	SVAR Voltage_Signal =  root:SponPSC:Voltage_Signal	// string to be matched to find voltage channel
	SVAR current_Signal=  root:SponPSC:current_Signal	// string to be matched to find current channel
	SVAR Output_Signal =  root:SponPSC:Output_Signal			// string to be matched to find DAC output to drive current step 
//	SVAR Current_AxClMode 	=root:NIDAQBoardVar:Current_AxClMode
//	NVAR  Current_AxClGain	=root:NIDAQBoardVar:Current_AxClGain
	
	
	String AcqString, WFOutString
	string InputWavesName
	String CommandStr
	variable err
	variable StartTicks,elapsedTicks
	Variable BeforeBuff = 0.100	//  time before test pulse , sec
	variable StartingSetNumber,EndingSetNumber
	variable i=0
	Variable j=0
	variable k=0
	Variable LeftPos=50					// variables for positioning graph windows for this module
	Variable TopPos=50
	Variable Graph_Height=100
	variable Graph_Width = 300
	variable Graph_grout = 25
	Make/N=4/O SpPSC_rawDataDisplay_pos,SpPSC_InpResDisplay_pos,SpPSC_HoldCurrDisplay_pos,SpPSC_VoltDisplay_pos,SpPSC_OutputWavesDisplay_pos
// graph across top
	SpPSC_rawDataDisplay_pos={LeftPos,TopPos,LeftPos+2*graph_Width,TopPos+2*Graph_Height}		
// graph 2nd from top, left
	SpPSC_OutputWavesDisplay_pos={LeftPos,TopPos+2*Graph_Height+Graph_Grout,LeftPos+graph_Width,TopPos+3*Graph_Height+Graph_Grout}	
//graph 2nd from top, right
	SpPSC_InpResDisplay_pos={LeftPos+graph_width+Graph_grout,TopPos+2*Graph_Height+Graph_Grout,LeftPos+2*graph_Width+Graph_Grout,TopPos+3*Graph_Height+Graph_Grout}	
//graph bottom right
	SpPSC_HoldCurrDisplay_pos={LeftPos+graph_width+Graph_grout,TopPos+3*Graph_Height+2*Graph_Grout,LeftPos+2*graph_Width+Graph_Grout,TopPos+4*Graph_Height+2*Graph_Grout}
// graph bottom left
	SpPSC_VoltDisplay_pos={LeftPos,TopPos+3*Graph_Height+2*Graph_Grout,LeftPos+graph_Width,TopPos+4*Graph_Height+2*Graph_Grout}	


	
// determine correct channel #s for Scaled out (voltage), I output
	Print "Getting Nidaq ADC/DAC globals"
	//string LocalMode
	NVAR AcqResolution=  root:DataAcquisitionVar:AcqResolution 
	WAVE ADC_ChannelWave			=root:NIDAQBoardVar:ADC_ChannelWave
	WAVE ADC_SignalWave				=root:NIDAQBoardVar:ADC_SignalWave
	//WAVE ADC_IndBoardGainWave		=root:NIDAQBoardVar:ADC_IndBoardGainWave
	WAVE ADC_AmpGainWave			=root:NIDAQBoardVar:ADC_AmpGainWave
	Variable Monitor_Channel
	//Variable Monitor_IndBoardGain
	Variable Monitor_AmpGain
	Variable Input_Channel
	//Variable Input_IndBoardGain
	Variable Input_AmpGain
	//
	
	//Variable Voltage_Channel
	//Variable Voltage_IndBoardGain
	//Variable Voltage_AmpGain
	//Variable Current_Channel
	//Variable Current_IndBoardGain
	//Variable  Current_AmpGain
	WAVE DAC_SignalWave				=root:NIDAQBoardVar:DAC_SignalWave
	WAVE DAC_Channel_Wave			=root:NIDAQBoardVar:DAC_Channel_Wave
	WAVE DAC_AmpGain_VCl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_VCl_Wave
	WAVE DAC_AmpGain_ICl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	//Variable DAC_out_Channel
	//Variable DAC_out_AmpGain
	Variable DAC_CellOut_Channel
	Variable DAC_CellOut_AmpGain
//	NVAR BoardID =	root:NIDAQBoardVar:Boardid
	print "determining channels & gains"
	string ADCsignalList = ConvertTextWavetoList(ADC_SignalWave)
	string DACsignalList = ConvertTextWavetoList(DAC_SignalWave)
	
	//
	Monitor_Channel=whichListItem(Monitor_Signal, ADCsignalList)				// channel is equivalent to position in List
	Input_Channel=WhichlistItem(Input_Signal, ADCsignalList)
	Monitor_AmpGain= ADC_AmpGainWave[Monitor_Channel]
	Input_AmpGain=ADC_AmpGainWave[Input_Channel]
	//
	//Voltage_Channel=whichListItem(Voltage_Signal, ADCsignalList)				// channel is equivalent to position in List
	//current_Channel=WhichlistItem(current_Signal, ADCsignalList)
	//DAC_out_Channel=WhichlistItem(Output_Signal, DACsignalList)
	//Voltage_AmpGain= ADC_AmpGainWave[Voltage_Channel]
	//Current_AmpGain=ADC_AmpGainWave[Current_Channel]

// update 2015
//  Amplifier control out channel:
	print "Preparing for IR test"
	DAC_CellOut_Channel=WhichlistItem(Outputcell_Signal, DACsignalList)
	if(DAC_CellOut_Channel==-1)
		SetDataFolder root:
		abort "if you want to do an IR test, you must choose 'External Command (Front)' for one of the DAC outs"
	else
		If(stringmatch(NowMulticlampMode, "V-Clamp"))		// if amplifier is in Voltage Clamp
			DAC_CellOut_AmpGain=DAC_AmpGain_VCl_Wave[DAC_CellOut_Channel]
		else
			if(  stringmatch(NowMulticlampMode,"I-Clamp")  )	// if amplifier is in Current Clamp
				DAC_CellOut_AmpGain=DAC_AmpGain_ICl_Wave[DAC_CellOut_Channel]
			else
				SetDataFolder root:
				Abort  "you must select  V-Clamp or I-Clamp "
			endif
		endif
		print "DAC_cellout_ampgain = " num2str( DAC_CellOut_AmpGain)
	endif
	if(  stringmatch(NowMulticlampMode,"V-Clamp")  )
			NVAR Sp_IR_Amp		=	root:DataAcquisitionVar:IRpulse_amp_VC	// input resistance test pulse, V (e.g. -5mV)
			NVAR Sp_IR_Dur		=	root:DataAcquisitionVar:IRpulse_dur_VC		// test pulse duration, sec (e.g., 10ms)
			
	
		else
			NVAR Sp_IR_Amp		=	root:DataAcquisitionVar:IRpulse_amp_IC	// input resistance test pulse, A (e.g. -0.05nA)
			NVAR Sp_IR_Dur		=	root:DataAcquisitionVar:IRpulse_dur_IC
		
		endif
	//
	// Update Telegraphs:  verify I-clamp, update scaled output gain, write to notebook the readouts
//	if(stringmatch(current_Signal,"ScaledOutput") | stringmatch(voltage_Signal,"ScaledOutput") )
//		Execute "UpdateTelegraphs()"
//		//print "getting TG globals"
//		NVAR Current_TG_Gain	=	root:NIDAQBoardVar:Current_TG_Gain		
//		SVAR  Current_TG_Mode=	root:NIDAQBoardVar:Current_TG_Mode
//		SVAR Current_ScaledOutType=root:NIDAQBoardVar:Current_ScaledOutType
//		NVAR Current_TG_Filter	=root:NIDAQBoardVar:Current_TG_Filter
//		NVAR current_TG_Capac	=root:NIDAQBoardVar:current_TG_Capac			
//		LocalMode=Current_TG_Mode
//		print LocalMode
		//if(  ! stringmatch(LocalMode,"V-Clamp")  )		// in future, use in both V-Cl and I-Cl
		//	Setdatafolder root:
		//	Abort "Amplifier must be set in'I-Clamp Fast'  or 'I-Clamp Normal' "
	//	endif
//		if(  stringmatch(LocalMode,"V-Clamp")  )
//			NVAR Sp_IR_Amp	=	root:DataAcquisitionVar:IRpulse_amp_VC
//			NVAR Sp_IR_Dur		=	root:DataAcquisitionVar:IRpulse_dur_VC	
//		else
//			NVAR Sp_IR_Amp	=	root:DataAcquisitionVar:IRpulse_amp_IC
//			NVAR Sp_IR_Dur	=	root:DataAcquisitionVar:IRpulse_dur_IC
//		endif
//			if(!stringmatch(Output_signal[0,6],"Ext Com"))
//				setdatafolder root:
//				abort "you must select 'Ext Command (front)' or 'Ext Command (rear)' for output signal"
//			endif
//
//	endif
	
//	if(stringmatch(Current_Signal,"AxCl_Iout"))
//		LocalMode = Current_AxClMode
//		print LocalMode
//		if(  stringmatch(LocalMode,"V-Clamp")  )
//			NVAR Sp_IR_Amp	=	root:DataAcquisitionVar:AxCl_IRpulse_amp_VC
//			NVAR Sp_IR_Dur	=	root:DataAcquisitionVar:AxCl_IRpulse_dur_VC
//			if(!stringmatch(Output_signal,"AxoClamp VCCmd"))
//				setdatafolder root:
//				abort "you must select AxoClamp VCCmd for vclamp output signal"
//			endif
//		else
//			NVAR Sp_IR_Amp	=	root:DataAcquisitionVar:AxCl_IRpulse_amp_IC
//			NVAR Sp_IR_Dur	=	root:DataAcquisitionVar:AxCl_IRpulse_dur_IC
//			if(!stringmatch(Output_signal,"AxoClamp ME1ExtCmd"))
//				print output_signal, "AxoClamp ME1ExtCmd"
//				setdatafolder root:
//				abort "you must select AxoClamp ME1ExtCmd for Iclamp output signal"
//			endif
//		endif
//	endif
	If(stringmatch(NowMulticlampMode, "V-Clamp"))
			//Input_signal = Current_Signal
		//	Monitor_signal = Voltage_Signal	
			ymin	= ymin_VC
			ymax	= ymax_VC
	else
			//Input_signal = Voltage_Signal
			//Monitor_signal = Current_Signal
			ymin	= ymin_IC
			ymax	= ymax_IC


	endif
	
// find  channels;determine current amplifier gains for output & input waves;determine individual board gains for input waves
//	if((Voltage_Channel==-1)  || (current_Channel==-1) || (DAC_out_Channel==-1))			// check that all have channels
//		SetDataFolder root:
//		commandstr = "you must select  channels containing  "+Voltage_Signal +"," +  current_Signal + ", and " + Output_Signal
//		Abort commandstr
//	endif 
//	if(  stringmatch(LocalMode,"V-Clamp") ||  stringMatch(LocalMode,"VClamp"  ) )		// if amplifier is in Voltage Clamp
//		DAC_out_AmpGain=DAC_AmpGain_VCl_Wave[DAC_out_Channel]
//	else
//		if(  stringmatch(LocalMode[0,3],"I-Cl") ||  stringMatch(LocalMode[0,2],"ICl"  ) )	// if amplifier is in Current Clamp
//			DAC_out_AmpGain=DAC_AmpGain_ICl_Wave[DAC_out_Channel]
//		else
//			print LocalMode
//			SetDataFolder root:
//			commandstr = "you must select  V-Clamp, I-Clamp Normal,  or I-Clamp Fast"
//			Abort commandstr
//		endif
//	endif
//	Voltage_IndBoardGain= ADC_IndBoardGainWave[Voltage_Channel]
//	Current_IndBoardGain=ADC_IndBoardGainWave[Current_Channel]

// write SponPSC panel parameters to notebook
// all the panel variables:
	print "Getting Spon PSC panel parameters"
	NVAR SpPSC_CmdVolt				=	root:SponPSC:SpPSC_CmdVolt
	NVAR SpPSC_SetNum				=	root:SponPSC:SpPSC_SetNum
	SVAR SpPSC_Basename				=	root:SponPSC:SpPSC_Basename
	SVAR Basename						=	root:DataAcquisitionVar:baseName
	String Local_Basename				=	"SpPSC_" +baseName + "s" + num2str(SpPSC_SetNum)	// recalculate a local basename
	NVAR SpPSC_AcqLength				=	root:SponPSC:SpPSC_AcqLength
	NVAR SpPSC_TrialISI				=	root:SponPSC:SpPSC_TrialISI					// in sec
	NVAR SpPSC_NumTrialRepeats		=	root:SponPSC:SpPSC_NumTrialRepeats
	NVAR SpPSC_NumSetRepeats		=	root:SponPSC:SpPSC_NumSetRepeats
	NVAR SpPSC_SetNum				=	root:SponPSC:SpPSC_SetNum
	NVAR SpPSC_RepeatCheck			=	root:SponPSC:SpPSC_RepeatCheck
	NVAR SpPSC_CalcIRCheck			=	root:SponPSC:SpPSC_CalcIRCheck
	NVAR SpPSC_DispHoldCurrCheck	=	root:SponPSC:SpPSC_DispHoldCurrCheck
	NVAR SpPSC_DispCmdVoltCheck		=	root:SponPSC:SpPSC_DispCmdVoltCheck
	//input resistance params

	

	Variable totalWavePoints = AcqResolution *SpPSC_AcqLength
	variable level
	StartingSetNumber=SpPSC_SetNum
// Write to notebook channels & gains
	Notebook Parameter_Log ruler=Title, text="\r\rStarting Spontaneous PSC Data Acquisition" +"\r"
	Notebook Parameter_Log ruler=Normal, text ="\t" +Date() + "  " + time() + "\r\r"
	Notebook Parameter_Log ruler=Title, text="\r\rStarting Evoked PSC Data Acquisition" +"\r"
	Notebook Parameter_Log ruler=Normal, text ="\t" +Date() + "  " + time() + "\r\r"
	Notebook Parameter_Log ruler=normal, text="\r\tAcquisition Resolution (samples/sec) :\t" + num2str(AcqResolution)
	Notebook Parameter_Log ruler =normal, text="\r\tInput signal : \t"  + Input_Signal+" on channel " +num2str(Input_Channel)
	Notebook Parameter_Log ruler =normal, text="\r\tInput  signal amplifier gain : " + num2str(Input_ampGain)//+ "\t and board gain : " + num2str(Monitor_IndBoardGain)
	Notebook Parameter_Log ruler=normal, text="\r\tMonitor signal : \t"  + Monitor_Signal  +" on channel " +num2str(Monitor_Channel)
	Notebook Parameter_Log ruler=normal, text="\r\tMonitor signal amplifier gain : " + num2str(Monitor_ampGain)// + "\t and board gain : " + num2str(Monitor_IndBoardGain)
	Notebook Parameter_Log ruler =normal, text="\r\tOutput to cell to:  \t"  + Outputcell_Signal+" on channel " +num2str(DAC_CellOut_Channel)
	Notebook Parameter_Log ruler =normal, text="\r\tOutput to cell amplifier gain : \t" + num2str(DAC_CellOut_AmpGain)
	Notebook Parameter_Log ruler =normal, text="\r\tBasename for acquired waves: \t" +Local_Basename
	
	

	
	Notebook Parameter_Log ruler =normal, text="\r\tTotal Wave Length (sec): \t" + num2str(SpPSC_AcqLength )	
	Notebook Parameter_Log ruler =normal, text="\r\tCommand Voltage (mV): \t" + num2str(SpPSC_CmdVolt*1000)
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of trials per set: \t" +num2str(SpPSC_NumTrialRepeats) + "\r"
	Notebook Parameter_Log ruler =normal, text="\r\tInter-trial interval (sec):\t" +num2str(SpPSC_TrialISI)
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of times to repeat set: \t" +num2str(SpPSC_NumSetRepeats) + "\r"
//	if(SpPSC_CalcIRCheck)
//		Notebook Parameter_Log ruler =normal, text="\r\tCalculating input resistance:"
//		Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse amplitude (mV or nA):\t"+ num2str(Sp_IR_Amp*1000)
//		Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse duration (ms):\t"+ num2str(Sp_IR_Dur*1000)
//	endif
	//Notebook Parameter_Log ruler =normal, text="\r\tFiltering is set to (kHz): /t" + num2str(Current_TG_Filter) + "\r"
	

// Acquisition wave names wave creation:
	
//	Make/T/N=(SpPSC_NumTrialRepeats*SpPSC_NumSetRepeats)/O  currentAcqNames_Wave, VoltageAcqNames_Wave,InputNamesWave // contains the names of the acquired waves
	
	Make/T/N=(SpPSC_NumTrialRepeats*SpPSC_NumSetRepeats)/O InputAcqNames_Wave, MonitorAcqNames_Wave,InputNamesWave // contains the names of the acquired waves


// OUTPUT WAVE CREATION:  create once, reuse each iteration.
// only need to create one output wave (for IR test pulse) per set:
	print "Creating output waves"
	if(SpPSC_TrialISI <= (SpPSC_AcqLength+0.200))	// check that ISI is long enough (200ms extra room)	
		SetDataFolder root:
		Abort "ISI must be longer than "  + num2str(SpPSC_AcqLength+0.200)
	endif
	Make/T/N=(SpPSC_NumSetRepeats)/O OutNames_Wave
	Make /N=( totalWavePoints)/O tempwave0
	SetScale /P x 0, (1/AcqResolution), "sec",  tempwave0

	tempwave0=SpPSC_CmdVolt			// is command voltage absolute or relative?  if relative, need to measure volt cmd & change to difference
	DoWindow /K SpPSC_OutputWavesDisplay
	Display /W=(SpPSC_OutputWavesDisplay_pos[0],SpPSC_OutputWavesDisplay_pos[1],SpPSC_OutputWavesDisplay_pos[2],SpPSC_OutputWavesDisplay_pos[3]) as "Spon PSC Output Waves"
	DoWindow /C SpPSC_OutputWavesDisplay
	i=0
	
	Do
		tempwave0[x2pnt(tempwave0,BeforeBuff),x2pnt(tempwave0,(BeforeBuff+Sp_IR_Dur))]=Sp_IR_Amp+SpPSC_CmdVolt
		tempWave0/=DAC_CellOut_AmpGain		//  divide by gain  in V/V
		print DAC_CellOut_AmpGain/1000
		OutNames_Wave[i]="Sp_OutputWave_s" + num2str(i)
		Duplicate /O tempWave0, $OutNames_Wave[i]
		AppendToGraph $OutNames_Wave[i]
		i+=1
	while(i<SpPSC_NumSetRepeats)		
	

// REAL TIME ANALYSES:

// Measure Input resistance for each trial; calculate & plot.
	controlInfo /W=SponPSCAcq_ControlPanel CalcIRCheck
	SpPSC_CalcIRCheck=V_value
	DoWindow/K SpPSC_InpResDisplay
	print "SpPSC_CalcIRCheck = " + num2str(SpPSC_CalcIRCheck)

	if(SpPSC_CalcIRCheck)
		print "Setting up for input resistance calculations", num2str(SpPSC_CalcIRCheck)
		Make/T/O/N=(SpPSC_NumSetRepeats) IRWave_Names
		IRWave_Names[0]=Local_Basename  + "_IR"			// one for each set (local_basename includes set#)	
		Make/O/N=(SpPSC_NumTrialRepeats) $IRWave_Names[0]					// create waves for real-time analysis each set
		
		Display /W=(SpPSC_InpResDisplay_pos[0],SpPSC_InpResDisplay_pos[1],SpPSC_InpResDisplay_pos[2],SpPSC_InpResDisplay_pos[3]) $IRWave_Names[0]   as "Input Resistance : " + Local_Basename
		Modifygraph  mode=3,live=1
		ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
		SetAxis /A left
		Label left "Input Resistance (MOhms)"
		Label bottom "Trials"
		doWindow /C SpPSC_InpResDisplay
		DoUpdate
		// no averaging across sets
	if(  stringmatch(NowMulticlampMode,"V-Clamp")  )
			
			Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse amplitude (mV):\t"+ num2str(Sp_IR_Amp*1000)
			Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse duration (ms):\t"+ num2str(Sp_IR_Dur*1000)
		else
			Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse amplitude (pA):\t"+ num2str(Sp_IR_Amp*1000)
			Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse duration (ms):\t"+ num2str(Sp_IR_Dur*1000)
		endif
	endif
// Measure Holding current and actual voltage levels: 
// Create Window to plot it.
///HOLDING CURRENT:
	controlInfo /W=SponPSCAcq_ControlPanel DispHoldCurrCheck
	SpPSC_DispHoldCurrCheck=V_value
	print "SpPSC_DispHoldCurrCheck = " + num2str(SpPSC_DispHoldCurrCheck)
	DoWindow/K SpPSC_HoldCurrDisplay
	if(SpPSC_DispHoldCurrCheck)
		print "Setting up for holding current measures", num2str(SpPSC_DispHoldCurrCheck)
		Make/T/O/N=(SpPSC_NumSetRepeats) HCWave_Names
		HCWave_Names[0]=Local_Basename  + "_HC"					// one for each set (local_basename includes set#)
		Make/O/N=(SpPSC_NumTrialRepeats) $HCWave_Names[0]					// create waves for real-time analysis each set
		Display /W=(SpPSC_HoldCurrDisplay_pos[0],SpPSC_HoldCurrDisplay_pos[1],SpPSC_HoldCurrDisplay_pos[2],SpPSC_HoldCurrDisplay_pos[3])  $HCWave_Names[0]	   as "Holding current (nA) : "	+ Local_Basename
		Modifygraph  mode=3,live=1
		ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
		SetAxis /A left
		Label left "Holding current (nA)"
		Label bottom "Trials"
		Modifygraph  lblPos(left)=40
		doWindow /C SpPSC_HoldCurrDisplay
		DoUpdate
	endif
/// VOLTAGE :	
	controlInfo /W=SponPSCAcq_ControlPanel DispCmdVoltCheck
	SpPSC_DispCmdVoltCheck=V_value
	print "SpPSC_DispCmdVoltCheck = " + num2str(SpPSC_DispCmdVoltCheck)
	DoWindow/K SpPSC_VoltDisplay
	if(SpPSC_DispCmdVoltCheck)
		print "Setting up for voltage measure", num2str(SpPSC_DispCmdVoltCheck)
		Make/T/O/N=(SpPSC_NumSetRepeats) VoltLevWave_Names	// one for each set (local_basename includes set#)						
		VoltLevWave_Names[0]=Local_Basename + "_VL"   
		Make/O/N=(SpPSC_NumTrialRepeats) $VoltLevWave_Names[0]					// create waves for real-time analysis each set
		Display /W=(SpPSC_VoltDisplay_pos[0],SpPSC_VoltDisplay_pos[1],SpPSC_VoltDisplay_pos[2],SpPSC_VoltDisplay_pos[3]) $VoltLevWave_Names[0]   as "Voltage (actual) : "+ Local_Basename
		Modifygraph  mode=3,live =1
		ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
		Label left "Voltage (V)"
		Label bottom "Trials"
		SetAxis /A left
		Modifygraph  lblPos(left)=40	
		doWindow /C SpPSC_VoltDisplay
		DoUpdate
	endif
		
/////////////////////////////	
	tempwave0=0
	k=0			// loop variable for number of set repeats
	do												// loop for each Set Iteration
		print "Beginning set iteration number:", num2str(k)
		// create waves for acquiring current & voltage data; create at beginning of each iteration & step Loop
		//print Local_Basename
		
		if(k>0)
			if(SpPSC_CalcIRCheck)
				print "set up for IR"
				IRWave_Names[k]=Local_Basename  + "_IR"					// one for each set (local_basename includes set#)
				Make/O/N=(SpPSC_NumTrialRepeats) $IRWave_Names[k]
				DoWindow/F SpPSC_InpResDisplay;	
				AppendtoGraph /W=SpPSC_InpResDisplay $IRWave_Names[k]
				Modifygraph  mode=3,live =1
				ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
				DoUpdate
			endif
			if(SpPSC_DispHoldCurrCheck || SpPSC_CalcIRCheck)			// need for IR calc also
				print "set up for HC"
				HCWave_Names[k]=Local_Basename  + "_HC"	
				Make/O/N=(SpPSC_NumTrialRepeats) $HCWave_Names[k]
				DoWindow /F SpPSC_HoldCurrDisplay;
				AppendtoGraph /W=SpPSC_HoldCurrDisplay $HCWave_Names[k]

				Modifygraph  mode=3
				ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
				DoUpdate
			endif
			if(SpPSC_DispCmdVoltCheck || SpPSC_CalcIRCheck)				// need for IR calc also
				print "set up for VL"
				VoltLevWave_Names[k]=Local_Basename + "_VL"  
				Make/O/N=(SpPSC_NumTrialRepeats) $VoltLevWave_Names[k]
				DoWindow /F SpPSC_VoltDisplay
				AppendtoGraph /W=SpPSC_VoltDisplay  $VoltLevWave_Names[k]	
				Modifygraph  mode=3
				ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
				DoUpdate
			endif	
		endif
			
		Wave temp_IR = $IRWave_Names[k]
		Wave temp_HC=$HCWave_Names[k]
		Wave temp_VL=	$VoltLevWave_Names[k]	
		temp_IR=0
		temp_HC=0
		temp_VL=0
		if( (Waveexists(temp_IR)==0)  ||  (Waveexists(temp_HC)==0) ||   (Waveexists(temp_VL)==0) )
			print "temp_HC or temp_IR or temp_VL does not exist"
		endif

		string axislabelStr
	j=0
	do
		
				If(stringmatch(NowMulticlampMode, "V-Clamp"))
				MonitorAcqNames_Wave[j][i]=Local_Basename + "_V" + num2str(j) 	
				InputAcqNames_Wave[j][i]=Local_Basename + "_A" + num2str(j)
			axislabelStr= "Current (nA)"
			else
				MonitorAcqNames_Wave[j][i]=Local_Basename + "_A" + num2str(j)	
				InputAcqNames_Wave[j][i]=Local_Basename + "_V" + num2str(j)
				axislabelStr= "Voltgage (V)"
			endif
			duplicate /O tempwave0, $MonitorAcqNames_Wave[j]
			duplicate /O tempwave0, $InputAcqNames_Wave[j]
	
		j+=1
	while(j<SpPSC_numTrialRepeats)		// creates entire set of names at once for each set
		
		
		
		
//		j=0
//		do
//			VoltageAcqNames_Wave[j]=Local_Basename + "_V" + num2str(j)		
//			currentAcqNames_Wave[j]=Local_Basename + "_A" + num2str(j)
//			duplicate /O tempwave0, $VoltageAcqNames_Wave[j]
//			duplicate /O tempwave0, $currentAcqNames_Wave[j]
//		
//			j+=1
//		while(j<SpPSC_numTrialRepeats)		// creates entire set of names at once for each set
//		string axislabelStr
//		if(  stringmatch(LocalMode,"V-Clamp")  )
//				WAVE InputWave = $currentAcqNames_Wave[0]
//				InputNamesWave[0] = currentAcqNames_Wave[0]
//				axislabelStr= "Current (nA)"
//		else
//				WAVE InputWave = $VoltageAcqNames_Wave[0]
//				InputNamesWave[0] =VoltageAcqNames_Wave[0]
//				axislabelStr= "Voltgage (V)"
//		endif
		
		
		
		
		
		//Wave VoltAcqWave=$VoltageAcqNames_Wave[0]
			//  create window for real-time raw data display:
		DoWindow/K SpPSC_rawDataDisplay	
		Display /W=(SpPSC_rawDataDisplay_pos[0],SpPSC_rawDataDisplay_pos[1],SpPSC_rawDataDisplay_pos[2],SpPSC_rawDataDisplay_pos[3]) InputWave  as   "Spon PSC Acq waves: " + Local_Basename 
		Label left axislabelStr
		Label bottom "Time (sec)"
		doWindow /C SpPSC_rawDataDisplay
		//Removefromgraph VoltAcqWave
		//Removefromgraph CurrAcqWave
		
		
		// Make variables to acquire a temperature measure, once at the beginning of each set.  
		variable TempGain = 0.1	// gain on the T2 output is 100mV/degC
		variable CurrentTempDegC
		string TempAcqString = "TemperatureGrabWave,7,1"
		Make /O/N=100 TemperatureGrabWave
		SetScale /P x 0, (1/AcqResolution), "sec",  TemperatureGrabWave
		mysimpleAcqRoutine("",TempAcqString)
		TemperatureGrabWave/=TempGain
		CurrentTempDegC=mean(TemperatureGrabWave,-inf,inf)
		Notebook Parameter_Log ruler =normal, text="\r\t  Recording chamber temperature (T2) : \t" + num2str(CurrentTempDegC) + " degrees C"
		/////
	
		DoUpdate	
		j=0
		do											// begin within set trials loop
			StartTicks=ticks
			//
			
			print "Beginning trial # ", num2str(j)
			// send waves to nidaq
//			AcqString=VoltageAcqNames_Wave[j]+"," +num2str(Voltage_Channel)+ "," + num2str(Voltage_IndBoardGain)
//			AcqString+=";" +currentAcqNames_Wave[j]+"," +num2str(Current_Channel) + "," + num2str(Current_IndBoardGain)
//			WFOutString=OutNames_Wave[j] + "," + num2str(DAC_Out_Channel)
//			mySimpleAcqRoutine(WFOutString,AcqString)
//			Wave VoltAcqWave=  $(VoltageAcqNames_Wave[j])
//			Wave CurrAcqWave=$(currentAcqNames_Wave[j])
//			if( (Waveexists(VoltAcqWave)==0)  ||  (Waveexists(CurrAcqWave)==0) )
//				print "VoltAcqWave or CurrAcqWave does not exist"
//			endif
//			print "Volt amp gain " + num2str(Voltage_AmpGain)
//			print "Curr amp gain " + num2str(Current_AmpGain)
//			VoltAcqWave/=Voltage_AmpGain
//			CurrAcqWave=CurrAcqWave/Current_AmpGain
//			if(  stringmatch(LocalMode,"V-Clamp")  )
//				WAVE InputWave = CurrAcqWave
//				InputNamesWave = currentAcqNames_Wave
//			else
//				WAVE InputWave = VoltAcqWave
//				InputNamesWave =VoltageAcqNames_Wave
//			endif
//			// save waves to hard drive
//			CommandStr = "Save/O/C/P=SponPath " +VoltageAcqNames_Wave[j] +","+currentAcqNames_Wave[j]
//			Execute CommandStr							// Quick! Before the computer crashes!!!
			// display  raw voltage & current data		-->> FI raw data window
			
			
			// updated 2015:
			AcqString=InputAcqNames_Wave[j]+"," +num2str(Input_Channel) + ";" 
				AcqString+=MonitorAcqNames_Wave[j]+"," +num2str(Monitor_Channel) + ";" 
				
			
					WFOutString= TempIRStr + "," + num2str(DAC_CellOut_Channel)	
						
				//print " Data Acquisition output string: " + WFOutString
				print "              Acquiring ",  InputAcqNames_Wave[j]
				mySimpleAcqRoutine(WFOutString,AcqString)
				Wave MonitorAcqWave=  $(MonitorAcqNames_Wave[j])
				Wave InputAcqWave=$(InputAcqNames_Wave[j])			
				if( (Waveexists(MonitorAcqWave)==0)  ||  (Waveexists(InputAcqWave)==0) )
					SetDataFolder root:
					abort "MonitorAcqWave or InputAcqWave does not exist"
				endif

				MonitorAcqWave/=Monitor_AmpGain
				InputAcqWave/=Input_AmpGain
				//CommandStr = "Save/O/C/P=SponPath " +MonitorAcqNames_Wave[j]+","+InputAcqNames_Wave[j]
				CommandStr = "Save/O/C/P=SponPath " +InputAcqNames_Wave[j]		// save just the input waves; monitor waves takes too much space
				Execute CommandStr							// Quick! Before the computer crashes!!!
				
			
			// end update
			
			
			
			
			
			DoWindow/F SpPSC_rawDataDisplay		
			if(j>0)			// don't add to graph twice	
				appendtoGraph  InputAcqWave  //   // udpated 2015
				level = mean(InputAcqWave,-inf,inf)  // udpated 2015
				removefromgraph $InputAcqNames_Wave[j-1]  // udpated 2015
				
				setaxis left level-ymin,level+ymax
			endif
			modifygraph rgb=(0,0,0)
			
			// accumulate to one graph:
			variable offsetmax = max(ymin,ymax)
			if(j==0)
			DoWindow /K SpPSC_allTracesDisplay
			Display InputAcqWave
			//setaxis left level-ymin,level+ymax
			
			Label left axislabelStr			
			Dowindow /C SpPSC_allTracesDisplay
			else
			Dowindow/F SpPSC_allTracesDisplay
			AppendtoGraph InputAcqWave
			ModifyGraph offset($InputAcqNames_Wave[j])={0,(-j*offsetmax)}
			endif
			//ModifyGraph rgb($currentAcqNames_Wave[j])=(0,0,0 )
			//ModifyGraph rgb($VoltageAcqNames_Wave[j])=(0,0,0 )
			DoUpdate
			//REAL TIME ANALYSIS: Measure baseline holding current:
			
			if (stringmatch(NowMulticlampMode,"V-Clamp"))
					WAVE VoltAcqWave =MonitorAcqWave
					WAVE  CurrAcqWave =InputAcqWave
			else
					WAVE VoltAcqWave =InputAcqWave
					WAVE  CurrAcqWave =MonitorAcqWave
			endif
			if(SpPSC_DispHoldcurrCheck || SpPSC_CalcIRCheck)		// need to measure for IR calculation anyway
				temp_HC[j]=mean(CurrAcqWave, 0.010,BeforeBuff-0.010)			// 3 ms from start to 3 ms before IR pulse
				//print temp_HC[j]	
				DoWindow /F SpPSC_HoldCurrDisplay;ModifyGraph rgb=(0,0,0 )
			endif
			//REAL TIME ANALYSIS: Measure baseline voltage:
			if(SpPSC_DispCmdVoltCheck || SpPSC_CalcIRCheck)		// need to measure for IR calculation anyway
				temp_VL[j]=mean(VoltAcqWave, 0.010,BeforeBuff-0.010)		// 3 ms from start to 3 ms before IR pulse
				//print temp_VL[j]
				DoWindow /F SpPSC_VoltDisplay;ModifyGraph rgb=(0,0,0 )
			endif
			//REAL TIME ANALYSIS: Calculate & plot input resistance:			mV/nA = MOhm
			if(SpPSC_CalcIRCheck)
				temp_IR[j]=( mean(VoltAcqWave, BeforeBuff+Sp_IR_Dur-0.005,BeforeBuff+Sp_IR_Dur-0.0005 )-temp_VL[j]) *1000  // convert from V to mV
				temp_IR[j] /=  ( mean(CurrAcqWave, BeforeBuff+Sp_IR_Dur-0.005,BeforeBuff+Sp_IR_Dur-0.0005)- temp_HC[j] )	// current is already in nA
				//print  temp_IR[j]
				DoWindow/F SpPSC_InpResDisplay;	ModifyGraph rgb=(0,0,0 )
			endif
			
			
			
			
			do									//waste time between runs according to ISI
				elapsedTicks=ticks-StartTicks
			while((elapsedTicks/60.15)<SpPSC_TrialISI)	
			print "time between " + num2str(elapsedTicks/60.15)
			j+=1
		while(j<SpPSC_numTrialRepeats)

		Notebook  Parameter_Log ruler =normal, text="\r\rCompleted Set#" + num2str(SpPSC_SetNum)
		//Notebook  Parameter_Log ruler =normal, text="\r\tAcquired current traces:\t" + currentAcqNames_Wave[0]+ "-" + num2str(SpPSC_numtrialRepeats-1)
		//Notebook  Parameter_Log ruler =normal, text="\r\tAcquired voltage traces:\t" +VoltageAcqNames_Wave[0] +"-" + num2str(SpPSC_numtrialRepeats-1)
			Notebook  Parameter_Log ruler =normal, text="\r\tAcquired input traces:\t" + InputAcqNames_Wave[0]+ "-" + num2str(SpPSC_numtrialRepeats-1)
		//Notebook  Parameter_Log ruler =normal, text="\r\tAcquired monitor traces:\t" +MonitorAcqNames_Wave[0] +"-" + num2str(SpPSC_numtrialRepeats-1)
		Notebook  Parameter_Log ruler =normal, text="\r\tAcquired but did not save hard copy of Monitor traces"
		// Save per set analysis waves:
		if(SpPSC_CalcIRCheck)
			CommandStr = "Save/O/C/P=SponPath "+ IRWave_Names[k] 	// Save the acquired wave in the home path right away!
			Execute CommandStr
			Notebook  Parameter_Log ruler =normal, text="\r\tInput Resistance measures for this set:\t" + IRWave_Names[k]
			WaveStats/Q $IRWave_Names[k]
			Notebook Parameter_Log ruler =normal, text="\r\t  Average Input Resistance (MOhm): " + num2str(V_avg) + " +/-" + num2str(V_sdev) + "  s.d."
		endif
		if(SpPSC_DispHoldCurrCheck)
			CommandStr = "Save/O/C/P=SponPath "+ HCWave_Names[k] 	// Save the acquired wave in the home path right away!
			Execute CommandStr
			Notebook  Parameter_Log ruler =normal, text="\r\tHolding current measures for this set:\t" +  HCWave_Names[k] 
			WaveStats /Q $HCWave_Names[k] 
			Notebook Parameter_Log ruler =normal, text="\r\t   Average Holding current (nA): " + num2str(V_avg*10e+9) + " +/-" + num2str(V_sdev*10e+9) + "  s.d."
		endif
		if(SpPSC_DispCmdVoltCheck)
			CommandStr = "Save/O/C/P=SponPath "+ VoltLevWave_Names[k] 	// Save the acquired wave in the home path right away!
			Execute CommandStr
			Notebook  Parameter_Log ruler =normal, text="\r\tBaseline voltage measures for this set:\t" + VoltLevWave_Names[k] 
			WaveStats/Q   $VoltLevWave_Names[k] 	 
			Notebook Parameter_Log ruler =normal, text="\r\t   Average Baseline voltage (mV): " + num2str(V_avg*1000) + " +/-" + num2str(V_sdev*1000) + "  s.d."
		endif
		/////	
		Notebook  Parameter_Log ruler =normal, text="\r"
		SpPSC_SetNum+=1			// update set#
		Local_Basename			=	"SpPSC_" +baseName + "s" + num2str(SpPSC_SetNum)	// recalculate basename
		k+=1	
	while(k<SpPSC_numsetRepeats)	
	print "completed Set repeats"
	EndingSetNumber=StartingSetNumber+k



	// END OF MACRO CLEAN-UP:
	Dowindow/K SpPSC_Layout
	NewLayout  /w=(80,40,400,450) as Local_Basename
	Appendlayoutobject graph SpPSC_rawDataDisplay
	Appendlayoutobject graph SpPSC_HoldCurrDisplay
	Appendlayoutobject graph SpPSC_VoltDisplay
	Appendlayoutobject graph  SpPSC_InpResDisplay
	Dowindow/C SpPSC_layout
	Dowindow/B SpPSC_layout
	print "Cleaning up"
	SpPSC_Basename= Local_Basename			// update global FI basename

	dowindow /K SpPSC_outputWaves
	KillWaves/Z tempWave0				// kill output waves & all other temporary & non-essential waves
	i=0
	do
		KillWaves/Z $OutNames_Wave[i]
		i+=1
	while(i<SpPSC_numsetRepeats)
	KillWaves/Z SpPSC_OutputWavesDisplay_pos,SpPSC_VoltDisplay_pos,SpPSC_HoldCurrDisplay_pos
	KillWaves/Z currentAcqNames_Wave,VoltLevWave_Names,OutNames_Wave
	killwaves /Z IRWave_Names,HCWave_Names,VLWave_Names,TemperatureGrabWave
	killWaves/Z SpPSC_OutputWaves_pos,SpPSC_HoldCurrDisplay,SpPSC_VoltDisplay,SpPSC_rawDataDisplay_pos,SpPSC_InpResDisplay_pos
	SetDataFolder root:		// return to root 
	
		Notebook Parameter_Log text="\rCompleted run:\tTime: "+Time()+"\r\r"
	
	Notebook  Parameter_Log ruler =normal, text="\r\r"
end		