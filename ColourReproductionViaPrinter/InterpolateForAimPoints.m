function [InterpolatedRGB, RGBvertices, xyzvertices, AllBaryCoords, tessellation] = ...
		  InterpolateForAimPoints(RGB, xyY, AimPoints, tessellation);
% Purpose		This routine interpolates over a tetrahedral tessellation, that has been transferred
%				from an RGB domain, to a codomain in CIE (or other) coordinates.
%
% Description	This routine was intended as part of an algorithm that identifies RGB triples that,
%				when printed (and viewed under a known illuminant), have a desired set of CIE
%				coordinates.  The input data consist of a set of RGB triples, their corresponding
%				CIE coordinates when printed, and a set of CIE aimpoints, for which RGB triples are
%				desired.  The routine first calculates a tetrahedral tessellation of the RGB
%				triples.  (The write-up "How to Print a Munsell Book" describes why the RGB data
%				should be tessellated, rather than the CIE coordinates.)  The tessellation is a
%				four-column matrix that lists four vertices for each tetrahedron; a vertex is an
%				RGB triple.  The RGB vertices are automatically indexed, in the order in which
%				they are input.  The RGB tessellation can be formally transferred to a CIE tessellation.  As long as
%				the RGB-CIE mapping is fairly regular, the new tessellation will in fact be valid, in
%				that it will contain no overlapping tetrahedra.  
%
%				A given CIE aimpoint is localized by identifying which tetrahedron of the tessellation
%				it belongs to, and where in that tetrahedron it is.  The location within a tetrahedron is
%				expressed in barycentric coordinates, while the tetrahedron itself is given by an
%				index.  The index and barycentric coordinates can apply equally well to RGB or CIE
%				coordinates, so an interpolated RGB value can be calculated.  When printed, this RGB
%				should be closer to the desired CIE coordinates than any of the input RGBs.
%
%				It is possible that the CIE aimpoint is outside the gamut of the input CIE points.  In
%				that case, flag values of -99 are used for many of the returned variables.
%
% Syntax		InterpolateForAimPoints(RGB, xyY, AimPoints);
%
%				RGB					A three-column matrix of RGB triples
%
%				xyY					A three-column matrix of CIE coordinates, which correspond to the
%									RGB triples.  The CIE coordinates are written here as "xyY," but could
%									be any kind of CIE coordinates, such as XYZ or Lab.
%
%				AimPoints			A three-column matrix of aimpoints, in the same CIE coordinates as xyY
%
%				InterpolatedRGB		A three-column matrix, the same size as AimPoints, that contains an RGB
%									triple for the corresponding CIE aimpoint
%
%				RGBvertices			A structure of matrices.  Each matrix lists the four RGB triples that
%									make up the vertices of the tetrahedron that contains an aimpoint
%									interpolation
%
%				xyzvertices			A similar structure to RGB vertices, but in CIE space
%
%				AllBaryCoords		A structure with the barycentric coordinates of the interpolated aimpoints
%
%				tessellation		A four-column matrix giving a tetrahedral Delaunay tessellation of
%									the input RGB data.  This variable can be input if desired; if not input,
%									it will be calculated and returned
%
% Author		Paul Centore (June 15, 2012)
% Revision		Paul Centore (November 3, 2015)
%				---Made 'tessellation' into an optional input, to avoid recalculating.
%
% Copyright 2012-2015 Paul Centore
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

% The input RGB values are a discrete set of points in three-dimensional 
% space.  Tesselate their convex hull.
if ~exist('tessellation')
	tessellation = delaunayn(RGB)	;
end

% Initialize variables
InterpolatedRGB = [];
vertices        = {};	% List of vertices for each aimpoint.  Each 
						% element of the list is a matrix of 4 rows, and each row is the RGB
						% coordinates of one vertex of the enclosing tetrahedron.
AllBaryCoords   = [];	% Each row of this matrix is the barycentric coordinates of an aimpoint,
						% with respect to the vertices in the matrix called 'vertices.'

% Loop over every aimpoint, finding the RGBs that are most likely to produce it
[NumberOfAimPoints, ~] = size(AimPoints)	;
PointsInGamut = 0							;	% Count aimpoints inside convex hull of xyY data
TetraIndices    = -99 * ones(NumberOfAimPoints)		;	% List which tetrahedra in tessellation
														% contain aimpoints
tic()
for ctr = 1:NumberOfAimPoints

% This routine can take a long time to execute.  To monitor its progress, set
% the condition in the following if statement to true
DisplayProgress = true			;
if mod(ctr,1) == 0 && DisplayProgress
   ElapsedTime = toc()			;
   RemainingMinutes = (ElapsedTime/ctr) * (NumberOfAimPoints-ctr+1)/60	;
   disp([num2str(ElapsedTime), ' sec; ',num2str(ctr),' out of ', num2str(NumberOfAimPoints),...
         '; minutes remaining: ', num2str(RemainingMinutes)])	;
   fflush(stdout)	;											;
end

	% Find which CIE tetrahedron contains a given aimpoint, and what its barycentric
	% coordinates are in that tetratedron.  The variable "tessellation" was originally 
	% calculated for the RGB data.  It is now applied to the CIE data
    [idx, BaryCoords] = tsearchn(xyY, tessellation, AimPoints(ctr,:))			;
	
	% Check whether the aimpoint is outside the gamut of the CIE inputs.  If it is,
	% then flag all values as -99
	if isnan(idx)
	    InterpolatedRGB(ctr,:) = [-99 -99 -99]									;
		RGBvertices{ctr}       = -99 * ones(4,3)								;
		xyzvertices{ctr}       = -99 * ones(4,3)								;
		AllBaryCoords(ctr,:)   = [-99 -99 -99 -99]								;
	% If the aimpoint is within the gamut of the CIE inputs, then interpolate in both
	% CIE and RGB data
	else
	    InterpolatedRGB(ctr,:) = BaryCoords(1) * RGB(tessellation(idx,1),:) + ...
		                         BaryCoords(2) * RGB(tessellation(idx,2),:) + ...
								 BaryCoords(3) * RGB(tessellation(idx,3),:) + ...
								 BaryCoords(4) * RGB(tessellation(idx,4),:)		;
        RGBvertices{ctr}       = [RGB(tessellation(idx,1),:);...	
								  RGB(tessellation(idx,2),:);...
								  RGB(tessellation(idx,3),:);...
								  RGB(tessellation(idx,4),:)]					;
        xyzvertices{ctr}       = [xyY(tessellation(idx,1),:);...	
								  xyY(tessellation(idx,2),:);...
								  xyY(tessellation(idx,3),:);...
								  xyY(tessellation(idx,4),:)]					;
		AllBaryCoords(ctr,:)   = [BaryCoords(1) BaryCoords(2) BaryCoords(3) BaryCoords(4)]	;	
%		TetraIndices(ctr)      = idx											;
     
	    % This gamut check is probably not necessary, but is performed just to be sure
		if max(InterpolatedRGB(ctr,:)) > 1 || min(InterpolatedRGB(ctr,:)) < 0
		    InterpolatedRGB(ctr,:) = [-99 -99 -99]								;
		    RGBvertices{ctr}       = -99 * ones(4,3)							;
		    xyzvertices{ctr}       = -99 * ones(4,3)							;
		    AllBaryCoords(ctr,:)   = [-99 -99 -99 -99]							;
		else
		    PointsInGamut = PointsInGamut + 1									;
		end
	end
end