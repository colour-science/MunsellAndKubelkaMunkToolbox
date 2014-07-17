function [XYZ] = SpectralPowerDensityToXYZ(Wavelengths, SpectralPowerPerWavelength, Obs)
% Purpose		Given a spectral power density, calculate its CIE XYZ coordinates
%				for an input observer.
%
% Description	In 1931, the Commission Internationale de l Eclairage (CIE) introduced
%				standards for specifying colours.  The standards involve integrating a colour
%				stimulus (given as a spectral power distribution (SPD) over the visible
%				spectrum) against three colour matching functions, denoted xbar, ybar, 
%				and zbar.  The three outputs are
%				denoted X, Y, and Z.  Two standard observers have been defined, the first one
%				in 1931 (the 2 degree observer) and the second one in 1964 (the 10 degree
%				observer).  Each observer has a different set of functions.  
%
% Syntax		XYZ = SpectralPowerDensityToXYZ(Wavelengths, SpectralPowerPerWavelength, Obs);
%
%				Wavelengths		A row vector whose entries are the wavelengths (in nm) for the   
%								spectral power density matrix.  The wavelengths should be evenly spaced.
%
%				SpectralPowerPerWavelength	A matrix, whose rows are the values for  
%									spectral power densities at the wavelengths
%									listed in the first input.  Each row gives a different density.
%
%				Obs		An indicator for either the 2 degree or the 10 degree standard observer.
%						This input can be either a string or a number.
%
%				XYZ		A matrix with three columns.  The first column gives X coordinates, the
%						second column gives Y coordinates, and the third column gives Z coordiantes.
%						The ith row is the CIE XYZ coordinates for the ith input density.			
%
% Author		Paul Centore (March 26, 2014)
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

% Convert Obs to string such as '2' or '10' if it is input as a number
if ~isstr(Obs)
	ObsAsString = num2str(Obs)	;
else
	ObsAsString = Obs			;
end

% Use an OptProp routine to extract data for the CIE colour matching functions
[CMF,CMFwavelengths] = observer(ObsAsString)	;
xbar = transpose(CMF(:,1))	;
ybar = transpose(CMF(:,2))	;
zbar = transpose(CMF(:,3))	;

% Integrate the spectral power density against the colour matching functions
% to produce CIE X, Y, and Z.  Interpolate first so that common wavelengths
% are used.
xbarInterpolated = interp1(CMFwavelengths, xbar, Wavelengths)	;
ybarInterpolated = interp1(CMFwavelengths, ybar, Wavelengths)	;
zbarInterpolated = interp1(CMFwavelengths, zbar, Wavelengths)	;

% Each row of SpectralPowerPerWavelength gives a different SPD, so integrate
% over all SPDs, one by one.
for ctr = 1:size(SpectralPowerPerWavelength,1)
	X(ctr,1) = sum(xbarInterpolated .* SpectralPowerPerWavelength(ctr,:))	;
	Y(ctr,1) = sum(ybarInterpolated .* SpectralPowerPerWavelength(ctr,:))	;
	Z(ctr,1) = sum(zbarInterpolated .* SpectralPowerPerWavelength(ctr,:))	;
end
XYZ = [X,Y,Z]	;
return