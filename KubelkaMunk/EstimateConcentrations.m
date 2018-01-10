function EstimatedConcentrations = EstimateConcentrations(Wavelengths,...
														  Reflectances,...
														  K,...
														  S,...
														  KnownConcentrations);
% Purpose		Given the reflectance spectra of various mixtures of colorants, and given the
%				Kubelka-Munk coefficients of the constituent colorants, estimate the concentrations
%				of the constituents in the mixtures.
%
% Description	This routine is intended to estimate the concentrations of various constituents
%				that make up a mixture of those constituents.  It is assumed that one has 
%				measured the reflectance spectrum of the mixture (at some set of wavelengths),
%				and that the Kubelka-Munk coefficients (K and S) are known for each
%				constituent (at the same set of wavelengths).  
%
%				The algorithm uses a least squares approach, as introduced in [Walowit1988], with
%				some modifications (such as different weights) as described in [Centore2014].  The
%				least squares approach begins with the Kubelka-Munk relationship
%				K/S = (1-R)^2/2R, which holds at each wavelength for a particular mixture.  The
%				terms K and S in this equation apply to the mixture, and are linear functions of
%				the K and S for the individual constituents, and of the concentrations.  Algebraic
%				manipulation leads to an overdetermined linear system Mc = 0, where M is a 
%				matrix, c is a column vector of concentrations, and 0 is the zero column vector.
%				Each wavelength leads to one row of M and one entry of b.  The least squares
%				method finds the concentrations that come closest to satisfying the system, and
%				these are returned as the estimated concentrations.
%
%				Rather than standard least squares algorithms, this routine uses a novel geometric
%				approach based on the GJK algorithm ([Gilbert1988], [Rabbitz1994]), explained in
%				[Centore2015].  This new approach was adopted to make sure that the concentrations
%				satisfy physical constraints (each concentration is between 0 and 1, and the sum
%				of all the concentrations is 1).  
%
% 				Some concentrations will already be known with certainty.  For example, a "mixture"
% 				might consist of just one constituent colorant, or it might be known that none of a
% 				constituent was used in a particular mixture.  The input matrix KnownConcentrations
%				will record these cases, so that the routine does not try to solve for them.  It
%				was found that performance degraded significantly if the known concentrations were
%				solved for, rather than taken as known.
%
% References	[Walowit1988] 	Eric Walowit, Cornelius J. McCarthy, & Roy S. Berns, Spectrophotometric
%								Color Matching Based on Two-Constant Kubelka-Munk Theory, Color Research 
%								and Application, Vol. 13, No. 6, December 1988.
%				[Centore2014] 	Paul Centore, Perceptual Reflectance Weighting for Estimating
%								Kubelka-Munk Coefficients, available at wwww.99main.com/~centore, 2015.
%				[Centore2015] 	Paul Centore, Enforcing Constraints in Kubelka-Munk Calculations, 
%								available at wwww.99main.com/~centore, 2015.
%				[Gilbert1988] 	Elmer G. Gilbert, Daniel W. Johnson, & Sathiya Keerthi, A Fast
%								Procedure for Computing the Distance Between Complex Objects in
%								Three-Dimensional Space, IEEE Journal of Robotics and Automation,
%								Vol. 4, No. 2, April 1988, pp. 193-203.
%				[Rabbitz1994]	Rich Rabbitz, Fast Collision Detection of Moving Convex Polyhedra,
%								in Section I.8 of Graphics Gems IV (IBM Version), ed. Paul Heckbert,
%								Academic Press, 1994.
%
%				Wavelengths		A row vector whose entries are the wavelengths for the reflectance  
%								spectra.  
%
%				Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%								between 0 and 1) for various reflectance spectra at the wavelengths
%								listed in the first input.  Each reflectance spectrum is the spectrum
%								for a mixture of the n constituent paints, at some concentrations
%
%				K,S				Kubelka-Munk absorption and scattering coefficients for the paints in
%								the mixtures.  There is a different coefficient for each
%								wavelength in Wavelengths.  K and S are both matrices, whose
%								number of rows is the number of paints, and whose number of columns is
%								the number of wavelengths
%
%				KnownConcentrations 	A matrix with a row for each mixture, and a column for each
%								constituent colorant.  A matrix entry will be 0 if the corresponding
%								mixture is known to contain none of the corresponding colorant, and 1
%								if the "mixture" consists completely of that colorant.  Otherwise, the
%								entries will be NaN.  This input is optional
%
%				EstimatedConcentrations		An n-column vector with the same number of rows as the input   
%								Reflectances.  The first row gives the concentrations of the first paint 
%								(in the corresponding row of Reflectances) in the mixtures, and the second
%								row gives the concentrations of the second paint, etc.  The concentrations
%								are numbers between 0 and 1
%
% Author		Paul Centore (January 5, 2015)
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

