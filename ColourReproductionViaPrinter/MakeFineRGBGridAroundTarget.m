function MakeFineRGBGridAroundTarget(AimPointXYZ, ...
									 ShadeBankFile, ...
									 IllumObs);
% Purpose		Make a finer RGB grid around a target colour.  Print and measure this
%				grid, to identify a printed colour that is very near the target.
%
% Description	This routine is intended as an aid to producing a printed colour that
%				matches a target colour.  The routine should be used when there is a
%				shade bank of reflectance spectra for a large set of RGBs.  Some of those
%				RGBs are near the target colour.  In order to find a more accurate
%				match, a large number of RGBs, in a fine grid around the target colour,
%				are printed and measured---with a large enough set, one of them should be 
%				very near the target.  The boundaries of the grid are determined from the
%				RGBs in the shade bank file that are already near the target; they should
%				indicate how far the new RGBs in the grid should extend, so as to be
%				far enough from the target to provide variety, but not so far as to be
%				unlikely candidates.  
%
%				Once the grid has been calculated, it is printed, so that the user can
%				measure it with a spectrophotometer.  The measurements are read in, and
%				added to the shade bank file, for further analysis.
%
%				AimPointXYZ	A target colour specification in XYZ format, relative to the input illuminant
%							and observer.  It is assumed that the XYZ coordinates are relative to
%							a white point whose Y value is 100.
%
%				ShadeBankFile	Comma-separated file with header line giving wavelengths.  Subsequent
%								lines give RGB components, followed by reflectances.
%
%				IllumObs	An illuminant/observer string, such as 'D50/2' or 'F12/10,' under
%							which the colour comparisons are to be made.  This input is
%							optional.
%
% Author		Paul Centore (January 3, 2014)
%
% Copyright 2014 Paul Centore
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

% Default to Illuminant C with a 2 degree standard observer if no illuminant or observer 
% information is input
if ~exist('IllumObs')
    IllumObs = 'C/2'	;
end

% See how near (in terms of DE 2000) the RGBs in the shade bank are to the aimpoint
[RGBs, DE2000, RankedIndices, FirstWavelengths, FirstReflectances] = ...
					EvaluateDEsToShadeBankFile( AimPointXYZ, ...
												ShadeBankFile, ...
												IllumObs);

% Bin the returned DEs, for later analysis
EdgeVector    = [0:0.5:10,1000]							;
[Counts]      = histc(transpose(DE2000), EdgeVector)	;
HistogramData = [EdgeVector; Counts]	;	% Delete semicolon to show data, if desired

DisplayFigure = false 	;
if DisplayFigure	% Use for displaying a figure if desired
% Print histogram showing DEs between aimpoint and entries in shade bank file
figure
set(gcf, 'Name', ['DEs Around Point of Interest'])
stairs(EdgeVector, Counts)	;
set(gca, 'xlim', [0,11])	;
figname = 'NearbyRGBsTest'	;
print(gcf, [figname,'.eps'], '-deps')	;
print(gcf, [figname,'.png'], '-dpng')	;
print(gcf, [figname,'.jpg'], '-djpg')	;
print(gcf, [figname,'.pdf'], '-dpdf')	;
end

