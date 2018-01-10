function [MunsellSpec MunsellVec Status] = xyYtoMunsell(x, y, Y);
% Purpose		Convert xyY coordinates to a Munsell specification, by interpolating
%				over Munsell renotation data.  Near the MacAdam limits, extrapolated
%				Munsell renotation data will be used if necessary.
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
%				indicate hue and chroma.  For example, the colour might be a saturated red,
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
%				The conversion data for the Munsell renotation was originally given as 
%				a look-up table, expressing a Munsell specification in xyY coordinates
%				([Newhall1943, Table I]). The renotation was later updated
%				in [ASTMD1535-08].  The routine MunsellToxyY 
%				can be used to find xyY coordinates for Munsell specifications that are not
%				in the original renotation data.
%
%				The interpolation uses two empirical facts.  First, the relative luminance
%				Y is a function solely of the Munsell value, and vice versa.  Therefore,
%				a Munsell section through a fixed value is mapped bijectively to the
%				chromaticity diagram for the corresponding relative
%				luminance ([Newhall1943, Figs. 1 to 9]; 
%				reproduced with some modifications in [Agoston1987, Figs. 12.1 to 12.9]). 
%				Second, within a Munsell section of fixed value, the lines of constant
%				chroma are rings around a central, achromatic point, corresponding to the
%				Munsell grey of that value.  The straight lines radiating from the central
%				point are roughly lines of constant hue.  It is therefore natural to use a
%				polar coordinate system, (r, theta), about the achromatic point, where r,
%				the distance from grey, is the chroma, and each angle of theta corresponds
%				to a particular hue.
%
%				This current routine is an inverse to MunsellToxyY.  Given xyY coordinates, we aim to
%				find the Munsell specification that would generate those xyY coordinates.
%				We can evaluate the xyY coordinates for any Munsell specification, and must
%				use that information in the inverse calculation.
%				
%				This inversion routine uses the same two empirical facts that the original
%				function uses.  First of all, the Munsell value can be calculated directly
%				from Y.  Secondly, for a fixed value, the level curves of Munsell 
%				hue and chroma are approximately rings and radials about the achromatic
%				point in xy coordinates.
%
%				The first step in the inversion is therefore a simple Munsell value
%				calculation, using a table lookup of inputs and outputs of the quintic
%				polynomial in [ASTMD1535-08, Eq. 2].  The problem then 
%				reduces to a two-dimensional problem:
%				finding a hue and chroma that give the desired x and y.
%
%				The inversion proceeds iteratively.  At each step, a Munsell 
%				specification is selected, whose xyY coordinates are (usually) closer to the
%				input xyY than the previous step.  Closeness is measured by the Euclidean
%				distance in xy space.  When the xyY of the current Munsell specification is
%				less than some threshold distance, the inversion terminates.
%
%				The starting Munsell specification is chosen with the help of the CIELAB
%				model.  The input xyY are converted into CIELAB coordinates, resulting in
%				a hue angle and an approximation for chroma.  CIELAB coordinates 
%				correspond approximately to Munsell quantities, so they are converted to
%				a Munsell specification, where the iterative inversion starts.  Although
%				this conversion is not exact, it is close enough to make a useful starting
%				point.
%
%				At each subsequent step, the xy coordinates are found for the current
%				Munsell specification.  They are converted to (rCur, thetaCur) coordinates about
%				the achromatic point of value Y, and compared to (rInput, thetaInput),
%				which correspond to the input x and y.  The distance r corresponds to
%				chroma, and the angle theta corresponds to hue.  The goal of the
%				inversion is to have (rCur, thetaCur) match (rInput, thetaInput) as closely 
%				as possible.  
%
%				To achieve this goal, the current chroma and hue will be adjusted. Start by 
%				varying hue while keeping chroma constant.  In the CIE chromaticity diagram, 
%				the Munsell hues lie along approximate
%				radials, whose angles can be read off.  The routines MunsellHueToChromDiagHueAngle
%				and ChromDiagHueAngleToMunsellHue convert between Munsell hues, and the
%				angles of the radials.  The angles thetaCur and thetaInput will probably
%				differ.  Calculate new hues whose angles (theta1, theta2, .., thetan)
%				bound thetaInput.  Then interpolate linearly to find a hue that should
%				match thetaInput more closely.
%
%				A natural approach to generating theta1 is to choose
%						(new hue angle) = (current hue angle) + thetaInput - thetaCur,
%				which roughly corrects for the current angle discrepancy.  Further angles
%				can be generated by
%						(current hue angle) + 2 * (thetaInput - thetaCur),
%						(current hue angle) + 3 * (thetaInput - thetaCur), etc.
%				In practice, two new hue angles are usually sufficient.
%
%				After varying hue without varying chroma, let chroma vary without changing hue.
%				Each new chroma produces a Munsell specification whose own (r, theta) values
%				can be calculated.  If n chromas are tried, there will be n Munsell
%				specifications, with n r-values: [r1, r2, ..., rn].  If the chromas are
%				chosen appropriately, rInput will be bounded by some ri and rj.  By linear 
%				interpolation, we find a new chroma value that should be closer to producing
%				rInput.  
%
%				A natural approach to generating r1 is to choose 
%							(new chroma) = (rInput/rCur) * (current chroma),		(1)
%				because this corrects for the current undershoot or overshoot.  If rInput
%				is not between rCur and the r1 generated by (1), then generate r2 from
%				another chroma given by ((rInput/rCur)^2) * (current chroma).  If rInput does
%				not lie in the interval containing rCur, r1, and r2, then increase the
%				exponent to 3 to produce an r3, and so on.  In practice, it is rarely
%				necessary to go beyond r1 and r2.
%
%				Proceed iteratively, adjusting the hue and the chroma in alternate 
%				iterations, until the desired accuracy is achieved.
%
%				For a detailed discussion and description of the inversion algorithm,
%				see [Centore2011].
%
%				[Agoston1987] G. A. Agoston, Color Theory and Its Application in Art
%					and Design, 2nd ed., Springer Series in Optical Science, vol. 19,
%					Springer-Verlag, 1987.
%				[ASTMD1535-08] ASTM, Standard D 1535-08, "Standard Practice for Specifying Color by the
%					Munsell System," approved January 1, 2008.
%				[Centore2011] Paul Centore, "An Open-Source Inversion for the Munsell
%					Renotation," 2011, unpublished (currently available at centore@99main.com/~centore).
%				[Foley1990] James D. Foley, Andries van Dam, Steven K. Feiner, & John
%					F. Hughes, Computer Graphics: Principles and Practice, 2nd ed.,
%					Addison-Wesley Publishing Company, 1990.
%				[McCamy1992] C. S. McCamy, "Munsell Value as Explicit Functions of CIE
%					Luminance Factor," COLOR Research and Application, Vol. 17,
%					1992, pp. 205-207.
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
%
% Syntax		[MunsellSpec MunsellVec Status] = xyYtoMunsell(x, y, Y);
%
%				MunsellSpec		A Munsell specification string, in Munsell format, such as 2.3R5.6/10.8.
%
%				MunsellVec		A Munsell specification, in ColorLab format, such as [2.3, 5.6, 10.8, 7] .
%
%				[x y Y]			CIE coordinates of MunsellSpecString, when
%								illuminated by Illuminant C.  Y is the luminance factor
%	
%				Status			A return code with two fields.  The second field is a list
%								of possible return messages.  The first field is a positive
%								integer indicating one of the return messages.  Two additional fields,
%								Status.dist and Status.num, might be assigned for debugging.
%
% Related		MunsellToxyY
% Functions
%
% Required		MunsellSpecToColorLabFormat, LuminanceFactorToMunsellValue,
% Functions		MunsellToxyForIntegerMunsellValue, MunsellToxyY,
%				CIELABtoApproxMunsellSpec, MunsellHueToChromDiagHueAngle,
%				xyz2lab, lab2perc
%
% Author		Paul Centore (June 13, 2010)
% Revision  	Paul Centore (Jan. 12, 2011)
%	            ---Previouly, Munsell value was calculated in accordance with [Newhall1943].  In the revision,
%				   Munsell value is calculated in accordance with [McCamy1992], which has been
%				   incorporated into [ASTMD1535-08].
%				---Tne Munsell output is now returned as a standard Munsell string, as well as in ColorLab format
% Revision  	Paul Centore (Jan. 22, 2011)
%				---Previouly, Munsell value was calculated in accordance with [McCamy1992].  In the revision,
%				   Munsell value is calculated by linear interpolation over a table lookup of evaluations of
%				   [ASTMD1535-08, Eq. 2].
% Revision   	Paul Centore (May 8, 2012)
%				 ---Changed != to ~= so that code would work in both Matlab and Octave.
% Revision   	Zsolt Kovacs-Vajna (May 14, 2012)
%				 ---Added 'linear' option to interp1 calls when 'extrap' option is used, for compatibility
%				    with Matlab.
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (Jan. 1, 2014)  
%				 ---Replaced call to IlluminantCWhitePoint with call to roo2xy (from OptProp).
% Revision		Paul Centore (Feb. 16, 2014)  
%				 ---Replaced call to roo2xy (from OptProp) with call to ChromaticityOfWhitePoint
%
% Copyright 2010-2014 Paul Centore
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

