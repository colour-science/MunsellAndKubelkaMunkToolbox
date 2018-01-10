function [K, S, ErrorFlag] = KandSfromMixtures(	  Wavelengths,...
												  Reflectances,...
												  Concentrations   );
% Purpose		Given the reflectance spectra of various mixtures of paints, at different
%				concentrations, estimate the Kubelka-Munk coefficients, K and S, for the paints.  
%
% Description	This routine is intended to find the Kubelka-Munk coefficients for a set of
%				constituent paints or colorants.  The constituent paints have been mixed in
%				various concentrations, and the reflectance spectra of the mixtures have been measured
%				with a spectrophotometer.  The variable Wavelengths records the set of 
%				wavelengths (in nm) at which the mixtures have been measured.  The input 
%				Reflectances records the reflectances measured at those wavelengths.  Reflectances
%				has one row for each mixture of colorants.
%
%				In 1987 [Walowit1987], Walowit, McCarthy, and Berns suggested a least squares
%				algorithm that simultaneously solves for K and S for each constituent colorant,
%				when given the reflectance spectra of mixtures of those colorants, at known
%				concentrations.  The algorithm actually applies to only one wavelength at a
%				time, so it is applied multiple times, once to each of the entries in Wavelengths.
%				This routine is based on their work (and many of the variable
%				names in this routine follow the names used in [Walowit1987]), but two updates 
%				have been made.  
%
%				First, this routine uses an updated version ([Centore2014]) of their
%				algorithm, that assigns statistical weights to the linear
%				relationships in the least squares formulation.  A weight is conveniently expressed 
%				in terms of the standard deviation, or sigma, of the residual of a linear
%				relationship.  
%
%				Second, a novel geometric algorithm ([Centore 2015]) is used to solve the least
%				squares problem.  The new algorithm is based on the GJK algorithm ([Gilbert1988],
%				[Rabbitz1994]), and incorporates the constraints on K and S: for each paint at each
%				wavelength, K and S are non-negative.
%
%				This routine is an adaptation of the routine KandSfromMixturesCentore2013.m, which
%				incorporates new weights, but not the GJK algorithm.  Another routine,
%				KandSfromMixturesWalowit1987.m, uses just the algorithm in [Walowit1987].  This
%				routine calls the GJK algorithm for an initial estimate of K and S, from
%				which weights are calculated.
%				If the GJK algorithm fails, then KandSfromMixturesWalowit1987.m is called as a
%				backup.
%
% References	[Walowit1987] 	Eric Walowit, Cornelius J. McCarthy, & Roy S. Berns, An Algorithm
%								for the Optimization of Kubelka-Munk Absorption and Scattering Coefficients,
%								Color Research and Application, Vol. 12, Number 6, December 1987.
%				[Centore2014] 	Paul Centore, Perceptual Reflectance Weighting for Estimating
%								Kubelka-Munk Coefficients, available at wwww.99main.com/~centore, 2014.
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
% Variables		Wavelengths		A row vector whose entries are the wavelengths for the reflectance  
%								spectra.  
%
%				Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%								between 0 and 1) for various reflectance spectra at the wavelengths
%								listed in the first input.  Each reflectance spectrum is the spectrum
%								for a mixture of the n constituent paints, at some concentrations
%
%				Concentrations	An n-column vector with the same number of rows as the input Reflectances.  
%								The first row gives the concentrations of the first paint (in the
%								corresponding row of Reflectances) in the mixtures, and the second
%								row gives the concentrations of the second paint, etc.  The concentrations
%								are numbers between 0 and 1
%
%				K,S				Kubelka-Munk absorption and scattering coefficients for the paints in
%								the mixtures.  There is a different coefficient for each
%								wavelength in Wavelengths.  K and S are both matrices, whose
%								number of rows is the number of paints, and whose number of columns is
%								the number of wavelengths
%
% Author		Paul Centore (January 26, 2015)
% Revision		Paul Centore (February 20, 2015)
%				---The initial approximation for S is now obtained via the GJK algorithm, rather than
%				   by the approach in [Walowit1987] (although [Walowit1987] is used as a backup)
%				---Multiple passes are made for estimating S.  The first, unweighted, S is calculated
%				   via the GJK approach, and is then used to determine weights.  K and S are then
%				   recalculated with those weights.  One or more new passes have now been added, in
%				   which the recalculated S is used to redetermine weights; K and S are then
%				   estimated again using those weights.  Further passes can be added if desired, but
%				   in practice two passes seems adequate.
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

