function [K, S, ErrorFlag] = KandSusingGJK(M);
% Purpose		Use the GJK algorithm to find the least squares solution to M*[K,S]^T = 0, 
%				subject to Kubelka-Munk constraints on K and S.
%
% Description	This routine is intended to find the Kubelka-Munk coefficients for a set of n
%				constituent paints or colorants.  The ith paint has two Kubelka-Munk coefficients:
%				K_i for absorption, and S_i for scattering.  Express all the coefficients by the vector
%				x = [K_1, K_2, ..., K_n, S_1, S_2, ..., S_n]. The constituent paints have been 
%				mixed in various concentrations, and their reflectance spectra have been measured
%				with a spectrophotometer.  From these measurements and their concentrations, it
%				is possible to derive equations of the form M(x^T) = b, where all the entries of
%				M and b are known.  While the equation likely has no exact solution, a least
%				squares solution can be found that comes as close as possible to satisfying the
%				equation.  These equations, and the output Ks and Ss, implicitly refer to
%				only one wavelength; the calculations must be repeated for other wavelengths.
%
%				In 1987, Walowit, McCarthy, and Berns [Walowit1987] derived one such equation, 
%				and recommended using ordinary least squares to find x.  One occasional difficulty
%				with this approach is that some of the Ks and Ss might be less than 0,
%				while the Kubelka-Munk model, on physical grounds, requires that all
%				Ks and Ss be non-negative. To remedy this difficulty, [Centore2015] suggests
%				using the GJK method instead of ordinary least squares.  The GJK method constructs
%				a convex polytope.  Every point in this polytope corresponds to at least one physically
%				valid selection of Ks and Ss, and every physically valid selection leads to
%				one point in the polytope.  [Centore2015] solves an equation of the form M(x^T) = 0,
%				and Centore s M differs from Walowit s M only by leaving out the bottom row of 1s.  
%				See [Centore2015] for details; the notation in this routine follows that reference.
%
%				The result of this routine, then, is a set of Kubelka-Munk Ks and Ss that satisfy
%				the requirement of being non-negative.  As a normalization factor, the sum of all
%				the Ks and Ss is 1.  This feature distinguishes it from
%				previous algorithms, which do not generally insure the constraints on K and S.
%
% References	[Centore2015] Paul Centore, Enforcing Constraints in Kubelka-Munk Calculations, 
%				available at wwww.99main.com/~centore, 2015
%           	[Walowit1987] Eric Walowit, Cornelius J. McCarthy, & Roy S. Berns, An Algorithm
%				for the Optimization of Kubelka-Munk Absorption and Scattering Coefficients,
%				Color Research and Application, Vol. 12, Number 6, December 1987.
%
%				M			A matrix with one row for each mixture, and two columns for every paint
%							(one column for the K for that paint, and one for the S).  The Kubelka-Munk 
%							coefficients are a constrained least squares solution to M*[K,S]^T = 0.
%
%				K,S			Kubelka-Munk absorption and scattering coefficients for the constituent 
%							paints in the mixtures, at one wavelength.  
%
%				ErrorFlag	A Boolean variable that is true if the routine cannot return a
%							solution, and false otherwise.
%
% Author		Paul Centore (January 19, 2015)
% Revision		Paul Centore (February 19, 2015)
%				-----Switched to a much simpler polytope.  The simplicity was made possible by
%					 only requiring that K and S be non-negative and that all Ks and Ss sum to 1.
%					 The previous version required 0 <= K_i + S_i <= 1 for all i.
%
% Copyright 2015 Paul Centore
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

% Initialize variables
ErrorFlag = false	;
K         = []		;
S		  = []		;

% Infer the number of mixtures and the number of base paints
[NumberOfMixtures, TwiceNumberOfPaints] = size(M)	;
NumberOfPaints = TwiceNumberOfPaints/2				;

% The constrained least squares solution to M*[K,S]^T = 0 corresponds to the point on the convex
% polytope P that is nearest to the origin.  Call the GJK algorithm to calculate
% this point.  The return variable KandS gives the coefficients in a convex
% combination of the generators of P; this convex combination is the closest point on P to
% the origin.  In this case, the coefficients of the combination are the values of K and S directly. 
[ClosestPoint,   ...
  Distance,       ...
  PointInPolytope,...
  KandS,   ...
  ErrorFlag] = ...
  ClosestPointInConvexPolytopeGJK(...
						transpose(M),...
						zeros(1,NumberOfMixtures))	;

% As a precaution, check that the GJK algorithm has returned successfully.  If it has not,
% then use the method suggested in [Walowit1987].
if ErrorFlag								
	disp(['ERROR in KandSusingGJK.m: reverting to lsqnonneg because of error in GJK algorithm'])
	% Calculation suggested in [Walowit1987] (except that we are using non-negative
	% least squares instead of just ordinary least squares).  This reference adds a
	% constraint row of all 1's to the matrix, and an extra 1 to the vector OBS
	KSCOEFS = [M; ones(1,size(M,2))]			;
	OBS     = [zeros(NumberOfMixtures,1); 1]	;
	[KandS, ...
	 ~,     ...
	 ~,     ...
	 exitflag]   = lsqnonneg(KSCOEFS, OBS)		;
	disp('Using lsqnonneg because of error in GJK routine or subroutine')
	% If neither the GJK algorithm nor a non-negative least squares algorithm has returned
	% a solution, then exit this routine with an error warning
	if exitflag == 0
		ErrorFlag = true	;
		return
	end	
end

% Extract K and S from the first and second halves of the vector KandS, and make sure
% they are row vectors
K = KandS(1:NumberOfPaints)			;
S = KandS((NumberOfPaints+1):end)	;
K = reshape(K,length(K),1)			;
S = reshape(S,length(S),1)			;