Status.Messages = {'Success',...
    [num2str(x),', ',num2str(y),', ',num2str(Y),' beyond gamut of renotation data.'],...
	'Exceeded maximum number of iterations.',...
	[num2str(x),', ',num2str(y),', ',num2str(Y),' outside MacAdam limits.'],...
	};
% Assign default output values
MunsellVec = -99;
MunsellSpec = 'ERROR';
Status.ind = -99;

% If the colour stimulus is beyond the MacAdam limits, set an error code and return.
% Determine the MacAdam limits with regard to illuminant C, which is the Munsell standard.
if ~IsWithinMacAdamLimits(x, y, Y, 'C');
   Status.ind = 4;
   return;
end
	
TRUE  = 1;
FALSE = 0;	
% Set ShowFigure to TRUE if a figure is desired for debugging
ShowFigure = false	;
if ShowFigure == TRUE
   figure	;
end
	
% The Munsell value is calculated directly from the luminance factor,
% using a lookup table of evaluations of [ASTMD1535-08, Eq. 2].
MunsellValues = LuminanceFactorToMunsellValue(Y)	;
MunsellValue  = MunsellValues.ASTMTableLookup		;
% To avoid numerical issues with approximation, set MunsellValue to an
% integer if it is very close to an integer.
if abs(MunsellValue - round(MunsellValue)) < 0.001
   MunsellValue = round(MunsellValue);
