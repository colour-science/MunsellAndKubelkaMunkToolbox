function [Designators, Abbreviations] = ISCCNBSnameFromNumber(Levels,Numbers);
%
% Purpose		Given a level and number (e.g. Level 3, Number 24) in the ISCC-NBS colour
%				naming system, find the corresponding name (in this case, "reddish black"). 
%
% Description	The ISCC-NBS colour naming system
%				[Kelly1976] is a standardized verbal description of object colours.  It was created
%				in 1955 by the Inter-Society Color Council (ISCC) and the US National Bureau of Standards 
%				(NBS) (now called NIST).  This
% 				system expresses common verbal colour descriptions, such as "light purplish pink," in 
% 				terms of the Munsell system [Newhall1943].  Terms such as "light purplish pink" encompass
% 				a multitude of distinguishable colours.  In fact, any Munsell colour whose hue is between
% 				9P and 9RP, whose value is greater than 7.5, and whose chroma is between 5 and 9, would
% 				be considered a light purplish pink.  
% 
% 				The ISCC-NBS system formalizes such relationships.  It gives colour names at three
% 				increasing levels of precision.  In Level 1, a colour is designated very broadly, using
% 				one of 13 common names (pink, red, orange, brown, yellow, olive, yellow green, green,
% 				blue, purple, white, gray, or black).  This description is commonly understood, but only
% 				approximate: many colours, for example, would be called "red."  In Level 2,
% 				16 intermediate colour names are added (yellowish pink, reddish orange, reddish brown,
% 				orange yellow, yellowish brown, olive brown, greenish yellow, yellow green, olive green,
% 				yellowish green, bluish green, greenish blue, purplish blue, reddish purple, purplish
% 				pink, and purplish red).  Combining the 16 intermediate terms with the 13 original terms
% 				from Level 1 gives a total of 29 Level 2 colour names.  Level 3 extends Level 2 by adding 
% 				modifiers such as light, deep, grayish, vivid, etc.  In all, Level 3 contains 267 colour
% 				names, and is the most detailed level of the ISCC-NBS system.  Each of the 267 colour
% 				names has been given a standard index; Table 10.1 of [Agoston1987] lists all 267 names,
% 				along with their indices.
%
%				This routine returns the ISCC-NBS colour name (and abbreviation) for the ISCC-NBS
%				colour that occurs at an input ISCC-NBS level (either 1, 2, or 3) and an input
%				index number at that level.
%
%				Levels			A vector (with possibly only one element) of ISCC-NBS levels
%
%				Numbers			A vector (with possibly only one element) of a colour s index
%								number, within a certain level, which is given by the corresponding
%								entry in the vector Levels
%
%				Designators		A list of strings such as "light purplish pink."  Each string gives
%								the ISCC-NBS verbal colour name for the input levels and indices
%
%				Abbreviations	A list of strings such as "l.pPk."  Each string gives the ISCC-NBS
%								abbreviation for the input levels and indices
%
% 				[Kelly1976] Kenneth L. Kelly & Deane B. Judd, Color: Universal Language and Dictionary 
% 						of Names, NBS Special Publication 440, 1976. Available online at
% 						http://nvlpubs.nist.gov/nistpubs/Legacy/SP/nbsspecialpublication440.pdf or
% 						https://ia801701.us.archive.org/9/items/coloruniversalla00kell/coloruniversalla00kell.pdf
% 				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, Final
% 				        Report of the O.S.A. Subcommittee on the Spacing of the Munsell
% 				        Colors, Journal of the Optical Society of America, Vol. 33,
% 				        Issue 7, pp. 385-418, 1943.
% 				[Agoston1987] George A. Agoston, Color Theory and Its Application in Art and Design,
% 						Springer, 1987.        
%
% Author		Paul Centore (April 6, 2016)
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

% Initialize output variables
Designators   = {}	;
Abbreviations = {}	;

% Read in ISCC-NBS data (unless it has already been read in once and saved in static memory)
persistent ISCCNBSlevel1		% Save in static memory, after reading in
persistent ISCCNBSlevel2
persistent ISCCNBSlevel3
% If the above data structure is not already in static memory, then read it in
if isempty(ISCCNBSlevel3)	
	[ISCCNBSlevel1, ISCCNBSlevel2, ISCCNBSlevel3] = ReadInISCCNBSdesignators();
end
Level1Designators   = ISCCNBSlevel1.Designators		;
Level1Abbreviations = ISCCNBSlevel1.Abbreviations	;
Level2Designators   = ISCCNBSlevel2.Designators		;
Level2Abbreviations = ISCCNBSlevel2.Abbreviations	;
Level3Designators   = ISCCNBSlevel3.Designators		;
Level3Abbreviations = ISCCNBSlevel3.Abbreviations	;

% Determine the number of inputs
NumberOfInputs = length(Levels)	;

% Find the ISCC-NBS name for each input
for ctr = 1:NumberOfInputs		

	% Extract the level and number for a particular input
	Level  = Levels(ctr)	;
	Number = Numbers(ctr)	;
	
	if Level == 1
		Designators{ctr}   = Level1Designators{Number}		;
		Abbreviations{ctr} = Level1Abbreviations{Number}	;
	elseif Level == 2
		Designators{ctr}   = Level2Designators{Number}		;
		Abbreviations{ctr} = Level2Abbreviations{Number}	;
	elseif Level == 3
		Designators{ctr}   = Level3Designators{Number}		;
		Abbreviations{ctr} = Level3Abbreviations{Number}	;
	else
	    disp(['Error in ISCCNBSnameFromNumber: Level is not 1, 2, or 3'])
	end
end