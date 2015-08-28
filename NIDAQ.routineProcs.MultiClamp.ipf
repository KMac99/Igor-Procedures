#pragma rtGlobals=1		// Use modern global access method.
/// NIDAQ routineProcs Multiclamp.ipf         built on  Version4
// updated version for new PCs, and nidaq-mx drivers, and nidaqMX Tools   20july2010
// updated to accomodate Multiclamp only
/// cut out  Axopatch 200B and Axoclamp 2B
#include <Waves Average>
#include  "C:\Documents and Settings\All Users\Documents\Igor Shared Procedures\Igor_current_procs\WavetoList procs"
//#include  "C:\Documents and Settings\All Users\Documents\Igor Shared Procedures\kate analysis procs v2"

//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\WavetoList procs"
//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\kate analysis procs"
//#include "Mack:IGOR Shared Procedures:current igor procs folder:WavetoList procs"
//#include "Mack:IGOR Shared Procedures:current igor procs folder:kate analysis procs"
// updated 6mar02
// 10/07/03 changed error in gains:  Vclamp DAC output gains are 20mV/V, thus
// gain must be 0.02 (not 20, as previously).
//  15feb03:  Incorporated    "switchboardupdate.ipf"  and  "telegraphs.ipf"  code into NIDAQ routine procs code 
// so no longer need to include separate procedure files.
////////////////////////////////////////////////////////////////////////////
///			NIDAQ routine Procs			8/21/01  KM
///////////////////////////
//  The routines below deal with the data acquisition:  NIDAQ call functions, and setting up 
// our specific rig set up 'SwitchBoard'.  
// Calls Wave Creation panel, saves expt
////////////////////////////////////////////////////////////////////////////

Menu "Initialize Procedures"
	"Initialize for Data Acquisition", InitDataAcq()
	//"Re-display FI control panel", FI_ControlPanel()
	//"Re-display Nidaq SwitchBoard Panel", Display_NIDAQSwitchBoard() 	// only redisplays panel, does not re-initialize
end

menu "Kill Windows"
	"Kill all graphs",KillAllGraphWindows()
end

function KillAllGraphWindows()
	string wl, wname
	variable i
	wl=WinList("*", ";", "WIN:1")
	i=0
	do
		wname=stringfromlist(i, wl,";")
		if(strlen(wname)==0)
			abort
		endif
		Dowindow/K $wname
		i+=1
	while(1)
end

function Update_MulticlampMode(ctrlName,popNum,popStr) : PopupMenucontrol
	string ctrlname
	Variable popNum
	String popStr	
	SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
	NowMulticlampMode = popStr

	NVAR MulticlampInGain_Vm_VC	=	root:NIDAQBoardVar:MulticlampInGain_Vm_VC
	NVAR  MulticlampInGain_Im_VC	=	root:NIDAQBoardVar:MulticlampInGain_Im_VC
		
	NVAR MulticlampInGain_Vm_IC	=	root:NIDAQBoardVar:MulticlampInGain_Vm_IC
	NVAR  MulticlampInGain_Im_IC	=	root:NIDAQBoardVar:MulticlampInGain_Im_IC
	
	NVAR  MulticlampMode		=	root:NIDAQBoardVar:MulticlampMode
	NVAR  PrimaryoutputGain		=	root:NIDAQBoardVar:PrimaryoutputGain
	NVAR   SecondaryoutputGain 	=	root:NIDAQBoardVar:SecondaryoutputGain
	NVAR ADC0_AmpGain		=	root:NIDAQBoardVar:ADC0_AmpGain
	NVAR ADC1_AmpGain		= 	root:NIDAQBoardVar:ADC1_AmpGain
	
	WAVE ADC_AmpGainWave 	=	root:NIDAQBoardVar:ADC_AmpGainWave
	WAVE/T ADC_SignalWave 	= 	root:NIDAQBoardVar:ADC_SignalWave
	String SignalList=convertTextWavetoList(ADC_SignalWave)
	
	
	print "***********************changing Multiclamp mode to: " + NowMulticlampMode
	print popNum
	
	if(popNum==1)	// popnum = 1, Iclamp
		PrimaryoutputGain=MulticlampInGain_Vm_IC
		SecondaryoutputGain=MulticlampInGain_Im_IC
		MulticlampMode=0
	
	else
		PrimaryoutputGain		=  MulticlampInGain_Im_VC		// default: assume Vclamp mode, so primary gain = Current output
		SecondaryoutputGain =  MulticlampInGain_Vm_VC
		MulticlampMode=10
	
	endif

	print "Primary output ADC gain="+ num2str(PrimaryoutputGain) + "  , Secondary output ADC gain=" + num2str(SecondaryoutputGain) 
	print "Mode value = " + num2str(MulticlampMode)
	
	//Find out which channel is primary and secondary going to via switchboard, then update the gains.
	variable Channel_Primary=WhichListItem("PrimaryOutCh1",SignalList,";")
	variable Channel_Secondary=WhichListItem( "SecondaryOutCh1"	,SignalList,";")
	print SignalList
	print Channel_Primary
	print Channel_Secondary
	ADC_AmpGainWave[Channel_Primary]=PrimaryoutputGain
	ADC_AmpGainWave[Channel_Secondary]=SecondaryoutputGain

	print ADC_AmpGainWave
	Execute "UpdateGains()"
	ControlUpdate/A/W=NIDAQSwitchBoard
	
end

function UpdateGains()
	WAVE ADC_AmpGainWave 	=	root:NIDAQBoardVar:ADC_AmpGainWave
	NVAR ADC0_AmpGain		= 	root:NIDAQBoardVar:ADC0_AmpGain
	NVAR ADC1_AmpGain	= 	root:NIDAQBoardVar:ADC1_AmpGain
	NVAR ADC2_AmpGain	= 	root:NIDAQBoardVar:ADC2_AmpGain
	NVAR ADC3_AmpGain	= 	root:NIDAQBoardVar:ADC3_AmpGain
	NVAR ADC4_AmpGain	= 	root:NIDAQBoardVar:ADC4_AmpGain
	NVAR ADC5_AmpGain	= 	root:NIDAQBoardVar:ADC5_AmpGain
	NVAR ADC6_AmpGain	=	root:NIDAQBoardVar:ADC6_AmpGain
	NVAR ADC7_AmpGain	=	root:NIDAQBoardVar:ADC7_AmpGain
	
	ADC0_AmpGain=	ADC_AmpGainWave[0]
	ADC1_AmpGain=	ADC_AmpGainWave[1]
	ADC2_AmpGain=	ADC_AmpGainWave[2]
	ADC3_AmpGain=	ADC_AmpGainWave[3]
	ADC4_AmpGain=	ADC_AmpGainWave[4]
	ADC5_AmpGain=	ADC_AmpGainWave[5]
	ADC6_AmpGain=	ADC_AmpGainWave[6]
	ADC7_AmpGain=	ADC_AmpGainWave[7]
	ControlUpdate/A/W=NIDAQSwitchBoard
end

function mySimpleAcqRoutine(WFOutListString,AcqWaveListString)
	String WFOutListString
	String AcqwaveListString
	print "Starting my simple acq routine"
	print WFOutListString
	print AcqwaveListString
	STring DeviceName = "dev1"
	variable WFnumPeriods=1// waveform generationnumber of periods	
	
	
		String TriggerSourcetoWF = "/Dev1/ai/StartTrigger"	// use to trigger WF off of Scan
	
	
	variable err
	err=fDAQmx_ResetDevice(DeviceName)		// resetting the board for good measure
	if (err)
			print "couldn't reset device?"
	endif	
	if(!(stringmatch(WFOutListString,"")))		// check for empty string; no error, just no output waves	
			print "          Sending WFout"	
			DAQmx_WaveformGen /DEV=DeviceName/TRIG={ TriggerSourcetoWF }    /NPRD=(WFnumPeriods)  WFOutListString	// 
		if (err)
			Abort "Could not send waveforms via DAQmx_WaveformGen"		
		endif
	endif
	if(!(stringmatch(AcqWaveListString,"")))		// check for empty string input; would be an error	
			print "          Starting DAQmx Scan"	
		DAQmx_Scan/DEV=(DeviceName)  WAVES=AcqwaveListString; //AbortOnRTE
		if(err)
			Abort "problem with DAQmx_Scan"
		endif
//		err=0
//		do
//			err=fNIDAQ_ScanWavesCheck(BoardID)		// transfer data 
//		while(err==0)									// don't do anything else until scan is completed & transferred!
	else
		Abort "Acquisition string sent to mySimpleAcqRoutine() was empty"
	endif
end

function EndofScanHook()
	STring DeviceName = "dev1"
	variable err
	print "Scan has ended; no errors"
	err=fDAQmx_ResetDevice(DeviceName)		// resetting the board for good measure
	if (err)
			print "couldn't reset device?"
	endif	
end

function ErrorScanHook()
	print "oops, there's been an error"
end