end

% Express xy chromaticity coordinates as polar coordinates around the achromatic
% point with Munsell value corresponding to Y.
[xcenter ycenter Ytemp StatusCode] = MunsellToxyY([MunsellValue])	;
if StatusCode.ind ~= 1
%    disp(['Status 2, line 271'])		    
    Status.ind  = 2;
    Status.dist = -99;
    Status.num  = -99;
    return		 
end
% rInput and thetaInput are the values the inversion algorithm will attempt to match
[thetaInput rInput] = cart2pol(x-xcenter, y-ycenter);
thetaInput          = mod((180/pi)*thetaInput, 360)	;	% Express in degrees
thetaR              = [thetaInput rInput]			;
%Solution = [rInput thetaInput]

% Use the following parameters for the inversion algorithm.  ConvergenceThreshold
% is the required Euclidean distance in xy coordinates between the input
% xy, and the xy corresponding to a Munsell sample.  GreyThreshold is the required
% distance from the origin for a colour to be considered grey; it is defined 
% separately from ConvergenceThreshold for numerical reasons.   
ConvergenceThreshold = 0.0001	;
GreyThreshold        = 0.001	;
MaxNumOfTries        = 60		;
NumOfTries			 = 0		;

% Check for grey
if rInput < GreyThreshold
	MunsellVec = [MunsellValue]	;
	MunsellSpec = ColorLabFormatToMunsellSpec(MunsellVec) ;
	Status.ind  = 1				;
	return						;
end

if ShowFigure == TRUE
   plot(xcenter, ycenter, '+', 'color', [0.6 0.6 0.6]);
   hold on
   plot(x, y, 'kx');
   hold on
   axis('equal');
end

% The input xyY are the CIE coordinates of Illuminant C, when reflected
% off a Munsell sample
[X Y Z]      = xyY2XYZ(x, y, Y)			;
ReflectedXYZ = [X Y Z]					;

% Since Y is a percentage reflection, we want to find the CIE coordinates
% for illuminant C, whose Y value is 100.  This is the reference
% illuminant which is reflected off the Munsell sample.
% The chromaticity coordinates for Illuminant C are
[xC, yC] = ChromaticityOfWhitePoint('C/2')	; % change made Feb. 16., 2014, by Paul Centore
% Convert to XYZ form, and normalize to have luminance 100.  This will
% be the reference illuminant.
[Xr Yr Zr] = xyY2XYZ(xC, yC, Y)		;
ReferenceXYZ = [(100/Yr)*Xr, 100, (100/Yr)*Zr];

