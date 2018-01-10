function [Vertices, Faces, BoundingReflectanceSpectra] = ...
								 DrawMetamerMismatchBody(...
								 ResponseFunctions1, ...
								 ResponseFunctions2, ...
								 Illuminant1, ...
								 Illuminant2, ...
								 z)	;
%
% Purpose		Draw the metamer mismatch body for a colour z when there are two sensing devices 
%				(possibly with two different sets of response functions), making an image 
%				under two different illuminants.
%
% Description	Suppose that a sensing device makes an image of a physical object under some
%				illuminant called Illuminant1.  Then a pixel corresponding to that object
%				has some coordinate vector z, assumed to be three-dimensional, in that
%				device s colour space.  The coordinates of z depend on the three response
%				functions for the device, given by the variable ResponseFunctions1.  For
%				cameras, z is usually an RGB triple, while for the human visual system,
%				z is typically a CIE XYZ tristimulus vector.
%
%				Somebody who is analyzing the image knows the output coordinates z, the
%				response functions for the first device, and the illuminant; the 
%				reflectance spectrum of the imaged object is unknown.
%				Now suppose that another sensing device (or perhaps the same device) images
%				the object under some different illumination, given by the variable
%				Illuminant2, and produces a new set of coordinates, z2, in the second
%				device s colour space.  Then z2 could take on a variety of values, all of
%				which are consistent with z, in the sense that there is a theoretical
%				reflectance spectrum that would produce z when imaged with the first
%				device under the first illuminant, and z2 when imaged with the second
%				device under the second illuminant.  The set of all possible z2 s in
%				the colour space of the second device is called the metamer mismatch
%				body associated with z.
%
%				This routine calculates a metamer mismatch body.  It implements the
%				algorithm in [Centore2016], which should be consulted for details.
%
%				ResponseFunctions1 (or 2) 	A matrix of 3 rows and 31 columns.  The 31 columns
%						each refer to one of the 31 wavelengths between 400 and 700 nm, at intervals
%						of 10 nm.  Each row gives the relative responses for one receptor
%						in a sensing device that contains three receptors.  For human vision,
%						the responses are given by the CIE colour-matching functions (usually
%						denoted x-bar, y-bar, and z-bar)
%
%				Illuminant1 (or 2)	A vector with 31 entries.  Each entry gives the relative
%						power of an illuminant at one of the 31 wavelengths between 400 and 700 nm.
%						The sensing device with ResponseFunctions1 is assumed to produce an 
%						image of an object under Illuminant1.  A similar statement holds for
%						ResponseFunctions2 and Illuminant2
%
%				z		A colour signal in the device colour space of Device 1
%
%				Vertices	A three-column output matrix, each row of which gives a vertex
%						of the metamer mismatch body in the colour space of the first
%						device
%
%				Faces	A three-column output matrix, each row of which gives a triangular
%						face of the metamer mismatch body.  Each entry in Faces is the
%						index of a row in Vertices
%
%				BoundingReflectanceSpectra	A 31-column output matrix, with the same
%						number of rows as the matrix Vertices.  Each row gives a 
%						reflectance spectrum that, when imaged by the second device,
%						produces the vertex in the corresponding row of Vertices
%
% 				[Centore2016] Paul Centore, "A Simple Algorithm for Metamer Mismatch Bodies,"
%						2016. 
%
% Author		Paul Centore (November 29, 2016)
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

% Initialize variables
Vertices                   = []	;
Faces                      = []	;
BoundingReflectanceSpectra = []	;

% Draw a picture of the metamer mismatch body, if desired
DisplayFigure = true	;

% Check that both response functions have 3 by 31 entries
if not((size(ResponseFunctions1,1) == 3 && size(ResponseFunctions1,2) == 31) || ...
	   (size(ResponseFunctions1,1) == 3 && size(ResponseFunctions1,2) == 31))
	return	   
elseif not((size(ResponseFunctions2,1) == 3 && size(ResponseFunctions2,2) == 31) || ...
	   (size(ResponseFunctions2,1) == 3 && size(ResponseFunctions2,2) == 31))
	return	   