// Initializes the common global
// variables to be used by all data acquisition modules.
Proc InitDataAcq()

	DoWindow /F GlobalVariableCtrlPanel
	if (V_flag!=0)
		//	return 0
	endif
	
	String dfSave=GetDataFolder(1)
	NewPath /C /O/Z DataFolderPath, "C:Data"
	NewDataFolder /O/S root:DataAcquisitionVar
	KillWaves /a/z
	killvariables /a/z
	killstrings /a/z
	
	Variable /G AcqResolution	=	30000
	String /G	DateStr		=	date()		// assumes OS form: dd mmm, yyyy
	String/G dStr = dateStr[0,1]+DateStr[3,5]+ dateStr[10,11]		// DY + MON + YR ~ '09Jul01'
	print dStr
	Variable /G	CellNum		=	1
	String /G Basename			:=  dStr + "c" + num2str(cellNum)	//to be used by all modules
	
	//  Make params to get Input resistance from subroutines such as EvokThresh, EvokAcquire,SponAcquire
	// for voltage clamp:
	Variable/G IRpulse_amp_VC = -0.010	// voltage step, Volts  /// 11/12/10:  Use Multiclamp version
	Variable /G IRpulse_dur_VC = 0.03		// duration in vclamp, sec
	Variable /G IRpulse_amp_IC= -0.050	// current step, nA
	Variable /G IRpulse_dur_IC= 0.020		// duration in vclamp, sec
	Variable/G AxCl_IRpulse_amp_VC = -0.005	// voltage step, Volts                         // delete in Multiclamp version
	Variable /G AxCl_IRpulse_dur_VC = 0.02		// duration in vclamp, sec
	Variable /G AxCl_IRpulse_amp_IC= -0.050	// current step, nA
	Variable /G AxCl_IRpulse_dur_IC= 0.020		// duration in vclamp, sec

	variable/G SealTest_ISI = 1	// ISI for pulses in seconds
	variable/G SealTestNumPulses = 100
	SetDataFolder dfSave
	// Create Notebook for all parameters:
	DoWindow/K Parameter_Log
	NewNotebook/N=Parameter_Log/F=1/V=1/W=(300,350,750,500) as "Parameter Log for Data Acquisition"
	Notebook Parameter_Log defaultTab=36, statusWidth=238,pageMargins={72,72,72,72}
	Notebook Parameter_Log showruler=0,rulerUnits=1,updating={1,216000}
	Notebook Parameter_Log newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={16,32,400+3*8192,450+8192*2}, rulerDefaults={"Geneva",10,0,(0,0,0)}
	Notebook Parameter_Log newRuler=subHead,justification=0, margins={0,0,538}, spacing={0,0,0}, tabs={}, rulerDefaults={"Helvetica",12,0,(0,0,0)}
	Notebook Parameter_Log newRuler=TextRow, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={16,32,450+8192*2}, rulerDefaults={"Geneva",10,0,(0,0,0)}
	Notebook Parameter_Log newRuler=ImageRow, justification=1, margins={0,0,468}, spacing={0,0,0}, tabs={16,32,450+8192*2}, rulerDefaults={"Geneva",10,0,(0,0,0)}
	Notebook Parameter_Log newRuler=Title, justification=0, margins={0,0,538}, spacing={0,0,0}, tabs={}, rulerDefaults={"Helvetica",18,0,(0,0,0)}
	Notebook Parameter_Log ruler=Title, text="Starting up the Data Acquisition software\r"
	Notebook Parameter_Log ruler=Normal, text="\r\tDate: "+Date()+"\r"
	
	Notebook Parameter_Log text="\tTime: "+Time()+"\r\r"
	
	Execute "Init_NIDAQSwitchBoard()"
	SaveExperiment
	//Execute "Init_WaveCreationPanel()"
end







function SaveExpt(ctrlname) : Buttoncontrol
	string ctrlname
	variable refNum
	SetDataFolder root:
	//SaveExperiment
	// Save the expt in the above directory named as the basename
	//Open/P=DataFolderPath refNum
	/// Create the path to the Data folder
	NewPath /C/M="Choose the data folder for this experiment"/O/Z ExptPath
end

Proc Init_NIDAQSwitchBoard()
	DoWindow /K NIDAQSwitchBoard
	//if (V_flag!=0)			// check not just for window but for folder existence
	//	return 0
	//endif
	
	String dfSave=GetDataFolder(1)
	
	NewDataFolder /O/S root:NIDAQBoardVar
	KillWaves /a/z
	killvariables /a/z
	killstrings /a/z
	//
	variable/G boardID=1

	
	// give various ADC inputs names
	String/G MulticlampOutPutName0 = "PrimaryOutCh1"			//0
	String/G  MulticlampOutPutName1 = "SecondaryOutCh1"				//1
	String/G MulticlampOutPutName2 = "PrimaryOutCh2"				//2
	String/G MulticlampOutPutName3= "SecondaryOutCh2"			//3
	String /G MulticlampOutPutName4 = "_none_"		//4
	String/G MulticlampOutPutName5 = "_none_"	//5
	String/G MulticlampOutPutName6 = "_none_"	//6
	String/G TempProbeName	=	"TemperatureProbe"			//7
	//String /G AxoClampOutputName0 = "AxCl_10Vm"			//8
	//String /G AxoClampOutputName1 ="AxCl_Iout"				//9
	// Create a text wave containing the names of possible AxoPatch amplifier/ other connections; place in desired default order.
	Make /T/O  ConnectionNameTextWave= {MulticlampOutPutName0,MulticlampOutPutName1,TempProbeName,"_none_"}
	String/G ConnectionPopupString="_none_;"
	variable i=0
	do
		connectionPopupString+=ConnectionNameTextWave[i]+";"
		 i+=1
	while (i<4)		
	// current choice of input; initalize to desired value
	String/G ADC0_Signal= connectionNameTextWave[0]
	String/G ADC1_Signal= connectionNameTextWave[1]
	String/G ADC2_Signal= connectionNameTextWave[2]
	String/G ADC3_Signal= connectionNameTextWave[3]
	String/G ADC4_Signal= connectionNameTextWave[3]
	String/G ADC5_Signal= connectionNameTextWave[3]
	String/G ADC6_Signal= connectionNameTextWave[3]
	String/G ADC7_Signal= connectionNameTextWave[3]
	make/T /O/N=8 ADC_SignalWave={ADC0_Signal,ADC1_Signal,ADC2_Signal,ADC3_Signal,ADC4_Signal,ADC5_Signal,ADC6_Signal,ADC7_Signal}
	////  Analog-to-Digital variables:
//	variable/G ADC0_IndBoardGain=1
//	variable/G ADC1_IndBoardGain=1
//	variable/G ADC2_IndBoardGain=1
//	variable/G ADC3_IndBoardGain=1
//	variable/G ADC4_IndBoardGain=1
//	variable/G ADC5_IndBoardGain=1
//	variable/G ADC6_IndBoardGain=1
//	variable/G ADC7_IndBoardGain=1
//	variable/G ADC8_IndBoardGain=1
//	make /O/N=9 ADC_IndBoardGainWave={ADC0_IndBoardGain,ADC1_IndBoardGain,ADC2_IndBoardGain,ADC3_IndBoardGain,ADC4_IndBoardGain,ADC5_IndBoardGain,ADC6_IndBoardGain,ADC7_IndBoardGain,ADC8_IndBoardGain}

	// Acquisition Channel numbers; slightly redundant.
	variable/G ADC0_Channel=0
	variable/G ADC1_Channel=1
	variable/G ADC2_Channel=2
	variable/G ADC3_Channel=3
	variable/G ADC4_Channel=4
	variable/G ADC5_Channel=5
	variable/G ADC6_Channel=6
	variable/G ADC7_Channel=7	
	make /O/N=8 ADC_ChannelWave={0,1,2,3,4,5,6,7,8}
	// Create a text wave containing the different possible valid NIDAQ board individual gains.
//	Make /O ValidBoardGains={1,2,5,10,20,50,100}
//	String /G ValidBoardGainsPopupStr
//	i=0
//	do
//		ValidBoardGainsPopupStr+=num2str(ValidBoardGains[i]) + ";";  i+=1
//	while(i<7)
//	
	// Initialize variables to contain useful telegraph values/strings based on raw telegraph voltage readings:
	Variable /G Current_TG_Gain	= 1					// this is alpha*beta.
	String /G Current_TG_Mode		= "V-clamp"
	String/G Current_ScaledOutType= "Current"
	Variable/G Current_TG_Filter	= 5
	Variable /G current_TG_Capac	= 0						// eventually eliminate the initializations; and only acquire through ADC.  allow 'no value' entries.
	String /G Current_AxClMode 	= "I-clamp"		// Must select mode & gain by hand - no telegraphs for Axoclamp
	Variable /G Current_AxClGain	= 10				// 
	// Create Variables to contain known amplifier gains:
//	Variable/G mybeta = 1					// add to panel, with 1 as default; possible to change to 0.1.
//	String/G betaPopupString="1;0.1"	//
	
	Variable/G MulticlampInGain_Vm_VC	=  100	// 10 mV/mV   * changed to 100mV/mV on Nov 11,2014
	Variable/G  MulticlampInGain_Im_VC		=  0.5 // 0.5  V/nA   * changed to 5V/na on Nov 11,2014; chagned back March 11,2015
	Variable/G MulticlampInGain_Vm_IC	=  100	// 10  mV/mV * changed to 100mV/mV on Nov 11,2014
	Variable/G  MulticlampInGain_Im_IC		= 5 // 0.5  V/nA * changed to 5V/na on Nov 11,2014
	Variable /G  MulticlampMode		=  10	// high for Vclamp (10V),  low for Iclamp (0V);  defautl to Vclamp
	String /G NowMulticlampMode			= "V-clamp"
	variable/G  PrimaryoutputGain		=  MulticlampInGain_Im_VC		// default: assume Vclamp mode, so primary gain = Current output
	Variable /G   SecondaryoutputGain =  MulticlampInGain_Vm_VC

//	Variable/G AxoPatchScaledOutputGain	:=current_TG_Gain	// depends on Telegraph reading
//	Variable/G AxoPatch10VmGain		=10						// fixed
//	variable/G AxoPatchIOutputGain		:=1*mybeta				// true as long as AxoPatch rear panel I output switch is  in down position
//	Variable/G TG_Gain_Gain				=1								// this is the gain for the telegraph input containing the 'total scaled output gain'.
//	VAriable/G TG_Mode_Gain			=1							// set all telegraph settings to default to 1, they require a lookup table
//	Variable/G TG_Filter_Gain				=1
//	Variable/G TG_Capac_Gain			=1							// except Cell Capacitance, which is linearly related to reading.  what is it?
	Variable/G Temp_Probe_Gain			=0.1						// 
