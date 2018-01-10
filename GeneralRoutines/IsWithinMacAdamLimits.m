function InsideLimits = IsWithinMacAdamLimits(x, y, Y, Illuminant);
% Purpose		Determine whether an input colour, given by x-y-Y, is within the MacAdam limits
%				for an input illuminant.
%
% Description	In 1931, the Commission Internationale de l'Eclairage (CIE) introduced
%				standards for specifying colours.  In one of these standards,
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
%				observer).  
%
%				The coordinates x and y are chromaticity coordinates.  While Y
%				indicates, roughly speaking, how light or dark a colour is, x and y
%				indicate hue and chroma.  For example, the colour might be saturated red,
%				or a dull green.  The CIE chromaticity diagram ([Foley1990, Sect. 13.2.2]) 
%				displays all chromaticities that are possible for a light source of a fixed
%				luminance, when	the light source is viewed in isolation.  
%
%				A related set of coordinates is the XYZ system.  The Y in the xyY and XYZ
%				systems is identical and has the same interpretation.  The XYZ system has
%				the advantage of linearity: if a colour C1 has coordinates X1-Y1-Z1, and
%				another colour C2 has coordinates X2-Y2-Z2, then the colour aC1 + (1-a)C2,
%				given by pointwise linear interpolation of their spectral power distributions
%				(SPD), or reflectance functions, has coordinates aX1 + (1-a)X2, aY1 + (1-a)Y2,
%				and aZ1 + (1-a)Z2.
%
%				A colour given by xyY coordinates can be imaginary, in the sense that no
%				colour that a human can perceive has those coordinates.  Otherwise, colours
%				are said to be real.  The real colours can be thought of as filling in a
%				region of a three-dimensional Cartesian space, with orthogonal coordinates
%				given by x, y, and Y.  The shape filled is called the Roesch colour solid; an
%				illustration appears in Figure 5(3.7) of [Wyszecki1982].
%
%				In other coordinate systems, the set of real colours takes a different shape.
%				In the XYZ coordinate system, the colour solid has the advantage of being
%				convex.  The convexity follows from the linearity property: if two colours
%				are in the colour solid, then the straight line between them is given by
%				mixtures in different proportions of the two bounding colours.  The Roesch color
%				solid is nearly convex, but not quite.
%
%				The Delaunay tessellation of a convex solid is a set of tetrahedra that contain
%				all points that are within the solid, and no points that are not within the
%				solid.  If the solid is not convex, then some tetrahedra of the tessellation
%				might contain points that are not inside the solid.  To take advantage of this
%				fact, this routine converts from xyY coordinates, where the Roesch colour
%				is not convex, to XYZ coordinates, where the colour solid is convex.
%
%				The boundary of the colour solid is called the MacAdam limits.  A colour that is
%				on the boundary of the colour solid is called an optimal colour.  One interpretation
%				of optimality is that there exists no colour, of the same Munsell hue and value
%				as the optimal colour, that has higher Munsell chroma than the optimal colour. 
%				Another interpretation is that an optimal colour can never appear as another
%				colour that is seen in shadow.
%
%				Optimal colours vary with the illuminant.  One set of xyY coordinates might
%				represent an optimal colour for Illuminant C, for example, but not for Illuminant
%				D65.  The Munsell interpretation above explains this effect, because an object
%				colour will match different Munsell samples under different illuminants.
%
%				Lists of optimal colours have been calculated.  Lists for Illuminants A and D65
%				appear as Tables I(3.7) and II(3.7) in [Wyszecki1982].  The D65 table has been
%				converted into an ASCII file called OptimalColoursForD65.txt, which this function
%				can read.  To avoid repeated file loading, a file is read only once, and then
%				stored as a persistent variable.
%				
%				This function first reads in, or finds in static memory, a list of optimal
%				colours for the input illuminant.  The optimal colours are next converted to
%				XYZ coordinates.  Since the XYZ colour solid is convex, and all the optimal
%				colours are on the bounding surface, the XYZ colour solid is approximated as
%				the convex hull of the optimal colours in XYZ coordinates.  A Delaunay
%				tessellation, consisting of tetrahedra that exactly fill the convex hull, is
%				calculated.  The MATLAB or Octave routine called tsearchn, identifies which
%				tetrahedron, if any, contains the input xyY colour, which is also converted
%				to XYZ coordinates.  If the input colour is in one of the tetrahedra, then
%				it is inside the colour solid, and therefore within the MacAdam limits.  If
%				no tetrahedron contains it, it is outside the MacAdam limits.
%
%				[Foley1990] James D. Foley, Andries van Dam, Steven K. Feiner, & John
%					F. Hughes, Computer Graphics: Principles and Practice, 2nd ed.,
%					Addison-Wesley Publishing Company, 1990.
%				[Wyszecki1982] Gunter Wyszecki & W. S. Stiles, Color Science: Concepts and
%					Methods, Quantitative Data and Formulae, 2nd edition, John Wiley and Sons,
%					1982.
%
% Syntax		InsideLimits = IsWithinMacAdamLimits(x, y, Y, Illuminant);
%
%				x, y, Y				The x-y-Y coordinates of a colour
%
%				Illuminant			A string identifying an illuminant.  
%
%				InsideLimits		An output variable that is TRUE if the colour given by x-y-Y
%									is within the MacAdam limits for the input illuminant, and
%									FALSE otherwise
%
% Related		
% Functions
%
% Required		xyz2XYZ
% Functions		
%
% Author		Paul Centore (July 4, 2010)
% Revision   	Paul Centore (May 9, 2012)
%				 ---Changed ! to ~ so that code would work in both Matlab and Octave.
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

