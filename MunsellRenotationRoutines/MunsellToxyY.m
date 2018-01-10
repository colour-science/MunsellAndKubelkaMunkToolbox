function [x y Y Status] = MunsellToxyY(MunsellSpec);
% Purpose		Convert a Munsell specification into xyY coordinates, by interpolating
%				over the extrapolated Munsell renotation data.  Because extrapolated data
%				are used, this routine might return xyY coordinates even when MunsellSpec
%				is beyond the MacAdam limits.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma (C), in the form HV/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R9.0/4.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				The Commission Internationale de l'Eclairage (CIE) uses a different system
%				for specifying colours.  In their system, standardized in 1931,
%				a coloured light source is specified by three coordinates: x, y, and Y.
%				The coordinate Y gives a colour's luminance factor, or relative luminance.  
%				When expressed as a number between 0 and
%				100, Y is the intensity of the source as a percentage of some
%				maximum intensity.  This percentage is calculated with regard to the
%				human photopic luminous efficiency function, which has been established
%				as part of the CIE 2 degree standard observer.  When dealing with
%				physical samples such as paints, Y is the percentage of a fixed light
%				source that a paint sample reflects (with regard to the standard 
%				observer).  
%
%				The coordinates x and y are chromaticity coordinates.  While Y
%				indicates how light or dark a colour is, x and y
%				indicate hue and chroma.  For example, the colour might be saturated red,
%				or a dull green.  The CIE chromaticity diagram ([Foley1990, Sect. 13.2.2]) displays 
%				all chromaticities that are possible for physical samples of a fixed
%				luminance factor.
%
%				There is a conceptual difficulty in converting between Munsell specifications
%				and CIE coordinates.  The difficulty occurs because the Munsell system
%				applies to local colours, which are defined by spectral reflectance
%				functions, and CIE coordinates apply to coloured lights, which are defined
%				by spectral power distributions (SPD).  The 1943 Munsell renotation ([Newhall1943])
%				bridged this gap by fixing Illuminant C as a light source,
%				that illuminates the local colour.  The local colour is specified in the
%				Munsell system, and the light reflecting off the local colour is analyzed
%				in terms of CIE coordinates.  The Y value is the percentage of light,
%				originally of an Illuminant C SPD, that the local colour reflects, 
%				measured in terms of the CIE standard observer.  The x and y chromaticity
%				coordinates can also be found for the reflected light.
%
%				The 1943 Munsell renotation ([Newhall1943]) expressed Munsell specifications
%				in terms of CIE coordinates.  The Munsell renotation was later updated
%				in [ASTMD1535-08].	Table I of [Newhall1943] lists CIE coordinates for
%				different combinations of H, V, and C.  The file all.dat from [MCSL2010]
%				extrapolates to further combinations, some of them imaginary.  For these samples, 
%				the conversion to xyY coordinates is a straightforward calculation.  The samples 
%				have integer value specifications, even chroma specifications, and hue
%				specifications prefixed by 2.5, 5.0, 7.5, or 10.  It is 
%				desired to find the xyY coordinates for Munsell specifications that are
%				intermediate to these samples.  This routine interpolates between xyY
%				coordinates for the available data samples, to find xyY coordinates for
%				Munsell specifications for which no renotation data is available.
%
%				The interpolation uses the empirically verified fact that the luminance factor
%				Y is a function solely of the Munsell value, and vice versa.  Therefore,
%				a Munsell section through a fixed value is mapped bijectively to the
%				chromaticity diagram for the corresponding luminance factor ([Newhall1943, Figs. 1 to 9]; 
%				reproduced with some modifications in [Agoston1987, Figs. 12.1 to 12.9]). 
%
%				The interpolation scheme first finds two Munsell colours of integer values
%				that bound the input Munsell colour immediately.  For example, 4B6.3/7 would
%				be bounded between 4B6/7 and 4B7/7.  The x and y coordinates of the
%				input Munsell colour are then found by linear interpolation on the x and y
%				coordinates of the bounding colours, over the luminance
%				factors.  The problem is thereby reduced to finding
%				x and y coordinates for Munsell colours of integer value, which is performed
%				by the routine MunsellToxyForIntegerMunsellValue.
%
%				For a detailed discussion and description of the interpolation algorithm,
%				see [Centore2011].
%
%				[Agoston1987] G. A. Agoston, Color Theory and Its Application in Art
%					and Design, 2nd ed., Springer Series in Optical Science, vol. 19,
%					Springer-Verlag, 1987.
%				[ASTMD1535-08] ASTM, Standard D 1535-08, "Standard Practice for Specifying Color by the
%					Munsell System," approved January 1, 2008.
%				[Centore2011] Paul Centore, "An Open-Source Inversion for the Munsell
%					Renotation," 2011, unpublished (currently available at centore@99main.com/~centore).
%				[Agoston1987] G. A. Agoston, Color Theory and Its Application in Art
%					and Design, 2nd ed., Springer Series in Optical Science, vol. 19,
%					Springer-Verlag, 1987.
%				[ASTMD1535-08] ASTM, Standard D 1535-08, "Standard Practice for Specifying Color by the
%					Munsell System," approved January 1, 2008.
%				[Foley1990] James D. Foley, Andries van Dam, Steven K. Feiner, & John
%					F. Hughes, Computer Graphics: Principles and Practice, 2nd ed.,
%					Addison-Wesley Publishing Company, 1990.
%				[MCSL2010] http://www.cis.rit.edu/mcsl/online/munsell.php, as of June 12, 2010
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
%
% Syntax		[x y Y Status] = MunsellToxyY(MunsellSpec);
%
%				MunsellSpec		Either a standard Munsell specification, such as 4.2R8.1/5.3,
%								or a Munsell vector in ColorLab format
%
%				[x y Y]			CIE coordinates of MunsellSpec, when
%								illuminated by Illuminant C
%	
%				Status			A return code with two fields.  The second field is a list
%								of possible return messages.  The first field is a positive
%								integer indicating one of the return messages.  
%
% Related		xyYtoMunsell
% Functions
%
% Required		MunsellSpecToColorLabFormat, MunsellToxyForIntegerMunsellValue,
% Functions		MunsellValueToLuminanceFactor
%
% Author		Paul Centore (June 13, 2010)
% Revised by	Paul Centore (Jan. 5, 2011)
% Revisions:	Previouly Y was calculated in accordance with [Newhall1943].  In the revision,
%					Y is calculated in accordance with [ASTMD1535-08].
%				Allowed Munsell values to go to 10, rather than just to 9
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (April 13, 2013)  
%				 ---Corrected handling of failure message from MunsellToxyForIntegerMunsellValue.
% Revision		Paul Centore (April 26, 2014)  
%				 ---Added a check that the numerical hue prefix is between 0 and 10.
% Revision		Paul Centore (August 29, 2014)  
%				 ---The numerical hue prefix is now only checked when the input colour is not
%				    a neutral grey (bug pointed out by Thomas Mansencal).
% Revision		Paul Centore (Feb. 6, 2017)  
%				 ---Replaced some conditional operators | with ||, to avoid short-circuit warnings
%
% Copyright 2010-2017 Paul Centore
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
                   ['Input beyond extrapolated renotation data.'],...
				   'Value must be between 1 and 10',...
				   };
