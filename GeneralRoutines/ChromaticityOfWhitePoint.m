function [x, y] = ChromaticityOfWhitePoint(IllumObs);
% Purpose		Find the chromaticity of the white point in CIE xy coordinates for an  
%				illuminant/observer combination.  
%
% Description	In 1931, the Commission Internationale de l Eclairage (CIE) introduced
%				standards for specifying colours.  The standard involves integrating a colour
%				stimulus (given as a spectral power distribution (SPD) over the visible
%				spectrum) against three fundamental functions.  The three outputs are
%				denoted X, Y, and Z.  Two standard observers have been defined, the first one
%				in 1931 (the 2 degree observer) and the second one in 1964 (the 10 degree
%				observer).  Each observer has a different set of fundamentals.  In addition
%				to XYZ coordinates, chromaticity coordinates, denoted x and y, have also
%				been defined.
%
%				A colour stimulus (for a surface colour) occurs when light (with a certain
%				SPD over the visible spectrum) strikes a surface.  The surface reflects the
%				light in accordance with a reflectance spectrum.  The reflectance spectrum
%				is a function over the visible spectrum.  At each wavelength in the visible
%				spectrum, the reflectance function specifies the percentage of light of that
%				wavelength that the surface colour reflects.  The colour stimulus that
%				reaches the observer s eye is the product of the incoming SPD and the
%				reflectance spectrum.  
%
%				An illuminant is a function (over the visible spectrum) that describes the
%				SPD of the light that reaches a surface colour (or that reaches an
%				observer s eye directly).  An illuminant is a mathematical description, and
%				should be distinguished from a light source, which is a physical object 
%				that produces light.  A multitude of standard illuminants have been
%				defined, including Illuminant A, Illuminant C, a series of Illuminant D s
%				(that model light produced by blackbody radiation), and a series of
%				Illuminant F s (that model light produced by fluorescent sources).  
%
%				Rather than defining an SPD in absolute terms, an illuminant only defines
%				an SPD in relative terms.  The illuminant gives the relative power for
%				each wavelength in the visible spectrum.  The light produced by a dimmable
%				bulb would have the same relative SPD, and therefore be described by the
%				same illuminant, even if the bulb s power output varied by orders of
%				magnitude.
%
%				A white surface is defined as a surface that diffusely reflects 100 percent
%				of the light at any wavelength in the visible spectrum.  (Diffuse
%				reflectance means that the reflected light satisfies Lambert s law, causing
%				the surface colour to appear identical, no matter what direction the surface is
%				viewed from.  Diffuse reflectance should be distinguished from specular
%				reflection, which occurs with mirrors, in which the reflected light is
%				stronger in some directions than in others.)  
%				The white point for a given illuminant and observer is the colour perceived
%				by the observer when light of that illuminant is diffusely reflected off
%				a white surface.  The white point is given by the three CIE values: X, Y,
%				and Z.  
%
%				The white point could also be given by chromaticity coordinates x
%				and y, which can be calculated from X, Y, and Z.  The chromaticity is the
%				"colour" that the illuminant would appear, without any regard for a lightness
%				component, when it is compared with other illuminants.  In practice, if
%				all the light sources are in accordance with the illuminant, then colour
%				constancy will make the illuminant itself appear white.
%
%				IllumObs		An illuminant/observer string, such as 'D50/2' or 'F12_64.' The
%								first part is a standard illuminant designation.  The symbol in the
%								middle can be either a forward slash or an underscore.  The number at
%								the end is either 2, 10, 31, or 64.  2 and 31 both correspond to the
%								standard 1931 2 degree observer, while 10 and 64 both correspond to 
%								the standard 1964 10 degree observer.  If no observer is indicated, then
%								the 1931 observer is assumed.
%
% Required		WhitePointWithYEqualTo100, XYZ2xyY
% Functions		
%
% Author		Paul Centore (January 20, 2014)
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

% Default to a C/2 viewing condition, if no illuminant or observer is specified
if ~exist('IllumObs')
    IllumObs = 'C/2' 	;
end

% Calculate the white point of the illuminant-observer combination
WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs);

% Convert from XYZ coordinates to xyY coordinates
X   = WhitePointXYZ(1)	;
YIn = WhitePointXYZ(2)	;
Z   = WhitePointXYZ(3)	;
[x, y, YOut] = XYZ2xyY(X, YIn, Z);
% The [x y] values are the chromaticity coordinates, which will be returned

return; 