function ShadeBankRGBs = ProcessInitialShadeBankFile(ShadeBankFile, CSVfileName);
% Purpose		Process a shade bank so that it can be used by a routine that produces accurate
%				printed colour matches.  
%
% Description	The processing involves extracting the list of RGBs, and
%				converting the reflectance data into a ColorMunki .csv format, that the printing
%				routine expects.
%
% Syntax		ShadeBankRGBs = ProcessInitialShadeBankFile(ShadeBankFile);
%
%				ShadeBankFile	Comma-separated file with header line giving wavelengths.  Subsequent
%								lines give RGB components, followed by reflectances
%
%				CSVfileName		A string used to label the output .csv file
%
%				ShadeBankRGBs	A list of the RGBs from the shade bank file
%
% Author		Paul Centore (December 22, 2013)
%
% Copyright 2013 Paul Centore
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

% Convert the information in the input file into a vector of wavelengths, and a 
% matrix of reflectance spectra
% Wavelengths	A row vector whose entries are the wavelengths for the reflectance  
%				spectra of the colour samples in the shade bank file
%
% Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%				between 0 and 1) for the reflectance spectra of the 
%				colour samples in the shade bank file

% Open the shade bank file
fid  = fopen(ShadeBankFile, 'r');

% Read the file into a matrix; strings in the file will not appear as strings, but
% numbers will be preserved.
AllFileData = dlmread(fid, ',')	;
[row, col] = size(AllFileData)	;

% The first row of the file is a header row.  The first three entries of the header
% row are the letters R, G, and B.  The remainder of the header row is a list of 
% wavelengths at which reflectances are measured.  Extract these wavelengths.
Wavelengths = AllFileData(1, 4:col)			;

% Every row of the file except the first is data for one colour sample.  The first
% three entries of each row are the RGB values, between 0 and 1.  The
% remaining entries are the reflectances for the wavelengths listed in the first row.
ShadeBankRGBs = AllFileData(2:row, 1:3)		;
Reflectances  = AllFileData(2:row, 4:col)	;

fclose(fid)									;

% Create the .csv file into which the shade bank file will be converted
csv_fid = fopen(CSVfileName, 'w')			;

% The first line of a ColorMunki .csv file is fixed, so it is written directly to the file
FirstOutputLine = ['Name,L*,a*,b*,380 nm,390 nm,400 nm,410 nm,420 nm,430 nm,440 nm,',...
                   '450 nm,460 nm,470 nm,480 nm,490 nm,500 nm,510 nm,520 nm,530 nm,',...
				   '540 nm,550 nm,560 nm,570 nm,580 nm,590 nm,600 nm,610 nm,620 nm,',...
				   '630 nm,640 nm,650 nm,660 nm,670 nm,680 nm,690 nm,700 nm,710 nm,720 nm,730 nm']	;
fprintf(csv_fid, '%s\n', FirstOutputLine)	;			
fclose(csv_fid)								;

% Each line of the ColorMunki .csv format requires 4 entries before the list of
% reflectances.  Use dummy entries, consisting of -99. 
NumOfRGBs = size(ShadeBankRGBs,1)								;
AugmentedReflectances = [-99*ones(NumOfRGBs,4), Reflectances]	;

% Add the dummy entries and reflectances after the first line of the output .csv file.
dlmwrite(CSVfileName, AugmentedReflectances, ',', '-append')	;