% Assign default values
x          = -99;
y          = -99;
Y          = -99;
Status.ind = -99;

% Assign a difference threshold for Munsell value.  If the value is within this much of
% an integer, it will be rounded to that integer.
ValueDifferenceThreshold = 0.001	;	

% The input could be either a Munsell string, such as 4.2R8.1/5.3,
% or a Munsell vector in ColorLab format.  Determine which, and convert
% to ColorLab format, if needed.
if ischar(MunsellSpec)
   ColorLabMunsellVector = MunsellSpecToColorLabFormat(MunsellSpec)	;	
else
   ColorLabMunsellVector = MunsellSpec	;
end

% Extract hue, chroma, and value from ColorLab Munsell vector that corresponds
% to input.
if length(ColorLabMunsellVector) == 1		% Colour is Munsell grey
   Value = ColorLabMunsellVector(1)			;
else
   HueNumber     = ColorLabMunsellVector(1)		;
   Value         = ColorLabMunsellVector(2)		;
   Chroma        = ColorLabMunsellVector(3)		;
   HueLetterCode = ColorLabMunsellVector(4)		;
end

% Calculate Y directly from the Munsell value, in accordance with [ASTMD153508].
LuminanceFactors = MunsellValueToLuminanceFactor(Value)	;	
Y                = LuminanceFactors.ASTMD153508			;	

