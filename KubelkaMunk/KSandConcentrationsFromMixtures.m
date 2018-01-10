function [K, ...
		  S, ...
		  EstimatedConcentrations] = ...
		  KSandConcentrationsFromMixtures( ...
										  Wavelengths,...
										  Reflectances,...
										  IntendedConcentrations,...
										  Saundersonk2);
% Purpose		Given the reflectance spectra of various mixtures of colorants, estimate the
%				Kubelka-Munk coefficients of the constituent colorants, and the concentrations
%				of the constituents in the mixtures.  This routine is intended for the situation
%				where there is some error in measuring out the quantities of colorants that go into
%				the mixtures.
%
% Description	This routine is intended to find the Kubelka-Munk coefficients and concentrations for 
%				a set of constituent paints or colorants.  The constituent paints have been mixed in
%				various concentrations (which are only known approximately), 
%				and their reflectance spectra have been measured
%				with a spectrophotometer.  The variable Wavelengths records the set of 
%				wavelengths (in nm) at which the mixtures have been measured.  The input 
%				Reflectances records the reflectances measured at those wavelengths.  
%
%				In many Kubelka-Munk algorithms, the concentrations of the constituent colorants
%				is assumed to be known exactly.  This routine was written to handle the situation
%				in which concentrations are only known approximately.  It was motivated by an
%				example in practice, in which paints were measured out manually with syringes. 
%				The reflectances predicted by the estimated Kubelka-Munk coefficients were often
%				consistently above or below the measured reflectances, suggesting that a
%				systematic error was present.  The manual measurement technique seemed to be a
%				likely source of error.  To avoid the problem, not only coefficients but also
%				concentrations were estimated from the reflectance data, which improves the overall fit.
%
%				The algorithm in this routine is iterative.  Each iteration, except the first, 
%				has two steps.  The first iteration makes an initial estimate of Kubelka-Munk 
%				coefficients.  This initial estimate uses the input
%				intended concentrations, and estimates the K and S values.  While the intended
%				concentrations are probably not exact, they are likely close enough to provide
%				useful estimates of K and S.
%   
%				After the initial estimate, each two-step iteration uses estimates from the 
%				previous iteration.  In the first step of each iteration, the most recently
%				estimated K and S are used, and the actual concentrations are estimated---they
%				are probably slightly different from the intended concentrations.  The second
%				step of the iteration then re-estimates K and S, using the revised
%				concentration estimates.  The first step of the next iteration makes a
%				further estimate of concentrations, using the re-estimated K and S.  The
%				algorithm proceeds in this pattern until the revised concentration estimates
%				agree with the immediately previous concentration estimates to within some
%				threshold, such as 0.5 percent.  At that point, the algorithm is taken to
%				have converged, and stops.  The algorithm will also stop automatically if
%				a certain number of iterations occurs without convergence.
%
%				This algorithm can be seen as an optimization method in which minimization is
%				performed independently on alternate variables.  Suppose, for example, that one
%				wished to minimize a function f(x,y), which is assumed to have a unique global
%				minimum at (x_min, y_min).  One could start with a point (x_0,y_0) that was
%				not too far from the minimum.  Then one could fix x_0 and minimize f|x_0, the
%				restriction of f to x=x_0.  The result would be a y-value y_1, and one would
%				move to the point (x_0,y_1).  Then fix y_1, and similarly find x_1 that minimizes
%				f|y_1.  Move to the point (x_1,y_1).  Continue like this, alternately minimizing
%				over x and y, until an (x_n,y_n) is found, such that f(x_n,y_n) is negligibly
%				different from f(x_(n-1),y_(n-1)).  In this routine, the Kubelka-Munk coefficients
%				are the x-variable, and the concentrations are the y-variable.  The function f
%				is a weighted sum of squared residuals that depends on both the coefficients and
%				the concentrations.
%
% References	[Centore2013] Paul Centore, "Perceptual Reflectance Weighting for
%				Kubelka-Munk Estimation," available at wwww.99main.com/~centore, 2013
%           	[Walowit1987] Eric Walowit, Cornelius J. McCarthy, & Roy S. Berns, "An Algorithm
%				for the Optimization of Kubelka-Munk Absorption and Scattering Coefficients,"
%				Color Research and Application, Vol. 12, Number 6, December 1987.
%				[Centore2015] 	Paul Centore, Enforcing Constraints in Kubelka-Munk Calculations, 
%								available at wwww.99main.com/~centore, 2015.
%
%				Wavelengths		A row vector whose entries are the wavelengths for the reflectance  
%								spectra.  
%
%				Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%								between 0 and 1) for various reflectance spectra at the wavelengths
%								listed in the first input.  Each reflectance spectrum is the spectrum
%								for a mixture of the n constituent paints, at some concentrations
%
%				IntendedConcentrations	An n-column vector with the same number of rows as the input Reflectances.  
%								The first column gives the intended concentrations of the first paint (in the
%								corresponding row of Reflectances) in the mixtures, and the second
%								column gives the concentrations of the second paint, etc.  The concentrations
%								are numbers between 0 and 1.  The concentrations are called "intended" because
%								there is likely some error in measuring out the colorants. 
%
%				Saundersonk2	A row vector with n columns (one for each colorant).  An entry gives
%								the fraction of light, as a number between 0 and 1, that is totally 
%								internally reflected (TIR) for a particular constituent colorant; this
%								fraction is denoted k_2 in the Saunderson correction.  TIR fractions
%								are assumed to combine linearly: the fraction for a mixture of 1/3
%								colorant 1 and 2/3 colorant 2 will be 1/3 (k2 for colorant 1) + 2/3 (k2
%								for colorant 2).  This input is optional; if Saundersonk2 is identically
%								0, then no Saunderson correction is used
%
%				K,S				Kubelka-Munk absorption and scattering coefficients for the paints in
%								the mixtures.  There is a different coefficient for each
%								wavelength in Wavelengths.  K and S are both matrices, whose
%								number of rows is the number of paints, and whose number of columns is
%								the number of wavelengths
%
%				EstimatedConcentrations 	Because of process error when measuring out the colorants 
%								that go into the mixture, the actual concentrations are probably not
%								quite the intended concentrations.  The routine estimates the actual
%								concentrations, and returns them in this variable, which has the
%								same format as the input IntendedConcentrations
%
% Author		Paul Centore (December 30, 2014))
%
% Copyright 2014 Paul Centore
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
K                       = []	;
S                       = []	;
EstimatedConcentrations = []	;

