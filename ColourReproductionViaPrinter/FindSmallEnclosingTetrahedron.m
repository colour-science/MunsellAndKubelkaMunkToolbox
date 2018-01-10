function [InterpolatedRGB, RGBvertices, LabVertices, AllBaryCoords, minDE2000, minRGB, TetrahedronDEs] = ...
          FindSmallEnclosingTetrahedron(RGBs, Labs, LabAimPoints, OutOfGamut);
% Purpose		Given a set of RGBs, and the Labs they produce when printed, find a set of
%				four of those Labs (forming a tetrahedron) which enclose a target Lab.  The
%				tetrahedra should be small in the sense that their DEs from the target are
%				small.
%
% Description	This routine   
%
%				RGBs				A three-column matrix of RGB triples
%
%				Labs				A three-column matrix of CIE coordinates, which correspond to the
%									RGB triples.  The CIE coordinates are written here as "Lab," but could
%									be any kind of CIE coordinates, such as XYZ or xyY.
%
%				LabAimPoints 		A three-column matrix of aimpoints, in the same CIE coordinates as Lab
%
%				OutOfGamut 			A Boolean vector which is true when the aimpont is known to be out of
%									gamut
%
%				InterpolatedRGB		A three-column matrix, the same size as AimPoints, that contains an RGB
%									triple for the corresponding CIE aimpoint
%
%				RGBvertices			A structure of matrices.  Each matrix lists the four RGB triples that
%									make up the vertices of the tetrahedron that contains an aimpoint
%									interpolation
%
%				Labvertices			A similar structure to RGB vertices, but in CIE space
%
%				AllBaryCoords		A structure with the barycentric coordinates of the interpolated aimpoints
%
%				minDE2000			A vector of the minimum DE obtained for each aimpoint
%
%				minRGB				A three-column vector, each row of which gives the RGB values that
%									produce the Lab point that is closest to the aimpoint
%
%				TetrahedronDEs 		A four-column vector.  The ith row gives the DEs between the ith
%									aimpoint and the four vertices of the enclosing tetrahedron
%
% Author		Paul Centore (September 19, 2014)
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

% Initialize return variables that might not be set
InterpolatedRGB = []	;
RGBvertices     = {}  	;
LabVertices     = {}  	;
AllBaryCoords   = []	;
TetrahedronDEs  = []	;
minDE           = []	;
minRGB          = []	;

DisplayProgress = true 	;	% A flag for displaying the routine s progress on large sets

% Possible containing tetrahedra will be constructed from Lab points (of known RGBs) that
% are nearby the Lab aimpoint.  Set a limit on the number of nearby points that will be
% considered.
MaxNumberOfNearbyPoints = 10 	;

[NumberOfAimPoints, ~]  = size(LabAimPoints)	
NumberOfLabs            = size(Labs,1) 		;

tic()	;

