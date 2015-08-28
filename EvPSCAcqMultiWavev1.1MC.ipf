
#pragma rtGlobals=1		// Use modern global access method.
//#include "C:\Documents and Settings\Kate\My Documents\Igor Shared Procedures\WavetoList procs"
#include <Waves Average>
//#include <ANOVA>
// Renamed EvPSCAcqMultiWavev1MC.ipf
// updated to use multiclamp
////EvPSCAcquire_MultiWave_randv2_2.ipf
///  Evoked PSC response data Acquisition using single SIU but applying multiple waves in interleaved trials per set.
//  10/10/03  Programming in ability to randomize stimulus order.
//  9/11/05   Adding inital PSC amplitude measure.  9/14/05  Corrected for random presentation.
//  08/01/06  Changing to add option to display data as concatenated waves of PSC clipped & pasted together.
//  08/02/06  Added ANOVA analysis of initial PSC compared across stimulus sets; generates table:  read off the ANOVA p-value (if <0.1 check for pairwise differences)
//                 if pairwise differences, continue to record more.
// 08/02/06  Added display of avg EPSC overlay of 1st,2nd & last two EPSC traces.
//  08/02/10  Adding ability to collect temperature data every trial akin to holding current data.

Menu "Initialize Procedures"
	"Initialize EvPMW  Parameters",Init_EvPMW_AcqControlPanel()
end

Menu "Kill Windows"
	"Kill EvPMW Acq Graphs",Kill_EvPMW_windows()
end

Function EvPMW_DisplayConcatCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_DisplayConcatCheck =  root:EvPMW:EvPMW_DisplayConcatCheck
	EvPMW_DisplayConcatCheck = checked
	print "Changing Display Concat check to " num2str(EvPMW_DisplayConcatCheck)
End


Macro Init_EvPMW_AcqControlPanel()
	// Check to see whether Globals Folder exists (i.e., that the InitializeDataAcquisition procedure 
	// has been run & common global variables exist
	if( DataFolderExists("root:DataAcquisitionVar"))	
		DoWindow/K EvPMW_rawDataDisplay
		DoWindow/K EvPMW_Holding_parameters
		Dowindow/K EvPMW_OutputWavesDisplay
	
		
		if( !DataFolderExists("root:EvPMW"))
			String dfSave=GetDataFolder(1)
			NewDataFolder /O/S root:EvPMW	// Create folder for FI variables
		
			KillWaves /a/z								// clean out folder & start from scratch
			killvariables /a/z		
			killstrings /a/z
			variable /G 	EvPMW_CmdVolt					=  0	// command voltage,V (absolute)
			variable /G EvPMW_CmdVolt_on			= 0.2
			variable/G EvPMW_CmdVolt_off			= 1.4	
			
			variable /G EvPMW_AcqLength		= 	4		// total length of acquisition wave, sec
			Variable /G EvPMW_TrialISI				=   10		// seconds between steps
			variable /G EvPMW_CalcIRCheck			=	1		// Calculate real-time Input resistance ?
			variable /G EvPMW_DispHoldCurrCheck	=	1		// measure & display holding current
			variable /G EvPMW_DispCmdVoltCheck	=	1		// measure & display real voltage
			Variable /G EvPMW_RepeatCheck		=	1		// Repeat sets?
			Variable/G EvPMW_NumTrialRepeats		=	5	// number of times to repeat trials within  a set
			Variable /G EvPMW_NumSetRepeats		=	1		// number of times to repeat sets
			Variable /G EvPMW_SetNum			=	0		// Label each set 
			//to average the set traces
			variable /G EvPMW_Averagecheck	=	0
			string /G EvPMW_AvgBasename	:=	"EvPMW_" + root:DataAcquisitionVar:baseName+"s"+ num2str(EvPMW_setnum) +  "_av" // Averaging waves basename
			//StimWave   variables:
			variable /G EvPMW_W1_check = 1
			String /G EvPMW_StimWaveName_1 := "EvPMW_s"	+ num2str(EvPMW_setnum) +"_StimW1"	// create a default evoked wave
			String /G EvPMW_StimWaveInput_1	="none"
			variable /G EvPMW_W2_check = 1
			String /G EvPMW_StimWaveName_2 := "EvPMW_s"	+ num2str(EvPMW_setnum) +"_StimW2"	// create a default evoked wave
			String /G EvPMW_StimWaveInput_2	="none"
			variable /G EvPMW_W3_check = 1
			String /G EvPMW_StimWaveName_3 := "EvPMW_s"	+ num2str(EvPMW_setnum) +"_StimW3"	// create a default evoked wave
			String /G EvPMW_StimWaveInput_3	="none"
			variable /G EvPMW_W4_check = 1
			String /G EvPMW_StimWaveName_4 := "EvPMW_s"	+ num2str(EvPMW_setnum) +"_StimW4"	// create a default evoked wave
			String /G EvPMW_StimWaveInput_4	="none"
			variable /G EvPMW_W5_check = 1
			String /G EvPMW_StimWaveName_5:= "EvPMW_s"	+ num2str(EvPMW_setnum) +"_StimW5"	// create a default evoked wave
			String /G EvPMW_StimWaveInput_5	="none"
			variable /G EvPMW_W6_check = 1
			String /G EvPMW_StimWaveName_6 := "EvPMW_s"	+ num2str(EvPMW_setnum) +"_StimW6"	// create a default evoked wave
			String /G EvPMW_StimWaveInput_6	="none"
			String/G EvPMW_WindowDispList =""
			variable /G dataDisplay_x1 = 0.99
			variable/G dataDisplay_x2 = 1.05
			variable/G dataDisplay_y1_CC= -0.005		// V below mean level to set left axis
			variable/G dataDisplay_y2_CC = 0.020		// V above mean level to set left axis
			variable/G dataDisplay_y1_VC= -2.500	// nA below mean level to set left axis
			variable/G dataDisplay_y2_VC = 2	// nA above mean level to set left axis
			variable /G EvPMW_DoRandomizeCheck	=  1
			//
			variable /G  EvPMW_DisplayConcatCheck	=  0				// display the trace data as concatenated waves of EPSC's clipped
			//  online analysis of inital PSC
			variable /G EvPMW_InitPSCdelay			= 1		//sec
			variable /G EvPMW_InitPSClatency			= 0.002		//sec
			/////////////////////////////////
			String 	/G EvPMW_Basename			:=	"EvPMW_" +root:DataAcquisitionVar:baseName + "s" + num2str(EvPMW_setnum)	// Acquisition waves basename
			Execute " EvPMW_ControlPanel()"
			SetDataFolder dfSave
		
		else

			Execute " EvPMW_ControlPanel()"
		endif
		SaveExperiment
		NewPath /C/M="Choose folder for Evoked PSC MultiWave files"/O/Q/Z EvPMWPath
	else
		Print "You must first initialize global variables with procedure 'InitializedDataAcquisition()' "
	endif
end


function Acq_EvPMW_data(ctrlname) 		: ButtonControl
	string ctrlname
	Print "**************Starting Evoked Multiwave Rand v2 acquisistion routine " + time()
	//// Make sure the experiment is saved and therefore named
	if (StringMatch(IgorInfo(1),"Untitled"))
		SetDataFolder root:	
		Print "\tAborting -- experiment not saved!"
		Abort "You'd better save your experiment first!"
	endif
	Execute "Kill_EvPMW_windows()"
	string dfsave=GetDataFolder(1)
	SetDataFolder root:EvPMW	
//	String Monitor_Signal = "10Vm"	// string to be matched to find voltage channel
//	String Input_Signal="ScaledOutput"		// string to be matched to find current channel
//	String OutputCell_Signal = "Ext Command (front)"			// string to be matched to find DAC output to drive current step 
//	String OutputStim_Signal = "Extracellular SIU1"	
		String Monitor_Signal = "SecondaryOutCh1"	// string to be matched to find secondary channel
	String Input_Signal= "PrimaryOutCh1"		// string to be matched to find input channel
	String OutputCell_Signal = "Command"		// string to be matched to find DAC output to drive current step 
	String OutputStim_Signal = "Extracellular SIU1"	
	
		SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
	
	String AcqString, WFOutString
	String CommandStr
	variable err
	variable StartTicks,elapsedTicks
	Variable BeforeBuff = 0.050	//  time before test pulse , sec
	variable StartingSetNumber,EndingSetNumber
	variable i=0
	variable iCount=0
	Variable j=0
	variable k=0
	variable Num_StimWaves
	variable totaltrials=0
	variable PlotLayouts=1
	// concatenation variables
	Variable /G Concat_ClipWidth	= 0.005			// in sec
	Variable/G Concat_PreStimClip	= 0.0002		// in sec
	variable tempNumStim 
	variable temp_timeT
	variable concatIndex =0
	string CurrConcatWaveName
	string CurrAvgConcatWaveName 
	string  temptimingwaveName
	variable temp_P
	//Determine # of StimWaves to be sent - determines everything else.
	Make/N=6/O StimCheckArray,DiffStimCheckArray
	string tempStr
	i=0
	do
		tempStr="W" + num2str(i+1) + "_CheckBox"
		ControlInfo /W=EvPMW_ControlPanel $tempStr
		StimCheckArray[i]=V_Value
		Num_StimWaves+=V_Value			/// adds 1 if selected
		i+=1
	while(i<6)
	if(num_stimWaves==0)		// change to: "if no waves are selected"
		SetDataFolder root:
		Abort "You must select a wave to apply to SIU1"
	endif
	///// make sure they are consecutive            ?? necessary?
	DiffStimCheckArray=StimCheckArray-StimCheckArray[p+1]
	WaveStats/Q  DiffStimCheckArray
	if(V_min<0)
		SetDataFolder root:
		Abort "Select Waves in consecutive order starting with Subtrial 1"
	endif
	print "Number of checked stim wave out = " + num2str(Num_stimWaves)


	////////////////////////Setup for Display
	// clear previous windows:
	SVAR EvPMW_WindowDispList =  root:EvPMW:EvPMW_WindowDispList
	i=0
	do
		tempStr = stringfromlist(i,EvPMW_WindowDispList,";")
		if(!(strlen(tempStr)==0))
			Dowindow/K $tempStr
		endif
		i+=1
	while(i<strlen(EvPMW_WindowDispList))
	//	
		
	Variable LeftPos=15					// variables for positioning graph windows for this module
	Variable TopPos=40
	Variable Graph_Height=100
	variable Graph_Width = 200
	variable Graph_groutH = 0
	variable Graph_groutV = 0
	variable y1				// variable to determine mean y-level of data to change axis appropriately
	variable OffsetGraph_y1,OffsetGraph_y2,Offsetgraph_Yrange
	String temp1,temp2,temp3,temp4,temp5
	Make/N=4/O EvPMW_HoldParamDisplay_pos,EvPMW_OutputWavesDisplay_pos
	//  graph top, right
	EvPMW_HoldParamDisplay_pos={LeftPos+2*graph_Width+20,TopPos+3*Graph_Height,LeftPos+4*graph_Width,TopPos+5*Graph_Height}
	EvPMW_OutputWavesDisplay_pos={LeftPos+20,TopPos+3*Graph_Height,LeftPos+graph_Width+Graph_groutH,TopPos+4*Graph_Height}

	EvPMW_WindowDispList=""
	TopPos+=20			// shift other windows down 10
	if(num_stimWaves>1)
		Graph_Height=420/num_stimWaves			// make graphs sized according to how many
	else
		Graph_Height=210
	endif
	Graph_Width = 190
	Make/N=(5,num_StimWaves)/T/O EvPMW_WindowNames
	i=0
	do	
		temp1	= 	"EvPMW_rawDataDisplay_Stim_" + num2str(i+1)  // left most
		temp2	=	"EvPMW_AvgWaveDisplay_Stim_" + num2str(i+1)	// second from left
		temp3	=	"EvPMW_allDataDisplay_Stim_"+ num2str(i+1)		// third from left
		temp4	=	"EvPMW_all_offset_Stim_"+ num2str(i+1)			// right most
		temp5	=	"EvPMW_AvgOverlayEPSC_Stim_" + num2str(i+1)
		Make/N=4/O  temp1_pos,temp2_pos,temp3_pos,temp4_pos,temp5_pos			// plot for each StimWave subtrials by row
		temp1_pos={LeftPos, TopPos+i*Graph_Height+i*Graph_GroutV, LeftPos +Graph_Width, TopPos+(i+1)*Graph_Height+i*Graph_groutV}
		temp2_pos={LeftPos+Graph_Width+Graph_GroutH, TopPos+i*Graph_Height+i*Graph_GroutV, LeftPos+2*Graph_Width+Graph_GroutH, TopPos+(i+1)*Graph_Height+i*Graph_groutV}
		temp3_pos={LeftPos+2*Graph_Width+2*Graph_GroutH, TopPos+i*Graph_Height+i*Graph_GroutV, LeftPos+3*Graph_Width+2*Graph_GroutH, TopPos+(i+1)*Graph_Height+i*Graph_groutV}
		temp4_pos={LeftPos+3*Graph_Width+3*Graph_GroutH, TopPos+i*Graph_Height+i*Graph_GroutV, LeftPos+4*Graph_Width+3*Graph_GroutH, TopPos+(i+1)*Graph_Height+i*Graph_groutV}
		temp5_pos={LeftPos+Graph_Width+Graph_GroutH, TopPos+i*Graph_Height+i*Graph_GroutV, LeftPos+2*Graph_Width+Graph_GroutH, TopPos+(i+1)*Graph_Height+i*Graph_groutV}
		Display/w=(temp1_pos[0],temp1_pos[1],temp1_pos[2],temp1_pos[3]) as "Raw trace"
		Dowindow/C $temp1
		EvPMW_WindowNames[0][i]=temp1
	  		Display/w=(temp2_pos[0],temp2_pos[1],temp2_pos[2],temp2_pos[3]) as "Average trace"
			Dowindow/C $temp2
			EvPMW_WindowNames[1][i]=temp2
				Display/w=(temp3_pos[0],temp3_pos[1],temp3_pos[2],temp3_pos[3]) as "Overlay traces"
				Dowindow/C $temp3
				EvPMW_WindowNames[2][i]=temp3
					Display/w=(temp4_pos[0],temp4_pos[1],temp4_pos[2],temp4_pos[3]) as "Offset traces"
					Dowindow/C $temp4
					EvPMW_WindowNames[3][i]=temp4
							Display/w=(temp5_pos[0],temp5_pos[1],temp5_pos[2],temp5_pos[3]) as "Ovly Avg EPSC traces"
							Dowindow/C $temp5
							EvPMW_WindowNames[4][i]=temp5

		EvPMW_WindowDispList+= ";"+temp1+";"+temp2+ ";"+temp3+";"+temp4 +";"+temp5
		print EvPMW_WindowDispList
		i+=1
	while(i<num_StimWaves)

	/////////////////// Update Telegraphs:  verify I-clamp, update scaled output gain, write to notebook the readouts
	//Execute "UpdateTelegraphs()"
