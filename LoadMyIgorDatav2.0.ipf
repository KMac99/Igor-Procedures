  #pragma rtGlobals=1		// Use modern global access method.
#include <Concatenate Waves>
// Version 2.0

function LoadMyIgorData_2d()	
	string fileNameStr   
	String  totalStr
	variable j=0
	variable i=0
	variable	setStart  =15
	variable	setEnd  = 19
	variable	setNum =setEnd-setStart+1
	variable	trialStart  = 0
	variable 	trialEnd  = 8
	NVAR	trialNum = root:LoadDataPanel:trialNum
	SVAR  basename = root:LoadDataPanel:basename
	SVAR pathnameStr = root:LoadDataPanel:pathnameStr
	SVAR filesuffix = root:LoadDataPanel:filesuffix
	SVAR endtag   = root:LoadDataPanel:endtag
	fileNameStr=basename + num2str(setStart)  + filesuffix +num2str(trialStart) 
	print fileNameStr
	TotalStr=pathnameStr+filenamestr
	LoadWave/H/A/O/Q TotalStr
	WAVE w = $filenamestr
	Display w
	j=setStart
	do
		print "loading set# ",  j
		i=trialStart
		do
			fileNameStr=basename + num2str(j)  + filesuffix +num2str(i) 
			TotalStr=pathnameStr+filenamestr +endtag
			LoadWave/H/A/O/Q TotalStr
			WAVE w = $filenamestr
			appendtograph w
			i+=1
		while(i<=trialEnd)
		print "last trial# ", i
		j+=1
	while(j<=setEnd)
end



function ConcatenateTheseWaves(ctrlname): buttoncontrol
	string ctrlname	
	string dest
	string fileNameStr
	String  totalStr
	variable j=0
	NVAR	trialStart  = root:LoadDataPanel:trialStart
	NVAR	trialNum = root:LoadDataPanel:trialNum
	NVAR	trialEnd  = root:LoadDataPanel:trialEnd
	SVAR  basename = root:LoadDataPanel:basename
	SVAR pathnameStr = root:LoadDataPanel:pathnameStr
	SVAR filesuffix = root:LoadDataPanel:filesuffix
	SVAR endtag   = root:LoadDataPanel:endtag
	dest = "M_"+ basename+ num2str(trialStart)+ "_" + num2str(trialEnd)+ filesuffix
	Make/O/N=1 $dest
	j=trialStart
	do
		fileNameStr=basename +num2str(j) + filesuffix 
		ConcatenateWaves(dest, fileNameStr)
		j+=1
	while(j<=trialEnd)
	Display $dest as dest
	TextBox dest
end

function ConcatWavesInGraph(ctrlname):  buttoncontrol
	string ctrlname	
	string dest="M_concatwave"
	string wlist, fileNameStr
	variable numwaves, index=0, j=0,m
	wlist=WaveList("*",";","WIN:")
	numwaves=ItemsinList(wlist)
	PauseUpdate;		
	do
		fileNameStr=stringfromlist(index,wlist,";")	
		print num2str(index), "  ", 	fileNameStr
		if (strlen(fileNameStr)==0)
			break
		endif
		ConcatenateWaves(dest, fileNameStr)
		index +=1
	while(1)	
	Display $dest
end


Window LoadDataPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(572.25,47,987.75,331.25)
	ModifyPanel cbRGB=(48896,52992,65280)
	ShowTools
	SetDrawLayer UserBack
	DrawRRect 28,2,168,26
	DrawText 55,21,"Load Igor Data"
	SetDrawEnv linethick= 0.5,fillfgc= (48896,52992,65280)
	DrawRect 10,268,377,113
	SetDrawEnv fillfgc= (52224,52224,52224)
	SetDrawEnv save
	DrawRect 14,116,13,117
	SetDrawEnv fsize= 9
	DrawText 162,113,"Form: 'basename' + number + 'suffix' + '.ibw'"
	Button ButtonLoad,pos={132,131},size={94,38},proc=LoadMyIgorData,title="Load These Files"
	SetVariable PathSetVar,pos={5,39},size={266,16},title="File Path"
	SetVariable PathSetVar,limits={-Inf,Inf,1},value= root:LoadDataPanel:pathnameStr
	SetVariable BasenameSetVar,pos={6,62},size={264,16},title="File Basename"
	SetVariable BasenameSetVar,limits={-Inf,Inf,1},value= root:LoadDataPanel:basename
	SetVariable TrialStartSetVar,pos={33,119},size={92,16},title="Start at:"
	SetVariable TrialStartSetVar,limits={0,1000,1},value= root:LoadDataPanel:trialStart
	SetVariable TrialStartSetVar01,pos={34,166},size={92,17},title="# trials:"
	SetVariable TrialStartSetVar01,font="Arial",fSize=9
	SetVariable TrialStartSetVar01,limits={1,1000,0},value= root:LoadDataPanel:TrialNum,noedit= 1
	SetVariable TrialStartSetVar0101,pos={33,141},size={92,16},title="End at:"
	SetVariable TrialStartSetVar0101,limits={0,1000,1},value= root:LoadDataPanel:trialEnd
	Button LoadAllButton,pos={23,185},size={195,26},proc=LoadAllProc,title="Load All Binary Waves in Path Folder"
	SetVariable ShowSuffixSetVar,pos={179,4},size={125,17},title="Data type suffix"
	SetVariable ShowSuffixSetVar,font="Arial",fSize=9
	SetVariable ShowSuffixSetVar,limits={-Inf,Inf,0},value= root:LoadDataPanel:endtag,noedit= 1
	Button SelectFolderButton,pos={278,36},size={97,20},proc=SelectFolderDialog,title="Select Folder"
	Button GraphButton,pos={23,219},size={108,24},proc=GraphMyIgorData,title="Graph these waves"
	SetVariable setvar0,pos={8,85},size={149,16},title="File name suffix"
	SetVariable setvar0,limits={-Inf,Inf,0},value= root:LoadDataPanel:filesuffix
	SetVariable EndtagSetVar,pos={167,85},size={146,16},title="file type tag"
	SetVariable EndtagSetVar,limits={-Inf,Inf,1},value= root:LoadDataPanel:endtag
	CheckBox AppendCheckBox,pos={21,248},size={115,14},proc=AppendCheckProc,title="Append to top graph"
	CheckBox AppendCheckBox,value= 0
	Button ConcatButtonControl,pos={236,136},size={129,33},proc=ConcatenateTheseWaves,title="Concatenate these waves"
	Button ConcatWavesGraphButton,pos={182,227},size={140,34},proc=ConcatWavesInGraph,title="Concat Waves in Graph"
