function [x y Status] = FindHueOnRenotationOvoid(MunsellSpec)
% Purpose		Convert a Munsell specification, whose value is an integer, and whose
%				chroma is a positive even integer, into xy coordinates.  The xy point
%				will be on the ovoid about the achromatic point, corresponding to the
%				input value and chroma.  Such ovoids can be seen in Figures 1 through 9
%				of [Newhall1943].
%
% Description	It is a difficult problem to convert Munsell specifications to xyY
%				coordinates, when xyY coordinates are only available for some
%				Munsell specifications.  A subtask is to convert a Munsell
%				specification of integer value and even chroma to xyY coordinates, in accordance with the
%				Munsell renotation.  The current routine performs that subtask.
%
%				The 1943 Munsell renotation ([Newhall1943]) expressed Munsell specifications
%				in terms of a color system standardized by the Commission Internationale de 
%				l Eclairage (CIE).  Table I of [Newhall1943] lists CIE coordinates for
%				different combinations of H, V, and C.  The samples in that table
%				have integer value specifications, even chroma specifications, and hue
%				specifications prefixed by 2.5, 5.0, 7.5, or 10.  Most of the entries in
%				Table I were based on spectrophotometric measurements of physical samples, whose
%				Munsell coordinates had been determined from human assessments.  
%
%				The renotation uses the empirically verified fact that relative luminance
%				Y is a function solely of the Munsell value, and vice versa.  Therefore,
%				a Munsell section through a fixed value is mapped bijectively to the
%				chromaticity diagram for the corresponding relative luminance.
%				Figs. 1 through 9 of [Newhall1943] plot the xyY coordinates for Munsell samples
%				of Values 1 through 9.  Within each figure, the lines of constant
%				chroma are ovoids around a central, achromatic point, corresponding to the
%				Munsell grey of that value.  The lines of constant hue are slightly curving 
%				lines radiating from the central point.
%				Although Figs. 1 through 9 show smooth ovoids and radials, it is important to
%				note that these lines are visually interpolated.  Only the grid points, where
%				the ovoids and radials intersect, were taken from Table I, and are thus
%				empirically tested data.  
%
%				Since the ovoids will be taken from Figs. 1 through 9, it is required that
%				the input Munsell coordinates have an integer value, and an even chroma.  The
%				input hue will either be in Table I, or be between two hues in Table I, so
%				there are no restrictions on it.  Since the output from this routine will be
%				later used in interpolation and extrapolation routines, the entries in Table I
%				have sometimes been extrapolated beyond the MacAdam limits.
%
%				Each ovoid connects the data points, corresponding to standard hues, for a set
%				integer value, and a set even chroma.  There are two natural ways to connect
%				adjacent standard hues.  The first is linear interpolation, in which a straight
%				line is used to join the two points.  The hues between the standard adjacent hues
%				are assumed to be mapped linearly:  equally spaced Munsell hue intervals are
%				separated by equal arclengths on the linear segment of the ovoid. 
%
%				A second natural approach is radial interpolation between adjacent standard
%				hues.  Radial interpolation is expressed in terms of a
%				polar coordinate system, (R, theta), about the achromatic point, where R,
%				the distance from grey, is the chroma, and each angle of theta corresponds
%				to a particular hue.  Radial interpolation is performed by linear interpolation over 
%				theta.  Suppoe a hue H is between two adjacent standard hues, H_1 and H_2, whose locations are
%				(R_1, theta_1) and (R_2, theta_2).  Then the position (R, theta) of that hue is
%				chosen such that theta_1:theta:theta_2 = H_1:H:H_2 = R_1:R:R_2. 
%			
%				The routine LinearVsRadialInterpOnRenotationOvoid is called to determine when linear 
%				interpolation is used and when radial interpolation is used.  The current routine
%				interpolates accordingly, and produces an xy pair that is on the ovoid.  
%
%				Since the results of this routine will be used for interpolation and extrapolation,
%				the Munsell renotation has been extrapolated beyond the MacAdam limits, in accordance
%				with [MCSL2010].
%
%				[MCSL2010] http://www.cis.rit.edu/mcsl/online/munsell.php, as of June 12, 2010
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		[x y Status] = MunsellToxyForIntegerMunsellValue(ColorLabMunsellVector);
%
%				MunsellSpec		Either a standard Munsell specification, such as 4.2R8.1/5.3,
%								or a Munsell vector in ColorLab format
%
%				[x y]			CIE chromaticity coordinates of the input Munsell colour,
%								when illuminated by Illuminant C
%	
%				Status			A return code with two fields.  The second field is a list
%								of possible return messages.  The first field is a positive
%								integer indicating one of the return messages.  
%
% Related		MunsellToxyY
% Functions
%
% Required		LinearVsRadialInterpOnRenotationOvoid, roo2xy
% Functions		
%
% Author		Paul Centore (Dec. 31, 2010)
% Revision   	Paul Centore (May 8, 2012)
%					---Changed != to ~= so that code would work in both Matlab and Octave.
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (Jan. 1, 2014)  
%				 ---Replaced call to IlluminantCWhitePoint with call to roo2xy (from OptProp).
% Revision		Paul Centore (Aug. 18, 2015)  
%				 ---Moved hue threshold to its own line, and added explanation.
% Revision		Paul Centore (February 11, 2017)  
%				 ---Replaced | with || to avoid short-circuit warnings
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
				   'Value must be integer between 1 and 10',...
				   'Chroma must be positive, even integer',...
				   'Could not determine type of interpolation',...
				   'Could not evaluate',...
				   };