//	print "getting TG globals"
//	NVAR Current_TG_Gain	=	root:NIDAQBoardVar:Current_TG_Gain		
//	SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
//	SVAR Current_ScaledOutType=root:NIDAQBoardVar:Current_ScaledOutType
//	NVAR Current_TG_Filter	=root:NIDAQBoardVar:Current_TG_Filter
//	NVAR current_TG_Capac	=root:NIDAQBoardVar:current_TG_Capac			

//
//
//	if(  (! stringmatch(NowMulticlampMode,"V-Clamp")) &&  (! stringmatch(NowMulticlampMode,"I-Clamp Normal")) && (! stringmatch(NowMulticlampMode,"I-Clamp Fast")) )		// in future, use in both V-Cl and I-Cl
//		SetDataFolder root:
//		Abort "Amplifier must be set in'V-Clamp' or 'I-Clamp'"
//	endif
// determine correct channel #s for Scaled out (voltage), I output
	Print "Getting Nidaq ADC/DAC globals"

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
	WAVE DAC_SignalWave				=root:NIDAQBoardVar:DAC_SignalWave
	WAVE DAC_Channel_Wave			=root:NIDAQBoardVar:DAC_Channel_Wave
	WAVE DAC_AmpGain_VCl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_VCl_Wave
	WAVE DAC_AmpGain_ICl_Wave		=root:NIDAQBoardVar:DAC_AmpGain_ICl_Wave
	Variable DAC_CellOut_Channel
	Variable DAC_CellOut_AmpGain
	Variable DAC_StimOut_Channel = 1		// set to DAC1 for now
	variable DAC_StimOut_AmpGain =1		// set to 1; always?  default?
	
	Variable DAC_StimOut_Channel_2= 0		// set to DAC1 for now
	variable DAC_StimOut_AmpGain_2 =1		// set to 1; always?  default?
	
	//NVAR BoardID =	root:NIDAQBoardVar:Boardid
	
// find  channels;determine current amplifier gains for output & input waves;determine individual board gains for input waves
	print "determining channels & gains"
	string ADCsignalList = ConvertTextWavetoList(ADC_SignalWave)
	string DACsignalList = ConvertTextWavetoList(DAC_SignalWave)
	Monitor_Channel=whichListItem(Monitor_Signal, ADCsignalList)				// channel is equivalent to position in List
	Input_Channel=WhichlistItem(Input_Signal, ADCsignalList)
	Monitor_AmpGain= ADC_AmpGainWave[Monitor_Channel]
	Input_AmpGain=ADC_AmpGainWave[Input_Channel]
	//Monitor_IndBoardGain= ADC_IndBoardGainWave[Monitor_Channel]
	//Input_IndBoardGain=ADC_IndBoardGainWave[Input_Channel]
	////////Some Channel checking
	//  SIU out channel:
	DAC_StimOut_Channel=WhichlistItem(OutputStim_Signal, DACsignalList)
	if(DAC_StimOut_Channel==-1)
		SetDataFolder root:
		abort "if you want to use SIU#1, you must choose ' Extracellular SIU1'  for one of the DAC outs"
	endif
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
	//
		


// write EvokPSC Multiwave panel parameters to notebook
// all the panel variables:
	print "Getting Evoked PSC Multiwave panel parameters"
	NVAR EvPMW_CmdVolt				=	root:EvPMW:EvPMW_CmdVolt
	NVAR EvPMW_CmdVolt_on				=	root:EvPMW:EvPMW_CmdVolt_on
	NVAR EvPMW_CmdVolt_off				=	root:EvPMW:EvPMW_CmdVolt_off
	NVAR EvPMW_SetNum				=	root:EvPMW:EvPMW_SetNum
	SVAR EvPMW_Basename				=	root:EvPMW:EvPMW_Basename
	SVAR Basename						=	root:DataAcquisitionVar:baseName
	String Local_Basename				=	"EvPMW_" +baseName + "s" + num2str(EvPMW_SetNum)	// recalculate a local basename
	String TextBox_label					= 	Local_basename
	NVAR EvPMW_AcqLength				=	root:EvPMW:EvPMW_AcqLength
	NVAR EvPMW_TrialISI				=	root:EvPMW:EvPMW_TrialISI					// in sec
	NVAR EvPMW_NumTrialRepeats		=	root:EvPMW:EvPMW_NumTrialRepeats
	
	NVAR EvPMW_RepeatCheck			=	root:EvPMW:EvPMW_RepeatCheck
	NVAR EvPMW_CalcIRCheck			=	root:EvPMW:EvPMW_CalcIRCheck
	NVAR EvPMW_DispHoldCurrCheck	=	root:EvPMW:EvPMW_DispHoldCurrCheck
	NVAR EvPMW_DispCmdVoltCheck		=	root:EvPMW:EvPMW_DispCmdVoltCheck
	
	variable EvPMW_DispTemperatureCheck		// future replace with NVAR and panel check box
	//NVAR EvPMW_StimBuffer = root:EvPMW:EvPMW_StimBuffer	// time after IR test to place stimulus (sec)
	variable x1,x2,x3,x4
	NVAR EvPMW_AverageCheck	=	root:EvPMW:EvPMW_AverageCheck
	print "        average check = " + num2str(EvPMW_AverageCheck)
	NVAR EvPMW_DoRandomizeCheck	=	root:EvPMW:EvPMW_DoRandomizeCheck
	NVAR DisplayConcatCheck			=	root:EvPMW:EvPMW_DisplayConcatCheck
	////////
	NVAR DataDisplay_x1	=	root:EvPMW:DataDisplay_x1
	NVAR DataDisplay_x2	=	root:EvPMW:DataDisplay_x2
	NVAR DataDisplay_y1_CC	=	root:EvPMW:DataDisplay_y1_CC	
	NVAR DataDisplay_y2_CC	=	root:EvPMW:DataDisplay_y2_CC
	NVAR DataDisplay_y1_VC	=	root:EvPMW:DataDisplay_y1_VC
	NVAR DataDisplay_y2_VC	=	root:EvPMW:DataDisplay_y2_VC
	/////////
	NVAR EvPMW_InitPSCdelay	=	root:EvPMW:EvPMW_InitPSCdelay
	NVAR EvPMW_InitPSClat		=	root:EvPMW:EvPMW_InitPSClatency
	////////
	SVAR EvPMW_AvgBasename 	=	root:EvPMW:EvPMW_AvgBasename	
	Variable totalWavePoints = AcqResolution *EvPMW_AcqLength
	variable deltx= 1/AcqResolution
	StartingSetNumber=EvPMW_SetNum
		///Set up for randomization
		Make/O/N=(num_stimWaves) Stim_order,Rand_order
		string StimOrderWaveName = Local_Basename +"StimOrder"
		Make/O/N=(EvPMW_NumTrialRepeats*num_stimWaves) $StimOrderWaveName								// select a random order
		WAVE temp_stimorderWave = $StimOrderWaveName
		Stim_order=x
		Dowindow/K EvPMW_StimOrder
		Display /W=(EvPMW_OutputWavesDisplay_pos[0],EvPMW_OutputWavesDisplay_pos[1]+Graph_Height,EvPMW_OutputWavesDisplay_pos[2],EvPMW_OutputWavesDisplay_pos[3]+2*Graph_Height)   $StimOrderWaveName
		Modifygraph rgb=(65500,65500,65500), mode=4
		label left "stimulus ID"
		label bottom "Trial order"
		Dowindow/C EvPMW_StimOrder
		Dowindow/B EvPMW_StimOrder

