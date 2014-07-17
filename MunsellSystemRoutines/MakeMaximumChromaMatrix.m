function MaxChromaMatrix = MakeMaximumChromaMatrix();
% Purpose		Make a matrix that gives the maximum chroma for standard Munsell hues and
%				values.
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
%				The 1943 Munsell renotation ([Newhall1943]) expressed Munsell specifications
%				in terms of a color system standardized by the Commission Internationale de 
%				l Eclairage (CIE).  Table I of [Newhall1943] lists CIE coordinates for
%				different combinations of H, V, and C.  For each combination of H and V,
%				the renotation has a maximum C; if chroma were greater than this maximum,
%				then the specification would not define a colour that could occur
%				as an object colour.
%				The maximum chroma can be seen as an approximation to the MacAdam limit.
%				It is only an approximation because the renotation chromas are all even
%				integers, whereas, in theory, a chroma could take on any positive value.
%
%				This routine extracts the maximum chromas from the renotation data, and
%				saves them off both as a text file, and as a Matlab variable in .mat
%				format.  
%
%				The routine MakeRenotationMatrices has already constructed three data
%				matrices, corresponding to the three CIE coordinates.  The three matrices
%				are combined as fields of a structure, named 
%				RenotationMatrices. Each matrix is triply indexed.  The three indices,
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
%				If a colour exceeds the MacAdam limits, then the three matrices	contain
%				entries of NaN.  The current routine calculates, for each combination of H and
%				V, the maximum chroma for which the matrices contain a numerical entry.  Since
%				greys have chroma 0, they are not included.
%
%				The routine outputs a matrix called MacAdamMatrix, which is doubly indexed, by
%				hue and value.  The hues are taken from HueIndex, except that the 41st entry,
%				for greys, is not used.  The values run from 1 to 9.  Entry (H,V) in
%				MacAdamMatrix is the maximum chroma in the renotation data for a colour of
%				hue H and value V.  In addition, the routine outputs a text file,
%				called MacAdamLimitsFromRenotationData.txt.
%
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		MacAdamMatrix = MakeRenotationMacAdamLimitMatrix();
%
%				MacAdamMatrix	Matrix for MacAdam limits.  See Description for details.
%
% Related		MakeRenotationMatrices
% Functions
%
% Required		MaxChromaForMunsellHueAndValue, MunsellSpecToColorLabFormat
% Functions		
%
% Author		Paul Centore (July 10, 2010)
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

% Initialize a matrix in Matlab format.  Each row of the matrix is of the form
% [HuePrefix , CLHueLetter, Value, MaxChroma], where the first three entries are
% parts of the ColorLab specification for a colour, and the fourth entry is
% the maximum chroma.  There are forty standard Munsell hues, as given below in
% HueList, and nine standard Munsell values, for a total of 360 rows.
MaxChromaMatrix = NaN * ones(360, 4);

% This list of hues will be used to produce text output for a file.
HueList = {'2.5R ', '5R ', '7.5R ', '10R ',...
           '2.5YR', '5YR', '7.5YR', '10YR',...
		   '2.5Y ', '5Y ', '7.5Y ', '10Y ',...
           '2.5GY', '5GY', '7.5GY', '10GY',...
		   '2.5G ', '5G ', '7.5G ', '10G ',...
		   '2.5BG', '5BG', '7.5BG', '10BG',...
		   '2.5B ', '5B ', '7.5B ', '10B ',...
		   '2.5PB', '5PB', '7.5PB', '10PB',...
		   '2.5P ', '5P ', '7.5P ', '10P ',...
		   '2.5RP', '5RP', '7.5RP', '10RP'};
% This is the ColorLab list of Munsell hue designators.
ColourLetters = {'B', 'BG', 'G', 'GY', 'Y', 'YR', 'R', 'RP', 'P', 'PB'};

ctr = 0;
for HueNumber = 1:40		% Loop over hues
   % Write hues in ColorLab format, as a numerical prefix, and an index to a string in
   % the list  {B, BG, G, GY, Y, YR, R, RP, P, PB}.
   HueString = deblank(HueList{HueNumber});
   TempMunsellSpec = [HueString,'1/1'];  % Value and chroma are dummy arguments
   ColorLabMunsellVector = MunsellSpecToColorLabFormat(TempMunsellSpec);
   HuePrefix   = ColorLabMunsellVector(1)	;
   CLHueLetter = ColorLabMunsellVector(4)	;
   for Value = 1:9		% Loop over values
      ctr = ctr + 1;
      [MaxChroma Status] = MaxChromaForMunsellHueAndValue(HuePrefix, CLHueLetter, Value);
	  if Status.ind == 1
	     MaxChromaMatrix(ctr,:) = [HuePrefix , CLHueLetter, Value, MaxChroma];
 	  end
   end
end

% Write the output to a text file, consisting of lines of the
% form      Hue String, Value, Maximum Chroma (MacAdam limit)
fid = fopen('MaxChromasForStandardMunsellHuesAndValues.txt', 'w');

% Add a file description at the top of the file.
fprintf(fid, 'Description:\n');
fprintf(fid, 'The MacAdam limits are the boundaries of the set of surface reflectance colours,\n');
fprintf(fid, 'when viewed in a given illuminant.  Since the Munsell system classifies all\n');
fprintf(fid, 'surface reflectance colours, a colour at the MacAdam limits (also called an optimal\n');
fprintf(fid, 'colour) can also be seen as a colour whose Munsell chroma attains a maximum for a\n');
fprintf(fid, 'given Munsell hue and value.  This file lists the maximum chroma possible for\n');
fprintf(fid, 'colours of one of the 40 standard Munsell hues, and 9 integer Munsell values.\n'); 
fprintf(fid, 'The illuminant is assumed to be the Munsell standard, illuminant C.\n');
fprintf(fid, 'This file was generated by the routine MakeMaximumChromaMatrix.m, which\n');
fprintf(fid, 'has been contributed to ColorLab, an open source set of colour-related routines\n');
fprintf(fid, 'for Matlab or Octave.  A related file is MacAdamLimitsFromRenotationData.txt,\n');
fprintf(fid, 'which gives the maximum chroma for which data is available in the Munsell\n');
fprintf(fid, 'renotation [Newhall1943, Table I].\n');
fprintf(fid, '\n');
fprintf(fid, '[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final\n');
fprintf(fid, '        Report of the O.S.A. Subcommittee on the Spacing of the Munsell\n');
fprintf(fid, '        Colors," Journal of the Optical Society of America, Vol. 33,\n');
fprintf(fid, '        Issue 7, pp. 385-418, 1943.\n');
fprintf(fid, 'DESCRIPTION ENDS HERE\n');

fprintf(fid, '  H\tV\tMaximum Chroma (MacAdam limit)\n');
[row col] = size(MaxChromaMatrix);
for i = 1:row
   for j = 1:10
      if MaxChromaMatrix(i,2) == j
	     LetterCode = ColourLetters{j};
	  end
   end
   tempstr = sprintf('%3.1f%s\t%d\t%4.2f\n',...
                   MaxChromaMatrix(i,1),...
				   LetterCode,...
				   MaxChromaMatrix(i,3),...
				   MaxChromaMatrix(i,4));
   fprintf(fid,tempstr);
end
fclose(fid);

return;