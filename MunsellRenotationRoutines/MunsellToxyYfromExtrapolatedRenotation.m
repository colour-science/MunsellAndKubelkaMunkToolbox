function [x y Y Status] = MunsellToxyYfromExtrapolatedRenotation(ColorLabColour);
% Purpose		Find the xyY coordinates for a Munsell colour, including achromatic
%				colours, listed in the extrapolated renotation data.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form HV/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R8.0/4.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				The CIE chromaticity diagram ([Foley1990, Sect. 13.2.2]) displays 
%				all chromaticities that are possible for a light source of a fixed
%				luminance, when	the light source is viewed in isolation.  
%				The Munsell renotation ([Newhall1943]) related local colours, as
%				exemplified in the Munsell colour system, to coloured lights, for
%				which xy chromaticities can be calculated.  The renotation measured,
%				and adjusted, the chromaticities of physical Munsell samples, when 
%				illuminated by illuminant C.  
%
%				Table 1 of [Newhall1943] lists xyY coordinates for Munsell colours whose
%				Munsell values are integers from 1 to 9, whose chromas are even integers,
%				and whose numerical hue prefixes are 2.5, 5, 7.5, or 10.  Neutral greys are
%				not listed in Table 1, but p. 386 of [Newhall1943] says that they are taken to
%				be of the same chromaticity as Illuminant C.  The renotation data has been
%				extrapolated, sometimes beyond the MacAdam limits, in the file all.dat from
%				[MCSL2010].   
%
%				This routine reads in a variable from the file ExtrapolatedRenotationMatrices.mat, made
%				by the routine MakeExtrapolatedRenotationMatrices, which converts the data
%				in all.dat into a form suitable for Matlab or Octave. 
%				The variable ExtrapolatedRenotationMatrices is a structure with three fields: x, y, and Y.
%				Each field is a triply indexed matrix.  The three matrices
%				give the x, y, and Y coordinates for the extrapolated Munsell renotations.  The three indices,
%				which are identical for each matrix, are HueIndex, Value Index, and Chroma Index.
%
%				HueIndex goes from 0 to 41, corresponding to Munsell hues, as follows:
%					1 2.5R	 |	 9 2.5Y  |	17 2.5G  |	25 2.5B  |	33 2.5P  |	41 N
%					2 5R	 |	10 5Y	 |	18 5G    |	26 5B    |	34 5P    |
%					3 7.5R	 |	11 7.5Y	 |	19 7.5G  |	27 7.5B  |	35 7.5P  |
%					4 10R	 |	12 10Y   |	20 10G   |	28 10B   |	36 10P   |
%					5 2.5YR |	13 2.5GY |	21 2.5BG |	29 2.5PB |	37 2.5RP |
%					6 5YR	 |	14 5GY   |	22 5BG   |	30 5PB   |	38 5RP   |
%					7 7.5YR |	15 7.5GY |	23 7.5BG |	31 7.5PB |	39 7.5RP |
%					8 10YR	 |	16 10GY  |	24 10BG  |	32 10PB  |	40 10RP  |
%				In addition to chromatic colours, neutral greys are given a hue index of 41.
%
%				ValueIndex runs from 1 to 9, and is equal to the Munsell value.
%
%				ChromaIndex runs from 1 to 19, and is half the Munsell chroma.  Greys, whose
%				chroma is 0, are assigned a ChromaIndex of 20.
%
%				If a Munsell specification is beyond the MacAdam limits, then the three matrices
%				contain entries of NaN.
%
%				Routines in ColorLab use the Munsell specifications, but not necessarily the
%				Munsell notation HV/C.  A Munsell vector is given by [H1, V, C, H2], where 
%				H1 is the numerical prefix for hue, H2 is the position of the hue letter 
%				designator in the list
%				                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
%				V is the Munsell value, and C is the Munsell chroma. For example, 
%				5.0R9.0/4.0 is [5 9 4 7] in ColorLab
%				format.  A neutral Munsell grey is a one-element vector in ColorLab
%				format, consisting of the grey value.  For example, N4 is [4] in ColorLab
%				format.
%
%				While the renotation uses hue numbers of 2.5, 5.0, 7.5, or 10.0, sometimes
%				a hue number of 0 is used for hues with hue number 10.  For example,
%				instead of writing 10Y, one might write 0GY; these two hues are the same.
%				This routine has been revised to allow hue numbers to be input as 0.  Such
%				inputs are changed to 10 (of an adjacent hue), so that they can be read
%				from the renotation data.
%
%				This routine calculates HueIndex, ValueIndex, and ChromaIndex from the input
%				colour vector, and then evaluates the three renotation matrices at those
%				indices.
%
%				[Foley1990] James D. Foley, Andries van Dam, Steven K. Feiner, & John
%					F. Hughes, Computer Graphics: Principles and Practice, 2nd ed.,
%					Addison-Wesley Publishing Company, 1990.
%				[MCSL2010] http://www.cis.rit.edu/mcsl/online/munsell.php, as of June 12, 2010
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		[x y Y Status] = MunsellToxyYfromExtrapolatedRenotation(ColorLabColour);
%
%				ColorLabColour	A colour in the format [H1, V, C, H2], where 
%								H1 is the number designator for hue, H2 is the 
%								position of the hue letter designator in the list
%										{B, BG, G, GY, Y, YR, R, RP, P, PB},
%								V is the Munsell value, and C is the Munsell chroma. 
%
%				x, y, Y			Chromaticity (and relative luminance)  coordinates for
%								the input colour, according to the extrapolated
%								Munsell renotation ([Newhall1943], [MCSL2010]).
%
%				Status			A return code with multiple fields.  The second field is a list
%								of possible return messages.  The first field is a positive
%								integer indicating one of the return messages.  
%
% Related		MakeExtrapolatedRenotationMatrices
% Functions
%
% Required		
% Functions		
%
% Author		Paul Centore (June 23, 2010) 
% Revision  	Paul Centore (December 31, 2010)
%	             ---Added NumericalHuePrefix threshold, to avoid error due to very small quantities
% Revision   	Paul Centore (May 8, 2012)
%				 ---Changed != to ~= so that code would work in both Matlab and Octave.
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (August 18, 2015)  
%				 ---Allowed hue number to be 0, and converted to 10.  E.g. 0GY would be
%				    converted to 10Y.
%
% Copyright 2010-2015 Paul Centore
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

