function K1 = K1FromIndicesOfRefraction(n1, n2);
% Purpose		Calculate K1, the percentage of light that is perpendicularly reflected, when light
%				goes from a medium of refractive index n1 to a medium of refractive index n2.
%
% Description	This routine implements Equation (3.1) of [Judd1967].
%
% References	[Judd1967] Deane B. Judd and Gunter Wyszecki, Color in Business, Science, and 
%				Industry, 3rd printing, John Wiley and Sons, 1967.
%
%				n1		The index of refraction of the medium through which light arrives.  In
%						most cases, this medium will be air, so n1 should be very near 1.
%
%				n2		The index of refraction of the medium at which light arrives.  In
%						most cases, this medium will be a film of paint or ink.
%
%				K1		The fraction, as a value between 0 and 1, of the light impinging (from
%						OUTside the film) on a paint or ink, that is reflected back 
%						directly from the paint surface, without first entering the paint film.
%
% Author		Paul Centore (October 14, 2013)
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

K1 = ( (n2-n1)./(n1+n2) ).^2	;