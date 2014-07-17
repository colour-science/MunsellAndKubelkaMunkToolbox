function [RankedMaxDE2000, RankedIndices, CompMatrix] = EvaluateDEsToReflectanceSpectraMultiIllum( ...
																   WavelengthsStandard, ...
																   ReflectancesStandard, ...
																   Wavelengths, ...
																   Reflectances, ...
																   IllumObsList);
% Purpose		Reflectance spectra for a set of object colour samples are input, along with the
%				reflectance spectrum for a standard that is trying to be matched.  The match is
%				desired to be adequate simultaneously under an input list of multiple illuminants.
%				Rank the possible matches in terms of overall effectiveness.
%
% Description	This routine was intended to help in providing printed matches for paints.
%				The reflectance spectrum of a target paint is given by the input variables
%				WavelengthsStandard and ReflectancesStandard.  There might be a large
%				number of possible matches.  Their reflectance spectra are given by the 
%				input matrix Reflectances, and all refer to the wavelengths in the input
%				vector Wavelengths.
%
%				The accuracy of a match depends not just on the reflectances of the two
%				colours that should match, but also on the viewing conditions, defined
%				by the illuminant and observer.  Because of metamerism, two samples might
%				match well under one illuminant, but not under another illuminant.  The
%				input variable IllumObsList is a list of viewing conditions under which
%				the potential match is expected to be viewed.
%
%				To evaluate the overall effectiveness of a particular potential match,
%				the DE between that match and the standard is found for every illuminant
%				on the input list.  The maximum of all those DEs is the largest error 
%				that would be expected for that match.  The lower the maximum DE is, the
%				better the match is, overall.  The routine ranks the potential matches, 
%				from lowest maximum DE to highest maximum DE, and returns the ranked
%				max DEs, along with their corresponding indices.  
%
%				The returned matrix CompMatrix gives more detailed information about the
%				effects of the illuminants on the matches.  Each row in CompMatrix refers
%				to one possible match, and each column refers to one illuminant.  The 
%				entry is the DE between that possible match and the standard, when viewed
%				under that illuminant.
%
%				This routine is similar to another routine, Evaluate DEsToReflectanceSpectra.
%				The other routine is used when there is only one illuminant, and when the
%				standard is defined colorimetrically, rather than spectrally.  For example,
%				the Munsell renotation gives CIE coordinates for Munsell specifications,
%				relative to Illuminant C and the 2 degree observer.  In that case, a
%				reflectance spectrum for the standard is not defined.  
%
%				WavelengthsStandard	The wavelengths of the reflectance spectrum of the
%									standard that is to be matched
%
%				ReflectancesStandard	The reflectances, between 0 and 1, of the 
%									reflectance spectrum of the	standard to be matched.
%									The reflectances correspond to the wavelengths in
%									WavelengthsStandard									
%
%				Wavelengths		A row vector whose entries are the wavelengths for the reflectance  
%								spectra of potential matches.  The wavelengths should be evenly spaced
%
%				Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%								between 0 and 1) for various reflectance spectra at the wavelengths
%								listed in the first input
%
%				IllumObsList	An list of illuminant/observer strings, such as 'D50/2' or
%								'F12/10,' under	which possible colour matches are to be compared
%
%				RankedIndices   The indices of the input reflectance spectra, ordered from 
%								the lowest max DE to the highest max DE
%
%				RankedMaxDE2000	A vector of maximum CIE DE 2000 differences between the
%								standard and the potential matches.  Their order corresponds 
%								to the order of the indices in the output RankedIndices
%
%				CompMatrix  The i-j th entry of this matrix is the DE between the ith
%							possible match and the standard, when viewed under the jth
%							illuminant
%
% Author		Paul Centore (December 27, 2013)
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

% Default to Illuminant C with a 2 degree standard observer if no illuminant or observer 
% information is input
if ~exist('IllumObsList')
    IllumObsList{1} = 'C/2'	;
end

% Make a matrix of DEs for all possible matches, under all illuminants of interest.  
% Attempted matches index the rows; illuminants index the columns.  Each 
% matrix entry is the DE2000 that would result if the original standard and the attempted 
% match were viewed under that illuminant.
NumOfIlluminants = length(IllumObsList)		;
NumOfSpectra = size(Reflectances,1)			;
CompMatrix = -99 * ones(NumOfSpectra,NumOfIlluminants)		;
for IllumCtr = 1:NumOfIlluminants
	% Find CIE coordinates for the standard when viewed under a particular illuminant.
	% Also, find the white point for that illuminant
	CIEcoords = ReflectancesToCIEwithWhiteY100( ...
	              WavelengthsStandard, ReflectancesStandard, IllumObsList{IllumCtr}) ;
	XYZStand  = CIEcoords(1:3,1)	;
    XYZwhitepoint = WhitePointWithYEqualTo100(IllumObsList{IllumCtr})	;
    
    for SpectraCtr = 1:NumOfSpectra
    		% Use the following code, if it is desired to print out the progress rate
		% if mod(SpectraCtr,500) == 0
		%    disp(['Rows in reflectance matrix: ',num2str(SpectraCtr),' out of ',num2str(NumOfSpectra)])
		%	fflush(stdout)	;
		% end	
		
		% Find the CIE coordinates for the possible match, and evaluate its DE from the
		% standard, under the current illuminant.  Place the DE in CompMatrix
  	    CIEcoords = ReflectancesToCIEwithWhiteY100( ...
	              Wavelengths, Reflectances(SpectraCtr,:), IllumObsList{IllumCtr}) ;
	    XYZmatch  = CIEcoords(1:3,1)	;
		CompMatrix(SpectraCtr, IllumCtr) = CIEDE2000ForXYZ(XYZStand, XYZmatch, XYZwhitepoint)	;			;
	end
end

% Find the maximum DE for all the possible matches, and rank them
MaxDE = transpose(max(transpose(CompMatrix)))	;
[RankedMaxDE2000, RankedIndices] = sort(MaxDE)	;