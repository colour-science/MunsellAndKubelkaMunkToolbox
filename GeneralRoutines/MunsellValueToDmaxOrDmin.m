function D = MunsellValueToDmaxOrDmin(MunsellValue);
% Purpose		Convert a Munsell value to a printer Dmax or Dmin value 
%
% Description	A printer, given a fixed inkset, paper, and method of printing,
%				can produce a darkest black and a lightest white (this white is
%				usually the white of the paper).  Dmax is commonly used to
%				quantify the deepest black that a printer can produce, while
%				Dmin quantifies the brightest white it can produce.  White and
%				black can seen be as extremes of shades of grey.  The darkness or  
%				lightness of a grey can be expressed as a reflectance factor: the grey
%				will reflect back a certain percentage of an illuminating light.
%
%				The percentage of light reflected back by an arbitrary surface
%				colour can vary with the wavelength of the light.  The reflectance (or luminance)
%				factor must then be calculated with respect to the photopic luminous
%				efficiency function (CIE Y), and will vary with the spectral power
%				density (SPD) of the illuminating light.  An ideal  
%				grey is a sample colour that reflects the same percentage
%				of light, regardless of the wavelength of that light.  In that case,
%				the reflectance factor can be defined unambiguously to be that 
%				percentage, regardless of the SPD of the illuminant.  In practice,
%				the assumption of an ideal grey is accurate enough for printer applications, 
%				and Dmax and Dmin calculations make that assumption.  
%
%				The D value for an ideal grey is given by the expression
%
%							10^(-D) = (reflectance factor)/100,
%
%				where the reflectance factor is a percentage between 0 and 100.
%				Dmax is the maximum value of D that a printer (actually a
%				printer-inkset-paper combination) can produce, so it defines
%				the darkness of the darkest black.  Similarly, Dmin is the minimum
%				value of D that a printer can produce, so it defines the lightness
%				of the brightest white.
%
%				The Munsell value is a perceptual measure of how light or dark a
%				surface colour is.  It is an invertible function of the reflectance
%				factor of that colour.  Munsell value varies from 0 to 10, and is
%				higher for lighter colours.  A Munsell value of 0 corresponds to an
%				absolute black (which reflects no light, of any wavelength).  A
%				Munsell value of 10 corresponds to an absolute white (which diffusely
%				reflects 100% of every wavelength).  
%
%				Since the D value and the Munsell value are both functions of the 
%				reflectance factor, it is possible to convert between them, which this
%				routine does.
%
%				[ASTMD1535-08] ASTM, Standard D 1535-08, "Standard Practice for Specifying Color by the
%					Munsell System," approved January 1, 2008.
%
% Syntax		D = MunsellValueToDmaxOrDmin(MunsellValue);
%
%				D				The D value of a printed black or white.  Usually,
%								one is only interested in the maximum (Dmax) or
%								minimum (Dmin) D.
%
%				MunsellValue	The Munsell value of a printed black or white.
%
% Related		DmaxOrDminToMunsellValue
% Functions
%
% Required		MunsellValueToLuminanceFactor
% Functions
%
% Author		Paul Centore (July 14, 2012)
%
% Copyright 2012 Paul Centore
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


LuminanceFactorStruct = MunsellValueToLuminanceFactor(MunsellValue)	;
% This routine returns a structure with different possible luminance factors.  Use the
% one specified by the standard [ASTM D1535-08].
LuminanceFactor       = LuminanceFactorStruct.ASTMD153508			;
D                     = -log10(LuminanceFactor/100)					;