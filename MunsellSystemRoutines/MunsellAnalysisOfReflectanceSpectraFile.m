function [NameList, MunsellList, C2xyY] = ...
		MunsellAnalysisOfReflectanceSpectraFile(FileOfReflectanceSpectra, ...
												NameForOutput, ...
												FileOfNames);
% Purpose		Analyze a colour set, where colours are given by reflectance spectra that are
%				stored in a .csv file in X-Rite ColorMunki format.
%
% Description	This routine describes a set of colours in terms of the Munsell system.  It
%				was originally intended to describe a set of pastels.  Pastel sets are large,
%				typically containing hundreds of different colours.  An artist or designer
%				(or pastel manufacturer) needs some way to organize the set, and to see it as a
%				whole.  The Munsell system is a natural tool, because it uses perceptual
%				quantities that are of interest visually.  
%
%				This function is a wrapper for another function, MunsellAnalysisOfColourSet.
%				The latter function takes as input a list of Munsell specifications, and
%				possibly a list of colour names.  The current function reads in data from
%				files, converts it into Octave/Matlab lists, and then calls 
%				MunsellAnalysisOfColourSet.  	
%
%				The file containing the reflectance spectra is expected to be in the .csv
%				format produced by the X-Rite ColorMunki spectrophotometer.  This is a
%				text format.  The first line contains four placeholders, and then a list
%				of wavelengths, from 380 nm to 730 nm, in 10 nm increments.  Each subsequent
%				line gives the reflectance spectrum for one colour.  The line s first
%				entry is an identifying number or string.  The next three entries are L*a*b*
%				coordinates; the current function ignores these three entries.  The remaining
%				entries are the reflectance ratios (as a value between 0 and 1) for each
%				wavelength listed in the first line.  All entries in any line are separated
%				by commas---hence the acronym csv (comma-separated values).	
%
%				An optional argument is a file containing names for the colours.  If there
%				is such a file, then it must be a text file, every line of which gives a
%				name or identifier for a colour.  The identifiers can be numbers, although
%				they will be manipulated as strings.  The number of names must be the same
%				as the number of colours in the reflectance spectra file, and the two files
%				must list the colours in the same order.		
%
%				FileOfReflectanceSpectra	Comma-separated text file, with the same
%								format as a .csv file exported from the ColorMunki Design
%								spectrophotometer.
%
%				NameForOutput	A string that will identify which colour set is being
%								analyzed.  This string will be attached to the front of
%								the names of saved figures and files.
%
%				FileOfNames		A text file, each line of which gives a name or identifier
%								for a colour in the reflectance spectra file.  This input
%								is optional.
%
%				NameList		An output list of names, taken from FileOfNames.
%
%				MunsellList		An output list of Munsell specifications, for each 
%								reflectance spectrum, in order.
%
%				C2xyY			A three-column output matrix giving the xyY coordinates of
%								the reflectance spectra, relative to C/2 viewing conditions.
%
% Author		Paul Centore (April 4, 2014)
% Revised		Paul Centore (September 20, 2014)
% 				---Routine now produces additional files, and output variables
% Revised		Paul Centore (June 26, 2014)
% 				---Calculate xyY coordinates, save to file, and return as output
%
% Copyright 2014-2015 Paul Centore
%
%    This file is part of MunsellAndKubelkaMunkToolbox.
%
%    MunsellAndKubelkaMunkToolbox is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    MunsellAndKubelkaMunkToolbox is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with MunsellAndKubelkaMunkToolbox.  If not, see <http://www.gnu.org/licenses/>.

% Initialize output variables
NameList    = {}	;
MunsellList = {}	;

% Read in the reflectance spectra in the input file, and express them as a vector of 
% wavelengths, and a matrix of reflectances
[Wavelengths, Reflectances] = ColorMunkiCSVfileToOctaveFormat(FileOfReflectanceSpectra);
NumberOfWavelengths         = length(Wavelengths)	;
NumberOfSpectra             = size(Reflectances,1)	;
disp([num2str(NumberOfSpectra),' reflectance spectra in data file.'])

% Convert the reflectance spectra into CIE coordinates (both XYZ and xyY).  Since the
% Munsell system is standardized on Illuminant C and the CIE 1931 2 degree observer,
% specify C/2 observing conditions.
CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, Reflectances, 'C/2')	;
C2xyY     = CIEcoords(:,4:6)													;