EndMacro

macro InitLoadPanel()
	string dfsave=getDataFolder(1)
	
	NewDataFolder /O/S root:LoadDataPanel
	KillWaves/a/z
	Killvariables /a/z
	killstrings /a/z
	string/G pathnameStr = "c:Data:"
	//string/G pathnameStr = "Owl-nt:Shared:Kate Shared:Expt_backup_Owl12:21feb04_01 Folder:EvPMW:"
	string/G basename="EvPMW_21feb04c1s0_A"
	string /G filesuffix="_0"
	//string/G endtag=".ibw"	
	string/G endtag=".ibw"			//igor binary wave
	variable/G TrialStart,TrialNum,TrialEnd,Appendcheck
	AppendCheck =0
	TrialStart=0
	TrialNum:=TrialEnd-TrialStart+1
	TrialEnd= 9
	// error catch here - bad path
	Newpath/O/C LoadingPath, pathnameStr
	execute "LoadDataPanel()"
	SetDataFolder dfsave
end

Function AppendCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR AppendCheck = root:LoadDataPanel:AppendCheck
	AppendCheck=checked
	print "AppendCheck = " + num2str(AppendCheck)
End

function LoadAllProc(ctrlname): buttoncontrol
	string ctrlname
	SVAR  basename = root:LoadDataPanel:basename
	SVAR pathnameStr = root:LoadDataPanel:pathnameStr
	SVAR endtag   = root:LoadDataPanel:endtag
	LoadData  /O/L=1/P=LoadingPath/Q/D
end


function LoadMyIgorData(ctrlname)	:	ButtonControl
	string ctrlname
	string fileNameStr
	String  totalStr
	variable j=0
	NVAR	trialStart  = root:LoadDataPanel:trialStart
	NVAR	trialNum = root:LoadDataPanel:trialNum
	NVAR	trialEnd  = root:LoadDataPanel:trialEnd
	SVAR  basename = root:LoadDataPanel:basename
	SVAR pathnameStr = root:LoadDataPanel:pathnameStr
	SVAR filesuffix = root:LoadDataPanel:filesuffix
	SVAR endtag   = root:LoadDataPanel:endtag
	j=trialStart
	do
		fileNameStr=basename +num2str(j) + filesuffix +endtag
		TotalStr=pathnameStr+filenamestr
		LoadWave/H/A/O/Q TotalStr
		j+=1
	while(j<=trialEnd)
end


Function SelectFolderDialog(ctrlName) : ButtonControl
	String ctrlName
	SVAR pathnameStr =  root:LoadDataPanel:pathnameStr
	Newpath/O/Q LoadingPath
	PathInfo LoadingPath
	pathnameStr = S_path
End


function GraphMyIgorData(ctrlname)	:	ButtonControl
	string ctrlname
	string fileNameStr
	String  totalStr
	variable j=0
	variable offsetY=-0.2
	variable offsetTick=0
	variable ColorandOffsetCheck=0
	NVAR Appendcheck = root:LoadDataPanel:AppendCheck
	NVAR	trialStart  = root:LoadDataPanel:trialStart
	NVAR	trialNum = root:LoadDataPanel:trialNum
	NVAR	trialEnd  = root:LoadDataPanel:trialEnd
	SVAR  basename = root:LoadDataPanel:basename
	SVAR filesuffix = root:LoadDataPanel:filesuffix
	SVAR pathnameStr = root:LoadDataPanel:pathnameStr
	SVAR endtag   = root:LoadDataPanel:endtag
	j=trialStart
	do
		fileNameStr=basename +num2str(j) +filesuffix
		TotalStr=pathnameStr+filenamestr
		if(j==trialStart)
			if(appendcheck)
				AppendtoGraph $fileNameStr
			else
				Display $fileNameStr
			endif
		else
			AppendtoGraph $fileNameStr
			OffsetTick+=1	
		endif
		if(colorandoffsetCheck)
			ModifyGraph offset($fileNameStr)={0,(OffsetY*offsetTick)}
		endif
		j+=1
	while(j<=trialEnd)
	if(colorandoffsetCheck)
		Execute "ColorStyleMacro()"
	endif
	textbox /A=MT/E/F=0 basename
end