PlotKandS = false	;	% Flag for making plot of K and S as functions of wavelength
PlotWeights = false	;	% Flag for making plots of weights and related quantities as a function of wavelength

NumOfPaints      = size(Concentrations,2)	;	% Number of constituent paints or colorants
NumOfWavelengths = length(Wavelengths)		;
NumOfMixtures    = size(Reflectances,1)		;

% Initialize output variables
K 		  = -99*ones(NumOfPaints,NumOfWavelengths)	;
S         = -99*ones(NumOfPaints,NumOfWavelengths)	;
ErrorFlag = false									;
            
% Find approximate scattering coefficients S to use in statistical weights.  These
% coefficients are calculated by the methods of [Centore2015], but without any weights											               
for ctr = 1:NumOfWavelengths
	% For each wavelength, use the matrix KSCOEFS from [Walowit1987], but without the bottom
	% row.  The bottom row is all 1s, to insure that the solution is not all 0s.  [Walowit1987]
	% recommends using ordinary least squares, but we will use the GJK approach, as described in
	% [Centore2015].  Either way, the result will be an estimate of all
	% K and S for that wavelength, for all the constituent paints.
	
	% Construct the matrix UnAugmentedKSCOEFS (this is the matrix KSCOEFS without the bottom row)
    R                  = Reflectances(:,ctr)						;
	KoverS_mix         = KoverSfromMasstoneR(R)						;
	UnAugmentedKSCOEFS = -99 * ones(NumOfMixtures, 2*NumOfPaints)	;
	for idx = 1:NumOfMixtures
		for id2 = 1:NumOfPaints
			UnAugmentedKSCOEFS(idx, id2) = -Concentrations(idx, id2)	;
		end
		for id3 = 1:NumOfPaints
			UnAugmentedKSCOEFS(idx, (NumOfPaints + id3)) = KoverS_mix(idx) * Concentrations(idx, id3)	;
		end
	end
	
	% Once this matrix has been constructed, use the GJK approach to estimate K and S
	[KgjkFor1Wavelength, ...
	 SgjkFor1Wavelength, ...
	 ErrorFlag] = ...
		 KandSusingGJK(UnAugmentedKSCOEFS)	;

   if ErrorFlag	% Just in case the GJK algorithm does not succeed, use the approach from [Walowit1987]
		disp(['ERROR in KandSfromMixtures.m, using GJK algorithm; reverting to [Walowit1987] algorithm.'])
		fflush(stdout);
		[ApproxConstK,ApproxConstS] = KandSfromMixturesWalowit1987(Wavelengths,...
														   Reflectances,...
											               Concentrations)	;
   else
   		% The GJK approach has succeeded, so use its returned values as initial estimates
   		% for K and S.  These initial estimates will only be used for calculating weights,
   		% after which K and S will be re-estimated, using those weights
		ApproxConstK(:,ctr) = reshape(KgjkFor1Wavelength, length(KgjkFor1Wavelength), 1)	;
		ApproxConstS(:,ctr) = reshape(SgjkFor1Wavelength, length(SgjkFor1Wavelength), 1)	;
   end											 
end
											               