% ReferenceXYZ are the CIE coordinates for a reference light, whose power spectral distribution
% is consistent with Illuminant C, and whose luminance is 100.  The relative
% luminance of the input sample, when illuminated by Illuminant C, is given by Y, which
% varies between 0 and 100, and is the percentage of illuminant C that the sample
% reflects.  Therefore, RefXYZ can be viewed as the reference illuminant for the 
% sample, and XYZ as the CIE coordinates for the reflected illuminant.  These are the
% data needed to apply the CIELAB model.
Lab = xyz2lab(ReflectedXYZ, ReferenceXYZ)	;
LhC = lab2perc(Lab)							;

% Find an initial Munsell specification for the interpolation algorithm, by using a
% rough transformation from CIELAB to Munsell coordinates.  InitialMunsellSpec is
% not an exact inverse for xyY, but should be close.
L   = LhC(1)	;		% Lightness in CIELAB system
hab = LhC(2)	;		% Hue angle in CIELAB system
Cab = LhC(3)	;		% C*ab in CIELAB system
InitialMunsellSpec = CIELABtoApproxMunsellSpec(L, Cab, hab)	;
% Replace value of initial Munsell estimate with known Munsell value
TempCLvec    = MunsellSpecToColorLabFormat(InitialMunsellSpec)	;
TempCLvec(2) = MunsellValue										;
% Deliberately underestimate chroma to avoid chromas beyond extrapolated
% renotation values
TempCLvec(3) = (5/5.5) * TempCLvec(3)							;

if ShowFigure == TRUE
   [xCur yCur YCur StatusCode] = MunsellToxyY(TempCLvec);
   plot(xCur, yCur, 'gx');
   hold on
   text(xCur, yCur, [num2str(NumOfTries)]);
   hold on
end

% Use a loop to iterate over different Munsell specifications, whose xyY coordinates
% should progressively approach the input xyY.
CurrentCLVec        = TempCLvec	;
EuclideanDifference = -99		;
while NumOfTries <= MaxNumOfTries
   % After adjusting chroma without adjusting hue, the next iteration adjusts hue
   % without adjusting chroma.
   NumOfTries = NumOfTries + 1;

   % Extract Munsell quantities from Munsell specification
   CurrentCLHueNumber       = CurrentCLVec(1);
   CurrentMunsellChroma     = CurrentCLVec(3);
   CurrentCLHueLetterIndex  = CurrentCLVec(4);
   CurrentChromDiagHueAngle = MunsellHueToChromDiagHueAngle(CurrentCLHueNumber,CurrentCLHueLetterIndex);
   
   % Check that current chroma is possible for the hue and value in the Munsell specification.  If the
   % chroma is too high, set it to be the maximum chroma.
   [MaxChroma StatusCode] = MaxChromaForExtrapolatedRenotation(CurrentCLHueNumber, CurrentCLHueLetterIndex, MunsellValue);
   if CurrentMunsellChroma > MaxChroma
      CurrentMunsellChroma = MaxChroma				;
	  CurrentCLVec(3)      = CurrentMunsellChroma	;
   end

   % Find xy coordinates corresponding to the current Munsell specification.

   [xCur yCur YCur StatusCode] = MunsellToxyY(CurrentCLVec);
   if StatusCode.ind ~= 1
