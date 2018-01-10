function [xRen yRen YRen] = MakeExtrapolatedRenotationMatrices();
% Purpose		Convert the extrapolated Munsell renotation data into three MATLAB matrices.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form HV/C.  The value is a number between 0 and 10,
%				although for practical purposes value usually ranges only from 1 to 9.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.6R8.2/4.1 is a light pastel
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
%				observer).  
%
%				The coordinates x and y are chromaticity coordinates.  While Y
%				indicates, roughly speaking, how light or dark a colour is, x and y
%				indicate hue and chroma.  For example, the colour might be saturated red,
%				or a dull green.  The CIE chromaticity diagram ([Foley1990, Sect. 13.2.2]) 
%				displays all chromaticities that are possible for a light source of a fixed
%				luminance, when	the light source is viewed in isolation.  
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
%				coordinates can be found for the reflected light.
%
%				The Munsell renotation went further, by using assessments from 40 human
%				observers of Munsell hue, value, and chroma.  The results of these assessments
%				were averaged, to express xyY coordinates as smooth functions of 
%				Munsell samples.  The renotation used samples from the 1929 Munsell Book of
%				Color, and recommended some changes, summarized in Table III of 
%				[Newhall1943].  For example, the 1929 sample 2.5R8/4 was renotated to
%				2.0R7.8/3.1.  The 1943 Munsell renotation is a standard today, and supersedes
%				previous versions of the Munsell system.
%
%				The conversion data for the Munsell renotation was originally given as 
%				a look-up table, expressing a Munsell specification in xyY coordinates
%				([Newhall1943, Table I]).  Grey values were not included in this table;
%				according to ([Newhall1943, p. 386]), the xy coordinates of any neutral grey
%				are the xy coordinates of the white point of Illuminant C.  
%				The renotation matrices made by the current routine include all the data
%				from ([Newhall1943, Table I]), and augment it with data for greys.
%
%				To aid in interpolation, the renotation data has been
%				extrapolated, sometimes beyond the MacAdam limits, in the file all.dat from
%				[MCSL2010].  The file all.dat has been renamed ExtrapolatedMunsellRenotation.txt,
%				and a description has been added to the top of the file.  This routine
%				uses the extrapolated renotation data.
%
%				This routine makes three data matrices (xRen, yRen, and YRen), one for
%				each of x, y, and Y.   The three matrices
%				give the x, y, and Y coordinates for the extrapolated Munsell renotations.  
%				Each matrix is triply indexed.  The three indices,
%				which are identical for each matrix, are HueIndex, Value Index, and Chroma Index.
%
%				HueIndex goes from 0 to 41, corresponding to Munsell hues, as follows:
%					1 2.5R	 |	 9 2.5Y  |	17 2.5G  |	25 2.5B  |	33 2.5P  |	41 N
%					2 5R	 |	10 5Y	 |	18 5G    |	26 5B    |	34 5P    |
%					3 7.5R	 |	11 7.5Y	 |	19 7.5G  |	27 7.5B  |	35 7.5P  |
%					4 10R	 |	12 10Y   |	20 10G   |	28 10B   |	36 10P   |
%					5 2.5YR |	13 2.5GY |	21 2.5BG |	29 2.5PB |	37 2.5RP |
%					6 5YR	 |	14 5GY   |	22 5BG   |	30 5PB   |	38 5RP   |
%					7 7.5YR |	15 7.5GY |	23 7.5BG |	31 7.5PB |	39 7.5RP |
%					8 10YR	 |	16 10GY  |	24 10BG  |	32 10PB  |	40 10RP  |
%				In addition to chromatic colours, neutral greys are given a hue index of 41.
%
%				ValueIndex runs from 1 to 9, and is equal to the Munsell value.
%
%				ChromaIndex runs from 1 to 19, and is half the Munsell chroma.  Greys, whose
%				chroma is 0, are assigned a ChromaIndex of 20.
%
%				The three matrices	contain entries of NaN for Munsell specifications
%				that are beyond the extrapolated renotation data.  Note that some of the 
%				extrapolated data is beyond the MacAdam limits.
%
%				The three matrices are combined as fields of a structure, named 
%				ExtrapolatedRenotationMatrices.  This routine saves that structure 
%				in a .mat file, for use by other ColorLab routines.
%
%				[Foley1990] James D. Foley, Andries van Dam, Steven K. Feiner, & John
%					F. Hughes, Computer Graphics: Principles and Practice, 2nd ed.,
%					Addison-Wesley Publishing Company, 1990.
%				[MCSL2010] http://www.cis.rit.edu/mcsl/online/munsell.php, as of June 12, 2010
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		[xRen yRen YRen] = MakeExtrapolatedRenotationMatrices();
%
%				xRen, yRen, YRen	Matrices for Munsell renotation data.  See Description
%									 for details.
%
% Related		
% Functions
%
% Required		roo2xy
% Functions		
%
% Author		Paul Centore (September 5, 2010)
% Revision   	Paul Centore (May 9, 2012)
%				 ---Changed ! to ~ so that code would work in both Matlab and Octave.
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (Jan. 1, 2014)  
%				 ---Replaced call to IlluminantCWhitePoint with call to roo2xy (from OptProp).
%
% Copyright 2010, 2012, 2014 Paul Centore
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

