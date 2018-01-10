function DE2000 = CIEDE2000ForXYZ(XYZstd, XYZsmp, WhitePointXYZ, KLCH)
% Purpose		Find the CIE Delta E (2000) for two XYZ specifications
%
% Description	Convert the two XYZ specifications to Lab specifications, and call a routine
%				that calculates the CIE DE 2000 difference for Lab coordinates
%
%				XYZstd		The standard, in XYZ coordinates, whose colour we are trying to match
%							with a sample
%
%				XYZsmp		The sample, in XYZ coordinates, which is trying to match the colour
%							of a standard
%
%				WhitePointXYZ	The XYZ coordinates, for a given illuminant and observer, of a
%							perfect diffuse reflector, i.e. a surface colour whose reflectance
%							spectrum is 100% across the entire visible spectrum
%
%				KLCH		Coefficients for the difference formula, to be passed to the 
%							routine for the CIEDE 2000 difference formula.  This input is optional
%
% Required routines: deltaE2000, taken from the website of Gaurav Sharma: 
%					 http://www.ece.rochester.edu/~gsharma/ciede2000/dataNprograms/deltaE2000.m
%
% Author		Paul Centore (August 21, 2012)
% Revised		Paul Centore (December 14, 2013)
%				---Made the whitepoint a variable input, instead of a default
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

% Convert the standard and the sample from XYZ coordinates to Lab coordinates
Labstd             = xyz2lab([XYZstd(1), XYZstd(2), XYZstd(3)], WhitePointXYZ)		;

Labsmp             = xyz2lab([XYZsmp(1), XYZsmp(2), XYZsmp(3)], WhitePointXYZ)		;

% Call the difference equation routine for Lab coordinates
if nargin == 3		% No user input for the coefficients in the CIE DE 2000 formula
	DE2000 = deltaE2000(Labstd,Labsmp)							;
else				% The user has input coefficients for the CIE DE 2000 formula
	DE2000 = deltaE2000(Labstd,Labsmp, KLCH)					;
end