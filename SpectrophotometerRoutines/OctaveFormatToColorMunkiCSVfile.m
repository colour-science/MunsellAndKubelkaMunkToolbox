function OctaveFormatToColorMunkiCSVfile( Reflectances, ...
									     ColorMunkiCSVfile);
% Purpose		Save a set of reflectance spectra in a comma-separated file, with the
%				same .csv format that is used by the X-Rite ColorMunki.
%
% Description	The ColorMunki Design measures the reflectance spectrum of a colour sample. The
%				data for a set of colour samples can be exported to a comma-separated (.csv) file,
%				by using the File/Export command and choosing the option 'Comma Separated.'  This
%				routine saves reflectance spectra in such a CSV file.  The
%				Octave/Matlab input consists of a set of vectors of the
%				same length, each entry of which is the reflectance percentage for the 
%				wavelengths between 380 and 730 nm inclusive, in 10 nm increments.
%
%				ColorMunkiCSVfile	Comma-separated file in the same format that would be produced
%									by the Export command of the ColorMunki Design
%
%				Reflectances		A matrix, whose rows are the reflectances (expressed as values 
%									between 0 and 1) for the reflectance spectra of a set of 
%									colour samples, at the values between 380 and 730 nm, in 
%									10 nm increments
%
% Author		Paul Centore (March 14, 2015)
%
% Copyright 2015 Paul Centore
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

% Open the CSV file to be written to
output_fid  = fopen(ColorMunkiCSVfile, 'w')		;

% The first row of a ColorMunki .csv file is a header row.  The first four entries of the header
% row are Name, L*, a*, and b*.  The remainder of the header row is a list of the fixed
% wavelengths at which reflectances are measured.  Write this line directly to the file
FirstOutputLine = ['Name,L*, a*, b*, 380 nm, 390 nm, 400 nm, 410 nm, 420 nm, 430 nm, 440 nm,',...
                   ' 450 nm, 460 nm, 470 nm, 480 nm, 490 nm, 500 nm, 510 nm, 520 nm, 530 nm,',...
				   ' 540 nm, 550 nm, 560 nm, 570 nm, 580 nm, 590 nm, 600 nm, 610 nm, 620 nm,',...
				   ' 630 nm, 640 nm, 650 nm, 660 nm, 670 nm, 680 nm, 690 nm, 700 nm, 710 nm, 720 nm, 730 nm']	;
fprintf(output_fid, '%s\n', FirstOutputLine)	;	
 
% Every row of the file except the first is data for one colour sample.  The first
% four entries of each row are a name, an L* value, an a* value, and a b* value.  The
% remaining entries are the reflectances for the wavelengths listed in the first row.
% Since the colour name is unknown, and the L*a*b* depend on an illuminant, the first
% four entries will contain -99 as a placeholder.

NumberOfReflectanceSpectra = size(Reflectances,1)	;
% Write each reflectance spectrum into one line in the file
for ctr = 1:NumberOfReflectanceSpectra
	OutputLine = '-99,-99,-99,-99, '	;
	% Include the reflectance value for each wavelength
	for WavelengthCtr = 1:36	% There are 36 wavelengths between 380 and 730 nm, in steps of 10
		SingleReflectance = Reflectances(ctr,WavelengthCtr)		;
		if WavelengthCtr ~= 36
			OutputLine = [OutputLine, sprintf('%6.4f',SingleReflectance), ', ']	;
		else	% No comma after the last reflectance
			OutputLine = [OutputLine, sprintf('%6.4f',SingleReflectance)]	;	
		end
	end
	
	% Write the string of reflectances to one line of the file
	if ctr ~= NumberOfReflectanceSpectra
		fprintf(output_fid, '%s\n', OutputLine)	;
	else 		% No return after last line of file
		fprintf(output_fid, '%s', OutputLine)	;
	end
end		

% Close the file and exit
fclose(output_fid)	;