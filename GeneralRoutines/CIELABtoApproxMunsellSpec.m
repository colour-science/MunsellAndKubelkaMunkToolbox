function [MunsellSpec] = CIELABtoApproxMunsellSpec(L, Cab, hab);
% Purpose		Convert a CIELAB specification to an approximate Munsell specification. 
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C), in the form HV/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R9.0/4.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				The CIELAB ([Fairchild2005], Section 10.3) model is another colour
%				system.  It uses coordinates L* (corresponding to Munsell value), C*ab
%				(corresponding to Munsell chroma), and a hue angle hab (corresponding to
%				Munsell hue).
%
%				This routine makes a rough conversion from a CIELAB specification to a
%				Munsell specification.  L* is just 10 times the Munsell value.  
%
%				The CIELAB hue angle, which varies between 0 and 360 degrees, is converted
%				into a Munsell hue specification, such as 2.5RP, or 6.3G.  The
%				conversion is approximate: if one started with a Munsell sample, calculated
%				the xyY coordinates when illuminated by Illuminant C, entered this data 
%				into the CIELAB model to produce L*, C*ab, and hab, and then converted back
%				to the Munsell system, the resulting Munsell specification would not agree
%				exactly with the Munsell specification of the original sample.
%
%				Nevertheless, the agreement is good enough for most practical purposes.
%				Figure 10.4 of [Fairchild2005] plots some Munsell samples in terms of their
%				CIELAB coordinates.  Ideally, the ten hue designators should be evenly spaced
%				in terms of their hue angle, with no dependency on chroma or value.  In
%				Figure 10.4, that ideal situation is nearly achieved.
%
%				This routine uses Figure 10.4 as a guide to converting from hab to Munsell
%				hue.  That figure shows that yellow occurs at hab = 90 deg, so 5Y, the 
%				yellowest of the yellow hues, is set to correspond to 90 deg.  The other
%				nine hues are assumed to be evenly spaced around the circle, in a 
%				counterclockwise direction.  This arrangement is sufficient to define
%				the transformation from hab to Munsell hue.
%
%				Finally, Munsell chroma is taken to be 1/5 of C*ab.  This
%				is a crude approximation, but the best available so far ([MCSL2010],
%				Question #696).  
%
%				[Fairchild2005] Mark D. Fairchild, Color Appearance Models, 2nd ed.,
%					John Wiley & Sons, Ltd., 2005.
%				[MCSL2010] Munsell Color Science Laboratory website, accessed May 31, 2010,
%					http://www.cis.rit.edu/mcsl/outreach/faq.php?catnum=5#696.
%
% Syntax		[MunsellSpec] = ApproxMunsellSpecFromCIELAB(L, Cab, hab);
%
%				MunsellSpec		A standard Munsell specification, such as 4.2R8.1/5.3.
%
%				L				The CIELAB variable L*, denoting lightness.
%	
%				Cab				The CIELAB variable C*ab, corresponding to Munsell chroma.
%	
%				hab				The CIELAB variable hab, denoting hue angle in radians.
%	
%
% Related		
% Functions
%
% Required		ColorLabFormatToMunsellSpec
% Functions		
%
% Author		Paul Centore (May 31, 2010)
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

% Approximate Munsell hue first
% Convert hab from radians to degrees, and make sure it is between 0 and 360
habDegrees = (180/pi)*hab			;
habDegrees = mod(habDegrees, 360)	;

% The Munsell hues are assumed to be evenly spaced on a circle, with 5Y
% at 90 degrees, 5G at 162 degrees, and so on.  Each letter code corresponds
% to a certain sector of the circle.  The following cases extract the 
% letter code.
if habDegrees == 0
	HueLetterCode    = 8	;
elseif habDegrees <= 36
	HueLetterCode    = 7	;
elseif habDegrees <= 72
	HueLetterCode    = 6	;
elseif habDegrees <= 108
	HueLetterCode    = 5	;
elseif habDegrees <= 144
	HueLetterCode    = 4	;
elseif habDegrees <= 180
	HueLetterCode    = 3	;
elseif habDegrees <= 216
	HueLetterCode    = 2	;
elseif habDegrees <= 252
	HueLetterCode    = 1	;
elseif habDegrees <= 288
	HueLetterCode    = 10	;
elseif habDegrees <= 324
	HueLetterCode    = 9	;
else
	HueLetterCode    = 8	;
end

% Each letter code is prefixed by a number greater than 0, and less than
% or equal to 10, that further specifies the hue.
HueNumber = interp1([0 36], [0 10], mod(habDegrees, 36))	;
if HueNumber == 0
	HueNumber = 10	;
end

% Munsell value can be approximated very accurately with a simple division by 10
Value         = L/10				;		
% This Munsell chroma expression is a very rough approximation, but the best available
Chroma        = Cab/5				;		

% Assemble individual Munsell coordinates into one Munsell specification
ColorLabMunsellVector = [HueNumber, Value, Chroma, HueLetterCode];
MunsellSpec           = ColorLabFormatToMunsellSpec(ColorLabMunsellVector);
return