% Make a list of possible status return messages
Status.Messages = {'Success',...
                   'The input colour is beyond the extrapolated renotation data',...
				   'The input value must be an integer between 1 and 9',...
				   'The numerical prefix must be 2.5, 5, 7.5, or 10',...
				   'The chroma must be an even number less than or equal to 38',...
				   'The hue letter designator must be an integer between 1 and 10',...
				   };
% Initialize return variables with default values
x = -99	;
y = -99	;
Y = -99	;

% To avoid numerical issues, the numerical hue prefix number is not required to be exactly
% 0.0, 2.5, 5, 7.5, or 10, but only very close: it must be within NHPthreshold
NHPthreshold = 0.001;	
NHPthreshold = 0.001	;							
	
% Load renotation data as a MATLAB structure, if it is not already loaded
persistent ExtrapolatedRenotationMatrices		% Load data only once, to save time
if isempty(ExtrapolatedRenotationMatrices) 		% Extrapolated renotation data not loaded
   load ExtrapolatedRenotationMatrices.mat;
end
				   
% These are the letter designators for the Munsell hue, in the order used in HueList
HueListLetters = {'R', 'YR', 'Y', 'GY', 'G', 'BG', 'B', 'PB', 'P', 'RP'};

% These are the letter designators for the Munsell hue, in ColorLab format
ColorLabHueLetters = {'B', 'BG', 'G', 'GY', 'Y', 'YR', 'R', 'RP', 'P', 'PB'};

