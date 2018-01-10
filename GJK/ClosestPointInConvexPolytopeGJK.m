function [ClosestPoint,   ...
          Distance,       ...
          PointInPolytope,...
          Coefficients,   ...
          ErrorFlag] = ...
          ClosestPointInConvexPolytopeGJK(...
								InputPolytopeGenerators,...
								Point)
% Purpose		Find the point on a convex polytope which is closest to a given point.
%
% Description	This routine implements the Gilbert-Johnson-Keerthi (GJK) algorithm to determine,
%				in a space of arbitrary finite dimension, which point on a closed, convex
%				polytope is nearest to an input target Point.  It can easily be shown that
%				there always exists a unique nearest point on a closed convex polytope, from
%				any other point in the space, so there are no difficulties with non-existence
%				or multiple solutions.  
%
%				The convex polytope must be input as a set of points
%				in n-space, whose convex hull is the polytope.  Another typical characterization
%				of a convex polytope, that occurs in linear or quadratic programming, is as
%				all the points that satisfy a set of linear equations or inequalities.  If
%				the polytope is in this form, it will be necessary to convert it to a set of
%				generating points.  Typically, one finds the extreme points, which are a
%				generating set; this operation, however, can be numerically demanding.  The
%				input set of generating points does not have to be minimal.  The algorithm
%				will work even if one includes interior polytope points in the input.
%
%				The GJK algorithm was introduced
%				in 1988 ([Gilbert1988]).  Readable descriptions occur in [Rabbitz1994] (although 
%				the term GJK algorithm is not used there), [Ericson2004], and [McCutchan2006].
%				In a more general form, the algorithm finds the minimum distance between two
%				convex polytopes.  Since a single point is trivially a convex polytope, the
%				current routine can be seen as implementing a special case of the algorithm.
%				This special case is actually central to the more general algorithm, in which
%				one constructs the Minkowski difference of the two polytopes, and then finds
%				the minimum distance from the difference polytope to the origin.  This routine
%				would likely be called by a more general implementation of the algorithm, using
%				the Minkowsi difference as the polytope, and the origin as Point.
%
%				The algorithm works by forming simplices from subsets of the polytope s
%				generating points.  Johnson s sub-distance algorithm is used to find the closest 
%				point to Point on a simplex; the smallest subsimplex that contains the closest
%				point is also found.  The support function for the generating points is then
%				calculated, in the direction given by the vector from Point to the closest point.
%				The generating point of smallest support is then appended to the vertices of
%				the subsimplex, to create a new simplex.  (Provided that that point does indeed
%				create a new simplex.  If not, another point is chosen, some points are eliminated
%				until there is a new simplex, or points are very slightly
%				adjusted.)  Johnson s algorithm is applied to
%				that new simplex, and the algorithm repeats iteratively, until the points of
%				least support are all contained in the simplex.
%
%				The GJK algorithm is very fast, because the simplices typically only
%				have a few vertices, sometimes only two or three, so Johnson s algorithm is
%				very quick, even if it is inefficiently implemented.  Choosing the generator
%				of least support also avoids many calculations: many generators will never
%				belong to any simplex that the algorithm uses.  Calculating the support function
%				for all the generators is often the most time-consuming step. Sophisticated
%				methods can reduce these computations.  The present implementation, however,
%				emphasizes simplicity over speed.  Since this code is open source, others are
%				invited to modify it, if desired, for greater efficiency. 
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
%				InputPolytopeGenerators		A set of vectors in n dimensions.  Their convex hull is
%								the polytope of interest.  While every extreme point must be
%								included, one can also include points in the interior of the
%								polytope.  The generators are expressed
%								as row vectors, stacked up to form a matrix, so InputPolytopeGenerators
%								is a matrix.  The number of rows is the number of generators, and
%								the number of colums is the dimension of the ambient space.
%
%				Point			A point in n dimensions.  Point is a row vector with n entries.  The
%								routine finds the point on the polytope that is nearest to Point.
%
%				ClosestPoint	The closest point on the polytope to Point.  ClosestPoint is a
%								row vector with n entries.
%
%				Distance		The distance between Point and the closest point on the polytope.  This
%								output is 0 if Point is inside the polyotpe or on its boundary
%
%				PointInPolytope	A Booolean variable that is true if Point is inside the polytope or
%								on its boundary, and false otherwise.
%
%				Coefficients	The coefficients of a linear (in fact, convex) combination of a set
%								of generators that produces the closest point.  This output might
%								not be unique: another combination of a different set of generators
%								might produce the same closest point.  The ith entry of Coefficients
%								is the coefficient of the ith generator defined by InputPolytopeGenerators.
%
%				ErrorFlag		A Boolean variable that is true if the routine cannot return a
%								solution, and false otherwise.
%
% Author		Paul Centore (January 8, 2015)
% Revised		Paul Centore (February 18, 2015)
%				---Added check for case in which all generators are in one simplex, and the 
%				   nearest point is a combination of all the generators
% Revised		Paul Centore (February 20, 2015)
%				---Corrected condition of loop which checks for new point to add 
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
ClosestPoint    = []	;
Distance        = -99	;
Coefficients    = []	;
PointInPolytope = false	;
ErrorFlag       = false	;