%	  disp(['Status 2, line 383'])		    
	  Status.ind  = 2;
      Status.dist = EuclideanDifference;
      Status.num  = NumOfTries;
      return		 
   end

   % Hue angles correspond to values of theta.  The new hue angle will differ from the
   % current hue angle approximately as much as the desired theta value (thetaInput) differs from the
   % current theta value.  Call this difference thetaDiff and calculate it.  Other
   % hue angles, with their corresponding thetas and theta differences, will be tried.
   % Make a list, thetaDiffsVec, of the corresponding theta differences.  
   [thetaCur rCur] = cart2pol(xCur-xcenter, yCur-ycenter);
   thetaCur        = mod((180/pi)*thetaCur, 360)		 ;		% Express in degrees
   thetaDiff       = mod(360 - thetaInput + thetaCur, 360);
   if thetaDiff > 180		% Adjust for wraparound if necessary
      thetaDiff = thetaDiff-360		;
   end
   thetaDiffsVec = [thetaDiff]	;
   % Start a similar list for hue angles that correspond to the theta differences.
   ChromDiagHueAngles       = [CurrentChromDiagHueAngle]	;
   % Also make a list of how much the new hue angles differ from CurrentChromDiagHueAngle.  These
   % angles will be near zero, and will avoid potential problems with wraparound.
   ChromDiagHueAngleDiffs   = [0];

   % Ideally, thetaDiff will be 0
   % (thetaInput will agree with the theta corresponding to the new hue angle).  
   % Continue constructing the list of theta differences until it contains both
   % negative and positive differences; then find the new hue angle by linear interpolation
   % at the value thetaDiff = 0.
   ctr = 0;
   AttemptExtrapolation = FALSE;
   while sign(min(thetaDiffsVec)) == sign(max(thetaDiffsVec))  && AttemptExtrapolation == FALSE
      ctr = ctr + 1;
	  if ctr > 10	% Too many attempts.  Return with error message
		 Status.ind = 3		;
		 return;
	  end
	  
	  % Find another hue angle, by increasing the coefficient of (thetaInput-thetaCur).
	  % Construct a trial Munsell specification by using the new hue angle.
	  TempChromDiagHueAngle     = mod(CurrentChromDiagHueAngle + ctr*(thetaInput - thetaCur),360);
	  % Record the difference of the trial angle from the current hue angle
	  TempChromDiagHueAngleDiff = mod(ctr*(thetaInput - thetaCur), 360)	;
	  if TempChromDiagHueAngleDiff > 180
	     TempChromDiagHueAngleDiff = TempChromDiagHueAngleDiff - 360;
	  end
      [TempHueNumber,TempHueLetterCode] = ChromDiagHueAngleToMunsellHue(TempChromDiagHueAngle);
      TempCLVec       = [TempHueNumber, MunsellValue, CurrentMunsellChroma, TempHueLetterCode];

	  % Evaluate the trial Munsell specification, convert to polar coordinates, and 
	  % calculate the difference of the resulting trial theta and thetaInput
      [xCurTemp yCurTemp YCurTemp StatusCode] = MunsellToxyY(TempCLVec);
	  if StatusCode.ind ~= 1
	     % Interpolation is impossible because there are not both positive and negative differences,
		 % but extrapolation is possible if there are at least two data points already
	     if length(thetaDiffsVec) >= 2	
		    AttemptExtrapolation = TRUE	;
		 else
%			disp(['Status 2, line 442'])		    
  		    Status.ind  = 2;
            Status.dist = EuclideanDifference;
            Status.num  = NumOfTries;
            return
		 end  		 
	  end
	  
	  if AttemptExtrapolation == FALSE
	     [thetaCurTemp rCurTemp] = cart2pol(xCurTemp-xcenter, yCurTemp-ycenter);
         thetaCurTemp            = mod((180/pi)*thetaCurTemp, 360)				;	 % Express in degrees
         thetaDiff               = mod(360 - thetaInput + thetaCurTemp, 360)   ;
         if thetaDiff > 180		% Adjust for wraparound if necessary
            thetaDiff = thetaDiff-360		;
         end

	     % Add trial hue angle and theta difference to lists
         thetaDiffsVec          = [thetaDiffsVec, thetaDiff]				;	
 	     ChromDiagHueAngleDiffs = [ChromDiagHueAngleDiffs, TempChromDiagHueAngleDiff];
	     ChromDiagHueAngles     = [ChromDiagHueAngles, TempChromDiagHueAngle]	;
	  end
   end
   
   % Since the while loop exited successfully, both negative and positive theta
   % differences have been found, so an extrapolation should
   % be attempted.  Interpolate linearly to estimate the hue
   % angle that corresponds to a theta difference of 0
   [thetaDiffsVecSort I]  = sort(thetaDiffsVec)		;
   ChromDiagHueAnglesSort = ChromDiagHueAngles(I)	;
   ChromDiagHueAngleDiffs = ChromDiagHueAngleDiffs(I);
   % The extrapolation option will be used if there is not sufficient data
   % for interpolation
   NewChromDiagHueAngleDiff  = mod(interp1(thetaDiffsVecSort, ChromDiagHueAngleDiffs, 0, 'linear', 'extrap'),360);
   NewChromDiagHueAngle      = mod(CurrentChromDiagHueAngle + NewChromDiagHueAngleDiff,360);

   % Adjust the current Munsell specification by replacing the current hue with the
   % new hue.
   [NewHueNumber,NewHueLetterCode] = ChromDiagHueAngleToMunsellHue(NewChromDiagHueAngle);
   CurrentCLVec       = [NewHueNumber, MunsellValue, CurrentMunsellChroma, NewHueLetterCode];
