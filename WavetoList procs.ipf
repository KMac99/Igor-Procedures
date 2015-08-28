#pragma rtGlobals=1		// Use modern global access method.



function/s ConvertNumWavetoList(wave0)
	WAVE wave0
	String destListStr=""
	variable wavelength
	variable i=0
	if((wavetype(wave0)==0))
		Abort "Aborting function 'ConvertNumWavetoList()' :  wave is not a Numerical Wave"
	endif
	// get length of wave
	wavelength=numpnts(wave0)
		do
			destListStr+=num2str(wave0[i]) + ";"

			i+=1
		while(i<wavelength)
	//	print destListStr
		return destListStr
end

		
function/s ConvertTextWavetoList(wave0)
	WAVE/T wave0

	String destListStr=""
	variable wavelength
	variable i=0
	
	if(!(wavetype(wave0)==0))
		Abort "Aborting function 'ConvertTextWavetoList()' :  input wave is not a Text Wave"
	endif
	
	// get length of wave
	wavelength=numpnts(wave0)
		do
			destListStr+=wave0[i] + ";"
			i+=1
		while(i<wavelength)
		// print destListStr
		return destListStr
end

/// Converts a numerical wave to a text wave, creating a new wave with "_txt" suffix.
// Does not overwrite existing wave.
function NumWavetoTextWave(NUMwave)
	WAVE NUMwave
	if((wavetype(NUMwave)==0))
		Abort "Aborting function 'NumWavetoTextWave()' :  input wave is not a Numerical Wave"
	endif
	string textWaveName=NameofWave(NumWave)
	textwavename+="_txt"

	variable wavelength=numpnts(NUMwave)
	string s
	Make/T/O/N=(wavelength) temp_wave
	variable i=0	
	do
		temp_wave[i]=num2str(NUMwave[i])
		i+=1
	while(i<wavelength)
	
	duplicate/T/O temp_wave, $textWaveName
	killwaves  temp_wave
end

/// Converts a text wave to a numerical wave, creating a new wave with "_num" suffix.
// Does not overwrite existing wave.
function TextWavetoNumWave(TEXTwave)
	WAVE/T TEXTwave
	if(!(wavetype(TEXTwave)==0))
		Abort "Aborting function 'TextWavetoNumWave()' :  input wave is not a Text Wave"
	endif
	string numWaveName=NameofWave(TEXTWave)
	numwavename+="_num"
	variable NaN_flag
	variable wavelength=numpnts(TEXTwave)

	Make/O/N=(wavelength) temp_wave
	variable i=0	
	do
		temp_wave[i]=str2num(TEXTwave[i])	
		if(! (numtype(temp_wave[i])==0))
			NaN_flag=1
		endif			
		i+=1
	while(i<wavelength)
	if(Nan_flag)
		print "Warning!   Numerical wave may contain NaN or +-Inf."
	endif
	duplicate/T/O temp_wave, $numWaveName
	killwaves  temp_wave
end

function ConvertListToTextWave(List, destName)
	string List
	string destName
	variable i=0
	variable number=ItemsinList(list)
	Make/T/O temp_wave
	do
		temp_wave[i]=stringfromlist(i,list)
		i+=1
	while(i<number)
	
	duplicate/O/T temp_wave, $destName
	killwaves temp_wave
end

function ReturnSisterValue(value,wave0,wave1)
	Variable value
	WAVE wave0
	WAVE wave1
	variable sistervalue
	//check that waves are sister waves:
	if(!(numpnts(wave1)==numpnts(wave0)) )
		print "Warning :  waves are not of the same length; Are you sure these are matching waves?"
	endif
	
	FindValue /V=(value)/T=0.1 wave0
	if(V_value==-1)
				print "Original value not found in wave"
		elseif(V_value>numpnts(wave1)-1)
			print "Index exceeding range of sister wave; no sister value found"
		else
			sistervalue=wave1[V_value]
			print sistervalue
			return sistervalue
	endif

end
	