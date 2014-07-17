function DrawMunsellHueSheet(HuePrefix, CLHueLetter);
% Purpose		Draw a Munsell sheet, over standard values and chromas, for an input
%				Munsell hue.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form HV/C.  The value is a number between 0 and 10, though
%				in practical cases it usually runs between 1 and 9.  
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
%				5.0R9.0/4.0 is [5 9 4 7] in ColorLab format.  The two inputs to this
%				routine are H1 and H2, respectively.
%
%				The Munsell system is usually presented as a series of sheets, with each
%				sheet displaying all the colours of a fixed hue.  The value increases in
%				integer increments from 1 to 9, while the chroma increases in even integer
%				increments from left to right.  
%
%				This routine draws such a sheet for an input hue.  Although sheets are usually
%				only drawn for hues whose numerical prefixes are 0, 2.5, 5, or 7.5, this
%				routine draws a sheet for an arbitrary hue, such as 6.5RP.
%
%				Any hue can take on values at least between 1 and 9, which are the values 
%				displayed.  For a given hue and value, there is a maximum chroma, called the
%				MacAdam limit.  This routine calls another routine, MaxChromaForMunsellHueAndValue,
%				to calculate the greatest chroma for each value, and then draws a row of
%				colours at that value, out to the maximum chroma.  
%
%				Since computer monitors use a red-green-blue (RGB) specification for colours, each
%				Munsell specification must be converted to RGB coordinates.  This conversion 
%				takes two steps.  First, the routine MunsellToxyY
%				converts the Munsell specification to an xyY specification, in accordance
%				with the Munsell renotation ([Newhall1943]).  The xyY specification was
%				standardized by the Commission Internationale de l Eclairage (CIE) in 1931,
%				and is described in Section 3.7 of [Fairchild2005].  Next, the xyY
%				specification is converted to an XYZ specification, another CIE standard.
%				Finally, the XYZ specification is converted to RGB coordinates.  RGB coordinates
%				vary from computer to computer, and the conversion also needs an illuminant
%				to be specified.  Currently, this routine uses an Apple RGB working space, 
%				with a D65 illuminant, but these can be easily changed.
%
%				[Fairchild2005] Mark D. Fairchild, Color Appearance Models, 2nd ed.,
%					John Wiley & Sons, Ltd., 2005.
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		DrawMunsellHueSheet(HuePrefix, CLHueLetter);
%
%				HuePrefix		A value between 0 and 10 that prefixes a literal Munsell
%								hue description, such as the 6.3 in 6.3RP.
%
%				CLHueLetter		A numerical index to the list of Munsell hue strings,
%								that is given in the description.  For example, the index 2
%								corresponds to BG.
%
% Related		
% Functions
%
% Required		MaxChromaForMunsellHueAndValue, MunsellToxyY, xyY2XYZ, XYZ2RGBapplergbD50
% Functions		
%
% Author		Paul Centore (July 11, 2010)
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

% ColorLab hue letters for Munsell specifications
ColourLetters = {'B', 'BG', 'G', 'GY', 'Y', 'YR', 'R', 'RP', 'P', 'PB'};

figure
figuretitle = ['MunsellSheetFor',deblank(toupper([num2str(HuePrefix),ColourLetters{CLHueLetter}]))];
set(gcf, 'Name', figuretitle, 'Color', [1 1 1]);
% Display the Munsell hue sheet so that one value step equals two chroma steps, as
% is customary.
CVratio = 2;
% Use the variable SizePar to control the size of the Munsell samples displayed
SizePar = 0.8; 

% Draw a row for each value
for Value = 1:9
   % The colours for each value extend out to a maximum chroma
   [MaxChroma Status] = MaxChromaForMunsellHueAndValue(HuePrefix, CLHueLetter, Value);
   for Chroma = 2:2:MaxChroma
      % Convert Munsell specification to RGB coordinates, in three steps
      [x y Y Status] = MunsellToxyY([HuePrefix,Value,Chroma,CLHueLetter]);
	  [X, Y, Z]      = xyY2XYZ(x, y, Y);
	  % The conversion to RGB requires the XYZ values all to be between 0 and 1
	  [R, G, B]      = XYZ2RGBapplergbD65(X/100, Y/100, Z/100);
	  
	  % Draw Munsell sample, centered on the Cartesian point (Chroma, Value)
	  centerx = Chroma	;
	  centery = Value	;
	  cornerX = centerx + [-CVratio*SizePar/2,  CVratio*SizePar/2, CVratio*SizePar/2,...
						   -CVratio*SizePar/2, -CVratio*SizePar/2];
	  cornerY = centery + [ SizePar/2, SizePar/2, -SizePar/2,...
						   -SizePar/2, SizePar/2];	 
	  
	  % If the R, G, and B values are all between 0 and 1, then the colour is  within
	  % gamut, and will be displayed.  If the colour is out of gamut, then an empty box
	  % will be drawn where the colour would have been.
	  if min([R,G,B]) >= 0 & max([R,G,B]) <= 1
	     patch(cornerX, cornerY, [R, G, B], 'EdgeColor', [1 1 1]);
	  else
	     patch(cornerX, cornerY, [1 1 1], 'EdgeColor', [0 0 0]);
	  end
	  hold on
   end
end

set(gca, 'xlim', [0 22], 'ylim', [0 10]);
print(gcf, [figuretitle,'.png'], '-dpng');
return; 