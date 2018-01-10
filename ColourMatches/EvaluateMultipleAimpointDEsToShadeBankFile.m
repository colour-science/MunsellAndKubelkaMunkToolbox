function [MinRGBs, DE2000s] = ...
					EvaluateMultipleAimpointDEsToShadeBankFile( CIEXYZ, ...
												ShadeBankFile, ...
												IllumObs);
% Purpose		An input shade bank file contains a list of reflectance spectra for
%				various RGBs.  There are also some colorimetric aimpoints, CIEXYZ, defined
%				with respect to an input illuminant-observer combination.  This routine
%				finds the smallest DEs between the shade bank entries and each aimpoint.
%
% Description	Calculate the minimum DE for each aimpoint, over every colour in the shade bank,
%				under the input illuminant-observer viewing conditions.  Return the minimum
%				DE for each aimpoint, along with the corresponding RGB.  
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
%				MinRGBs		A three-column matrix.  The ith row is the RGB triple that is closest
%							to the ith input aimpoint
%
%				DE2000s		A vector of CIE DE 2000 differences.  The ith entry is the minimum 
%							DE between the ith input aimpoint, and all the shade bank entries. 
%
% Author		Paul Centore (June 26, 2015)
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

% Initialize the output variables
MinRGBs = []	;
DE2000s = []	;

% Default to Illuminant C with a 2 degree standard observer if no illuminant or observer 
% information is input
if ~exist('IllumObs')
    IllumObs = 'C/2'	;
end

% Compute the white point for further calculations
WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs)				;

% Convert the input aimpoints into Lab coordinates.  
NumberOfAimPoints = size(CIEXYZ,1)					;
LabStand          = -99 * ones(NumberOfAimPoints, 3)	;					
for ctr = 1:NumberOfAimPoints
	LabStand(ctr,:) = xyz2lab(CIEXYZ(ctr,:), WhitePointXYZ)		;
end

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

% Convert the reflectance spectra of the shade bank RGBs into Lab form
% First, convert them into CIE XYZ coordinates
CIEcoords  = ReflectancesToCIEwithWhiteY100(Wavelengths, Reflectances, IllumObs);
SpectraXYZ = CIEcoords(:,1:3)				;
NumOfRGBs = size(Reflectances,1)			;
SpectraInLab = -99 * ones(NumOfRGBs, 3)	;
for ctr = 1:NumOfRGBs
    SpectraInLab(ctr,:) = xyz2lab(SpectraXYZ(ctr,:), WhitePointXYZ)	;
end

% For each aimpoint, calculate the DE to every RGB in the shade bank file.  Save off the
% RGB with the minimum DE, along with that DE
for AimPointCtr = 1:NumberOfAimPoints
	% This routine can be slow, so print out regular progress updates
	if mod(AimPointCtr,25) == 0
		disp(['AimPointCtr: ', num2str(AimPointCtr), ' of ', num2str(NumberOfAimPoints)])
		fflush(stdout);
	end
	
	minDE = 1000000	;	% Start with a number that is higher than any DE, and reduce it
						% as lower DEs are found
	for RGBctr = 1:NumOfRGBs
		diff = deltaE2000(LabStand(AimPointCtr,:), SpectraInLab(RGBctr,:))	;
		if diff < minDE
			minDE                  = diff						;
			DE2000s(AimPointCtr)   = diff						;
			MinRGBs(AimPointCtr,:) = ShadeBankRGBs(RGBctr,:)	;
		end	
	end
end