//	Variable /G AxoClamp_10VmGain		=10
//	variable/G AxoClamp_IoutputGain		=0.1				// 10/H mV/nA; H=0.1, so 100mV/nA; 10mV/100pA
//	Variable /G alpha

	//   These will be updated with choice of inputs.
	
	variable/G ADC0_AmpGain=PrimaryoutputGain		// default to Vclamp mode, Primary out is membrane current
	variable/G ADC1_AmpGain=SecondaryoutputGain		// default to Iclamp mode, secondary out is membrane voltage
	variable/G ADC2_AmpGain=Temp_Probe_Gain		
	variable/G ADC3_AmpGain=1						// default to null
	variable/G ADC4_AmpGain=1
	variable/G ADC5_AmpGain=1
	variable/G ADC6_AmpGain=1
	variable/G ADC7_AmpGain=1

	make /O kn={ADC0_AmpGain,ADC1_AmpGain,ADC2_AmpGain,1,1,1,1,1}

	make /O/N=8 ADC_AmpGainWave={Kn[0],Kn[1], Kn[2],Kn[3],Kn[4],Kn[5],Kn[6],Kn[7]}		// order the same as ADC_SignalWave
	duplicate/O Kn, ADC_KnownAmpGainWave
	// DAC output variables
	String/G MulticlampInputName0="Command"
	String/G MulticlampInputName1= "Mode"
	
	String/G AxoPatchInputName0 = "Ext Command (front)"
	String/G AxoPatchInputName1 = "Ext Command (rear)"
	String/G SIU1 = "Extracellular SIU1"
	String/G SIU2 = "Extracellular SIU2"
	String/G AxoClampInputName0 = "AxoClamp ME1ExtCmd"
	string/G AxoClampInputName1 = "AxoClamp VCCmd"
	Make /T/O  OutputNamesTextWave= {MulticlampInputName0,MulticlampInputName1,SIU1,SIU2}
	String/G OutputNamesString="_none_;" +OutputNamesTextWave[0] +";" + OutputNamesTextWave[1] +";" + OutputNamesTextWave[2] +";"+ OutputNamesTextWave[3] 
	
	String/G DAC0_Signal=OutputNamesTextWave[0]
	String/G DAC1_Signal=OutputNamesTextWave[1]
	make /T/O DAC_SignalWave={DAC0_Signal, DAC1_Signal}
	
	variable/G DAC0_Channel=0
	variable/G DAC1_Channel=1
	Make /N=2/O DAC_Channel_Wave={0,1}
	/// Known amplifier gains for AxoPatch command inputs.
	Variable/G MuCl_Command_VCl = 0.02			// 20mV/V
	Variable/G MuCl_Command_ICl = 2		//   400pA/V or 2nA/V		  CC feedback resistor to 500MOhm
	
//	Variable/G  AxCl_ME1ExtCmdGain_ICl= 1		// 10*H nA/V,  H is 0.1 currently (see headstage)
//	Variable/G AxCl_VCExtCmdGain_VCl = 0.02			// 20mV/V
//	Variable/G ExtCmdFrontGain_VCl=0.02			// AxoPatch gains: 20mV/mV   default name is AxoPatch
//	Variable/G ExtCmdFrontGain_ICl:=2/mybeta		// 2/betagain nA/V;  e.g., sending 1V delivers 2nA if beta=1, or 20nA if beta=0.1
//	Variable /G ExtCmdRearGain_VCl=100
//	Variable /G ExtCmdRearGain_ICl:=2/mybeta
	Variable/G ExtracellStimGain=1
	
	// there's going to be a problem here with selecting the right gains given the mode of the 2 different amps, if one
	// amp is in Vclamp & thoe other is in Current clamp:
	// update these variable names:
	make/N=4/O DAC_KnownGain_VCl={MuCl_Command_VCl}
	make/N=4/O DAC_KnownGain_ICl={MuCl_Command_ICl}
	
	// Set up DAC Amp Gains by channel:
	variable/G DAC0_AmpGain_VCl=MuCl_Command_VCl
	variable/G DAC1_AmpGain_VCl=1
	Make /O/N=2 DAC_AmpGain_VCl_Wave = {DAC0_AmpGain_VCl,DAC1_AmpGain_VCl}
	
	variable/G DAC0_AmpGain_ICl=MuCl_Command_ICl
	variable/G DAC1_AmpGain_ICl=1
	Make /O/N=2 DAC_AmpGain_ICl_Wave = {DAC0_AmpGain_ICl,DAC1_AmpGain_ICl}

	Execute "NIDAQSwitchBoard()"
	SetDataFolder dfSave
	
	/// Set up Data folder for telegraph processes:
	dfSave=GetDataFolder(1)
	NewDataFolder /O/S root:TelegraphAcqVar
	Killwaves /A/Z
	Killvariables /A/Z
	Killstrings /A/Z
	SetDataFolder dfSave
	
	
	
end
	



