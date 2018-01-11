function [InterpStyle, Status] = LinearVsRadialInterpOnRenotationOvoid(MunsellSpec);
% Purpose		Determine whether to use linear or radial interpolation when drawing
%				ovoids through data points in the Munsell renotation.
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
%				When interpreted as a
%				relative luminance, as will be done here, Y is a number between 0 and
%				100, that expresses the intensity of the source as a percentage of some
%				maximum intensity.  This percentage is calculated with regard to the
%				human photopic luminous efficiency function, which has been established
%				as part of the CIE 2 degree standard observer.  When dealing with
%				physical samples such as paints, Y is the percentage of a fixed light
%				source that a paint sample reflects (with regard to the standard 
%				observer).  In this context, Y is called the luminance factor.
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
%				The renotation uses the empirically verified fact that luminance factor
%				Y is a function solely of the Munsell value, and vice versa.  Therefore,
%				a Munsell section through a fixed value is mapped bijectively to the
%				chromaticity diagram for the corresponding relative luminance.
%				Figs. 1 through 9 of [Newhall1943] plot the xyY coordinates for Munsell samples
%				of Values 1 through 9.  Within each figure, the lines of constant
%				chroma are ovoids around a central, achromatic point, corresponding to the
%				Munsell grey of that value.  The lines of constant hue are slightly curving 
%				rays radiating from the central point.
%				Although Figs. 1 through 9 show smooth ovoids and radials, it is important to
%				note that these lines are visually interpolated.  Only the grid points, where
%				the ovoids and radials intersect, were taken from Table I, and are thus
%				empirically tested data.  
%
%				To automate renotation calculation for Munsell coordinates not in Table I, it
%				is necessary to fix an interpolation scheme for ovoids.  Visual inspection shows
%				that some ovoid segments are represented well by straight lines, while other
%				segments are better represented by curves.  This routine specifies where linear
%				interpolation will be used for ovoids, and where radial interpolation (which
%				gives a curve) will be used. 
%
%				Since the ovoids will be taken from Figs. 1 through 9, it is required that
%				the input Munsell coordinates have an integer value, and an even chroma.  The
%				input hue will either be in Table I, or be between two hues in Table I, so
%				there are no restrictions on it.  Since the output from this routine will be
%				later used in interpolation and extrapolation routines, the entries in Table I
%				have sometimes been extrapolated beyond the MacAdam limits.
%
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		[InterpStyle, Status] = LinearVsRadialInterpOnRenotationOvoid(MunsellSpec);
%
%				MunsellSpec		Either a standard Munsell specification, such as 4.2R8.1/5.3,
%								or a Munsell vector in ColorLab format.  The value must be an
%								integer between 1 and 10, and the chroma must be an even integer.
%
%				InterpStyle		A structure specifying whether interpolation is linear, radial,
%								or on a grid point.
%	
%				Status			A return code with two fields.  The second field is a list
%								of possible return messages.  The first field is a positive
%								integer indicating one of the return messages.
%
% Related		None
% Functions
%
% Required		MunsellSpecToColorLabFormat, MunsellHueToASTMHue
% Functions
%
% Author		Paul Centore (Dec. 31, 2010)
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (February 12, 2017)  
%				 ---Replaced & with && to avoid short-circuit warnings
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
				   'Value must be integer between 1 and 9',...
				   'Chroma must be positive, even integer',...
				   };
Status.ind      = -99;			% Default unassigned value

% Initialize output variable
InterpStyle.Input  = []		;
InterpStyle.Linear = false	;
InterpStyle.Radial = false	;
InterpStyle.OnGrid = false	;

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
   Value  = ColorLabMunsellVector(1)		;
   Chroma = 0								;
else
   HueNumber     = ColorLabMunsellVector(1)		;
   Value         = ColorLabMunsellVector(2)		;
   Chroma        = ColorLabMunsellVector(3)		;
   HueLetterCode = ColorLabMunsellVector(4)		;