end
% Flip response function matrices if necessary to insure they have 3 rows and 31 columns
if size(ResponseFunctions1,1) == 31 
	AdjResponseFunctions1 = transpose(ResponseFunctions1)	;
else	
	AdjResponseFunctions1 = ResponseFunctions1				;
end	
if size(ResponseFunctions2,1) == 31 
	AdjResponseFunctions2 = transpose(ResponseFunctions2)	;
else	
	AdjResponseFunctions2 = ResponseFunctions2				;
end	
	
% Check that both illuminants have 31 entries
if length(Illuminant1) ~= 31
	return
elseif length(Illuminant2) ~= 31
	return
end	
% Reshape the illuminants into row vectors, if needed
AdjIlluminant1 = reshape(Illuminant1,1,31)	;
AdjIlluminant2 = reshape(Illuminant2,1,31)	;
	
% Check that z has three entries, and make it vertical, if needed
if length(z) ~= 3
	return
else
	zvert = reshape(z,3,1)	;
end	

% Input checking ends here, and the algorithm proper begins.

% Construct the transformations Phi and Psi.  Phi is the linear transformation from the
% 31-dimensional space of reflectance spectra to the 3-dimensional colour space of the
% first sensing device; it results from applying the illuminant to an object s
% reflectance spectrum, and then using that stimulus to make an image.  Psi is the
% corresponding transformation for the second sensing device.
Phi = AdjResponseFunctions1 .* AdjIlluminant1	;
Psi = AdjResponseFunctions2 .* AdjIlluminant2	;

% The metamer mismatch body (MMB) is the set
%
%		M(z,Psi,Phi) = Psi(Phi^(-1)(z) intersect {set of reflectance spectra}).
%
% [Centore2016] describes an algorithm to find a vertex (or at least a boundary point) of 
% M, which is a convex set, in a given direction.  In addition, a reflectance spectrum
% that corresponds to that boundary point can be found.  
%
% Loop over a set of directions, finding two vertices in each direction (one in which 
% a linear functional in that direction is minimized, and another in which it is 
% maximized).  The directions are formed using spherical coordinates, with an azimuthal
% angle theta and an elevation angle phi.  The values of theta and phi are taken to be
% evenly spaced, and to be the same size for either angle.  The variable FinenessIndex
% controls how many directions are chosen; as FinenessIndex increases, so does the
% number of directions.  The directions are spaced so that the azimuth or elevation angle
% between adjacent directions is 45/(2^FinenessIndex) degrees.  When FinenessIndex is 5,
% the spacing is just under 1.5 degrees, and usually gives a few hundred vertices, which 
% should be adequately detailed but not excessively so.  
FinenessIndex = 5															;
thetas        = ([0:(8*FinenessIndex+7)]./(8*(FinenessIndex+1))) * 360		;	
phis          = ([0:(2^(FinenessIndex+1))] ./ (2^(FinenessIndex+1))) * 90	;	
for theta = thetas
	for phi = phis
		% Each theta-phi pair defines a direction in which two vertices are found.
		% Find the coordinates of a vector, or direction, for that pair of angles
		alpha_1 = cosd(theta) * sind(phi)	;
		alpha_2 = sind(theta) * sind(phi)	;
		alpha_3 = cosd(phi)					;

		% Use the vector coordinates as the coordinates of a functional.  If one
		% imposed a Euclidean metric on the 3-dimensional device colour space, then
		% the level curves of this functional would be a space-filling stack of
		% planes that are normal to the direction vector.  M is bounded between two
		% of those planes; the value of F over M is minimized by one bounding plane
		% and maximized by the other.  In the generic case, each plane intersects M
		% in exactly one vertex.  Linear programming (LP) is used to find those two 
		% vertices.  If a bounding plane intersects M in an edge or face, then the
		% LP algorithm will find some vertex of M in that edge or face, but not the
		% others.  Regardless of the kind of intersection, some boundary point will be found.			
		F = [alpha_1, alpha_2, alpha_3]		;
		% F is a linear functional on M, which can be pulled back by Psi to (Phi^(-1)
		% (z) intersect {reflectance spectra}), by writing
		%			(Psi^*F)(x) = F(Psi(x)) = F(z), where z = F(x).
		% Find a coordinate expression for Psi^*F:
		PsiStarF = sum(Psi .* transpose(F))	;
		% [Centore2016] shows that maximizing (or minimizing) F on M is equivalent to
		% maximizing (or minimizing) Psi^*F on (Phi^(-1)(z) intersect {spectra}).  The
		% latter problem can be cast as a linear programming problem (see [Centore2016]
		% for details).  Use the LP solver glpk.m to find a reflectance spectrum x
		% that produces a vertex of M that minimizes F.  Then find the resulting 
		% vertex, and store both the vertex and the spectrum in running lists:  
		x        = glpk(PsiStarF,Phi,zvert,zeros(31,1),ones(31,1))	;
		Vertex   = Psi * x											;
		Vertices = [Vertices; reshape(Vertex,1,3)]					;
		BoundingReflectanceSpectra = [BoundingReflectanceSpectra; ...
									  reshape(x,1,31)]				;
									  
		% Do the same to find a vertex of M that maximizes F:	
		x        = glpk(-PsiStarF,Phi,zvert,zeros(31,1),ones(31,1))	;	
		Vertex   = Psi * x											;
		Vertices = [Vertices; reshape(Vertex,1,3)]					;
		BoundingReflectanceSpectra = [BoundingReflectanceSpectra; ...
									  reshape(x,1,31)]				;
	end
