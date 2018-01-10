function [K,S] = KandSfromMixturesCentore2013(Wavelengths,...
											  Reflectances,...
											  Concentrations);
% Purpose		Given the reflectance spectra of various mixtures of paints, at different
%				concentrations, use [Centore2013] to estimate the Kubelka-Munk coefficients,
%				K and S, for the paints.
%
% Description	This routine is intended to find the Kubelka-Munk coefficients for a set of
%				constituent paints or colorants.  The constituent paints have been mixed in
%				various concentrations, and their reflectance spectra have been measured
%				with a spectrophotometer.  The variable Wavelengths records the set of 
%				wavelengths (in nm) at which the mixtures have been measured.  The input 
%				Reflectances records the reflectances measured at those wavelengths.  Reflectances
%				has one row for each mixture of colorants.
%
%				In 1987 [Walowit1987], Walowit, McCarthy, and Berns suggested a least squares
%				algorithm that simultaneously solves for K and S for each constituent colorant,
%				when given the reflectance spectra of mixtures of those colorants, at known
%				concentrations.  This routine uses an updated version ([Centore2013]) of their
%				algorithm.  The update involves assigning statistical weights to the linear
%				relationships in the least squares formulation.  A weight is conveniently expressed 
%				in terms of the standard deviation, or sigma, of the residual of a linear
%				relationship.  The algorithm actually applies to only one wavelength at a
%				time, so it is applied multiple times, once to each of the entries in Wavelengths.
%
%				Many of the variable names in this routine follow the names used in [Walowit1987].
%
%				This routine has been largely superseded by KandSfromMixtures.m, into which 
%				it is incorporated.  The routine KandSfromMixtures.m uses the same weights as
%				this routine, but uses a GJK-based algorithm to solve the least squares problem,
%				rather than standard least squares methods.  It is likely that the current
%				routine will be eliminated from future versions of the Munsell and Kubelka-Munk
%				Toolbox, for simplicity.
%
% References	[Centore2013] Paul Centore, "Perceptual Reflectance Weighting for
%				Kubelka-Munk Estimation," available at wwww.99main.com/~centore, 2013
%           	[Walowit1987] Eric Walowit, Cornelius J. McCarthy, & Roy S. Berns, "An Algorithm
%				for the Optimization of Kubelka-Munk Absorption and Scattering Coefficients,"
%				Color Research and Application, Vol. 12, Number 6, December 1987.
%
% Syntax		[K,S] = KandSfromMixturesCentore2013(Wavelengths,...
%													 Reflectances,...
%													 Concentrations);
%
%				Wavelengths		A row vector whose entries are the wavelengths for the reflectance  
%								spectra.  
%
%				Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%								between 0 and 1) for various reflectance spectra at the wavelengths
%								listed in the first input.  Each reflectance spectrum is the spectrum
%								for a mixture of the n constituent paints, at some concentrations
%
%				Concentrations	An n-column vector with the same number of rows as the input Reflectances.  
%								The first column gives the concentrations of the first paint (in the
%								corresponding row of Reflectances) in the mixtures, and the second
%								column gives the concentrations of the second paint, etc.  The concentrations
%								are numbers between 0 and 1
%
%				K,S				Kubelka-Munk absorption and scattering coefficients for the paints in
%								the mixtures.  There is a different coefficient for each
%								wavelength in Wavelengths.  K and S are both matrices, whose
%								number of rows is the number of paints, and whose number of columns is
%								the number of wavelengths
%
% Related Routines	KandSfromMixturesWalowit1987
%
% Author		Paul Centore (August 7, 2013)
% Revised		Paul Centore (October 13, 2013)
%				--Gave the constraint (K1 + S1 + K2 + S2 + ... + Kn + Sn =1) lower weight than any other
%				  linear relationship
%				--When making sure K and S are all less than or equal to 1, the ratios between the Ks and Ss were
%				  kept constant when any adjustments were made
% Revised		Paul Centore (December 31, 2014)
%				--Slight revisions to documentation
% Revised		Paul Centore (January 4, 2015)
%				--Checked directly that no sigmas were 0
%				--Replaced ols (ordinary least squares) with lsqnonneg (non-negative least squares)
%
% Copyright 2013-2015 Paul Centore
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
K = -99*ones(NumOfPaints,NumOfWavelengths)	;
S = -99*ones(NumOfPaints,NumOfWavelengths)	;

