function [Vertices ListOfEdges ListOfFaces VertexCoefficients ZonohedronFigureHandle] = ...
			ConstructCyclicZonohedron(GeneratingVectorsInCyclicOrder);
% Purpose		Find the vertices, edges, and faces of the zonohedron generated by a set of
%				three-dimensional vectors in cyclic form, meaning that no vector is in the
%				convex hull of the remaining vectors.  The
%				generating vectors must be in general position: no set of 
%				three (or fewer) input vectors can be linearly dependent.  Also, produce
%				a figure showing the zonohedron.
%
% Description	A zonohedron is the set of all linear combinations of a set of generating
%				vectors, such that the coefficients of any linear combination is between
%				0 and 1, inclusive.  A zonohedron is a convex polytope.  Each edge of the
%				zonohedron is a translation of one of the generating vectors.  Each face 
%				of the zonohedron is a parallelogram.  The coefficients of the linear
%				combinations that make up the vertices are all either 0 or 1.  
%
%				This routine calculates the vertices, edges, and faces, of the zonohedron
%				generated by an input set of three-dimensional vectors.  It is assumed
%				that the vectors are cyclic, meaning that no vector is in the convex cone of
%				the remaining vectors.  Furthermore, it is assumed that no two of
%				the input vectors are parallel, and no three are linearly dependent.  
%
%				While finding the vertices, edges, and faces of a zonohedron is a difficult
%				problem in general, that problem is much simpler for cyclic zonohedra.
%				Pp. 113-115 of [Centore2013] gives a general procedure, which assumes that the
%				generating vectors are numbered cyclically, either clockwise or
%				counterclockwise.  This approach has been implemented in another routine,
%				which this routine calls.
%
%				This routine uses three output lists to express a cyclic zonohedron s
%				combinatorial structure.  The first list gives the vertices.  Each entry
%				in this list is a vector of indices, and the sum of the generators with
%				those indices is a vertex of the zonohedron.  The first entry in the list
%				is the empty vector, which corresponds to the origin, which is also a
%				vertex.  The second list gives the edges.  Each entry in this list consists
%				of a two-element vector.  The two elements are indices into the first list,
%				of vertices; the zonohedron has an edge between the two vertices with those
%				indices.  The third list gives the parallelogram faces.  Each entry is
%				a four-element vector, where the elements are indices in the list of
%				vertices.  If the fourth vertex is joined to the first, then those four 
%				vertices form a parallelogram face of the cyclic zonohedron.
%
%				[Centore2013] 	Paul Centore, A Zonohedral Approach to Optimal Colours,
%								Color Research and Application, Vol. 38, No. 2, pp. 110-119,
%								April 2013.
%
%				GeneratingVectorsInCyclicOrder	A cyclic set of three-dimensional vectors.  The
%									zero vector is not allowed, and no two vectors may be parallel.
%									This variable is a three-column matrix, where each row gives
%									a different generating vector; the vectors are assumed to be
%									listed cyclically, in either clockwise or counterclockwise
%									order.  
%
%				Vertices		A list of vertices, in a three-column matrix, where each row
%								is a vertex of the zonohedron.  
%
%				ListOfEdges		A list of two-element vectors.  The entries of each vector 
%								are indices into the list of vertices.  If two vertices
%								appear in such a vector, then the zonohedron has an edge
%								joining them.
%
%				ListOfFaces		A list of four-element vectors.  The entries of each vector 
%								are indices into the list of vertices.  If four vertices
%								appear in such a vector, then they are the corners of a
%								parallelogram face on the zonohedron.
%
%				VertexCoefficients	A list of vectors.  The entries of the ith vector are indices
%								to the generators; summing up the generators with those
%								indices gives the ith vertex of the zonohedron, which appears
%								in the output varible Vertices.
%
%				ZonohedronFigureHandle	The handle to a 3-d figure of the zonohedron.
%
% Author		Paul Centore (January 28, 2016)
%
% Copyright 2016 Paul Centore
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

% To construct the cyclic zonohedron, use the fact that its combinatorial structure depends
% only on the number of generating vectors.  Extract the number of such vectors, and use
% it as an input to a routine that determines that combinatorial structure.
NumOfGens = length(GeneratingVectorsInCyclicOrder(:,1));
[VertexCoefficients ListOfEdges ListOfFaces] = ...
			CombinatorialStructureOfCyclicZonohedron(NumOfGens);
			
% The combinatorial structure expresses each zonohedron vertex as a sum of generating
% vectors.  The variable VertexCoefficients gives the coefficients in these sums, and
% the following section of code calculates the actual vertices from those coefficients			
Vertices = []	;			
for ind = 1:length(VertexCoefficients)
	% Each entry in VertexCoefficients is a vector, and the entries in that vector are
	% the indices of rows in GeneratingVectorsInCyclicOrder; summing up the rows
	% corresponding to those indices gives a vertex in the zonohedron.  If an entry in
	% VertexCoefficients is the empty vector, then the corresponding vertex is the origin.
	VectorOfSummands = VertexCoefficients{ind}		;
	NumberOfSummands = length(VectorOfSummands)	;
	if NumberOfSummands == 0
		Vertex = [0 0 0]	;
	else
		% Sum up the rows of GeneratingVectorsInCyclicOrder specified by an entry
		% in VertexCoefficients
		Vertex = [0 0 0]	;
		for ctr = 1:NumberOfSummands
			Vertex = Vertex + GeneratingVectorsInCyclicOrder(VectorOfSummands(ctr),:)	;
		end
	end
	Vertices = [Vertices; Vertex]	;
