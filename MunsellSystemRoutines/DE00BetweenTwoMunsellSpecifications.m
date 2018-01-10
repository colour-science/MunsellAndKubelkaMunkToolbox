function [Status, DE00] = DE00BetweenTwoMunsellSpecifications(MunsellSpec1, MunsellSpec2);
% Purpose		Find the colour difference, given by the CIE DE2000 formula, between two
%				input Munsell specifications.
%
% Description	
%
%				MunsellSpec1	Either a standard Munsell specification, such as 4.2R8.1/5.3,
%								or a Munsell vector in ColorLab format
%
%				MunsellSpec2	Either a standard Munsell specification, such as 4.2R8.1/5.3,
%								or a Munsell vector in ColorLab format
%
%				Status			An output vector that indicates whether there was any
%								problem converting a Munsell input to CIE coordinates
%
%				DE00			The colour difference between the two input Munsell specifications 
%
% Author		Paul Centore (November 2, 2015)
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

DE00       = -99	;
Status.ind = 1		;

CWhitePointXYZ = WhitePointWithYEqualTo100('C/2')	;

% Convert the first Munsell specification to CIE coordinates (xyY, XYZ, and Lab)
[x1 y1 Y1 Status1] = MunsellToxyY(MunsellSpec1);
if Status1.ind ~= 1
    disp(['Could not convert Munsell specification ', MunsellSpec1])	;
    Status.ind = 2														; 
	return
end
[X1, YOut1, Z1] = xyY2XYZ(x1, y1, Y1)						;
Lab1            = xyz2lab([X1, YOut1, Z1], CWhitePointXYZ)	;

% Convert the second Munsell specification to CIE coordinates (xyY, XYZ, and Lab)
[x2 y2 Y2 Status2] = MunsellToxyY(MunsellSpec2);
if Status2.ind ~= 1
    disp(['Could not convert Munsell specification ', MunsellSpec2])	;
    Status.ind = 2														; 
	return
end
[X2, YOut2, Z2] = xyY2XYZ(x2, y2, Y2)						;
Lab2            = xyz2lab([X2, YOut2, Z2], CWhitePointXYZ)	;

% Find the colour difference between the two input Munsell specifications
DE00 = deltaE2000(Lab1, Lab2)								;