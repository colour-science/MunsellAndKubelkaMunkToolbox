function perc=lab2perc(lab)

% LAB2PERC computes the lightness, chroma and hue angle of a set of colours 
% characterized in the CIELAB space.
%
% SYNTAX
% ----------------------------------------------------------------------------
% LhC=LAB2PERC(LAB)
%
% LAB = Ligthness and chromaticity coordinates of the stimuli in CIELAB.
%       For N stimuli, this is a Nx3 matrix.
%
% LhC = For N stimuli, Nx3 matrix. The first column contains the lightness L*,
%        the second the hue angle (h*=atan(b*/a*), 0<=h*<=2*pi) and the third
%        the chroma (C*=sqrt(a*^2+b*^2)).
%        
% RELATED FUNCTIONS
% ----------------------------------------------------------------------------
% PERC2LAB, XYZ2LAB, LAB2XYZ


perc=[lab(:,1) atan2(lab(:,3),lab(:,2))+2*pi*(+(atan2(lab(:,3),lab(:,2))<0)) sqrt((lab(:,3).^2)+(lab(:,2).^2))];