// Write to notebook channels & gains
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
	Notebook Parameter_Log ruler =normal, text="\r\tSIU #1 is in use:"
	Notebook Parameter_Log ruler =normal, text="\r\tInter-trial interval (sec):\t" +num2str(EvPMW_TrialISI)
	if(EvPMW_DoRandomizeCheck)
	Notebook Parameter_Log ruler =normal, text="\r\tStimulus trials are set to pseudorandomize, save in wave: \t" + StimOrderWaveName
	endif
	

	// OUTPUT WAVES CREATION:  
	/////Get  StimWave string variables;  Check exists? check wave lengths match; display:
	DoWindow /K EvPMW_OutputWavesDisplay
	Display /W=(EvPMW_OutputWavesDisplay_pos[0],EvPMW_OutputWavesDisplay_pos[1],EvPMW_OutputWavesDisplay_pos[2],EvPMW_OutputWavesDisplay_pos[3]) as "Evoked PSC Output Waves"
	DoWindow /C EvPMW_OutputWavesDisplay
	Make/O/T/N=(Num_stimWaves) StimWaveNameArray,StimWaveInputArray
	make/O/N=(num_stimwaves+1) LengthWave 
	LengthWave[0]=totalWavePoints
	i=0
	do
		tempStr = "root:EvPMW:EvPMW_StimWaveInput_" + num2str(i+1)
		SVAR 	TempStr_input	=	$tempStr
		StimWaveInputArray[i] = TempStr_input	
		WAVE/Z inputWave= root:$StimWaveInputArray[i]
		if(!Waveexists(inputWave))
			SetDataFolder root:
			Abort "No Wave " + StimWaveInputArray[i] + " exists (check folders)"
		endif		
		tempStr = "root:EvPMW:EvPMW_StimwaveName_" + num2str(i+1)
		SVAR 	TempStr_name	=	$tempStr
		if(!SVAR_Exists(tempSTr_name))
			SetDataFolder root:
			abort "problem with SVAR during out wave creation"
		endif
		StimWaveNameArray[i]= TempStr_name
		Duplicate/O inputWave ,  $StimWaveNameArray[i]		
		AppendtoGraph /R $StimWaveNameArray[i]
		LengthWave[i+1]=numpnts($StimWaveNameArray[i])
		i+=1
	while(i<num_StimWaves)
	
	////Check wavelengths:
	WAveStats /Q LengthWave
	LengthWave[0] = V_max		// set total length to maximum of the three

	print "Total Num of wave Points " + num2str(LengthWave[0] )
	i=0			// gotta run through them again
	do
		if(numpnts($StimWaveNameArray[i])<LengthWave[0])
			insertpoints numpnts($StimWaveNameArray[i]),LengthWave[0]-numpnts($StimWaveNameArray[i]), $StimWaveNameArray[i]
		endif
		i+=1
	while(i<num_stimwaves)
	totalwavepoints=lengthwave[0]
	EvPMW_AcqLength=totalWavePoints /AcqResolution
	if(DataDisplay_x2>EvPMW_AcqLength)
		DataDisplay_x2=EvPMW_AcqLength			// shorten time axis to be no longer than waves
	endif
	DoUpdate

	Notebook Parameter_Log ruler =normal, text="\r\t  Number of stimulus waves to use:    \t" + num2str(num_stimwaves)
	Notebook Parameter_Log ruler =normal, text="\r\t  Stim waves input to use:             \tStim wave output saved as: \t"
	i=0
	do
		Notebook Parameter_Log ruler =normal, text="\r\t     " + StimWaveInputArray[i] + "\t"+ StimWaveNameArray[i]
		i+=1
	while(i<Num_stimwaves)
	Notebook Parameter_Log ruler =normal, text="\r\tTotal Wave Length (sec): \t" + num2str(EvPMW_AcqLength )	
	Notebook Parameter_Log ruler =normal, text="\r\tNumber of trials per set: \t" +num2str(EvPMW_NumTrialRepeats) + "\r"
	

	///////////////// ACQUISITION WAVES names wave creation:
	variable numpntsinconcatsb = Concat_clipWidth*AcqResolution
	Make/O/N=(totalwavepoints) tempWave0
	SetScale /P x 0,(1/AcqResolution), "sec", tempWave0
	//  create all acquisition waves up front - 2D names text waves
	Make/T/N=(EvPMW_NumTrialRepeats,num_StimWaves)/O  InputAcqNames_Wave, MonitorAcqNames_Wave // contains the names of the acquired waves
	Make/T/N=(EvPMW_NumTrialRepeats,num_StimWaves)/O  InputAcqConcatNames_Wave		//080106
	j=0
	do
		i=0
		do
				If(stringmatch(NowMulticlampMode, "V-Clamp"))
				MonitorAcqNames_Wave[j][i]=Local_Basename + "_V" + num2str(j) + "_" + num2str(i)		
				InputAcqNames_Wave[j][i]=Local_Basename + "_A" + num2str(j) + "_" + num2str(i)
				InputAcqConcatNames_Wave[j][i]=  Local_Basename + "_A"+ num2str(j) + "_" + num2str(i)+"_cat"		//080106 not noting A or V, doesn't matter

			else
				MonitorAcqNames_Wave[j][i]=Local_Basename + "_A" + num2str(j)	+ "_" + num2str(i)		
				InputAcqNames_Wave[j][i]=Local_Basename + "_V" + num2str(j)+ "_" + num2str(i)	
				InputAcqConcatNames_Wave[j][i]=  Local_Basename + "_V"+ num2str(j) + "_" + num2str(i)+"_cat"	
			endif
			duplicate /O tempwave0, $MonitorAcqNames_Wave[j][i]
			duplicate /O tempwave0, $InputAcqNames_Wave[j][i]
			Make/O/N=(numpntsinconcatsb)  $InputAcqConcatNames_Wave[j][i]			//080106
			SetScale /P x 0,(1/AcqResolution), "sec",  $InputAcqConcatNames_Wave[j][i]
			i+=1
		while(i<num_stimwaves)
		j+=1
	while(j<EvPMW_numTrialRepeats)		// creates entire set of names at once for each set
	
	//  Setting up for Concatenation of waves							//080106
	// load timing waves
	Make/O/T/N=(num_stimwaves) TimingWaveNames
	Print "CONCAT loading names of stim timing waves   "
	i=0
	do
		Timingwavenames[i]= StimWaveInputArray[i] +"_t"
		print "            ", Timingwavenames[i]
		i+=1
	while(i<num_stimwaves)
	//  make subwave 	
	//print " CONCAT  num of pnts in sb  = ", num2str(numpntsinconcatsb)
	Make/N=(numpntsinconcatsb)/O subwave			// create temporary clip wave
	subwave=0
	SetScale /P x 0,(1/AcqResolution), "sec", subwave
	


	/// AVERAGING DATA WAVES:check if to average raw waves themselves, if so create average wave:  Create Window to plot it
	ControlInfo /W=EvPMW_ControlPanel AvgCheck
	//print  V_flag
	EvPMW_AverageCheck=V_value
	//print "EvPMW_averagecheck is" , num2str(EvPMW_AverageCheck)
	if(EvPMW_AverageCheck)
		print "setting up for averaging of waves across sets"
		string AvWave_VoltName,AvWave_CurrName
		
		///make average wave for each stimwave
		Make/O/N=(num_stimwaves)/T AvgWavenames, SumWaveNames
		Make/O/N=(num_stimwaves)/T AvgConcatWaveNames							//080106
		tempwave0=0
		i=0
		do
			SumWaveNames[i]="TempSum_" + num2str(i)		// a temporary running sum for each stimwave response
			AvgWavenames[i]=EvPMW_AvgBasename + "_"	+num2str(i)		// average wave to be calculated and saved; running average
			AvgConcatWaveNames[i]  =  EvPMW_AvgBasename + "_"	+num2str(i)+ "_concat"   	///080106
			Duplicate /O tempWave0, $SumWaveNames[i], $AvgWavenames[i]
			Make/O/N=(numpntsinconcatsb) $AvgConcatWaveNames[i]								//080106
			SetScale /P x 0,(1/AcqResolution), "sec",  $AvgConcatWaveNames[i]
			Dowindow/F $EvPMW_WindowNames[1][i]
			if(DisplayConcatCheck)										//080106
				appendtograph /L=left $AvgConcatWaveNames[i]				// display either concatenized waves or normal
			else
				appendtograph /L=left $AvgWavenames[i]
				SetAxis bottom dataDisplay_x1,dataDisplay_x2
			endif
			ModifyGraph rgb=(0,0,0)		// start off black
			//Label bottom "Time (sec)"
			if (stringmatch(NowMulticlampMode,"V-Clamp"))
				SetAxis left dataDisplay_y1_VC,dataDisplay_y2_VC
				//Label left "Current (nA)"
			else
				setaxis left dataDisplay_y1_CC,dataDisplay_y2_CC
				//Label left "Voltage (V)"
			endif
			//TextBox /F=0/A=MT "Average across trials"
			i+=1
		while(i<num_StimWaves)
		DoUpdate
		/////////////  Set up display of avg waves to overlay Initial PSC
		Dowindow/K EvPMW_DisplayInitialPSCTraces
		
		Display/w=(temp5_pos[0]+3*Graph_Width,temp5_pos[1],temp5_pos[2]+3.5*Graph_Width,temp5_pos[3]) as "Overlay Avg Initial PSC"
		Dowindow/C EvPMW_DisplayInitialPSCTraces
		EvPMW_WindowDispList+=";EvPMW_DisplayInitialPSCTraces" 
		i=0
		do
			appendtograph /L=left $AvgConcatWaveNames[i]
			i+=1
		while(i<num_StimWaves)
		SetAxis bottom 0, Concat_ClipWidth
		if (stringmatch(NowMulticlampMode,"V-Clamp"))
				SetAxis left dataDisplay_y1_VC,dataDisplay_y2_VC
				Label left "Current (nA)"
		else
				setaxis left dataDisplay_y1_CC,dataDisplay_y2_CC
				Label left "Voltage (V)"
		endif
		Execute "ColorStyleMacro()"
		 Modifygraph lSize=2
		legend /E=1 /F=0/A=MT/B=1
		/////////////  Set up display of avg waves to overlay Subsequent  EPSCs within a stimulus
		/// could modify to overlay all stimuli
		variable Concatoffsetvar
		variable ColorRow 
		colortab2wave   BlueRedGreen			// create wave 3-col, 100 row matrix name M_colors
		WAVE myColors  = M_colors
		i=0
		do
			Dowindow/F $EvPMW_WindowNames[4][i]
			j=0
			ColorRow =0
			do
				appendtograph /L=left $AvgConcatWaveNames[i]					// re-plot each avg wave 4 times
				if(j>0)
					print "my color row selected for ", num2str(j) , "th trace, ", num2str(i), "th window:  ", num2str(colorRow)
					Modifygraph rgb[j]=((myColors[colorRow][0]),  (myColors[colorRow][1]), (myColors[colorRow][2]) )			// color each trace differently
					colorRow+=49						// blue, then red, then green
				endif	
				//offset
				if(j<2)
					Concatoffsetvar  =   j*concat_Clipwidth
					Modifygraph offset[j]={ -Concatoffsetvar, 0}					// first two: 1st PSC, no offset; 2nd PSC, offset by one clipwidth
				else
					 temptimingwaveName  =TimingWaveNames[i]				// for 2nd to last & last PSCs, need to know # points
					WAVE Timingwave =  root:$temptimingwaveName			// get the right timing wave
					tempNumStim = numpnts(TimingWave)						// calc # pnts = #stim
					Concatoffsetvar  =  (tempNumStim-4+j)*concat_Clipwidth
					Modifygraph offset[j]={ -Concatoffsetvar, 0}			//for j=2, need to offset by n-2 widths; for j=3, need to offset by n-1  widths
				endif
				j+=1
				
			while(j<4)
			Modifygraph rgb[0]=(0,0,0), lsize[0] = 2			// Make first PSC thick black line										
			setaxis bottom 0, Concat_Clipwidth
			if (stringmatch(NowMulticlampMode,"V-Clamp"))
				SetAxis left dataDisplay_y1_VC,dataDisplay_y2_VC
				Label left "Current (nA)"
			else
				setaxis left dataDisplay_y1_CC,dataDisplay_y2_CC
				Label left "Voltage (V)"
			endif
			i+=1
		while(i<num_StimWaves)
		
		Killwaves myColors
	endif

	////////////////// REAL TIME ANALYSES:
	// IR TEST PULSE Output
	String TempIRStr
	TempIRStr="Ev_OutputtoCellWave_s" + num2str(EvPMW_Setnum)
	Notebook Parameter_Log ruler =normal, text="\r\tCreating wave to send to generate input resistance:\t" + TempIRStr
	if(EvPMW_CalcIRCheck)
		if(  stringmatch(NowMulticlampMode,"V-Clamp")  )
			NVAR EvPMW_IRamp		=	root:DataAcquisitionVar:IRpulse_amp_VC	// input resistance test pulse, V (e.g. -5mV)
			NVAR EvPMW_IRdur		=	root:DataAcquisitionVar:IRpulse_dur_VC		// test pulse duration, sec (e.g., 10ms)
			
			Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse amplitude (mV):\t"+ num2str(EvPMW_IRamp*1000)
			Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse duration (ms):\t"+ num2str(EvPMW_IRdur*1000)
		else
			NVAR EvPMW_IRamp		=	root:DataAcquisitionVar:IRpulse_amp_IC	// input resistance test pulse, A (e.g. -0.05nA)
			NVAR EvPMW_IRdur		=	root:DataAcquisitionVar:IRpulse_dur_IC
			Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse amplitude (pA):\t"+ num2str(EvPMW_IRamp*1000)
			Notebook Parameter_Log ruler =normal, text="\r\t    Test pulse duration (ms):\t"+ num2str(EvPMW_IRdur*1000)
		endif
		//print "Creating output waves to Cell"
		if(EvPMW_TrialISI <= (EvPMW_AcqLength+0.200))	// check that ISI is long enough (200ms extra room)	
			SetDataFolder root:
			Abort "ISI must be longer than "  + num2str(EvPMW_AcqLength+0.200)
		endif
		Make /O/N=( totalWavePoints) tempwave0
		SetScale /P x 0, (1/AcqResolution), "sec",   tempwave0
		//	tempwave0=EvPMW_CmdVolt			// is command voltage absolute or relative?  if relative, need to measure volt cmd & change to difference
		tempWave0=0
		DoWindow /F EvPMW_OutputWavesDisplay
		//print "DAC_cellOut_ampgain "  + num2str(DAC_Cellout_ampgain)
		if(EvPMW_CmdVolt!=0)
			Notebook Parameter_Log ruler =normal, text="\r\t   command step amplitude (mV):\t"+ num2str(EvPMW_CmdVolt*1000)
			Notebook Parameter_Log ruler =normal, text="\r\t   time on/off (s):\t"+ num2str(EvPMW_CmdVolt_on) + "  to " + num2str(EvPMW_CmdVolt_off)
		endif
		
		tempwave0[x2pnt(tempwave0,EvPMW_CmdVolt_on),x2pnt(tempwave0,EvPMW_CmdVolt_off)]=EvPMW_CmdVolt
		tempwave0[x2pnt(tempwave0,BeforeBuff),x2pnt(tempwave0,(BeforeBuff+EvPMW_IRdur))]=EvPMW_IRamp
		//tempwave0[x2pnt(tempwave0,BeforeBuff),x2pnt(tempwave0,(BeforeBuff+EvPMW_InpResPulse_Dur))]=EvPMW_InpResPulse_AmpVC+EvPMW_CmdVolt
		tempWave0/=DAC_CellOut_AmpGain			//  divide by gain  in V/V
		Duplicate /O tempWave0, $TempIRStr
		AppendToGraph $TempIRStr
	endif
	//////  Realtime measurements:			
	// Measure Input resistance for each trial; calculate & plot.
	String IRStr,HCStr,VLStr,TMPCStr
	controlInfo /W=EvPMW_ControlPanel CalcIRCheck
	EvPMW_CalcIRCheck=V_value
	controlInfo /W=EvPMW_ControlPanel DispHoldCurrCheck
	EvPMW_DispHoldCurrCheck=V_value
	controlInfo /W=EvPMW_ControlPanel DispCmdVoltCheck
	EvPMW_DispCmdVoltCheck=V_value
	//controlInfo /W=EvPMW_ControlPanel DispTemperatureCheck  / / modify in future version s
	EvPMW_DispTemperatureCheck=1
	
