function [ClockwiseHue, CtrClockwiseHue] = BoundingRenotationHues(CLHueNumPrefix, CLHueLetterIndex);
% Purpose		For an input hue, such as 2.9GY, find the two immediately bounding hues, in
%				this example 2.5GY and 5GY, for which renotation data is available. 
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form HV/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R9.0/4.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				Routines in ColorLab use the Munsell specifications, but not necessarily the
%				Munsell notation HV/C.  A Munsell vector is given by [H1, V, C, H2], where 
%				H1 is the number designator for hue, H2 is the position of the hue letter 
%				designator in the list
%				                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
%				V is the Munsell value, and C is the Munsell chroma. For example, 
%				5.0R9.0/4.0 is [5 9 4 7] in ColorLab format.  
%			
%				In the CIE diagram ([Foley1990]), the hue list above wraps around a circle in
%				a counterclockwise direction.  
%
%				Since renotation data is only available when H1 is 2.5, 5, 7.5, or 10, it is
%				often convenient for interpolation to find the two Munsell hues which
%				immediately bound an input hue.  For example, the input hue 2.9GY would be
%				bounded between 2.5GY and 5GY.  This routine calculates the two bounding
%				hues, one of which is immediately clockwise from the input hue on the
%				CIE diagram, and the other of which is counterclockwise.
%
%				[Foley1990] James D. Foley, Andries van Dam, Steven K. Feiner, & John
%					F. Hughes, Computer Graphics: Principles and Practice, 2nd ed.,
%					Addison-Wesley Publishing Company, 1990.
%
% Syntax		[ClockwiseHue, CtrClockwiseHue] = BoundingRenotationHues(CLHueNumPrefix, CLHueLetterIndex);
%
%				CLHueNumPrefix,		H1 and H2 from the ColorLab format for Munsell 
%				CLHueLetterIndex	specifications, as defined above.
%
%				ClockwiseHue		The Munsell hue prefixed by 2.5, 5, 7.5, or 10, that is
%									immediately clockwise from the input hue, in the CIE diagram.
%
%				CtrClockwiseHue		The Munsell hue prefixed by 2.5, 5, 7.5, or 10, that is
%									immediately counterclockwise from the input hue, in the CIE diagram.
%
% Related		ColorLabFormatToMunsellSpec, MunsellSpecToColorLabFormat
% Functions
%
% Required		
% Functions		
%
% Author		Paul Centore (June 20, 2010)
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
%
% Copyright 2010, 2012 Paul Centore
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

% Find two hues which bound the hue of the input colour, and for which
% renotation data is available.  Renotation data is available only 
% for hues whose prefix number is 2.5, 5.0, 7.5, or 10.0.
if mod(CLHueNumPrefix, 2.5) == 0		% No interpolation needed for Munsell hue
   if CLHueNumPrefix == 0				% Convert to (0,10] from [0,10)
      CLHueNumPrefixCW = 10	;
      CLHueLetterIndexCW = mod(CLHueLetterIndex+1,10);
   else
      CLHueNumPrefixCW    = CLHueNumPrefix;
      CLHueLetterIndexCW  = CLHueLetterIndex;
   end
   CLHueNumPrefixCCW   = CLHueNumPrefixCW;
   CLHueLetterIndexCCW = CLHueLetterIndexCW;
else									% Interpolate between nearest hues
   CLHueNumPrefixCW    = 2.5 * (floor( CLHueNumPrefix/2.5))	;
   CLHueNumPrefixCCW   = mod(CLHueNumPrefixCW + 2.5, 10)	;
   if CLHueNumPrefixCCW == 0			% Put in (0 10], not [0 10)
      CLHueNumPrefixCCW = 10;
   end
   CLHueLetterIndexCCW = CLHueLetterIndex;
   
   % Switch hue letter of clockwise point, if necessary.  E.g., go from 0R to 10RP
   if CLHueNumPrefixCW == 0
      CLHueNumPrefixCW = 10	;
      CLHueLetterIndexCW = mod(CLHueLetterIndex+1,10);
	  % Wraparound from B to PB, if needed.
	  if CLHueLetterIndexCW == 0		% Put in (0 10], not [0 10)
	     CLHueLetterIndexCW = 10					;
      end
   else
      CLHueLetterIndexCW = CLHueLetterIndex		;
   end
   CLHueLetterIndexCCW = CLHueLetterIndex		;
end

ClockwiseHue    = [CLHueNumPrefixCW, CLHueLetterIndexCW];
CtrClockwiseHue = [CLHueNumPrefixCCW, CLHueLetterIndexCCW];
return