function [RGBs, DE2000, RankedIndices, FirstWavelengths, FirstReflectances] = ...
					EvaluateDEsToShadeBankFile( CIEXYZ, ...
												ShadeBankFile, ...
												IllumObs);
% Purpose		An input shade bank file contains a list of reflectance spectra for
%				various RGBs.  There is also a colorimetric aimpoint, CIEXYZ, defined
%				with respect to an input illuminant-observer combination.  This routine
%				finds the DEs between the shade bank entries and the aimpoint.
%
% Description	Calculate a DE for each shade bank entry, relative to the aimpoint,
%				under the input illuminant-observer viewing conditions.  Rank the
%				entries, and return the rankings.  
%
%				CIEXYZ 		An object colour specification in XYZ format, relative to the input illuminant
%							and observer.  It is assumed that the XYZ coordinates are relative to
%							a white point whose Y value is 100
%
%				ShadeBankFile	Comma-separated file with header line giving wavelengths.  Subsequent
%								lines give RGB components, followed by reflectances
%
%				IllumObs	An illuminant/observer string, such as 'D50/2' or 'F12/10,' under
%							which the colour matches are to be made
%
%				RankedIndices   The indices of the input reflectance spectra, ordered from the best
%								match to the worst match, of the input set of CIE XYZ coordinates
%
%				RGBs		A three-column matrix.  Each row is an RGB triple, with the best-matching triple
%							first, and the remaining rows ranked in order of ascending DE 2000.
%
%				DE2000		A vector of CIE DE 2000 differences between the input CIE XYZ coordinates
%							and the reflectance spectra in the .csv file.  Their order corresponds to the
%							order of the indices in the output RankedIndices
%
%				FirstReflectances	The reflectances of the RGB triple that most closely matches CIEXYZ, under
%									the input illuminant-observer combination
%
%				FirstWavelengths	The wavelengths of entries in FirstReflectances
%
% Author		Paul Centore (December 23, 2013)
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
fid  = fopen(ShadeBankFile, 'r')		;

% Read the file into a matrix; strings in the file will not appear as strings, but
% numbers will be preserved.
AllFileData = dlmread(fid, ',')				;
[row, col] = size(AllFileData)				;

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

% Default to Illuminant C with a 2 degree standard observer if no illuminant or observer 
% information is input
if ~exist('IllumObs')
    IllumObs = 'C/2'	;
end

% Find the DE between CIEXYZ and the entries in the shade bank, under a given
% illuminant-observer combination
[RankedIndices, DE2000] = EvaluateDEsToReflectanceSpectra(CIEXYZ, ...
														  Wavelengths, ...
													      Reflectances, ...
														  IllumObs);
														  
% Make a list of RGBs, in order of ascending DE 2000														  
RGBs = -99 * ones(length(RankedIndices),3)	;
for ctr = 1:length(RankedIndices)
    RGBs(ctr,:) = ShadeBankRGBs(RankedIndices(ctr),:)	;
end

% Extract the wavelengths and reflectances for the RGB in the shade bank that gives
% the best match
FirstWavelengths  = Wavelengths							;
FirstReflectances = Reflectances(RankedIndices(1),:)	;