% Names (usually assigned by a manufacturer) might be available from an input file.  If
% such a file exists, then read it in and store the names in a variable called NameList.
if exist('FileOfNames') 
	% Read in list of names from file
	NameList = {}		;
	NameFile = fopen(FileOfNames, 'r')	;
	while not(feof(NameFile))
		NameList{end+1} = fgetl(NameFile)	;
	end
	fclose(NameFile)	;
	
	for NameCtr = 1:length(NameList)
		% Replace any commas in the name with a semicolon.  This replacement is made because
		% some output files are comma-separated files, and commas in a name will be read as
		% separators rather than as part of the name.  This adjustment was motivated by
		% Rembrandt pastels, which have comma-containing names such as '727,3'
		Name = NameList{NameCtr} 		;
		for CharacterCtr = 1:length(Name)
			if strcmp(Name(CharacterCtr),',')
				Name(CharacterCtr) = ';'	;
			end
		end
		NameListNoCommas{NameCtr} = Name 	;
	end
	disp([num2str(length(NameList)),' colours in set.'])
end

% Produce a text file of names and reflectance spectra.  The first line of the file is a header line
% that gives the wavelengths at which reflectances have been measured.  Every line after the
% first gives the name of a colour (taken from the input FileOfNames), followed by the
% reflectances at those wavelengths.  Each reflectance is expressed as a number between 0
% and 1.  This reflectance file is only created if the variable FileOfNames has been input.
if exist('FileOfNames') 
	% Construct the first line in the reflectance file as a string
	FirstLine = 'Name'	;
	for wavelength = Wavelengths
		FirstLine = [FirstLine, ', ',num2str(wavelength),' nm']	;
	end
	
	% Create a file, and write the first line
	ReflectanceOutputFileName = [NameForOutput,'NamesAndReflectanceSpectra','.txt'] ;
	ReflectanceOutputFile     = fopen(ReflectanceOutputFileName, 'w')				;
	fprintf(ReflectanceOutputFile, '%s', FirstLine) 								;
	
	% Write a line for each name in the input FileOfNames; these names have already been
	% assigned to the variable NameListNoCommas.
	for NameCtr = 1:length(NameList)
		% Start a new line
		fprintf(ReflectanceOutputFile, '\n') 	;

		Name = NameListNoCommas{NameCtr}	;
		fprintf(ReflectanceOutputFile, '%s', Name) 	;

		% Write the reflectance for each wavelength to the file.  The rounding off is used
		% to produce more presentable output
		for WavelengthCtr = 1:NumberOfWavelengths
			fprintf(ReflectanceOutputFile, ', %s', sprintf('%6.4f',Reflectances(NameCtr,WavelengthCtr)))	;
		end
	end
		
	fclose(ReflectanceOutputFile)		;
end

% Produce a text file of xyY coordinates, relative to C/2 viewing conditions.
% If a file of names is input, then produce an additional file that contains the names, too.
xyYOutputFileName = [NameForOutput,'C2xyY','.txt'] 	;
dlmwrite(xyYOutputFileName, C2xyY, '\t')			;
SaveName = [NameForOutput,'xyY.mat'] 				;
xyY      = C2xyY									;
save(SaveName, 'xyY')
if exist('FileOfNames') 
	NameAndxyYOutputFile = [NameForOutput,'NamesAndC2xyY','.txt'] 	;
	NameAndxyYOutputFid  = fopen(NameAndxyYOutputFile, 'w')			;
	for ctr = 1:NumberOfSpectra
		if ctr == NumberOfSpectra
			fprintf(NameAndxyYOutputFid, '%s\t%6.4f\t%6.4f\t%7.4f', ...
					NameList{ctr}, ...
					C2xyY(ctr,1), C2xyY(ctr,2), C2xyY(ctr,3))	;
		else
			fprintf(NameAndxyYOutputFid, '%s\t%6.4f\t%6.4f\t%7.4f\n', ...
					NameList{ctr}, ...
					C2xyY(ctr,1), C2xyY(ctr,2), C2xyY(ctr,3))	;
		end
	end
	fclose(NameAndxyYOutputFid)	;
end

% Find the Munsell specifications resulting from the reflectance spectra.
% If Munsell specifications have already been calculated, then just read them in, rather
% than recalculating them (the conversion to Munsell can be slow).  If a file
% has already been created, it will have been given the following name:
MunsellOutputFileName = [NameForOutput,'MunsellSpecs','.txt'] 	;
NonConvertedCtrs = []	;	% Keep a list of colours which fail to be converted
if not(isempty(which(MunsellOutputFileName)))	% Such a file exists.
	% Read the Munsell list from this file.
	disp(['Munsell specifications being read in from file.'])
	MunsellList = {}		;
	MunsellOutputFile = fopen(MunsellOutputFileName, 'r')	;
	while not(feof(MunsellOutputFile))
		MunsellList{end+1} = fgetl(MunsellOutputFile)	;
	end
	fclose(MunsellOutputFile)	;
