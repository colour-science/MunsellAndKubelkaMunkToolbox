function CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, ReflectanceSpectra, IllumObs)
% Purpose		Given the reflectance spectrum of an object colour, calculate the 
%				CIE coordinates of the visual stimulus for an input illuminant and
%				observer.  Normalize the calculations so that the Y value of the white
%				point would be 100 for that illuminant and observer.
%
% Description	In 1931, the Commission Internationale de l Eclairage (CIE) introduced
%				standards for specifying colours.  The standard involves integrating a colour
%				stimulus (given as a spectral power distribution (SPD) over the visible
%				spectrum) against three fundamental functions.  The three outputs are
%				denoted X, Y, and Z.  Two standard observers have been defined, the first one
%				in 1931 (the 2 degree observer) and the second one in 1964 (the 10 degree
%				observer).  Each observer has a different set of fundamentals.  In addition
%				to XYZ coordinates, there are also xyY coordinates; one can move freely
%				between the two types.  
%
%				A colour stimulus (for a surface colour) occurs when light (with a certain
%				SPD over the visible spectrum) strikes a surface.  The surface reflects the
%				light in accordance with a reflectance spectrum.  The reflectance spectrum
%				is a function over the visible spectrum.  At each wavelength in the visible
%				spectrum, the reflectance function specifies the percentage of light of that
%				wavelength that the surface colour reflects.  The colour stimulus that
%				reaches the observer s eye is the product of the incoming SPD and the
%				reflectance spectrum.  In this
%				routine, the input variable Wavelengths gives a set of wavelengths
%				(in nm), and the input variable ReflectanceSpectra gives the fraction
%				of light reflected, as a value between 0 and 1, for each wavelength.  
%				ReflectanceSpectra can actually
%				be a matrix, each row of which gives a reflectance spectrum for a different
%				surface colour.
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
%				There is some ambiguity in the above definition of colour, however, because an illuminant
%				only defines a relative SPD, rather than an absolute SPD.  If the light
%				source doubled its output, then the calculated X, Y, and Z would double
%				in value.  Humans typically adapt to the ambient illumination level, and
%				automatically judge surface colours in terms of that level.  As a result, surface colours 
%				show constancy, in that they do not change visually when the light level
%				changes (within some bounds). 
%
%				In order to compare the colour of a non-white surface with a white surface,
%				some normalization factor is necessary.  A simple normalization is to
%				multiply the relative illuminant SPD by some factor, such that the 
%				Y value for a white surface will take on a constant value, such as 100.
%				This routine calculates the CIE coordinates for a surface colour described
%				by an input reflectance spectrum, for an input combination of
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
%           	The reflectance spectrum of a surface colour gives the percentage of
%				light reflected by that surface colour, at each wavelength.  In this
%				routine, the input variable Wavelengths gives a set of wavelengths
%				(in nm), and the input variable ReflectanceSpectra gives the percentage
%				of light reflected, for each wavelength.  ReflectanceSpectra can actually
%				be a matrix, each row of which gives a reflectance spectrum for a different
%				surface colour.
%
% Syntax		CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, ReflectanceSpectra, IllumObs)
%
%				Wavelengths			A row vector whose entries are the wavelengths for the reflectance  
%									spectra.  The wavelengths must be evenly spaced
%
%				ReflectanceSpectra	A matrix, whose rows are the reflectances (expressed as values 
%									between 0 and 1) for various reflectance spectra at the wavelengths
%									listed in the first input
%
%				IllumObs		An illuminant/observer string, such as 'D50/2' or 'F12_64.' The
%								first part is a standard illuminant designation.  The symbol in the
%								middle can be either a forward slash or an underscore.  The number at
%								the end is either 2, 10, 31, or 64.  2 and 31 both correspond to the
%								standard 1931 2 degree observer, while 10 and 64 both correspond to 
%								the standard 1964 10 degree observer.  If no observer is indicated, then
%								the 1931 observer is assumed.
%
%				CIEcoords			An output matrix, each of whose rows gives [X Y Z x y Y] coordinates
%									for the input reflectance spectra, under Illuminant C
%
%% Author		Paul Centore (January 1, 2014)
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

% Check to make sure all reflectances are between 0 and 1
if max(max(ReflectanceSpectra)) > 1.0 || min(min(ReflectanceSpectra)) < 0.0
    disp(['Error: Reflectances must be between 0 and 1.'])
	return
end

% Find the un-normalized CIE XYZ values
XYZ = roo2xyz(ReflectanceSpectra, IllumObs, Wavelengths)	;

% Find the un-normalized white point, which should be compatible with the 
% un-normalized CIE XYZ values
UnNormalizedWhitePointXYZ = roo2xyz(ones(size(Wavelengths)), IllumObs, Wavelengths)	;

% Initialize output matrix
NumOfSpectra = size(ReflectanceSpectra, 1) 			;
CIEcoords    = -99 *ones(NumOfSpectra, 6) 			;

% Assign the output matrix, row by row 
for ctr = 1:NumOfSpectra
    % Normalize the CIE XYZ values
    XYZ(ctr,:) = (100/UnNormalizedWhitePointXYZ(2)) * XYZ(ctr,:);
    % Calculate xyY coordinates from XYZ coordinates
    [x, y, Y]  = XYZ2xyY(XYZ(ctr,1), XYZ(ctr,2), XYZ(ctr,3))	;
    % Assign both kinds of coordinates to output matrix
    CIEcoords(ctr,:) = [XYZ(ctr,:), x, y, Y]					;
end