end


% Save the zonohedron construction data in .ply format, which can be used by 3-d programs
% like Blender, or other software
VertexIndicesStructure = {}	;
for ind = 1:length(ListOfFaces)
	% The .PLY format counts vertices starting at 0, rather than 1, so subtract 1 from all the
	% vertex references
	VectorOfIndices = ListOfFaces{ind} - 1			;
	VertexIndicesStructure{ind} = VectorOfIndices	;
end

% Put geometric data in a structure that is used as input to a routine that produces PLY files
Data.vertex.x = Vertices(:,1)	;
Data.vertex.y = Vertices(:,2)	;
Data.vertex.z = Vertices(:,3)	;
Data.face.vertex_indices = VertexIndicesStructure	;

% Put in format of PLY file, and save
ply_write(Data, ['Zonohedron.ply'], 'ascii')		;


% Create a 3-d figure of the cyclic zonohedron.  Rather than displaying it directly, this
% routine returns the figure handle for a calling outine to use.  Another option, one
% not implemented here, is to use the .ply file to make a figure.  
ZonohedronFigureHandle = figure	;
%ZonohedronFigureHandle = open('/Users/paulcentore/Colour/ColourArticles/ZonohedralGamutsForColourConstancy/Figures/IllAObjectColourSolid.fig');

if false	% If desired, the generating vectors can be displayed.  Each generator
			% appears on the zonohedron as an edge starting at the origin
	for ind = 1:NumOfGens
		XYZs = [0 0 0; GeneratingVectorsInCyclicOrder(ind,:)]	;
		Xs = transpose(XYZs(:,1))	;
		Ys = transpose(XYZs(:,2))	;
		Zs = transpose(XYZs(:,3))	;
		plot3(Xs,Ys,Zs,'r-')
		hold on
	end
end

% The zonohedron figure will be created by drawing its parallelogram faces in three-
% dimensional space.  For more realism, and to avoid many overlapping lines, we will
% distinguish between faces which can be seen from a certain direction, and faces which
% cannot be seen, because they are on the other side of the zonohedron.  Calculating
% which faces are which involves calculating each face s outward normal, which uses
% the center of the zonohedron.
CenterOfZonohedron = [sum(GeneratingVectorsInCyclicOrder(:,1)), ...
					  sum(GeneratingVectorsInCyclicOrder(:,2)), ...
					  sum(GeneratingVectorsInCyclicOrder(:,3))]/2	;
% Choose a direction from which to view the zonohedron.					  
AzDeg      = 240	;	%135;
ElDeg      = 40		;	%45	;
ViewCoords = [AzDeg, ElDeg]	;
ViewVector = -[cosd(AzDeg-90), sind(AzDeg-90), tand(ElDeg)]	;

% Go through the zonohedron s faces one by one, determining whether or not they are
% visible.  If a face is visible, draw it in black; otherwise draw it in grey, or don t
% draw it at all.
for ind = 1:length(ListOfFaces)
	% Each entry in ListOfFaces is a four-element vector.  Each element of the vector
	% gives the index of a vertex, and the four vertices are the corners of the 
	% parallelogram face.
	VectorOfIndices = ListOfFaces{ind}			;
	XYZs = []	;
	for ctr = 1:4
		XYZs = [XYZs; Vertices(VectorOfIndices(ctr),:)]	;
	end
	% Connect fourth vertex of parallelogram back to first vertex
	XYZs = [XYZs; Vertices(VectorOfIndices(1),:)]	;
	
	% Calculate an outward normal vector to the face.  Use the line connecting the
	% center of the zonohedron to the face to determine which direction is outward
	NormalDirection    = cross(XYZs(2,:)-XYZs(1,:), XYZs(3,:)-XYZs(2,:))	;
	DirectionIndicator = dot(XYZs(1,:)-CenterOfZonohedron,NormalDirection)	;
	if DirectionIndicator < 0
		OutwardNormal = NormalDirection	;
	else
		OutwardNormal = -NormalDirection	;
	end
	
	% Plot the face as four vertices that define a boundary.  If desired, choose
	% different colours and markings for visible and hidden faces.
	Xs = transpose(XYZs(:,1))	;
	Ys = transpose(XYZs(:,2))	;
	Zs = transpose(XYZs(:,3))	;
	if dot(ViewVector,OutwardNormal) > 0	% The face is visible from the chosen direction
		plot3(Xs,Ys,Zs,'k-')
		hold on
	else		% The face is hidden from the chosen direction
		plot3(Xs,Ys,Zs,'-','color',0.7*[1 1 1])
		hold on
	end
end

set(gca, 'view', ViewCoords);
axis('equal');
% If desired, choose limits, tick locations, labels, etc.
%set(gca, 'xlim', [-2 2], 'ylim', [-3 3], 'zlim', [0 6]);
%set(gca, 'xlim', [0 1.5], 'ylim', [0 1.5], 'zlim', [0 1.5]);
%set(gca, 'xtick',[0.5:0.5:1],'ytick',[0.5:0.5:1],'ztick',[0.5:0.5:1]);
%set(gca, 'xticklabel',[],'yticklabel',[],'zticklabel',[]);
% Make the zonohedron figure visible or invisible, as desired
set(gcf,'Visible','on')