Window NIDAQSwitchBoard() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(138,509,914,905)
	ModifyPanel cbRGB=(65535,60076,49151)
	ShowTools
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (65535,32764,16385)
	DrawRRect 6,7,353,35
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 18,30,"NIDAQ SwitchBoard Control Panel Multiclamp"
	SetDrawEnv fsize= 10
	DrawText 86,120,"BNC Input"
	SetDrawEnv fsize= 10,fstyle= 4
	DrawText 563,35,"Gain:     V-Cl      I-Cl"
	SetDrawEnv fsize= 10
	DrawText 424,37,"BNC Output"
	SetDrawEnv fsize= 10
	DrawText 194,121,"Amp gain"
	SetDrawEnv fsize= 10,fstyle= 2
	DrawText 197,90,"(samples/sec)"
	DrawText 10,123,"ADC"
	SetDrawEnv fsize= 10,fstyle= 4
	DrawText 561,158," V-Cl  "
	SetDrawEnv fsize= 10,fstyle= 2
	DrawText 285,129,"User entered values:"
	SetDrawEnv fsize= 10,fstyle= 4
	DrawText 658,159," I-Cl  "
	GroupBox MulticlampSealTestGroup,pos={268,164},size={151,107},title="Multiclamp Seal Test"
	GroupBox DateGroup,pos={456,106},size={265,132},title="Input Resistance Multiclamp"
	PopupMenu ADC0inputPopup,pos={40,133},size={160,21},bodyWidth=160,proc=UpdateADC0_SignalWave
	PopupMenu ADC0inputPopup,font="Times New Roman"
	PopupMenu ADC0inputPopup,mode=2,popvalue="PrimaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	PopupMenu ADC1inputPopup,pos={40,158},size={160,21},bodyWidth=160,proc=UpdateADC1_SignalWave
	PopupMenu ADC1inputPopup,mode=3,popvalue="SecondaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	PopupMenu ADC2inputPopup,pos={40,184},size={160,21},bodyWidth=160,proc=UpdateADC2_SignalWave
	PopupMenu ADC2inputPopup,mode=4,popvalue="TemperatureProbe",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	PopupMenu ADC3inputPopup,pos={40,210},size={160,21},bodyWidth=160,proc=UpdateADC3_SignalWave
	PopupMenu ADC3inputPopup,mode=1,popvalue="_none_",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	PopupMenu ADC4inputPopup,pos={40,236},size={160,21},bodyWidth=160,proc=UpdateADC4_SignalWave
	PopupMenu ADC4inputPopup,mode=1,popvalue="_none_",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	PopupMenu ADC5inputPopup,pos={40,263},size={160,21},bodyWidth=160,proc=UpdateADC5_SignalWave
	PopupMenu ADC5inputPopup,mode=1,popvalue="_none_",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	PopupMenu ADC6inputPopup,pos={40,292},size={160,21},bodyWidth=160,proc=UpdateADC6_SignalWave
	PopupMenu ADC6inputPopup,mode=1,popvalue="_none_",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	PopupMenu ADC7inputPopup,pos={40,320},size={160,21},bodyWidth=160,proc=UpdateADC7_SignalWave
	PopupMenu ADC7inputPopup,mode=1,popvalue="_none_",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	SetVariable ADC0_AmpGainSetVar,pos={199,134},size={40,16},proc=Update_AmpGainWave,title="  "
	SetVariable ADC0_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:ADC0_AmpGain
	SetVariable ADC1_AmpGainSetVar,pos={199,161},size={40,16},proc=Update_AmpGainWave,title="  "
	SetVariable ADC1_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:ADC1_AmpGain
	SetVariable ADC2_AmpGainSetVar,pos={199,187},size={40,16},proc=Update_AmpGainWave,title="  "
	SetVariable ADC2_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:ADC2_AmpGain
	SetVariable ADC3_AmpGainSetVar,pos={199,213},size={40,16},proc=Update_AmpGainWave,title="  "
	SetVariable ADC3_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:ADC3_AmpGain
	SetVariable ADC4_AmpGainSetVar,pos={199,239},size={40,16},proc=Update_AmpGainWave,title="  "
	SetVariable ADC4_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:ADC4_AmpGain
	SetVariable ADC5_AmpGainSetVar,pos={199,266},size={40,16},proc=Update_AmpGainWave,title="  "
	SetVariable ADC5_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:ADC5_AmpGain
	SetVariable ADC6_AmpGainSetVar,pos={199,295},size={40,16},proc=Update_AmpGainWave,title="  "
	SetVariable ADC6_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:ADC6_AmpGain
	SetVariable ADC7_AmpGainSetVar,pos={200,323},size={40,16},proc=Update_AmpGainWave,title="  "
	SetVariable ADC7_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:ADC7_AmpGain
	ValDisplay ADC0_ChannelDisp,pos={10,133},size={20,14}
	ValDisplay ADC0_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay ADC0_ChannelDisp,value= #"root:NIDAQBoardVar:ADC0_Channel"
	ValDisplay ADC1_ChannelDisp,pos={12,162},size={18,14}
	ValDisplay ADC1_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay ADC1_ChannelDisp,value= #"root:NIDAQBoardvar:ADC1_Channel"
	ValDisplay ADC2_ChannelDisp,pos={12,188},size={19,14}
	ValDisplay ADC2_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay ADC2_ChannelDisp,value= #" root:NIDAQBoardVar:ADC2_Channel"
	ValDisplay ADC3_ChannelDisp,pos={12,214},size={19,14}
	ValDisplay ADC3_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay ADC3_ChannelDisp,value= #" root:NIDAQBoardVar:ADC3_Channel"
	ValDisplay ADC4_ChannelDisp,pos={12,240},size={17,14}
	ValDisplay ADC4_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay ADC4_ChannelDisp,value= #" root:NIDAQBoardVar:ADC4_Channel"
	ValDisplay ADC5_ChannelDisp,pos={12,267},size={19,14}
	ValDisplay ADC5_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay ADC5_ChannelDisp,value= #"root:NIDAQBoardVar:ADC5_Channel"
	ValDisplay ADC6_ChannelDisp,pos={12,296},size={18,14}
	ValDisplay ADC6_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay ADC6_ChannelDisp,value= #" root:NIDAQBoardVar:ADC6_Channel"
	ValDisplay ADC7_ChannelDisp,pos={12,324},size={20,14}
	ValDisplay ADC7_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay ADC7_ChannelDisp,value= #" root:NIDAQBoardvar:ADC7_Channel"
	GroupBox DACSwitchBoardGroup,pos={357,6},size={327,90},title="Digital-to-analog parameters"
	GroupBox ADCSwitchBoardGroup,pos={1,96},size={247,255},title="Analog-to-digital parameters"
	ValDisplay DAC0_ChannelDisp,pos={368,43},size={44,14},title="DAC"
	ValDisplay DAC0_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay DAC0_ChannelDisp,value= #" root:NIDAQBoardVar:DAC0_Channel"
	ValDisplay DAC1_ChannelDisp,pos={368,69},size={44,14},title="DAC"
	ValDisplay DAC1_ChannelDisp,limits={0,0,0},barmisc={0,1000}
	ValDisplay DAC1_ChannelDisp,value= #" root:NIDAQBoardVar:DAC1_Channel"
	SetVariable DAC0_AmpGainSetVar,pos={588,42},size={40,16},proc=Update_DACAmpGainWave,title="  "
	SetVariable DAC0_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:DAC0_AmpGain_VCl
	SetVariable DAC1_AmpGainSetVar,pos={589,68},size={40,16},proc=Update_DACAmpGainWave,title="  "
	SetVariable DAC1_AmpGainSetVar,limits={0.05,500,0},value= root:NIDAQBoardVar:DAC1_AmpGain_VCl
	PopupMenu DAC0inputPopup,pos={423,40},size={160,21},bodyWidth=160,proc=UpdateDAC0_SignalWave
	PopupMenu DAC0inputPopup,font="Times New Roman"
	PopupMenu DAC0inputPopup,mode=2,popvalue="Command",value= #"root:NIDAQBoardVar:OutputNamesString"
	PopupMenu DAC1inputPopup,pos={423,66},size={160,21},bodyWidth=160,proc=UpdateDAC1_SignalWave
	PopupMenu DAC1inputPopup,font="Times New Roman"
	PopupMenu DAC1inputPopup,mode=3,popvalue="Mode",value= #"root:NIDAQBoardVar:OutputNamesString"
	SetVariable DAC0_AmpGainSetVar01,pos={637,42},size={34,16},proc=Update_DACAmpGainWave,title=" "
	SetVariable DAC0_AmpGainSetVar01,limits={0.05,500,0},value= root:NIDAQBoardVar:DAC0_AmpGain_ICl
	SetVariable DAC1_AmpGainSetVar01,pos={636,68},size={34,16},proc=Update_DACAmpGainWave,title=" "
	SetVariable DAC1_AmpGainSetVar01,limits={0.05,500,0},value= root:NIDAQBoardVar:DAC1_AmpGain_ICl
	SetVariable CurrentDateDisplay,pos={7,59},size={154,16},title="Today's Date : "
	SetVariable CurrentDateDisplay,value= root:DataAcquisitionVar:DateStr
	SetVariable CellNumSetVar,pos={9,81},size={147,16},title="Current Cell #"
	SetVariable CellNumSetVar,value= root:DataAcquisitionVar:CellNum
	SetVariable BasenameSetVar,pos={9,41},size={240,16},title="Global Waves Basename  "
	SetVariable BasenameSetVar,value= root:DataAcquisitionVar:Basename
	SetVariable ResolutionSetVar,pos={171,60},size={170,16},title="Acquisition Resolution"
	SetVariable ResolutionSetVar,limits={1000,30000,500},value= root:DataAcquisitionVar:AcqResolution
	SetVariable setvar0,pos={475,161},size={137,16},title="Amplitude: (V)"
	SetVariable setvar0,limits={-0.1,0.1,0.005},value= root:DataAcquisitionVar:IRpulse_amp_VC
	SetVariable setvar1,pos={475,178},size={140,16},title="Duration(sec): "
	SetVariable setvar1,limits={0,0.1,0.01},value= root:DataAcquisitionVar:IRpulse_dur_VC
	SetVariable setvar2,pos={619,161},size={84,16},title=" (nA)"
	SetVariable setvar2,limits={-1,1,0.01},value= root:DataAcquisitionVar:IRpulse_amp_IC
	SetVariable setvar3,pos={649,179},size={55,16},title=" "
	SetVariable setvar3,limits={0,1,0.005},value= root:DataAcquisitionVar:IRpulse_dur_IC
	Button SaveExptButton,pos={255,38},size={87,21},proc=SaveExpt,title="SAVE expt"
	PopupMenu AxoClamp_SetModePopup,pos={285,131},size={110,21},proc=Update_MulticlampMode,title="Mode:"
	PopupMenu AxoClamp_SetModePopup,mode=1,popvalue="V-clamp",value= #"\"I-clamp;V-clamp\""
	Button AxoClSealTestButton,pos={285,224},size={123,41},proc=MClampSealButtonProc,title="Multiclamp Seal Test"
	SetVariable Seal_ISI,pos={287,182},size={88,16},title="ISI (s)"
	SetVariable Seal_ISI,limits={0.1,10,0.1},value= root:DataAcquisitionVar:SealTest_ISI
	SetVariable SealTest_numpulsessetvar,pos={288,204},size={90,16},title="# pulses"
	SetVariable SealTest_numpulsessetvar,limits={0,inf,10},value= root:DataAcquisitionVar:SealTestNumPulses
	GroupBox MulticlampModeGroup1,pos={271,100},size={151,61},title="Multiclamp Mode Selection"
EndMacro



///********************************************************************************
// Accessory procs:  Switchboardupdate.ipf and telegraphs.ipf
// no longer need incldue statement
//*******************************************************************************************