% Initialize three extrapolated renotation matrices with NaN everywhere
xRen = NaN * ones(41,9,20);
yRen = NaN * ones(41,9,20);
YRen = NaN * ones(41,9,20);

% Make list of Munsell hues for which renotation data is available
HueList = {'2.5R',  '5R',  '7.5R',  '10R',...
           '2.5YR', '5YR', '7.5YR', '10YR',...
		   '2.5Y',  '5Y',  '7.5Y',  '10Y',...
           '2.5GY', '5GY', '7.5GY', '10GY',...
		   '2.5G',  '5G',  '7.5G',  '10G',...
		   '2.5BG', '5BG', '7.5BG', '10BG',...
		   '2.5B',  '5B',  '7.5B',  '10B',...
		   '2.5PB', '5PB', '7.5PB', '10PB',...
		   '2.5P',  '5P',  '7.5P',  '10P',...
		   '2.5RP', '5RP', '7.5RP', '10RP',...
		   'N'};

fid = fopen('ExtrapolatedMunsellRenotation.txt', 'r');


% Read through and ignore the description at the start of the file.
% The line 'DESCRIPTION ENDS HERE' has been added to the file, to
% indicate when the description ends.
FileLine = fgetl(fid);
while strcmp(FileLine, 'DESCRIPTION ENDS HERE') == false
   FileLine = fgetl(fid);
end

% Read through line with headings, and leading space of second line
for i = 1:6
   blankspace = fscanf(fid,'%s',1);
end

% Each loop iteration reads a line of renotation data, 
% and enters it into renotation matrices
linectr = 0;
while ~feof(fid)
   % Read in Munsell coordinates, and xyY coordinates
   linectr = linectr + 1;
   HStr = fscanf(fid,'%s',1);
   VStr = fscanf(fid,'%s',1);
   CStr = fscanf(fid,'%s',1);
   xStr = fscanf(fid,'%s',1);
   yStr = fscanf(fid,'%s',1);
   YStr = fscanf(fid,'%s',1);
   
   % Determine matrix indices for data just read in
   for i = 1:length(HueList)
      if strcmp(HStr,HueList{i}) == 1
         HueIndex = i;
      end
   end
   ValueIndex  = str2num(VStr);
   ChromaIndex = str2num(CStr)/2;

   if abs(ValueIndex - round(ValueIndex)) < 0.001		% Only record entries with integer values
      % Enter data into appropriate matrix cells
      xRen(HueIndex, ValueIndex, ChromaIndex) = str2num(xStr);
      yRen(HueIndex, ValueIndex, ChromaIndex) = str2num(yStr);
      YRen(HueIndex, ValueIndex, ChromaIndex) = str2num(YStr);
   end
end
fclose(fid);
disp(['number of colours read from file: ',num2str(linectr)]);

% Fill renotation matrices for greys.  The reflectance percentages for the 
% nine integer values are taken from Table II of [Newhall1943].
RenotationPercentages = [1.210, 3.126, 6.555, 12.00, 19.77, 30.05, 43.06, 59.10, 78.66];
for MunsellValue = 1:9			% Loop over nine grey values
   RenotationPercentage   = RenotationPercentages(MunsellValue);
   % In the Munsell renotation, the xy coordinates of neutral greys are taken to be
   % the xy coordinates of Illuminant C
   [xRen(41,MunsellValue,20) yRen(41,MunsellValue,20)] = roo2xy(ones(size([400:10:700])), 'C/2', [400:10:700]);
   % The following line was replaced Jan. 1, 2014 by the line above, by Paul Centore
%   [xRen(41,MunsellValue,20) yRen(41,MunsellValue,20)] = IlluminantCWhitePoint();
   YRen(41,MunsellValue,20) = RenotationPercentage;
end

% Save three matrices as fields of one structure, and save that structure
% as a .mat file.
ExtrapolatedRenotationMatrices.x = xRen;
ExtrapolatedRenotationMatrices.y = yRen;
ExtrapolatedRenotationMatrices.Y = YRen;
save ExtrapolatedRenotationMatrices.mat ExtrapolatedRenotationMatrices;