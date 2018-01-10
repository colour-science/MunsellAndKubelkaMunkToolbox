function [	MunsellSpecs, ...
			HueStrings,...
			MunsellValues,...
			MunsellChromas,...
			ASTMHues,...
			ISCCNBSdesignators,...
			ISCCNBSlevels,...
			sRGBs] = ...
			DescriptiveFileForReflectanceSpectra(...
			  	Wavelengths,...
			  	ReflectanceSpectra,...
			  	SpectraNames,...
			  	OutputFile);
%			  	
% Purpose		Convert a set of reflectance spectra into perceptual terms, such as Munsell 
%				specifications, ISCC-NBS names, and sRGBs.  Write out the results to a
%				text file for easy reference.  
%
% Description	The reflectance spectrum of a surface colour gives the percentage of
%				light reflected by that surface colour, at each wavelength.  In this
%				routine, the input variable Wavelengths gives a set of wavelengths
%				(in nm), and the input variable ReflectanceSpectra gives the percentage
%				of light reflected, for each wavelength.  ReflectanceSpectra can actually
%				be a matrix, each row of which gives a reflectance spectrum for a different
%				surface colour.
%
%				While reflectance spectra provide data about the physical source of colour,
%				perceptual terms, that describe how humans see those colours, are also
%				useful.  This routine expresses reflectance spectra in perceptual terms,
%				that are more easily understood by humans.  In particular, each object has
%				a Munsell specification that depends only on its reflectance spectrum.  
%				Another system, the ISCC-NBS colour-naming system, assigns names in
%				common words such as "dark purplish red" to an object s colour, and also
%				assigns a category to a colour at each of three levels, where the levels
%				become progressively finer.  
%
%				The sRGB system gives a set of red-green-blue coordinates that can be used
%				to produce a colour on a computer monitor.  The sRGB system has been
%				standardized, and assumes that the object is viewed under Illuminant D65.
%				An sRGB can be calculated from a reflectance spectrum, so that that
%				colour (or at least a good approximation to it) can be displayed on a
%				computer.  (The sRGB system also makes some assumptions about the ambient
%				lighting, that are not often satisfied in practice; even without exact
%				compliance, however, the system is still helpful.)
%
%				For easy reference, these data are written out to a text file, that a user
%				can understand.  As currently implemented, the text file assumes that the
%				input wavelengths go from 380 to 730 nm, in 10 nm increments.  This format
%				was chosen because it is commonly used.  Other sets of wavelengths would
%				require modifying the function to produce a text file, although the
%				calculated values allow different sets of wavelengths.
%				
%				Wavelengths			A row vector whose entries are the wavelengths for the reflectance  
%									spectra.  The wavelengths must be evenly spaced
%
%				ReflectanceSpectra	A matrix, whose rows are the reflectances (expressed as values 
%									between 0 and 1) for various reflectance spectra at the wavelengths
%									listed in the first input
%
%				SpectraNames		A set of names for the spectra, in the same order; this
%									variable is a cell structure
%
%				OutputFile			The name of the text file for the output data
%
%				MunsellSpecs		A cell structure giving the Munsell specification, as a
%									string, for each input reflectance spectrum
%
%				HueStrings			A cell structure giving the hue part (e.g. 8.3PB) of each
%									Munsell specification
%
%				MunsellValues, MunsellChromas	Vectors with values and chromas for each
%									Munsell specification
%
%				ASTMHues			The hue for each Munsell specification, as a number between
%									0 and 100
%
%				ISCCNBSdesignators	A cell structure with a string, such as "reddish black,"
%									for each input spectrum
%			
%				ISCCNBSlevels		A three-column matrix.  The first column gives the Level 3
%									category for the ISCC-NBS system, the second column gives
%									the Level 2 category, and the third column gives the 
%									Level 1 category
%
%				sRGBs				A three-column matrix, each of whose rows gives the sRGB
%									specification for an input reflectance spectrum
%
% Author		Paul Centore (February 12, 2017)
%
% Copyright 2017 Paul Centore
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

% Find the sRGBs for the input reflectance spectra
[sRGBs, OutOfGamutFlag] = ReflectanceSpectrumTosRGB(Wavelengths, ReflectanceSpectra)		;

% Find the Munsell specifications for the input reflectance spectra.  If the conversion
% routine fails to find a Munsell specification for a particular spectrum, then the
% string 'NA' or 'ERROR' is returned
[MunsellSpecs, ~, ~] = ReflectanceSpectrumToMunsellAndCIE(Wavelengths, ReflectanceSpectra)	;

% Break the Munsell specifications into individual pieces
HueStrings                      = HueStringFromMunsellSpec(MunsellSpecs, 2)					;
ASTMHues                        = ASTMHuesOfMunsellSpecifications(MunsellSpecs)				;
[MunsellValues, MunsellChromas] = ValuesAndChromasOfMunsellSpecifications(MunsellSpecs)		;

% If SpectraNames have already been input, then use them.  If not, then assign numbers
% as names.  To avoid changing an input variable, make a new variable called InternalSpectraNames
InternalSpectraNames = {}	;
NumberOfColours = size(ReflectanceSpectra,1)	;
if isempty(SpectraNames)
	for ctr = 1:NumberOfColours
		InternalSpectraNames{ctr} = num2str(ctr)	;
	end
else
	InternalSpectraNames = SpectraNames	;
end

