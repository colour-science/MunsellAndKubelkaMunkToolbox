function [R, G, B] = XYZ2RGBapplergbD65(X, Y, Z);
% Purpose		Convert XYZ coordinates to RGB coordinates, using Apple RGB working space,
%				and a D65 illuminant.
%
% Description	The matrix for this conversion is taken from [Lindbloom2010].  
%
%				[Lindbloom2010] http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
%
% Syntax		[R, G, B] = XYZ2RGBapplergbD50(X, Y, Z);
%
%				X, Y, Z		XYZ coordinates for an input colour
%
%				R, G, B		RGB coordinates for the input colour
%
% Related		
% Functions
%
% Required		
% Functions		
%
% Author		Paul Centore (July 11, 2010)
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
%
% Copyright 2010, 2012 Paul Centore
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

ConversionMatrix = [ 2.9515373, -1.2894116, -0.4738445;...
                    -1.0851093,  1.9908566,  0.0372026;...
					 0.0854934, -0.2694964,  1.0912975];
RGB = ConversionMatrix * [X; Y; Z];
R   = RGB(1);
G   = RGB(2);
B   = RGB(3);
return; 