% Loop through each aimpoint, identifying an enclosing tetrahedron, if possible
for APctr = 1:NumberOfAimPoints

	% This routine might be slow, so print out progress reports periodically
	if mod(APctr,10) == 0 && DisplayProgress
	   ElapsedTime = toc()			;
	   RemainingMinutes = (ElapsedTime/APctr) * (NumberOfAimPoints-APctr+1)/60	;
	   disp([num2str(ElapsedTime), ' sec; ',num2str(APctr),' out of ', num2str(NumberOfAimPoints),...
			 '; minutes remaining: ', num2str(RemainingMinutes)])	;
	   fflush(stdout)												;
	end

	% Initialize variables
	InterpolatedRGB(APctr,:) = [-99 -99 -99]		;
	RGBvertices{APctr}       = -99 * ones(4,3)		;
	LabVertices{APctr}       = -99 * ones(4,3)		;
	AllBaryCoords(APctr,:)   = [-99 -99 -99 -99]	;
	TetrahedronDEs(APctr,:)  = [-99 -99 -99 -99]	;
	minDE2000(APctr,1)       = -99 					;
	minRGB(APctr,:)          = [-99 -99 -99]		;

	% Check to make sure the aimpoint is in gamut.  If not, then return -99s.  This check
	% is mainly to save the time needed to find the nearest RGB.
	if not(OutOfGamut(APctr))
	
		% Calculate CIEDE2000 between each Lab and the aimpoint Lab
		DE2000diffs = []	;
		for ctr = 1:NumberOfLabs
			diff        = deltaE2000(LabAimPoints(APctr,:), Labs(ctr,:))	;
			DE2000diffs = [DE2000diffs; diff]								;
		end

		% Rank the possible matches, from lowest DE to highest
		[DE2000, RankedIndices] = sort(DE2000diffs)		;

		% Find and return the Lab point which is nearest the Lab aimpoint
		minDE2000(APctr,1) = DE2000(1) 					;
		minRGB(APctr,:)    = RGBs(RankedIndices(1),:)	;

		PositionInNearbyPointsList = 4		;
		EnclosingTetrahedronFound = false 	;
		while not(EnclosingTetrahedronFound) && PositionInNearbyPointsList <= MaxNumberOfNearbyPoints
	
			% Construct all tetrahedra whose vertices are contained in the n nearest points.  To
			% avoid repetition, require that the nth point be one of the vertices.
			Combinations       = combinator(PositionInNearbyPointsList, 4, 'c')	;
			PossibleTetrahedra = [] 	;
			for CombRow = 1:size(Combinations,1)
				Vertices = Combinations(CombRow,:)	;
				% Check that latest vertex is included in tetrahedron
				if ismember(PositionInNearbyPointsList, Vertices)
					PossibleTetrahedra = [PossibleTetrahedra; reshape(RankedIndices(Vertices),1,4)]	;
				end
			end

			% Loop through possible tetrahedra, to find see if one really does contain the aimpoint
			NumberOfPossibleTetrahedra = size(PossibleTetrahedra,1) 	;
			ctr = 1		;
			while not(EnclosingTetrahedronFound) && ctr <= NumberOfPossibleTetrahedra
				if ismember(RankedIndices(PositionInNearbyPointsList), PossibleTetrahedra(ctr,:))
					LabVerticesOfTetrahedron = [Labs(PossibleTetrahedra(ctr,1),:) ; ...
												Labs(PossibleTetrahedra(ctr,2),:) ; ...
												Labs(PossibleTetrahedra(ctr,3),:) ; ...
												Labs(PossibleTetrahedra(ctr,4),:) ]	;
					Beta = cart2bary (LabVerticesOfTetrahedron, LabAimPoints(APctr,:))	;
					if min(Beta) >= 0 && max(Beta) <= 1
						EnclosingTetrahedronFound = true 	;
						RGBvertices{APctr} = [ RGBs(PossibleTetrahedra(ctr,1),:) ; ...
											   RGBs(PossibleTetrahedra(ctr,2),:) ; ...
											   RGBs(PossibleTetrahedra(ctr,3),:) ; ...
											   RGBs(PossibleTetrahedra(ctr,4),:) ]	;
						LabVertices{APctr} = LabVerticesOfTetrahedron 	;
						InterpolatedRGB(APctr,:) = Beta(1) * RGBs(PossibleTetrahedra(ctr,1),:) + ...
												   Beta(2) * RGBs(PossibleTetrahedra(ctr,2),:) + ...
												   Beta(3) * RGBs(PossibleTetrahedra(ctr,3),:) + ...
												   Beta(4) * RGBs(PossibleTetrahedra(ctr,4),:) ;
						AllBaryCoords(APctr,:)  = [Beta(1) Beta(2) Beta(3) Beta(4)] 	;
						TetrahedronDEs(APctr,:) = DE2000diffs(PossibleTetrahedra(ctr,1:4))	;
					end
				end
				ctr = ctr + 1 	;
			end		% End looping through possible containing tetrahedra from set of n nearest points
			% For the next iteration, add the next nearest data point, and construct new tetrahedra that
			% contain that point
			PositionInNearbyPointsList = PositionInNearbyPointsList + 1	;
		end 		% End looping through possible containing tetrahedra
	end			% End check to make sure aimpoint is in gamut
end 			% End looping through list of aimpoints