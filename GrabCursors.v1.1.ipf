#pragma rtGlobals=1		// Use modern global access method.
// updated Feb2003

menu "KateAnalysis"
	"Grab Delay",GrabDelay()
	"Grab Peak to Peak",GrabPeaktoPeak()
	"Grab Peak Amp, Rise, Lat Stats", GetPeakStats()
	"Fit Exponential Curve" ,DoExpCurveFit()
	"Fit Double Exponential Curve" , DoDblExpCurveFit()
	//"Fit Recovery, Dbl exp", DoDblExpCurveFit()
	//"Fit Recovery, Single Exp",DoSingleExpCurveFit_recovery()
	"Quickie peak grabber",FastGetPeaks()
	//"Quick cursor value grabber", FastGrabCursor()
end

function GrabDelay()
	variable Avalue
	variable Bvalue
	variable delay
	Avalue=xcsr(A)
	Bvalue=xcsr(B)
	delay=Bvalue-Avalue
	
	print delay
end

function GrabPeaktoPeak()
	variable Avalue
	variable Bvalue
	variable peaktopeak
	Avalue=vcsr(A)
	Bvalue=vcsr(B)
	peaktopeak=Avalue-Bvalue
	print peaktopeak
end


function  FastGetPeaks()
	string wlist, w
	variable x1,x2
	Dowindow/K PeakAmpsGraph
	Dowindow/K PeakAmpsTable
	wlist=wavelist("*",";","WIN:")
	print wlist;
	variable n = itemsinlist(wlist)
	Make/O/N=(n) peakamps
	x1=xcsr(A)
	x2=xcsr(B)
	variable i=0
	do
	w=stringfromlist(i,wlist,";")
	//print "getting from " + w
	Wave mywave = $w
	//peakamps[i]= mean(mywave,x2-0.0005,x2+0.0005)  - mean(mywave,x1-0.002,x1)	//x1 window of 10ms prior; x2 window 5ms, +/-2.5 ms
	peakamps[i]=mywave(x2)  -  mywave(x1)
	//print peakamps[i]
	i+=1
	while(i<n)
	
	display peakamps  as "Peak amplitude vs stimulus sequence"
	Dowindow/C PeakAmpsGraph
	Modifygraph mode=3, marker=14, zero(left)=1
	setaxis /A
	Label left "Peak amplitudes,V"
	Label bottom "stimulus sequence"
	edit peakamps
	Dowindow/C PeakAmpsTable
end

function  FastGrabCursor()
	string wlist, w
	variable x1,x2
	wlist=wavelist("*",";","WIN:")
	variable n = itemsinlist(wlist)
	Make/O/N=(n) CursorYvalues
	x1=xcsr(A)
	//x2=xcsr(B)
	variable i=0
	do
	w=stringfromlist(i,wlist,";")
//	print "getting from " + w
	Wave mywave = $w
	CursorYvalues[i]= mean(mywave,x1-0.0002,x1)
	//peakamps[i]=mywave(x2)  -  mywave(x1)
	//print peakamps[i]
	i+=1
	while(i<n)
	
	display CursorYvalues  as "Cursor value vs stimulus sequence"
	Modifygraph mode=3, marker=14, zero(left)=1
	setaxis /A/E=1
	Label left "Y Value,V"
	Label bottom "stimulus sequence"
	
end


