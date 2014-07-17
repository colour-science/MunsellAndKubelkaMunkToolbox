function HueString = HueStringFromMunsellSpec(MunsellSpecString, NumberOfDecimalPlaces);
% Purpose		Extract the hue string from a Munsell specification. 
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form H V/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R 9.0/2.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				This routine extracts the Munsell hue, as a character string, from a complete
%				Munsell specification, which is also input as a string.  The hue string 
%				would be, for example, 8.5BG or 2.03Y.  The number of decimal places is a
%				user input.
%
% Syntax		HueString = HueStringFromMunsellSpec(MunsellSpecString, NumberOfDecimalPlaces);
%
%				MunsellSpecString		A standard Munsell specification, such as 5R 9/4.  Spaces 
%								are not required; 5R9/4 is also acceptable.
%
%				NumberOfDecimalPlaces	The number of decimal places in the hue string
%
%				HueString	A Munsell hue notation, such as 7.5R or 3.19GY, as a character string
%				
% Required		MunsellSpecToColorLabFormat, ColorLabFormatToMunsellSpec
% Functions		
%
% Author		Paul Centore (April 10, 2013)
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (January 19, 2014)  
%				 ---Changed comment under Purpose heading.
%
% Copyright 2013, 2014 Paul Centore
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

% Default to one decimal place if the user does not specify the number of decimal places
if ~exist('NumberOfDecimalPlaces')
    NumberOfDecimalPlaces = 1		;
end

% Convert the Munsell specification string into ColorLab format.
% Routines in ColorLab use the Munsell specifications, but not necessarily the
% Munsell notation HV/C.  A Munsell vector is given by [H1, V, C, H2], where 
% H1 is the number designator for hue, H2 is the position of the hue letter 
% designator in the list
%                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
% V is the Munsell value, and C is the Munsell chroma. For example, 
% 5.0R 9.0/4.0 is [5 9 4 7] in ColorLab
% format.  A neutral Munsell grey is a one-element vector in ColorLab
% format, consisting of the grey value.  For example, N4 is [4] in ColorLab
% format.  It is also possible for a Munsell grey to be of the form
% [H1 V 0 H2], indicating that there is no chroma.
ColorLabMunsellVector = MunsellSpecToColorLabFormat(MunsellSpecString);

% Extract the hue string directly from the Munsell vector in ColorLab format
[~, HueString] = ColorLabFormatToMunsellSpec(ColorLabMunsellVector,...
                                             NumberOfDecimalPlaces,...
											 0,...
											 0);
return