% Assign default output values
x          = -99;
y          = -99;
Status.ind = -99;

% Set a threshold for hue.  If an input hue is within this distance of a standard hue
% (one prefixed by 0, 2.5, 5, 7.5, or 10), it will be rounded to that standard hue
threshold = 0.000000001;		% 0.001 was used before August 2015

% The input could be either a Munsell string, such as 4.2R8.1/5.3,
% or a Munsell vector in ColorLab format.  Determine which, and convert
% to ColorLab format, if needed.
if ischar(MunsellSpec)
   ColorLabMunsellVector = MunsellSpecToColorLabFormat(MunsellSpec);	
else
   ColorLabMunsellVector = MunsellSpec	;
end

% Extract hue, chroma, and value from ColorLab Munsell vector that corresponds
% to input.
if length(ColorLabMunsellVector) == 1		% Colour is Munsell grey
   % A one-element vector is an achromatic grey, so no interpolation is
   % necessary.  Evaluate directly and return.
   [x y] = roo2xy(ones(size([400:10:700])), 'C/2', [400:10:700]);
   % Paul Centore replaced the following line by the line above, on Jan. 1, 2014
%  [x y]      = IlluminantCWhitePoint()	;
   Status.ind = 1						;
   return								;							
else
   HueNumber     = ColorLabMunsellVector(1)		;
   Value         = ColorLabMunsellVector(2)		;
   Chroma        = ColorLabMunsellVector(3)		;
   HueLetterCode = ColorLabMunsellVector(4)		;
end

% Check that the Munsell value of the input is an integer between 1 and 9
% (If the value is 10, then the colour is ideal white, which was previously assgined
% the xy coordinates for Illuminant C.)
if Value < 1 || Value > 9
   Status.ind = 2;		% Set error and return
   return
end
% For numerical convenience, allow Munsell values very close to integers, and
% round them to integers.
if abs(Value-round(Value)) > 0.001		
   Status.ind = 2;		% Set error and return
   return
end
% Round value to integer, if it is already very close to an integer.
Value = round(Value);

% Check that the chroma of the input is a positive, even integer.
if Chroma < 2
   Status.ind = 3;		% Set error and return
   return
end
% For numerical convenience, allow Munsell chromas very close to even integers, and
% round them to even integers.
if abs(2*((Chroma/2)-round(Chroma/2))) > 0.001		
   Status.ind = 3;		% Set error and return
   return
end
% Round chroma to positive even integer, if it is already very near a positive even integer
Chroma = 2*round(Chroma/2)	;

% Check to see if the input colour is a standard Munsell colour, for which
% renotation data is available without interpolation.  If so, make the
% renotation conversion and return
if abs(HueNumber) < threshold ||...   
  abs(HueNumber-2.5) < threshold ||...
  abs(HueNumber-5) < threshold ||...
  abs(HueNumber-7.5) < threshold ||...
  abs(HueNumber-10) < threshold
  HueNumber = 2.5 * round(HueNumber/2.5)	;	% Round to very close standard hue
  [x y Y StatusCode] = MunsellToxyYfromExtrapolatedRenotation(ColorLabMunsellVector);	
  if StatusCode.ind ~= 1	% No renotation data available.  Set error code and return
     Status.ind = 5;
     return;
  else						% Successful assignment, so return without error code
     Status.ind = 1;
	 return;
  end
end

% Find two hues which bound the hue of the input colour, and for which
% renotation data is available.  Renotation data is available only 
% for hues whose prefix number is 2.5, 5.0, 7.5, or 10.0.
[ClockwiseHue, CtrClockwiseHue] = BoundingRenotationHues(HueNumber, HueLetterCode);
MunsellHueNumberMinus = ClockwiseHue(1)		;
CLHueLetterIndexMinus = ClockwiseHue(2)		;
MunsellHueNumberPlus  = CtrClockwiseHue(1)	;
CLHueLetterIndexPlus  = CtrClockwiseHue(2)	;

