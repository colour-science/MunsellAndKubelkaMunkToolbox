function [ISCCNBSlevel1,ISCCNBSlevel2,ISCCNBSlevel3] = ReadInISCCNBSdesignators();
% Purpose		Read in numbers, verbal colour descriptions (also called designators), and
%				abbreviations for the ISCC-NBS colour naming system.
%
% Description	In 1955, the Inter-Society Color Council (ISCC) and the US National Bureau of Standards 
% (NBS) (now called NIST) produced the ISCC-NBS colour naming system [Kelly1976].  This
% system expresses common verbal colour descriptions, such as "light purplish pink," in 
% terms of the Munsell system [Newhall1943].  Terms such as "light purplish pink" encompass
% a multitude of distinguishable colours.  In fact, any Munsell colour whose hue is between
% 9P and 9RP, whose value is greater than 7.5, and whose chroma is between 5 and 9, would
% be considered a light purplish pink.  
% 
% The ISCC-NBS system formalizes such relationships.  It gives colour names at three
% increasing levels of precision.  In Level 1, a colour is designated very broadly, using
% one of 13 common names (pink, red, orange, brown, yellow, olive, yellow green, green,
% blue, purple, white, gray, or black).  This description is commonly understood, but only
% approximate: there are many colours, for example, that would be called "red."  In Level 2,
% 16 intermediate colour names are added (yellowish pink, reddish orange, reddish brown,
% orange yellow, yellowish brown, olive brown, greenish yellow, yellow green, olive green,
% yellowish green, bluish green, greenish blue, purplish blue, reddish purple, purplish
% pink, and purplish red).  Combining the 16 intermediate terms with the 13 original terms
% from Level 1 gives a total of 29 Level 2 colour names.  Level 3 extends Level 2 by adding 
% modifiers such as light, deep, grayish, vivid, etc.  In all, Level 3 contains 267 colour
% names, and is the most detailed level of the ISCC-NBS system.  Each of the 267 colour
% names has been given a standard index; Table 10.1 of [Agoston1987] lists all 267 names,
% along with their indices.
% 
% The data for the ISCC-NBS colour naming system appear in the text file
% ISCCNBSDesignators.txt.  This routine reads the data from that file, and assembles it 
% into data structures.  Three data structures are output, one for each level.  The fields
% of each structure give an index for each colour name at that level and lower levels, the 
% designator (i.e. the colour name), and an abbreviation as specified by [Kelly1976].  
%
% References:
% [Kelly1976] Kenneth L. Kelly & Deane B. Judd, "Color: Universal Language and Dictionary 
% 		of Names," NBS Special Publication 440, 1976. Available online at
% 		http://nvlpubs.nist.gov/nistpubs/Legacy/SP/nbsspecialpublication440.pdf or
% 		https://ia801701.us.archive.org/9/items/coloruniversalla00kell/coloruniversalla00kell.pdf
% [Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%         Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%         Colors," Journal of the Optical Society of America, Vol. 33,
%         Issue 7, pp. 385-418, 1943.
% [Agoston1987] George A. Agoston, Color Theory and Its Application in Art and Design,
% 		Springer, 1987.        
%
% Author		Paul Centore (March 15, 2016)
%
% Copyright 2016 Paul Centore
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

% If the data has already been read in and saved, then just load it and return it
ISCCNBSfile = 'ISCCNBSdata.mat'	;
FullFileName = which(ISCCNBSfile)	;
if not(isempty(FullFileName))
	load(FullFileName)	;
	return				;
end

% Initialize output variables
ISCCNBSlevel1.Indices       = []	;
ISCCNBSlevel1.Designators   = {}	;
ISCCNBSlevel1.Abbreviations = {}	;
ISCCNBSlevel2.Level2Indices = []	;
ISCCNBSlevel2.Level1Indices = []	;
ISCCNBSlevel2.Designators   = {}	;
ISCCNBSlevel2.Abbreviations = {}	;
ISCCNBSlevel3.Indices       = []	;
ISCCNBSlevel3.Level3Indices = []	;
ISCCNBSlevel3.Level2Indices = []	;
ISCCNBSlevel3.Level1Indices = []	;
ISCCNBSlevel3.Designators   = {}	;
ISCCNBSlevel3.Abbreviations = {}	;

% Find the file which contains information about the designators and abbreviations for the
% ISCC-NBS colour naming system
FileName     = 'ISCCNBSDesignators.txt'	;
FullFileName = which(FileName)			;
if isempty(FullFileName)
	disp('Exiting routine ReadInISCCNBSdesignators: file with ISCC-NBS designators not found.')	;
end

% Open the file with the ISCC-NBS designator data. 
% Read through and ignore the description at the start of the file.
% The line 'DESCRIPTION ENDS HERE' has been added to the file, to
% indicate when the description ends.
fid  = fopen(FullFileName, 'r');
FileLine = fgetl(fid);
while strcmp(FileLine, 'DESCRIPTION ENDS HERE') == false
	FileLine = fgetl(fid);
end

% The remainder of the file consists of ISCC-NBS designator data for levels 1, 2, and 3, in
% three sections.  The end of the data for level x is the line 'LEVEL x DESCRIPTION ENDS HERE.'
% Assemble the data for level 1 first.
FileLine = fgetl(fid)	;	% Skip header line
FileLine = fgetl(fid)	;
while strcmp(FileLine, 'LEVEL 1 DESCRIPTION ENDS HERE') == false
	% Scan in formatted data from file line
	FileLine(FileLine == ' ') = '_'		;	% Avoid skipping over spaces when extracting data from strings
	[Level1Index, Designator, Abbreviation] = sscanf(FileLine, '%d\t%s\t%s', 'C')	;
	Designator(Designator == '_') = ' '	;	% Add spaces back into designator
	
	% Save scanned data in output variables
	TempVector            = ISCCNBSlevel1.Indices	;
	TempVector            = [TempVector Level1Index];
	ISCCNBSlevel1.Indices = TempVector				;
	
	TempStrings               = ISCCNBSlevel1.Designators	;
	TempStrings{end+1}        = Designator					;
	ISCCNBSlevel1.Designators = TempStrings					;
	
	TempStrings                 = ISCCNBSlevel1.Abbreviations	;
	TempStrings{end+1}          = Abbreviation					;
	ISCCNBSlevel1.Abbreviations = TempStrings					;
	
	% Read in the next line of the file
	FileLine = fgetl(fid)	;
end

% Now assemble the data for level 2
FileLine = fgetl(fid)	;	% Skip header line
FileLine = fgetl(fid)	;
while strcmp(FileLine, 'LEVEL 2 DESCRIPTION ENDS HERE') == false
	% Scan in formatted data from file line
	FileLine(FileLine == ' ') = '_'		;	% Avoid skipping over spaces when extracting data from strings
	[Level2Index, Level1Index, Designator, Abbreviation] = sscanf(FileLine, '%d\t%d\t%s\t%s', 'C')	;
	Designator(Designator == '_') = ' '	;	% Add spaces back into designator
	
	% Save scanned data in output variables
	TempVector                  = ISCCNBSlevel2.Level2Indices	;
	TempVector                  = [TempVector Level2Index]		;
	ISCCNBSlevel2.Level2Indices = TempVector					;
	
	TempVector                  = ISCCNBSlevel2.Level1Indices	;
	TempVector                  = [TempVector Level1Index]		;
	ISCCNBSlevel2.Level1Indices = TempVector					;
	
	TempStrings               = ISCCNBSlevel2.Designators	;
	TempStrings{end+1}        = Designator					;
	ISCCNBSlevel2.Designators = TempStrings					;
	
	TempStrings                 = ISCCNBSlevel2.Abbreviations	;
	TempStrings{end+1}          = Abbreviation					;
	ISCCNBSlevel2.Abbreviations = TempStrings					;
	
	% Read in the next line of the file
	FileLine = fgetl(fid)	;
end

% Finally, assemble the data for level 3
FileLine = fgetl(fid)	;	% Skip header line
FileLine = fgetl(fid)	;
while strcmp(FileLine, 'LEVEL 3 DESCRIPTION ENDS HERE') == false
	% Scan in formatted data from file line
	FileLine(FileLine == ' ') = '_'		;	% Avoid skipping over spaces when extracting data from strings
	[Level3Index, Level2Index, Level1Index, Designator, Abbreviation] = sscanf(FileLine, '%d\t%d\t%d\t%s\t%s', 'C')	;
	Designator(Designator == '_') = ' '	;	% Add spaces back into designator
	
	% Save scanned data in output variables
	TempVector                  = ISCCNBSlevel3.Level3Indices	;
	TempVector                  = [TempVector Level3Index]		;
	ISCCNBSlevel3.Level3Indices = TempVector					;
	
	TempVector                  = ISCCNBSlevel3.Level2Indices	;
	TempVector                  = [TempVector Level2Index]		;
	ISCCNBSlevel3.Level2Indices = TempVector					;
	
	TempVector                  = ISCCNBSlevel3.Level1Indices	;
	TempVector                  = [TempVector Level1Index]		;
	ISCCNBSlevel3.Level1Indices = TempVector					;
	
	TempStrings               = ISCCNBSlevel3.Designators	;
	TempStrings{end+1}        = Designator					;
	ISCCNBSlevel3.Designators = TempStrings					;
	
	TempStrings                 = ISCCNBSlevel3.Abbreviations	;
	TempStrings{end+1}          = Abbreviation					;
	ISCCNBSlevel3.Abbreviations = TempStrings					;
	
	% Read in the next line of the file
	FileLine = fgetl(fid)	;
end

% Close the data file
fclose(fid)	;

% Save the data to avoid reading it in again
save('ISCCNBSdata.mat')	;