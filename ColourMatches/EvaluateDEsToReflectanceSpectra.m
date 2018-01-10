function [RankedIndices, DE2000] = EvaluateDEsToReflectanceSpectra(CIEXYZ, ...
																   Wavelengths, ...
																   Reflectances, ...
																   IllumObs);
% Purpose		Reflectance spectra for a set of possible colour matches are input, along with a
%				CIE XYZ specification.  Evaluate the DEs between the specification and each
%				reflectance spectrum, for an input combination of illuminant and observer.
%
% Description	This routine helps in finding object colours that agree with an input
%				CIE specification, given by CIEXYZ.  There might be a large
%				number of possible matches.  Their reflectance spectra are given by the 
%				input matrix Reflectances, and all refer to the wavelengths in the input
%				vector Wavelengths.	The accuracy of a match depends not just on the reflectances 
%				of the two colours that should match, but also on the viewing conditions, defined
%				by the illuminant and observer, given in the input IllumObs.  The DE
%				(using the CIE DE 2000 expression) between each possible match and the 
%				aimpoint is calculated.  The DEs are ranked from lowest to highest and
%				returned, along with the corresponding indices of the input matches.
%
%				This routine is similar to EvaluateDEsToReflectanceSpectraMultiIllum,
%				another routine that is used when there are multiple illuminants.  In that
%				case, the aimpoint must be defined by a reflectance spectrum (rather than
%				by CIE XYZ coordinates), because its CIE coordinates will vary with illuminant.
%
%				CIEXYZ 		An object colour specification in XYZ format, relative to the input illuminant
%							and observer.  It is assumed that the XYZ coordinates are relative to
%							a white point whose Y value is 100
%
%				Wavelengths		A row vector whose entries are the wavelengths for the reflectance  
%								spectra.  The wavelengths must be evenly spaced
%
%				Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%								between 0 and 1) for various reflectance spectra at the wavelengths
%								listed in the first input
%
%				IllumObs	An illuminant/observer string, such as 'D50/2' or 'F12/10,' under
%							which the colour matches are to be made
%
%				RankedIndices   The indices of the input reflectance spectra, ordered from the best
%								match to the worst match, of the input set of CIE XYZ coordinates
%
%				DE2000		A vector of CIE DE 2000 differences between the input CIE XYZ coordinates
%							and the rows of the Reflectances matrix.  Their order corresponds to the
%							order of the indices in the output RankedIndices
%
% Author		Paul Centore (December 20, 2013)
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

% Default to Illuminant C with a 2 degree standard observer if no illuminant or observer 
% information is input
if ~exist('IllumObs')
    IllumObs = 'C/2'	;
end

% Convert the input specification into Lab coordinates.  This will be the
% standard against which the reflectance spectra are judged.
WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs)				;
LabStand      = xyz2lab(reshape(CIEXYZ,1,3), WhitePointXYZ)		;

% Convert reflectance spectra into Lab form
% First, convert them into CIE XYZ coordinates
CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, Reflectances, IllumObs);
SpectraXYZ = CIEcoords(:,1:3)				;
%sizSpecXYZ = size(SpectraXYZ)
NumOfSpectra = size(Reflectances,1)			;
SpectraInLab = -99 * ones(NumOfSpectra, 3)	;
for ctr = 1:NumOfSpectra
%disp(['ctr: ', num2str(ctr)]);
%specCtr = SpectraXYZ(ctr,:)
    SpectraInLab(ctr,:) = xyz2lab(SpectraXYZ(ctr,:), WhitePointXYZ)	;
end

% Calculate CIEDE2000 for each reflectance spectrum, compared to the input standard
DE2000diffs = []	;
for ctr = 1:NumOfSpectra
	diff        = deltaE2000(LabStand, SpectraInLab(ctr,:))	;
	DE2000diffs = [DE2000diffs; diff]						;
end

% Rank the possible matches, from lowest DE to highest
[DE2000, RankedIndices] = sort(DE2000diffs)					;