if NumOfTries >= 2000 	% Use for debugging non-converging cases
	NumOfTries
	thetaDiffsVecSort
	ChromDiagHueAngleDiffs
	ChromDiagHueAnglesSort
	NewChromDiagHueAngle
    [ctr CurrentCLVec]
end

   % Calculate the Euclidean distance between the xy coordinates of the newly
   % constructed Munsell specification, and the input xy
   [xCur yCur YCur StatusCode] = MunsellToxyY(CurrentCLVec);
   if StatusCode.ind ~= 1
%	  disp(['Status 2, line 494'])		    
%	  CurrentCLVec
%	  [xCur yCur YCur]
%	  StatusCode
	  Status.ind  = 2;
      Status.dist = EuclideanDifference;
      Status.num  = NumOfTries;
      return		 
   end
   EuclideanDifference     = sqrt(((x-xCur)*(x-xCur)) + ((y-yCur)*(y-yCur)));

   if ShowFigure == TRUE
      plot(xCur, yCur, 'gx');
      hold on
	  text(xCur, yCur, [num2str(NumOfTries)]);
	  hold on
   end
 
   % If the two xy coordinate pairs are close enough, then exit with a success message
   if EuclideanDifference < ConvergenceThreshold  % Current Munsell spec is close enough
	  MunsellVec = CurrentCLVec;
      MunsellSpec = ColorLabFormatToMunsellSpec(MunsellVec) ;
      Status.ind  = 1;
	  return
   end
   
   NumOfTries = NumOfTries + 1	;
 
   % Extract Munsell quantities from Munsell specification
   CurrentCLHueNumber       = CurrentCLVec(1);
   CurrentMunsellChroma     = CurrentCLVec(3);
   CurrentCLHueLetterIndex  = CurrentCLVec(4);
   CurrentChromDiagHueAngle = MunsellHueToChromDiagHueAngle(CurrentCLHueNumber,CurrentCLHueLetterIndex);
   
   % Check that current chroma is possible for the hue and value in the Munsell specification.  If the
   % chroma is too high, set it to be the maximum chroma.
   [MaxChroma StatusCode] = MaxChromaForExtrapolatedRenotation(CurrentCLHueNumber, CurrentCLHueLetterIndex, MunsellValue);
   if CurrentMunsellChroma > MaxChroma
      CurrentMunsellChroma = MaxChroma				;
	  CurrentCLVec(3)      = CurrentMunsellChroma	;
   end
   
%[xtmop ytmop Ytmop StstTmop] = MunsellToxyY(CurrentCLVec);
%[CurrentCLVec, xtmop ytmop]

   % Find xy coordinates corresponding to the current Munsell specification.
   [xCur yCur YCur StatusCode] = MunsellToxyY(CurrentCLVec);
   if StatusCode.ind ~= 1
%	  disp(['Status 2, line 542'])		    
	  Status.ind  = 2;
      Status.dist = EuclideanDifference;
      Status.num  = NumOfTries;
      return		 
   end
   [thetaCur rCur] = cart2pol(xCur-xcenter, yCur-ycenter)	;
   thetaCur        = mod((180/pi)*thetaCur, 360)			;		% Express theta of current point in degrees
%TempData = [rCur thetaCur xCur yCur]
   % For this iteration, keep hue (corresponding to thetaCur) constant,
   % and let chroma (corresponding to rCur) vary.
   % Construct a set of chromas, called TempMunsellChromas, and find the (r, theta)
   % values for Munsell specifications with those chromas.
   % Make a list of r values, called rTempValues, that correspond to different chromas
   rTempValues        = [rCur]	;
   TempMunsellChromas = [CurrentMunsellChroma];
