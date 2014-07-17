
function NewVertices = NewLabVerticesInTessellation(RGBverts, Labverts, LabtargetIn, LabestIn);
% Purpose		Find new vertices for a finer tessellation.  Choose the vertices adaptively, 
%				so that they enclose the aimpoint in a small tetrahedron.
%
% Description	This routine was intended as part of an algorithm that identifies RGB triples that,
%				when printed (and viewed under a known illuminant), have a desired set of CIE
%				coordinates.  The CIE target is the variable LabtargetIn, denoted in Lab coordinates.
%				The current best attempt at matching LabtargetIn has achieved the CIE coordinates
%				given in the variable LabestIn.  Furthermore, the target is contained within a
%				tetrahedron whose vertices (in Lab coordinates) are given by Labverts.  The
%				variable RGBverts gives RGB triples that are known to produce the CIE coordinates
%				given in Labverts.  
%
%				The goal of this routine is to find a new containing tetrahedron, that is finer
%				than the current containing tetrahedron.  Using barycentric coordinates, the tetrahedron
%				can exist equally well in RGB and Lab space (because RGBverts corresponds to
%				Labverts).  Some details of the new tetrahedron are described in the write-up "How
%				to Print a Munsell Book."  The parameters for generating the new tetrahedron depend on
%				the measurement error characteristics of the spectrophotometer used, so they can be
%				adjusted as needed.
%
% Syntax		NewVertices = NewVerticesInTessellation(RGBverts, Labverts, Labtarget, RGBest, Labest);
%
%				RGBverts		The vertices, in RGB space, of a tetrahedron that is believed to contain
%								an RGB that will produce LabtargetIn, when printed
%
%				Labverts		The corresponding vertices, in Lab space, of RGBverts
%
%				LabtargetIn		The aimpoint in CIE Lab coordinates
%
%				LabestIn		The Lab coordinates of the current estimate of the pre-image of
%								LabtargetIn.  This point has barycentric coordinates with respect to
%								Labverts.  The current best estimate of the RGB pre-image of LabtargetIn
%								is the RGB point with the same barycentric coordinates, with respect
%								to RGBverts
%
%				NewVertices		The vertices of the finer containing tetrahedron.
%
% Related		
% Functions
%
% Required		
% Functions
%
% Author		Paul Centore (August 22, 2012)
%
% Revision		Paul Centore (July 15, 2013)
%				---Corrected a bug in which the returned vertices were not checked for entries
%				   less than 0 or greater than 1
%
% Copyright 2012 Paul Centore
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

% Use flag to display figures for testing and diagnosis, if desired
DisplayFigures = false	;
ViewAngle = [210, 20]	;	% Use one viewing angle in all figures, for consistency
coms = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4]			;	% Use for figures

% Make Lab target vector vertical if needed
Labtarget(1,1) = LabtargetIn(1)	;
Labtarget(2,1) = LabtargetIn(2)	;
Labtarget(3,1) = LabtargetIn(3)	;

% Make Lab estimated vector vertical if needed
Labest(1,1) = LabestIn(1)	;
Labest(2,1) = LabestIn(2)	;
Labest(3,1) = LabestIn(3)	;

if DisplayFigures == true
figure
set(gcf, 'Name', 'Lab vertices')
for ctr = 1:6
    plot3([Labverts(coms(ctr,1),1), Labverts(coms(ctr,2),1)],...
	      [Labverts(coms(ctr,1),2), Labverts(coms(ctr,2),2)],...
		  [Labverts(coms(ctr,1),3), Labverts(coms(ctr,2),3)],...
		  'k-')		;
	hold on
end
plot3(Labtarget(1), Labtarget(2), Labtarget(3), 'k*')
hold on
plot3(Labest(1), Labest(2), Labest(3), 'r*')
set(gca, 'View', ViewAngle)
end

if DisplayFigures == true
figure
set(gcf, 'Name', 'RGB vertices')
for ctr = 1:6
    plot3([RGBverts(coms(ctr,1),1), RGBverts(coms(ctr,2),1)],...
	      [RGBverts(coms(ctr,1),2), RGBverts(coms(ctr,2),2)],...
		  [RGBverts(coms(ctr,1),3), RGBverts(coms(ctr,2),3)],...
		  'k-')		;
	hold on
