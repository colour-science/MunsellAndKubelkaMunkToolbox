function [HuePrefix, HueLetter] = HuePrefixAndLetterFromHueString(HueString);
% Purpose		Break a Munsell hue string, such as 2.5RP, into a numerical prefix (in this
%				case, 2.5) and a hue letter designator (in this case, RP).
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma (C) in the form H V/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R 9.0/2.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				To manipulate Munsell specifications, this routine separates the hue part of
%				a Munsell specification into its numerical prefix and its letter part.  For
%				example, 7.5BG would be separated into 7.5 and BG.  The prefix and letter 
%				part are returned.  If the colour is neutral, then
%				its hue letter is N, and the hue prefix is returned as NaN.
%
%				HueString	A Munsell hue notation, such as 7.5R or 3.19GY, as a character string
%				
%				HuePrefix	The numerical part of a Munsell hue string
%
%				HueLetter	The letter (or letters) that make up a Munsell hue string
%
% Author		Paul Centore (July 22, 2015)
%
% Copyright 2015, Paul Centore
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

% Normalize the input hue string by making all letters uppercase, and removing all blanks
NormalizedHueString = upper(HueString)				;
NormalizedHueString(NormalizedHueString==' ') = ''	;

% Check whether the hue string is for a neutral colour
if strcmp(NormalizedHueString,'N')
	% If the colour is neutral, then the numerical prefix is undefined, and the hue letter
	% is just N.  Make these assignments and return
	HuePrefix = NaN	;
	HueLetter = 'N'	;
else	% The colour is not neutral, so there is a hue prefix
	% The string begins with digits (or a decimal point).  Read through the string until
	% all the digits and decimal points have been found
	AllDigitsAndDecimalPointsFound = false	;
	PositionCtr = 1							;
	while ~AllDigitsAndDecimalPointsFound
		if isalpha(NormalizedHueString(PositionCtr)) 
			AllDigitsAndDecimalPointsFound = true	;
		else
			PositionCtr = PositionCtr + 1			;	
		end
	end
	HuePrefix = str2num(NormalizedHueString(1:(PositionCtr-1)))		;
	HueLetter = NormalizedHueString(PositionCtr:end)				;
end	