% Find approximate scattering coefficients S to use in statistical weights.  These
% coefficients are taken from the algorithm in [Walowit1987].
[ApproxConstK,ApproxConstS] = KandSfromMixturesWalowit1987(Wavelengths,...
														   Reflectances,...
											               Concentrations)	;
													 
% Estimate a K and an S for each paint, at each wavelength.  Loop over wavelengths.
Sigmas = []			;	% Matrix of standard deviations for different mixtures and wavelengths
FirstTerms  = []	;	% Record terms in sigma calculation, for possible analysis
SecondTerms = []	;
ThirdTerms  = []	;
for ctr = 1:NumOfWavelengths
	% For each wavelength, use the least squares method in [Centore2013] to estimate
	% K and S for that wavelength, for all the constituent paints.
	
	% Calculate the sigma for each mixture, from Eq. (39) of [Centore2013].
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

	% Construct the matrix KSCOEFS
	KoverS_mix  = KoverSfromMasstoneR(Reflectances(:,ctr))		;
	KSCOEFS     = -99 * ones((NumOfMixtures+1), 2*NumOfPaints)	;
	for idx = 1:NumOfMixtures
		for id2 = 1:NumOfPaints
			KSCOEFS(idx, id2) = -Concentrations(idx, id2)		;
		end
		for id3 = 1:NumOfPaints
			KSCOEFS(idx, (NumOfPaints + id3)) = KoverS_mix(idx) * Concentrations(idx, id3)		;
		end

        % To weight the residuals properly, divide each row in KSCOEFS (except the last)
		% by its standard deviation, sigma.  This adjustment is where [Centore2013] differs from
		% [Walowit1987].	
		KSCOEFS(idx,:) = (1/Sigmas(idx,ctr)) * KSCOEFS(idx,:)	;
	end
	% Add constraint row, to avoid solution of all 0s.  The constraint is treated as a linear
	% relationship, which is given very low weight, or equivalently a very high sigma (changed
	% Oct. 13, 2013)
	MaxSigma = max(Sigmas(:,ctr))	;
	for id2 = 1:(2*NumOfPaints)
		KSCOEFS((NumOfMixtures+1),id2) = 1/(10*MaxSigma)	;
	end

	% Construct the observation vector.
	OBS = zeros(NumOfMixtures,1)				;
	% (Changed Oct. 13, 2013) The observation entry corresponding to the constraint has been
	% given much smaller weight than any of the other linear relationships
	OBS((NumOfMixtures+1),1) = 1/(10*MaxSigma)	;

	% Solve a linear least squares system to get estimates for K and S
%	[KandS, sigma, r] = ols (OBS, KSCOEFS)	;	% Previous method, replaced Jan. 4, 2015
	KandS = lsqnonneg(KSCOEFS, OBS)			;	% New method, installed Jan. 4, 2015
	K(:,ctr) = KandS(1:NumOfPaints)			;
	S(:,ctr) = KandS((NumOfPaints+1):end)	;
	
	% Place K and S between 0 and 1, if needed
	for idx = 1:length(K(:,ctr))
		if K(idx,ctr) < 0
			K(idx,ctr) = 0	;
%		elseif K(idx,ctr) > 1
%			K(idx,ctr) = 1	;
		end
		if S(idx,ctr) < 0
			S(idx,ctr) = 0	;
%		elseif S(idx,ctr) > 1
%			S(idx,ctr) = 1	;
		end
	end
	
	% (Changed Oct. 13, 2013) Maintain the ratios of Ks and Ss, so that the set as a whole
	% is placed between 0 and 1.
	MaxKorS = max([K(:,ctr);S(:,ctr)])	;
	K(:,ctr) = K(:,ctr)/MaxKorS			;
	S(:,ctr) = S(:,ctr)/MaxKorS			;
end

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
    print(gcf, ['./',figname,'.eps'], '-deps');
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
    print(gcf, ['./',figname,'.eps'], '-deps');
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
    print(gcf, ['./',figname,'.eps'], '-deps');
    print(gcf, ['./',figname,'.svg'], '-dsvg');
    print(gcf, ['./',figname,'.pdf'], '-dpdf');
end