end
hold on
LabtargetBary = cart2bary(Labverts, Labtarget')				%'
RGBest = LabtargetBary(1) * RGBverts(1,:) + ...
         LabtargetBary(2) * RGBverts(2,:) + ...
         LabtargetBary(3) * RGBverts(3,:) + ...
         LabtargetBary(4) * RGBverts(4,:)	;
plot3(RGBest(1), RGBest(2), RGBest(3), 'r*')
set(gca, 'View', ViewAngle)
end

% Calculate the error between the Lab target, and the Lab estimate produced by the
% best RGB estimate
LabError = Labest - Labtarget		;

e1 = LabError(1)	;
e2 = LabError(2)	;
e3 = LabError(3)	;

RotationMatrix = [-e1*e3/e2,      1,      e1; ...
				  -e3,            -e1/e2, e2; ...
				  e2+((e1^2)/e2), 0,      e3] ;
			
% Make the rotation matrix orthonormal
for ind = 1:3
   RotationMatrix(:,ind) = RotationMatrix(:,ind)/norm(RotationMatrix(:,ind))	;
end

% Allow random rotation about error axis (the vector joining the target Lab to its
% best estimate), if desired.  
RandomAngleDeg = 0 ; % 360 * rand()		;
AxialRotationMatrix = [ cosd(RandomAngleDeg), sin(RandomAngleDeg), 0; ...
                       -sind(RandomAngleDeg), cos(RandomAngleDeg), 0; ...
					   0,                     0,                   1] ;
					   
% Compose the two matrices to get a randomized rotation matrix, that still sends
% the z-axis (0, 0, 1) onto the error axis (the vector joining the target Lab to its
% best estimate)
ComposedMatrix = RotationMatrix * AxialRotationMatrix	;

% Scale the composed matrix, so that the z-axis (0, 0, 1) starts at the target Lab
% triple, and ends at the image of the best RGB estimate for that triple
FinalMatrix = norm(LabError) * ComposedMatrix		;

% The scaling constant is a paramter that can be tuned to fit the accuracy of
% the spectrophotometric measurements.  The larger the measurement errors, relative
% to the scales of the containing tetrahedron, the larger this constant should be.
ScalingConstant = 2.0				;

% The new, or prototype, tetrahedron contains Labest as one vertex.  The other
% three vertices are on the other side of Labtarget.  Their distance from
% Labtarget, and the amount they are spread out, are tunable parameters, that
% can be adjusted to the measurement error.  The farther the prototype vertices
% are, the more likely they are to contain the target, but the slower convergence
% is.
% The first prototype vertex would be [0;0;1], but this was chosen
% to map to Labest, so its image does not need to be calculated.  It is also in
% the tessellation, so there is no need to add it.
if true
    ProtoVertex2 = ScalingConstant * [1;    0;            -1]	;
    ProtoVertex3 = ScalingConstant * [-1/2; (sqrt(3))/2;  -1]	;
    ProtoVertex4 = ScalingConstant * [-1/2; -(sqrt(3))/2; -1]	;
end
if false
    ProtoVertex2 = ScalingConstant * [1;    0;            -1]	;
    ProtoVertex3 = ScalingConstant * [-1/2; (sqrt(3))/2;  -1]	;
    ProtoVertex4 = ScalingConstant * [-1/2; -(sqrt(3))/2; -1]	;
end

if DisplayFigures == true
figure
set(gcf, 'Name', 'Prototype Tetrahedron')
plot3([ProtoVertex2(1), ProtoVertex3(1)],...
      [ProtoVertex2(2), ProtoVertex3(2)],...
	  [ProtoVertex2(3), ProtoVertex3(3)],...
	  'k-')		;
hold on
plot3([ProtoVertex2(1), ProtoVertex4(1)],...
      [ProtoVertex2(2), ProtoVertex4(2)],...
	  [ProtoVertex2(3), ProtoVertex4(3)],...
	  'k-')		;
hold on
plot3([ProtoVertex3(1), ProtoVertex4(1)],...
      [ProtoVertex3(2), ProtoVertex4(2)],...
	  [ProtoVertex3(3), ProtoVertex4(3)],...
	  'k-')		;
hold on
plot3([0,ProtoVertex2(1)],...
      [0,ProtoVertex2(2)],...
	  [1,ProtoVertex2(3)],...
	  'k-')		;
hold on
plot3([0,ProtoVertex3(1)],...
      [0,ProtoVertex3(2)],...
	  [1,ProtoVertex3(3)],...
	  'k-')		;
hold on
plot3([0,ProtoVertex4(1)],...
      [0,ProtoVertex4(2)],...
	  [1,ProtoVertex4(3)],...
	  'k-')		;
hold on
set(gca, 'View', ViewAngle)	
end

NewLabVert2 = (FinalMatrix * ProtoVertex2) + Labtarget	;
NewLabVert3 = (FinalMatrix * ProtoVertex3) + Labtarget	;
NewLabVert4 = (FinalMatrix * ProtoVertex4) + Labtarget	;

if DisplayFigures == true
figure
set(gcf, 'Name', 'New Tetrahedral Points')
for ctr = 1:6
    plot3([Labverts(coms(ctr,1),1), Labverts(coms(ctr,2),1)],...
	      [Labverts(coms(ctr,1),2), Labverts(coms(ctr,2),2)],...
		  [Labverts(coms(ctr,1),3), Labverts(coms(ctr,2),3)],...
		  'k-')		;
	hold on
end
plot3([NewLabVert2(1), NewLabVert3(1)],...
      [NewLabVert2(2), NewLabVert3(2)],...
	  [NewLabVert2(3), NewLabVert3(3)],...
	  'k-')		;
hold on
plot3([NewLabVert2(1), NewLabVert4(1)],...
      [NewLabVert2(2), NewLabVert4(2)],...
	  [NewLabVert2(3), NewLabVert4(3)],...
	  'k-')		;
hold on
plot3([NewLabVert3(1), NewLabVert4(1)],...
      [NewLabVert3(2), NewLabVert4(2)],...
	  [NewLabVert3(3), NewLabVert4(3)],...
	  'k-')		;
hold on
plot3([Labest(1), NewLabVert2(1)],...
      [Labest(2), NewLabVert2(2)],...
	  [Labest(3), NewLabVert2(3)],...
	  'k-')		;
hold on
plot3([Labest(1), NewLabVert3(1)],...
      [Labest(2), NewLabVert3(2)],...
	  [Labest(3), NewLabVert3(3)],...
	  'k-')		;
hold on
plot3([Labest(1), NewLabVert4(1)],...
      [Labest(2), NewLabVert4(2)],...
	  [Labest(3), NewLabVert4(3)],...
	  'k-')		;
hold on
plot3(Labtarget(1), Labtarget(2), Labtarget(3), 'k*')
hold on
plot3(Labest(1), Labest(2), Labest(3), 'r*')
set(gca, 'View', ViewAngle)
end

% Write three new vertices in barycentric coordinates
NewLabVert2Bary = cart2bary(Labverts, NewLabVert2')	;		%'
NewLabVert3Bary = cart2bary(Labverts, NewLabVert3')	;		%'
NewLabVert4Bary = cart2bary(Labverts, NewLabVert4')	;		%'

% Convert barycentric coordinates into RGB coordinates
NewRGBVert2 = NewLabVert2Bary(1) * RGBverts(1,:) + ...
              NewLabVert2Bary(2) * RGBverts(2,:) + ...
              NewLabVert2Bary(3) * RGBverts(3,:) + ...
              NewLabVert2Bary(4) * RGBverts(4,:)	;
NewRGBVert3 = NewLabVert3Bary(1) * RGBverts(1,:) + ...
              NewLabVert3Bary(2) * RGBverts(2,:) + ...
              NewLabVert3Bary(3) * RGBverts(3,:) + ...
              NewLabVert3Bary(4) * RGBverts(4,:)	;
NewRGBVert4 = NewLabVert4Bary(1) * RGBverts(1,:) + ...
              NewLabVert4Bary(2) * RGBverts(2,:) + ...
              NewLabVert4Bary(3) * RGBverts(3,:) + ...
              NewLabVert4Bary(4) * RGBverts(4,:)	;
			  
NewVertices = [NewRGBVert2; NewRGBVert3; NewRGBVert4]		;

if DisplayFigures == true
coms = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4]			;
figure
set(gcf, 'Name', 'Old and New RGB vertices')
for ctr = 1:6
    plot3([RGBverts(coms(ctr,1),1), RGBverts(coms(ctr,2),1)],...
	      [RGBverts(coms(ctr,1),2), RGBverts(coms(ctr,2),2)],...
		  [RGBverts(coms(ctr,1),3), RGBverts(coms(ctr,2),3)],...
		  'k-')		;
	hold on
end
plot3([NewRGBVert2(1), NewRGBVert3(1)],...
      [NewRGBVert2(2), NewRGBVert3(2)],...
	  [NewRGBVert2(3), NewRGBVert3(3)],...
	  'k-')		;
hold on
plot3([NewRGBVert2(1), NewRGBVert4(1)],...
      [NewRGBVert2(2), NewRGBVert4(2)],...
	  [NewRGBVert2(3), NewRGBVert4(3)],...
	  'k-')		;
hold on
plot3([NewRGBVert3(1), NewRGBVert4(1)],...
      [NewRGBVert3(2), NewRGBVert4(2)],...
	  [NewRGBVert3(3), NewRGBVert4(3)],...
	  'k-')		;
hold on
LabtargetBary = cart2bary(Labverts, Labtarget')				%'
RGBest = LabtargetBary(1) * RGBverts(1,:) + ...
         LabtargetBary(2) * RGBverts(2,:) + ...
         LabtargetBary(3) * RGBverts(3,:) + ...
         LabtargetBary(4) * RGBverts(4,:)	;
plot3([RGBest(1), NewRGBVert2(1)],...
      [RGBest(2), NewRGBVert2(2)],...
	  [RGBest(3), NewRGBVert2(3)],...
	  'k-')		;
hold on
plot3([RGBest(1), NewRGBVert3(1)],...
      [RGBest(2), NewRGBVert3(2)],...
	  [RGBest(3), NewRGBVert3(3)],...
	  'k-')		;
hold on
plot3([RGBest(1), NewRGBVert4(1)],...
      [RGBest(2), NewRGBVert4(2)],...
	  [RGBest(3), NewRGBVert4(3)],...
	  'k-')		;
hold on
plot3([NewVertices(1,1), NewVertices(3,1)],...
      [NewVertices(1,2), NewVertices(3,2)],...
	  [NewVertices(1,3), NewVertices(3,3)],...
	  'g-')		;
hold on
plot3([NewVertices(1,1), NewVertices(2,1)],...
      [NewVertices(1,2), NewVertices(2,2)],...
	  [NewVertices(1,3), NewVertices(2,3)],...
	  'g-')		;
hold on
plot3([NewVertices(3,1), NewVertices(2,1)],...
      [NewVertices(3,2), NewVertices(2,2)],...
	  [NewVertices(3,3), NewVertices(2,3)],...
	  'g-')		;
hold on
plot3([RGBest(1), NewVertices(1,1)],...
      [RGBest(2), NewVertices(1,2)],...
	  [RGBest(3), NewVertices(1,3)],...
	  'g-')		;
hold on
plot3([RGBest(1), NewVertices(3,1)],...
      [RGBest(2), NewVertices(3,2)],...
	  [RGBest(3), NewVertices(3,3)],...
	  'g-')		;
hold on
plot3([RGBest(1), NewVertices(2,1)],...
      [RGBest(2), NewVertices(2,2)],...
	  [RGBest(3), NewVertices(2,3)],...
	  'g-')		;
hold on
plot3(RGBest(1), RGBest(2), RGBest(3), 'r*')
set(gca, 'View', ViewAngle)
end


% Try revised method
if false

% Calculate the error between the Lab target, and the Lab estimate produced by the
% best RGB estimate
LabError = Labest - Labtarget		;

% Convert all terms to barycentric RGB coordinates
LabtargetBary = cart2bary(Labverts, transpose(Labtarget))	;
RGBtarget     = LabtargetBary(1) * RGBverts(1,:) + ...
                LabtargetBary(2) * RGBverts(2,:) + ...
                LabtargetBary(3) * RGBverts(3,:) + ...
                LabtargetBary(4) * RGBverts(4,:)			;

LabesttBary   = cart2bary(Labverts, transpose(Labest))		;
RGBest        = LabesttBary(1) * RGBverts(1,:) + ...
                LabesttBary(2) * RGBverts(2,:) + ...
                LabesttBary(3) * RGBverts(3,:) + ...
                LabesttBary(4) * RGBverts(4,:)				;
				
RGBerror = RGBest - RGBtarget		;

NewVertices = [NewRGBVert2 - RGBerror; ...
               NewRGBVert3 - RGBerror; ...
			   NewRGBVert4 - RGBerror]		;
end

% Some new vertices might be beyond the RGB gamut.  If so, move
% them to a nearby point on the border of the RGB gamut.
idx = find(NewVertices < 0)		;
NewVertices(idx) = 0			;
idx = find(NewVertices > 1)		;
NewVertices(idx) = 1			;