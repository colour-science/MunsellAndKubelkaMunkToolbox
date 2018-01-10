function [AddNewPoint, 			...
		  VerticesToBeDeleted, 	...
		  AdjustPoint, 			...
		  AdjustedNewPoint] = 	...
				CheckNewPointMakesSimplex( ...
					SimplexVertices, 	...
					PossibleNewPoint)	;
% Purpose		Verify that a new point, that is to be added to an existing simplex, will
%				form a new simplex.  If not, then delete some points from the existing simplex,
%				or adjust the new point very slightly so that a simplex is formed.
%
% Description	This routine is intended as a helper routine to an implementation of the GJK
%				algorithm ([Gilbert1988], [Rabbitz1994], [Ericson2004], [McCutchan2006]).  The GJK
%				algorithm finds the minimum distance between two convex polytopes, or, in a
%				special case, between a convex polytope and a point.  The GJK algorithm chooses
%				a set of simplices, whose vertices are taken from a set whose convex hull is the
%				polytope; each simplex is (loosely speaking) closer to the point of interest.  
%				Once a simplex has been found, the Johnson algorithm is used to find a subsimplex
%				that is nearest to the point of interest.  That subsimplex S is then expanded to a
%				larger simplex by adding a new generator point p.
%
%				The difficulty is that the union of S and p might not be a simplex.  If S were
%				three corners of a square, for example, and p were the fourth corner, then S
%				would be a simplex, but the	union of S and p would not be a simplex.  This routine
%				checks to make sure that the union is a simplex.  If it is, the routine can
%				terminate, setting AddNewPoint to TRUE, and making no further adjustments.
%
%				If the union is not a simplex, then the configuration is investigated more
%				closely.  Possibly a vertex of S can be removed to make S union P into a simplex.
%				This would be the case, for example, if S were a pyramid, and p were directly
%				above the apex of the pyramid.  Then the five points do not form a simplex, but can
%				be made into a simplex by deleting the apex.  This deletion will not degrade the GJK
%				algorithm, because the new simplex will contain every point of the previous
%				simplex.  Furthermore, the deleted point is in the convex hull of other points,
%				so the GJK algorithm can ignore the deleted point without consequence.
%
%				Sometimes deleting vertices of the previous simplex is not sufficient.  For 
%				example, when the previous simplex was a triangle, and the new set is the vertices
%				of a square.  S union p is then in an unstable configuration, because the 
%				slightest adjustment can make it into a simplex.  If needed, we will adjust
%				the new point very slightly, by an amount that should have a negligible effect
%				on the calculations, to produce a stable simplex.  Unstable configurations
%				are statistically unlikely, but expected to occur when polytopes are produced
%				non-randomly.  An example is the cube, every face of which is an unstable,
%				non-simplicial square.
%
%				[Gilbert1988] 	Elmer G. Gilbert, Daniel W. Johnson, & Sathiya Keerthi, A Fast
%								Procedure for Computing the Distance Between Complex Objects in
%								Three-Dimensional Space, IEEE Journal of Robotics and Automation,
%								Vol. 4, No. 2, April 1988, pp. 193-203.
%				[Rabbitz1994]	Rich Rabbitz, Fast Collision Detection of Moving Convex Polyhedra,
%								in Section I.8 of Graphics Gems IV (IBM Version), ed. Paul Heckbert,
%								Academic Press, 1994.
%				[Ericson2004]	Christer Ericson, The Gilbert-Johnson-Keerthi Algorithm, 
%								http://realtimecollisiondetection.net/pubs/SIGGRAPH04_Ericson_GJK_notes.pdf
%				[McCutchan2006]	John McCutchan, Introduction to GJK, 9 November 2006,
%								http://www.cas.mcmaster.ca/~carette/SE3GB3/2006/notes/gjk1_pres.pdf
%
%				SimplexVertices		A set of vectors in n dimensions, which are the vertices of
%								a simplex.  The vertices are expressed
%								as row vectors, stacked up to form the matrix SimplexVertices.
%								The number of rows is the number of vertices, and
%								the number of colums is the dimension of the ambient space.
%
%				PossibleNewPoint	A point that we would like to add to SimplexVertices, to
%								make a new simplex.  
%
%				AddNewPoint		A Boolean variable that is TRUE if the possible new point (perhaps
%								adjusted) makes a simplex with the previous vertices (possibly
%								after deleting some of those vertices)
%
%				VerticesToBeDeleted		A subset of SimplexVertices, whose deletion results in
%								a simplex when PossibleNewPoint is added to SimplexVertices.
%
%				AdjustPoint		A Boolean variable that is TRUE if the possible new point has
%								been adjusted so that a simplex is formed.
%
%				AdjustedNewPoint	The adjusted version of PossibleNewPoint, if it has been decided
%								to make an adjustment.
%
% Author		Paul Centore (January 18, 2015)
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

