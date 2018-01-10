function [Level3Indices, Level2Indices, Level1Indices, Designators, Abbreviations] = ...
			MunsellToISCCNBS(MunsellSpecifications);
%
% Purpose		For an input Munsell specification (such as 5RP 8/6), find the verbal 
%				description given by the ISCC-NBS colour naming system (in this case, light
%				purplish pink).
%
% Description	The Munsell system [Newhall1943] specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form H V/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose upper bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R 9.0/4.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				Routines in ColorLab use the Munsell specifications, but not necessarily the
%				Munsell notation HV/C.  A Munsell vector is given by [H1, V, C, H2], where 
%				H1 is the number designator for hue, H2 is the position of the hue letter 
%				designator in the list
%				                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
%				V is the Munsell value, and C is the Munsell chroma. For example, 
%				5.0R 9.0/4.0 is [5 9 4 7] in ColorLab
%				format.  A neutral Munsell grey is a one-element vector in ColorLab
%				format, consisting of the grey value.  For example, N4 is [4] in ColorLab
%				format; alternately, a grey could have its third entry be 0, in which case
%				the first and fourth entries are ignored; this form insures that all vectors
%				have four entries, so that they can be stacked in a matrix.
%
%				In 1955, the Inter-Society Color Council (ISCC) and the US National Bureau of Standards 
%				(NBS) (now called NIST) produced the ISCC-NBS colour naming system [Kelly1976].  This
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
% 				Thirty-one graphical charts on pp. 16 through 31 of [Kelly1976] give visual
%				instructions for converting a Munsell specification to a Level 3 ISCC-NBS description.
%				Each chart represents a small sector of contiguous hue leaves, which has been
%				subdivided into (usually) rectangles corresponding to ISCC-NBS descriptions.  
%
%				This routine implements those thirty-one charts in computer code.  The input to
%				the routine is one or more Munsell specifications, given either as a list, indicated
%				by {}, of strings, or as a four-column matrix, each row of which is a Munsell
%				specification in ColorLab format.  For each input Munsell specification, the 
%				routine finds the corresponding ISCC-NBS index, at Levels 1, 2, and 3.  In addition,
%				a verbal designator such as "light purplish pink" is found, as well as a standardized
%				abbreviation ("l.pPk" in this case).  The routine returns this information.
%
%				MunsellSpecifications	Either a list of Munsell specifications, such as 4.2R 8.1/5.3,
%								or a matrix, each row of which is a Munsell vector in ColorLab 
%								format.  A list of strings should be indicated by {}.  The entry
%								might also be a single string, which will be converted to a
%								one-element list
%
%				Level1Indices, Level2Indices, Level3Indices		Vectors giving the ISCC-NBS indices
%								for Levels 1, 2, and 3, for the input Munsell specification(s)
%
%				Designators		A list of strings such as "light purplish pink."  Each string gives
%								the ISCC-NBS verbal colour name for an input Munsell specification
%
%				Abbreviations	A list of strings such as "l.pPk."  Each string gives the ISCC-NBS
%								abbreviation for an input Munsell specification
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

% Initialize output variables
Level3Indices = []	;
Level2Indices = []	;
Level1Indices = []	;
Designators   = {}	;
Abbreviations = {}	;

% Determine the number of input Munsell specifications
if iscell(MunsellSpecifications)	% The specifications are a list, denoted by {}, of character strings
	NumberOfSpecs   = length(MunsellSpecifications)	;
else	% The specifications are a four-column matrix of row vectors
	NumberOfSpecs   = size(MunsellSpecifications,1) ;
end

% Check that at least one Munsell specification has been input
if NumberOfSpecs == 0
	disp(['Empty input to routine MunsellToISCCNBS: exiting routine'])	;
	return
end

% Read in ISCC-NBS data (unless it has already been read in once and saved in static memory)
persistent ISCCNBSlevel3		% Save in static memory, after reading in
% If the above data structure is not already in static memory, then read it in
if isempty(ISCCNBSlevel3)	
	[~,~,ISCCNBSlevel3] = ReadInISCCNBSdesignators();
end
AllLevel2Indices = ISCCNBSlevel3.Level2Indices	;
AllLevel1Indices = ISCCNBSlevel3.Level1Indices	;
AllDesignators   = ISCCNBSlevel3.Designators	;
AllAbbreviations = ISCCNBSlevel3.Abbreviations	;

% Extract the hues, values, and chromas of the input Munsell specifications
ASTMHues                        = ASTMHuesOfMunsellSpecifications(MunsellSpecifications)		;	
%disp(['ASTM hues calculated in routine MunsellToISCCNBS'])
fflush(stdout);
[MunsellValues, MunsellChromas] = ValuesAndChromasOfMunsellSpecifications(MunsellSpecifications)	;
%disp(['Values and chromas calculated in routine MunsellToISCCNBS'])
fflush(stdout);

