function [MCDM, ColourDifferences] = MeanColourDifferenceFromTheMean( ...
											Wavelengths, ...
											Reflectances, ...
											IllumObs);
% Purpose		Calculate the mean colour difference from the mean (MCDM), with respect to 
%				CIE DE 2000.  The MCDM is a simple one-dimensional measure of the
%				variability in a spectrophotometer s object-colour measurements.  
%
% Description   Repeated spectrophotometer measurements of an object-colour sample (i.e.
%				measurements made with the identical spectrophotometer, of  the identical
%				sample, but at different times) will show some variability.  For practical
%				purposes, it is good to have an estimate of this variability.  Standards
%				such as ASTM E2214 give some complicated, multi-dimensional measures for
%				this "repeatability."  The MCDM is a simpler, one-dimensional measure which
%				is easy to interpret.
%
%				The MCDM is used when the reflectance spectrum for one sample is measured 
%				multiple times.  The reflectance spectra measurements will vary.  As long
%				as the instrument is unbiased in each wavelength, the best estimate of the 
%				true reflectance spectrum is the average, or mean, of the reported spectra.
%				Each reported spectrum can then be compared to the mean spectrum, by using
%				a colour difference expression; this routine uses CIE DE 2000.  The result
%				will be a set of colour differences between the reported spectra and the
%				mean spectrum.  The mean of these colour differences is the MCDM.
%
%				Wavelengths		A row vector whose entries are the wavelengths for the reflectance  
%								spectra.  The wavelengths must be evenly spaced
%
%				Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%								between 0 and 1) for various reflectance spectra at the wavelengths
%								listed in the first input
%
%				IllumObs	An illuminant/observer string, such as 'D50/2' or 'F12_64.' The
%							first part is a standard illuminant designation.  The symbol in the
%							middle can be either a forward slash or an underscore.  The number at
%							the end is either 2, 10, 31, or 64.  2 and 31 both correspond to the
%							standard 1931 2 degree observer, while 10 and 64 both correspond to 
%							the standard 1964 10 degree observer.  If no observer is indicated, then
%							the 1931 observer is assumed.  The input IllumObs is optional.
%
% Author		Paul Centore (December 7, 2014)
%
% Copyright 2014 Paul Centore
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

% The white point for the illuminant/observer combination will be needed to calculate
% CIE coordinates and DE 2000 values.
WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs);

NumberOfSpectra = size(Reflectances,1)	;

% Find CIE coordinates for the measured reflectance spectra
CIEcoords           = ReflectancesToCIEwithWhiteY100(Wavelengths, Reflectances, IllumObs)	;
CIEXYZforAllSpectra = CIEcoords(:,1:3)	;

% Calculate the mean reflectance spectrum, which is the best estimate of the true spectrum
MeanSpectrum = sum(Reflectances)/NumberOfSpectra	;
% Find CIE coordinates for the mean spectrum
CIEcoords             = ReflectancesToCIEwithWhiteY100(Wavelengths, MeanSpectrum, IllumObs)	;
CIEXYZforMeanSpectrum = CIEcoords(:,1:3)	;

% Make a list of colour differences between the mean spectrum and the reported spectra
ColourDifferences = []	;
for ctr = 1:NumberOfSpectra
	DE2000 = CIEDE2000ForXYZ(CIEXYZforMeanSpectrum, ...
							 CIEXYZforAllSpectra(ctr,:), ...
							 WhitePointXYZ)	;
	ColourDifferences = [ColourDifferences, DE2000]	;
end

% The MCDM is the mean of all the colour differences
MCDM = mean(ColourDifferences)	;