//Function UpdateTelegrButton(ctrlName) : ButtonControl
//	String ctrlName
//	Execute "UpdateTelegraphs()"
//End
//
//function UpdateTelegraphs()
//	// Get the relevent Waves from Switchboard for the telegraph readings	
//	WAVE/T ADC_SignalWave= root:NIDAQBoardVar:ADC_SignalWave
//	WAVE ADC_AmpGainWave= root:NIDAQBoardVar:ADC_AmpGainWave
//	WAVE ADC_IndBoardGainWave= root:NIDAQBoardVar:ADC_IndBoardGainWave
//	// Pass variables to contain useful telegraph values/strings based on raw telegraph voltage readings:
//	NVAR Current_TG_Gain	=	root:NIDAQBoardVar:Current_TG_Gain		
//	SVAR  Current_TG_Mode=	root:NIDAQBoardVar:Current_TG_Mode
//	SVAR Current_ScaledOutType=root:NIDAQBoardVar:Current_ScaledOutType
//	NVAR Current_TG_Filter	=root:NIDAQBoardVar:Current_TG_Filter
//	NVAR current_TG_Capac	=root:NIDAQBoardVar:current_TG_Capac		
//	NVAR AcqResolution	= root:DataAcquisitionVar:AcqResolution
//	NVAR BoardID	=root:NIDAQBoardVar:boardid
//	//  Create Waves to acquire telegraph readings:
//	variable err
//	
//	String dfSave=GetDataFolder(1)
//	SetDataFolder root:TelegraphAcqVar
//	
//	Make /N=10/O TG_Gain_Reading,TG_Mode_Reading	,TG_Filter_Reading,TG_Capac_Reading
//	SetScale /P x 0, (1/AcqResolution), "sec",TG_Gain_Reading,TG_Mode_Reading	,TG_Filter_Reading,TG_Capac_Reading
//
//	
//	Variable Channel_TG_Gain,Channel_TG_Mode,Channel_TG_Filter,Channel_TG_Capac
//	String SignalList=convertTextWavetoList(ADC_SignalWave)
//	
//	Channel_TG_Gain=WhichListItem("Telegraph_Gain",SignalList,";")
//	Channel_TG_Mode=WhichListItem("Telegraph_Mode",SignalList,";")
//	Channel_TG_Filter=WhichListItem("Telegraph_Frequency",SignalList,";")
//	Channel_TG_Capac=WhichListItem("Telegraph_CellCapac",SignalList,";")
//	print "channel for gain,mode,filt,capac" 
//	print Channel_TG_Gain,Channel_TG_Mode,Channel_TG_Filter,Channel_TG_Capac
//	String AcqString =""
//	String WFOutString=""
//	if(Channel_TG_Gain!=-1)		// make sure channel is selected on Switchboard
//		//AcqString="TG_Gain_Reading," + num2str(Channel_TG_Gain) + "," +num2str(ADC_IndBoardGainWave[channel_TG_Gain]) +";"
//		AcqString="TG_Gain_Reading," + num2str(Channel_TG_Gain)  +";"
//	endif
//	if(Channel_TG_Mode!=-1)
//		//AcqString+="TG_Mode_Reading," + num2str(Channel_TG_Mode) + "," +num2str(ADC_IndBoardGainWave[channel_TG_Mode]) +";"
//		AcqString+="TG_Mode_Reading," + num2str(Channel_TG_Mode)  +";"
//	endif
//	if(Channel_TG_Filter!=-1)
//		//AcqString+="TG_Filter_Reading," + num2str(Channel_TG_Filter) + "," +num2str(ADC_IndBoardGainWave[channel_TG_Filter]) +";"
//		AcqString+="TG_Filter_Reading," + num2str(Channel_TG_Filter) +";"
//	endif
//	if(channel_TG_Capac!=-1)
//		//AcqString+="TG_Capac_Reading," + num2str(Channel_TG_Capac) + "," +num2str(ADC_IndBoardGainWave[channel_TG_Capac]) +";"
//		AcqString+="TG_Capac_Reading," + num2str(Channel_TG_Capac) +";"
//	endif
//
//
//	//must change NIDAQ board to 0-10V range, b/c Axopatch telegraphs go from 0-6.5 volts:
////	SetupBoards_2()
//	if(!strlen(AcqString)==0)
//		print "Beginning acquisition of the following (wave, channel, board gain):"
//		print "       ", acqString
//		mySimpleAcqRoutine(WFOutString,AcqString)
//	
//		//SetupBoards_1()	//return to -5 to +5V	
//		// Fake Data generation
//		//TG_Gain_Reading=abs(enoise(6.55))
//		//TG_Mode_Reading=abs(enoise(8))+2
//		//TG_Filter_Reading=abs(enoise(8))+2
//		//TG_Capac_Reading=abs(enoise(50))		// choice of 50 is arbitrary;
//	
//	
//	
//		// convert Readings to results:
//		if(1)
//			print "Gain reading is : " + num2str(mean(TG_Gain_Reading,-Inf,Inf))
//			print "Mode reading is : " + num2str(mean(TG_Mode_Reading,-Inf,Inf))
//			print "Filter reading is: " + num2str(mean(TG_Filter_REading,-Inf,inf))
//			print "Capacitance reading is: " + num2str(mean(TG_Capac_reading,-inf,inf)) 
//		endif
//		Notebook Parameter_Log ruler=Normal, text = "\r\rUpdating Telegraph Values:\r"	
//		
//		if(Channel_TG_Gain!=-1) 
//			TG_Gain_Reading*=ADC_AmpGainWave[Channel_TG_Gain]		// condition acquired wave by amplifier gain
//			make/O Gain_ReadingWave={0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5}
//			make/O Gain_ResultWave={0.05,0.1,0.2,0.5,1,2,5,10,20,50,100,200,500}
//			FindValue /V=(mean(TG_Gain_Reading,-Inf,Inf))/T=0.1Gain_ReadingWave
//			Current_TG_Gain=Gain_ResultWave[V_value]
//			//Current_tg_Gain=1
//			//print mean(TG_Gain_Reading,-Inf,Inf)
//			Notebook Parameter_Log ruler=Normal, text="\tScaledOutput Total Gain = \t" +  num2str(Current_TG_Gain) +"\r"
//		endif
//		
//		if(Channel_TG_Mode!=-1)
//			//print ADC_AmpGainWave[Channel_TG_Mode]	
//			TG_Mode_Reading*=ADC_AmpGainWave[Channel_TG_Mode]		// condition acquired wave by amplifier gain
//			//print TG_Mode_Reading
//			make/O Mode_ReadingWave={4,6,3,2,1}			// check these numbers
//			make/T/O Mode_ResultWave={"Track","V-Clamp", "I=0","I-Clamp Normal","I-Clamp Fast"}
//			make/T/O ScaledOutSignalTypeWave={"Current","Current","Voltage","Voltage","Voltage"}		
//			FindValue /V=(mean(TG_Mode_Reading,-Inf,Inf))/T=0.25 Mode_ReadingWave
//			current_TG_Mode=Mode_resultWave[V_value]
//			Current_ScaledOutType=ScaledOutSignalTypeWave[V_value]
//			Notebook Parameter_Log ruler=Normal, text="\tMode=\t" + Current_TG_Mode +"\r"
//			Notebook Parameter_Log ruler=Normal, text=" \tScaled Output Signal type = \t" +  Current_ScaledOutType +"\r"
//		endif
//	
//		if(Channel_TG_Filter!=-1)
//			TG_Filter_Reading*=ADC_AmpGainWave[Channel_TG_Filter]	// condition acquired wave by amplifier gain
//			Make /O Filter_REadingWAve={2,4,6,8,10}  // check these numbers
//			Make/O Filter_ResultWave={1,2,5,10,100}
//			FindValue /V=(mean(TG_Filter_Reading,-Inf,Inf))/T=0.5 Filter_ReadingWave
//			Current_TG_Filter=Filter_ResultWave[V_value]
//			//print mean(TG_Filter_Reading,-Inf,Inf)
//			Notebook Parameter_Log ruler=Normal, text="\tFilter Frequency =  \t" +  num2str(Current_TG_Filter) +"\r"
//		endif
//	
//		if(Channel_TG_Capac!=-1)
//			TG_Capac_Reading*=ADC_AmpGainWave[Channel_TG_Capac]	// condition acquired wave by amplifier gain
//			variable GainFunction=1		// pF/V				// find the correct relationship.  depends on beta??
//			Current_TG_Capac=GainFunction*TG_Capac_Reading
//			//print mean(TG_Capac_Reading,-Inf,Inf)
//			Notebook Parameter_Log ruler=Normal, text="\tCell Capacitance dial = \t" +  num2str(Current_TG_Capac) +"\r"
//		endif
//
//		Notebook Parameter_Log ruler=Normal, text="\tTime :    " + time() +"\r\r"
//	
//	else
//		print "No channels selected, no telegraphs read"
//	endif
//	//
//	ControlUpdate/A/W=NIDAQSwitchBoard			// Update the SwitchBoard control
//	SetDataFolder dfSave
//end
//
////*****end telegraphs*****************************************************************
//// switchboard update functions:*************************************************************
///// Updated procedures to accommodate NIDAQ/Data Acquisition Board Version 2 - 2 amplifier.
//
//Function UpdateBetaProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr	
//	NVAR mybeta = root:NIDAQBoardVar:mybeta
//	mybeta = str2num(popStr)
//	print "Setting presumed beta gain to: ", num2str(mybeta)
//	
//	NVAR AxoPatchIOutputGain =  root:NIDAQBoardVar:AxoPatchIOutputGain  // need to find a way to update the switchboard values affected by beta.
//	
//	ControlUpdate/A/W=NIDAQSwitchBoard
//
//End

//function Update_AxoclampMode(ctrlName,popNum,popStr) : PopupMenucontrol
//	string ctrlname
//	Variable popNum
//	String popStr	
//	SVAR  Current_AxClMode=	root:NIDAQBoardVar:Current_AxClMode
//	Current_AxClMode = popStr
//	
//	print "changing Axoclamp mode to: " + Current_AxClMode
//end

function Update_DACAmpGainWave(ctrlName,varNum,varStr,varName) : SetVariablecontrol
	string ctrlname
	variable varNum
	string VarStr
	string varName
	NVAR DAC0_AmpGain_VCl	= root:NIDAQBoardVar:DAC0_AmpGain_VCl
	NVAR DAC0_AmpGain_ICl	= root:NIDAQBoardVar:DAC0_AmpGain_ICl
	NVAR DAC1_AmpGain_VCl	= root:NIDAQBoardVar:DAC1_AmpGain_VCl
	NVAR DAC1_AmpGain_ICl	= root:NIDAQBoardVar:DAC1_AmpGain_ICl	
	WAVE DAC_AmpGain_VCl_Wave	= root:NIDAQBoardVar:DAC_AmpGain_VCl_Wave
	WAVE DAC_AmpGain_ICl_Wave	= root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	DAC_AmpGain_VCl_Wave[0]=DAC0_AmpGain_VCl
	DAC_AmpGain_VCl_Wave[1]=DAC1_AmpGain_VCl
	DAC_AmpGain_ICl_Wave[0]=DAC0_AmpGain_ICl
	DAC_AmpGain_ICl_Wave[1]=DAC1_AmpGain_ICl
end


function Update_AmpGainWave(ctrlName,varNum,varStr,varName) : SetVariablecontrol
	string ctrlname
	variable varNum
	string VarStr
	string varName
	NVAR ADC0_AmpGain	= root:NIDAQBoardVar:ADC0_AmpGain
	NVAR ADC1_AmpGain	= root:NIDAQBoardVar:ADC1_AmpGain
	NVAR ADC2_AmpGain	= root:NIDAQBoardVar:ADC2_AmpGain
	NVAR ADC3_AmpGain	= root:NIDAQBoardVar:ADC3_AmpGain
	NVAR ADC4_AmpGain	= root:NIDAQBoardVar:ADC4_AmpGain
	NVAR ADC5_AmpGain	= root:NIDAQBoardVar:ADC5_AmpGain
	NVAR ADC6_AmpGain	= root:NIDAQBoardVar:ADC6_AmpGain
	NVAR ADC7_AmpGain	= root:NIDAQBoardVar:ADC7_AmpGain
	WAVE ADC_AmpGainWave = root:NIDAQBoardVar:ADC_AmpGainWave
	
	ADC_AmpGainWave[0]=ADC0_AmpGain
	ADC_AmpGainWave[1]=ADC1_AmpGain
	ADC_AmpGainWave[2]=ADC2_AmpGain
	ADC_AmpGainWave[3]=ADC3_AmpGain
	ADC_AmpGainWave[4]=ADC4_AmpGain
	ADC_AmpGainWave[5]=ADC5_AmpGain
	ADC_AmpGainWave[6]=ADC6_AmpGain
	ADC_AmpGainWave[7]=ADC7_AmpGain