% Check that the Munsell value is between 1 and 10, which are the limits of the
% renotation data.
if Value < 1 || Value > 10
   Status.ind = 3;		% Set error and return
   return
end

% Additional error check added by Paul Centore on April 26, 2014
% Check that the Munsell hue prefix is between 0 and 10, which are the limits of the
% Munsell system.
if exist('HueNumber') % This variable was not set for greys, so do not check it (line
					  % added by Paul Centore on August 29, 2014)
	if HueNumber < 0 || HueNumber > 10
	   Status.ind = 3;		% Set error and return
	   return
	end
end

% Bound Munsell value between two integer values, ValueMinus and ValuePlus, for which Munsell
% renotation data are available.  
% If the input value is very close to an integer, then assume it is an integer,
% and let the bounding values both be that integer
if abs(Value - round(Value)) < ValueDifferenceThreshold
   ValueMinus = round(Value)		;
   ValuePlus  = round(Value)		;
else
   ValueMinus = floor(Value)		;
   ValuePlus  = ValueMinus + 1		;
end

% Calculate xy co-ordinates for two Munsell samples.  The first sample is the input
% sample, with the input value changed to ValueMinus.  The second sample is the input
% sample, with the input value changed to ValuePlus.  The xy co-ordinates for the input
% sample will then be found by linearly interpolating between the xy co-ordinates for
% the two new samples.  
if length(ColorLabMunsellVector) == 1		% Colour is Munsell grey
   ColorLabVecMinus = [ValueMinus]	;
else
   ColorLabVecMinus = [HueNumber,ValueMinus,Chroma,HueLetterCode];
end
[xminus yminus StatusCode] = MunsellToxyForIntegerMunsellValue(ColorLabVecMinus); 
if StatusCode.ind ~= 1	% No reflectance data available for bounding colour.  Set error code and return
   Status.ind = 2;
   return;
end
if length(ColorLabMunsellVector) == 1		% Colour is Munsell grey
   ColorLabVecPlus = [ValuePlus]	;
elseif ValuePlus == 10						% Colour with upper bounding value is ideal white
   ColorLabVecPlus = [ValuePlus]	;
else
   ColorLabVecPlus = [HueNumber,ValuePlus,Chroma,HueLetterCode]; 
end
[xplus yplus   StatusCode] = MunsellToxyForIntegerMunsellValue(ColorLabVecPlus);  
if StatusCode.ind ~= 1	% No reflectance data available for bounding colour.  Set error code and return
   Status.ind = 2;
   return;
end

% Interpolate between the xy coordinates for the lighter and darker Munsell samples
if ValueMinus == ValuePlus
   x = xminus	;
   y = yminus	;
else
   LuminanceFactors = MunsellValueToLuminanceFactor(ValueMinus)	;
   YMinus           = LuminanceFactors.ASTMD153508				;
   LuminanceFactors = MunsellValueToLuminanceFactor(ValuePlus)	;
   YPlus            = LuminanceFactors.ASTMD153508				;
   x = interp1([YMinus YPlus], [xminus xplus], Y)				;
   y = interp1([YMinus YPlus], [yminus yplus], Y)				;
   % The following option can be used to test interpolating over value vs interpolating
   % over luminance factor
   if false		% Interpolate over value instead of over luminance factor
      x = interp1([ValueMinus ValuePlus], [xminus xplus], Value)	;
      y = interp1([ValueMinus ValuePlus], [yminus yplus], Value)	;
   end
end

% Set successful status return code and return
Status.ind = 1;
return; 