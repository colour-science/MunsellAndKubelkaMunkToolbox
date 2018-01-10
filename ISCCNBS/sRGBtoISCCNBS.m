function [Level3Indices, Level2Indices, Level1Indices, Designators, Abbreviations, MunsellSpecs] = ...
			sRGBtoISCCNBS(sRGB);
%
% Purpose		For an input sRGB triple (such as [247	182	212]), find the verbal 
%				description given by the ISCC-NBS colour naming system (in this case, light
%				purplish pink).
%
% Description	The sRGB system standardizes the visual output of a red-green-blue display such as
%				an electronic monitor.  The standard specifies the CIE XYZ coordinates of the
%				visual output for a given sRGB triple.  The colour appearance of that output can
%				vary with the ambient illumination in which the monitor is viewed.  
%				While a monitor produces coloured light, objects can also have colours.  Under
%				the right circumstances, a coloured light can match the colour of an object; a
%				graphic artist, for example, will calibrate his printer and monitor so that the
%				colours he sees on the screen agree with the colours he prints.
%
%				While the sRGB system standardizes light source, the ISCC-NBS colour naming system
%				[Kelly1976] is a standardized verbal description of object colours.  It was created
%				in 1955, the Inter-Society Color Council (ISCC) and the US National Bureau of Standards 
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
% 				approximate: there are many colours, for example, that would be called "red."  In Level 2,
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
%				This routine gives the ISCC-NBS description of an sRGB colour.  Since the ISCC-NBS
%				system assumes the ambient light is in accordance with Illuminant C, the monitor on
%				which the sRGB colour is displayed is also assumed to be viewed under Illuminant C.
%				The Munsell system also assumes Illuminant C.  The conversion from sRGB to ISCC-NBS
%				has two steps: first the sRGB triple is converted to a Munsell notation, and then
%				the Munsell notation is converted to ISCC-NBS (using pp. 16-31 of [Kelly1976]).  Each
%				of these steps is performed by calling an already-written routine.
%
%				A detailed technical discussion of the sRGB to ISCC-NBS conversion can be found in
%				[Centore2016].
%
%				sRGB			A three-column matrix, each row of which gives the red, green, and
%								blue coordinates for a single sRGB triple.  All entries are
%								assumed to be between 0 and 255.
%
%				Level1Indices, Level2Indices, Level3Indices		Vectors giving the ISCC-NBS indices
%								for Levels 1, 2, and 3, for the input Munsell specification(s)
%
%				Designators		A list of strings such as "light purplish pink."  Each string gives
%								the ISCC-NBS verbal colour name for an input Munsell specification(s)
%
%				Abbreviations	A list of strings such as "l.pPk."  Each string gives the ISCC-NBS
%								abbreviation for an input Munsell specification(s)
%
% 				[Kelly1976] Kenneth L. Kelly & Deane B. Judd, "Color: Universal Language and Dictionary 
% 						of Names," NBS Special Publication 440, 1976. Available online at
% 						http://nvlpubs.nist.gov/nistpubs/Legacy/SP/nbsspecialpublication440.pdf or
% 						https://ia801701.us.archive.org/9/items/coloruniversalla00kell/coloruniversalla00kell.pdf
% 				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
% 				        Report of the O.S.A. Subcommittee on the Spacing of the Munsell
% 				        Colors," Journal of the Optical Society of America, Vol. 33,
% 				        Issue 7, pp. 385-418, 1943.
% 				[Agoston1987] George A. Agoston, Color Theory and Its Application in Art and Design,
% 						Springer, 1987.      
%				[Centore2016] Paul Centore, "sRGB Centroids for the ISCC-NBS Colour System," 2016.  
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
Level3Indices = []	;
Level2Indices = []	;
Level1Indices = []	;
Designators   = {}	;
Abbreviations = {}	;
MunsellSpecs  = {}	;

% Determine the number of input sRGBs
NumberOfsRGBs = size(sRGB,1)	;

% Check that at least one sRGB triple has been input
if NumberOfsRGBs == 0
	disp(['Empty input to routine sRGBtoISCCNBS: exiting routine'])	;
	return
end

% Loop through all the input sRGB triples
for ctr = 1:NumberOfsRGBs
	% Extract an individual sRGB triple, which is one row of the input matrix
	sRGBtriple = sRGB(ctr,:)	;
	
	% Convert the current sRGB triple to a Munsell specification
	[MunsellSpec, MunsellVec, InMacAdamLimitsFlag, Status] = sRGBtoMunsell(sRGBtriple);
	
	% If there is no Munsell specification for a particular sRGB triple, then record NaN
	% or null entries in the output lists
	if Status.ind ~= 1 		
		Level3Indices(ctr)   = NaN	;
		Level2Indices(ctr)   = NaN	;
		Level1Indices(ctr)   = NaN	;
		Designators{ctr}     = 'NA'	;
		Abbreviations{ctr}   = 'NA'	;
		MunsellSpecs{ctr}    = 'NA'	;
	else	% Otherwise, find the ISCC-NBS description from the Munsell specification
		[Level3Index, Level2Index, Level1Index, Designator, Abbreviation] = MunsellToISCCNBS(MunsellSpec)	;
		Level3Indices(ctr)   = Level3Index	;
		Level2Indices(ctr)   = Level2Index	;
		Level1Indices(ctr)   = Level1Index	;
		Designators{ctr}     = Designator	;
		Abbreviations{ctr}   = Abbreviation	;
		MunsellSpecs{ctr}    = MunsellSpec	;
	end				
	
end		% End looping through input sRGB triples