function InterpolatedRGBs = InterpolateLinearlyOverShadeBank(ShadeBankFile, LabAimPoints, IllumObs);
%
% Purpose		Interpolate linearly over a shade bank, to make an initial estimate of
%				the RGB triplets that produce a desired set of aimpoint colours.
%
% Description	This routine was intended as part of an algorithm that identifies RGB triples that,
%				when printed (and viewed under a known illuminant), have a desired set of CIE
%				coordinates.  The input data consist of a set of RGB triples, their corresponding
%				CIE coordinates when printed, and a set of CIE aimpoints, for which RGB triples are
%				desired.  The routine first calculates a tetrahedral tessellation of the RGB
%				triples.  (The write-up "How to Print a Munsell Book" describes why the RGB data
%				should be tessellated, rather than the CIE coordinates.)  The tessellation is a
%				four-column matrix that lists four vertices for each tetrahedron; a vertex is an
%				RGB triple.  The RGB vertices are automatically indexed, in the order in which
%				they are input.  The RGB tessellation can be formally transferred to a CIE tessellation.  As long as
%				the RGB-CIE mapping is fairly regular, the new tessellation will in fact be valid, in
%				that it will contain no overlapping tetrahedra.  
%
%				A given CIE aimpoint is localized by identifying which tetrahedron of the tessellation
%				it belongs to, and where in that tetrahedron it is.  The location within a tetrahedron is
%				expressed in barycentric coordinates, while the tetrahedron itself is given by an
%				index.  The index and barycentric coordinates can apply equally well to RGB or CIE
%				coordinates, so an interpolated RGB value can be calculated.  When printed, this RGB
%				should be closer to the desired CIE coordinates than any of the input RGBs.
%
%				It is possible that the CIE aimpoint is outside the gamut of the input CIE points.  In
%				that case, flag values of -99 are used for many of the returned variables.
%
%				ShadeBankFile		Comma-separated file with header line giving wavelengths.  Subsequent
%									lines give RGB components, followed by reflectances.  The name of
%									this file should be given with its full path.  
%
%				LabAimPoints		A three-column matrix of aimpoints, in Lab coordinates, relative to IllumObs
%
%				IllumObs			An illuminant/observer string, such as 'D50/2' or 'F12/10,' under
%									which colour comparisons are to be made.  This input is optional.
%
%				InterpolatedRGBs	A three-column matrix, the same size as AimPoints, that contains an RGB
%									triple for the corresponding CIE Lab aimpoint
%
% Author		Paul Centore (November 3, 2015)
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

% Default to Illuminant C with a 2 degree standard observer if no illuminant or observer 
% information is input
if ~exist('IllumObs')
    IllumObs = 'C_2'	;
end

% Find the white point for further coordinate conversions
WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs)	;

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

% Convert the reflectance spectra in the shade bank to CIE Lab coordinates, using the
% input illuminant
CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, Reflectances, IllumObs)	;
Lab       = xyz2lab(CIEcoords,WhitePointXYZ)									;

% Check whether the shade bank file has already been tessellated.  If so, read in the
% tessellation rather than recalculating it.
[Directory, Name] = fileparts(ShadeBankFile)	;
IllumObsWithUnderscore = IllumObs	;
IllumObsWithUnderscore(IllumObsWithUnderscore == '/') = '_'	;
TessellationFileName = fullfile(Directory,[Name,IllumObsWithUnderscore,'Tessellation.mat'])	;
if ~isempty(which(TessellationFileName))
	load(TessellationFileName)					;
else
	tessellation = delaunayn(ShadeBankRGBs)		;
	save(TessellationFileName, 'tessellation')	;
	save(TessellationFileName, 'ShadeBankRGBs', 'tessellation')	;
end	

[InterpolatedRGBs, RGBvertices, ~, ~, ~] = ...
		  InterpolateForAimPoints(ShadeBankRGBs, Lab, LabAimPoints, tessellation);