end	




Function UpdateADC0_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	WAVE/T ADC_SignalWave= root:NIDAQBoardVar:ADC_SignalWave
	SVAR ADC0_Signal=root:NIDAQBoardVar:ADC0_Signal	
	ADC0_Signal=popStr
	print "Changing signal on channel 0 to ", ADC0_Signal, " Popnum = " , num2str(popnum)
	ADC_SignalWave[0]=ADC0_Signal	
	// Also update the gains:
	WAVE ADC_AMPGainWave= root:NIDAQBoardVar:ADC_AMPGainWave
	NVAR ADC0_AmpGain = root:NIDAQBoardVar:ADC0_AmpGain
	NVAR  PrimaryoutputGain		= root:NIDAQBoardVar:PrimaryoutputGain		// default: assume Vclamp mode, so primary gain = Current output
	NVAR   SecondaryoutputGain = root:NIDAQBoardVar:SecondaryoutputGain
	NVAR AxoPatchScaledOutputGain	=	root:NIDAQBoardVar:AxoPatchScaledOutputGain
	WAVE  ADC_KnownAmpGainWave=  root:NIDAQBoardVar: ADC_KnownAmpGainWave
	if(stringmatch(popStr,"_none_"))
		ADC0_AmpGain=1
	else
		if(stringmatch(popStr,"PrimaryOutCh1"))
			ADC0_AmpGain=PrimaryoutputGain
		else
		
			if(stringmatch(popStr,"SecondaryOutCh1"))
				ADC0_AmpGain =SecondaryoutputGain		
			else
				ADC0_AmpGain = ADC_KnownAmpGainWave[popNum-2]	
			endif
		endif	
	endif															// are 1-based, while wave indexing is 0-based.
	print "Updating the amplifier gain on this channel to ", num2str(ADC0_AmpGain)
	print ADC_SignalWave
	ADC_AmpGainWave[0]=ADC0_AmpGain
	
	ControlUpdate/A/W=NIDAQSwitchBoard
End


Function UpdateADC1_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	WAVE/T ADC_SignalWave= root:NIDAQBoardVar:ADC_SignalWave
	SVAR ADC1_Signal=root:NIDAQBoardVar:ADC1_Signal	
	ADC1_Signal=popStr
	print "Changing signal on channel 1  to ", ADC1_Signal, " Popnum = " , num2str(popnum)
	ADC_SignalWave[1]=ADC1_Signal	
	// Also update the gains:
	WAVE ADC_AMPGainWave= root:NIDAQBoardVar:ADC_AMPGainWave
	NVAR ADC1_AmpGain = root:NIDAQBoardVar:ADC1_AmpGain
	NVAR  PrimaryoutputGain		= root:NIDAQBoardVar:PrimaryoutputGain		// default: assume Vclamp mode, so primary gain = Current output
	NVAR   SecondaryoutputGain = root:NIDAQBoardVar:SecondaryoutputGain
	NVAR AxoPatchScaledOutputGain	=	root:NIDAQBoardVar:AxoPatchScaledOutputGain
	WAVE  ADC_KnownAmpGainWave=  root:NIDAQBoardVar: ADC_KnownAmpGainWave
	if(stringmatch(popStr,"_none_"))
		ADC1_AmpGain=1
	else
		if(stringmatch(popStr,"PrimaryOutCh1"))
			ADC1_AmpGain=PrimaryoutputGain
		else
		
			if(stringmatch(popStr,"SecondaryOutCh1"))
				ADC1_AmpGain =SecondaryoutputGain		
			else
				ADC1_AmpGain = ADC_KnownAmpGainWave[popNum-2]	
			endif
		endif	
	endif															// are 1-based, while wave indexing is 0-based.
	print "Updating the amplifier gain on this channel to ", num2str(ADC1_AmpGain)
	ADC_AmpGainWave[1]=ADC1_AmpGain
	print ADC_SignalWave
	ControlUpdate/A/W=NIDAQSwitchBoard
End

Function UpdateADC2_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	WAVE/T ADC_SignalWave= root:NIDAQBoardVar:ADC_SignalWave
	SVAR ADC2_Signal=root:NIDAQBoardVar:ADC2_Signal	
	ADC2_Signal=popStr
	print "Changing signal on channel 2  to ", ADC2_Signal, " Popnum = " , num2str(popnum)
	ADC_SignalWave[2]=ADC2_Signal	
	// Also update the gains:
	WAVE ADC_AMPGainWave= root:NIDAQBoardVar:ADC_AMPGainWave
	NVAR ADC2_AmpGain = root:NIDAQBoardVar:ADC2_AmpGain
	NVAR  PrimaryoutputGain		= root:NIDAQBoardVar:PrimaryoutputGain		// default: assume Vclamp mode, so primary gain = Current output
	NVAR   SecondaryoutputGain = root:NIDAQBoardVar:SecondaryoutputGain
	NVAR AxoPatchScaledOutputGain	=	root:NIDAQBoardVar:AxoPatchScaledOutputGain
	WAVE  ADC_KnownAmpGainWave=  root:NIDAQBoardVar: ADC_KnownAmpGainWave
	if(stringmatch(popStr,"_none_"))
		ADC2_AmpGain=1
	else
		if(stringmatch(popStr,"PrimaryOutCh1"))
			ADC2_AmpGain=PrimaryoutputGain
		else
		
			if(stringmatch(popStr,"SecondaryOutCh1"))
				ADC2_AmpGain =SecondaryoutputGain		
			else
				ADC2_AmpGain = ADC_KnownAmpGainWave[popNum-2]	
			endif
		endif	
	endif															// are 1-based, while wave indexing is 0-based.
	print "Updating the amplifier gain on this channel to ", num2str(ADC2_AmpGain)
	ADC_AmpGainWave[2]=ADC2_AmpGain
	
	ControlUpdate/A/W=NIDAQSwitchBoard
End





Function UpdateADC3_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	WAVE/T ADC_SignalWave= root:NIDAQBoardVar:ADC_SignalWave
	SVAR ADC3_Signal=root:NIDAQBoardVar:ADC3_Signal	
	ADC3_Signal=popStr
	print "Changing signal on channel 3  to ", ADC3_Signal, " Popnum = " , num2str(popnum)
	ADC_SignalWave[3]=ADC3_Signal	
	// Also update the gains:
	WAVE ADC_AMPGainWave= root:NIDAQBoardVar:ADC_AMPGainWave
	NVAR ADC3_AmpGain = root:NIDAQBoardVar:ADC3_AmpGain
	NVAR  PrimaryoutputGain		= root:NIDAQBoardVar:PrimaryoutputGain		// default: assume Vclamp mode, so primary gain = Current output
	NVAR   SecondaryoutputGain = root:NIDAQBoardVar:SecondaryoutputGain
	NVAR AxoPatchScaledOutputGain	=	root:NIDAQBoardVar:AxoPatchScaledOutputGain
	WAVE  ADC_KnownAmpGainWave=  root:NIDAQBoardVar: ADC_KnownAmpGainWave
	if(stringmatch(popStr,"_none_"))
		ADC3_AmpGain=1
	else
		if(stringmatch(popStr,"PrimaryOutCh1"))
			ADC3_AmpGain=PrimaryoutputGain
		else
		
			if(stringmatch(popStr,"SecondaryOutCh1"))
				ADC3_AmpGain =SecondaryoutputGain		
			else
				ADC3_AmpGain = ADC_KnownAmpGainWave[popNum-2]	
			endif
		endif	
	endif															// are 1-based, while wave indexing is 0-based.
	print "Updating the amplifier gain on this channel to ", num2str(ADC3_AmpGain)
	ADC_AmpGainWave[3]=ADC3_AmpGain
	
	ControlUpdate/A/W=NIDAQSwitchBoard
End

Function UpdateADC4_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	WAVE/T ADC_SignalWave= root:NIDAQBoardVar:ADC_SignalWave
	SVAR ADC4_Signal=root:NIDAQBoardVar:ADC4_Signal	
	ADC4_Signal=popStr
	print "Changing signal on channel 4  to ", ADC4_Signal, " Popnum = " , num2str(popnum)
	ADC_SignalWave[4]=ADC4_Signal	
	// Also update the gains:
	WAVE ADC_AMPGainWave= root:NIDAQBoardVar:ADC_AMPGainWave
	NVAR ADC4_AmpGain = root:NIDAQBoardVar:ADC4_AmpGain
	NVAR  PrimaryoutputGain		= root:NIDAQBoardVar:PrimaryoutputGain		// default: assume Vclamp mode, so primary gain = Current output
	NVAR   SecondaryoutputGain = root:NIDAQBoardVar:SecondaryoutputGain
	NVAR AxoPatchScaledOutputGain	=	root:NIDAQBoardVar:AxoPatchScaledOutputGain
	WAVE  ADC_KnownAmpGainWave=  root:NIDAQBoardVar: ADC_KnownAmpGainWave
	if(stringmatch(popStr,"_none_"))
		ADC4_AmpGain=1
	else
		if(stringmatch(popStr,"PrimaryOutCh1"))
			ADC4_AmpGain=PrimaryoutputGain
		else
		
			if(stringmatch(popStr,"SecondaryOutCh1"))
				ADC4_AmpGain =SecondaryoutputGain		
			else
				ADC4_AmpGain = ADC_KnownAmpGainWave[popNum-2]	
			endif
		endif	
	endif															// are 1-based, while wave indexing is 0-based.
	print "Updating the amplifier gain on this channel to ", num2str(ADC4_AmpGain)
	ADC_AmpGainWave[4]=ADC4_AmpGain
	
	ControlUpdate/A/W=NIDAQSwitchBoard
End



