function ShadowMatrix = ShadowSeriesInMunsellSystem(MunsellSpec);
% Purpose		Find the Munsell specifications for an input colour, when seen in 
%				different degrees of shadow.
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
%				5.0R9.0/4.0 is [5 9 4 7] in ColorLab format.  The three inputs to this
%				routine are H1, H2, and V, respectively.  A neutral Munsell
%				grey is a one-element vector in ColorLab format, consisting of the grey
%				value.  For example, N4 is [4] in ColorLab format.
%
%				Suppose that the colour of an object is given by the input Munsell specification.
%				The object, or parts of the object, might be viewed in shadow.  A shadow occurs
%				when less light reaches a shadowed part of the objects than reaches a more
%				brightly lit part.  If the object in full light has CIE standard coordinates
%				(Xl, Yl, Zl), then the object in shadow has coordinates (kXl, kYl, kZl), where
%				0 <= k < 1.  The chromaticity coordinates given in xyY form (Section 3.7 of
%				[Fairchild2005]) are
%									x = X / (X + Y + Z),
%									y = Y / (X + Y + Z),
%									Y = Y. 
%				From these equations, it can be seen that the chromaticity
%				coordinates given by x and y are unchanged when a colour is
%				viewed in shadow, but the relative luminosity coordinate, Y, is reduced.  
%
%				This routine first converts the input colour to xyY form.  Shadow colours then
%				have the same x and y coordinates, but smaller Y values.  Shadow Y values are chosen
%				that correspond to the luminance factors for integer Munsell values, and
%				are less than the original Y value.  For each shadow Y value, Ys, the colour
%				with coordinates (x, y, Ys) is converted to a Munsell specification, and stored
%				as one row in an output matrix.  The output matrix is a 4-column matrix whose
%				first row is the input colour in ColorLab Munsell format, and whose remaining
%				rows give a series of shadow colours for the input colour, in descending order,
%				that take on integer Munsell values.  If the input colour is a Munsell grey,
%				then the output matrix only has one column, because the ColorLab format for
%				a grey only consists of one entry.
%
%				[Fairchild2005] Mark D. Fairchild, Color Appearance Models, 2nd ed.,
%					John Wiley & Sons, Ltd., 2005.
%
% Syntax		ShadowMatrix = ShadowSeriesInMunsellSystem(MunsellSpec);
%
%				MunsellSpec		Either a standard Munsell specification, such as 4.2R8.1/5.3,
%								or a Munsell vector in ColorLab format
%
%				ShadowMatrix	A 4-column matrix where each row gives the ColorLab format
%								of the input colour when seen in some amount of shadow.  The
%								first row is the input colour.  The remaining rows, which
%								correspond to the input colour in different degrees of shadow,
%								are chosen to have descending integer Munsell values.  If the 
%								input colour is grey, then ShadowMatrix only has one column.
%
% Related		
% Functions
%
% Required		MunsellSpecToColorLabFormat, MunsellToxyY, 
% Functions		xyYtoMunsell, MunsellValueToLuminanceFactor
%
% Author		Paul Centore (July 14, 2010)
% Revised		Paul Centore (January 15, 2011)
% Revision		Added MunsellSpec as third argument to call to xyYtoMunsell(), to reflect
%					updates to xyYtoMunsell()
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
%
% Copyright 2010, 2011, 2012 Paul Centore
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

% The input could be either a Munsell string, such as 4.2R8.1/5.3,
% or a Munsell vector in ColorLab format.  Determine which, and convert
% to ColorLab format, if needed.
if ischar(MunsellSpec)
   ColorLabMunsellVector = MunsellSpecToColorLabFormat(MunsellSpec)	;
else
   ColorLabMunsellVector = MunsellSpec	;
end

% The value of the input colour will be needed later.
if length(ColorLabMunsellVector) == 1		% Colour is Munsell grey
   InputMunsellValue = ColorLabMunsellVector(1);
else
   InputMunsellValue = ColorLabMunsellVector(2);
end

% Convert the input colour to xyY notation
[x y Y Status] = MunsellToxyY(MunsellSpec);

% The first colour in ShadowMatrix is the input colour, which will appear in the
% first row.  Subsequent rows will be the Munsell specifications, in ColorLab
% format, of the input colour when seen in shadow.  The Munsell values of the
% rows after the first will be integers, starting at the highest value that is
% less than the Munsell value of the input colour.
ShadowMatrix = ColorLabMunsellVector;

% If the input colour has Munsell value less than or equal to 1, then it is
% already so dark that no shadows will be calculated.
if InputMunsellValue <= 1
   return;
end

% Otherwise, find the highest integer Munsell value that is less than the
% Munsell value of the input colour.
if abs(InputMunsellValue - round(InputMunsellValue)) < 0.001  % Input value is integer
   HighestMunsVal = round(InputMunsellValue - 1)	;
else
   HighestMunsVal = floor(InputMunsellValue)		;
end

% The input colour seen in shadow will have the same chromaticity coordinates (x and y)
% as the input colour, but a smaller Munsell value.  For each integer Munsell value that is
% less than the value of the input colour, calculate the Munsell specification 
% assuming the same chromaticity as the input colour.  Save each shadow, in ColorLab
% format, as a row in ShadowMatrix.
for MunsellValue = HighestMunsVal: -1 : 1
   % Find luminance factor (Y) for the Munsell value
   LuminanceFactors = MunsellValueToLuminanceFactor(MunsellValue)						;
   Yvalue           = LuminanceFactors.ASTMD153508	;	% Use ASTM D 1535-08 standard	
   [MunsellSpec MunsellVec Status]    = xyYtoMunsell(x, y, Yvalue)						;
   % If shadow was successfully calculated, add shadow to shadow matrix
   if Status.ind == 1
      ShadowMatrix = [ShadowMatrix; MunsellVec]	;
   end
end

return; 