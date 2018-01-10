function ConsolidateShadeBankFile(ShadeBankFile, ShadeBankDirectory);
% Purpose		A shade bank might contain repeated measurements of a particular RGB
%				triple.  If so, average those measurements, and list that triple only once.  
%
% Description	This routine is intended to manage a large shade bank of RGBs, that is
%				used for reproducing colours via printer.  A shade bank was started by
%				printing out a large number of RGBs, and measuring them with a
%				spectrophotometer.  Algorithms to reproduce target colours caused other
%				RGBs to be printed out and measured.  These new RGBs were added to the
%				shade bank, which could easily grow to several thousand colours.  
%
%				It was found that sometimes a particular RGB appeared more than once in
%				the shade bank.  Variations in measurement made its reflectance spectrum
%				slightly different for each appearance.  This slight difference could
%				cause numerical instability.  
%
%				To avoid these problems, this routine identifies all the cases where an
%				RGB appears multiple times in a shade bank.  The reflectance spectra for
% 				all the appearances are then averaged.  All appearances of the same RGB
%				are merged into one, which is assigned the average spectrum.
%
%				ShadeBankFile	Comma-separated file with header line giving wavelengths.  Subsequent
%								lines give RGB components, followed by reflectances
%
%				ShadeBankDirectory	The directory containing the shade bank file.  This input
%									is optional.  The routine will default to the current directory
%									if this input is not present
%
% Author		Paul Centore (November 22, 2014)
% Revised		Paul Centore (July 1, 2015)
%				---Allowed input directory to have final slash or not
%
% Copyright 2014-2015 Paul Centore
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

% A flag for displaying the number of repeated RGBs to the user
DisplayInfoToUser = true	;

% Default to the current directory if the inputs do not specify a directory
if not(exist('ShadeBankDirectory'))
	ShadeBankDirectory = '.'	;
end

% Remove the final slash from the directory name if needed
if strcmp(ShadeBankDirectory,'/')	% Directory name contains a slash: remove it
	ShadeBankDirectoryWithoutFinalSlash = ShadeBankDirectory(1:(end-1))	;
else								% Directory name contains no slash: don t change it
	ShadeBankDirectoryWithoutFinalSlash = ShadeBankDirectory	;
end

% Open the shade bank file and read the data
FullShadeBankFileName = [ShadeBankDirectoryWithoutFinalSlash,'/',ShadeBankFile]	;
fid  = fopen(FullShadeBankFileName, 'r');
% Read the file into a matrix; strings in the file will not appear as strings, but
% numbers will be preserved.
AllFileData = dlmread(fid, ',')	;
fclose(fid)						;
% Every row of the file except the first is data for one RGB triple.  The first
% three entries of each row are the RGB values, between 0 and 1.  The
% remaining entries are the reflectances for the wavelengths listed in the first row.
RGBsAndReflectances = AllFileData(2:end,:)	;

% Express the RGBs as integers between 0 and 255, so that equality comparisons can be
% made without numerical issues
RGBs                       = RGBsAndReflectances(:,1:3)	;
RGBs                       = round(255 * RGBs)			;
RGBsAndReflectances(:,1:3) = RGBs						;

% Sort the data by ascending RGBs.  That way, repeated RGBs will occur in a consecutive
% sequence
SortedData = sortrows(RGBsAndReflectances, [1 2 3])	;

