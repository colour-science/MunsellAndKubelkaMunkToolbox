function [AverageOutputMatrix,		...
          MedianOutputMatrix,		...
          NameForFileOfAverages,	...
          NameForFileOfMedians] = 	...
		 AverageColorMunkiCSVFiles(ListOfColorMunkiCSVfiles, 	...
		 						   OutputDirectory,				...
		 						   NameKey);
% Purpose		Find averages and medians of different sets of ColorMunki measurements.
%
% Description   This routine averages multiple ColorMunki measurements of the same set
%				of samples.  The averaged measurement should have less variance than the
%				original measurements.  The routine also takes the median of the multiple
%				measurements, which is more robust than the average.  
%
%				The measurements are assumed to have been saved in a comma-separated value
%				(.csv) file.  To create such a file, choose the File:Export option in the
%				ColorMunki program, and select 'comma-separated value' format.
%
% Inputs		ListOfColorMunkiCSVfiles	A list (using {}) of strings, which are the filenames
%											of the ColorMunki .csv files to be averaged.  Each
%											file should have the same number of samples, and should be
%											in ColorMunki .csv format
%
%				OutputDirectory		The directory in which the files of averages and medians
%									will be saved
%
%				NameKey		A string giving part of the names of the file in which the
%							averages and medians will be saved
%
% Outputs		AverageOutputMatrix	A matrix containing averaged reflectance values.  The first row
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
% Author		Paul Centore (October 6, 2012)
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (May 21, 2015)  
%				 ---Calculate median as well as average.
% Revision		Paul Centore (May 22, 2015)  
%				 ---Rounded off medians and averages to four decimal places, to make smaller files.
%
% Copyright 2012-2015 Paul Centore
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

% Extract reflectance data from each input file.  Save them in a 3D
% matrix, indexed by input file, colour sample, and wavelength
NumberOfCSVFiles = length(ListOfColorMunkiCSVfiles)		;
AllReflectances3D = []									;
for ctr = 1:NumberOfCSVFiles
    fid  = fopen(ListOfColorMunkiCSVfiles{ctr}, 'r')	;
    % Read the file into a matrix; strings in the file will not appear as strings, but
    % numbers will be preserved.
    AllFileData = dlmread(fid, ',')						;
    fclose(fid)											;
    [row, col] = size(AllFileData)						;
	AllReflectances3D(ctr,:,:) = AllFileData(2:row, 5:col)	;
end

% Average all the reflectances, for a fixed wavelength and colour sample, over all the
% input files.  Similarly, calculate the medians of the reflectances
AverageReflectances = []	;
MedianReflectances  = []	;
for rowctr = 1:(row-1)
    for colctr = 1:(col-4)
	    AverageReflectances(rowctr,colctr) = mean(AllReflectances3D(:,rowctr,colctr))	;
	    MedianReflectances(rowctr,colctr)  = median(AllReflectances3D(:,rowctr,colctr))	;
	end
end

% Round off the medians and averages, so that the files they produce are smaller
NumberOfDecimalPlaces = 4	;
NumberOfRows    = size(AverageReflectances,1)	;
NumberOfColumns = size(AverageReflectances,2)	;
for rowctr = 1:NumberOfRows
	for colctr = 1:NumberOfColumns
		% First round averages
		UnroundedNumber = AverageReflectances(rowctr,colctr)	;
		RoundedNumber   = str2num(num2str((10^(-NumberOfDecimalPlaces)) * ...
							round((10^(NumberOfDecimalPlaces)) * UnroundedNumber)))	;
		AverageReflectances(rowctr,colctr) = RoundedNumber		;							

		% Then round medians
		UnroundedNumber = MedianReflectances(rowctr,colctr)	;
		RoundedNumber   = str2num(num2str((10^(-NumberOfDecimalPlaces)) * ...
							round((10^(NumberOfDecimalPlaces)) * UnroundedNumber)))	;
		MedianReflectances(rowctr,colctr) = RoundedNumber		;							
	end
end

% If there is a final slash in the output directory name, then remove it
if strcmp(OutputDirectory(end),'/')
	OutputDirectoryNoSlash = OutputDirectory(1:(end-1))	;
else
	OutputDirectoryNoSlash = OutputDirectory			;
end	

% Create an output file for the averages by starting with one CSV file, and modifying some entries
AverageOutputMatrix = AllFileData							;
AverageOutputMatrix(:,1:4)   = -99							;
AverageOutputMatrix(2:row,5:col) = AverageReflectances		;
NameForFileOfAverages = [OutputDirectoryNoSlash,'/AvOf',num2str(NumberOfCSVFiles),NameKey,'.csv']	;
dlmwrite(NameForFileOfAverages, AverageOutputMatrix, ',')	;

% Similarly, create an output file for the medians by starting with one CSV file, and modifying some entries
MedianOutputMatrix = AllFileData							;
MedianOutputMatrix(:,1:4)   = -99							;
MedianOutputMatrix(2:row,5:col) = MedianReflectances		;
NameForFileOfMedians = [OutputDirectoryNoSlash,'/MedianOf',num2str(NumberOfCSVFiles),NameKey,'.csv'];	
dlmwrite(NameForFileOfMedians, MedianOutputMatrix, ',')	;