// if any of above, then create one window for all three measures:
	if ( (EvPMW_CalcIRCheck==1) || (EvPMW_DispHoldCurrCheck==1) || (EvPMW_DispCmdVoltCheck==1) )
		DoWindow /K EvPMW_Holding_parameters
		Display /W=(EvPMW_HoldParamDisplay_pos[0],EvPMW_HoldParamDisplay_pos[1],EvPMW_HoldParamDisplay_pos[2],EvPMW_HoldParamDisplay_pos[3])   as "Holding for " + Local_Basename
		DoWindow /C EvPMW_Holding_parameters
	endif
	if(EvPMW_CalcIRCheck)
		//print "Setting up for input resistance calculations", num2str(EvPMW_CalcIRCheck)
		IRStr=Local_Basename  + "_IR"			// one for entire set - continuous time - easier to tell course of expt
		Make/O/N=(EvPMW_NumTrialRepeats*num_stimWaves) $IRStr					
		DoWindow/F EvPMW_Holding_parameters
		AppendtoGraph /L $IRStr 
		Label left "\\E\\Z06Inp Resist (MOhms)"
		ModifyGraph axisEnab(left)={0,0.25}, axRGB(left)=(64768,0,0),tlblRGB(left)=(64768,0,0), alblRGB(left)=(64768,0,0)
		Modifygraph marker($IRStr)=19,rgb($IRStr)=(65000,0,0)
		//SetAxis /A/E=1 left 
		SetAxis  left 0,500
		Modifygraph  lblPos(left)=35
	endif
	///HOLDING CURRENT:
	if(EvPMW_DispHoldCurrCheck)
		//print "Setting up for holding current measures", num2str(EvPMW_DispHoldCurrCheck)
		HCStr=Local_Basename  + "_HC"					// one for entire set - continuous time
		Make/O/N=(EvPMW_NumTrialRepeats*num_stimWaves) $HCStr				
		Appendtograph /R $HCStr
		Label right "\\E\\Z06Holding current (nA)"
		Modifygraph  marker($HCStr)=16,rgb($HCStr)=(0,12800,52224)	
		ModifyGraph axisEnab(right)={0.35,0.60},axRGB(right)=(0,12800,52224),tlblRGB(right)=(0,12800,52224),alblRGB(right)=(0,12800,52224)
		SetAxis /A/E=2 right		// sym around zero
		Modifygraph  lblPos(right)=35, zero(right)=2
	endif
	/// VOLTAGE :	
	if(EvPMW_DispCmdVoltCheck)
		//print "Setting up for voltage measure", num2str(EvPMW_DispCmdVoltCheck)				
		VLStr=Local_Basename + "_VL"   										// one for entire set - continuous time
		Make/O/N=(EvPMW_NumTrialRepeats*num_stimWaves) $VLStr			
		//AppendtoGraph /L=L2 $VLStr
		//Label L2 "\\E\\Z06Voltage (V)"
		//Modifygraph  marker($VLStr)=17,rgb($VLStr)=(0,39168,0)		
		//ModifyGraph axisEnab(L2)={0.70,0.95},axRGB(L2)=(0,39168,0),tlblRGB(L2)=(0,39168,0),alblRGB(L2)=(0,39168,0)
		//SetAxis /A/E=1 L2	// autoscale from zero
		//ModifyGraph freePos(L2)=0,  lblPos(L2)=35,zero(right)=2	
	endif
	if ( (EvPMW_CalcIRCheck==1) || (EvPMW_DispHoldCurrCheck==1) || (EvPMW_DispCmdVoltCheck==1) )
		ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,0}
		ModifyGraph axisEnab(bottom)={0.05,0.95}
		Label bottom "Trials"
		ModifyGraph msize=3,mode=4,live=1
		Doupdate
	endif
	////REAL-TIME Temperature MEASUREMENT
	if(EvPMW_DispTemperatureCheck)
		//print "Setting up for voltage measure", num2str(EvPMW_DispCmdVoltCheck)				
		TMPCStr=Local_Basename + "_DegC"   										// one for entire set - continuous time
		Make/O/N=(EvPMW_NumTrialRepeats*num_stimWaves) $TMPCStr			
		DoWindow/K EvPMW_TemperaturevsTrials
		temp5_pos={EvPMW_HoldParamDisplay_pos[0],EvPMW_HoldParamDisplay_pos[1]+Graph_Height+20, EvPMW_HoldParamDisplay_pos[2], EvPMW_HoldParamDisplay_pos[3]+0.5*Graph_Height+Graph_groutV}

		display /w=(temp5_pos[0],temp5_pos[1],temp5_pos[2],temp5_pos[3])  /L $TMPCStr as "Temperature vs Trials"
		DoWindow/C EvPMW_TemperaturevsTrials
		Label left "\\E\\Z06Temperature (degC)"
		ModifyGraph axisEnab(left)={0,1}, axRGB(left)=(26368,0,52224),tlblRGB(left)=(26368,0,52224), alblRGB(left)=(26368,0,52224)
		Modifygraph marker($TMPCStr)=19,rgb($TMPCStr)=(26368,0,52224)
		//SetAxis /A/E=1 left 
		SetAxis  left 20,40		
		Modifygraph  lblPos(left)=35
	endif
	
	////REAL-TIME PSC RESPONSE MEASUREMENT
	string PSC1_namestr,All_PSC1str
	Make/T/O/N=(num_stimWaves) PSC1_WaveNames
	if(1)
		All_PSC1str = local_basename + "_allP1"
		Make/O/N=(EvPMW_NumTrialRepeats*num_stimWaves) $All_PSC1str
		DoWindow/F EvPMW_Holding_parameters
		AppendtoGraph /L=L2 $All_PSC1str
		Label L2 "\\E\\Z06Init PSC (nA)"
		Modifygraph  mode($All_PSC1str)=4,marker($All_PSC1str)=17,rgb($All_PSC1str)=(0,39168,0)		
		ModifyGraph axisEnab(L2)={0.70,0.95},axRGB(L2)=(0,39168,0),tlblRGB(L2)=(0,39168,0),alblRGB(L2)=(0,39168,0)
		SetAxis /A/E=1 L2	// autoscale from zero
		ModifyGraph freePos(L2)=0,  lblPos(L2)=35,zero(right)=2	
		i=0
		do
			PSC1_namestr=local_basename + "_P1"+ "_"+num2str(i)
			Make/O/N=(EvPMW_NumTrialRepeats) $PSC1_namestr
			PSC1_WaveNames[i]= PSC1_namestr
		i+=1
		while(i<num_stimWaves)
	endif
	
	
	
	
	/////////////////////////////	
	print "Beginning set iteration number:", num2str(EvPMW_setnum)
	Wave temp_IR = $IRStr
	Wave temp_HC=$HCStr
	Wave temp_VL=	$VLStr	
	Wave temp_TMPC=	$TMPCStr
	WAve temp_P1 = $All_PSC1str	
	variable temp_VLdelta,temp_HCdelta,temp_P1_baseline	
	variable step_VL,step_HC	
	temp_IR=0		
	temp_HC=0
	temp_VL=0
	temp_P1 =0
	temp_TMPC=0
	tempwave0=0
	j=0  // loop variable for number of trials
	i=0		// loop variable for subtrials (each stimwave)

		//print Local_Basename
		if( (Waveexists(temp_IR)==0)  ||  (Waveexists(temp_HC)==0) ||   (Waveexists(temp_VL)==0) )
			print "temp_HC or temp_IR or temp_VL does not exist"		
		endif		
		//  create window for real-time raw data display:		
		i=0
		do			
			DoWindow/F $EvPMW_WindowNames[0][i]
			if(!DisplayConcatCheck)
				SetAxis bottom dataDisplay_x1,dataDisplay_x2
				tempStr=InputAcqNames_Wave[0][i]
				AppendtoGraph 	$InputAcqNames_Wave[0][i]
				else
				tempStr=InputAcqConcatNames_Wave[0][i]
				AppendtoGraph 	$InputAcqConcatNames_Wave[0][i]
			endif
			
			if (stringmatch(NowMulticlampMode,"V-Clamp"))
				//Label left "Current (nA)"
				SetAxis left dataDisplay_y1_VC,dataDisplay_y2_VC
			else
				//Label left "Voltage (V)"
				SetAxis left dataDisplay_y1_CC,dataDisplay_y2_CC
			endif
			//Label bottom "Time (sec)"
			
			if(i==num_stimWaves-1)
			TextBox /F=0/A=MT  StimWaveInputArray[i]
			endif
			Modifygraph  rgb=(0,0,0),lblPos(left)=40,live=1		// positions the label of left axes properly
			DoUpdate	
			i+=1
		while(i<num_stimWaves)

		
		// Make variables to acquire a temperature measure, once at the beginning of each set.  
		variable TempGain = 0.1	// gain on the T2 output is 100mV/degC
		variable CurrentTempDegC
		string TempAcqString = "TemperatureGrabWave,3"
		Make /O/N=100 TemperatureGrabWave
		SetScale /P x 0, (1/AcqResolution), "sec",  TemperatureGrabWave
		mysimpleAcqRoutine("",TempAcqString)
		TemperatureGrabWave/=TempGain
		CurrentTempDegC=mean(TemperatureGrabWave,-inf,inf)
		Notebook Parameter_Log ruler =normal, text="\r\t  Recording chamber temperature (T2) : \t" + num2str(CurrentTempDegC) + " degrees C"
		///
		DoUpdate	

		////////////////////////////////////////////////////
		j=0
		do											// begin   Trials loop////////////////////////////////////////////////////
			print "   Beginning trial # ", num2str(j)		
			if(EvPMW_DoRandomizeCheck)	
				rand_order=enoise(1)					// beginning of trial loop select new random order			
				sort rand_order, rand_order,stim_order
			endif
			iCount=0
			do										// begin  Sub-Trials loop////////////////////////////////////////////////////
				StartTicks=ticks
				totaltrials+=1					/// running tally of total number of trials over set.
				if(EvPMW_DoRandomizeCheck)				// routine to select randomized stim order
					i= stim_order[iCount]		// let i = the ith stimulus in that order
				else
					i=iCount							// if no randomization, just let i = the count (like normal)
				endif
				temp_stimorderWave[totaltrials-1]=i
				print "       subtrial # " + num2str(i) + " with Stimulus wave " + StimWaveInputArray[i]
				// send waves to nidaq
				
				
				AcqString=InputAcqNames_Wave[j][i]+"," +num2str(Input_Channel) + ";" 
				AcqString+=MonitorAcqNames_Wave[j][i]+"," +num2str(Monitor_Channel) + ";" 
				
				if(DAC_CellOut_Channel>DAC_StimOut_Channel)
					WFOutString =  StimWaveNameArray[i] + "," + num2str(DAC_StimOut_Channel)
					WFOutString+= ";"  + TempIRStr + "," + num2str(DAC_CellOut_Channel)	
				else
					WFOutString= TempIRStr + "," + num2str(DAC_CellOut_Channel)	
					WFOutString +=   ";"  +StimWaveNameArray[i] + "," + num2str(DAC_StimOut_Channel)
					
				endif	
				//print " Data Acquisition output string: " + WFOutString
				print "              Acquiring ",  InputAcqNames_Wave[j][i]
				mySimpleAcqRoutine(WFOutString,AcqString)
				Wave MonitorAcqWave=  $(MonitorAcqNames_Wave[j][i])
				Wave InputAcqWave=$(InputAcqNames_Wave[j][i])			
				if( (Waveexists(MonitorAcqWave)==0)  ||  (Waveexists(InputAcqWave)==0) )
					SetDataFolder root:
					abort "MonitorAcqWave or InputAcqWave does not exist"
				endif

				MonitorAcqWave/=Monitor_AmpGain
				InputAcqWave/=Input_AmpGain
				//CommandStr = "Save/O/C/P=EvPMWPath " +MonitorAcqNames_Wave[j][i] +","+InputAcqNames_Wave[j][i]
				CommandStr = "Save/O/C/P=EvPMWPath " +InputAcqNames_Wave[j][i]		// save just the input waves; monitor waves takes too much space
				Execute CommandStr							// Quick! Before the computer crashes!!!
				
	
				// display  raw voltage & current data		-->> raw data window
				// if using concat wave display		080206
				
				if(DisplayConcatCheck)
					
					 temptimingwaveName  =TimingWaveNames[i]	
					WAVE Timingwave =  root:$temptimingwaveName			// get the rigth timing wave
					//print TimingWaveNames[i]	
					CurrConcatWaveName = InputAcqConcatNames_Wave[j][i]
					WAVE Concatw = $CurrConcatWaveName
					//print "CONCAT"  ,CurrConcatWaveName
					tempNumStim = numpnts(TimingWave)
					//print   "CONCAT num of stim"  , num2str(tempNumStim)
					concatIndex =0
					do
						temp_timeT = Timingwave[concatIndex]  - Concat_PreStimClip
						//print "CONCAT  index ", num2str(concatindex), "  clip at time t ",  num2str(temp_timeT)
						temp_P= x2pnt(InputAcqWave,temp_timeT)
						subwave = InputAcqWave[p+ (temp_P)]
						if(concatIndex<1)
							Concatw=subwave
						else
							concatenateWaves(CurrConcatWaveName,"subwave")
						endif
						concatIndex +=1
					while(concatIndex<tempNumStim)
					//display $CurrConcatWaveName
					WAVE DisplayAcqWave = $CurrConcatWaveName
				else
					WAVE DisplayAcqWave =  InputAcqWave
				endif
				
				DoWindow/F $EvPMW_WindowNames[0][i]		
				if(j>0)	
					AppendtoGraph 	 DisplayAcqWave				// append first to maintain axes
					
					if(DisplayConcatCheck)
						Removefromgraph /Z $InputAcqConcatNames_Wave[j-1][i]
					else
						Removefromgraph /Z $InputAcqNames_Wave[j-1][i]
					endif
				else
					ModifyGraph rgb=(65500,0,0)			// first trial, simply make current trace red
				endif
				y1=mean(DisplayAcqWave,-inf,inf)
				//print y1
				if (stringmatch(NowMulticlampMode,"V-Clamp"))
					SetAxis left y1+dataDisplay_y1_VC,y1+dataDisplay_y2_VC
				else
					SetAxis left y1+dataDisplay_y1_CC,y1+dataDisplay_y2_CC
				endif
				//modifygraph rgb=(0,0,0)		//let current waves be red by default
				/////////////////////////////////////////////////////////////Plot cumulative graphs only if there is more than one trial
				if(EvPMW_numTrialRepeats>1)
					// accumulate to one graph (overlay):
					Dowindow/F $EvPMW_WindowNames[2][i]
					if(j==0)
						AppendtoGraph DisplayAcqWave
						//TextBox /F=0/A=MT  StimWaveInputArray[i]
						if (stringmatch(NowMulticlampMode,"V-Clamp"))
							SetAxis left y1+dataDisplay_y1_VC,y1+dataDisplay_y2_VC
							//Label left "Current (na)"
						else
							SetAxis left y1+dataDisplay_y1_CC,y1+dataDisplay_y2_CC
							//Label left "Voltage (V)"
						endif
						if(!DisplayConcatCheck)
							Setaxis bottom dataDisplay_x1,dataDisplay_x2
						endif
						//Label bottom "Time (sec)"
					else
						AppendtoGraph DisplayAcqWave
					endif
					
					DoUpdate
					//  accumulate & offset to one graph
					Dowindow/F $EvPMW_WindowNames[3][i]
					if(j==0)
						AppendtoGraph DisplayAcqWave
						//TextBox /F=0/A=MT "All traces, top to bottom"
						if (stringmatch(NowMulticlampMode,"V-Clamp"))
							OffsetGraph_y1	=	y1+dataDisplay_y1_VC
							OffsetGraph_y2 	= 	y1+dataDisplay_y2_VC
							//Label left "Current (nA)"
						else
							OffsetGraph_y1	=	y1+dataDisplay_y1_CC
							OffsetGraph_y2 	= 	y1+dataDisplay_y2_CC
							//Label left "Voltage (V)"
						endif
						Offsetgraph_Yrange = OffsetGraph_y2-OffsetGraph_y1
						Offsetgraph_y2=OffsetGraph_y1+Offsetgraph_yrange*EvPMW_numTrialRepeats
						SetAxis left OffsetGraph_y1,Offsetgraph_y2					// set axis to total anticipate range
						if(!DisplayConcatCheck)
							Setaxis bottom dataDisplay_x1,dataDisplay_x2
						endif
						//Label bottom "Time (sec)"
						Modifygraph offset[0]={0 , (EvPMW_numTrialRepeats-1)*Offsetgraph_Yrange}
					else
						AppendtoGraph DisplayAcqWave
					endif
					Modifygraph offset[j]={0 , (EvPMW_numTrialRepeats-j-1)*Offsetgraph_Yrange}
				endif
			
				//REAL TIME ANALYSIS: AVERAGING voltage and current traces across set repeats:
				if(EvPMW_AverageCheck)	
					WAVE Sum_Curr=$SumWaveNames[i]				
					WAVE Avg_Curr=$AvgWavenames[i]
					if ( (Waveexists(Sum_Curr)==0)   ||  (Waveexists(Avg_Curr)==0))
						print "  Sum_Curr or Avg_Currdoes not exist"
					endif			
				
					Sum_Curr+=InputAcqWave		// j+1 should be number of trials;  provides running average
					Avg_Curr=Sum_Curr/(j+1)
					DoWindow/F $EvPMW_WindowNames[1][i]
					y1=mean(Avg_Curr,-inf,inf)			// adjust axis accordingly
					//print y1
					if (stringmatch(NowMulticlampMode,"V-Clamp"))
						SetAxis left y1+dataDisplay_y1_VC,y1+dataDisplay_y2_VC
					else
						SetAxis left y1+dataDisplay_y1_CC,y1+dataDisplay_y2_CC
					endif
					ModifyGraph rgb=(65500,0,0),live=1		// make current average wave red 
					// Make Concatenated wave of running average.
					if(DisplayConcatCheck)
						CurrAvgConcatWaveName = AvgConcatWaveNames[i]
						WAVE Concatw  =$CurrAvgConcatWaveName
						concatIndex =0
						Make/O/N=(numpntsinconcatsb)  TempConcatwave			// use new temp wave each time
						SetScale /P x 0, (1/AcqResolution), "sec", TempConcatwave
						do
							temp_timeT = Timingwave[concatIndex]  - Concat_PreStimClip
							subwave = Avg_Curr[p+ x2pnt(Avg_Curr,temp_timeT)]
							if(concatIndex<1)
								TempConcatwave= subwave
							else
								concatenateWaves("TempConcatwave","subwave")
							endif
							concatIndex +=1
						while(concatIndex<tempNumStim)
						Duplicate/O  TempConcatwave, $CurrAvgConcatWaveName	// overwrite old avg concat wave with what's in  new temp wave
						Dowindow/F $EvPMW_WindowNames[4][i]					// bring overlay graph to the front (currently obscures concat avg graph)
						if (stringmatch(NowMulticlampMode,"V-Clamp"))				// update left axis scaling
							SetAxis left y1+dataDisplay_y1_VC,y1+dataDisplay_y2_VC
						else
							SetAxis left y1+dataDisplay_y1_CC,y1+dataDisplay_y2_CC
						endif
					endif
				endif
			
				if (stringmatch(NowMulticlampMode,"V-Clamp"))
					WAVE VoltAcqWave =MonitorAcqWave
					WAVE  CurrAcqWave =InputAcqWave
				else
					WAVE VoltAcqWave =InputAcqWave
					WAVE  CurrAcqWave =MonitorAcqWave
				endif
				//REAL TIME ANALYSIS: Measure baseline holding current:  
				if(EvPMW_DispTemperatureCheck)		// need to measure for IR calculation anyway
					temp_TMPC[totaltrials-1]=mean(CurrAcqWave, 0.010,BeforeBuff-0.010)			// 10 ms from start to 10 ms before IR pulse
				endif
				
				//REAL TIME ANALYSIS: Measure baseline holding current:  
				if(EvPMW_DispHoldcurrCheck || EvPMW_CalcIRCheck)		// need to measure for IR calculation anyway
					temp_HC[totaltrials-1]=mean(CurrAcqWave, 0.010,BeforeBuff-0.010)			// 10 ms from start to 10 ms before IR pulse
				endif
				//REAL TIME ANALYSIS: Measure baseline voltage:
				if(EvPMW_DispCmdVoltCheck || EvPMW_CalcIRCheck)		// need to measure for IR calculation anyway
					temp_VL[totaltrials-1]=mean(VoltAcqWave, 0.010,BeforeBuff-0.010)		// 10 ms from start to 10 ms before IR pulse
				endif
				//REAL TIME ANALYSIS: Calculate & plot input resistance:			mV/nA = MOhm
				if(EvPMW_CalcIRCheck)

				temp_VLdelta=( mean(VoltAcqWave, BeforeBuff+EvPMW_IRdur-0.005,BeforeBuff+EvPMW_IRdur-0.001 )-temp_VL[totaltrials]) *1000  // convert from V to mV
				if (stringmatch(NowMulticlampMode,"V-Clamp"))
					temp_VLdelta = abs(EvPMW_IRamp*1000)			// assume volt step, convert to mV
					temp_HCdelta =  abs( mean(CurrAcqWave, BeforeBuff+EvPMW_IRdur-0.005,BeforeBuff+EvPMW_IRdur-0.001)- temp_HC[totaltrials] )
				else
					temp_HCdelta = EvPMW_IRamp
				endif
					temp_IR[totaltrials-1]=temp_VLdelta/temp_HCdelta
					print "            Volt step, (V)= " , num2str(temp_VLdelta)," , Current step, (nA)=", num2str(temp_HCdelta)
				print "                          Input resistance,(MOhm) =" , num2str(temp_IR[totaltrials-1])
				//	( mean(VoltAcqWave, BeforeBuff+EvPMW_IRdur-0.005,BeforeBuff+EvPMW_IRdur-0.0005 )-temp_VL[totaltrials]) *1000  // convert from V to mV
				//	temp_IR[totaltrials-1] /=  ( mean(CurrAcqWave, BeforeBuff+EvPMW_IRdur-0.005,BeforeBuff+EvPMW_IRdur-0.0005)- temp_HC[totaltrials] )	// current is already in nA
				
				/////////////   Initial PSC analysis
				if (stringmatch(NowMulticlampMode,"V-Clamp"))
					temp_P1_baseline =mean(CurrAcqWave, EvPMW_InitPSCdelay-0.005,EvPMW_InitPSCdelay-0.001)
					temp_P1[totaltrials-1]	=mean(CurrAcqWave, EvPMW_InitPSCdelay+EvPMW_InitPSClat-0.0002,EvPMW_InitPSCdelay+EvPMW_InitPSClat+0.0002)  -  temp_P1_baseline
				else
					temp_P1_baseline =mean(VoltAcqWave, EvPMW_InitPSCdelay-0.005,EvPMW_InitPSCdelay-0.001)
					temp_P1[totaltrials-1]	=mean(VoltAcqWave, EvPMW_InitPSCdelay+EvPMW_InitPSClat-0.0002,EvPMW_InitPSCdelay+EvPMW_InitPSClat+0.0002)  -  temp_P1_baseline
				endif
				
				endif
				//Dowindow/F EvPMW_Holding_parameters
				Modifygraph/W=EvPMW_Holding_parameters rgb($IRstr)=(65000,0,0),  rgb($All_PSC1str)=(0,65000,0), rgb($HCStr)=(0,12800,52224)
				Doupdate
				//Dowindow/B EvPMW_Holding_parameters
				//REAL TIME ANALYSIS: Measure baseline holding current:  
				if(EvPMW_DispTemperatureCheck)		// need to measure for IR calculation anyway
					mysimpleAcqRoutine("",TempAcqString)
					TemperatureGrabWave/=TempGain
					temp_TMPC[totaltrials-1]=mean(TemperatureGrabWave,-inf,inf)
					print num2str(temp_TMPC[totaltrials-1])	, " deg C"
					dowindow /F EvPMW_TemperaturevsTrials
					Modifygraph/W=EvPMW_TemperaturevsTrials rgb($TMPCstr)=(26368,0,52224), mode($TMPCstr)=4
					Doupdate
				endif
				do									//waste time between runs according to ISI
					elapsedTicks=ticks-StartTicks
				while((elapsedTicks/60.15)<EvPMW_TrialISI)	
				//print "time between " + num2str(elapsedTicks/60.15)
				ModifyGraph/W=$EvPMW_WindowNames[0][i]/Z rgb=(0,0,0)		/// change past traces to black
				ModifyGraph/W=$EvPMW_WindowNames[1][i]/Z rgb=(0,0,0)		
				ModifyGraph/W=$EvPMW_WindowNames[2][i]/Z rgb=(0,0,0)		
				ModifyGraph/W=$EvPMW_WindowNames[3][i]/Z rgb=(0,0,0)		
				if(!DisplayConcatCheck)											// only if not concatenated plotting
					if(j==EvPMW_numTrialRepeats-1)										// if last trial, add grayed out stimulus waveform
						k=0
						do
							Appendtograph/w=$EvPMW_WindowNames[k][i] /R $StimwaveNameArray[i]
							ModifyGraph/w=$EvPMW_WindowNames[k][i] rgb($StimwaveNameArray[i])=(52224,52224,52224), lstyle($StimwaveNameArray[i])=1
							SetAxis/w=$EvPMW_WindowNames[k][i] /A/E=1 right
							k+=1
						while(k<4)
					endif
				endif
				iCount+=1
				while(iCount<num_stimWaves)				
				j+=1
			while(j<EvPMW_numTrialRepeats)
			
			//////////////////// post-hoc analysis of PSC1:
			Print " Doing posthoc analysis of PSC1"
			Display /W=(EvPMW_HoldParamDisplay_pos[0],EvPMW_HoldParamDisplay_pos[1],EvPMW_HoldParamDisplay_pos[2],EvPMW_HoldParamDisplay_pos[3]) as "Initial PSC by stimulus set"
			Dowindow/C EvPMW_InitPSC_win1
			Make/O/N=(num_stimWaves)  Avg_PSC1bystim, SD_PSC1bystim, SE_PSC1bystim
			edit as "Initial PSC analysis"
			Dowindow/C EvPMW_InitPSC_tab1
			variable StimOrderIndex
			variable start
			i=0
			do
				//print "            i = " + num2str(i)

				Wave temp_PSC1byStim = $PSC1_WaveNames[i]
				appendtograph temp_PSC1byStim
				j=0
				start=0
				do
					FindValue/V=(i)  /S=(start) temp_stimorderWave		// find the index of stimorder matching the value (equiv to stimwave number)					
					temp_PSC1byStim[j] = temp_P1[V_value]
					start = V_value+1									// start next find later 
					//print "           j = " + num2str(i) +", " + PSC1_WaveNames[i] + "   index of temp_P1 = " + num2str(i+ j*num_stimwaves)
					j+=1
				while(j<EvPMW_numTrialRepeats)
				appendtotable temp_PSC1byStim
				CommandStr = "Save/O/C/P= EvPMWPath "+ PSC1_WaveNames[i]	// Save the acquired wave in the home path right away!
				Execute CommandStr
				WaveStats /Q temp_PSC1byStim
				Avg_PSC1bystim[i]= V_avg
				SD_PSC1bystim[i]= V_sdev
				SE_PSC1bystim[i]= V_sdev/sqrt(EvPMW_numTrialRepeats)
				i+=1
			while (i<num_stimWaves)
			Execute "ColorStyleMacro()"
			legend
			label bottom "Trial sequence"
			label Left "initial PSC amplitude in train"
			Dowindow/B EvPMW_InitPSC_win1
			//  
			// Stats ANOVA analysis of initial PSC amplitudes; round robin ttest analysis of PSC1_WaveNames[i]
			Dowindow/F EvPMW_InitPSC_tab1
			//Do1wayANOVAOnWindow("EvPMW_InitPSC_tab1", 1, 0, 0, 0, 0)			//generates table report
			//
			Display /W=(EvPMW_HoldParamDisplay_pos[0],EvPMW_HoldParamDisplay_pos[1],EvPMW_HoldParamDisplay_pos[2],EvPMW_HoldParamDisplay_pos[3])  Avg_PSC1bystim as "Average Initial PSC by stimulus"
			Dowindow/C EvPMW_InitPSC_win2
			ErrorBars  Avg_PSC1bystim, Y wave=(SD_PSC1bystim,SE_PSC1bystim)
			label bottom "Stimulus set #"
			label Left "Averge initial PSC amplitude in train +SD, -SE"
			Dowindow/B EvPMW_InitPSC_win2
			
			PlotLayouts=0
			if(PlotLayouts)  // use checkbox 
			NewLayout  /w=(240,60,440,460)/P=portrait
			Dowindow/C InitialPSC_Layout
			Appendlayoutobject /T=1/F=0/R=( 95,100,520,330   ) graph EvPMW_Holding_parameters
			Appendlayoutobject /T=1/F=0/R=( 80,360,500,560   ) graph  EvPMW_InitPSC_win1
			Appendlayoutobject /T=1/F=0/R=( 80,580,500,700   ) graph EvPMW_InitPSC_win2
			endif
			Notebook  Parameter_Log ruler =normal, text="\r\rCompleted Set#" + num2str(EvPMW_SetNum)
			Notebook  Parameter_Log ruler =normal, text="\r\tAcquired input traces:\t" + InputAcqNames_Wave[0][0]+ "-" + num2str(EvPMW_numtrialRepeats-1)+ "-" + num2str(num_stimwaves)
			Notebook  Parameter_Log ruler =normal, text="\r\tAcquired monitor traces:\t" +MonitorAcqNames_Wave[0][0] +"-" + num2str(EvPMW_numtrialRepeats-1) + "-" + num2str(num_stimwaves)
		
			// Save per set analysis waves:
			if(EvPMW_CalcIRCheck)
				CommandStr = "Save/O/C/P= EvPMWPath "+ IRStr 	// Save the acquired wave in the home path right away!
				Execute CommandStr
				Notebook  Parameter_Log ruler =normal, text="\r\tInput Resistance measures for this set:\t" + IRStr
				WaveStats/Q $IRStr
				Notebook Parameter_Log ruler =normal, text="\r\t  Average Input Resistance (MOhm): " + num2str(V_avg) + " +/-" + num2str(V_sdev) + "  s.d."
			endif
			if(EvPMW_DispHoldCurrCheck)
				CommandStr = "Save/O/C/P= EvPMWPath "+ HCStr 	// Save the acquired wave in the home path right away!
				Execute CommandStr
				Notebook  Parameter_Log ruler =normal, text="\r\tHolding current measures for this set:\t" +  HCStr
				WaveStats /Q $HCStr
				Notebook Parameter_Log ruler =normal, text="\r\t   Average Holding current (nA): " + num2str(V_avg*10e+9) + " +/-" + num2str(V_sdev*10e+9) + "  s.d."
			endif
			if(EvPMW_DispCmdVoltCheck)
				CommandStr = "Save/O/C/P= EvPMWPath "+ VLStr	// Save the acquired wave in the home path right away!
				Execute CommandStr
				Notebook  Parameter_Log ruler =normal, text="\r\tBaseline voltage measures for this set:\t" + VLStr
				WaveStats/Q   $VLStr 
				Notebook Parameter_Log ruler =normal, text="\r\t   Average Baseline voltage (mV): " + num2str(V_avg*1000) + " +/-" + num2str(V_sdev*1000) + "  s.d."
			endif
			// Save trace averages:
			if(EvPMW_AverageCheck)
				Notebook  Parameter_Log ruler =normal, text="\r\rCalculated traces averages for set#" +num2str(EvPMW_setnum) 
				i=0
				do
					CommandStr = "Save/O/C/P= EvPMWPath "+AvgWaveNames[i] 
					Execute commandStr
					Notebook  Parameter_Log ruler =normal, text="\r\tAverage response traces saved:\t" +AvgWaveNames[i]  
					i+=1
				while(i<num_stimWaves)

			endif
			
			if(1)
				CommandStr = "Save/O/C/P= EvPMWPath "+ All_PSC1str 	// Save the acquired wave in the home path right away!
				Execute CommandStr
				Notebook  Parameter_Log ruler =normal, text="\r\tInitial PSC measures for this set:\t" +  All_PSC1str
				WaveStats /Q $All_PSC1str
				Notebook Parameter_Log ruler =normal, text="\r\t   Average PSC/PSP amplitude: " + num2str(V_avg*10e+9) + " +/-" + num2str(V_sdev*10e+9) + "  s.d."
			endif
			/////	
		
			// Plot set trials to Layouts:
			variable plotHeight 
			if(EvPMW_numTrialrepeats<4)
				plotHeight = 100*EvPMW_numTrialrepeats
			else
				plotHeight = 360
			endif
			PlotLayouts=0
			if(PlotLayouts)  // use checkbox 
				Make/t/N=6/O LayoutNames={"EvPMW_Layout1","EvPMW_Layout2","EvPMW_Layout3","EvPMW_Layout4","EvPMW_Layout5","EvPMW_Layout6"}
				NewLayout  /w=(240,40,440,440)/P=portrait
				Dowindow/C AverageTracesLayout
				i=0
				do
					NewLayout  /w=(40*i,40,360,440)/P=portrait 
					Dowindow/C $LayoutNames[i]
					TextBox /F=0/X=5/Y=1 Local_BaseName +  "    " + StimWaveInputArray[i]
			
					//Appendlayoutobject /T=1/F=0/R=( 80,80,500,220   ) graph  EvPMW_WindowNames[0][i]		// raw trace
					Appendlayoutobject /T=1/F=0/R=( 80,110,500,250   ) graph   $EvPMW_WindowNames[1][i]	// average
					TextBox /F=0/X=15/Y=3	"Average trace:" +AvgWavenames[i]+ ",  n trials: " + num2str(EvPMW_numTrialRepeats) 
					if(EvPMW_numTrialRepeats>1)
						Appendlayoutobject /T=1/F=0/R=(80,260,500,360 ) graph  $EvPMW_WindowNames[2][i]		// overlay
						TextBox /F=0/X=60/Y=30	"Overlay traces"
					endif
					//Appendlayoutobject /T=1/F=0/R=(80,400,500,480   ) graph EvPMW_OutputWavesDisplay
					Appendlayoutobject /T=1/F=0/R=( 80,360,500,360+plotHeight    ) graph  $EvPMW_WindowNames[3][i]
					TextBox /F=0/X=65/Y=48	"All traces"
					//Dowindow/C ( Local_Basename + "_Layout"  +num2str(i))
					//	DoWindow/B EvPMW_layout1
					//
					//	if(EvPMW_numTrialRepeats>1)
					//			NewLayout  /w=(200,40,520,440)/P=portrait as Local_Basename  + "_Layout2"
					//			TextBox /F=0/X=10/Y=1 Local_BaseName
					//			Appendlayoutobject /T=1/F=0/R=( 80,100,500,600   ) graph  EvPMW_allTracesDisplay_Offset
					//			Dowindow/C EvPMW_layout2
					//			DoWindow/B EvPMW_layout2
					//		endif
					//	Appendlayoutobject /T=1/F=0/R=( 60,490,520,700   ) graph  EvPMW_Holding_parameters
					Appendlayoutobject/W=AverageTracesLayout/T=1/F=0/R=( 80,80+i*120,500,200+i*120) graph   $EvPMW_WindowNames[1][i]	//  put average wave graph on averagetraces layout
					i+=1
				while(i<num_stimwaves)
			endif
		
		Dowindow/B EvPMW_InitPSC_tab1
		Dowindow/B EvPMW_DisplayInitialPSCTraces
		
			Notebook  Parameter_Log ruler =normal, text="\r"
			EvPMW_SetNum+=1			// update set#
			Local_Basename			=	"EvPMW_" +baseName + "s" + num2str(EvPMW_SetNum)	// recalculate basename