Function UpdateADC5_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	WAVE/T ADC_SignalWave= root:NIDAQBoardVar:ADC_SignalWave
	SVAR ADC5_Signal=root:NIDAQBoardVar:ADC5_Signal	
	ADC5_Signal=popStr
	print "Changing signal on channel 5  to ", ADC5_Signal, " Popnum = " , num2str(popnum)
	ADC_SignalWave[5]=ADC5_Signal	
	// Also update the gains:
	WAVE ADC_AMPGainWave= root:NIDAQBoardVar:ADC_AMPGainWave
	NVAR ADC5_AmpGain = root:NIDAQBoardVar:ADC5_AmpGain
	NVAR  PrimaryoutputGain		= root:NIDAQBoardVar:PrimaryoutputGain		// default: assume Vclamp mode, so primary gain = Current output
	NVAR   SecondaryoutputGain = root:NIDAQBoardVar:SecondaryoutputGain
	NVAR AxoPatchScaledOutputGain	=	root:NIDAQBoardVar:AxoPatchScaledOutputGain
	WAVE  ADC_KnownAmpGainWave=  root:NIDAQBoardVar: ADC_KnownAmpGainWave
	if(stringmatch(popStr,"_none_"))
		ADC5_AmpGain=1
	else
		if(stringmatch(popStr,"PrimaryOutCh1"))
			ADC5_AmpGain=PrimaryoutputGain
		else
		
			if(stringmatch(popStr,"SecondaryOutCh1"))
				ADC5_AmpGain =SecondaryoutputGain		
			else
				ADC5_AmpGain = ADC_KnownAmpGainWave[popNum-2]	
			endif
		endif	
	endif															// are 1-based, while wave indexing is 0-based.
	print "Updating the amplifier gain on this channel to ", num2str(ADC5_AmpGain)
	ADC_AmpGainWave[5]=ADC5_AmpGain
	
	ControlUpdate/A/W=NIDAQSwitchBoard
End



Function UpdateADC6_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	WAVE/T ADC_SignalWave= root:NIDAQBoardVar:ADC_SignalWave
	SVAR ADC6_Signal=root:NIDAQBoardVar:ADC6_Signal	
	ADC6_Signal=popStr
	print "Changing signal on channel 6 to ", ADC6_Signal, " Popnum = " , num2str(popnum)
	ADC_SignalWave[6]=ADC6_Signal	
	// Also update the gains:
	WAVE ADC_AMPGainWave= root:NIDAQBoardVar:ADC_AMPGainWave
	NVAR ADC6_AmpGain = root:NIDAQBoardVar:ADC6_AmpGain
	NVAR  PrimaryoutputGain		= root:NIDAQBoardVar:PrimaryoutputGain		// default: assume Vclamp mode, so primary gain = Current output
	NVAR   SecondaryoutputGain = root:NIDAQBoardVar:SecondaryoutputGain
	NVAR AxoPatchScaledOutputGain	=	root:NIDAQBoardVar:AxoPatchScaledOutputGain
	WAVE  ADC_KnownAmpGainWave=  root:NIDAQBoardVar: ADC_KnownAmpGainWave
	if(stringmatch(popStr,"_none_"))
		ADC6_AmpGain=1
	else
		if(stringmatch(popStr,"PrimaryOutCh1"))
			ADC6_AmpGain=PrimaryoutputGain
		else
		
			if(stringmatch(popStr,"SecondaryOutCh1"))
				ADC6_AmpGain =SecondaryoutputGain		
			else
				ADC6_AmpGain = ADC_KnownAmpGainWave[popNum-2]	
			endif
		endif	
	endif															// are 1-based, while wave indexing is 0-based.
	print "Updating the amplifier gain on this channel to ", num2str(ADC6_AmpGain)
	ADC_AmpGainWave[6]=ADC6_AmpGain
	
	ControlUpdate/A/W=NIDAQSwitchBoard
End

Function UpdateADC7_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	WAVE/T ADC_SignalWave= root:NIDAQBoardVar:ADC_SignalWave
	SVAR ADC7_Signal=root:NIDAQBoardVar:ADC7_Signal	
	ADC7_Signal=popStr
	print "Changing signal on channel 7 to ", ADC7_Signal, " Popnum = " , num2str(popnum)
	ADC_SignalWave[7]=ADC7_Signal	
	// Also update the gains:
	WAVE ADC_AMPGainWave= root:NIDAQBoardVar:ADC_AMPGainWave
	NVAR ADC7_AmpGain = root:NIDAQBoardVar:ADC7_AmpGain
	NVAR  PrimaryoutputGain		= root:NIDAQBoardVar:PrimaryoutputGain		// default: assume Vclamp mode, so primary gain = Current output
	NVAR   SecondaryoutputGain = root:NIDAQBoardVar:SecondaryoutputGain
	NVAR AxoPatchScaledOutputGain	=	root:NIDAQBoardVar:AxoPatchScaledOutputGain
	WAVE  ADC_KnownAmpGainWave=  root:NIDAQBoardVar: ADC_KnownAmpGainWave
	if(stringmatch(popStr,"_none_"))
		ADC7_AmpGain=1
	else
		if(stringmatch(popStr,"PrimaryOutCh1"))
			ADC7_AmpGain=PrimaryoutputGain
		else
		
			if(stringmatch(popStr,"SecondaryOutCh1"))
				ADC7_AmpGain =SecondaryoutputGain		
			else
				ADC7_AmpGain = ADC_KnownAmpGainWave[popNum-2]	
			endif
		endif	
	endif															// are 1-based, while wave indexing is 0-based.
	print "Updating the amplifier gain on this channel to ", num2str(ADC7_AmpGain)
	ADC_AmpGainWave[7]=ADC7_AmpGain
	
	ControlUpdate/A/W=NIDAQSwitchBoard
End







// end switchboard update functions


Function UpdateDAC0_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	print popStr
	WAVE/T DAC_SignalWave= root:NIDAQBoardVar:DAC_SignalWave
	SVAR DAC0_Signal=root:NIDAQBoardVar:DAC0_Signal	
	DAC0_Signal=popStr
	print "Changing signal on DA channel 0 to ", DAC0_Signal
	DAC_SignalWave[0]=DAC0_Signal	
	// Also update the gains:
	WAVE DAC_AmpGain_VCl_Wave= root:NIDAQBoardVar:DAC_AmpGain_VCl_Wave
	NVAR DAC0_AmpGain_VCl = root:NIDAQBoardVar:DAC0_AmpGain_VCl
	WAVE DAC_KnownGain_VCl= root:NIDAQBoardVar:DAC_KnownGain_VCl
	string list
	list=convertNumwavetolist(DAC_AmpGain_VCl_Wave)
	print DAC_AmpGain_VCl_Wave
	print "DAC_AmpGain_VCl_Wave : " , list
	if(stringmatch(popStr,"_none_") || stringmatch(popStr,"Extracellular SIU1")   || stringmatch(popStr,"Extracellular SIU2") || stringmatch(popStr,"Mode") )
		DAC0_AmpGain_VCl=1
	else
		DAC0_AmpGain_VCl = DAC_KnownGain_VCl[popNum-2]
	endif
	DAC_AmpGain_VCl_Wave[1]=DAC0_AmpGain_VCl
	print "Updating the V-clamp amplifier gain on this channel to ", num2str(DAC0_AmpGain_VCl)
	
	
	WAVE DAC_AmpGain_ICl_Wave=  root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	NVAR DAC0_AmpGain_ICl = root:NIDAQBoardVar:DAC0_AmpGain_ICl
	WAVE DAC_KnownGain_ICl= root:NIDAQBoardVar:DAC_KnownGain_ICl
	list=convertNumwavetolist(DAC_AmpGain_ICl_Wave)
	print "DAC_AmpGain_ICl_Wave : " , list
	if(stringmatch(popStr,"_none_") || stringmatch(popStr,"Extracellular SIU1")   || stringmatch(popStr,"Extracellular SIU2")  || stringmatch(popStr,"Mode")  )
		DAC0_AmpGain_ICl=1
	else
		DAC0_AmpGain_ICl = DAC_KnownGain_ICl[popNum-2]
	endif
	DAC_AmpGain_ICl_Wave[0]=DAC0_AmpGain_ICl
	print "Updating the I-clamp amplifier gain on this channel to ", num2str(DAC0_AmpGain_ICl)

	ControlUpdate/A/W=NIDAQSwitchBoard
End


Function UpdateDAC1_SignalWave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	print popNum
	print popStr
	WAVE/T DAC_SignalWave= root:NIDAQBoardVar:DAC_SignalWave
	SVAR DAC1_Signal=root:NIDAQBoardVar:DAC1_Signal	
	DAC1_Signal=popStr
	print "Changing signal on DA channel 1 to ", DAC1_Signal
	DAC_SignalWave[1]=DAC1_Signal	
	// Also update the gains:
	WAVE DAC_AmpGain_VCl_Wave= root:NIDAQBoardVar:DAC_AmpGain_VCl_Wave
	NVAR DAC1_AmpGain_VCl = root:NIDAQBoardVar:DAC1_AmpGain_VCl
	WAVE DAC_KnownGain_VCl= root:NIDAQBoardVar:DAC_KnownGain_VCl
	string list
	list=convertNumwavetolist(DAC_AmpGain_VCl_Wave)
	print DAC_AmpGain_VCl_Wave
	print "DAC_AmpGain_VCl_Wave : " , list
	if(stringmatch(popStr,"_none_") || stringmatch(popStr,"Extracellular SIU1")   || stringmatch(popStr,"Extracellular SIU2") || stringmatch(popStr,"Mode") )
		DAC1_AmpGain_VCl=1
	else
		DAC1_AmpGain_VCl = DAC_KnownGain_VCl[popNum-2]
	endif
	DAC_AmpGain_VCl_Wave[1]=DAC1_AmpGain_VCl
	print "Updating the V-clamp amplifier gain on this channel to ", num2str(DAC1_AmpGain_VCl)
	
	
	WAVE DAC_AmpGain_ICl_Wave=  root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	NVAR DAC1_AmpGain_ICl = root:NIDAQBoardVar:DAC1_AmpGain_ICl
	WAVE DAC_KnownGain_ICl= root:NIDAQBoardVar:DAC_KnownGain_ICl
	list=convertNumwavetolist(DAC_AmpGain_ICl_Wave)
	print "DAC_AmpGain_ICl_Wave : " , list
	if(stringmatch(popStr,"_none_") || stringmatch(popStr,"Extracellular SIU1")   || stringmatch(popStr,"Extracellular SIU2")  || stringmatch(popStr,"Mode")  )
		DAC1_AmpGain_ICl=1
	else
		DAC1_AmpGain_ICl = DAC_KnownGain_ICl[popNum-2]
	endif
	DAC_AmpGain_ICl_Wave[1]=DAC1_AmpGain_ICl
	print "Updating the I-clamp amplifier gain on this channel to ", num2str(DAC1_AmpGain_ICl)

	ControlUpdate/A/W=NIDAQSwitchBoard
