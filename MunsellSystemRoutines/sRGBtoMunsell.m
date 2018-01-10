function [MunsellSpec, MunsellVec, InMacAdamLimitsFlag, Status] = sRGBtoMunsell(sRGB);
% Purpose		Convert sRGB coordinates into the Munsell system.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma (C), in the form H V/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R 9.0/2.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				The 1943 Munsell renotation ([Newhall1943]) expressed Munsell specifications
%				in terms of CIE coordinates.  The Munsell renotation was later updated
%				in [ASTMD1535-08].	Table I of [Newhall1943] lists CIE coordinates for
%				different combinations of H, V, and C.  These data allow conversions from
%				Munsell specifications to CIE coordinates, and vice versa.
%
%				sRGB is a specification for colour monitors.  It specifies the CIE chromaticities
%				and relative luminances of the three primaries: red (R), green (G), and 
%				blue (B).  The sRGB standard also specifies how to calculate R, G, and B
%				values from a given set of CIE coordinates, and vice versa.  
%
%				Since both Munsell notations and sRGB coordinates can be converted to
%				CIE coordinates, it is possible to convert between Munsell and sRGB, going
%				by way of CIE, which is the path this routine takes.  The results should be
%				interpreted with caution, however, because a colour perception involves not
%				just a colour stimulus itself, but also the ambient illumination.  The CIE
%				coordinates for the Munsell renotation are valid when the power spectral
%				density (PSD) of the ambient illumination is given by Illuminant C.  The CIE
%				coordinates for the sRGB system are valid when the PSD is Illuminant D65.
%
%				This difficulty can be finessed, by viewing the monitor under Illuminant C.
%				A given Munsell colour will be converted (by the Renotation) to CIE 
%				coordinates.  When viewed under Illuminant C, any monitor stimulus that has those
%				CIE coordinates will match the original Munsell colour.  If some other
%				illuminant were used, then, because of chromatic adaptation, those CIE 
%				coordinates might not match the original Munsell colour.  A side effect of
%				this adjustment is that the sRGB colours will not have their usual
%				interpretations.  For example, a stimulus where R=G=B is usually considered
%				a neutral grey, because the primaries were chosen to make the white point
%				(R=G=B=max) agree with the chromaticity of the D65 white point.  Under
%				Illuminant C, a stimulus where R=G=B will appear not quite neutral.  sRGB
%				colours (e.g. R=125, G= 121, B=127) can appear neutral, however.  The Munsell
%				notation, for an input sRGB, is the Munsell colour that that sRGB will
%				produce, when displayed on a monitor viewed under Illuminant C.
%				
%				[ASTMD1535-08] ASTM, Standard D 1535-08, "Standard Practice for Specifying Color by the
%					Munsell System," approved January 1, 2008.
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		[MunsellSpec, MunsellVec, InMacAdamLimitsFlag, Status] = sRGBtoMunsell(sRGB)
%
%				sRGB			Input sRGB coordinates (0 <= R,G,B <= 255)
%	
%				MunsellSpec		A standard Munsell specification, such as 4.2R 8.1/5.3
%
%				MunsellVec		A Munsell vector in ColorLab format, such as [5 3 6 7]
%
%				InMacAdamLimitsFlag		TRUE if the sRGB input can exist as a surface colour,
%								FALSE otherwise
%	
%				Status			A return code with two fields.  The first field is a list
%								of possible return messages.  The second field is a positive
%								integer indicating one of the return messages.  This status code is used
%								to indicate when the Munsell specification exceeds the extrapolated
%								renotation data, or is otherwise invalid, so that it cannot be converted
%								to CIE coordinates.
%
% Related		MunsellTosRGB
% Functions
%
% Required		xyYtoMunsell, XYZ2xyY, srgb2xyz
% Functions		
%
% Author		Paul Centore (April 13, 2013)
%
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
%
% Copyright 2013 Paul Centore
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

% Make list of possible status return messages
Status.Messages = {'Success',...
                   'sRGB input beyond MacAdam limits',...
				   'Failure in call to Munsell conversion' ...
				   };
% Assign default values
MunsellSpec         = '-99'	;
MunsellVec          = [-99]	;
InMacAdamLimitsFlag = -99	;
Status.ind          = -99	;

% Convert sRGB input into CIE XYZ and xyY coordinates
[XYZ] = srgb2xyz(sRGB)	;
X = XYZ(1)	;
Y = XYZ(2)	;
Z = XYZ(3)	;
[x, y, Y] = XYZ2xyY(X, Y, Z)	;

% For convenience, return that a blank screen is ideal black
if max([x y Y]) == 0	
    MunsellSpec         = 'N0'	;
	MunsellVec          = [0]	;
	InMacAdamLimitsFlag = true	;
    Status.ind          = 1		;
	return						;
end

% Convert CIE coordinates to Munsell coordinates
[MunsellSpec MunsellVec MunsellConversionStatus] = xyYtoMunsell(x, y, 100*Y);

% Check whether CIE coordinates are outside MacAdam limits, so no conversion to Munsell is possible 
if MunsellConversionStatus.ind == 4		  
    Status.ind          = 2		;          
	InMacAdamLimitsFlag = false	;
	return						;
% Check whether other reasons caused the conversion to fail
elseif MunsellConversionStatus.ind == 2 || MunsellConversionStatus.ind == 3
    Status.ind          = 3		;
	return						;
end

% Since none of the error conditions hold, the conversion was successful
InMacAdamLimitsFlag = true	;
Status.ind          = 1		;
return						; 