/////////////////////////////////////////////////

		print "Cleaning up"
		EvPMW_Basename= Local_Basename			// update global  basename
		KillWaves/Z tempWave0				// kill output waves & all other temporary & non-essential waves
		i=0

		KillWaves/Z EvPMW_OutputWavesDisplay_pos
		KillWaves/Z currentAcqNames_Wave,VoltLevWave_Names,OuttocellNames_Wave
		killwaves /Z TemperatureGrabWave
	
		SetDataFolder root:			// return to root 
		Notebook Parameter_Log text="\rCompleted run:\tTime: "+Time()+"\r\r"
	
		Notebook  Parameter_Log ruler =normal, text="\r\r"
		SetDataFolder root:
end					///////////End data acquisition 	

/////////single/sub routines
Menu "Macros"
"Initialize EvokPSAcq Multiwave Parameters", Init_EvPMW_AcqControlPanel()
"Kill EvokPSC_Multiwave Acq Graphs",Kill_EvPMW_windows()
end


Window EvPMW_ControlPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(314,212,914,761)
	ModifyPanel cbRGB=(65535,49151,55704)
	ShowTools
	SetDrawLayer UserBack
	SetDrawEnv fillpat= 15,fillfgc= (51456,44032,58880)
	DrawRRect 11,4,489,41
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 53,31,"Evoked PSC Acquisition Control Panel  - Multi-Wave"
	DrawLine 76,62,370,62
	DrawLine 73,137,367,137
	DrawText 394,317,"X-axis (absolute:"
	DrawText 302,368,"Y-axis range:"
	DrawText 391,370,"I-clamp"
	DrawText 494,370,"V-clamp"
	SetDrawEnv fname= "Times New Roman",fsize= 10
	DrawText 495,356,"(sec)"
	SetVariable EvPMW_BasenameSetVar,pos={13,41},size={265,16},title="Acquisition Waves Basename"
	SetVariable EvPMW_BasenameSetVar,value= root:EvPMW:EvPMW_Basename
	SetVariable SetRepeatSetVar,pos={19,113},size={206,16},title="Number of times to repeat set :   "
	SetVariable SetRepeatSetVar,limits={1,100,1},value= root:EvPMW:EvPMW_NumSetRepeats
	SetVariable SetNumSetVar,pos={294,42},size={118,16},title="Current Set #"
	SetVariable SetNumSetVar,value= root:EvPMW:EvPMW_SetNum
	Button EvPMW_AcquireButton,pos={233,505},size={264,42},proc=Acq_EvPMW_data,title="Acquire"
	PopupMenu SelectOutCellPopup,pos={295,188},size={202,21},disable=2,title="Cmd Output Signal (cell)"
	PopupMenu SelectOutCellPopup,mode=2,popvalue="Command",value= #"root:NIDAQBoardVar:OutputNamesString"
	PopupMenu SelectOutStimPopup,pos={309,256},size={241,21},disable=2,title="Stimulus Output Signal   "
	PopupMenu SelectOutStimPopup,mode=2,popvalue="Extracellular SIU1",value= #"root:NIDAQBoardVar:OutputNamesString"
	PopupMenu SelectInputSignalPopup,pos={342,211},size={168,21},disable=2,title="Input Signal"
	PopupMenu SelectInputSignalPopup,mode=2,popvalue="PrimaryOutCh1",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	PopupMenu SelectVoltInputSignalPopup,pos={374,235},size={179,21},disable=2,title="Monitor Signal"
	PopupMenu SelectVoltInputSignalPopup,mode=3,popvalue="PrimaryOutCh2",value= #"root:NIDAQBoardVar:ConnectionPopupString"
	SetVariable TrialISISetVar,pos={208,70},size={135,16},title="Trial ISI (sec)      "
	SetVariable TrialISISetVar,limits={0.1,100,0.1},value= root:EvPMW:EvPMW_TrialISI
	CheckBox CalcIRCheck,pos={22,143},size={151,14},disable=2,proc=EvPMW_CalcIRCheckProc,title="Calculate Input Resistance?"
	CheckBox CalcIRCheck,value= 1
	CheckBox DispHoldCurrCheck,pos={183,143},size={134,14},disable=2,proc=EvPMW_DispHoldCurrCheckProc,title="Display Holding Current?"
	CheckBox DispHoldCurrCheck,value= 1
	CheckBox DispCmdVoltCheck,pos={326,142},size={138,14},disable=2,proc=EvPMW_DispCmdVoltCheckProc,title="Display baseline voltage?"
	CheckBox DispCmdVoltCheck,value= 1
	SetVariable AcqLengthSetVar,pos={18,71},size={180,16},title="Length per trial (sec)"
	SetVariable AcqLengthSetVar,limits={0.001,100,0.5},value= root:EvPMW:EvPMW_AcqLength
	SetVariable TrialRepeatSetVar,pos={18,91},size={206,16},title="Number of trial repeats per set :"
	SetVariable TrialRepeatSetVar,limits={1,1000,1},value= root:EvPMW:EvPMW_NumtrialRepeats
	SetVariable CmdVoltSetVar,pos={371,75},size={175,16},title="Command voltage (V)"
	SetVariable CmdVoltSetVar,limits={-0.2,0.2,0.01},value= root:EvPMW:EvPMW_CmdVolt
	SetVariable StimWaveNameSetVar1,pos={30,222},size={253,16},title="Save with Wave Name:"
	SetVariable StimWaveNameSetVar1,value= root:EvPMW:EvPMW_StimWaveName_1
	CheckBox AvgCheck,pos={22,161},size={107,14},proc=EvPMW_AvgCheckProc,title="Average Repeats?"
	CheckBox AvgCheck,value= 1
	SetVariable AvNameSetVar,pos={135,158},size={303,16},title="Average Waves Basename:"
	SetVariable AvNameSetVar,value= root:EvPMW:EvPMW_AvgBasename
	GroupBox SIU1group,pos={8,179},size={284,317},title="SIU#1"
	CheckBox W1_Checkbox,pos={15,199},size={61,14},proc=EvPMW_W1_CheckProc,title="1st wave"
	CheckBox W1_Checkbox,value= 1
	PopupMenu EvokStimWave1Popup,pos={81,196},size={152,21},proc=EvPMW_ChEvokStimWaveProc1,title="Apply Stim Wave:"
	PopupMenu EvokStimWave1Popup,mode=5,popvalue="Stim1",value= #"Wavelist(\"*\",\";\",\"\")"
	SetVariable setvar0,pos={472,314},size={74,16},title="min"
	SetVariable setvar0,value= root:EvPMW:dataDisplay_x1
	SetVariable setvar001,pos={472,332},size={76,16},title="max"
	SetVariable setvar001,value= root:EvPMW:dataDisplay_x2
	SetVariable setvar002,pos={338,400},size={101,16},title="V below"
	SetVariable setvar002,limits={-inf,inf,5},value= root:EvPMW:dataDisplay_y1_CC
	SetVariable setvar00101,pos={338,376},size={99,16},title="V above"
	SetVariable setvar00101,limits={-inf,inf,5},value= root:EvPMW:dataDisplay_y2_CC
	GroupBox AxisControlBox,pos={299,283},size={262,146},title="Data Graph Axis Control"
	SetVariable setvar00201,pos={449,399},size={99,16},title="nA below"
	SetVariable setvar00201,limits={-inf,inf,50},value= root:EvPMW:dataDisplay_y1_VC
	SetVariable setvar0010101,pos={449,378},size={97,16},title="nA above"
	SetVariable setvar0010101,limits={-inf,inf,50},value= root:EvPMW:dataDisplay_y2_VC
	Button EvPMW_SetAxesButton,pos={309,316},size={65,28},proc=EvPMW_setallaxes,title="Set all now"
	CheckBox W2_checkBox,pos={18,244},size={65,14},proc=EvPMW_W2_CheckProc,title="2nd wave"
	CheckBox W2_checkBox,value= 0
	PopupMenu EvokStimWave2Popup,pos={85,241},size={187,21},proc=EvPMW_ChEvokStimWaveProc2,title="Apply Stim Wave:"
	PopupMenu EvokStimWave2Popup,mode=3,popvalue="StimWave_2",value= #"Wavelist(\"*\",\";\",\"\")"
	SetVariable StimWaveNameSetVar2,pos={31,268},size={244,16},title="Save with Wave Name:"
	SetVariable StimWaveNameSetVar2,value= root:EvPMW:EvPMW_StimWaveName_2
	CheckBox W3_checkbox,pos={19,289},size={62,14},proc=EvPMW_W3_CheckProc,title="3rd wave"
	CheckBox W3_checkbox,value= 0
	PopupMenu EvokStimWave3Popup,pos={87,289},size={187,21},proc=EvPMW_ChEvokStimWaveProc3,title="Apply Stim Wave:"
	PopupMenu EvokStimWave3Popup,mode=2,popvalue="StimWave_3",value= #"Wavelist(\"*\",\";\",\"\")"
	SetVariable StimWaveNameSetVar3,pos={38,313},size={240,16},title="Save with Wave Name:"
	SetVariable StimWaveNameSetVar3,value= root:EvPMW:EvPMW_StimWaveName_3
	CheckBox W4_checkbox,pos={19,344},size={62,14},proc=EvPMW_W4_CheckProc,title="4th wave"
	CheckBox W4_checkbox,value= 0
	PopupMenu EvokStimWave4Popup,pos={89,339},size={187,21},proc=EvPMW_ChEvokStimWaveProc4,title="Apply Stim Wave:"
	PopupMenu EvokStimWave4Popup,mode=4,popvalue="StimWave_4",value= #"Wavelist(\"*\",\";\",\"\")"
	SetVariable StimWaveNameSetVar4,pos={42,364},size={244,16},title="Save with Wave Name:"
	SetVariable StimWaveNameSetVar4,value= root:EvPMW:EvPMW_StimWaveName_4
	CheckBox W5_checkBox,pos={20,389},size={62,14},proc=EvPMW_W5_CheckProc,title="5th wave"
	CheckBox W5_checkBox,value= 0
	PopupMenu EvokStimWave5Popup,pos={87,385},size={187,21},proc=EvPMW_ChEvokStimWaveProc5,title="Apply Stim Wave:"
	PopupMenu EvokStimWave5Popup,mode=5,popvalue="StimWave_5",value= #"Wavelist(\"*\",\";\",\"\")"
	SetVariable StimWaveNameSetVar5,pos={44,413},size={235,16},title="Save with Wave Name:"
	SetVariable StimWaveNameSetVar5,value= root:EvPMW:EvPMW_StimWaveName_5
	CheckBox W6_checkBox,pos={17,444},size={62,14},proc=EvPMW_W6_CheckProc,title="6th wave"
	CheckBox W6_checkBox,value= 0
	PopupMenu EvokStimWave6Popup,pos={82,440},size={187,21},proc=EvPMW_ChEvokStimWaveProc6,title="Apply Stim Wave:"
	PopupMenu EvokStimWave6Popup,mode=6,popvalue="StimWave_6",value= #"Wavelist(\"*\",\";\",\"\")"
	SetVariable StimWaveNameSetVar6,pos={40,468},size={239,16},title="Save with Wave Name:"
	SetVariable StimWaveNameSetVar6,value= root:EvPMW:EvPMW_StimWaveName_6
	GroupBox InitPSCanalysisBox,pos={299,432},size={263,62},title="Init PSC analysis"
	SetVariable PSCMeas_Stim1time,pos={311,452},size={104,16},title="Time stim 1"
	SetVariable PSCMeas_Stim1time,limits={0,10,0.1},value= root:EvPMW:EvPMW_InitPSCdelay
	SetVariable PSCMeas_Stim1time01,pos={419,451},size={136,16},title="PSC latency"
	SetVariable PSCMeas_Stim1time01,limits={0,0.1,0.001},value= root:EvPMW:EvPMW_InitPSClatency
	CheckBox DisplayConcatCheck,pos={17,508},size={175,14},proc=EvPMW_DisplayConcatCheckProc,title="Display as concatenated waves?"
	CheckBox DisplayConcatCheck,value= 0
	SetVariable CmdVoltOn,pos={328,104},size={146,16},title="Command On (sec)"
	SetVariable CmdVoltOn,limits={0,10,0.01},value= root:EvPMW:EvPMW_CmdVolt_on
	SetVariable CmdVoltOff,pos={481,101},size={73,16},title="off (sec)"
	SetVariable CmdVoltOff,limits={0,10,0.01},value= root:EvPMW:EvPMW_CmdVolt_off