End





Function MClampSealButtonProc(ctrlName) : ButtonControl
	String ctrlName
	variable duration
	variable amplitude
	variable outputGain
	variable DAC_out_Channel
	string DACsignalList,ADCsignalList
	string Output_Signal
	String WFOutString,AcqString
	string inputsignal
	variable inputchannel
	variable inputgain
	string OutWin_ylabel, InWin_ylabel
	// online R measure:
	variable  Res
	variable Step_outAmp, Step_InAmp
	variable Step_InBaseline
	variable Set_yaxis_ampl,Set_yaxis_ampl_Vcl,Set_yaxis_ampl_Icl,Yaxis_offset
	variable t_base, t_step, delta_t
	t_base = 0.01		// measure baseline at t_base sec
	delta_t = 0.01		// avrerage signal over time window delta_t
	string textboxStr=""
	// run continuos seal test
	NVAR SealTest_ISI =	root:DataAcquisitionVar:SealTest_ISI	// ISI for pulses in seconds
	NVAR SealTestNumPulses = root:DataAcquisitionVar:SealTestNumPulses
	NVAR	AcqResolution	= root:DataAcquisitionVar:AcqResolution
	SVAR NowMulticlampMode = root:NIDAQBoardVar:NowMulticlampMode
	NVAR AxCl_IRpulse_amp_VC = root:DataAcquisitionVar:IRpulse_amp_VC
	NVAR AxCl_IRpulse_dur_VC = root:DataAcquisitionVar:IRpulse_dur_VC
	NVAR AxCl_IRpulse_amp_IC = root:DataAcquisitionVar:IRpulse_amp_IC
	NVAR AxCl_IRpulse_dur_IC = root:DataAcquisitionVar:IRpulse_dur_IC
	WAVE/T DAC_SignalWave =  root:NIDAQBoardVar:DAC_SignalWave
	WAVE DAC_AmpGain_ICl_Wave =  root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	WAVE DAC_AmpGain_VCl_Wave =  root:NIDAQBoardVar:DAC_AmpGain_VCl_Wave
	WAVE/T DAC_SignalWave				=root:NIDAQBoardVar:DAC_SignalWave
	WAVE DAC_Channel_Wave			=root:NIDAQBoardVar:DAC_Channel_Wave
	WAVE/T ADC_SignalWave		=root:NIDAQBoardVar:ADC_SignalWave
	WAVE	ADC_ChannelWave		=root:NIDAQBoardVar:ADC_ChannelWave
	WAVE ADC_AmpGainWave =root:NIDAQBoardVar:ADC_AmpGainWave
	DACsignalList = ConvertTextWavetoList(DAC_SignalWave)
	ADCsignalList = ConvertTextWavetoList(ADC_SignalWave)
	

	print "************STARTING MCLAMP SEAL TEST"
	print "    DAC signal wave   " +DAC_SignalWave + "gains:"
	print DAC_AmpGain_ICl_Wave
	print DAC_AmpGain_VCl_Wave
	print "    ADC signal wave   " +ADC_SignalWave
	print DACsignallist,ADCsignallist
	if(stringmatch(NowMulticlampMode,"V-clamp"))
	print "current multiclamp mode is: V-clamp  :" ,NowMulticlampMode
		print "note vclamp mode"
		duration=AxCl_IRpulse_dur_VC
		amplitude =AxCl_IRpulse_amp_VC
		output_signal = "Command"
		DAC_out_Channel=WhichlistItem(Output_Signal, DACsignalList)
		outputGain=DAC_AmpGain_VCl_Wave[DAC_out_Channel]
		inputsignal="PrimaryOutCh1"
		
		OutWin_ylabel = "Voltage Step (*gain of " + num2str(outputGain)
		 InWin_ylabel	= " Current Response (A)"
		 Set_yaxis_ampl_Vcl		=  1.5		// nA?
	else
			print "current multiclamp mode is I-clamp:  " ,NowMulticlampMode
		duration=AxCl_IRpulse_dur_IC
		amplitude =AxCl_IRpulse_amp_IC
		output_signal = "Command"
		DAC_out_Channel=WhichlistItem(Output_Signal, DACsignalList)
		print DAC_out_Channel
		outputGain=DAC_AmpGain_ICl_Wave[DAC_out_Channel]
		inputsignal= "PrimaryOutCh1"
		OutWin_ylabel = " Current Step (*gain of " + num2str(outputGain)
		 InWin_ylabel	= "  Voltage Response (V)"
		  Set_yaxis_ampl_Icl		=  0.02		// V
	endif	
	print "input signal:  ", inputsignal
	inputchannel=WhichlistItem(inputsignal, ADCsignalList)
	print "input channel:  ", inputchannel
	inputgain = ADC_AmpGainWave[inputchannel]
	print "input  gain:  ", inputgain
	print "output signal:  ", output_signal
	print " output gain :  ", outputGain
	Make/O/N=(3*duration*AcqResolution) SealtestwaveOut, SealTestInput, SealTestDisplay
	SetScale /P x 0,(1/AcqResolution), "sec", SealtestwaveOut,SealTestInput,SealTestDisplay
	SealtestwaveOut=0
		SealTestWaveOut[ x2pnt(SealTestWaveOut,duration),x2pnt(SealTestWaveOut,2*duration)] = amplitude/outputGain
	t_step= 2*duration-0.01	// measure step at 0.01 sec before end of seal test
	SealTestDisplay=SealtestwaveOut*outputGain
	//Dowindow/K SealtestWindow
	//display SealTestWaveOut
	//Dowindow/C SealtestWindow
	AcqString = "SealTestInput," +  num2str(inputchannel) + ";"
	WFOutString =  "SealTestWaveOut," + num2str(DAC_out_Channel) + ";" 
	print AcqString ,WFOutString
	//NVAR BoardID = root:NIDAQBoardVar:BoardID
	//The Following couldn't hurt at the beginning of a data acquisition run:
	
		Step_outAmp= amplitude		// voltage if vclamp, current if Iclamp
		print "output amplitude is :", Step_outAmp

	variable i,elapsedTicks,startTicks
	if(stringmatch(WFOutString,""))		// check for empty string; no error, just no output waves
		SetDataFolder root:
		abort  "problem with output wavefunction"
	endif
	if(stringmatch(AcqString,""))		// check for empty string; no error, just no output waves
		SetDataFolder root:
		abort  "problem with acquired wave"
	endif
			Dowindow/K SealtestWindow
			display/W= (50,50, 300,350) SealTestWaveOut  as "Output step"
			Dowindow/C SealtestWindow
			
			
			Dowindow/K SealtestInWindow
			display /W= (300,50, 600,350)    as "Acquired Vm/Im response"
			
			Dowindow/C SealtestInWindow
		do
			StartTicks=ticks

			mySimpleAcqRoutine(WFOutString,AcqString)
			
			//display SealTestInput
			SealTestInput= SealTestInput/inputgain
			Step_InBaseline= mean(SealTestInput, t_base,t_base+delta_t) 
			Step_InAmp=mean(SealTestInput, t_step-delta_t/2,t_step+delta_t/2)   - mean(SealTestInput, t_base,t_base+delta_t) 
			//print "response amplitude is :", Step_InAmp
			if(stringmatch(NowMulticlampMode,"V-clamp"))
				Res= Step_outAmp/Step_InAmp		// R = V/I    Ohms = Volts/Amps
				Res= 1000*Res	// convert Ohms to MegaOhms
				print "Step_out= ",  Step_outAmp
				print "Step_InAmp= ",  Step_InAmp
				Set_yaxis_ampl=Set_yaxis_ampl_Vcl
				if(Res>500)
					Set_yaxis_ampl=0.1*Set_yaxis_ampl_Vcl
				endif
				Yaxis_offset = Step_InBaseline
			else
				Res= Step_InAmp/Step_outAmp		// R = V/I    Ohms = Volts/Amps
				Res= 1000*Res	// convert Ohms to MegaOhms
				Set_yaxis_ampl= Set_yaxis_ampl_Icl
				Yaxis_offset = Step_InBaseline  //mean(SealTestInput, t_step-delta_t/2,t_step+delta_t/2)
			endif
			
			
			Dowindow/F SealtestWindow
			Dowindow/K SealtestInWindow
			display /W= (300,50, 600,350)  SealTestInput  as "Acquired Vm/Im response"
			SetAxis left -Set_yaxis_ampl+Yaxis_offset,Set_yaxis_ampl+Yaxis_offset
			Setaxis /A left
			textboxStr = "\Z18Resistance =  "+ num2str(Res) + "   MOhms"
			textbox /A=RT  textboxStr
			Dowindow/C SealtestInWindow
			Doupdate /W=SealtestInWindow
			i+=1
			
			do									//waste time between runs according to ISI
				elapsedTicks=ticks-StartTicks
			while((elapsedTicks/60.15)< SealTest_ISI)
			//	
		while(i<SealTestNumPulses)
	
	//Dowindow/K SealtestWindow
End

