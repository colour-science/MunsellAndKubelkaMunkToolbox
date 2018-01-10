function DE2000 = CIEDE2000ForxyY(xyYstd, xyYsmp, WhitePointXYZ, KLCH)
% Purpose		Find the CIE Delta E (2000) for two xyY specifications
%
% Description	Convert the two xyY specifications to Lab specifications, and call a routine
%				that calculates the CIE DE 2000 difference for Lab coordinates
%
%				xyYstd		The standard, in xyY coordinates, whose colour we are trying to match
%							with a sample
%
%				xyYsmp		The sample, in xyY coordinates, which is trying to match the colour
%							of a standard
%
%				WhitePointXYZ	The XYZ coordinates, for a given illuminant and observer, of a
%							perfect diffuse reflector, i.e. a surface colour whose reflectance
%							spectrum is 100% across the entire visible spectrum
%
%				KLCH		Coefficients for the difference formula, to be passed to the 
%							routine for the difference formula
%
% Required routines: deltaE2000, taken from the website of Gaurav Sharma: 
%					 http://www.ece.rochester.edu/~gsharma/ciede2000/dataNprograms/deltaE2000.m
%					 CIEDE2000ForXYZ
%
% Author		Paul Centore (June 9, 2012)
% Revised		Paul Centore (December 14, 2013)
%				---Made the whitepoint a variable input, instead of a default
%				---For simplicity and consistency, called the DE2000 formula in XYZ coordinates,
%				   after converting from xyY coordinates
%
% Copyright 2012, 2013 Paul Centore
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

% Convert the standard and the sample from xyY coordinates to XYZ coordinates
[Xstd, Ystd, Zstd] = xyY2XYZ(xyYstd(1), xyYstd(2), xyYstd(3))	;
XYZstd             = [Xstd, Ystd, Zstd]							;
[Xsmp, Ysmp, Zsmp] = xyY2XYZ(xyYsmp(1), xyYsmp(2), xyYsmp(3))	;
XYZsmp             = [Xsmp, Ysmp, Zsmp]							;

% Call the CIE DE 2000 routine for XYZ coordinates.  Pass along the KLCH coefficients if
% they have been input.
if exist('KLCH')
    DE2000 = CIEDE2000ForXYZ(XYZstd, XYZsmp, WhitePointXYZ, KLCH)	;
else
    DE2000 = CIEDE2000ForXYZ(XYZstd, XYZsmp, WhitePointXYZ)			;
end