% Create a 3-d lattice of RGB triples that are near AimPointXYZ, in the sense that
% their DEs from AimPointXYZ are small.  The size of the lattice is NumOfGridPoints^3.
% We will start by making a list of RGBs that are near the aimpoint.  There must be at
% least EnoughRGBs in the list to make a grid.  We select the RGBs that are nearest the
% aimpoint.  We work our way up the histogram Counts, starting at the index given by
% cutoffDEindex, and including all RGBs whose DEs are <= EdgeVector(cutoffDEindex).
% If there are not enough RGBs, then we increase the index until there are enough.
% Once we have the list of RGBs, we let the lattice vary over the dimensions R, G, and
% B.  We choose NumOfGridPoints in each dimension, varying evenly between the minimum
% and maximum value of that dimension in the list of RGBs.  Since each RGB dimension is
% described by 8 bits, we multiply the RGB dimensions (which are between 0 and 1) by
% 255, and round.  The final lattice is the Cartesian product of the R values times the
% G values times the B values.  This lattice of RGBs is printed out, so that it can be
% measured.  
FileName        = 'FinerGrid'	;
NumOfGridPoints = 7		;
cutoffDEindex   = 3		;
EnoughRGBs      = 10	;
EnoughDEsFound = false  ;
CumulCounts    = cumsum(Counts)	;	
while ~ EnoughDEsFound
    NumOfRGBs = CumulCounts(cutoffDEindex)	;
	if NumOfRGBs >= EnoughRGBs
	    EnoughDEsFound = true	;
    	RGBsForIndex = RGBs(1:NumOfRGBs,:)	;
	    RGBsForIndex = round(255*RGBsForIndex);
	    minR = min(RGBsForIndex(:,1))		;
	    maxR = max(RGBsForIndex(:,1))		;
	    minG = min(RGBsForIndex(:,2))		;
	    maxG = max(RGBsForIndex(:,2))		;
	    minB = min(RGBsForIndex(:,3))		;
	    maxB = max(RGBsForIndex(:,3))		;
	    indR = unique(round(linspace(minR,maxR,NumOfGridPoints)))		;
	    indG = unique(round(linspace(minG,maxG,NumOfGridPoints)))		;
	    indB = unique(round(linspace(minB,maxB,NumOfGridPoints)))		;
		FinerRGBs = -99*ones(length(indR)*length(indG)*length(indB),3)	;
	    RGBctr = 0	;
	    for Rval = indR
	        for Gval = indG
		        for Bval = indB
			        RGBctr = RGBctr + 1		;
				    FinerRGBs(RGBctr,:) = [Rval Gval Bval]	;
			    end
		    end
	    end
		FinerRGBs = (1/255)*FinerRGBs			;
		PrintRGBs(FinerRGBs, FileName, 23, 15)	;
    else
	    cutoffDEindex = cutoffDEindex + 1	;
	end
end

% During the pause, print the figure using the printer and paper of interest.
% Then measure the printed colours with a spectrophotometer, in the same order in
% which they appear in the matrix FinerRGBs.  If the spectrophotometer is a
% ColorMunki, then click File:Export on the ColorMunki
% window, and choose "Comma separated" as the file type.  Export to a
% file named "FinerGrid_M2.csv" in the current directory, where _x_ is the current iteration.
% If the spectrophotometer is an i1i0 AST, equipped with an i1Pro2, then save to a file
% named "FinerGrid_M2.txt" in the current directory.  This file will then be
% converted to a .csv file in ColorMunki format.
disp(['During the pause, print the figure using the printer and paper of interest.'])	;
disp(['Measure the ',num2str(length(FinerRGBs)),' printed colours in the order in which they appear.  Use either a ColorMunki,'])	;
disp(['or an i1i0 Automatic Scanning Table (AST), equipped with an i1Pro2 spectrophotometer.']);
disp(['If using the AST with the i1Pro2, choose 0.0 to 0.1 as the reflectance range, and']);
disp(['a decimal point as a separator, when saving.  Export to a file named FinerGrid_M2.txt']);
disp(['in the current directory.  (The i1i0 will automatically append _M2 to the chosen file name.)]); 
disp(['If the printed samples are measured with a ColorMunki, then Click File:Export on the ColorMunki'])	;
disp(['window, and choose "Comma separated" as the file type.  Export to a'])	;
disp(['file named FinerGrid_M2.csv in the current directory.  Once the file is saved,'])	;
disp(['press the "y" key (or any other key) to resume the program.'])					;
temp = fflush(stdout);
pause()										;

% Either read in a ColorMunki file that the user created, or convert the i0i1 file into
% ColorMunki format.
if isempty(which('FinerGrid_M2.csv'))
    % An i1i0 was used, rather than a ColorMunki, so convert the output file to
    % ColorMunki format
    [EntriesGreaterThan1, ...
     EntriesLessThan0] =   ...
        i1i02txtFileToColorMunkiCSVFormat('FinerGrid_M2.txt')	;
end        

% Read in ColorMunki file in .csv format
[Wavelengths, Reflectances] = ColorMunkiCSVfileToOctaveFormat('FinerGrid_M2.csv');

% Append the newly measured RGBs to the shade bank file
dlmwrite(ShadeBankFile, [FinerRGBs, Reflectances], ',', '-append')	;
	
% For reference, save the new RGBs and measurements	
dlmwrite('FinerGridShadeBankFormat', [FinerRGBs, Reflectances], ',')	;	
