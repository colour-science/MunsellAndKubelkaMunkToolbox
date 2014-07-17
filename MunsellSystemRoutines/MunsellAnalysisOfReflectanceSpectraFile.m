function MunsellAnalysisOfReflectanceSpectraFile(FileOfReflectanceSpectra, NameForOutput, FileOfNames);
% Purpose		Analyze a colour set, where colours are given by reflectance spectra that are
%				stored in a .csv file in X-Rite ColorMunki format.
%
% Description	This routine describes a set of colours in terms of the Munsell system.  It
%				was originally intended to describe a set of pastels.  Pastel sets are large,
%				typically containing hundreds of different colours.  An artist or designer
%				(or pastel manufacturer) needs some way to organize the set, or to see as a
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
% Author		Paul Centore (April 4, 2014)
%
% Copyright 2014 Paul Centore
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

% If Munsell specifications have already been calculated, then just read them in, rather
% than recalculating them (the conversion from CIE to Munsell can be slow).  If a file
% has already been created, it will have been given the following name:
MunsellOutputFileName = [NameForOutput,'MunsellSpecs','.txt'] 	;
if not(isempty(which(MunsellOutputFileName)))	% Such a file exists.
	% Read the Munsell list from this file.
	MunsellList = {}		;
	MunsellOutputFile = fopen(MunsellOutputFileName, 'r')	;
	while not(feof(MunsellOutputFile))
		MunsellList{end+1} = fgetl(MunsellOutputFile)	;
	end
	fclose(MunsellOutputFile)	;
	
else 		% A file of Munsell specifications does not exist, so it must be created	
	% Read in the reflectance spectra in the input file, and express them as a vector of 
	% wavelengths, and a matrix of reflectances
	[Wavelengths, Reflectances] = ColorMunkiCSVfileToOctaveFormat(FileOfReflectanceSpectra);

	% Convert the reflectance spectra into CIE coordinates (both XYZ and xyY).  Since the
	% Munsell system is standardized on Illuminant C and the CIE 1931 2 degree observer,
	% specify C/2 observing conditions.
	CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, Reflectances, 'C/2');

	% Convert each set of CIE coordinates into Munsell specifications (Hue Value/Chroma)
	MunsellList = {}	;
	NumberOfColours = size(CIEcoords,1)	;
	for ctr = 1:NumberOfColours
	   [MunsellSpec MunsellVec Status] = xyYtoMunsell(CIEcoords(ctr,4), CIEcoords(ctr,5), CIEcoords(ctr,6));
	   MunsellList{ctr} = MunsellSpec	;
		disp(['ctr: ', num2str(ctr),'  ',MunsellList{ctr}]); fflush(stdout);
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

% Read in the colour names from a file, if such a file has been input, and construct a
% list of those names.  If there is no such file, then do not construct a list.  Either
% way, call the function MunsellAnalysisOfColourSet to perform the actual analysis.
if exist('FileOfNames') 
	% Read in list of names from file
	NameList = {}		;
	NameFile = fopen(FileOfNames, 'r')	;
	while not(feof(NameFile))
		NameList{end+1} = fgetl(NameFile)	;
	end
	fclose(NameFile)	;

	% Now that the data is in the right format, use a previous function to perform the
	% actual analysis.
	MunsellAnalysisOfColourSet(MunsellList, NameForOutput, NameList);
else 	% There is no file containing names, so do not construct a list of names; instead
		% call the analysis function directly.
	MunsellAnalysisOfColourSet(MunsellList, NameForOutput);
end