% Initialize variables
AddNewPoint         = true	;
VerticesToBeDeleted = []	;
AdjustPoint         = false	;
AdjustedNewPoint     = []	;

EpsDist = 1e-15	;	% Minimum distance for some comparisons, to avoid numerical roundoff error

% Infer the number of vertices and the dimension of the ambient space from the size of the
% input variables
[NumberOfVertices, DimensionOfSpace] = size(SimplexVertices)	;

% Check whether the potential new point is inside the convex hull of the current simplex.  If
% it is, then it should not be added in.  Deleting current simplex vertices in this case
% will interfere with the GJK algorithm.  Since PossibleNewPoint is in the convex hull of 
% other points, the GJK algorithm can ignore without causing an error.  Pass along this
% information by setting AddNewPoint to FALSE.
[~,  ...
 Distance,     ...
 ~, ...
 ~, ...
 ~] = ClosestPointInSimplex(...
			SimplexVertices, ...
			PossibleNewPoint)	;
if Distance < EpsDist
	AddNewPoint = false	;
	return
end

% We have determined that the new point is outside the simplex, so adding it will extend
% the simplex.  We want to be sure, however, that none of the current vertices is inside the
% simplex formed by adding the potential new point to the current simplex.  If a current
% vertex would be inside, then it should be deleted.  Check through the current vertices
% one by one, making a list of those that should be deleted.
AllPoints = [SimplexVertices; PossibleNewPoint]	;
for ctr = 1:NumberOfVertices
	Vertex                       = SimplexVertices(ctr,:)	;
	AllPointsExceptVertex        = AllPoints				;
	AllPointsExceptVertex(ctr,:) = []						;
	[~,  ...
	 Distance,     ...
	 ~, ...
	 ~, ...
	 ~] = ClosestPointInSimplex(...
				AllPointsExceptVertex, ...
				Vertex)	;
	if Distance < EpsDist
		VerticesToBeDeleted = [VerticesToBeDeleted, ctr]	;
	end
end

% Even though we have deleted any points that might be in the interior of the new
% simplex, it is still possible that the remaining points, together with the input
% PossibleNewPoint, form a degenerate simplex.  Such would be the case, for example,
% if the current generators formed a triangle, and PossibleNewPoint was in the same
% plane, and adding it formed a diamond.  Then no point would be in the interior, but
% the points would not form a simplex because their convex hull would have 
% too low a dimension.
% This situation is unstable, in that an arbitrarily small adjustment to any of the
% vertices would result in a simplex with non-zero volumne.  Most practical situations
% should be robust to very small adjustments in the positions of the generators, so we
% will avoid this unstable case by adjusting PossibleNewPoint slightly.
RemainingGenerators                        = SimplexVertices	;
RemainingGenerators(VerticesToBeDeleted,:) = []					;
% Describe the simplex as a set of edges radiating out from PossibleNewPoint
EdgeVectors       = []	;
EdgeVectorLengths = []	;
for ctr = 1:rows(RemainingGenerators)
	EdgeVectors(ctr,:) = RemainingGenerators(ctr,:) - PossibleNewPoint	;
	EdgeVectorLengths(ctr) = norm(EdgeVectors(ctr,:))					;
end
% Find the minimum edge length to get a scale for what a "small" adjustment is
MinEdgeLength   = min(EdgeVectorLengths)	;
SmallAdjustment = MinEdgeLength/(1e3)		;
% The simplex will have full dimension if the matrix of edge vectors has full rank.
% In that case, no change is necessary.  If the matrix does not have full rank, however,
% then an adjustment will be made.
if rows(EdgeVectors) ~= rank(EdgeVectors)
	AdjustPoint      = true	;
	AdjustedNewPoint = []	;
	for ctr = 1:length(PossibleNewPoint)
		AdjustedNewPoint(ctr) = PossibleNewPoint(ctr) + SmallAdjustment * randn(1)	;
	end
end