EndMacro


Function EvPMW_AvgCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_AverageCheck =  root:EvPMW:EvPMW_AverageCheck
	EvPMW_AverageCheck = checked
	print "Changing avg check to " num2str(EvPMW_AverageCheck)
End

Function EvPMW_DispHoldCurrCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_DispHoldCurrCheck =  root:EvPMW:EvPMW_DispHoldCurrCheck
	EvPMW_DispHoldCurrCheck = checked
	print "Changing display holding check to " num2str(EvPMW_DispHoldCurrCheck)
End

Function EvPMW_DispCmdVoltCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_DispCmdVoltCheck =  root:EvPMW:EvPMW_DispCmdVoltCheck
	EvPMW_DispCmdVoltCheck = checked
	print "Changing display command voltage check to " num2str(EvPMW_DispCmdVoltCheck)
End

Function EvPMW_CalcIRCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_CalcIRCheck =  root:EvPMW:EvPMW_CalcIRCheck
	EvPMW_CalcIRCheck = checked
	print "Changing RI calculate check to " num2str(EvPMW_CalcIRCheck)
End

function Kill_EvPMW_windows()
	SVAR EvPMW_WindowDispList=root:EvPMW:EvPMW_WindowDispList
	string allEvPMWgraphList 
	allEvPMWgraphList= winlist("EvPMW*",";","WIN:1")
	print allEvPMWgraphList
	variable numWin=Itemsinlist(allEvPMWgraphList,";")
	variable i=0
	string wn
	do
		wn=Stringfromlist(i,allEvPMWgraphList,";")
		//print wn
		if(!(strlen(wn)==0))
		Dowindow/K $wn
		endif
		i+=1
	while(i<numWin)
	Dowindow/K EvPMW_OutputWavesDisplay;Dowindow/K EvPMW_InitPSC_tab1;Dowindow/K InitialPSC_Layout
	Dowindow/K EvPMW_layout1;Dowindow/K EvPMW_layout2;Dowindow/K EvPMW_layout3;Dowindow/K EvPMW_layout4;Dowindow/K AverageTracesLayout
	Dowindow/K EvPMW_layout5;Dowindow/K EvPMW_layout6;
	DoWindow /K EvPMW_Holding_parameters;DoWindow /K EvPMW_InitPSC_win1;DoWindow /K EvPMW_InitPSC_win2;DoWindow /K EvPMW_TemperaturevsTrials