% The approximate S values are used to determine weights, in accordance with [Centore2014].	
% The weights are then used to re-estimate S.  The re-estimated S values are then used to
% redetermine weights, which are used to re-re-estimate S, and so on for a set number of
% passes.  In practice, two passes seems to be enough.
NumberOfPasses = 2	;										               
for PassCtr = 1:NumberOfPasses
	% On the first pass, use the S values that resulted when no weights were applied.  On
	% subsequent passes, use the most recently estimated S values
	if PassCtr > 1
		ApproxConstS = S	;
	end
													 
	% Estimate a K and an S for each paint, at each wavelength.  Loop over wavelengths.
	Sigmas = []			;	% Matrix of standard deviations for different mixtures and wavelengths
	FirstTerms  = []	;	% Record terms in sigma calculation, for possible analysis
	SecondTerms = []	;
	ThirdTerms  = []	;
	for ctr = 1:NumOfWavelengths
		% For each wavelength, use the least squares method in [Centore2014] to estimate
		% K and S for that wavelength, for all the constituent paints.
	
		% Calculate the sigma for each mixture, from Eq. (39) of [Centore2014].
		for idx = 1:NumOfMixtures
			% Calculate S for mixture, as linear combination of S from constituents
			EstimatedS = 0	;
			for ind = 1:NumOfPaints
				EstimatedS = EstimatedS + Concentrations(idx,ind) * ApproxConstS(ind,ctr)		;
			end
			% Divide by sum of concentrations, just in case the concentrations do not sum to 1
			FirstTerms(idx,ctr) = EstimatedS/sum(Concentrations(idx,:))		;
		
			R = Reflectances(idx,ctr)						;
			SecondTerms(idx,ctr) = abs(((R^2)-1)/(2*(R^2)))	;
			ThirdTerms(idx,ctr)  = R^(2/3)					;

			Sigmas(idx,ctr) = abs(FirstTerms(idx,ctr) * SecondTerms(idx,ctr) * ThirdTerms(idx,ctr))	;
		end
	
		% The following check was added because a case occurred where one of the sigmas was 0.  (That
		% case occurred because EstimatedS was 0, and ultimately because ApproxConstS, as evaluated
		% by Walowit s 1987 algorithm was 0 whenever concentration was non-zero.  A closer look might
		% reveal a more elegant way to handle this problem.)
		maxSigmas  = max(max(Sigmas))	;
		[row, col] = size(Sigmas)		;
		for rowctr = 1:row
			for colctr = 1:col
				if Sigmas(rowctr,colctr) == 0
					Sigmas(rowctr,colctr) = 1e6 * maxSigmas	;
				end
			end
		end

		% Construct the matrix M
		KoverS_mix  = KoverSfromMasstoneR(Reflectances(:,ctr))		;
		M           = -99 * ones(NumOfMixtures, 2*NumOfPaints)		;
		for idx = 1:NumOfMixtures
			for id2 = 1:NumOfPaints
				M(idx, id2) = -Concentrations(idx, id2)		;
			end
			for id3 = 1:NumOfPaints
				M(idx, (NumOfPaints + id3)) = KoverS_mix(idx) * Concentrations(idx, id3)		;
			end

			% To weight the residuals properly, divide each row in M 
			% by its standard deviation, sigma.  This adjustment is where [Centore2014] differs from
			% [Walowit1987].	
			M(idx,:) = (1/Sigmas(idx,ctr)) * M(idx,:)	;
		end

		% Solve the constrained linear least squares system M*x = 0 to get estimates for K and S
		[KgjkFor1Wavelength, ...
		 SgjkFor1Wavelength, ...
		 ErrorFlag] = ...
			 KandSusingGJK(M)	;
		% Check whether the GJK routine has returned successfully.  If not, then exit this
		% routine with a warning message.  If so, then exit after assigning K and S		 
		if ErrorFlag	
			return
		else
			K(:,ctr) = KgjkFor1Wavelength		;
			S(:,ctr) = SgjkFor1Wavelength		;
		end		% End after assigning K and S for one wavelength
	end			% End after looping over all wavelengths
end				% End after final pass