end

% The previous loop has produced a three-column matrix Vertices, each row of which is a
% vertex of M in the colour space of the second device.  Possibly some of the vertices
% are repeated, because one vertex can be a maximizing (or minimizing) vertex in multiple
% directions simultaneously.  Also, some repeated vertices might appear whose differences
% are decimal dust, because of the numerical computations.  To avoid both these situations,
% use convhulln.m to find the convex hull of the vertices.  This routine returns a
% three-column matrix Faces of bounding triangular faces.  Each row of Faces gives one
% triangle.  Each entry in Faces is an index to a row in Vertices, and each row of
% Vertices gives one vertex.
Faces = convhulln(Vertices)	;

% As mentioned previously, likely some vertices are redundant.  Find the indices of just
% those vertices that are needed for the convex hull, by making a long list of all the
% entries in Faces, and selecting a unique set of entries.
ListOfVertexIndices = [Faces(:,1); Faces(:,2); Faces(:,3)]	;
ReducedIndices      = unique(ListOfVertexIndices)			;
% Extract just those vertices from the total list, along with a reflectance spectrum that
% produces each vertex.
Vertices                   = Vertices(ReducedIndices,:)						;
BoundingReflectanceSpectra = BoundingReflectanceSpectra(ReducedIndices,:)	;
% Eliminating redundant vertices leads to a comnplicated re-indexing; a simple method of
% avoiding the re-indexing is just to recalculate the convex hull with the reduced set
% of vertices.
Faces = convhulln(Vertices)	;

% Draw a figure of the metamer mismatch body if desired
if DisplayFigure
	figure
	for ctr = 1:size(Faces,1)
		Indices = Faces(ctr,:)	;
		xcoords = [Vertices(Indices(1),1), ...
				   Vertices(Indices(2),1), ...
				   Vertices(Indices(3),1), ...
				   Vertices(Indices(1),1)]	;
		ycoords = [Vertices(Indices(1),2), ...
				   Vertices(Indices(2),2), ...
				   Vertices(Indices(3),2), ...
				   Vertices(Indices(1),2)]	;
		zcoords = [Vertices(Indices(1),3), ...
				   Vertices(Indices(2),3), ...
				   Vertices(Indices(3),3), ...
				   Vertices(Indices(1),3)]	;
		plot3(xcoords, ycoords, zcoords, 'k-')
		hold on
	end
	set(gca,'dataaspectratio',[1 1 1])
	set(gcf,'Name','Metamer Mismatch Body')
set(gca,'view',[60 30])
set(gca,'xlabel','X','ylabel','Y','zlabel','Z')
figname = 'MetamerMismatchBodyFigure'	;	
print(gcf, [figname,'.eps'], '-depsc')	;
print(gcf, [figname,'.png'], '-dpng')	;
print(gcf, [figname,'.jpg'], '-djpg')	;
print(gcf, [figname,'.pdf'], '-dpdf')	;
end