else 		% A file of Munsell specifications does not exist, so it must be created	
	% A set of CIE xyY coordinates has already been calculated for each reflectance spectrum.
	% Convert each set of xyY coordinates into Munsell specifications (Hue Value/Chroma)
	MunsellList = {}	;
	NumberOfColours = size(CIEcoords,1)	;
	for ctr = 1:NumberOfColours
	    [MunsellSpec MunsellVec Status] = xyYtoMunsell(C2xyY(ctr,1), C2xyY(ctr,2), C2xyY(ctr,3))	;
	    MunsellList{ctr} = MunsellSpec	;
		disp(['ctr: ', num2str(ctr),'  ',MunsellList{ctr}]); fflush(stdout);
		
		% If the spectrum could not be converted to Munsell, then save its index for future
		% manual conversion
		if Status.ind ~= 1
			NonConvertedCtrs = [NonConvertedCtrs, ctr]	;
		end
	end

	% Save the list of Munsell specifications in a text file for future reference, and to avoid
	% recomputing.  
	MunsellOutputFile = fopen(MunsellOutputFileName, 'w') 			;
	for ctr = 1:length(MunsellList)
		MunsellSpec = MunsellList{ctr} 		;
		if ctr == length(MunsellList)
			fprintf(MunsellOutputFile, '%s', MunsellSpec) 	;
		else
			fprintf(MunsellOutputFile, '%s\n', MunsellSpec) 	;
		end	
	end
	fclose(MunsellOutputFile)	;
end	
disp([num2str(length(MunsellList)),' Munsell specifications.'])
% Print out a list of unconverted spectra, if there are any, along with their xyY coordinates.
% These must be converted manually, instead.
if ~isempty(NonConvertedCtrs)
	disp(['The following reflectance spectra must be converted to Munsell specifications manually,'])
	disp(['using the given xyY coordinates:'])
	for ctr = NonConvertedCtrs
		% Display the Munsell value to make the manual conversion easier
		LuminanceFactor = C2xyY(ctr,3)									;
		MunsellValues = LuminanceFactorToMunsellValue(LuminanceFactor)	;
		MunsellValue  = MunsellValues.ASTMTableLookup					;
		if exist('FileOfNames') 
			disp(['Sample ',num2str(ctr),'. ', NameList{ctr},', xyY: ', ...
				num2str(C2xyY(ctr,1)),', ', num2str(C2xyY(ctr,2)),', ', num2str(C2xyY(ctr,3)), ...
				' (Munsell value: ',num2str(MunsellValue),')'])
		else
			disp(['Sample ',num2str(ctr),'. xyY: ', ...
				num2str(C2xyY(ctr,1)),', ', num2str(C2xyY(ctr,2)),', ', num2str(C2xyY(ctr,3)), ...
				' (Munsell value: ',num2str(MunsellValue),')'])			
		end
	end
end

% If colour names are available, then create an additional file, which gives the Munsell 
% specifications for each colour by name.
if exist('FileOfNames') 
	NameForMunsellOutputFile = [NameForOutput,'NamesAndMunsellSpecs','.txt'] 	;
	NameAndMunsellOutputFile = fopen(NameForMunsellOutputFile, 'w') 			;
	for ctr = 1:length(MunsellList)
		% Start a new line (if this is not the first line of the file)
		if ctr > 1
			fprintf(NameAndMunsellOutputFile, '\n') 	;
		end

		MunsellSpec = MunsellList{ctr} 	;
		% If desired, round off the entries in the Munsell file to 1 decimal place for 
		% each of hue, value, and chroma
		if false		
			ColorLabMunsellVector    = MunsellSpecToColorLabFormat(MunsellSpec);
			[MunsellSpec, HueString] = ColorLabFormatToMunsellSpec(ColorLabMunsellVector,...
                                                         1,...
														 1,...
														 1);
	 	end
		
		% Since a file of names has been input, the variable NameListNoCommas has already 
		% been created, containing the colour names.
		fprintf(NameAndMunsellOutputFile, '%s', NameListNoCommas{ctr}) 	;
		fprintf(NameAndMunsellOutputFile, ', %s', MunsellSpec) 	;
	end
	fclose(NameAndMunsellOutputFile)	;
end

% So far, we have printed out text files that contain different combinations of information.
% Now, we will analyze the set of colours to determine its distribution of hues, values, and
% chromas. Call the function MunsellAnalysisOfColourSet to perform the actual analysis.
if exist('FileOfNames') 
	% If a file of names has been input, then the variable NameList has already been
	% created, containing the colour names, in the format expected by MunsellAnalysisOfColourSet.
	% Now that the data is in the right format, perform the actual analysis.
	MunsellAnalysisOfColourSet(MunsellList, NameForOutput, NameList);
else 	% There is no file containing names, so the analysis function is called without
		% that input variable.
	MunsellAnalysisOfColourSet(MunsellList, NameForOutput);
end