function GetPeakStats()
	variable peakx, peakamp
	variable x_90, x_10,y_90,y_10
	string wlist, w
	variable risetime
	variable latency
	string NameStr, X_Name,Y_Name
	Make/O/N=2 x_values, y_values
	Removefromgraph /Z y_values
	wlist=wavelist("*",";","WIN:")
	w=stringfromlist(0,wlist,";")
	peakx = xcsr(B)
	latency = xcsr(B)- xcsr(A)
	peakamp = vcsr(B)-vcsr(A)
	print num2str(peakx),num2str(latency), num2str(peakamp)
	textbox /K/N=text1
	string textstr = "Peak Amplitude : "  + num2str(1000*peakamp) + " pA\rPeak Latency : " +  num2str(1000*latency) + " ms"
	textbox /N=text1/F=0 /A=RT textstr
	y_90 = 0.9*peakamp
	y_10 = 0.1*peakamp
	
	// round these to nearest  0.1 pA:
	//y_90=round(y_90*10000)/10000
	//y_10=round(y_10*10000)/10000
	print y_10, Y_90
	FindLevel /Q/R=(peakx,peakx-latency/3 ) $w, y_90
	if(V_flag)
		abort "Cannot find 90% level at " + num2str(Y_90) + " nA"
	endif
	x_90=V_levelx
	print x_90
	FindLevel  /Q/R=(peakx,peakx-latency/2)  $w, y_10
	if(V_flag)
		print "Cannot find 10% level at " + num2str(Y_10) + " nA"
		variable Y_20= 0.2*peakamp
		FindLevel  /Q/R=(peakx,latency/2) $w, y_20
		if(V_flag)
			print "Cannot find 20% level at " + num2str(Y_20) + " nA"
			variable Y_50= 0.5*peakamp
			FindLevel  /Q/R=(peakx,latency/2) $w, y_50
			if(V_flag)
				abort "Cannot find even 50% level at " + num2str(Y_50) + " nA"
			else
				risetime= (x_90 -V_levelx)*(8/4)
				x_10 = x_90 - risetime 
				
			endif
		else
			risetime= (x_90 -V_levelx)*(8/7)
			x_10 = x_90 - risetime 
		endif
	else
		x_10=V_levelx
		risetime=x_90-x_10
	endif
	print x_10
	x_values= {x_10,x_90}
	y_values = {y_10,y_90}
	X_Name = w + "_xval_Pksts"
	Duplicate/O x_values, $X_Name
	Y_Name = w + "_yval_Pksts"
	Duplicate/O y_values, $Y_Name
	AppendtoGraph  $Y_Name vs $X_Name;  ModifyGraph mode($Y_Name)=4, marker($Y_Name)=16,rgb($Y_Name)=(0,0,65280)
	textstr = "10-90 rise time : " + Num2str(1000*risetime) + " ms\r"+ textstr
	textbox /C/N=text1  textstr
	// saving values according to parent wave
	NameStr = w + "_rise_Pksts"
	Make/O/N=1  $NameStr = {risetime}
	NameStr = w + "_lat_Pksts"
	Make/O/N=1  $NameStr = {latency}
	NameStr = w + "_pkamp_Pksts"
	Make/O/N=1  $NameStr = {peakamp}
	print "10% latency =", num2str(x_10-xcsr(A))
	print "10% to peak time=", num2str(xcsr(B)-x_10)
end


function DoExpCurveFit()		//single exponential on time-varying wave
	string wlist, w
	variable V_FitMaxIters, V_FitTol,tau,V_FitNumIters
	string NameStr
	V_FitMaxIters = 100
	V_FitTol = 0.005
	//wlist=wavelist("*",";","WIN:")
	//w=stringfromlist(0,wlist,";")
	w=csrWave(A)
	CurveFit  /N/Q/W=0 exp $w[pcsr(A),pcsr(B)] /D  //suppress results in cmd window
	//CurveFit  /N/W=0 exp $w[pcsr(A),pcsr(B)] /D
	WAVE W_coef
	tau= 1/W_coef[2]
	textbox /K/N=text0
	string textstr = "Exp Decay Tau : "  + num2str(1000*tau) + " ms"
	textbox /N=text0/F=0 /A=RC textstr
	print "Num of iterations required:" + num2str(V_fitnumiters)
	NameStr = w + "_tau"
	Make/N=1/O $NameStr={tau}
	
	
end

function DoDblExpCurveFit()  //double exponential on time-varying wave
	string wlist, w
	variable V_FitMaxIters, V_FitTol,tau1,tau2,V_FitNumIters
	variable y0, A1, A2, invtau1, invtau2
	string NameStr
	V_FitMaxIters = 100
	V_FitTol = 0.005
	Make/O/D/N=5 CoefGuess
	CoefGuess={0,-0.1,100,-0.1,10}		// make coefficient wave for itial guess; /H="10000" holds the y0 value to 1.
	wlist=wavelist("*",";","WIN:")
	w=stringfromlist(0,wlist,";")
	w=csrWave(A)
	print w
	
	//if(WaveExists(RecoveryWave))  // fitting a recovery curve
	//	CurveFit  /G/H="10000"/N/W=0 dblexp kwCWave=CoefGuess $w[pcsr(A),pcsr(B)] /X=RecoveryWave/D  //suppress results in cmd window
		//print "using recovery wave for x wave"
	//else		// otherwise assume time-dependent wave
		//CurveFit  /N/W=0 dblexp $w[pcsr(A),pcsr(B)] /D  
		CurveFit /N/W=0/H="10000"/NTHR=0/TBOX=0  dblexp kwCWave=CoefGuess  $w[pcsr(A),pcsr(B)] /D
	//endif
	//CurveFit/NTHR=0/TBOX=0 dblexp  NrmRecovAvg_200Hz /X=RecoveryWave /D 
	//CurveFit  /N/W=0 exp $w[pcsr(A),pcsr(B)] /D
	WAVE CoefGuess
	tau1= 1/CoefGuess[2]
	tau2 = 1/CoefGuess[4]
	y0= CoefGuess[0]
	A1 = CoefGuess[1]
	invtau1= CoefGuess[2]
	A2 = CoefGuess[3]
	invtau2= CoefGuess[4]
	
	
	textbox /K/N=Fittext
	string textstr
	if(WaveExists(RecoveryWave))
	textstr= "Exp Decay Tau1 : "  + num2str(tau1) + "ms,  Tau 2 : " +   num2str(tau2) + " ms"
	print textstr
	else
	textstr= "Exp Decay Tau1 : "  + num2str(tau1) + "sec,  Tau 2 : " +   num2str(tau2) + " sec"
	endif
	textstr += "\rA1 : " + num2str(CoefGuess[1]) + " ,  A2 : " + num2str(CoefGuess[3])
	textstr += "\ry0 : " + num2str(CoefGuess[0]) 
	textbox /N=Fittext/F=0 /A=RC textstr
	print "Num of iterations required:" + num2str(V_fitnumiters)
	NameStr = w + "_dbltau"
	Make/N=2/O $NameStr={tau1,tau2}
	// make table
	Edit $NameStr, CoefGuess
	
