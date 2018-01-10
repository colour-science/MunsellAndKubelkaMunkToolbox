function [MunsellSpecString, HueString] = ColorLabFormatToMunsellSpec(ColorLabMunsellVector,...
                                                         HueDecimals,...
														 ValueDecimals,...
														 ChromaDecimals);
% Purpose		Convert the ColorLab form of a Munsell colour into a standard 
%				Munsell specification.
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
%				Routines in ColorLab use the Munsell specifications, but not necessarily the
%				Munsell notation H V/C.  A Munsell vector is given by [H1, V, C, H2], where 
%				H1 is the number designator for hue, H2 is the position of the hue letter 
%				designator in the list
%				                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
%				V is the Munsell value, and C is the Munsell chroma. For example, 
%				5.0R 9.0/4.0 is [5 9 4 7] in ColorLab
%				format.  A neutral Munsell grey is a one-element vector in ColorLab
%				format, consisting of the grey value.  For example, N4 is [4] in ColorLab
%				format.  It is also possible for a Munsell grey to be of the form
%				[H1 V 0 H2], indicating that there is no chroma.
%
%				The user can input the number of decimal places for the hue, value, and
%				chroma components of the specification.  The hue string is returned as a
%				separate output, so that it can be used on its own.
%
% Syntax		[MunsellSpecString, HueString] = ColorLabFormatToMunsellSpec(ColorLabMunsellVector,...
%                                                        HueDecimals,...
%														 ValueDecimals,...
%														 ChromaDecimals);
%
%				ColorLabMunsellVector	Either a one- or four-element vector consisting of
%								Munsell data, as described above.
%
%				HueDecimals, ValueDecimals, ChromaDecimals	The number of decimal places in
%								the hue, value, and chroma specifications, respectively
%
%				MunsellSpecString		A standard Munsell specification, such as 5R 9/4.
%
%				HueString	A Munsell hue notation, such as 7.5R or 3.19GY, as a character string
%				
% Related		MunsellSpecToColorLabFormat
% Functions
%
% Required		
% Functions		
%
% Author		Paul Centore (May 15, 2010)
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (April 10, 2013)  
%				 ---Made the number of decimal places a user input.
%				 ---Corrected handling of ColorLab vectors with 0 chroma
%				 ---Made a string for hue an additional, separate output
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
%
% Copyright 2010, 2012, 2013 Paul Centore
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

if length(ColorLabMunsellVector) ~= 1 && length(ColorLabMunsellVector) ~= 4
   disp(['ERROR: A ColorLab Munsell vector must have either 1 or 4 elements.']);
   return
end

% If the user does not specify how many decimal places to use for each component, use
% a default of 2 for all components
if ~exist('HueDecimals')
    HueDecimals = 2			;
end
if ~exist('ValueDecimals')
    ValueDecimals = 2		;
end
if ~exist('ChromaDecimals')
    ChromaDecimals = 2		;
end

if length(ColorLabMunsellVector) == 1		% Achromatic colour of form [V]
   if ValueDecimals == 0		% Avoid printing space between 'N' and value
       MunsellSpecString = sprintf(['N%0.0f'], ColorLabMunsellVector(1));
   else							% Print input number of decimals
       MunsellSpecString = sprintf(['N%',num2str(ValueDecimals+2),'.',num2str(ValueDecimals),'f'],...
                                 ColorLabMunsellVector(1));
   end
   HueString = 'N'	;
elseif ColorLabMunsellVector(3) == 0		% Achromatic colour, of form [H1 V 0 H2]
   if ValueDecimals == 0		% Avoid printing space between 'N' and value
       MunsellSpecString = sprintf(['N%0.0f'], ColorLabMunsellVector(2));
   else							% Print input number of decimals
       MunsellSpecString = sprintf(['N%',num2str(ValueDecimals+2),'.',num2str(ValueDecimals),'f'],...
                                 ColorLabMunsellVector(2));
   end
   HueString = 'N'	;
else										% Chromatic colour
   % Construct the complete output string as a concatenation of a hue string, a value string, and
   % a chroma string.

   % The fourth element of the ColorLab vector refers to a colour letter designator:
   ColourLetters = {'B', 'BG', 'G', 'GY', 'Y', 'YR', 'R', 'RP', 'P', 'PB'};
   if HueDecimals == 0			% Avoid unwanted spaces in final output
       HueString = sprintf(['%0.0f'], ColorLabMunsellVector(1));       
   else
       HueString = sprintf(['%',num2str(HueDecimals+2),'.',num2str(HueDecimals),'f'],...
                    ColorLabMunsellVector(1))							;
   end
   HueString = [HueString,ColourLetters{ColorLabMunsellVector(4)}]	;
	     
   if ValueDecimals == 0		% Avoid unwanted spaces in final output
       ValueString = sprintf(['%0.0f'], ColorLabMunsellVector(2));
   else
       ValueString  = sprintf(['%',num2str(ValueDecimals+2),'.',num2str(ValueDecimals),'f'],...
                    ColorLabMunsellVector(2))							;
   end
   
   if ChromaDecimals == 0		% Avoid unwanted spaces in final output
       ChromaString = sprintf(['%0.0f'], ColorLabMunsellVector(3));
   else
       ChromaString = sprintf(['%',num2str(ChromaDecimals+2),'.',num2str(ChromaDecimals),'f'],...
                    ColorLabMunsellVector(3))							;
   end

   % Combine the component strings into one final string
   MunsellSpecString = [HueString,' ',ValueString,'/',ChromaString]		;
end
return