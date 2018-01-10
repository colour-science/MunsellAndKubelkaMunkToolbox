function MaxExtRenChromaMatrix = MakeMaxExtRenChromaMatrix();
% Purpose		Make a matrix that gives the maximum chroma for which extrapolated renotation data is
%				available, for all combinations of hues and values.  The extrapolated data
%				is taken from the file all.dat ([MCSL2010]).
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
%				different combinations of H, V, and C.  The file all.dat from [MCSL2010]
%				extrapolates to further combinations, some of them 
%				imaginary.  For each combination of H and V, the extrapolated
%				renotation has a maximum C; 
%
%				This routine extracts the maximum chromas from the extrapolated renotation data,
%				and saves them off both as a text file, and as a Matlab variable in .mat
%				format.  
%
%				The routine MakeExtrapolatedRenotationMatrices has already constructed three data
%				matrices, corresponding to the three CIE coordinates.  The three matrices
%				are combined as fields of a structure, named ExtrapolatedRenotationMatrices.
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
%				If all.dat contains no data for that colour, then the three matrices contain
%				entries of NaN.  The current routine calculates, for each combination of H and
%				V, the maximum chroma for which the matrices contain a numerical entry.  Since
%				greys have chroma 0, they are not included.
%
%				The routine outputs a matrix called MaxExtRenChromaMatrix, which is doubly indexed, by
%				hue and value.  The hues are taken from HueIndex, except that the 41st entry,
%				for greys, is not used.  The values run from 1 to 9.  Entry (H,V) in
%				MaxExtRenChromaMatrix is the maximum chroma in the renotation data for a colour of
%				hue H and value V.  In addition, the routine outputs a text file,
%				called MaxExtRenChroma.txt.
%
%				[MCSL2010] http://www.cis.rit.edu/mcsl/online/munsell.php, as of June 12, 2010
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		MaxExtRenChromaMatrix = MakeMaxExtRenChromaMatrix();
%
%				MaxExtRenChromaMatrix	Matrix for maximum chromas in all.dat.
%
% Related		MakeExtrapolatedRenotationMatrices, MakeRenotationMacAdamLimitMatrix
% Functions
%
% Required		
% Functions		
%
% Author		Paul Centore (June 23, 2010)
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

% Load previous renotation data, assembled into Matlab form by the
% routine MakeExtrapolatedRenotationMatrices.
load ExtrapolatedRenotationMatrices.mat

% Initialize a matrix in Matlab format, and one to be used in
% outputting a text file.
MaxExtRenChromaMatrix = NaN * ones(40,9);
outputmatrix          = [];

% The three matrices (x,y, and Y) in the structure ExtrapolatedRenotationMatrices, all
% have the same size.  An entry in any one is NaN if and only if it is alse
% NaN in the other two.  Loop over the first matrix to determine which
% chroma values occur for different hue and value combinations.
[row col] = size(ExtrapolatedRenotationMatrices.x);
for H = 1:40		% Loop over hues
   for V = 1:9		% Loop over values
      % For each hue and value combination, list all the chromas for which renotation data
	  % is available.  The maximum of this list is the MacAdam limit for that
	  % hue and value combination.
      chromalist = [];
	  for C = 1:19
	     if ~isnan(ExtrapolatedRenotationMatrices.x(H,V,C))
		    chromalist = [chromalist 2*C];
		 end
	  end
	  MaxChroma                  = max(chromalist);
	  MaxExtRenChromaMatrix(H,V) = MaxChroma;
	  outputmatrix               = [outputmatrix; H V MaxChroma];
   end
end