% Make the lists of optimal colours and tessellations static, so that they
% do not have to be loaded each time this routine is called.
persistent AOptimalColours
persistent COptimalColours
persistent D65OptimalColours
persistent ATessellation
persistent CTessellation
persistent D65Tessellation
% Also keep a list of illuminants whose optimal colours have been loaded so far.
persistent LoadedIlluminants

% Check to see whether data has been loaded for the input illuminant
dataloaded = false;
if ~isempty(LoadedIlluminants)
   % Check through the list of illuminants for which data has already been
   % loaded, to see if the input illuminant is there.
   for i = 1:length(LoadedIlluminants)
      if strcmp(Illuminant, LoadedIlluminants{i}) == 1
	     dataloaded = true	;
	  end
   end
end

% If data is not already available in persistent memory, then load the data
if dataloaded == false;
   % Find the file containing a list of optimal colours
   datafile = which(['OptimalColoursForIlluminant',Illuminant,'.txt']);
   if isempty(datafile)
      disp(['ERROR: No optimal colour file for Illuminant ',Illuminant,'.']);
	  return;
   end
   
   % Open the file containing the list of optimal colours
   fid = fopen(datafile, 'r');
   
   % Read through and ignore the description at the start of the file.
   % The line 'DESCRIPTION ENDS HERE' has been added to the file, to
   % indicate when the description ends.
   FileLine = fgetl(fid);
   while strcmp(FileLine, 'DESCRIPTION ENDS HERE') == false
      FileLine = fgetl(fid);
   end

   % Read through line with headings, and discard
   for i = 1:3
      blankspace = fscanf(fid,'%s',1);
   end

   % Apart from a header, the data file is a matrix of three columns, one for
   % x, one for y, and one for Y.  Each row of the matrix is an optimal colour.
   % Each loop iteration reads an optimal colour, and enters it into a matrix.
   data = []	;
   ctr  = 0		;
   while ~feof(fid)
      ctr = ctr + 1;
      % Read in xyY coordinates for an optimal colour
      xIn = fscanf(fid,'%f',1)	;
      yIn = fscanf(fid,'%f',1)	;
      YIn = fscanf(fid,'%f',1)	;
      data = [data; xIn yIn YIn]		;
   end
   fclose(fid);

   % Save matrix of optimal colours in persistent variables, and add the
   % illuminant to the persistent list of illuminants for which optimal
   % colours have been loaded.
   if strcmp(Illuminant,'A') == 1
      AOptimalColours = data			;
	  LoadedIlluminants{end+1} = 'A'	;
   elseif strcmp(Illuminant,'C') == 1
      COptimalColours = data			;
	  LoadedIlluminants{end+1} = 'C'	;
   elseif strcmp(Illuminant,'D65') == 1
	  D65OptimalColours = data			;
	  LoadedIlluminants{end+1} = 'D65'	;
   else
      disp(['ERROR: Illuminant ,',Illuminant,' not on list of illuminants.']);
	  return;
   end

end

% Select list of optimal colours from stored or newly created lists
if strcmp(Illuminant,'A') == 1
   OptColoursInxyY = AOptimalColours 	;
elseif strcmp(Illuminant,'C') == 1
   OptColoursInxyY = COptimalColours 	;
elseif strcmp(Illuminant,'D65') == 1
   OptColoursInxyY = D65OptimalColours 	;
else
   disp(['ERROR in data.']);
   return;
end

% Convert optimal colours from xyY format to XYZ format.  In XYZ format, the
% colour solid is convex, so existing Octave or Matlab routines can be used.
OptColoursInXYZ = []					;
[row col]		= size(OptColoursInxyY)	;
for i = 1:row
   xOpt      = OptColoursInxyY(i,1)	;
   yOpt      = OptColoursInxyY(i,2)	;
   YOpt      = OptColoursInxyY(i,3)	;
   % Convert colour to XYZ coordinates
   [X, newY, Z] = xyY2XYZ(xOpt, yOpt, YOpt);
   % Store XYZ coordinates in matrix of optimal colours
   OptColoursInXYZ(i,:) = [X newY Z]	;
end

% Convert input colour to XYZ coordinates
[XInput, YInput, ZInput] = xyY2XYZ(x, y, Y)	;

% Calculate a tessellation of the optimal colours, if it has not been
% done already.  Save the tessellation as a static variable
if dataloaded == false
   % Construct a Delaunay tessellation of the convex XYZ colour solid
   tessellation = delaunayn(OptColoursInXYZ);
   if strcmp(Illuminant,'A') == 1
      ATessellation = tessellation 	;
   elseif strcmp(Illuminant,'C') == 1
      CTessellation = tessellation 	;
   elseif strcmp(Illuminant,'D65') == 1
      D65Tessellation = tessellation;
   else
      disp(['ERROR in tessellation data.']);
      return;
   end
else  % If the tessellation is already calculated, just use it.
   if strcmp(Illuminant,'A') == 1
      tessellation = ATessellation 	;
   elseif strcmp(Illuminant,'C') == 1
      tessellation = CTessellation 	;
   elseif strcmp(Illuminant,'D65') == 1
      tessellation = D65Tessellation;
   else
      disp(['ERROR 2 in tessellation data.']);
      return;
   end
end

% The routine tsearchn returns the index of the tetrahedron in the Delaunay
% tessellation that contains the input colour.  If no tetrahedron contains
% that colour, then tsearchn returns NaN.
idx = tsearchn(OptColoursInXYZ, tessellation, [XInput, YInput, ZInput])	;
if isnan(idx)
   InsideLimits = false;
else
   InsideLimits = true;
end
return;