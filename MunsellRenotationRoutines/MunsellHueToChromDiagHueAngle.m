function ChromDiagHueAngle = MunsellHueToChromDiagHueAngle(HueNumber,HueLetterCode);
% Purpose		The Munsell specification for hue involves both a letter code (such as R or BG),
%				and a numerical modifier.  For ease of calculation, it is often more
%				convenient to express the Munsell hue as a single number.  Since the hues
%				naturally form a circle, the number is thought of as an angle between 0 and 360.
%				This routine converts from the Munsell hue specification to a single hue angle.
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
%				5.0R9.0/4.0 is [5 9 4 7] in ColorLab format.  The arguments HueNumber and
%				HueLetterCode in this routine correspond to H1 and H2, respectively.
%
%				It is natural to make the Munsell hues into a circle, with PB being followed
%				by B.  In the CIE chromaticity diagram ([Foley1990, Sect. 13.2.2]),
%				the hues also follow an approximate
%				circle, centered on an achromatic point.  The hue R is at the 
%				right of the achromatic point.  In mathematical polar coordinates, (r, theta),
%				the angle theta is 0 to the right of the origin, and measured counterclockwise.
%				For consistency with this convention, 5R is assigned a hue angle of 0.  To be 
%				consistent with the CIE chromaticity diagram, the hues run counterclockwise
%				from R to Y to G to B, and back to R again, with the following angle 
%				assignments:
%											5R		0
%											5Y		90
%											5G		180
%											5B		270
%											5P		315
%								  (5-epsilon)R		360 - f(epsilon).
%				The difference f(epsilon) is arbitrary, but consistent with the angle scheme.
%
%				The angle scheme used in this routine is an approximation representation of
%				hues as they appear in the CIE chromaticity diagram.  This scheme should
%				not be confused with the CIELAB hue angle, with which it disagrees, nor be
%				interpreted as a perceptual difference system.
%
%				[Foley1990] James D. Foley, Andries van Dam, Steven K. Feiner, & John
%					F. Hughes, Computer Graphics: Principles and Practice, 2nd ed.,
%					Addison-Wesley Publishing Company, 1990.
%
% Syntax		ChromDiagHueAngle = MunsellHueToChromDiagHueAngle(HueNumber,HueLetterCode);
%
%				HueNumber		A number greater than 0, and less than or equal to 10, that
%								is prefixed to a hue descriptor in the list
%								{B, BG, G, GY, Y, YR, R, RP, P, PB}, in the Munsell system.
%
%				HueLetterCode	An integer between 1 and 10, corresponding to an element in
%								the list {B, BG, G, GY, Y, YR, R, RP, P, PB}.
%
%				ChromDiagHueAngle	An angle between 0 and 360 degrees, measured counter-
%								clockwise from the right on the CIE chromaticity diagram.

%
% Related		ChromDiagHueAngleToMunsellHue
% Functions
%
% Required		
% Functions		
%
% Author		Paul Centore (June 6, 2010)
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

% As an intermediate step, the Munsell hues, e.g. 5.8R, 3.1BG, etc., are mapped between
% 0 and 10.  The mapping is in the reverse order to the list {B, BG, G, GY, Y, YR, R, RP, P, PB}. 
% The following representations are used:
%				5R		0.0 (which is equivalent to 10 mod 10)
%			10R/0YR		0.5
%			   5YR		1.0
%			10YR/0Y		1.5
%				5Y		2.0
%			10Y/0GY		2.5
%			   5GY		3.0
%			10GY/0G		3.5
%				5G		4.0
%			10G/0BG		4.5
%			   5BG		5.0
%			10BG/0B		5.5
%				5B		6.0
%			10B/0PB		6.5
%			   5PB		7.0
%			10PB/0P		7.5
%				5P		8.0
%			10P/0RP		8.5
%			   5RP		9.0
%			10RP/0R		9.5
SingleHueNumber = mod(mod(17-HueLetterCode,10) + (HueNumber/10) - 0.5, 10);

% The intermediate hue number, between 0 and 10, is mapped to a temporary hue angle,
% as follows:
%				0		0
%				2		45
%				3		70
%				4		135
%				5		160
%				6		225
%				8		255
%				9		315
%			   10		360
ChromDiagHueAngle = interp1([0,2,3,4,5,6,8,9,10], [0,45,70,135,160,225,255,315,360], SingleHueNumber);
return