function [Counts, SortedEdgeVerticesAndLengths] = ...
          DisplayEdgeLengthsOfTessellation(tessellation, XYZ, Name, iteration );
% Purpose		Produce a histogram of the edge lengths of a tessellation 
%				of CIE XYZ space, where the lengths are given by CIE DE 2000 values
%
%				tessellation	A 4-column matrix.  Each row of this matrix gives the
%								indices of the four vertices of a tetrahedron in a
%								tessellation.  The index refers to a row in the matrix XYZ.
%
%				XYZ				A 3-column matrix.  Each row is a set of CIE XYZ coordinates.
%
%				Name			A string to use when saving the histogram
%								
%				iteration		An index to use when saving the histogram
%				
%				SortedEdgeVerticesAndLengths	A 3-column matrix.  Each row corresponds
%								to one edge in the tessellation.  The first two entries 
%								are the indices of the vertices that that edge joins in 
%								the tessellation.  The third entry is the DE of that edge.
%								The edges are sorted from lowest DE to highest.
%
% Author		Paul Centore (December 26, 2012)
% Revised		Paul Centore (January 1, 2014)
%				---Calculated white point for Illuminant C and 2 deg observer, and passed to revised
%				   routine for calculating CIE DE 2000
% Revised		Paul Centore (January 21, 2014)
%				---Ranked edges of tessellation by DE, and passed to calling routine
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

% EdgeMatrix is a 2-column matrix, where each row contains the indices of
% the vertices to one edge in the tessellation
TmpMatrix  = [tessellation(:,[1,2]);...
              tessellation(:,[1,3]);...
              tessellation(:,[1,4]);...  
			  tessellation(:,[2,3]);...
			  tessellation(:,[2,4]);...
			  tessellation(:,[3,4])];
TmpMatrixTranspose = transpose(TmpMatrix)		; 
% Sort edges so lower vertex is first
FirstColumn = min(TmpMatrixTranspose)			;
SecndColumn = max(TmpMatrixTranspose)			;
EdgeMatrix  = [FirstColumn', SecndColumn']		;

% Eliminate redundancies from matrix of edges
EdgeMatrix = unique(EdgeMatrix, 'rows')		;

WhitePointXYZ = WhitePointWithYEqualTo100('C/2')	;	% Line added Jan. 1, 2014, to calculate white point

% Calculate edge lengths for all edges in EdgeMatrix
EdgeLengths = []	;		% Initialize list of edge lengths
[NumOfUniqueEdges,~] = size(EdgeMatrix)		;
for idx = 1:NumOfUniqueEdges
    % The number of edges has occasionally the tens of thousands, making the edge
    % calculation very slow.  If desired, set a flag to monitor the calculation progress.
    ShowProgress = false	;
    if ShowProgress && mod(idx,5000) == 0
        disp(['idx is ', num2str(idx),' of ', num2str(NumOfUniqueEdges)]);
    	fflush(stdout);
    end

    % Find XYZ coordinates of two vertices for that edge
	XYZ1 = XYZ(EdgeMatrix(idx,1),:)			;
	XYZ2 = XYZ(EdgeMatrix(idx,2),:)			;
	
	% Find the edge length, with respect to the CIEDE2000 function
	% The following line was modified on December 14, 2013
	DE2000 = CIEDE2000ForXYZ(XYZ1, XYZ2, WhitePointXYZ)	;
	EdgeLengths = [EdgeLengths, DE2000]		;
end

% Added Jan. 21, 2014, by Paul Centore---Start
% The matrix EdgeVerticesAndLengths has three columns.  The first two entries of each
% row are the vertex indices for one (unique) edge, and the third entry is the DE for
% that edge.
EdgeVerticesAndLengths = [EdgeMatrix, transpose(EdgeLengths)] 			;
% Sort the edges from smallest to largest
SortedEdgeVerticesAndLengths = sortrows(EdgeVerticesAndLengths, 3) 		;
% Added Jan. 21, 2014, by Paul Centore---End

% Calculate data for histogram of edgelengths
MaxEdgeLength = 50							;
EdgeVector = [0:1:MaxEdgeLength]			;
Counts = histc(EdgeLengths, EdgeVector)		;

% Produce and format histogram
figure
HistogramData = [EdgeVector; Counts]		;
AverageEdgeLength = mean(EdgeLengths)		;
disp(['Iteration ',num2str(iteration), ': ',num2str(length(EdgeLengths)), ...
      ' edges in tessellation']);
disp(['Average length of edge in tessellation: ',num2str(AverageEdgeLength),' (DE2000)']);
stairs(EdgeVector, Counts)					;
set(gca, 'xlim', [0,MaxEdgeLength])			;
set(gcf, 'Name', ['Histogram of DEs of edge lengths for Iteration ',num2str(iteration)]) ;
fflush(stdout)								;

% Save figures in files of multiple formats
figname = [Name,'HistEdgeLengthsIteration',num2str(iteration)]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');