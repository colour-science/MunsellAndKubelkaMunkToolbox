function [FormattedMunsellSpec, HueString] = FormatMunsellSpec(MunsellSpecString, ...
																 HueDecimals,...
																 ValueDecimals,...
																 ChromaDecimals);

% Purpose		Format a Munsell specification to display a certain number of decimal 
%				places in its hue prefix, value, and chroma.
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
%				This routine formats a Munsell specification so that there is a certain
%				number of decimal places in the numerical entries.  For example, 5.76R 9.35/2.76
%				might become 5.8R 9.4/2.8, if only one decimal place is desired.  Although
%				all three numbers will likely have the same number of decimal places, the
%				routine provides the option of more or fewer decimal places for
%				different numbers.
%
%				The hue string is returned as a	separate output, so that it can be used on its own.
%
%				MunsellSpecString	A Munsell specification, such as 5R 9/4.
%
%				HueDecimals, ValueDecimals, ChromaDecimals	The number of decimal places in
%								the hue, value, and chroma specifications, respectively
%		
%				HueString	A Munsell hue notation, such as 7.5R or 3.19GY, as a character string
%	
% Author		Paul Centore (April 3, 2015)
%
% Copyright 2015 Paul Centore
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

% A routine has already been written which formats a Munsell specification which is given
% in ColorLab format.  Convert the input Munsell specification to ColorLab format, and
% then call the existing routine to format the specification and extract the hue string.
ColorLabMunsellVector             = MunsellSpecToColorLabFormat(MunsellSpecString);
[FormattedMunsellSpec, HueString] = ColorLabFormatToMunsellSpec(ColorLabMunsellVector,...
                                                         HueDecimals,...
														 ValueDecimals,...
														 ChromaDecimals);