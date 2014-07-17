function R_Inf = SaundersonCorrectionInverse(R_m, K1, K2);
% Purpose		Calculate the inverse of the Saunderson correction.
%
% Description	This routine implements Equation (26) of [Allen1980].  This reference also
%				gives a readable derivation and discussion.  The input variables can apply at just 
%				one wavelength, or can be taken to be apply to the entire visible spectrum.
%
%				The Saunderson correction is an adjustment to the Kubelka-Munk model.  The Kubelka-
%				Munk model deals with the behavior of light after that light has entered a film
%				of paint or ink, and assumes that the light s behavior is the same at the air-film
%				interface as it is elsewhere in the film.  In fact, the behavior at the interface is
%				different.  The Saunderson correction models behavior at the interface.
%
%				The Saunderson correction relates two terms, R_m and R_Inf.  R_m is the reflectance
%				fraction that a spectrophotometer (in a 0/0 geometry) would measure.  The light from a
%				spectrophotometer, of course, originates from outside the paint film.  R_inf is the
%				bulk reflectance, which is the fraction of light that would escape from the
%				top of the paint film, if the light originated just inside the paint film, at the top,
%				and was directed into the film.
%
%				This routine calculates R_Inf, if R_m is already known.  The Saunderson correction
%				depends on two physical terms, K1 and K2.  These terms are often not known in practice,
%				and so must be estimated.  K1 can be calculated from the Fresnel Equation (Equation (3.1)
%				of [Judd1967]) if the refractive indices of the paint film and the surrounding air
%				are known. The refractive index of air is very near 1, but the refractive index of the
%				paint film is usually not known.  K2 is usually chosen to be between 0.4 and 0.6. 
%
% References	[Allen1980] Eugene Allen, "Colorant Formulation and Shading," Chap. 7 in
%				Optical Radiation Measurements, Vol. 2: Color Measurement (eds. Franc Grum
%				and C. James Bartleson), Academic Press, 1980.
%				[Judd1967] Deane B. Judd and Gunter Wyszecki, Color in Business, Science, and 
%				Industry, 3rd printing, John Wiley and Sons, 1967.
%
% Syntax		R_Inf = SaundersonCorrectionInverse(R_m, K1, K2);
%
%				R_m		The reflectance, as a ratio between 0 and 1, of a masstone of a paint or
%						ink.  R has the same size as R_Inf, and can be a scalar or a vector.  R_m
%						is the reflectance value that a spectrophotometer would measure.
%
%				R_Inf	The bulk reflectance, as a ratio between 0 and 1, of a masstone 
%						of a paint or ink.  R_Inf is the fraction of light, that has penetrated the
%						top surface of a paint film, that is eventually reflected back out the top,
%						possibly after complicated internal scattering.
%
%				K1		The fraction, as a value between 0 and 1, of the light impinging (from
%						OUTside the film) on a paint
%						or ink, that is reflected back directly from the paint surface, without
%						first entering the paint film.  The Fresnel equation (Equation (3.1) of 
%						[Judd1967] gives an expression for K1 in terms of refractive indices.
%
%				K2		The fraction, as a value between 0 and 1, of the light impinging (from
%						INside the film) on the interface between the film and the surrounding
%						air (or other medium), that is reflected back into the film.  P. 308
%						of [Allen1980] indicates that a theoretical value for K2, assuming 
%						perfectly diffuse light, is 0.6.  In practice, it is not always clear
%						how K2 should be determined, and values as low as 0.4 might be used.
%
% Author		Paul Centore (July 28, 2013)
% Revised		Paul Centore (October 30, 2013)
%				--Used elementwise operations consistently in formula
%
% Copyright 2013 Paul Centore
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

R_Inf = (R_m - K1)./(1 - K1 - K2 + K2.*R_m)	;