end

//function DoSingleExpCurveFit_recovery()
//	string wlist, w
//	variable V_FitMaxIters, V_FitTol,tau1,V_FitNumIters
//	variable y0, A1, invtau1
//	string NameStr
//	V_FitMaxIters = 100
//	V_FitTol = 0.005
//	Make/O/D/N=3 CoefGuess
//	CoefGuess={1,-0.1,.001}		// make coefficient wave for itial guess; /H="10000" holds the y0 value to 1.
//	//wlist=wavelist("*",";","WIN:")
//	//w=stringfromlist(0,wlist,";")
//	w=csrWave(A)
//	print w
//	
//	if(WaveExists(RecoveryWave))  // fitting a recovery curve
//		CurveFit  /G/H="10000"/N/W=0 exp kwCWave=CoefGuess $w[pcsr(A),pcsr(B)] /X=RecoveryWave/D  //suppress results in cmd window
//		print "using recovery wave for x wave"
//	else		// otherwise assume time-dependent wave
//		CurveFit  /N/W=0 exp $w[pcsr(A),pcsr(B)] /D  
//	endif
//	//CurveFit/NTHR=0/TBOX=0 dblexp  NrmRecovAvg_200Hz /X=RecoveryWave /D 
//	//CurveFit  /N/W=0 exp $w[pcsr(A),pcsr(B)] /D
//	WAVE CoefGuess
//	tau1= 1/CoefGuess[2]
//	
//	y0= CoefGuess[0]
//	A1 = CoefGuess[1]
//	invtau1= CoefGuess[2]
//	textbox /K/N=Fittext
//	string textstr
//	if(WaveExists(RecoveryWave))
//	textstr= "Exp Decay Tau1 : "  + num2str(tau1) + "ms"
//	print textstr
//	else
//	textstr= "Exp Decay Tau1 : "  + num2str(tau1) + "sec " 
//	endif
//	textstr += "\rA1 : " + num2str(CoefGuess[1]) 
//	textstr += "\ry0 : " + num2str(CoefGuess[0]) 
//	textbox /N=Fittext/F=0 /A=RC textstr
//	print "Num of iterations required:" + num2str(V_fitnumiters)
//	NameStr = w + "_dbltau"
//	Make/N=1/O $NameStr={tau1}
//	// make table
//	Edit $NameStr, CoefGuess
//
//end



//function DoSingleExpCurveFit_recovery()
//	string wlist, w
//	variable V_FitMaxIters, V_FitTol,tau1,tau2,V_FitNumIters
//	string NameStr
//	V_FitMaxIters = 100
//	V_FitTol = 0.005
//	Make/O/D/N=3 CoefGuess
//	CoefGuess={1,-0.1,.001}		// make coefficient wave for itial guess; /H="10000" holds the y0 value to 1.
//	//wlist=wavelist("*",";","WIN:")
//	//w=stringfromlist(0,wlist,";")
//	w=csrWave(A)
//	if(WaveExists(RecoveryWave))  // fitting a recovery curve
//		CurveFit  /G/H="10000"/N/W=0 exp kwCWave=CoefGuess $w[pcsr(A),pcsr(B)] /X=RecoveryWave/D  //suppress results in cmd window
//	else		// otherwise assume time-dependent wave
//		CurveFit  /N/W=0 exp $w[pcsr(A),pcsr(B)] /D  
//	endif
//	//CurveFit/NTHR=0/TBOX=0 dblexp  NrmRecovAvg_200Hz /X=RecoveryWave /D 
//	//CurveFit  /N/W=0 exp $w[pcsr(A),pcsr(B)] /D
//	WAVE W_coef
//	tau1= 1/W_coef[2]
//	textbox /K/N=Fittext
//	string textstr
//	if(WaveExists(RecoveryWave))
//	textstr= "Exp Decay Tau1 : "  + num2str(tau1) + "ms,"
//	else
//	textstr= "Exp Decay Tau1 : "  + num2str(tau1) + "sec"
//	endif
//	textbox /N=Fittext/F=0 /A=RC textstr
//	print "Num of iterations required:" + num2str(V_fitnumiters)
//	NameStr = w + "_tau"
//	Make/N=2/O $NameStr={tau1}
//	
//	
//end