% Initialize return variables
EstimatedConcentrations    = []	;

% Find the sizes of different inputs
NumberOfWavelengths       = length(Wavelengths) 	;	
NumberOfConstituentPaints = size(K,1)				;
NumberOfMixtures          = size(Reflectances,1)	;	

% If no known concentrations have been input, then all concentrations are unknown and must
% be solved for
KCvariableInput = true		;
if not(exist('KnownConcentrations')) 
	KCvariableInput = false	;
else
	if isempty(KnownConcentrations)
		KCvariableInput = false	;
	end
end
if not(KCvariableInput)
	KnownConcentrations = NaN * ones(NumberOfMixtures, NumberOfConstituentPaints)	;
end

% Initialize return variables
EstimatedConcentrations    = KnownConcentrations	;

% Read in the 1931 CIE Standard Observer colour-matching functions, to be used for weighting
% the rows of M and b
FileName = which('1931ColourMatchingFunctions.mat')	;
load(FileName)
% Evaluate the photopic luminous efficiency function (denoted y-bar(lambda) by the CIE) at
% the input wavelengths.  The variables wavelengths and ybar are provided by the file that
% was just loaded.
ybarForWavelengths = interp1(wavelengths, ybar, Wavelengths)	;

% Calculate K/S (the ratio of Kubelka-Munk absorbing and scattering coefficients) from each 
% input reflectance 
fofR = KoverSfromMasstoneR(Reflectances)		;		

% Loop through the mixtures, estimating the concentrations for each one
for MixtureCtr = 1:NumberOfMixtures

	% Check whether any of the constituent concentrations are already known for this
	% mixture.  
	PaintsToBeSolvedFor = []	;
	for ColorantCtr = 1:NumberOfConstituentPaints
		if isnan(KnownConcentrations(MixtureCtr,ColorantCtr))
			PaintsToBeSolvedFor = [PaintsToBeSolvedFor, ColorantCtr]	;
		end
	end
	NumberOfPaintsToBeSolvedFor = length(PaintsToBeSolvedFor)	;

	% If the concentration of every paint in this mixture is known, then no calculations are
	% necessary.  Otherwise, there should be at least two paints in the mixture whose
	% concentrations must be estimated
	if NumberOfPaintsToBeSolvedFor >= 2
		M = NaN * ones(NumberOfWavelengths, NumberOfPaintsToBeSolvedFor)	;
		for WavelengthCtr = 1:NumberOfWavelengths
			for ConstituentPaintCtr = 1:(NumberOfPaintsToBeSolvedFor)
				M(WavelengthCtr,ConstituentPaintCtr) = ...
					ybarForWavelengths(WavelengthCtr) * ...
					(fofR(MixtureCtr,WavelengthCtr) .* S(PaintsToBeSolvedFor(ConstituentPaintCtr),WavelengthCtr) - ...
					 K(PaintsToBeSolvedFor(ConstituentPaintCtr),WavelengthCtr) );
			end
		end
		b = zeros(NumberOfWavelengths,1)	;

		% Reformulate the least squares problem as a geometric problem in which one finds
		% the shortest distance between a point (the zero vector) and a convex polytope
		% (the convex hull of the columns of M), and then apply the GJK algorithm.
		PolytopeGenerators = transpose(M)	;
		Point = reshape(b,1,length(b))		;
		[ClosestPoint,   ...
          Distance,       ...
          PointInPolytope,...
          Coefficients] = ...
          ClosestPointInConvexPolytopeGJK(...
								PolytopeGenerators,...
								Point)	;
		for ctr = 1:NumberOfPaintsToBeSolvedFor
			EstimatedConcentrations(MixtureCtr,PaintsToBeSolvedFor(ctr)) = Coefficients(ctr);
		end
	end
end