% It might be necessary to adjust some of the generators very slightly, to avoid unstable
% equilibria, in which would-be simplices have zero relative volume.  Rather than changing
% the input variables directly, make a copy and change the copy
PolytopeGenerators = InputPolytopeGenerators	;

EpsDist = 1e-15	;	% Minimum distance for some comparisons, to avoid numerical roundoff error

% Infer the number of vertices and the dimension of the ambient space from the size of the
% input variables
[NumberOfPolytopeGenerators, DimensionOfSpace] = size(PolytopeGenerators)	;

% Translate the input point to the origin; translate the simplex by the same amount
TranslatedPolytopeGenerators = PolytopeGenerators - repmat(Point,NumberOfPolytopeGenerators,1)	;

% Choose a simple initial set, consisting of a point with lowest norm
GeneratorNorms = []	;
for ctr = 1:NumberOfPolytopeGenerators
	GeneratorNorms = [GeneratorNorms; norm(TranslatedPolytopeGenerators(ctr,:))]	;
end
[SortedNorms, SortedIndices] = sort(GeneratorNorms)					;
Subset        = TranslatedPolytopeGenerators(SortedIndices(1),:)	;
SubsetIndices = SortedIndices(1) 									;							

% Use a loop that constructs new simplices, such that each simplex is closer to the origin
% than the previous simplex.
NearestPointFound = false	;
while not(NearestPointFound)
    % The entries in Subset should form a simplex.  We will find the closest point to the
    % origin for that simplex, along with other information.
	[ClosestPoint,  ...
	  Distance,     ...
	  NestedSubsetIndices, ...
      IntCoefficients, ...
      ErrorFlag] = ClosestPointInSimplex(...
						Subset,    ...
						zeros(1,DimensionOfSpace))	;
	% If the simplex routine did not terminate successfully, then return from the current
	% routine, too, with an error flag.						
	if ErrorFlag
		return
	end		
	
	% Express the current closest point estimate as a linear combination of the input
	% polytope generators
	Coefficients = zeros(1,NumberOfPolytopeGenerators)	;		
	for ctr = 1:length(IntCoefficients)
		Coefficients(SubsetIndices(NestedSubsetIndices(ctr))) = IntCoefficients(ctr)	;
	end

	% Construct a new simplex.  Begin with those points of the previous simplex that are
	% needed to find the closest point on that previous simplex
	SubsetIndices = SubsetIndices(NestedSubsetIndices)	;

	% Check whether the distance to the closest point in the simplex is effectively 0.  If
	% it is, then conclude that Point is inside (or on the boundary of) the polytope
	if Distance < EpsDist
		PointInPolytope   = true					;
		NearestPointFound = true					;
	else
		% The current closest point can also be seen as a vector pointing away from the origin.
		% Calculate the support of all the polytope generators with respect to this vector.
		Supports = []	;
		for ctr = 1:NumberOfPolytopeGenerators							
			Supports = [Supports; dot(ClosestPoint, TranslatedPolytopeGenerators(ctr,:))./...
								(norm(ClosestPoint))]	;
		end
		
		% Extract the supports of the current subset, and find the minimum current support
		CurrentSupports   = Supports(SubsetIndices)	;
		MinCurrentSupport = min(CurrentSupports)	;
		% The generator (or at least _a_ generator) with as small a support
		% as possible should be added to the
		% subset in which potential closest points are looked for.  It must also be insured,
		% however, that the new generator does indeed form a simplex when added to the
		% current set of generators.  Search through the generators of smallest support, in
		% ascending order, selecting the first one that does indeed form a new simplex.
		[SortedNorms, SortedIndices] = sort(Supports)	;
		IndexOfMinimum               = 1				;	
		NewPointToBeAdded            = false			;
		while not(NewPointToBeAdded) && ...
			IndexOfMinimum <= length(Supports) && ...
			SortedNorms(IndexOfMinimum) <= MinCurrentSupport	% Corrected from Supports(IndexofMinimum)
																% on Feb. 20, 2015, by Paul Centore
