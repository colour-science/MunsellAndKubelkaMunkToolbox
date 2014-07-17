function OutputMatrix = AverageColorMunkiCSVFiles(ListOfColorMunkiCSVfiles, NameForFileOfAverages);
% Purpose		Average different sets of ColorMunki measurements.
%
% Description   This routine averages multiple ColorMunki measurements of the same set
%				of samples.  The averaged measurement should have less variance than the
%				original measurements.  
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
%				NameForFileOfAverages		A string giving the name of the file in which the
%											averages will be saved
%
% Outputs		OutputMatrix	A matrix containing averaged reflectance values.  The first row
%								gives the wavelengths to which the reflectances apply.  The first
%								four columns consist of placeholders, indicated by -99.  This
%								output file has the same size and shape as each input file.
%
% Author		Paul Centore (October 6, 2012)
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
%
% Copyright 2012 Paul Centore
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
% input files
AverageReflectances = []		;
for rowctr = 1:(row-1)
    for colctr = 1:(col-4)
	    AverageReflectances(rowctr,colctr) = mean(AllReflectances3D(:,rowctr,colctr))	;
	end
end

% Create output file by starting with one CSV file, and modifying some entries
OutputMatrix = AllFileData							;
OutputMatrix(:,1:4)   = -99							;
OutputMatrix(2:row,5:col) = AverageReflectances		;
dlmwrite(NameForFileOfAverages, OutputMatrix, ',')	;