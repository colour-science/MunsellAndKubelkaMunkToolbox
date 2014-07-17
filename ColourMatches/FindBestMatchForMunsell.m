function [IndexOfBestMatch, MinDE2000Diff, BestMunsSpec, BestMunsSpecColorLab] = ...
			FindBestMatchForMunsell(MunsellSpec, Wavelengths, Reflectances);
% Purpose		Of a set of object colour samples, whose reflectance spectra have been input,
%				find the one that best matches an input Munsell specification.
%
% Description	The input variables Wavelengths and Reflectances define a list of sample
%				colours, by their reflectance spectra.  The input variable MunsellSpec
%				gives a standard that we would like to match.  This routine finds the
%				sample colour in the input list that is closest to the standard.  The colour
%				difference is measured by the CIE DE 2000 formula.
%
%				This routine makes Munsell conversions, which can be slow.  If Munsell coordinates
%				are not important, then it might be faster to use a routine such as
%				FindBestMatchforxyY.m.
%
% Syntax		[IndexOfBestMatch, MinDE2000Diff, BestMunsSpec, BestMunsSpecColorLab] = 
%					FindBestMatchForMunsell(MunsellSpec, Wavelength, Reflectances)
%
%				MunsellSpec		Either a standard Munsell specification, such as 4.2R8.1/5.3,
%								or a Munsell vector in ColorLab format
%
%				Wavelengths		A row vector whose entries are the wavelengths for the reflectance  
%								spectra of the colour samples exported from a ColorMunki Design
%
%				Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%								between 0 and 1) for the reflectance spectra of the 
%								colour samples exported from a ColorMunki Design
%
%				IndexOfBestMatch	The colour sample with this index is the best match for 
%									the input variable MunsellSpec
%
%				MinDE2000Diff		The CIE DE2000 difference between the input Munsell specification
%									and the colour in the file that is the closet match
%
%				BestMunsSpec		A string in the from H V/C that gives the Munsell coordinates
%									of the closest match in the file
%		
%				BestMunsSpecColorLab		A row vector, in ColorLab format, of the Munsell coordinates
%									of the closest match in the file
%
% Author		Paul Centore (September 14, 2012)
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (January 1, 2014)  
%				 ---Used new CIE coordinate calculation routines, that call OptProp routines
%
% Copyright 2012-2014 Paul Centore
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

% Convert the input Munsell specification into Lab coordinates.  This will be the
% standard against which the samples are judged.

% The Munsell conversion routine returns a Y whose maximum value is 100
[x y Y Status] = MunsellToxyY(MunsellSpec);
if Status.ind ~= 1
    disp(['Could not convert Munsell specification'])		;
	return
end

% Express the Munsell standard in L*a*b* coordinates
[X, YOut, Z]   = xyY2XYZ(x, y, Y)						;
CWhitePointXYZ = WhitePointWithYEqualTo100('C/2')		;
[LabStand]     = xyz2lab([X, YOut, Z], CWhitePointXYZ)	;

% Find the number of samples to be tested for matching the Munsell standard
NumOfSamples = size(Reflectances,1)		;

% Convert samples into CIE coordinates
CIEcoords    = ReflectancesToCIEwithWhiteY100(Wavelengths, Reflectances, 'C/2');
%SamplesInLab = CIEcoords(:,4:6)				;

DE2000Differences = []						;
% For each sample, calculate CIEDE2000 for that sample and the standard
for ind = 1:NumOfSamples
    SampleInxyY = CIEcoords(ind, 4:6)											;
	[X Y Z]     = xyY2XYZ(SampleInxyY(1), SampleInxyY(2), SampleInxyY(3))		;
	SampleInXYZ = [X Y Z]														;
	SampleInLab = xyz2lab(SampleInXYZ, CWhitePointXYZ)							;
	diff        = deltaE2000(LabStand, SampleInLab)								;
	DE2000Differences = [DE2000Differences; diff]								;
end

[SortedValues, SortedIndices] = sort(DE2000Differences)							;
IndexOfBestMatch              = SortedIndices(1)								;
MinDE2000Diff                 = SortedValues(1)									;
	
% Convert xyY coordinates to a Munsell specification	
% First, check if the reflectance spectra is identically 100 %, or very close to it.  If
% it is, assign a Munsell specification of N10.  This check is necessary because the
% renotation inversion routine uses a fixed white point for Illuminant C.  The read-in
% values for Illuminant C could be at intervals of 5 nm, 10 nm, etc., making the white point
% disagree slightly with the white point used in xyYtoMunsell.  To avoid this issue, just
% assign a Munsell specification of N10 in this case.   
SampleReflectances = Reflectances(IndexOfBestMatch,:)	;
if min(SampleReflectances) >= 0.99
    BestMunsSpec = 'N10'						;
	MunsellVec   = [10]							;
else		% Reflectance spectrum is not identically 100 percent
    tempvec = CIEcoords(IndexOfBestMatch, 4:6)	;
	x    = tempvec(1)							;
	y    = tempvec(2)							;	
	Yrel = tempvec(3)							;
    [BestMunsSpec MunsellVec Status] = xyYtoMunsell(x, y, Yrel);
    if Status.ind ~= 1		% Conversion to Munsell specification failed
        BestMunsSpec           = 'NA'						;
		BestMunsSpecColorLab   = [-99 -99 -99 -99]			;
	    disp(['Failure to convert from xyY to Munsell.'])	;
		return
    end
end

% MunsellSpecsColorlab is a 4-column matrix, with one row for each reflectance spectrum.  The
% row entries are the Munsell specification in ColorLab format.  If the colour is not neutral,
% the ColorLab format has 4 entries.  If the colour is neutral, the ColorLab format has only
% 1 entry.  In order to make one matrix, with 4 entries in each row, convert the 1-element
% neutral format into a 4-element format.
if length(MunsellVec) == 1		
    BestMunsSpecColorLab(ind,:) = [0 MunsellVec 0 7]	;
else
    BestMunsSpecColorLab(ind,:) = [MunsellVec]			;
end