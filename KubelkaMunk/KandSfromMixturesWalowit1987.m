function [K,S] = KandSfromMixturesWalowit1987(Wavelengths,...
											  Reflectances,...
											  Concentrations);
% Purpose		Given the reflectance spectra of various mixtures of paints, at different
%				concentrations, use [Walowit1987] to estimate the Kubelka-Munk coefficients,
%				K and S, for the two paints.
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
%				concentrations.  The algorithm actually applies to only one wavelength at a
%				time, so it is applied multiple times, once to each of the entries in Wavelengths.
%
%				Many of the variable names in this routine follow the names used in [Walowit1987].
%
% References	[Walowit1987] Eric Walowit, Cornelius J. McCarthy, & Roy S. Berns, "An Algorithm
%				for the Optimization of Kubelka-Munk Absorption and Scattering Coefficients,"
%				Color Research and Application, Vol. 12, Number 6, December 1987.
%
% Syntax		[K,S] = KandSfromMixturesWalowit1987(Wavelengths,...
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
%								wavelength in Wavelengths.  K and S are both column vectors, whose
%								number of rows is the number of paints
%
% Related Routines	KandSfromMixturesCentore2013
%
% Author		Paul Centore (July 21, 2013)
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

PlotKandS = false	;	% Flag for making plot of K and S as functions of wavelength

NumOfPaints      = size(Concentrations,2)	;	% Number of constituent paints or colorants
NumOfWavelengths = length(Wavelengths)		;
NumOfMixtures    = size(Reflectances,1)		;

% Initialize output variables
K = -99*ones(NumOfPaints,NumOfWavelengths)	;
S = -99*ones(NumOfPaints,NumOfWavelengths)	;

% Estimate a K and an S for each paint, at each wavelength.  Loop over wavelengths.
for ctr = 1:NumOfWavelengths
	% For each wavelength, use the least squares method in [Walowit1987] to estimate
	% K and S for that wavelength, for all the constituent paints.
	
	% Construct the matrix KSCOEFS
    R           = Reflectances(:,ctr)		;
	KoverS_mix  = KoverSfromMasstoneR(R)	;
	KSCOEFS     = -99 * ones((NumOfMixtures+1), 2*NumOfPaints)	;
	for idx = 1:NumOfMixtures
		for id2 = 1:NumOfPaints
			KSCOEFS(idx, id2) = -Concentrations(idx, id2)		;
		end
		for id3 = 1:NumOfPaints
			KSCOEFS(idx, (NumOfPaints + id3)) = KoverS_mix(idx) * Concentrations(idx, id3)		;
		end
	end
	% Add constraint row, to avoid solution of all 0s
	for id2 = 1:(2*NumOfPaints)
		KSCOEFS((NumOfMixtures+1),id2) = 1	;
	end

	% Construct the observation vector.
	OBS = zeros(NumOfMixtures,1)	;
	OBS((NumOfMixtures+1),1) = 1	;

	% Solve a linear least squares system to get estimates for K and S
	[KandS, sigma, r] = ols (OBS, KSCOEFS)	;
	K(:,ctr) = KandS(1:NumOfPaints)			;
	S(:,ctr) = KandS((NumOfPaints+1):end)	;
	
	% Place K and S between 0 and 1, if needed
	for idx = 1:length(K(:,ctr))
		if K(idx,ctr) < 0
			K(idx,ctr) = 0	;
		elseif K(idx,ctr) > 1
			K(idx,ctr) = 1	;
		end
		if S(idx,ctr) < 0
			S(idx,ctr) = 0	;
		elseif S(idx,ctr) > 1
			S(idx,ctr) = 1	;
		end
	end
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
	set(gca, 'xlim', [400 700])
	set(gca, 'ytick', 0:0.2:1, 'yticklabel', ['0.0';'0.2';'0.4';'0.6';'0.8';'1.0'])
	figname = 'EstimatedKvalues1987';
    set(gcf, 'Name', figname);
    print(gcf, ['./',figname,'.eps'], '-deps');
    print(gcf, ['./',figname,'.svg'], '-dsvg');
    print(gcf, ['./',figname,'.pdf'], '-dpdf');

	figure
	for ctr = 1:row
		plot(Wavelengths, S(ctr,:), ColorList{ctr})
		hold on
	end
	set(gca, 'xlim', [400 700])
	set(gca, 'ytick', 0:0.2:1, 'yticklabel', ['0.0';'0.2';'0.4';'0.6';'0.8';'1.0'])
	figname = 'EstimatedSvalues1987';
    set(gcf, 'Name', figname);
    print(gcf, ['./',figname,'.eps'], '-deps');
    print(gcf, ['./',figname,'.svg'], '-dsvg');
    print(gcf, ['./',figname,'.pdf'], '-dpdf');
end