function [RMS,DE00sC] = CompareReflectanceSpectra(Wavelengths,...
											      Targets,...
											      AttemptedMatches);
% Purpose		Given a set of reflectance spectra, and a set of attempted matches for those
%				spectra, evaluate the accuracy of the attempted matches.
%
% Description	This routine quantifies how closely an attempted colour match agrees with the
%				target colour.  Both the targets and the attempted matches are expressed as
%				reflectance spectra, defined over the same set of wavelengths (specified in the
%				input variable Wavelengths).  The inputs are vectorized.  Targets is a matrix,
%				each row of which gives the reflectance spectrum, as reflectances at the
%				wavelengths in Wavelengths, of one target colour.  AttemptedMatches has the
%				same structure, but gives reflectance spectra for the attempted colour matches.
%
%				Two evaluation techniques are used: the root mean square (RMS) and the CIE DE2000
%				colour difference formula.  The root mean square uses the difference, at each
%				wavelength, between a target reflectance spectrum, and the attempted match 
%				reflectance spectrum.  The differences (for all spectra, at all wavelengths) are
%				squared, averaged, and then square-rooted.  This measure comes for the statistical
%				technique of least squares.  The second method, the DE2000 formula, is based more
%				on human perception.  It is the difference a human would perceive if confronted
%				with those two colours.  The DE2000 formula is applied to CIE XYZ coordinates that
%				are calculated with respect to Illuminant C.
%
% Syntax		[RMS,DE00sC] = CompareReflectanceSpectra(Wavelengths,...
%													     Targets,...
%													     AttemptedMatches);
%
%				Wavelengths		A row vector whose entries are the wavelengths for the reflectance  
%								spectra.  The wavelengths must be evenly spaced
%
%				Targets			A matrix, whose rows are the reflectances (expressed as values 
%								between 0 and 1) for various reflectance spectra at the wavelengths
%								listed in the first input. 
%
%				AttemptedMatches	A matrix of the same size as the input Targets.  Each
%								row gives the spectral reflectances of an attempted match for the
%								corresponding row of the input Targets.
%
%				RMS				The root mean square (RMS) of the differences in reflectance values
%								between the values in the input Targets, and the values in the
%								input AttemptedMatches.
%
%				DE00sC			DE2000 colour difference values with respect to Illuminant C.  Each
%								difference is between an input reflectance spectrum, corresponding to
%								a particular row in the input Targets, and the attempted
%								match in the same row of the input AttemptedMatches. 
%
% Author		Paul Centore (August 24, 2013)
% Revision		Paul Centore (January 1, 2014)  
%				 ---Used new CIE coordinate calculation routines, that call OptProp routines
%
% Copyright 2013, 2014 Paul Centore
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

NumOfSpectra     = size(Targets,1)	;

% Initialize output variables
RMS    = -99						;
DE00sC = -99*ones(NumOfSpectra,1)	;

WhitePointXYZ = WhitePointWithYEqualTo100('C/2')	;	% Line added Jan. 1, 2014, to calculate white point

% Find the RMS difference, and a DE2000 value (wrt Ill. C) for each input spectrum
ReflectanceDiffs = []	;
for ctr = 1:NumOfSpectra
    % Calculate reflectance differences across all wavelengths, and save as row in matrix
	ReflectanceDiffs = [ReflectanceDiffs; Targets(ctr,:) - AttemptedMatches(ctr,:)];
	
	% Calculate DE2000 values, with respect to Illuminant C (next two lines modified Jan. 1, 2014)
    ReflectancesCIE = ReflectancesToCIEwithWhiteY100(Wavelengths, Targets(ctr,:), 'C/2')	;
    AttMatCIE       = ReflectancesToCIEwithWhiteY100(Wavelengths, AttemptedMatches(ctr,:), 'C/2')	;
	ReflectancesXYZ = ReflectancesCIE(1,1:3)												;
	AttMatXYZ       = AttMatCIE(1,1:3)														;
	% Following line was modified on Dec. 14, 2013
	DE00sC(ctr,1)   = CIEDE2000ForXYZ(ReflectancesXYZ, AttMatXYZ, WhitePointXYZ)			; 
end

% Sum up all squared reflectance differences, average, and take the square root
RMS = sqrt(sum(sum(ReflectanceDiffs.^2))/(NumOfSpectra * length(Wavelengths)))	;