% If desired, make a plot showing K and S for each constituent colorant, at each wavelength.
if PlotKandS
	ColorList = {'k-','b-','r-','g-','y-'}	;
	[row,col] = size(K)					;
	
	figure
	for ctr = 1:row
		plot(Wavelengths, K(ctr,:), ColorList{ctr})
		hold on
	end
	set(gca, 'ytick', 0:0.2:1, 'yticklabel', ['0.0';'0.2';'0.4';'0.6';'0.8';'1.0'])
	figname = 'EstimatedKvalues2013';
    set(gcf, 'Name', figname);
    print(gcf, ['./',figname,'.eps'], '-deps');
    print(gcf, ['./',figname,'.svg'], '-dsvg');
    print(gcf, ['./',figname,'.pdf'], '-dpdf');

	figure
	for ctr = 1:row
		plot(Wavelengths, S(ctr,:), ColorList{ctr})
		hold on
	end
	set(gca, 'ytick', 0:0.2:1, 'yticklabel', ['0.0';'0.2';'0.4';'0.6';'0.8';'1.0'])
	figname = 'EstimatedSvalues2013';
    set(gcf, 'Name', figname);
    print(gcf, ['./',figname,'.eps'], '-deps');
    print(gcf, ['./',figname,'.svg'], '-dsvg');
    print(gcf, ['./',figname,'.pdf'], '-dpdf');
end

% If desired, make a plot of the weights and related data for each mixture, at each wavelength
if PlotWeights
	ColorList = {'k-','b-','r-','g-','y-','k*','b*','r*','g*','y*'}	;
	[row,col] = size(Sigmas)					;
	
	figure
	for ctr = 1:row
%		plot(Wavelengths, Sigmas(ctr,:), ColorList{ctr})
		plot(Wavelengths, Sigmas(ctr,:), 'k-')
		hold on
	end
	set(gca, 'xlim', [400 700])
	set(gca,'yscale', 'log')
	figname = 'Sigmas';
    set(gcf, 'Name', figname);
    print(gcf, ['./',figname,'.eps'], '-depsc');
    print(gcf, ['./',figname,'.svg'], '-dsvg');
    print(gcf, ['./',figname,'.pdf'], '-dpdf');
	
	figure
	for ctr = 1:row
		plot(Wavelengths, FirstTerms(ctr,:), 'k-')
		hold on
		plot(Wavelengths, SecondTerms(ctr,:), 'k.')
		hold on
		plot(Wavelengths, ThirdTerms(ctr,:), 'k*')
		hold on
	end
	set(gca, 'xlim', [400 700])
	set(gca,'yscale', 'log')
	figname = 'IndividualTerms';
    set(gcf, 'Name', figname);
    print(gcf, ['./',figname,'.eps'], '-depsc');
    print(gcf, ['./',figname,'.svg'], '-dsvg');
    print(gcf, ['./',figname,'.pdf'], '-dpdf');
	
	% Plot condition numbers of sigmas, and terms making up sigmas
	FirstTermsCondNum  = max(FirstTerms)./min(FirstTerms)	;
	SecondTermsCondNum = max(SecondTerms)./min(SecondTerms)	;
	ThirdTermsCondNum  = max(ThirdTerms)./min(ThirdTerms)	;
	SigmaCondNum       = max(Sigmas)./min(Sigmas)			;
	figure
	for ctr = 1:row
		plot(Wavelengths, FirstTermsCondNum, 'k-')
		hold on
		plot(Wavelengths, SecondTermsCondNum, 'k-')
		hold on
		plot(Wavelengths, ThirdTermsCondNum, 'k-')
		hold on
		plot(Wavelengths, SigmaCondNum, '-', 'Linewidth',4, 'color',0.7*[1 1 1])
		hold on
	end
	set(gca, 'xlim', [400 700])
	set(gca,'yscale', 'log')
	figname = 'ConditionNumbers';
    set(gcf, 'Name', figname);
    print(gcf, ['./',figname,'.eps'], '-depsc');
    print(gcf, ['./',figname,'.svg'], '-dsvg');
    print(gcf, ['./',figname,'.pdf'], '-dpdf');
end