% This list of hues will be used to produce text output for a file
HueList = {'2.5R ', '5R ', '7.5R ', '10R ',...
           '2.5YR', '5YR', '7.5YR', '10YR',...
		   '2.5Y ', '5Y ', '7.5Y ', '10Y ',...
           '2.5GY', '5GY', '7.5GY', '10GY',...
		   '2.5G ', '5G ', '7.5G ', '10G ',...
		   '2.5BG', '5BG', '7.5BG', '10BG',...
		   '2.5B ', '5B ', '7.5B ', '10B ',...
		   '2.5PB', '5PB', '7.5PB', '10PB',...
		   '2.5 P', '5P ', '7.5P ', '10P ',...
		   '2.5RP', '5RP', '7.5RP', '10RP',...
		   'N '};

% Write the output to a text file, consisting of 360 lines of the
% form      Hue, Value, Maximum Chroma (MacAdam limit)
fid = fopen('MaxChromaFromExtrapRenotationData.txt', 'w');

% Add a file description at the top of the file.
fprintf(fid, 'Description:\n');
fprintf(fid, 'The MacAdam limits are the boundaries of the set of surface reflectance colours,\n');
fprintf(fid, 'when viewed in a given illuminant.  The Munsell renotation [Newhall1943] expresses\n');
fprintf(fid, 'Munsell colours (which are surface reflectance colours) in xyY coordinates, with\n');
fprintf(fid, 'respect to illuminant C.  The MacAdam limit colours occur when,\n');
fprintf(fid, 'for a given hue and value, the chroma reaches a physically realizable maximum.\n');
fprintf(fid, 'To aid in interpolation and inversion algorithms, the Munsell renotation data\n');
fprintf(fid, 'has been extrapolated.  Some of the extrapolated Munsell "colours" are not\n');
fprintf(fid, 'physically realizable, because they are beyond the MacAdam limits, and their\n');
fprintf(fid, 'renotations might have negative values for the xy chromaticity coordinates.\n');
fprintf(fid, 'This file lists the maximum Munsell chroma, for a given Munsell hue and value,\n');
fprintf(fid, 'for which an extrapolated renotation value is available.\n');   
fprintf(fid, 'This file was generated by the routine MakeMaxExtRenChromaMatrix.m, which\n');
fprintf(fid, 'has been contributed to ColorLab, an open source set of colour-related routines\n');
fprintf(fid, 'for Matlab or Octave.  That routine reads in the renotation data from the file\n');
fprintf(fid, 'ExtrapolatedMunsellRenotation.txt, which is a modified version of the file all.dat,\n');
fprintf(fid, 'obtained from [MCSL2010].  For ease of use,\n');
fprintf(fid, 'the data has also been saved in the Matlab file MaxChromaForExtrapolatedRenotation.mat,\n');
fprintf(fid, 'which can be loaded directly into Matlab or Octave.\n');
fprintf(fid, 'The chromas in this file only apply to the extrapolated data, and might not correspond\n');
fprintf(fid, 'to physically possible chromas.  Another file, MaxChromasForStandardMunsellHuesAndValues.txt,\n');
fprintf(fid, 'gives estimates of physically possible maximum chroma.\n');
fprintf(fid, '\n');
fprintf(fid, '[MCSL2010] http://www.cis.rit.edu/mcsl/online/munsell.php, as of June 12, 2010.\n');
fprintf(fid, '[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final\n');
fprintf(fid, '        Report of the O.S.A. Subcommittee on the Spacing of the Munsell\n');
fprintf(fid, '        Colors," Journal of the Optical Society of America, Vol. 33,\n');
fprintf(fid, '        Issue 7, pp. 385-418, 1943.\n');
fprintf(fid, 'DESCRIPTION ENDS HERE\n');

fprintf(fid, '  H\tV\tMaximum Chroma (MacAdam limit)\n');
[row col] = size(outputmatrix);
for i = 1:row
   tempstr = sprintf('%s\t%d\t%d\n',...
                   HueList{outputmatrix(i,1)},...
				   outputmatrix(i,2),...
				   outputmatrix(i,3));
   fprintf(fid,tempstr);
end
fclose(fid);

% Also, save the maximum chromas in Matlab format, for other Matlab routines.
save MaxChromaForExtrapolatedRenotation.mat MaxExtRenChromaMatrix
return;