Threshold = 0.005	;	% Two concentrations are considered equivalent if they differ by less
					;	% than this amount.
MaxIterations = 10	;	% Stop the algorithm after this many iterations, whether or not it
						% has converged.
DrawPlot = true 	;	% Flag for drawing a plot that compares measured reflectance spectra with
						% spectra predicted from the output values		
DisplayInformation = true	;	% Flag for displaying information on command line							
						
% Some concentrations will already be known with certainty.  For example, a "mixture"
% might consist of just one constituent colorant, or it might be known that none of a
% constituent was used in a particular mixture.  This information should be passed onto
% routines that estimate concentrations.  A concentration will be considered to be known
% with certainty whenever a 1 or a 0 appears in the IntendedConcentrations matrix.
% The matrix KnownConcentrations will have the same size and shape as IntendedConcentrations.
% It will have 1's and 0's exactly where IntendedConcentrations has 1's and 0's, and NaN
% elsewhere.
KnownConcentrations = IntendedConcentrations	;
[NumberOfMixtures, NumberOfConstituents] = size(IntendedConcentrations)		;
for mix = 1:NumberOfMixtures
	for consti = 1:NumberOfConstituents
		if IntendedConcentrations(mix,consti) > 0 && IntendedConcentrations(mix,consti) < 1
			KnownConcentrations(mix,consti) = NaN	;
		end
	end