if NumOfTries >= 2000 	% Use for debugging non-converging cases
OneChroma = [NumOfTries rTempValues TempMunsellChromas]
end
   % In order to interpolate, rInput must be within the span of the r values
   % in rTempValues.  Check this condition, and add more chromas and r values
   % until it is satisfied.  Usually, no more than three chromas are necessary.
   ctr = 0;
   while rInput < min(rTempValues) || rInput > max(rTempValues)
      ctr = ctr + 1;
	  if ctr > 10		% Too many attempts to bound rInput.  Return with error message
	     Status.ind = 3 ;
		 return;
	  end
	  
	  % Try a new chroma, by increasing the exponent on rInput/rCur
	  TempMunsellChroma = ((rInput./rCur)^ctr) * CurrentMunsellChroma;
	  % Check that current chroma is possible for the hue and value in the Munsell specification.  If the
      % chroma is too high, set it to be the maximum chroma.
      if TempMunsellChroma > MaxChroma
         TempMunsellChroma = MaxChroma				;
	     CurrentCLVec(3)   = TempMunsellChroma		;
      end
if NumOfTries >= 20000 	% Use for debugging non-converging cases
[NumOfTries ctr TempMunsellChroma rInput rCur rInput./rCur CurrentMunsellChroma]
end
      % Find (r, theta) values for a Munsell specification which is identical to
      % the current Munsell specification, except that the chroma is TempMunsellChroma
	  TempCLVec         = [CurrentCLHueNumber, MunsellValue, TempMunsellChroma, CurrentCLHueLetterIndex];
      [xCurTemp yCurTemp YCurTemp StatusCode] = MunsellToxyY(TempCLVec);
	  if StatusCode.ind ~= 1
%disp(['Status 2, line 597'])		    
		 Status.ind  = 2;
         Status.dist = EuclideanDifference;
         Status.num  = NumOfTries;
         return		 
	  end
      [thetaCurTemp rCurTemp] = cart2pol(xCurTemp-xcenter, yCurTemp-ycenter);				
      thetaCurTemp            = mod((180/pi)*thetaCurTemp, 360)		;		% Express in degrees
%temprTheta = [thetaCurTemp rCurTemp]
	  % Add r and chroma to lists
      rTempValues        = [rTempValues rCurTemp];
      TempMunsellChromas = [TempMunsellChromas TempMunsellChroma];
if NumOfTries >= 2000	% Use for debugging non-converging cases
rTempValues
TempMunsellChromas
end
   end
   
   % Since the while loop has been exited, we have found r values, resulting from
   % different chroma values, that bound rInput.  Linearly interpolate to find a further
   % chroma, which should be an even better approximation.
   % Linear interpolation requires the list of r values to be sorted. 
   [rTempSort I]          = sort(rTempValues);
   TempMunsellChromasSort = TempMunsellChromas(I);
   NewMunsellChroma       = interp1(rTempSort, TempMunsellChromasSort, rInput);
 
   % Adjust the current Munsell specification, by using the new chroma
   CurrentCLVec                = [CurrentCLHueNumber, MunsellValue, NewMunsellChroma, CurrentCLHueLetterIndex];
if NumOfTries >= 2000	% Use for debugging non-converging cases
 NumOfTries
 rTempSort
 TempMunsellChromasSort
 NewMunsellChroma
 CurrentCLVec
end
   
   % Calculate the Euclidean distance between the xy coordinates of the newly
   % constructed Munsell specification, and the input xy
   [xCur yCur YCur StatusCode] = MunsellToxyY(CurrentCLVec);

   if StatusCode.ind ~= 1
%disp(['Status 2, line 636'])		    
	  Status.ind  = 2;
      Status.dist = EuclideanDifference;
	  Status.num  = NumOfTries;
	  return		 
   end
   EuclideanDifference = sqrt(((x-xCur)*(x-xCur)) + ((y-yCur)*(y-yCur)));

   if ShowFigure == TRUE
      plot(xCur, yCur, 'gx');
      hold on
	  text(xCur, yCur, [num2str(NumOfTries)]);
	  hold on
   end

   % If the two xy coordinate pairs are close enough, then exit with a success message
   if EuclideanDifference < ConvergenceThreshold  
	  MunsellVec  = CurrentCLVec							;
	  MunsellSpec = ColorLabFormatToMunsellSpec(MunsellVec)	;
      Status.ind  = 1										;
	  return
   end

end

% If the routine did not exit from the while loop, then the maximum number of
% iterations has been tried.  Set an error message and return.
Status.ind  = 3						;
Status.dist = EuclideanDifference	;
Status.num  = NumOfTries			;
return