% Go through the input Munsell specifications one by one, assigning the ISCC-NBS values for each
for ctr = 1:NumberOfSpecs
	% Print out indications of progress, for large input sets
	if mod(ctr,1000) == 0
		disp([num2str(ctr),' out of ', num2str(NumberOfSpecs)]);
		fflush(stdout);
	end

	% Extract the Munsell hue (in ASTM form), value, and chroma
	Hue    = ASTMHues(ctr)			;
	Value  = MunsellValues(ctr)		;
	Chroma = MunsellChromas(ctr)	;
	
	% Find the Munsell specification as a string, in case it needs to be displayed later
	% in an informational message
	MunsellSpecString = ValueChromaAndASTMHueToMunsellSpec(Value,Chroma,Hue);
	
	% Use the charts in p. 16 to 31 of [Kelly1976] to find the Level 3 ISCC-NBS designator
	% for the current Munsell specification
	Level3Index = NaN	;
	
	% Handle the greys first, because they have no hues attached
	if Chroma <= 0.5
		if Value >= 8.5
			Level3Index = 263	;
		elseif Value >= 6.5
			Level3Index = 264	;
		elseif Value >= 4.5
			Level3Index = 265	;
		elseif Value >= 2.5
			Level3Index = 266	;
		else
			Level3Index = 267	;
		end
		
	else	% The input colour is not a grey.
	
		if Hue >= 1 && Hue < 4		%	Munsell hue range 1R-4R, p. 16 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 22	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 23	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 2 && Value < 3.5
				Level3Index = 20	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 24	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 21	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 7		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 8		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 8
				Level3Index = 4		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 6.5 
				Level3Index = 5		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 6.5 
				Level3Index = 2		;
			elseif Chroma > 11 && Value >= 6.5 
				Level3Index = 1		;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 5.5 && Value < 6.5
				Level3Index = 18	;
			elseif Chroma > 5 && Chroma <= 7 && Value >= 5.5 && Value < 6.5
				Level3Index = 6		;
			elseif Chroma > 7 && Chroma <= 15 && Value >= 5.5 && Value < 6.5
				Level3Index = 3		;
			elseif Chroma > 1.5 && Chroma <= 7 && Value >= 3.5 && Value < 5.5
				Level3Index = 19	;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5 && Value < 5.5
				Level3Index = 15	;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 3.5 && Value < 5.5
				Level3Index = 12	;
			elseif Chroma >= 3 && Chroma <= 9 && Value >= 2 && Value < 3.5
				Level3Index = 16	;
			elseif Chroma > 9 && Chroma <= 11 && Value >= 2 && Value < 3.5
				Level3Index = 13	;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2 
				Level3Index = 17	;
			elseif Chroma > 7 && Chroma <= 11 && Value < 2 
				Level3Index = 14	;
			elseif Chroma > 11 && Value < 6.5 
				Level3Index = 11	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 1 and 4)'])
			end
			
		elseif Hue >= 4 && Hue < 6		%	Munsell hue range 4R-6R, p. 16 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 22	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 23	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 2 && Value < 3.5
				Level3Index = 20	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 24	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 21	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 7		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 8		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 8
				Level3Index = 4		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 6.5 
				Level3Index = 5		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 6.5 
				Level3Index = 26		;
			elseif Chroma > 11 && Value >= 6.5 
				Level3Index = 25		;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 5.5 && Value < 6.5
				Level3Index = 18	;
			elseif Chroma > 5 && Chroma <= 7 && Value >= 5.5 && Value < 6.5
				Level3Index = 6		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 5.5 && Value < 6.5
				Level3Index = 3		;
			elseif Chroma > 11 && Chroma <= 15 && Value >= 5.5 && Value < 6.5
				Level3Index = 27		;
			elseif Chroma > 1.5 && Chroma <= 7 && Value >= 3.5 && Value < 5.5
				Level3Index = 19	;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5 && Value < 5.5
				Level3Index = 15	;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 3.5 && Value < 5.5
				Level3Index = 12	;
			elseif Chroma >= 3 && Chroma <= 9 && Value >= 2 && Value < 3.5
				Level3Index = 16	;
			elseif Chroma > 9 && Chroma <= 11 && Value >= 2 && Value < 3.5
				Level3Index = 13	;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2 
				Level3Index = 17	;
			elseif Chroma > 7 && Chroma <= 11 && Value < 2 
				Level3Index = 14	;
			elseif Chroma > 11 && Value < 6.5 
				Level3Index = 11	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 4 and 6)'])
			end
			
		elseif Hue >= 6 && Hue < 7		%	Munsell hue range 6R-7R, p. 17 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 22	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 23	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 47	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3.5
				Level3Index = 46	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 24	;
			elseif Chroma > 1 && Chroma <= 5 && Value < 2.5
				Level3Index = 44	;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 2.5 && Value < 3.5
				Level3Index = 43		;
			elseif Chroma > 5 && Chroma <= 7 && Value < 2.5
				Level3Index = 41	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 31		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 32		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 8
				Level3Index = 28		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 6.5 
				Level3Index = 29		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 6.5 
				Level3Index = 26		;
			elseif Chroma > 11 && Value >= 6.5 
				Level3Index = 25		;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 5.5 && Value < 6.5
				Level3Index = 18	;
			elseif Chroma > 5 && Chroma <= 7 && Value >= 5.5 && Value < 6.5
				Level3Index = 30		;
			elseif Chroma > 7 && Chroma <= 15 && Value >= 5.5 && Value < 6.5
				Level3Index = 27		;
			elseif Chroma > 1.5 && Chroma <= 7 && Value >= 3.5 && Value < 5.5
				Level3Index = 19	;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5 && Value < 5.5
				Level3Index = 15	;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 3.5 && Value < 5.5
				Level3Index = 12	;
			elseif Chroma >= 7 && Chroma <= 9 && Value >= 2 && Value < 3.5
				Level3Index = 16	;
			elseif Chroma > 9 && Chroma <= 11 && Value >= 2 && Value < 3.5
				Level3Index = 13	;
			elseif Chroma > 7 && Chroma <= 11 && Value < 2 
				Level3Index = 14	;
			elseif Chroma > 11 && Value < 6.5 
				Level3Index = 11	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 6 and 7)'])
			end
			
		elseif Hue >= 7 && Hue < 8		%	Munsell hue range 7R-8R, p. 17 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 22	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 23	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 47	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value <= 3.5
				Level3Index = 46	;
			elseif Chroma > 1.5 && Chroma <= 7 && Value >= 3.5 && Value <= 5.5
				Level3Index = 19	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 24	;
			elseif Chroma > 1 && Chroma <= 5 && Value < 2.5
				Level3Index = 44	;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 2.5 && Value < 3.5
				Level3Index = 43		;
			elseif Chroma > 5 && Chroma <= 7 && Value < 2.5
				Level3Index = 41	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 31		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 32		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 8
				Level3Index = 28		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 6.5 
				Level3Index = 29		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 6.5 
				Level3Index = 26		;
			elseif Chroma > 11 && Value >= 6.5 
				Level3Index = 25		;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 5.5 && Value < 6.5
				Level3Index = 18	;
			elseif Chroma > 5 && Chroma <= 7 && Value >= 5.5 && Value < 6.5
				Level3Index = 30		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 4.5 && Value < 6.5
				Level3Index = 37		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5 && Value < 4.5
				Level3Index = 38		;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 4.5 && Value < 6.5
				Level3Index = 35		;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 3.5 && Value < 4.5
				Level3Index = 36		;
			elseif Chroma > 13 && Value >= 4.5 && Value < 6.5
				Level3Index = 34		;
			elseif Chroma >= 7 && Chroma <= 9 && Value >= 2 && Value < 3.5
				Level3Index = 16	;
			elseif Chroma > 9 && Chroma <= 11 && Value >= 2 && Value < 3.5
				Level3Index = 13	;
			elseif Chroma > 7 && Chroma <= 11 && Value < 2 
				Level3Index = 14	;
			elseif Chroma > 11 && Value < 4.5 
				Level3Index = 11	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 7 and 8)'])
			end
			
		elseif Hue >= 8 && Hue < 9		%	Munsell hue range 8R-9R, p. 18 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 22	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 23	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 47	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 46	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 24	;
			elseif Chroma > 1 && Chroma <= 5 && Value < 2.5
				Level3Index = 44	;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 2.5 && Value < 4.5
				Level3Index = 43		;
			elseif Chroma > 5 && Chroma <= 7 && Value < 2.5
				Level3Index = 41	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 31		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 32		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 8
				Level3Index = 28		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 6.5 
				Level3Index = 29		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 6.5 
				Level3Index = 26		;
			elseif Chroma > 11 && Value >= 6.5 
				Level3Index = 25		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5 && Value < 6.5
				Level3Index = 18	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 4.5 && Value < 5.5
				Level3Index = 19	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 4.5 && Value < 6.5
				Level3Index = 42	;					
			elseif Chroma > 5 && Chroma <= 7 && Value >= 4.5 && Value < 6.5
				Level3Index = 39	;					
			elseif Chroma > 7 && Chroma <= 11 && Value >= 4.5 && Value < 6.5
				Level3Index = 37		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5 && Value < 4.5
				Level3Index = 38		;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 4.5 && Value < 6.5
				Level3Index = 35		;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 3.5 && Value < 4.5
				Level3Index = 36		;
			elseif Chroma > 13 && Value >= 4.5 && Value < 6.5
				Level3Index = 34		;
			elseif Chroma >= 7 && Chroma <= 9 && Value >= 2 && Value < 3.5
				Level3Index = 16	;
			elseif Chroma > 9 && Chroma <= 11 && Value >= 2 && Value < 3.5
				Level3Index = 13	;
			elseif Chroma > 7 && Chroma <= 11 && Value < 2 
				Level3Index = 14	;
			elseif Chroma > 11 && Value < 4.5 
				Level3Index = 11	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 8 and 9)'])
			end
			
		elseif Hue >= 9 && Hue < 11		%	Munsell hue range 9R-1YR, p. 18 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 22	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 23	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 47	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 46	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 24	;
			elseif Chroma > 1 && Chroma <= 5 && Value < 2.5
				Level3Index = 44	;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 2.5 && Value < 4.5
				Level3Index = 43		;
			elseif Chroma > 5 && Value < 2.5
				Level3Index = 41	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 31		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 32		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 8
				Level3Index = 28		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 6.5 
				Level3Index = 29		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 6.5 
				Level3Index = 26		;
			elseif Chroma > 11 && Value >= 6.5 
				Level3Index = 25		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5 && Value < 6.5
				Level3Index = 18	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 4.5 && Value < 5.5
				Level3Index = 19	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 4.5 && Value < 6.5
				Level3Index = 42	;					
			elseif Chroma > 5 && Chroma <= 7 && Value >= 4.5 && Value < 6.5
				Level3Index = 39	;					
			elseif Chroma > 7 && Chroma <= 11 && Value >= 4.5 && Value < 6.5
				Level3Index = 37		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5 && Value < 4.5
				Level3Index = 38		;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 4.5 && Value < 6.5
				Level3Index = 35		;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 3.5 && Value < 4.5
				Level3Index = 36		;
			elseif Chroma > 13 && Value >= 3.5 && Value < 6.5
				Level3Index = 34		;
			elseif Chroma >= 7 && Value >= 2.5 && Value < 3.5
				Level3Index = 40	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 9 and 11)'])
			end
			
		elseif Hue >= 11 && Hue < 12		%	Munsell hue range 1YR-2YR, p. 19 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 22	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 64	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 47	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 46	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 65	;
			elseif Chroma > 1 && Chroma <= 5 && Value < 2.5
				Level3Index = 44	;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 2.5 && Value < 4.5
				Level3Index = 43		;
			elseif Chroma > 5 && Value < 2.5
				Level3Index = 41	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 31		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 32		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 8
				Level3Index = 28		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 6.5 
				Level3Index = 29		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 6.5 
				Level3Index = 26		;
			elseif Chroma > 11 && Value >= 6.5 
				Level3Index = 25		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 45	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 4.5 && Value < 6.5
				Level3Index = 42	;					
			elseif Chroma > 5 && Chroma <= 7 && Value >= 4.5 && Value < 6.5
				Level3Index = 39	;					
			elseif Chroma > 7 && Chroma <= 11 && Value >= 4.5 && Value < 6.5
				Level3Index = 37		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5 && Value < 4.5
				Level3Index = 38		;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 4.5 && Value < 6.5
				Level3Index = 35		;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 3.5 && Value < 4.5
				Level3Index = 36		;
			elseif Chroma > 13 && Value >= 3.5 && Value < 6.5
				Level3Index = 34		;
			elseif Chroma >= 7 && Value >= 2.5 && Value < 3.5
				Level3Index = 40	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 11 and 12)'])
			end
			
		elseif Hue >= 12 && Hue < 13		%	Munsell hue range 2YR-3YR, p. 19 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 63	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 64	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 47	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 46	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 65	;
			elseif Chroma > 1 && Chroma <= 5 && Value < 2.5
				Level3Index = 44	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 2.5 && Value < 4.5
				Level3Index = 43		;
			elseif Chroma > 5 && Value < 2.5
				Level3Index = 56	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 31		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 32		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 45	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 46	;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 8
				Level3Index = 28		;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 6.5 
				Level3Index = 29		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 7.5 
				Level3Index = 52		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 4.5 && Value < 6.5
				Level3Index = 42		;				
			elseif Chroma > 5 && Chroma <= 7 && Value >= 4.5 && Value < 6.5
				Level3Index = 39		;				
			elseif Chroma > 6 && Chroma <= 10 && Value >= 5.5 
				Level3Index = 53		;
			elseif Chroma > 7 && Chroma <= 10 && Value >= 4.5 
				Level3Index = 54		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 7.5 
				Level3Index = 49		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 5.5 
				Level3Index = 50		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 4.5 
				Level3Index = 51		;
			elseif Chroma > 14 && Value >= 4.5
				Level3Index = 48		;
			elseif Chroma > 5 && Value >= 2.5 && Value < 4.5
				Level3Index = 55		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 12 and 13)'])
			end
			
		elseif Hue >= 13 && Hue < 15		%	Munsell hue range 3YR-5YR, p. 20 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 63	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 64	;
			elseif Chroma > 1.5 && Chroma <= 2.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 61	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 65	;
			elseif Chroma > 0.5 && Chroma <= 2.5 && Value >= 1.5 && Value < 2.5
				Level3Index = 62	;
			elseif Chroma > 1 && Chroma <= 5 && Value < 2.5
				Level3Index = 59	;
			elseif Chroma > 2.5 && Chroma <= 5 && Value >= 2.5 && Value < 4.5
				Level3Index = 58		;
			elseif Chroma > 5 && Value < 2.5
				Level3Index = 56	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 31		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 32		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 45	;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 8
				Level3Index = 28		;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 6.5 
				Level3Index = 29		;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 4.5 && Value < 6.5
				Level3Index = 57		;				
			elseif Chroma > 6 && Chroma <= 10 && Value >= 7.5 
				Level3Index = 52		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 5.5 
				Level3Index = 53		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 4.5 
				Level3Index = 54		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 7.5 
				Level3Index = 49		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 5.5 
				Level3Index = 50		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 4.5 
				Level3Index = 51		;
			elseif Chroma > 14 && Value >= 4.5
				Level3Index = 48		;
			elseif Chroma > 5 && Value >= 2.5 && Value < 4.5
				Level3Index = 55		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 13 and 15)'])
			end
			
		elseif Hue >= 15 && Hue < 17		%	Munsell hue range 5YR-7YR, p. 20 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.2 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 4.5
				Level3Index = 63	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5
				Level3Index = 64	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 61	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 65	;
			elseif Chroma > 0.5 && Chroma <= 2.5 && Value >= 1.5 && Value < 2.5
				Level3Index = 62	;
			elseif Chroma > 1 && Chroma <= 5 && Value < 2.5
				Level3Index = 59	;
			elseif Chroma > 2.5 && Chroma <= 5 && Value >= 2.5 && Value < 4.5
				Level3Index = 58		;
			elseif Chroma > 5 && Value < 2.5
				Level3Index = 56	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 8
				Level3Index = 31		;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 6.5
				Level3Index = 33		;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 60	;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 8
				Level3Index = 28		;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 6.5 
				Level3Index = 29		;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 4.5 && Value < 6.5
				Level3Index = 57		;				
			elseif Chroma > 6 && Chroma <= 10 && Value >= 7.5 
				Level3Index = 52		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 5.5 
				Level3Index = 53		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 4.5 
				Level3Index = 54		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 7.5 
				Level3Index = 49		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 5.5 
				Level3Index = 50		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 4.5 
				Level3Index = 51		;
			elseif Chroma > 14 && Value >= 4.5
				Level3Index = 48		;
			elseif Chroma > 5 && Value >= 2.5 && Value < 4.5
				Level3Index = 55		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 15 and 17)'])
			end
			
		elseif Hue >= 17 && Hue < 18		%	Munsell hue range 7YR-8YR, p. 21 of [Kelly1976]
			if Chroma > 0.7 && Chroma <= 1.2 && Value >= 8.5
				Level3Index = 92		;
			elseif Chroma > 0.7 && Chroma <= 1.2 && Value >= 6.5
				Level3Index = 93	;
			elseif Chroma > 0.7 && Chroma <= 1.2 && Value >= 4.5
				Level3Index = 63	;
			elseif Value >= 8.5 && Chroma <= 0.7
				Level3Index = 263	;
			elseif Value >= 6.5 && Chroma <= 0.7
				Level3Index = 264	;
			elseif Value >= 4.5 && Chroma <= 0.7
				Level3Index = 265	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 64	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 61	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 65	;
			elseif Chroma > 0.5 && Chroma <= 2.5 && Value >= 1.5 && Value < 2.5
				Level3Index = 62	;
			elseif Chroma > 1 && Chroma <= 5 && Value < 2.5
				Level3Index = 59	;
			elseif Chroma > 2.5 && Chroma <= 5 && Value >= 2.5 && Value < 4.5
				Level3Index = 58		;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 8
				Level3Index = 31		;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 6.5
				Level3Index = 33		;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 60	;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 7.5
				Level3Index = 73		;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 6.5 
				Level3Index = 76		;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 4.5 && Value < 6.5
				Level3Index = 57		;				
			elseif Chroma > 6 && Chroma <= 10 && Value >= 8 
				Level3Index = 70		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 6.5 
				Level3Index = 71		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 5.5 
				Level3Index = 72		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 8 
				Level3Index = 67		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 6.5 
				Level3Index = 68		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 5.5 
				Level3Index = 69		;
			elseif Chroma > 6 && Value >= 4.5 && Value < 5.5
				Level3Index = 74		;
			elseif Chroma > 14 && Value >= 5.5
				Level3Index = 66		;
			elseif Chroma > 5 && Value >= 2.5 && Value < 4.5
				Level3Index = 55		;
			elseif Chroma > 5 && Value < 2.5
				Level3Index = 56	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 17 and 18)'])
			end
			
		elseif Hue >= 18 && Hue < 21		%	Munsell hue range 8YR-1Y, p. 21 of [Kelly1976]
			if Chroma > 0.7 && Chroma <= 2 && Value >= 8.5
				Level3Index = 92		;
			elseif Chroma > 0.7 && Chroma <= 2 && Value >= 6.5
				Level3Index = 93	;
			elseif Chroma > 0.7 && Chroma <= 1.2 && Value >= 4.5 && Value < 6.5
				Level3Index = 63	;
			elseif Value >= 8.5 && Chroma <= 0.7
				Level3Index = 263	;
			elseif Value >= 6.5 && Chroma <= 0.7
				Level3Index = 264	;
			elseif Value >= 4.5 && Chroma <= 0.7
				Level3Index = 265	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 64	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value <= 1.5
				Level3Index = 65	;
			elseif Chroma > 2 && Chroma <= 6 && Value >= 7.5
				Level3Index = 73		;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 5.5 && Value < 7.5
				Level3Index = 79		;
			elseif Chroma > 3 && Chroma <= 6 && Value >= 5.5 && Value < 7.5
				Level3Index = 76		;
			elseif (Chroma > 1.2 && Chroma <= 3 && Value >= 4.5 && Value < 5.5) || ...
					(Chroma > 1.2 && Chroma <= 2.5 && Value >= 3.5 && Value < 4.5)
				Level3Index = 80		;
			elseif (Chroma > 3 && Chroma <= 5 && Value >= 4.5 && Value < 5.5) || ...
					(Chroma > 2.5 && Chroma <= 5 && Value >= 3.5 && Value < 4.5)
				Level3Index = 77		;
			elseif (Chroma > 1.2 && Chroma <= 2.5 && Value >= 2.5 && Value < 3.5) || ...
					(Chroma > 0.5 && Chroma <= 2.5 && Value >= 1.5 && Value < 2.5)
				Level3Index = 81		;
			elseif Chroma > 1 && Chroma <= 5 && Value < 3.5
				Level3Index = 78		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 8 
				Level3Index = 70		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 6.5 
				Level3Index = 71		;
			elseif Chroma > 6 && Chroma <= 10 && Value >= 5.5 
				Level3Index = 72		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 8 
				Level3Index = 67		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 6.5 
				Level3Index = 68		;
			elseif Chroma > 10 && Chroma <= 14 && Value >= 5.5 
				Level3Index = 69		;
			elseif Chroma > 14 && Value >= 5.5
				Level3Index = 66		;
			elseif Chroma > 5 && Value >= 3.5 && Value < 5.5
				Level3Index = 74		;
			elseif Chroma > 5 && Value < 3.5
				Level3Index = 75	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 18 and 21)'])
			end
			
		elseif Hue >= 21 && Hue < 24		%	Munsell hue range 1Y-4Y, p. 22 of [Kelly1976]
			if Chroma > 0.7 && Chroma <= 2 && Value >= 8.5
				Level3Index = 92		;
			elseif Chroma > 0.7 && Chroma <= 2 && Value >= 6.5
				Level3Index = 93	;
			elseif Chroma > 0.7 && Chroma <= 1.2 && Value >= 4.5 && Value < 6.5
				Level3Index = 63	;
			elseif Value >= 8.5 && Chroma <= 0.7
				Level3Index = 263	;
			elseif Value >= 6.5 && Chroma <= 0.7
				Level3Index = 264	;
			elseif Value >= 4.5 && Chroma <= 0.7
				Level3Index = 265	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 64	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 65	;
			elseif Chroma > 2 && Chroma <= 5 && Value >= 8
				Level3Index = 89		;
			elseif Chroma > 2 && Chroma <= 5 && Value >= 6.5
				Level3Index = 90		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 5.5 && Value < 6.5
				Level3Index = 91		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 8
				Level3Index = 86		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 6.5
				Level3Index = 87		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 5.5
				Level3Index = 88		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 8
				Level3Index = 83		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 6.5
				Level3Index = 84		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 5.5
				Level3Index = 85		;
			elseif Chroma > 11 && Value >= 5.5
				Level3Index = 82		;
			elseif Chroma > 1.2 && Value >= 4.5 && Value < 6.5
				Level3Index = 94		;
			elseif Chroma > 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 95		;
			elseif Chroma > 0.5 && Value < 2.5
				Level3Index = 96	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 21 and 24)'])
			end
			
		elseif Hue >= 24 && Hue < 27		%	Munsell hue range 4Y-7Y, p. 22 of [Kelly1976]
			if Chroma > 0.7 && Chroma <= 2 && Value >= 8.5
				Level3Index = 92		;
			elseif Chroma > 0.7 && Chroma <= 2 && Value >= 6.5
				Level3Index = 93	;
			elseif Chroma > 0.7 && Chroma <= 2 && Value >= 4.5 && Value < 6.5
				Level3Index = 112	;
			elseif Chroma > 2 && Chroma <= 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 109	;
			elseif Value >= 8.5 && Chroma <= 0.7
				Level3Index = 263	;
			elseif Value >= 6.5 && Chroma <= 0.7
				Level3Index = 264	;
			elseif Value >= 4.5 && Chroma <= 0.7
				Level3Index = 265	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 113	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 110	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 111	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 114	;
			elseif Chroma > 2 && Chroma <= 5 && Value >= 8
				Level3Index = 89		;
			elseif Chroma > 2 && Chroma <= 5 && Value >= 6.5
				Level3Index = 90		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 5.5 && Value < 6.5
				Level3Index = 91		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 8
				Level3Index = 86		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 6.5
				Level3Index = 87		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 5.5
				Level3Index = 88		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 8
				Level3Index = 83		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 6.5
				Level3Index = 84		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 5.5
				Level3Index = 85		;
			elseif Chroma > 11 && Value >= 5.5
				Level3Index = 82		;
			elseif Chroma > 3 && Value >= 4.5 && Value < 5.5
				Level3Index = 106		;
			elseif Chroma > 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 107		;
			elseif Chroma > 0.5 && Value < 2.5
				Level3Index = 108	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 24 and 27)'])
			end
			
		elseif Hue >= 27 && Hue < 29		%	Munsell hue range 7Y-9Y, p. 23 of [Kelly1976]
			if Chroma > 0.7 && Chroma <= 2 && Value >= 8.5
				Level3Index = 92		;
			elseif Chroma > 0.7 && Chroma <= 2 && Value >= 6.5
				Level3Index = 93	;
			elseif Chroma > 0.7 && Chroma <= 2 && Value >= 4.5 && Value < 6.5
				Level3Index = 112	;
			elseif Chroma > 2 && Chroma <= 3 && Value >= 8
				Level3Index = 89	;
			elseif Chroma > 2 && Chroma <= 3 && Value >= 6.5
				Level3Index = 90	;
			elseif Chroma > 2 && Chroma <= 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 109	;
			elseif Value >= 8.5 && Chroma <= 0.7
				Level3Index = 263	;
			elseif Value >= 6.5 && Chroma <= 0.7
				Level3Index = 264	;
			elseif Value >= 4.5 && Chroma <= 0.7
				Level3Index = 265	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 113	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 110	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 111	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 114	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 8
				Level3Index = 104		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 6.5
				Level3Index = 105		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 8
				Level3Index = 101		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 6.5
				Level3Index = 102		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 5.5
				Level3Index = 103		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 8
				Level3Index = 98		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 6.5
				Level3Index = 99		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 5.5
				Level3Index = 100		;
			elseif Chroma > 11 && Value >= 5.5
				Level3Index = 97		;
			elseif Chroma > 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 106		;
			elseif Chroma > 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 107		;
			elseif Chroma > 0.5 && Value < 2.5
				Level3Index = 108	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 27 and 29)'])
			end
			
		elseif Hue >= 29 && Hue < 32		%	Munsell hue range 9Y-2GY, p. 23 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.2 && Value >= 8.5
				Level3Index = 92		;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 6.5
				Level3Index = 93	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 4.5 && Value < 6.5
				Level3Index = 112	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 113	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 7.5
				Level3Index = 121	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 6.5
				Level3Index = 122	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 109	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 110	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 111	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 114	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 8
				Level3Index = 104		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 6.5
				Level3Index = 105		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 8
				Level3Index = 101		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 6.5
				Level3Index = 102		;
			elseif Chroma > 5 && Chroma <= 8 && Value >= 5.5
				Level3Index = 103		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 8
				Level3Index = 98		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 6.5
				Level3Index = 99		;
			elseif Chroma > 8 && Chroma <= 11 && Value >= 5.5
				Level3Index = 100		;
			elseif Chroma > 11 && Value >= 5.5
				Level3Index = 97		;
			elseif Chroma > 3 && Value >= 4.5 && Value < 6.5
				Level3Index = 106		;
			elseif Chroma > 3 && Value >= 2.5 && Value < 4.5
				Level3Index = 107		;
			elseif Chroma > 0.5 && Value < 2.5
				Level3Index = 108	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 29 and 32)'])
			end
			
		elseif Hue >= 32 && Hue < 34		%	Munsell hue range 2GY-4GY, p. 24 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.2 && Value >= 8.5
				Level3Index = 92		;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 6.5
				Level3Index = 93	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 4.5 && Value < 6.5
				Level3Index = 112	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 113	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 7.5
				Level3Index = 121	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 4.5
				Level3Index = 122	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 2.5
				Level3Index = 127	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 128	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 114	;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 7.5
				Level3Index = 119		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 4.5
				Level3Index = 120		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 2.5
				Level3Index = 125		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 7.5
				Level3Index = 116		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 4.5
				Level3Index = 117		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5
				Level3Index = 118		;
			elseif Chroma > 7 && Value >= 2.5 && Value < 3.5
				Level3Index = 123		;
			elseif Chroma > 11 && Value >= 3.5
				Level3Index = 115		;
			elseif Chroma > 1 && Value < 2.5
				Level3Index = 126		;
			elseif Chroma > 7 && Value < 2.5
				Level3Index = 124	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 32 and 34)'])
			end																																																																																																																																																																																																																																								
			
		elseif Hue >= 34 && Hue < 38		%	Munsell hue range 4GY-8GY, p. 24 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.2 && Value >= 8.5
				Level3Index = 153		;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 6.5
				Level3Index = 154	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 4.5 && Value < 6.5
				Level3Index = 155	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 156	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 7.5
				Level3Index = 121	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 4.5
				Level3Index = 122	;
			elseif Chroma > 1.2 && Chroma <= 3 && Value >= 2.5
				Level3Index = 127	;
			elseif Chroma > 0.5 && Chroma <= 3 && Value >= 1.5 && Value < 2.5
				Level3Index = 128	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 1.5
				Level3Index = 157	;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 7.5
				Level3Index = 119		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 4.5
				Level3Index = 120		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 2.5
				Level3Index = 125		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 7.5
				Level3Index = 116		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 4.5
				Level3Index = 117		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5
				Level3Index = 118		;
			elseif Chroma > 7 && Value >= 2.5 && Value < 3.5
				Level3Index = 123		;
			elseif Chroma > 11 && Value >= 3.5
				Level3Index = 115		;
			elseif Chroma > 1 && Value < 2.5
				Level3Index = 126		;
			elseif Chroma > 7 && Value < 2.5
				Level3Index = 124	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 34 and 38)'])
			end																																																																																																																																																																																																																																								
						
		elseif Hue >= 38 && Hue < 43		%	Munsell hue range 8GY-3G, p. 25 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.2 && Value >= 8.5
				Level3Index = 153		;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 6.5
				Level3Index = 154	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 4.5 && Value < 6.5
				Level3Index = 155	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 156	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 7.5
				Level3Index = 148	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 5.5
				Level3Index = 149	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 3.5
				Level3Index = 150	;
			elseif (Chroma > 1 && Chroma <= 2.5 && Value >= 2.5 && Value < 3.5) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 151	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 157	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 152	;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 8.5
				Level3Index = 134		;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 6.5
				Level3Index = 135		;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 4.5
				Level3Index = 136		;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 2.5
				Level3Index = 137		;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2.5
				Level3Index = 138		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 6.5
				Level3Index = 130		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 4.5
				Level3Index = 131		;
			elseif Chroma > 7 && Value >= 2.5 && Value <= 4.5
				Level3Index = 132		;
			elseif Chroma > 7 && Value < 2.5 
				Level3Index = 133		;
			elseif Chroma > 11 && Value > 4.5 
				Level3Index = 129		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 38 and 43)'])
			end
			
		elseif Hue >= 43 && Hue < 49		%	Munsell hue range 3G-9G, p. 25 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.2 && Value >= 8.5
				Level3Index = 153		;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 6.5
				Level3Index = 154	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 4.5 && Value < 6.5
				Level3Index = 155	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 156	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 7.5
				Level3Index = 148	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 5.5
				Level3Index = 149	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 3.5
				Level3Index = 150	;
			elseif (Chroma > 1 && Chroma <= 2.5 && Value >= 2.5 && Value < 3.5) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 151	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 157	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 152	;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 7.5
				Level3Index = 143		;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 5.5
				Level3Index = 144		;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 3.5
				Level3Index = 145		;
			elseif Chroma > 2 && Chroma <= 7 && Value >= 2
				Level3Index = 146		;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2
				Level3Index = 147		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 5.5
				Level3Index = 140		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5
				Level3Index = 141		;
			elseif Chroma > 7 && Chroma <= 11 && Value < 3.5
				Level3Index = 142		;
			elseif Chroma > 11
				Level3Index = 139		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 43 and 49)'])
			end
			
		elseif Hue >= 49 && Hue < 60		%	Munsell hue range 9G-10BG, p. 26 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.2 && Value >= 8.5
				Level3Index = 153		;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 6.5
				Level3Index = 154	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 4.5 && Value < 6.5
				Level3Index = 155	;
			elseif Chroma > 0.5 && Chroma <= 1.2 && Value >= 2.5 && Value < 4.5
				Level3Index = 156	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 7.5
				Level3Index = 148	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 5.5
				Level3Index = 149	;
			elseif Chroma > 1.2 && Chroma <= 2.5 && Value >= 3.5
				Level3Index = 150	;
			elseif (Chroma > 1.2 && Chroma <= 2.5 && Value >= 2.5 && Value < 3.5) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 151	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 157	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 152	;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 7.5
				Level3Index = 162		;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 5.5
				Level3Index = 163		;
			elseif Chroma > 2.5 && Chroma <= 7 && Value >= 3.5
				Level3Index = 164		;
			elseif Chroma > 2 && Chroma <= 7 && Value >= 2
				Level3Index = 165		;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2
				Level3Index = 166		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 5.5
				Level3Index = 159		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5
				Level3Index = 160		;
			elseif Chroma > 7 && Chroma <= 11 && Value < 3.5
				Level3Index = 161		;
			elseif Chroma > 11
				Level3Index = 158		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 49 and 60)'])
			end
			
		elseif Hue >= 60 && Hue < 69		%	Munsell hue range 10BG-9B, p. 26 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 189		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 190	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5 && Value < 6.5
				Level3Index = 191	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 192	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 7.5
				Level3Index = 184	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5
				Level3Index = 185	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 3
				Level3Index = 186	;
			elseif (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 187	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 193	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 188	;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 7.5
				Level3Index = 171		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 5.5
				Level3Index = 172		;
			elseif Chroma > 2 && Chroma <= 7 && Value >= 3.5
				Level3Index = 173		;
			elseif Chroma > 2 && Chroma <= 7 && Value >= 2
				Level3Index = 174		;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2
				Level3Index = 175		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 5.5
				Level3Index = 168		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5
				Level3Index = 169		;
			elseif Chroma > 7 && Chroma <= 11 && Value < 3.5
				Level3Index = 170		;
			elseif Chroma > 11
				Level3Index = 167		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 60 and 69)'])
			end
			
		elseif Hue >= 69 && Hue < 75		%	Munsell hue range 9B-5PB, p. 27 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 189		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 190	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5 && Value < 6.5
				Level3Index = 191	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 192	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 7.5
				Level3Index = 184	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 5.5
				Level3Index = 185	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 3
				Level3Index = 186	;
			elseif (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 187	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 193	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 188	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 7.5
				Level3Index = 180		;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 5.5
				Level3Index = 181		;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 3
				Level3Index = 182		;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 5.5
				Level3Index = 177		;
			elseif Chroma > 9 && Chroma <= 13 && Value > 3
				Level3Index = 178		;
			elseif Chroma > 2 && Chroma <= 7 && Value <= 3
				Level3Index = 183		;
			elseif Chroma > 7 && Chroma <= 11 && Value <= 3
				Level3Index = 179		;
			elseif (Chroma > 13) || ...
				   (Chroma > 11 && Value <= 3)
				Level3Index = 176		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 69 and 75)'])
			end
			
		elseif Hue >= 75 && Hue < 76		%	Munsell hue range 5PB-6PB, p. 27 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 189		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 190	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5 && Value < 6.5
				Level3Index = 191	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 192	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 7.5
				Level3Index = 184	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5
				Level3Index = 185	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 3
				Level3Index = 186	;
			elseif (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 187	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 193	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 188	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 7.5
				Level3Index = 202		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 4.5
				Level3Index = 203		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 3
				Level3Index = 204		;
			elseif Chroma > 5 && Chroma <= 7 && Value >= 7.5
				Level3Index = 198		;
			elseif Chroma > 5 && Chroma <= 7 && Value >= 4.5
				Level3Index = 199		;
			elseif Chroma > 7 && Chroma <= 9 && Value >= 7.5
				Level3Index = 180		;
			elseif Chroma > 7 && Chroma <= 9 && Value >= 5.5
				Level3Index = 181		;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 3
				Level3Index = 182		;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 5.5
				Level3Index = 177		;
			elseif Chroma > 9 && Chroma <= 13 && Value > 3
				Level3Index = 178		;
			elseif Chroma > 2 && Chroma <= 7 && Value <= 3
				Level3Index = 183		;
			elseif Chroma > 7 && Chroma <= 11 && Value <= 3
				Level3Index = 179		;
			elseif (Chroma > 13) || ...
				   (Chroma > 11 && Value <= 3)
				Level3Index = 176		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 75 and 76)'])
			end
			
		elseif Hue >= 76 && Hue < 77		%	Munsell hue range 6PB-7PB, p. 28 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 189		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 190	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5 && Value < 6.5
				Level3Index = 191	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 192	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 7.5
				Level3Index = 184	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5
				Level3Index = 185	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 3
				Level3Index = 186	;
			elseif (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 187	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 193	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 188	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 7.5
				Level3Index = 202		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 4.5
				Level3Index = 203		;
			elseif Chroma > 2 && Chroma <= 5 && Value >= 2
				Level3Index = 204		;
			elseif Chroma > 2 && Chroma <= 5 && Value <= 2
				Level3Index = 201		;
			elseif Chroma > 5 && Chroma <= 7 && Value >= 7.5
				Level3Index = 198		;
			elseif Chroma > 5 && Chroma <= 7 && Value >= 4.5
				Level3Index = 199		;
			elseif Chroma > 7 && Chroma <= 9 && Value >= 7.5
				Level3Index = 180		;
			elseif Chroma > 7 && Chroma <= 9 && Value >= 5.5
				Level3Index = 181		;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 3
				Level3Index = 182		;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 5.5
				Level3Index = 177		;
			elseif Chroma > 9 && Chroma <= 13 && Value > 3
				Level3Index = 178		;
			elseif Chroma > 2 && Chroma <= 7 && Value <= 3
				Level3Index = 183		;
			elseif Chroma > 7 && Chroma <= 11 && Value <= 3
				Level3Index = 179		;
			elseif (Chroma > 13) || ...
				   (Chroma > 11 && Value <= 3)
				Level3Index = 176		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 76 and 77)'])
			end
			
		elseif Hue >= 77 && Hue < 79		%	Munsell hue range 7PB-9PB, p. 28 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 189		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 190	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5 && Value < 6.5
				Level3Index = 191	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 192	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 7.5
				Level3Index = 184	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5
				Level3Index = 185	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 3
				Level3Index = 186	;
			elseif (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 187	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 193	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 188	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 7.5
				Level3Index = 202		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 4.5
				Level3Index = 203		;
			elseif Chroma > 2 && Chroma <= 5 && Value >= 2
				Level3Index = 204		;
			elseif Chroma > 2 && Chroma <= 7 && Value <= 2
				Level3Index = 201		;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 7.5
				Level3Index = 198		;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 4.5
				Level3Index = 199		;
			elseif (Chroma > 5 && Chroma <= 9 && Value >= 3 && Value < 4.5) || ...
				   (Chroma > 5 && Chroma <= 7 && Value >= 2 && Value < 3)
				Level3Index = 200	;
			elseif (Chroma > 9 && Chroma <= 13 && Value >= 5.5) || ...
				   (Chroma > 9 && Chroma <= 11 && Value >= 4.5 && Value < 5.5)
				Level3Index = 195		;
			elseif Chroma > 9 && Chroma <= 13 && Value > 3
				Level3Index = 196		;
			elseif Chroma > 7 && Chroma <= 11 && Value <= 3
				Level3Index = 197		;
			elseif (Chroma > 13) || ...
				   (Chroma > 11 && Value <= 3)
				Level3Index = 194		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 77 and 79)'])
			end
			
		elseif Hue >= 79 && Hue < 83		%	Munsell hue range 9PB-3P, p. 29 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 231		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 232	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5 && Value < 6.5
				Level3Index = 233	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 234	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 7.5
				Level3Index = 226	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5
				Level3Index = 227	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 3.5
				Level3Index = 228	;
			elseif (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3.5) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 229	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 235	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 230	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 7.5
				Level3Index = 213		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 4.5
				Level3Index = 214		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 2.5
				Level3Index = 215		;
			elseif Chroma > 2 && Chroma <= 7 && Value <= 2.5
				Level3Index = 212		;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 7.5
				Level3Index = 209		;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 4.5
				Level3Index = 210		;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 2.5
				Level3Index = 211	;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 4.5
				Level3Index = 206		;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 2.5
				Level3Index = 207		;
			elseif Chroma > 7 && Chroma <= 13 && Value <= 2.5
				Level3Index = 208		;
			elseif Chroma > 13
				Level3Index = 205		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 79 and 83)'])
			end
			
		elseif Hue >= 83 && Hue < 89		%	Munsell hue range 3P-9P, p. 29 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 231		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 232	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5 && Value < 6.5
				Level3Index = 233	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 234	;
			elseif (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3.5) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 229	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 7.5
				Level3Index = 226	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 5.5
				Level3Index = 227	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 3.5
				Level3Index = 228	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 7.5
				Level3Index = 221	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 5.5
				Level3Index = 222	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 3.5
				Level3Index = 223	;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 5.5
				Level3Index = 217	;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 3.5
				Level3Index = 218	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 235	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 230	;
			elseif Chroma > 2 && Chroma <= 7 && Value >= 2 && Value < 3.5
				Level3Index = 224		;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2 
				Level3Index = 225		;
			elseif Chroma > 7 && Chroma <= 13 && Value >= 2 && Value < 3.5
				Level3Index = 219		;
			elseif Chroma > 7 && Chroma <= 13 && Value < 2 
				Level3Index = 220		;
			elseif Chroma > 13
				Level3Index = 216		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 83 and 89)'])
			end
			
		elseif Hue >= 89 && Hue < 93		%	Munsell hue range 9P-3RP, p. 30 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 231		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 232	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5 && Value < 6.5
				Level3Index = 233	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 234	;
			elseif (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3.5) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 229	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 235	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 230	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 7.5
				Level3Index = 252	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 6.5
				Level3Index = 253	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5
				Level3Index = 227	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 3.5
				Level3Index = 228	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 5.5 && Value < 6.5
				Level3Index = 244	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 3.5 && Value < 5.5
				Level3Index = 245	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 7.5
				Level3Index = 249	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 6.5
				Level3Index = 250	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 5.5
				Level3Index = 240	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 3.5
				Level3Index = 241	;
			elseif Chroma > 9 && Value >= 7.5
				Level3Index = 246	;
			elseif Chroma > 9 && Value >= 6.5 && Value < 7.5
				Level3Index = 247		;
			elseif Chroma > 9 && Chroma <= 15 && Value >= 5.5 && Value < 6.5 
				Level3Index = 248		;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 3.5 && Value < 5.5
				Level3Index = 237		;
			elseif Chroma > 13 && Value < 6.5 
				Level3Index = 236		;
			elseif Chroma > 2 && Chroma <= 7 && Value >= 2 && Value < 3.5
				Level3Index = 242	;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2
				Level3Index = 243	;
			elseif Chroma > 7 && Chroma <= 13 && Value >= 2 && Value < 3.5
				Level3Index = 238	;
			elseif Chroma > 7 && Chroma <= 13 && Value < 2
				Level3Index = 239	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 89 and 93)'])
			end
			
		elseif Hue >= 93 && Hue < 99		%	Munsell hue range 3RP-9RP, p. 30 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 231		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 232	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5 && Value < 6.5
				Level3Index = 233	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5 && Value < 4.5
				Level3Index = 234	;
			elseif (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3.5) || ...
				   (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5)
				Level3Index = 229	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 235	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 230	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 7.5
				Level3Index = 252	;
			elseif Chroma > 1.5 && Chroma <= 5 && Value >= 6.5
				Level3Index = 253	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5
				Level3Index = 227	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 3.5
				Level3Index = 228	;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 5.5 && Value < 6.5
				Level3Index = 261	;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 3.5 && Value < 5.5
				Level3Index = 262	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 7.5
				Level3Index = 249	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 6.5
				Level3Index = 250	;
			elseif Chroma > 5 && Chroma <= 9 && Value >= 5.5
				Level3Index = 251	;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5 && Value < 5.5
				Level3Index = 258	;
			elseif Chroma > 9 && Value >= 7.5
				Level3Index = 246	;
			elseif Chroma > 9 && Value >= 6.5 && Value < 7.5
				Level3Index = 247		;
			elseif Chroma > 9 && Chroma <= 15 && Value >= 5.5 && Value < 6.5 
				Level3Index = 248		;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 3.5 && Value < 5.5
				Level3Index = 255		;
			elseif Chroma > 2 && Chroma <= 9 && Value >= 2 && Value < 3.5
				Level3Index = 259	;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2
				Level3Index = 260	;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 2 && Value < 3.5
				Level3Index = 256	;
			elseif Chroma > 7 && Chroma <= 11 && Value < 2
				Level3Index = 257	;
			elseif Chroma > 11 && Value < 6.5 
				Level3Index = 254		;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 93 and 99)'])
			end
	
		elseif Hue >= 99 || Hue < 1		%	Munsell hue range 9RP-1R, p. 31 of [Kelly1976]
			if Chroma > 0.5 && Chroma <= 1.5 && Value >= 8.5
				Level3Index = 9		;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 6.5
				Level3Index = 10	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 4.5
				Level3Index = 233	;
			elseif Chroma > 0.5 && Chroma <= 1.5 && Value >= 2.5
				Level3Index = 234	;
			elseif (Chroma > 0.5 && Chroma <= 2 && Value >= 2 && Value < 2.5) || ...
				   (Chroma > 1.5 && Chroma <= 3 && Value >= 2.5 && Value < 3.5)
				Level3Index = 229	;
			elseif Chroma > 0.5 && Chroma <= 1 && Value < 2
				Level3Index = 235	;
			elseif Chroma > 1 && Chroma <= 2 && Value < 2
				Level3Index = 230	;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 8
				Level3Index = 7		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 6.5
				Level3Index = 8		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 5.5
				Level3Index = 227		;
			elseif Chroma > 1.5 && Chroma <= 3 && Value >= 3.5
				Level3Index = 228		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 8
				Level3Index = 4		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 6.5 
				Level3Index = 5		;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 6.5 
				Level3Index = 2		;
			elseif Chroma > 11 && Value >= 6.5 
				Level3Index = 1		;
			elseif Chroma > 3 && Chroma <= 5 && Value >= 5.5 && Value < 6.5
				Level3Index = 261	;
			elseif Chroma > 5 && Chroma <= 7 && Value >= 5.5 && Value < 6.5
				Level3Index = 6		;
			elseif Chroma > 7 && Chroma <= 15 && Value >= 5.5 && Value < 6.5
				Level3Index = 3		;
			elseif Chroma > 3 && Chroma <= 7 && Value >= 3.5 && Value < 5.5
				Level3Index = 262	;
			elseif Chroma > 7 && Chroma <= 11 && Value >= 3.5 && Value < 5.5
				Level3Index = 258	;
			elseif Chroma > 11 && Chroma <= 13 && Value >= 3.5 && Value < 5.5
				Level3Index = 255	;
			elseif Chroma >= 2 && Chroma <= 9 && Value >= 2 && Value < 3.5
				Level3Index = 259	;
			elseif Chroma > 9 && Chroma <= 13 && Value >= 2 && Value < 3.5
				Level3Index = 256	;
			elseif Chroma > 2 && Chroma <= 7 && Value < 2 
				Level3Index = 260	;
			elseif Chroma > 7 && Chroma <= 11 && Value < 2 
				Level3Index = 257	;
			elseif Chroma > 11 && Value < 6.5 
				Level3Index = 254	;
			else
				disp(['No ISCC-NBS name found for ',MunsellSpecString,' (ASTM hue between 99 and 1)'])
			end																																																																																																																																																																																																
																																																																																																																																																																																																
		end
		
	end		% End neutral vs non-neutral
	
	% Add Level 3 index for current Munsell specification into vector of Level 3 indices
	Level3Indices(ctr) = Level3Index	;
	
	% From the Level 3 index, assign all the other ISCC-NBS data, using the read-in information
	if not(isnan(Level3Index))
		Level2Indices(ctr)   = AllLevel2Indices(Level3Index)	;
		Level1Indices(ctr)   = AllLevel1Indices(Level3Index)	;
		Designators{ctr}     = AllDesignators{Level3Index}		;
		Abbreviations{ctr}   = AllAbbreviations{Level3Index}	;
	else
		Level2Indices(ctr)   = NaN	;
		Level1Indices(ctr)   = NaN	;
		Designators{ctr}     = 'NA'	;
		Abbreviations{ctr}   = 'NA'	;
	end

end			% End looping through individual input Munsell specifications