end

%Saundersonk2 = 0.0 * [1 1 1 1]	;
if not(exist('Saundersonk2'))
	Saundersonk2 = zeros(1,NumberOfConstituents)	;
else
	if isempty(Saundersonk2)
		Saundersonk2 = zeros(1,NumberOfConstituents);
	end
end

% Make the simplifying assumption that the total internal reflectance (TIR) percentange for
% a mixture of colorants is a linear combination of the individual colorants' TIR percentages,
% in proportion to their concentrations.  This assumption is open to question, and can be
% replaced when a better one is found.
% If no Saunderson correction has been input, then all TIR percentages will be 0
k2ForAllMixtures = []	;
for mix = 1:NumberOfMixtures
	k2ForAllMixtures = [k2ForAllMixtures; dot(Saundersonk2,IntendedConcentrations(mix,:))]	;
end

% The Saunderson correction relates a measured reflectance, R_m, to the Kubelka-Munk
% reflectance, which is denoted R_inf for opaque films.  The input reflectances are assumed
% to have been measured with a spectrophotometer, so they correspond to R_m.  Kubelka-Munk
% calculations should be applied to R_inf.  Therefore use the Saunderson relationship to
% calculate R_inf from the input R_m, and use R_inf in the calculations.
% If no Saunderson correction has been input, then R_Inf will be identical to the
% input Reflectances
NumberOfWavelengths  = size(Reflectances,2)									;
k2ForAllReflectances = repmat(k2ForAllMixtures,1,NumberOfWavelengths)		;
R_Inf = SaundersonCorrectionInverse(Reflectances, 0, k2ForAllReflectances)	;
						
% Record the best estimates of K, S, and the concentrations, at each iteration	
Estimates = {}	;					

% The first iteration makes an initial estimate of the Kubelka-Munk coefficients, but not of
% the concentrations.  The initial estimate uses the input concentrations, which are expected
% to be reasonably near the true concentrations.  The routine KandSfromMixtures 
% implements the algorithm in [Walowit1987], with weights modified by [Centore2013], and with
% a GJK-based least squares algorithm described in [Centore2015]; the GJK approach allows
% constraints on K and S to be incorporated explicitly.  The
% routine KandSfromMixturesWalowit1987 can be used instead: it implements [Walowit1987],
% without modifying any weights, and uses a standard least squares algorithm.
[InitialK,InitialS] = KandSfromMixtures(Wavelengths,...
									   R_Inf,...
									   IntendedConcentrations)	;

% Record the most recent estimates in the results structure
Temp.K                       = InitialK					;
Temp.S                       = InitialS					;
Temp.EstimatedConcentrations = IntendedConcentrations	;											
Estimates{1} = Temp	;

% If the concentrations have been adjusted, then continue with the algorithm, further
% refining the estimates for the Kubelka-Munk coefficients and the concentrations
Iteration = 2				;
Converged = false			;
while	Iteration <= MaxIterations && not(Converged)
Iteration
fflush(stdout);
	% Get estimates from previous iteration
	Temp 					    = Estimates{Iteration - 1}		;
	PrevK    					= Temp.K						;	
	PrevS    					= Temp.S						;
	PrevEstimatedConcentrations = Temp.EstimatedConcentrations	;

	% Use the latest Kubelka-Munk coefficients to adjust the concentrations
	AdjustedConcentrations = EstimateConcentrations(Wavelengths,...
													R_Inf,...
													PrevK,...
													PrevS,...
													KnownConcentrations)	

	% Re-estimate the Kubelka-Munk coefficients, using the adjusted concentrations												
	[NewK,NewS] = KandSfromMixtures(Wavelengths,...
								   R_Inf,...
								   AdjustedConcentrations)	;

	% Save the new estimates in the results structure
	CurrentEstimates.K                       = NewK						;											   
	CurrentEstimates.S                       = NewS						;
	CurrentEstimates.EstimatedConcentrations = AdjustedConcentrations	;	
	Estimates{Iteration} = CurrentEstimates								;		
		
	% Find the differences between the previous concentrations and the current concentrations												
	ConcentrationDiffs = AdjustedConcentrations - PrevEstimatedConcentrations	;
	MaxDiff            = max(abs(ConcentrationDiffs(:,1)))						;

	% If the estimated concentrations are very near the previous estimates, then the 
	% algorithm has converged.  
	if MaxDiff < Threshold
		Converged = true	;
	end

	Iteration = Iteration + 1	;
