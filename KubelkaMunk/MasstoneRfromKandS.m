function R = MasstoneRfromKandS(K,S);
% Purpose		Given K and S (the absorption and scattering coefficients from the Kubelka-Munk
%				model) for a paint or ink, find the reflectance R of that paint or ink, 
%				applied as a masstone.
%
% Description	This routine implements Equation (19) from [Allen1980].  This equation applies to
%				a masstone of paint, which is a layer thick enough to be opaque, in practical
%				applications.  R is the bulk reflectance of the paint at a particular wavelength.
%				The bulk reflectance is the portion of reflected light that first penetrated the
%				paint sample from the exterior.  Technically speaking, it does not include light
%				which reflected directly off the paint s exterior surface, without first entering
%				the paint film.  The R in this equation is sometime denoted R_inf, in order to 
%				distinguish it from R_m, the measured reflectance (which includes light that 
%				reflected directly off the air-paint interface).  The Saunderson correction is
%				used where possible to convert between R_inf and R_m.
%
% References	[Allen1980] Eugene Allen, "Colorant Formulation and Shading," Chap. 7 in
%				Optical Radiation Measurements, Vol. 2: Color Measurement (eds. Franc Grum
%				and C. James Bartleson), Academic Press, 1980.
%
% Syntax		R = MasstoneRfromKandS(K,S);
%
%				R		The reflectance, as a ratio between 0 and 1, of a masstone of a paint or
%						ink.  R has the same size as K and S, and can be a scalar or a vector.
%
%				K,S		The absorption and scattering coefficients from the Kubelka-Munk model. K
%						and S should be scalars, or vectors of the same length.
%
% Author		Paul Centore (July 24, 2013)
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

if isempty(K) 
	disp(['ERROR: K is empty.'])	;
	return
end

if isempty(S) 
	disp(['ERROR: S is empty.'])	;
	return
end

if length(K) ~= length(S)
	disp(['ERROR: K has ,',length(K),' elements and S has ,',length(S),' elements.'])	;
	disp(['They should have the same number of elements.'])								;
	return
end

for ctr = 1:length(K)
	indK = K(ctr)	;
	indS = S(ctr)	;
	if indS == 0  % If no light is scattered, then all light is absorbed, and reflectance is 0
		R(ctr) = 0	;
	else
		R(ctr) = 1 + (indK/indS) - sqrt(((indK/indS)^2) + (2 * indK/indS))		;
	end
end