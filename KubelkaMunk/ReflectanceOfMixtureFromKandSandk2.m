function Reflectances = ReflectanceOfMixtureFromKandSandk2(Wavelengths,...
														   Concentrations,...
												           K,...
												           S,...
												           k2);
% Purpose		Given the Kubelka-Munk and Saunderson coefficients of various constituent paints, 
%				find the reflectance spectra of mixtures of those paints at the input concentrations.
%
% Description	[Allen1980] describes the Kubelka-Munk model, which gives the reflectance spectra
%				of mixtures of constituent paints at input concentrations.  The model requires absorption
%				and scattering coefficients (K and S) for each constituent paint, at each wavelength.  In
%				addition, the Saunderson correction (see [Saunderson1942]) coefficients (k2) are used.  The
%				basis of this routine is Eq. (19) of [Allen1980], which gives the reflectance of a mixture
%				when applied as a masstone, and Eq. (6) of [Saunderson1942], which corrects for total
%				internal reflection (TIR).
%
%				This routine makes one assumption, which might not have a sound physical basis: it
%				is assumed that the TIR percentage for a mixture of colorants is the linear sum
%				of the TIR percentages for the individual colorants (in proportion to their
%				concentrations).  This assumption would hold in visual mixing, in which the surface
%				of the mixture consists of the constituent colorants in proportion to their 
%				concentrations.  The Kubelka-Munk model, on the other hand, models a mixture as
%				a series of horizontal layers of the constituents.  Neither approach is physically
%				accurate, but both might be adequate for practical models.  Future investigations,
%				therefore, could require this routine to be updated.
%
%				Wavelengths		A row vector whose entries are the wavelengths at which the Kubelka-Munk  
%								coefficients apply.  
%
%				Concentrations	A matrix with the concentrations of paints in the mixtures.  The concentrations
%								are numbers between 0 and 1.  Each row of Concentrations gives the concentrations
%								for one mixture.  The number of columns of Concentrations is the number of
%								constituent paints or colorants.
%
%				K,S				Kubelka-Munk absorption and scattering coefficients for the constituent paints in
%								the mixtures.  There is a different coefficient for each
%								wavelength in Wavelengths.  K and S are both matrices.  The first row of
%								K gives the values of K for the first paint, at the wavelengths in the
%								input Wavelengths, the second row is for the second paint, and so on.
%
%				k2				A column of values of k2 (the Saunderson correction coefficient (see
%								Ref. [Saunderson1942])), for the constituent paints.
%
%				Reflectances	A matrix of reflectances (expressed as values 
%								between 0 and 1), at the wavelengths in the input Wavelengths,
%								of the paint mixtures determined by by mixing the constituent paints or
%								colorants at the given Concentrations.  
%
% References	[Allen1980] Eugen Allen, Chapter 7 of Optical Radiation Measurements, Vol. 2:
%				Color Measurement, eds. Franc Grum & C. James Bartleson, Academic Press, 1980.
%           	[Saunderson1942] J. L. Saunderson, Calculation of the Color of Pigmented
%				Plastic, Journal of the Optical Society of America, Vol. 32, December 1942,
%				pp. 727-736.
%
% Author		Paul Centore (October 17, 2014)
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

% If desired, make a plot of the reflectance spectra of the mixtures
PlotReflectanceSpectra = false	;

NumOfPaints      = size(Concentrations,2)	;	% Number of constituent paints or colorants
NumOfWavelengths = length(Wavelengths)		;
NumOfMixtures    = size(Concentrations,1)	;

% Initialize output variable
Reflectances = -99*ones(NumOfMixtures,NumOfWavelengths)	;

% Calculate reflectance spectrum for each mixture
for MixInd = 1:NumOfMixtures

	% The Saunderson correction is assumed not to depend on wavelength, and is modeled as
	% depending linearly on the concentrations of the constituents in the mixture
	Mixturek2 = sum(Concentrations(MixInd,:) .* reshape(k2,1,length(k2)))	;
	% Divide by sum of concentrations, just in case the concentrations do not sum to 1
	Mixturek2 = Mixturek2/sum(Concentrations(MixInd,:))						;

    % Calculate reflectance for each wavelength.  Loop over wavelengths.
    for ctr = 1:NumOfWavelengths
	
	    % Calculate K, S, and k2 for mixture, as linear combination of K and S from constituents
	    MixtureK = 0	;
	    MixtureS = 0	;
	    for ind = 1:length(Concentrations(MixInd,:))
		    MixtureK = MixtureK  + Concentrations(MixInd,ind) * K(ind,ctr)		;
		    MixtureS = MixtureS  + Concentrations(MixInd,ind) * S(ind,ctr)		;
	    end
		% Divide by sum of concentrations, just in case the concentrations do not sum to 1
	    MixtureK = MixtureK/sum(Concentrations(MixInd,:))		;
	    MixtureS = MixtureS/sum(Concentrations(MixInd,:))		;

        % Use the relationship between K, S, and the reflectance of the masstone (Equation (19)
		% of [Allen1980]).  This reflectance, which is usually denoted R_infinity, makes no 
		% correction for total internal reflection
	    R_Inf(MixInd, ctr)        = MasstoneRfromKandS(MixtureK, MixtureS)		;
	    
	    % Now use the Saunderson correction to adjust that reflectance
		Reflectances(MixInd, ctr) = SaundersonCorrection(R_Inf(MixInd, ctr), 0, Mixturek2)	;
		
	    % To avoid possible numerical issues, make sure each reflectance is between 0 and 1
	    if Reflectances(MixInd, ctr) < 0
		    Reflectances(MixInd, ctr) = 0	;
	    elseif Reflectances(MixInd, ctr) > 1
		    Reflectances(MixInd, ctr) = 1	;
	    end
    end
end

if PlotReflectanceSpectra
	figure
	plot(Wavelengths, Reflectances, 'k-')
	figname = 'KubelkaMunkPredictedReflectanceSpectra';
    set(gcf, 'Name', figname);
    print(gcf, ['./',figname,'.eps'], '-depsc');
    print(gcf, ['./',figname,'.svg'], '-dsvg');
    print(gcf, ['./',figname,'.pdf'], '-dpdf');
end