% Go through the sorted data file from the first row to the last.  If the same RGB triple
% occurs multiple times, then all the occurrences will appear in a block in the sorted
% matrix.  Identify all such blocks, one after the other.  Average the reflectances (for each 
% wavelength) within each block; the average reflectance will appear in the consolidated
% matrix.    
RepeatedRGBs  = []		; 	% A 3-column matrix of RGBs which occur more than once
ComparisonEps = 0.0001	;	% Use as a comparison threshold (in case entries are not integers)
ConsolidatedRGBsAndReflectances = []	;
NumberOfShadeBankEntries = size(SortedData,1)	;
ctr = 1	;
while ctr <= NumberOfShadeBankEntries

	% Display updates if desired, for large files
	if mod(ctr,1000) == 0
		disp(['ctr: ',num2str(ctr)])
		fflush(stdout);
	end

	% SortedData sorts all the RGBs, so that repeated RGBs occur in blocks of consecutive
	% rows.  Extract each block, by keeping track of how many times (if any) the first
	% row of RGBs is repeated.
	NumberOfIdenticalRows = 1	;
	R = SortedData(ctr,1)	;
	G = SortedData(ctr,2)	;
	B = SortedData(ctr,3)	;
	% Check immediately subsequent rows, to see how many are identical to the initial row
	RepeatCtr = ctr + 1		;	
	CheckNextRow = true		;
	while CheckNextRow & RepeatCtr <= NumberOfShadeBankEntries
		nextR = SortedData(RepeatCtr,1)	;
		nextG = SortedData(RepeatCtr,2)	;
		nextB = SortedData(RepeatCtr,3)	;
		if abs(R-nextR) < ComparisonEps & ...
		   abs(G-nextG) < ComparisonEps & ...
		   abs(B-nextB) < ComparisonEps 
		   NumberOfIdenticalRows = NumberOfIdenticalRows + 1	;
		   RepeatCtr = RepeatCtr + 1	;
		else
			CheckNextRow = false		;
	    end
	end
	
	% NumberOfIdenticalRows is the number of rows in a block with identical RGBs.  For
	% possible later analysis, record the repeated RGBs in a 3-column matrix.
	if NumberOfIdenticalRows > 1
		RepeatedRGBs = [RepeatedRGBs; R G B NumberOfIdenticalRows]	;
	end
	
	% Add the block s first RGB to the consolidated file.  If the RGB occurs multiple times,
	% then average the reflectances for the consolidated file.
	if NumberOfIdenticalRows == 1
		ConsolidatedRGBsAndReflectances = [ConsolidatedRGBsAndReflectances; SortedData(ctr,:)]	;
	else
		ConsolidatedRGBsAndReflectances = [ConsolidatedRGBsAndReflectances; ...
						sum(SortedData(ctr:(ctr+NumberOfIdenticalRows-1),:))/ ...
						NumberOfIdenticalRows]	;
	end
	% Express RGBs as numbers between 0 and 1 in consolidated file
	ConsolidatedRGBsAndReflectances(end,1:3) = (1/255)*[R G B]	;
	
	% Advance the counter to the next block
	ctr = ctr + NumberOfIdenticalRows 	;
end

% Display information to the user (if flag is set)
if DisplayInfoToUser
	NumberOfEntriesInConsolidatedShadeBankFile = size(ConsolidatedRGBsAndReflectances,1)	;
	disp([num2str(NumberOfShadeBankEntries),' RGB triples in input file ', ShadeBankFile])
	if NumberOfEntriesInConsolidatedShadeBankFile == 1
		disp([num2str(NumberOfEntriesInConsolidatedShadeBankFile),' RGB triple in consolidated file'])
	else
		disp([num2str(NumberOfEntriesInConsolidatedShadeBankFile),' RGB triples in consolidated file'])
	end
	NumberOfDuplicates = NumberOfShadeBankEntries - NumberOfEntriesInConsolidatedShadeBankFile	;
	if NumberOfDuplicates == 1
		disp(['(',num2str(NumberOfDuplicates),' sample was a repeat)'])
	else
		disp(['(',num2str(NumberOfDuplicates),' samples were repeats)'])
	end
end

% Write the consolidated file to same directory as the input file
FullConsolidatedFileName = [ShadeBankDirectoryWithoutFinalSlash,'/',ShadeBankFile(1:(end-4)), ...
					'Consolidated',num2str(NumberOfEntriesInConsolidatedShadeBankFile), ...
					'.txt']	
% Extract first line from input file, to write to consolidated file
Input_fid = fopen(FullShadeBankFileName, 'r')				;
FirstLine = fgetl(Input_fid)								;
fclose(Input_fid)											;
% Write first line and consolidated data to new file
Consolidated_fid = fopen(FullConsolidatedFileName, 'w')		;
fprintf(Consolidated_fid, '%s\n', FirstLine)				;		
fclose(Consolidated_fid)									;
dlmwrite(FullConsolidatedFileName, ConsolidatedRGBsAndReflectances, ',', '-append')	;