% Extract Munsell quantities from the input vector, which is in ColorLab format
% A one-element colour vector is achromatic grey
if length(ColorLabColour) == 1
   Value  = ColorLabColour(1)	;
   Chroma = 0					;
else	% ColorLab vector has four elements
   NumericalHuePrefix  = ColorLabColour(1)		;
   HueLetterDesignator = ColorLabColour(4)		;
   Value               = ColorLabColour(2)		;
   Chroma              = ColorLabColour(3)		;
   
	% If the numerical hue prefix is 0, it will be changed to 10, with an appropriate
	% adjustment of the hue letter.
	if abs(NumericalHuePrefix) < NHPthreshold
		NumericalHuePrefix  = 10						;
		HueLetterDesignator = HueLetterDesignator + 1	;
		% The hue 0PB must be wrapped around to 10B
		if HueLetterDesignator > 10
			HueLetterDesignator = 1	;
		end
	end	
end
		   
% Check that value is an integer between 1 and 9.  If not, return with an error message.
% If the value is valid, then the value index to the three extrapolated renotation matrices 
% is just the Munsell value.
if Value < 1 || Value >9 || mod(Value,1) ~= 0
   Status.ind = 3		;
   return;
else
   ValueIndex = Value	;
end

% Find HueIndex and ChromaIndex for three renotation matrices.  First check if the
% input colour is achromatic.  Assign conventional index values if it is
if Chroma == 0
   HueIndex = 41		;
   ChromaIndex = 20		;
else		% Find HueIndex and ChromaIndex for chromatic colours.
   % Check that the hue letter is one of the allowable ten
   if HueLetterDesignator < 1 || HueLetterDesignator >10 || mod(HueLetterDesignator,1) ~= 0
      Status.ind = 6		;
	  return;
   end
   ColorLabHueLetter = ColorLabHueLetters{HueLetterDesignator};
   
   % Find what position in the list {R, YR, Y, GY, G, BG, B, PB, P, RP} the input hue holds
   LetterPosition = -99	;
   for i = 1:length(HueListLetters)
      if strcmp(ColorLabHueLetter, HueListLetters{i}) == 1
	     LetterPosition = i;
	  end
   end
   
   % Use the numerical hue prefix to find where in the list of HueIndexes the input hue is
   if abs(NumericalHuePrefix-2.5) <= NHPthreshold
      NumberPosition = 1;
   elseif abs(NumericalHuePrefix-5) <= NHPthreshold
      NumberPosition = 2;
   elseif abs(NumericalHuePrefix-7.5) <= NHPthreshold
      NumberPosition = 3;
   elseif abs(NumericalHuePrefix-10) <= NHPthreshold
      NumberPosition = 4;
   else		% Invalid numerical prefix; return with error message
      Status.ind = 4		;
	  return;
   end
   HueIndex = ((LetterPosition-1)*4) + NumberPosition;
   
   % ChromaIndex is just the chroma divided by 2.  Check for a valid chroma input first
   if mod(Chroma,2) ~= 0 || Chroma < 2 || Chroma > 38	% Input chroma is not a multiple of 2
      Status.ind = 5		;
	  return;
   end
   ChromaIndex = Chroma/2	;
end

x = ExtrapolatedRenotationMatrices.x(HueIndex, ValueIndex, ChromaIndex);
y = ExtrapolatedRenotationMatrices.y(HueIndex, ValueIndex, ChromaIndex);
Y = ExtrapolatedRenotationMatrices.Y(HueIndex, ValueIndex, ChromaIndex);

% Check that the input colour is within MacAdam limits, as defined by Munsell renotation data
if isnan(x) || isnan(y) || isnan(Y)
   Status.ind = 2		;
   return;
end

% Set successful status return code and return
Status.ind = 1;
return; 