end
	
function EvPMW_setallaxes(ctrlname) : ButtonControl
	string ctrlname
	SVAR  NowMulticlampMode=	root:NIDAQBoardVar:NowMulticlampMode
	NVAR DataDisplay_x1	=	root:EvPMW:DataDisplay_x1
	NVAR DataDisplay_x2	=	root:EvPMW:DataDisplay_x2
	NVAR DataDisplay_y1_CC	=	root:EvPMW:DataDisplay_y1_CC	
	NVAR DataDisplay_y2_CC	=	root:EvPMW:DataDisplay_y2_CC
	NVAR DataDisplay_y1_VC	=	root:EvPMW:DataDisplay_y1_VC
	NVAR DataDisplay_y2_VC	=	root:EvPMW:DataDisplay_y2_VC
	string wn
	string wlist = "EvPMW_rawDataDisplay;EvPMW_allTracesDisplay;EvPMW_AvgWaveDisplay"
	variable index =0
	do
		wn = Stringfromlist(index,wlist,";")
		if (strlen(wn)==0)
			break
		endif
		Dowindow/F $wn
		if(V_flag)
			SetAxis bottom dataDisplay_x1,dataDisplay_x2
			if (stringmatch(NowMulticlampMode,"V-Clamp"))
				SetAxis left dataDisplay_y1_VC,dataDisplay_y2_VC
			else
				setaxis left dataDisplay_y1_CC,dataDisplay_y2_CC
			endif
		endif
		index+=1
	while(1)
	Dowindow /F EvPMW_allTracesDisplay_offset
	if(V_flag)
		SetAxis bottom dataDisplay_x1,dataDisplay_x2
	endif