%disp(['in loop 1']); fflush(stdout);																
			% The generator being added should form a new simplex when added to the generators
			% that are already in the set.  The following routine checks this condition,
			% and will suggest deleting current vertices if needed.  It might also suggest
			% adjusting a generator slightly, to avoid unstable equilibria, such as a 
			% square bounding face, where a set of vertices have the same minimal support,
			% but do not form a simplex.
			[AddNewPoint, ...
			 VerticesToBeDeleted, ...
			 RevisePoint, ...
			 RevisedNewPoint] = ...
				CheckNewPointMakesSimplex( ...
					Subset, ...
					TranslatedPolytopeGenerators(SortedIndices(IndexOfMinimum),:))	;
%disp(['in loop 2']); fflush(stdout);																
					
			if RevisePoint	
%disp(['in loop 3']); fflush(stdout);																
				TranslatedPolytopeGenerators(SortedIndices(IndexOfMinimum),:) = RevisedNewPoint	;
			end	

			if AddNewPoint 	% The new generator forms a simplex when added to the
							% current set of generators.  Therefore, add it to the set
				NewPointToBeAdded = true	;	 % Flag to break out of searching loop
				% Delete any generators that are inside the simplex when the new point is
				% added
%disp(['in loop 4']); fflush(stdout);																
				SubsetIndices     = setdiff(SubsetIndices, SubsetIndices(VerticesToBeDeleted))	;
				SubsetIndices     = reshape(SubsetIndices, length(SubsetIndices), 1)			;
				% Add the new generator to the latest list of generators
				SubsetIndices     = [SubsetIndices; SortedIndices(IndexOfMinimum)]				;
				Subset            = TranslatedPolytopeGenerators(SubsetIndices,:)				;
			else
%disp(['in loop 5']); fflush(stdout);																
				IndexOfMinimum = IndexOfMinimum + 1	;
				% Possibly all the generators are in one simplex, which contains the nearest 
				% point.  In that case, no new point should be added
				if IndexOfMinimum == length(Supports)
					NewPointToBeAdded = false	;
				end
			end
		end
		if not(NewPointToBeAdded)	% We have checked through all points, and found that
					% none of them would expand the subset we already have, and also include
					% a closer point than we already have.  Therefore the algorithm has
					% converged.
			NearestPointFound = true	;
		end
	end
end							

% The closest point was found after translating the input point to the origin; translate
% back for the returned answer
ClosestPoint = ClosestPoint + Point	;