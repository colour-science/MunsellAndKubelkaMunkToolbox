function [XYZ]=lab2xyz(C,bbb);

% LAB2XYZ computes the tristimulus values of a set of colours from their lightness, L*,
% and chromatic coordinates a* and b* in CIELAB.
%
% CIELAB is a simple appearance model providing perceptual descriptors (lightness, hue
% and chroma) for related colours (colours in a scene).
%
% In this representation, information about the illumination conditions or, alternatively,
% about the scene, is included in a reference stimulus. Using CIELAB in the standard
% conditions implies that the reference stimulus is a perfect difuser illuminated as the
% test.
% 
% SYNTAX
% ----------------------------------------------------------------------------
% XYZ=LAB2XYZ(LAB,XYZR)
%
% LAB  = For N colours, Nx3 matrix, containing, in columns, the lightness L*,
%        and the chromaticity coordinates a* and b*.
%
% XYZR = Tristimulus values of the reference stimulus.
%        If the reference stimulus is the same for all the test stimuli, this
%        is a 1x3 matrix. If the reference is different for each tes stimulus
%        XYZR is a Nx3 matrix.
%
% XYZ = Tristimulus values of the test stimuli.
%       For N colours, this is a Nx3 matrix.
%
% RELATED FUNCTIONS
% ----------------------------------------------------------------------------
% XYZ2LAB, LAB2PERC, PERC2LAB
%

s=size(C);
ss=size(bbb);
if ss(1)~=s(1)
   bbb=ones(s(1),1)*bbb(1,:);
end

for i=1:s(1)
    c=C(i,:);
    b=bbb(i,:);
    if ((c(1)+16)/116)^3>0.008856
       y=b(2)*((c(1)+16)/116)^3;
       F2=(c(1)+16)/116;
    else
       y=b(2)*c(1)/903.3;
       F2=(1/116)*(c(1)+16);
    end
    if (c(2)/500+F2)^3>0.008856
       x=b(1)*(c(2)/500+F2)^3;
    else
       x=(b(1)/903.3)*(116*(c(2)/500+F2)-16);
    end
    if abs((F2-c(3)/200)^3)>0.008856
       z=b(3)*(F2-c(3)/200)^3;
    else
       z=(b(3)/903.3)*(116*(F2-c(3)/200)-16);
    end
    XYZ(i,:)=[x y z];
end