end

Function EvPMW_ChEvokStimWaveProc1(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR EvPMW_StimWaveInput_1=  root:EvPMW:EvPMW_StimWaveInput_1
	EvPMW_StimWaveInput_1 =  popStr
	print "Changing subtrial1 input wave to " +EvPMW_StimWaveInput_1
End

Function EvPMW_ChEvokStimWaveProc2(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR EvPMW_StimWaveInput_2=  root:EvPMW:EvPMW_StimWaveInput_2
	EvPMW_StimWaveInput_2 =  popStr
	print "Changing subtrial2 input wave to " +EvPMW_StimWaveInput_2
End

Function EvPMW_ChEvokStimWaveProc3(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR EvPMW_StimWaveInput_3=  root:EvPMW:EvPMW_StimWaveInput_3
	EvPMW_StimWaveInput_3 =  popStr
	print "Changing subtrial3 input wave to " +EvPMW_StimWaveInput_3
End
Function EvPMW_ChEvokStimWaveProc4(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR EvPMW_StimWaveInput_4=  root:EvPMW:EvPMW_StimWaveInput_4
	EvPMW_StimWaveInput_4 =  popStr
	print "Changing subtrial4 input wave to " +EvPMW_StimWaveInput_4
End
Function EvPMW_ChEvokStimWaveProc5(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR EvPMW_StimWaveInput_5=  root:EvPMW:EvPMW_StimWaveInput_5
	EvPMW_StimWaveInput_5 =  popStr
	print "Changing subtrial5 input wave to " +EvPMW_StimWaveInput_5
End
Function EvPMW_ChEvokStimWaveProc6(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR EvPMW_StimWaveInput_6=  root:EvPMW:EvPMW_StimWaveInput_6
	EvPMW_StimWaveInput_6 =  popStr
	print "Changing subtrial6 input wave to " +EvPMW_StimWaveInput_6
End


Function EvPMW_W1_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_W1_check =  root:EvPMW:EvPMW_W1_check
	EvPMW_W1_check = checked
	print "Changing subtrial1 check to " num2str(EvPMW_W1_check)
End


Function EvPMW_W2_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_W2_check =  root:EvPMW:EvPMW_W2_check
	EvPMW_W2_check = checked
	print "Changing subtrial2 check to " num2str(EvPMW_W2_check)
End
Function EvPMW_W3_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_W3_check =  root:EvPMW:EvPMW_W3_check
	EvPMW_W3_check = checked
	print "Changing subtrial3 check to " num2str(EvPMW_W3_check)
End
Function EvPMW_W4_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_W4_check =  root:EvPMW:EvPMW_W4_check
	EvPMW_W4_check = checked
	print "Changing subtrial4 check to " num2str(EvPMW_W4_check)
End
Function EvPMW_W5_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_W5_check =  root:EvPMW:EvPMW_W5_check
	EvPMW_W5_check = checked
	print "Changing subtrial5 check to " num2str(EvPMW_W5_check)
End
Function EvPMW_W6_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR EvPMW_W6_check =  root:EvPMW:EvPMW_W6_check
	EvPMW_W6_check = checked
	print "Changing subtrial6 check to " num2str(EvPMW_W6_check)
End