% Initialize the matrix of ISCC-NBS levels and the cell structure of ISCC-NBS designators
ISCCNBSlevels = []	;
ISCCNBSdesignators   = {}	;

% Convert each Munsell specification to an ISCC-NBS name, and assign it to a Level 3
% category, a Level 2 category, and a Level 1 category.  If there is no Munsell specification
% for a particular spectrum, then return NA for the ISCC-NBS name, and NaN for each
% category
for ctr = 1:NumberOfColours
	MunsellSpec = toupper(MunsellSpecs{ctr})	;
	% Check whether the Munsell specification is defined
	if ~strcmp(MunsellSpec,'NA') && ~strcmp(MunsellSpec,'ERROR') 
		[Level3Index, Level2Index, Level1Index, Designator, Abbreviation] = ...
				MunsellToISCCNBS(MunsellSpec)	;
		ISCCNBSlevels = [ISCCNBSlevels; Level3Index, Level2Index, Level1Index]	;
		ISCCNBSdesignators{end+1}   = Designator{1}			;
	else
		ISCCNBSlevels = [ISCCNBSlevels; NaN, NaN, NaN]	;
		ISCCNBSdesignators{end+1}   = 'NA'				;
	end
end
%ISCCNBSlevels = [Level3Indices, Level2Indices, Level1Indices]	;

% Write out the results to a text file, whose name has been input.  If the input name is
% empty, then do not write out anything
if ~isempty(OutputFile)
	fid = fopen(OutputFile,'w')	;
	% Write out header line
	fprintf(fid,['%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s',...
				'\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s',...
				'\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s',...
				'\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n'],...
	 'Name',...
	 'Munsell', 'Hue', 'Value', 'Chroma', 'ASTM Hue',...
		'ISCC-NBS','L3' ,'L2', 'L1',...
		'sR', 'sG', 'sB',...
		'380nm','390nm','400nm','410nm','420nm','430nm',...
		'440nm','450nm','460nm','470nm','480nm','490nm',...
		'500nm','510nm','520nm','530nm','540nm','550nm',...
		'560nm','570nm','580nm','590nm','600nm','610nm',...
		'620nm','630nm','640nm','650nm','660nm','670nm',...
		'680nm','690nm','700nm','710nm','720nm','730nm')	;
	% Output a line for each reflectance spectrum
	for ctr = 1:NumberOfColours
		% Extract individual strings or values for each entry in the text file
		MunsellSpec  = MunsellSpecs{ctr}			;
		Designator   = ISCCNBSdesignators{ctr}		;
		SpectrumName = InternalSpectraNames{ctr}	;
		% If there is only one spectrum, then HueString is a single string; otherwise it
		% is a cell structure
		if NumberOfColours > 1
			HueString = HueStrings{ctr}	;
		else
			HueString = HueStrings		;
		end
		% A particular spectrum might be outside the sRGB gamut, which is signified by
		% an out-of-gamut flag that the sRGB conversion routine returned.  When a
		% spectrum is out of gamut, set the sRGB entries in the file to NaN
		sR = []	;
		sG = []	;
		sB = []	;
		if OutOfGamutFlag(ctr) == 1
			sR = NaN	;
			sG = NaN	;
			sB = NaN	;
		else
			sR = sRGBs(ctr,1)	;
			sG = sRGBs(ctr,2)	;
			sB = sRGBs(ctr,3)	;
		end
		
		% Write all the data, including the original reflectances, for one spectrum as
		% a long line in the text file
		fprintf(fid,'%s\t%s\t%s\t%f\t%f\t%f\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', 
			SpectrumName, ...
			MunsellSpec, HueString, MunsellValues(ctr), MunsellChromas(ctr),...
			ASTMHues(ctr),...
			Designator,ISCCNBSlevels(ctr,1),ISCCNBSlevels(ctr,2),ISCCNBSlevels(ctr,3),...
			sR, sG, sB,...
			ReflectanceSpectra(ctr,1), ReflectanceSpectra(ctr,2), ReflectanceSpectra(ctr,3), ReflectanceSpectra(ctr,4), ReflectanceSpectra(ctr,5), ReflectanceSpectra(ctr,6),...
			ReflectanceSpectra(ctr,7), ReflectanceSpectra(ctr,8), ReflectanceSpectra(ctr,9), ReflectanceSpectra(ctr,10), ReflectanceSpectra(ctr,11), ReflectanceSpectra(ctr,12),...
			ReflectanceSpectra(ctr,13), ReflectanceSpectra(ctr,14), ReflectanceSpectra(ctr,15), ReflectanceSpectra(ctr,16), ReflectanceSpectra(ctr,17), ReflectanceSpectra(ctr,18),...
			ReflectanceSpectra(ctr,19), ReflectanceSpectra(ctr,20), ReflectanceSpectra(ctr,21), ReflectanceSpectra(ctr,22), ReflectanceSpectra(ctr,23), ReflectanceSpectra(ctr,24),...
			ReflectanceSpectra(ctr,25), ReflectanceSpectra(ctr,26), ReflectanceSpectra(ctr,27), ReflectanceSpectra(ctr,28), ReflectanceSpectra(ctr,29), ReflectanceSpectra(ctr,30),...
			ReflectanceSpectra(ctr,31), ReflectanceSpectra(ctr,32), ReflectanceSpectra(ctr,33), ReflectanceSpectra(ctr,34), ReflectanceSpectra(ctr,35), ReflectanceSpectra(ctr,36))	;
	end
	fclose(fid);
end