% Express the two bounding Munsell colours in ColorLab Munsell vector format, and
% in ASTM format
CLMVMinus    = [ClockwiseHue(1), Value, Chroma, ClockwiseHue(2)]			;
CLMVPlus     = [CtrClockwiseHue(1), Value, Chroma, CtrClockwiseHue(2)]		;

% Find the achromatic point, to be used as the center of polar coordinates
[xGrey yGrey YGrey StatusCode] = MunsellToxyYfromExtrapolatedRenotation([Value]);
if StatusCode.ind ~= 1
   Status.ind = 5		;
   return				;
end			

% Express the two bounding Munsell colours in polar coordinates, after
% finding their chromaticity coordinates in the Munsell renotation.  
[xPlus yPlus YPlus StatusCode] = MunsellToxyYfromExtrapolatedRenotation(CLMVPlus) ;	
if StatusCode.ind ~= 1	% No renotation data available for bounding colour.  Set error code and return
   Status.ind = 2;
   return;
end
[THPlus RPlus]  = cart2pol(xPlus-xGrey, yPlus-yGrey)	;
THPlus          = mod((180/pi) * THPlus, 360)			;	% Convert to degrees

[xMinus yMinus YMinus StatusCode] = MunsellToxyYfromExtrapolatedRenotation(CLMVMinus)	;
if StatusCode.ind ~= 1	% No renotation data available for bounding colour.  Set error code and return
   Status.ind = 2;
   return;
end
[THMinus RMinus] = cart2pol(xMinus-xGrey, yMinus-yGrey)	;
THMinus          = mod((180/pi) * THMinus, 360)			;	% Convert to degrees

LowerTempHueAngle = MunsellHueToChromDiagHueAngle(MunsellHueNumberMinus, CLHueLetterIndexMinus) ;
TempHueAngle      = MunsellHueToChromDiagHueAngle(HueNumber,             HueLetterCode)				;
UpperTempHueAngle = MunsellHueToChromDiagHueAngle(MunsellHueNumberPlus,  CLHueLetterIndexPlus)  ;

% Adjust for possible wraparound.  There should be a short arc running counter clockwise from
% the lower hue value to the upper hue value
if THMinus - THPlus > 180 
   THPlus  = THPlus + 360;
end
if LowerTempHueAngle == 0
   LowerTempHueAngle = 360	;
end
if LowerTempHueAngle > UpperTempHueAngle	% E.g. Lower is 355, Upper is 10
   if LowerTempHueAngle > TempHueAngle
      LowerTempHueAngle = LowerTempHueAngle - 360	;
   else
      LowerTempHueAngle = LowerTempHueAngle - 360	;
      TempHueAngle      = TempHueAngle      - 360	;
   end
end

% The interpolation of the input colour using the two bounding colours will be done 
% by either linear or radial interpolation, as determined by a function call.
[InterpStyle, CallStatus] = LinearVsRadialInterpOnRenotationOvoid(MunsellSpec);
if CallStatus.ind ~= 1			% Unsuccessful call; return with error message
   Status.ind = 4	;
   return			;
end

% Perform interpolation as indicated
if InterpStyle.Linear == true				% Use linear interpolation
   x = interp1([LowerTempHueAngle,UpperTempHueAngle], [xMinus, xPlus], TempHueAngle);
   y = interp1([LowerTempHueAngle,UpperTempHueAngle], [yMinus, yPlus], TempHueAngle);
   
elseif InterpStyle.Radial == true			% Use radial interpolation
   % Interpolate radially along the chroma ovoid. For example, if the input colour is 4B6/7, then 
   % the two bounding points on this ovoid are 2.5B6/6 and 5B6/6.  The new point on the
   % ovoid will have hue angle 60% of the way from the hue angle of 2.5B, to the
   % hue angle at 5B.  The R value of the new point will be between the R values for 2.5B6/6
   % and 5B6/6, in a 60/40 ratio.  
   InterpolatedTheta = interp1([LowerTempHueAngle,UpperTempHueAngle], [THMinus THPlus], TempHueAngle) ;
   InterpolatedR     = interp1([LowerTempHueAngle,UpperTempHueAngle], [RMinus  RPlus],  TempHueAngle) ;
   % Find xy chromaticity coordinates for the new point on the chroma ovoid
   x  = InterpolatedR * cosd(InterpolatedTheta) + xGrey	;
   y  = InterpolatedR * sind(InterpolatedTheta) + yGrey	;
   
else		% Interpolation style not determined; return with error message
   Status.ind = 4	;
   return			;
end

% Set successful status return code and return
Status.ind = 1;
return; 