end

% Whether or not the algorithm converged, use the latest results as the best estimates of
% the concentrations and Kubelka-Munk coefficients
Temp 					= Estimates{end}				;
K    					= Temp.K						;
S    					= Temp.S						;
EstimatedConcentrations = Temp.EstimatedConcentrations	;

% The following calculation will be needed either to draw a plot or to display information
% on the command line.
if DrawPlot || DisplayInformation	
	PredictedReflectances = ReflectanceOfMixtureFromKandS(...
							  EstimatedConcentrations,...
							  Wavelengths,...
							  K,...
							  S);
end

if DrawPlot 	% If desired, illustrate the results with a plot
	figure
%	plot(Wavelengths, Reflectances, 'k-', 'Linewidth',4, 'color',0.7*[1 1 1])	;
	plot(Wavelengths, Reflectances, 'k-')	;
	hold on
%	plot(Wavelengths, PredictedReflectances, '-', 'Linewidth', 1, 'color', [0 0 0])
	set(gca,'xlim',[400 700])
	set(gca,'ylim',[0 1])
%	set(gca, 'ytick', 0:0.2:1, 'yticklabel', ['0.0';'0.2';'0.4';'0.6';'0.8';'1.0'])
	set(gca, 'ytick', 0:0.2:1, 'yticklabel', ['  0';' 20';' 40';' 60';' 80';'100'])
	figname = 'KSandConcentrationResultsJustBlue';
	set(gcf, 'Name', figname);
%	Directory = '.' 	;	% Change if a different output directory is desired
	Directory = '/Users/paulcentore/Colour/ColourArticles/SuggestiveReflectanceSpectra/Figures' 	;	% Change if a different output directory is desired
	Directory = '/Users/paulcentore/Colour/PaintMixing/i1Pro2' 	;	% Change if a different output directory is desired
	print(gcf, [Directory,'/',figname,'.eps'], '-depsc');
	print(gcf, [Directory,'/',figname,'.svg'], '-dsvg');
	print(gcf, [Directory,'/',figname,'.pdf'], '-dpdf');
	
	FigureHandle = figure
	PlotReflectanceSpectraPerceptually(FigureHandle, ...
											Wavelengths, ...
											Reflectances, ...
											'k-')
%	figname = 'KSandConcentrationResultsJustBlueSuggestive';
	figname = 'KSandConcentrationResultsAllMixtures';
	set(gcf, 'Name', figname);
	print(gcf, [Directory,'/',figname,'.eps'], '-depsc');
	print(gcf, [Directory,'/',figname,'.svg'], '-dsvg');
	print(gcf, [Directory,'/',figname,'.pdf'], '-dpdf');
end	
	
% Display informtion on command line, if desired	
if DisplayInformation	
	% Print out information regarding how well coefficients and concentrations predict
	% the measured reflectance
	[RMS,DE00] = CompareReflectanceSpectra(Wavelengths,...
											 Reflectances,...
											 PredictedReflectances)	;
	DE00
	disp(['Average DE00 between measured and predicted colours is ',num2str(mean(DE00)),'.'])	;	
	disp(['Maximum DE00 between measured and predicted colours is ',num2str(max(DE00)),'.'])	;	
	disp(['Number of iterations used: ',num2str(length(Estimates))])	;		
	if Converged
		disp(['Algorithm converged.'])
	else
		disp(['Algorithm did not converge.'])
	end						 
end