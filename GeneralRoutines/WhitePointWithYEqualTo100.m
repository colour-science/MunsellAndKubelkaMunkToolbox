function WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs);
% Purpose		Find the white point in CIE XYZ coordinates for an illuminant/observer 
%				combination.  Normalize the white point so that Y is 100.
%
% Description	In 1931, the Commission Internationale de l Eclairage (CIE) introduced
%				standards for specifying colours.  The standard involves integrating a colour
%				stimulus (given as a spectral power distribution (SPD) over the visible
%				spectrum) against three fundamental functions.  The three outputs are
%				denoted X, Y, and Z.  Two standard observers have been defined, the first one
%				in 1931 (the 2 degree observer) and the second one in 1964 (the 10 degree
%				observer).  Each observer has a different set of fundamentals.  
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
%				There is some ambiguity in this definition, however, because an illuminant
%				only defines a relative SPD, rather than an absolute SPD.  If the light
%				source doubled its output, then the calculated X, Y, and Z would double
%				in value.  Humans typically adapt to the ambient illumination level, and
%				automatically judge surface colours in terms of that level.  As a result,
%				a white surface appears equally white even if the power produced by the
%				light source is increased or decreased.  In fact, all surface colours 
%				show constancy, in that they do not change visually when the light level
%				changes (within some bounds). 
%
%				In order to compare the colour of a non-white surface with a white surface,
%				some normalization factor is necessary.  A simple normalization is to
%				multiply the relative illuminant SPD by some factor, such that the 
%				Y value for a white surface will take on a constant value, such as 100.
%				This routine calculates the white point for a given combination of
%				illuminant and observer, such that the white point s Y value is in fact
%				100.
%
%				This normalization is tricky, because it is often left implicit, especially
%				in computer code.  A computer program might calculate XYZ with respect to
%				an input illuminant and observer, but the brightness of that XYZ colour
%				cannot be calculated unless the normalizing factor or white point is
%				known.  An additional complication is that different programs might use
%				different normalizations.  The Computational Colour Toolbox, for example,
%				scales XYZ computations such that the Y value of the white point is 100;
%				this scaling is performed in line 85 of the routine r2xyz.m.  Other 
%				routines, then, such as xyz2lab.m, give white points whose Y values are
%				always 100.  While this treatment is consistent, a user cannot necessarily
%				use the Toolbox s CIE coordinates in other programs.  The program OptProp,
%				on the other hand, seems to scale all illuminants so that the white 
%				point s Y value is 1, rather than 100.  While both these programs are
%				internally consistent, a developer who uses their outputs must examine
%				or test their code to see what convention is being used.  The Munsell
%				and Kubelka-Munk Toolbox uses 100, and the current routine highlights that
%				fact in its long name.
%
% Syntax		WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs);
%
%				IllumObs		An illuminant/observer string, such as 'D50/2' or 'F12_64.' The
%								first part is a standard illuminant designation.  The symbol in the
%								middle can be either a forward slash or an underscore.  The number at
%								the end is either 2, 10, 31, or 64.  2 and 31 both correspond to the
%								standard 1931 2 degree observer, while 10 and 64 both correspond to 
%								the standard 1964 10 degree observer.  If no observer is indicated, then
%								the 1931 observer is assumed.
%
% Author		Paul Centore (January 1, 2014)
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

% This routine calls an OptProp routine, which requires a slash between the illuminant and
% the observer.  The Computational Colour Toolbox uses an underscore instead.  In order
% to allow multiple formats, change an underscore to a slash if needed
IllumObsWithSlash = IllumObs	;
for ctr = 1:length(IllumObs)
    if strcmp(IllumObs(ctr),'_') 
	    IllumObsWithSlash(ctr) = '/'	;
	end
end

% Eliminate spaces and only use upper-case, to be consistent with OptProp requirements
IllObsCaps = toupper(deblank(IllumObsWithSlash))	;

% The reflectance function of a white surface is identically 1 (or 100 percent) across
% all wavelengths in the visible spectrum, so construct this reflectance function
Wavelengths       = 400:10:700 				;
WhiteReflectances = ones(size(Wavelengths))	;

% Use an OptProp routine to calculate an un-normalized white point
WhitePointXYZ = roo2xyz(WhiteReflectances, IllObsCaps, Wavelengths)	;

% Normalize this white point so that its Y value is 100
WhitePointXYZ = (100/WhitePointXYZ(2)) * WhitePointXYZ 	;

return; 