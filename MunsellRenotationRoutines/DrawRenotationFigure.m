function  Status = DrawRenotationFigure(MunsellValue);
% Purpose		Figures 1 through 9 of [Newhall1943] present visual interpolations of ovoids and
%				radials, that connect measured values of Munsell samples, in xyY coordinates.  This
%				routine draws the same curves automatically; it is intended as a visual check
%				on the interpolateion that will be used in other renotation routines.  The current
%				routine allows Munsell values from 1 through 10, including non-integer values.
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
%				The coordinate Y gives a colour's luminance, or relative luminance.  
%				When interpreted as a relative luminance, Y is a number between 0 and
%				100, that expresses the intensity of the source as a percentage of some
%				maximum intensity.  This percentage is calculated with regard to the
%				human photopic luminous efficiency function, which has been established
%				as part of the CIE 2 degree standard observer.  When dealing with
%				physical samples such as paints, Y is the percentage of a fixed light
%				source that a paint sample reflects (with regard to the standard 
%				observer).  In the case of a physical sample, Y is called the luminance factor.  
%
%				The coordinates x and y are chromaticity coordinates.  While Y
%				indicates, roughly speaking, how light or dark a colour is, x and y
%				indicate hue and chroma.  For example, the colour might be a saturated red,
%				or a dull green.  
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
%				chromaticity diagram for the corresponding luminance factor.
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
%				Other routines have been written that automate this interpolation.  The current
%				routine draws figures that result from this automation, so that
%				researchers can determine visually whether the automated interpolation is 
%				acceptably close to the original interpolation.  
%				The current routine draws figures for Munsell values from 1
%				through 10.  Unlike [Newhall1943], this routine also draws figures 
%				for non-integer values.
%
%				This routine is very slow, due to the many calls to the routine IsWithinMacAdamLimits,
%				which itself is slow.  For faster performance, at the expense of showing some
%				points beyond the MacAdam limits, calls to IsWithinMacAdamLimits can be dispensed with.
%
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
%
% Syntax		Status = DrawRenotationFigure(MunsellValue);
%
%				MunsellValue	A Munsell value between 1 and 10, not necessarily an integer.  
%	
%				Status			A return code with two fields.  The second field is a list
%								of possible return messages.  The first field is a positive
%								integer indicating one of the return messages.
%
% Related		roo2xy
% Functions
%
% Required		MunsellValueToLuminanceFactor, MunsellToxyY, IsWithinMacAdamLimits
% Functions		
%
% Author		Paul Centore (Jan. 15, 2011)
% Revision   	Paul Centore (May 8, 2012)
%				 ---Changed != to ~= so that code would work in both Matlab and Octave.
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (Jan. 1, 2014)  
%				 ---Replaced call to IlluminantCWhitePoint with call to roo2xy (from OptProp).
%
% Copyright 2011, 2012, 2014 Paul Centore
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
				   'Value must be between 1 and 10',...
				   };
Status.ind      = -99;			% Default unassigned value

% Check that the Munsell value of the input is between 1 and 10
if MunsellValue < 1 | MunsellValue > 10
   Status.ind = 2;		% Set error and return
   return
end
% For numerical convenience, allow Munsell values very close to integers, and
% round them to integers.
if abs(MunsellValue-round(MunsellValue)) < 0.001		
   % Round value to integer, since it is already very close to an integer.
   MunsellValue = round(MunsellValue);
end

% Calculate Y directly from the Munsell value, in accordance with [ASTMD153508].
LuminanceFactors = MunsellValueToLuminanceFactor(MunsellValue)	;
Y                = LuminanceFactors.ASTMD153508					;

figure
% Choose an appropriate name for the figure, which will be saved
figname = ['RenotationFigureValue', num2str(MunsellValue)];
set(gcf, 'Name', figname);

% Draw Illuminant C white point
[originx originy] = roo2xy(ones(size([400:10:700])), 'C/2', [400:10:700]);
% Paul Centore replaced the following line by the line above, on Jan. 1, 2014
%   [originx originy] = IlluminantCWhitePoint();
plot(originx, originy, 'k.');
hold on

