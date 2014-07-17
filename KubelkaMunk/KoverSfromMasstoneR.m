function KoverS = KoverSfromMasstoneR(R);
% Purpose		Given the reflectance R of a paint or ink (at one particular wavelength) applied
%				as a masstone, find K/S in accordance with the Kubelka-Munk model.
%
% Description	This routine implements Equation (20) from [Allen1980].  This equation applies to
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
% Syntax		KoverS = KoverSfromMasstoneR(R);
%
%				R		The reflectance, as a ratio between 0 and 1, of a masstone of a paint or
%						ink, at a particular wavelength.
%
%				KoverS	K/S, where K and S are the absorption and scattering coefficients from 
%						the Kubelka-Munk model, at a particular wavelength.
%
%% Author		Paul Centore (July 21, 2013)
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

if R == 0		% No light at all is reflected (avoid a division by 0)
    KoverS = Inf				;
else			% Generic case, where some light is reflected
    KoverS = ((1-R).^2)./(2*R)	;
end