end

% Save input in output structure
InterpStyle.Input  = ColorLabMunsellVector		;

% No interpolation needed for greys
if Chroma == 0
   InterpStyle.OnGrid = true	;
   Status.ind         = 1		;		% Return successfully
end

% Check that the Munsell value of the input is an integer between 1 and 10
if Value < 1 || Value > 10
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

% If Munsell value is 10, then assume that the input colour is an ideal
% white, regardless of the other entries in the input vector.  
if Value == 10
   InterpStyle.OnGrid = true	;
   Status.ind         = 1		;		% Return successfully
end

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
Chroma = 2*round(Chroma/2)	;

% If the hue is already a standard hue, then no interpolation is needed, so return
% successfully
if mod(HueNumber, 2.5) == 0			
   InterpStyle.OnGrid = true	;
   Status.ind         = 1		;		% Return successfully
end

% The ASTM hue is a number between 0 and 100, that uses the same increments as
% HueNumber, and is sometimes easier to work with than Munsell hue
ASTMHue          = MunsellHueToASTMHue(HueNumber,HueLetterCode);

% Assign ovoid segment interpolation to be linear or radial.  These assignments are based on
% visual inspection of the grid points in [Newhall1943, Figs. 1 through 9], rather than on
% any mathematical technique. 
if Value == 1
   if Chroma == 2
      if (ASTMHue > 15 && ASTMHue < 30) || (ASTMHue > 60 && ASTMHue < 85)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 4 	  
      if (ASTMHue > 12.5 && ASTMHue < 27.5) || (ASTMHue > 57.5 && ASTMHue < 80) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 6 
      if (ASTMHue > 55 && ASTMHue < 80) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 8 
      if (ASTMHue > 67.5 && ASTMHue < 77.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma >= 10 
      if (ASTMHue > 72.5 && ASTMHue < 77.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   else
      InterpStyle.Linear = true	;
   end
	  
elseif Value == 2
   if Chroma == 2
      if (ASTMHue > 15 && ASTMHue < 27.5) || (ASTMHue > 77.5 && ASTMHue < 80)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 4 	  
      if (ASTMHue > 12.5 && ASTMHue < 30) || (ASTMHue > 62.5 && ASTMHue < 80) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 6 
      if (ASTMHue > 7.5 && ASTMHue < 22.5) || (ASTMHue > 62.5 && ASTMHue < 80)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 8 
      if (ASTMHue > 7.5 && ASTMHue < 15)  || (ASTMHue > 60 && ASTMHue < 80) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma >= 10 
      if (ASTMHue > 65 && ASTMHue < 77.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   else
      InterpStyle.Linear = true	;
   end
	  
elseif Value == 3
   if Chroma == 2
      if (ASTMHue > 10 && ASTMHue < 37.5) || (ASTMHue > 65 && ASTMHue < 85)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 4 	  
      if (ASTMHue > 5 && ASTMHue < 37.5) || (ASTMHue > 55 && ASTMHue < 72.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 6 || Chroma == 8 || Chroma == 10
      if (ASTMHue > 7.5 && ASTMHue < 37.5) || (ASTMHue > 57.5 && ASTMHue < 82.5)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma >= 12 
      if (ASTMHue > 7.5 && ASTMHue < 42.5) || (ASTMHue > 57.5 && ASTMHue < 80) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   else
      InterpStyle.Linear = true	;
   end
	  
elseif Value == 4
   if Chroma == 2 || Chroma == 4
      if (ASTMHue > 7.5 && ASTMHue < 42.5) || (ASTMHue > 57.5 && ASTMHue < 85)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 6 || Chroma == 8 	  
      if (ASTMHue > 7.5 && ASTMHue < 40) || (ASTMHue > 57.5 && ASTMHue < 82.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma >= 10 
      if (ASTMHue > 7.5 && ASTMHue < 40) || (ASTMHue > 57.5 && ASTMHue < 80) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   else
      InterpStyle.Linear = true	;
   end
	  
elseif Value == 5
   if Chroma == 2 
      if (ASTMHue > 5 && ASTMHue < 37.5) || (ASTMHue > 55 && ASTMHue < 85)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 4 || Chroma == 6 || Chroma == 8 	  
      if (ASTMHue > 2.5 && ASTMHue < 42.5) || (ASTMHue > 55 && ASTMHue < 85) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma >= 10 
      if (ASTMHue > 2.5 && ASTMHue < 42.5) || (ASTMHue > 55 && ASTMHue < 82.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   else
      InterpStyle.Linear = true	;
   end
	  	  
elseif Value == 6
   if Chroma == 2 || Chroma == 4
      if (ASTMHue > 5 && ASTMHue < 37.5) || (ASTMHue > 55 && ASTMHue < 87.5)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 6 	  
      if (ASTMHue > 5 && ASTMHue < 42.5) || (ASTMHue > 57.5 && ASTMHue < 87.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 8 || Chroma == 10 	  
      if (ASTMHue > 5 && ASTMHue < 42.5) || (ASTMHue > 60 && ASTMHue < 85) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 12 || Chroma == 14 	  
      if (ASTMHue > 5 && ASTMHue < 42.5) || (ASTMHue > 60 && ASTMHue < 82.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma >= 16 
      if (ASTMHue > 5 && ASTMHue < 42.5) || (ASTMHue > 60 && ASTMHue < 80) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   else
      InterpStyle.Linear = true	;
   end
	  
elseif Value == 7	  
   if Chroma == 2 || Chroma == 4 || Chroma == 6
      if (ASTMHue > 5 && ASTMHue < 42.5) || (ASTMHue > 60 && ASTMHue < 85)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 8 	  
      if (ASTMHue > 5 && ASTMHue < 42.5) || (ASTMHue > 60 && ASTMHue < 82.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 10 	  
      if (ASTMHue > 30 && ASTMHue < 42.5) || (ASTMHue > 5 && ASTMHue < 25) || (ASTMHue > 60 && ASTMHue < 82.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 12  	  
      if (ASTMHue > 30 && ASTMHue < 42.5) || (ASTMHue > 7.5 && ASTMHue < 27.5) || (ASTMHue > 80 && ASTMHue < 82.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma >= 14 
      if (ASTMHue > 32.5 && ASTMHue < 40) || (ASTMHue > 7.5 && ASTMHue < 15) || (ASTMHue > 80 && ASTMHue < 82.5) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   else
      InterpStyle.Linear = true	;
   end

elseif Value == 8
   if Chroma == 2 || Chroma == 4 || Chroma == 6 || Chroma == 8 || Chroma == 10 || Chroma == 12 
      if (ASTMHue > 5 && ASTMHue < 40) || (ASTMHue > 60 && ASTMHue < 85)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma >= 14 
      if (ASTMHue > 32.5 && ASTMHue < 40) || (ASTMHue > 5 && ASTMHue < 15) || (ASTMHue > 60 && ASTMHue < 85) 
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   else
      InterpStyle.Linear = true	;
   end
	  
elseif Value == 9
   if Chroma == 2 || Chroma == 4
      if (ASTMHue > 5 && ASTMHue < 40) || (ASTMHue > 55 && ASTMHue < 80)
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma == 6 || Chroma == 8 || Chroma == 10 || Chroma == 12 || Chroma == 14	  
      if (ASTMHue > 5 && ASTMHue < 42.5)  
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   elseif Chroma >= 16 
      if (ASTMHue > 35 && ASTMHue < 42.5)  
	     InterpStyle.Radial = true	;
	  else
		 InterpStyle.Linear = true	;
	  end
   else
      InterpStyle.Linear = true	;
   end

end
   
% Set successful status return code and return
Status.ind = 1;
return