% Draw chroma ovoids, at standard chromas
for Chroma = 2:2:40		
   % Initialize x- and y-coordinates for points on ovoid
   xchroma = [];
   ychroma = [];
   HueNumbers = 10:(-1):1;  % Ovoid goes through all 10 hues, clockwise
   for HueNumber = HueNumbers
      % The more hue prefixes are used, the better the ovoid resolution, but
	  % the slower the routine runs
      HuePrefixes = 0.5:0.5:10; %[2.5, 5, 7.5, 10];
      for HuePrefix = HuePrefixes
	     % Express Munsell specification in Colorlab format
	     MunsellSpec = [HuePrefix, MunsellValue, Chroma, HueNumber];
		 % Convert Munsell specification into xy chromaticity coordinates, for plotting
	     [x y Y Status] = MunsellToxyY(MunsellSpec);
		 % Only plot points within MacAdam limits, relative to Illuminant C, for which
		 % chromaticity coordinates have been calculated.
		 if Status.ind == 1 && IsWithinMacAdamLimits(x, y, Y, 'C')
		    xchroma = [xchroma x];
			ychroma = [ychroma y];
		 else
		    % Use -99 to signify a value that is not defined, so cannot be plotted.
		    xchroma = [xchroma -99];
			ychroma = [ychroma -99];	
		 end
	  end
   end
   
   % Plot an ovoid
   NumOfPointsOnOvoid = length(xchroma);
   for ind = 1:NumOfPointsOnOvoid
	  % Each point is connected by a line to the next point, except that the last point is
	  % connected by a line to the first point.
      if ind == NumOfPointsOnOvoid
	     indp1 = 1;
	  else
         indp1 = ind + 1;
	  end
	  % If two adjacent points are both defined, then plot a line joining those points
      if xchroma(ind) ~= -99 & xchroma(indp1) ~= -99
	     plot([xchroma(ind) xchroma(indp1)], [ychroma(ind), ychroma(indp1)], 'k-');
		 hold on
	  end
   end
end

% Draw radials, using linear interpolation over points for which renotation data is available
for HueNumber = 10:(-1):1
   for HuePrefix = [2.5, 5, 7.5, 10]
      % For each hue radial, start at Illuminant C white point, at the origin, and work outward
	  currx = originx;
	  curry = originy;
	  
	  % Initialize plotting limits
	  InitialChroma = 2;
	  FinalChroma   = 40;
	  % The finer the chroma increment, the better the MacAdam limits can be approximated, but
	  % the slower the routine will run
	  ChromaInc     = 0.1;
	  
	  % Plot hue radial from lower chromas to higher chromas
	  Chroma = InitialChroma;
  	  DataExists = true;
	  % Only plot as long as data is available for that radial
      while Chroma <= FinalChroma & DataExists == true;
	     % Express Munsell specification in Colorlab format
	     MunsellSpec = [HuePrefix, MunsellValue, Chroma, HueNumber];
		 % Convert Munsell specification into xy chromaticity coordinates, for plotting
	     [x y Y Status] = MunsellToxyY(MunsellSpec);
		 % Only plot points within MacAdam limits, relative to Illuminant C, for which
		 % chromaticity coordinates have been calculated.
		 if Status.ind == 1  && IsWithinMacAdamLimits(x, y, Y, 'C')
	        plot([currx x], [curry, y], 'k-');
			hold on
			currx = x;
			curry = y;
		 else
		    DataExists = false;	
		 end
		 Chroma = Chroma + ChromaInc;
	  end
   end
end

% Adjust plot limits, label size, etc., as desired
set(gca, 'xlim', [0.0 0.7], 'ylim', [0.0 0.7],...
             'xtick', [0.0:0.1:0.7], 'xticklabel',...
			 {'0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7'},...
             'ytick', [0.0:0.1:0.7], 'yticklabel',...
			 {'0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7'},...
			 'Fontunits','points','Fontsize',18);
axis equal;

% Save plot in eps format
print(gcf, [figname,'.eps'], '-deps');

return