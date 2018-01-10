function Beta = cart2bary (T, P)
## Copyright (C) 2007 David Bateman
##
## This file is part of Octave.
##
## Octave is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Conversion of Cartesian to Barycentric coordinates.
## Given a reference simplex in N dimensions represented by a
## (N+1)-by-(N) matrix, and arbitrary point P in cartesion coordinates,
## represented by a N-by-1 row vector can be written as
##
## P = Beta * T
##
## Where Beta is a N+1 vector of the barycentric coordinates. A criteria
## on Beta is that
##
## sum (Beta) == 1
##
## and therefore we can write the above as
##
## P - T(end, :) = Beta(1:end-1) * (T(1:end-1,:) - ones(N,1) * T(end,:))
##
## and then we can solve for Beta as
##
## Beta(1:end-1) = (P - T(end,:)) / (T(1:end-1,:) - ones(N,1) * T(end,:))
## Beta(end) = sum(Beta)
##
## Note below is generalize for multiple values of P, one per row.
[M, N] = size (P);
Beta = (P - ones (M,1) * T(end,:)) / (T(1:end-1,:) - ones(N,1) * T(end,:));
Beta (:,end+1) = 1 - sum(Beta, 2);