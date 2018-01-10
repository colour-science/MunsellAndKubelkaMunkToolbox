function [IndexOfBestMatch, MinDE2000Diff, SortedDEs, SortedIndices] = ...
				FindBestMatchforxyY(x, y, Y, CIEcoords, IllumObs);
% Purpose		Of a set of object colour samples, whose CIE coordinates are known, find 
%				the one that best matches an input xyY specification.
%
% Description	The input variable CIEcoords define a list of sample
%				colours, in XYZ and xyY coordinates.  The input variables (x,y,Y)
%				give a standard that we would like to match.  This routine finds the
%				sample colour in the input list that is closest to the standard.  The colour
%				difference is measured by the CIE DE 2000 formula.
%
%				The goodness of the match depends on the viewing conditions, which can be
%				specified by the input variable IllumObs.  If no viewing conditions are
%				input, then the routine defaults to Illuminant C with the 2 degree
%				observer.  The xyY and CIEcoords must have been calculated under the
%				assumption that the Y-value of the whitepoint is 100.
%
%				x, y, Y 	A colour specification in xyY format.  It is assumed that the
%							value is relative to a white point whose Y value is 100
%
%				CIEcoords	A six-column vector.  Each row contains XYZ coordinates, followed by
%							xyY coordinates, for a sample colour. It is assumed that the
%							CIE coordinates are relative to a white point whose Y value is 100
%
%				IndexOfBestMatch	The colour sample with this index is the best match for 
%									the input xyY standard
%
%				MinDE2000Diff		The CIE DE2000 difference between the input xyY
%									and the colour in the file that is the closet match
%
%				IllumObs	An illuminant/observer string, such as 'D50/2' or 'F12/10,' under
%							which the colour comparisons are to be made.  This input is
%							optional
%
%				SortedDEs, Sorted Indices	DEs from lowest to highest, along with
%											corresponding indices of rows in CIEcoords
%
% Author		Paul Centore (October 12, 2012)
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (January 4, 2014)  
%				 ---Allowed an illuminant-observer combination to be input.
%
% Copyright 2012, 2014 Paul Centore
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
if ~exist('IllumObs')
    IllumObs = 'C/2'	;
end

% Convert the input specification into Lab coordinates.  This will be the
% standard against which the samples are judged.
[X, YOut, Z]  = xyY2XYZ(x, y, Y)					;
WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs)	;
[LabStand]   = xyz2lab([X, YOut, Z], WhitePointXYZ)	;

% Find the number of samples
NumOfSamples = size(CIEcoords,1)	;

% For each sample, calculate CIEDE2000 for that sample and the standard
DE2000Differences = []				;
for ind = 1:NumOfSamples
	% Convert each sample into L*a*b*, and compare to input standard
    SampleInxyY = CIEcoords(ind, 4:6)											;
	[X Y Z]     = xyY2XYZ(SampleInxyY(1), SampleInxyY(2), SampleInxyY(3))		;
	SampleInXYZ = [X Y Z]														;
	SampleInLab = xyz2lab(SampleInXYZ, WhitePointXYZ)							;
	diff        = deltaE2000(LabStand, SampleInLab)								;
	DE2000Differences = [DE2000Differences; diff]								;
end

% Sort the DEs to find the best one, and return
[SortedDEs, SortedIndices]   = sort(DE2000Differences)							;
IndexOfBestMatch              = SortedIndices(1)								;
MinDE2000Diff                 = SortedValues(1)									;