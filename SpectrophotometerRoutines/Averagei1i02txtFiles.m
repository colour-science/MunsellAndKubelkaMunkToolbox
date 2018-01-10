function [AverageOutputMatrix,		...
          MedianOutputMatrix,		...
          NameForFileOfAverages,	...
          NameForFileOfMedians,		...
          ListOfColorMunkiCSVfiles] = 	...
		   Averagei1i02txtFiles(InputDirectory, ...
		 						OutputDirectory,				...
		 						NameKey);
% Purpose		Find averages and medians of different sets of i1i02 measurements.
%
% Description   This routine averages multiple i1i02 measurements of the same set
%				of samples.  The i1i02 is an X-Rite i1Pro2 spectrophotometer, inserted in
%				an X-Rite i1 automated scanning table (AST).  The averaged measurements 
%				should have less variance than the
%				original measurements.  The routine also takes the median of the multiple
%				measurements, which is more robust than the average.  
%
%				The measurements are assumed to have been saved in an i1i02 text
%				(.txt) file.  To create such a file, choose the Save option in the
%				i1Profiler.app program, and select 'i1Profiler CGATS Custom (*.txt)' format.
%
%				InputDirectory		The directory from which the i1iO files will be read
%
%				OutputDirectory		The directory in which the files of averages and medians
%									will be saved
%
%				NameKey		A string giving part of the names of the i1i0 files from which 
%							data will be read, and a name for the resulting ColorMunki files
%
% 				AverageOutputMatrix	A matrix containing averaged reflectance values.  The first row
%									gives the wavelengths to which the reflectances apply.  The first
%									four columns consist of placeholders, indicated by -99.  This
%									output file has the same size and shape as each input file
%
%				MedianOutputMatrix	Identical to AverageOutputMatrix, except that the entries are medians
%									rather than averages
%
%				NameForFileOfAverages, NameForFileOfMedians		Names of output files, including
%									directory path 
%
%				ListOfColorMunkiCSVfiles	A list (using {}) of strings, which are the filenames
%									of the ColorMunki .csv files that are produced by converting
%									the i1iO input files.  The ColorMunki files will be averaged,
%									using existing code
%
% Author		Paul Centore (November 22, 2015)
% Revision		Paul Centore (October 19, 2016)
%				---Made more informative output message when no files were found
%
% Copyright 2015, 2016 Paul Centore
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

% Initialize variables
AverageOutputMatrix   = []	;
MedianOutputMatrix    = []	;
NameForFileOfAverages = []	;
NameForFileOfMedians  = []	;

% Count number of i1i0 measurement files to be averaged.  The files all start with the
% same string NameKey and are in the same directory (InputDirectory), but the user does
% not have to specify how many files there are.  Instead, the following code will count
% the number of files.
NumberOfFiles = 0		;
ListOfFileNames = {}	;
AllFilesFound = false	;
while not(AllFilesFound)
	PossibleFileName = [NameKey,'Meas',num2str(NumberOfFiles+1),'_M2.txt']	;
	FullFilePath     = fullfile(InputDirectory, PossibleFileName)			;
	if not(isempty(which(FullFilePath)))
		NumberOfFiles          = NumberOfFiles + 1	;
		ListOfFileNames{end+1} = FullFilePath		;
	else
		AllFilesFound = true	;
	end		
end

% Check to make sure that there really are files to be averaged.  If there is none, then
% return
if NumberOfFiles == 0
	disp(['Warning from routine Average1i!O2txtFiles.m: Set of i1i02 files to be averaged is empty'])
	disp(['One possible file name is ', NameKey,'Meas1_M2.txt'])
	return
end

% Convert each i1i02 .txt file into ColorMunki .csv format
ListOfColorMunkiCSVfiles = {}	;
for ctr = 1:NumberOfFiles
	i1txtFile = ListOfFileNames{ctr}						;
	[EntriesGreaterThan1, ...
	EntriesLessThan0] =   ...
	i1i02txtFileToColorMunkiCSVFormat(i1txtFile)			;
	ColorMunkiCSVfileName = [i1txtFile(1:(end-3)),'csv']	;
	ListOfColorMunkiCSVfiles{end+1} = ColorMunkiCSVfileName	;
end

% A routine already exists to calculate averages and medians for measurements in
% ColorMunki .csv format, so call that routine.
[AverageOutputMatrix,	...
MedianOutputMatrix,		...
NameForFileOfAverages,	...
NameForFileOfMedians] = ...
AverageColorMunkiCSVFiles(ListOfColorMunkiCSVfiles, 	...
					      OutputDirectory,				...
					      NameKey);
