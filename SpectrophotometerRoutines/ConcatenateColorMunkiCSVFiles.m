function ConcatenateColorMunkiCSVFiles(ListOfColorMunkiCSVfiles, NameForConcatenatedFile);
% Purpose		Concatenate multiple sets of ColorMunki measurements.
%
% Description	The ColorMunki Design spectophotometer can measure a set of colour samples, and export
%				the measurements to a comma-separated value file, as a set of wavelengths and reflectance
%				percentages.  The first line of such a file is a list of headings, all but the first four
%				of which are wavelengths.  Each subsequent line gives the reflectance percetanges, for a
%				particular colour sample, underneath the wavelength headings.
%
%				This routine concatenates several such files into one file.  The first line of
%				the concatenated file is the same header line that appears in each individual file.
%
% Inputs		ListOfColorMunkiCSVfiles	A list (using {}) of strings, which are the filenames
%											of the ColorMunki .csv files to be concatenated.  Each
%											file should be in ColorMunki .csv format
%
%				NameForConcatenatedFile		The name (as a string) for the concatenated file
%
% Author		Paul Centore (October 7, 2012)
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (May 7, 2014)  
%				 ---Corrected some documentation.
%
% Copyright 2012-2014 Paul Centore
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

NewFileID = fopen(NameForConcatenatedFile, 'w')			;
NumberOfCSVFiles = length(ListOfColorMunkiCSVfiles)		;
linectr = 0												;
for ctr = 1:NumberOfCSVFiles
    fid = fopen(ListOfColorMunkiCSVfiles{ctr}, 'r')		;
    linectr = 0							;
	while !feof(fid)
		linectr = linectr + 1			;
		if linectr == 1 && ctr ~= 1
	        fskipl(fid,1)				;
		    fprintf(NewFileID, '\n')	;
	    end
		fileline = fgetl(fid)			;
		if linectr ~= 1
		    fprintf(NewFileID, '\n')	;
		end
		fprintf(NewFileID, fileline)	;
    end
	fclose(fid)							;
end 
fclose(NewFileID)						;