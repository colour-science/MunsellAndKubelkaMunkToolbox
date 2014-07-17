function [lab]=xyz2lab(C,bbb);

% Author		Taken from the ColorLab website
% Revised		Paul Centore (December 14, 2013)
%				---Made the whitepoint a variable input, instead of a default

% XYZ2LAB computes the lightness, L*, and the chromatic coordinates a* and b* in CIELAB
% of a set of colours defined by their tristimulus CIE-1931 values.
%
% CIELAB is a simple appearance model providing perceptual descriptors (lightness, hue
% and chroma) for related colours (colours in a scene).
%
% In this representation, information about the illumination conditions or, alternatively,
% about the scene, is included in a reference stimulus. Using CIELAB in the standard
% conditions implies that the reference stilulus is a perfect difuser illuminated as the
% test.
% 
% SYNTAX
% ----------------------------------------------------------------------------
% LAB=xyz2lab(XYZ,XYZR)
%
% XYZ = Tristimulus values of the test stimuli.
%       For N colours, this is a Nx3 matrix.
%
% XYZR = Tristimulus values of the reference stimulus.
%        If the reference stimulus is the same for all the test stimuli, this
%        is a 1x3 matrix. If the reference is different for each test stimulus
%        XYZR is a Nx3 matrix.
%
% LAB  = For N colours, Nx3 matrix, containing, in columns, the lightness L*,
%        and the chromaticity coordinates a* and b*.
%
% RELATED FUNCTIONS
% ----------------------------------------------------------------------------
% lab2xyz, lab2perc, perc2lab
%

% The following revision was made December 14, 2013, by Paul Centore.
% The reference white stimulus for an object colour is the XYZ coordinates (for a set illuminant
% and observer) of a perfectly diffuse reflector, when lit by the illuminant of interest.  A
% perfect reflector has a reflectance spectrum of 100% across the entire visible spectrum.
% A reference white stimulus, [X_R, Y_R, Z_R], is often expressed as a percentage, so that
% the luminosity (Y_R) is 100.  The routine as taken from ColorLab seems to assume that
% Y_R is 1 (i.e. 100%).  To handle both cases, normalize the input XYZR, so that the middle
% value is 1.  
%[rows, cols] = size(XYZR)					;
%NormalizedXYZR = -99 * ones(size(XYZR))		;
%for ctr = 1:rows
%    NormalizedXYZR(ctr,:) = XYZR(ctr,:)/XYZR(ctr,2)	;
%end
% For consistency with previous version, use the variable bbb
%bbb = NormalizedXYZR	

% The following code made up the original ColorLab routine, before the Dec. 2013 revision
s=size(C);
ss=size(bbb);
if ss(1)~=s(1)
   bbb=ones(s(1),1)*bbb(1,:);
end

for i=1:s(1)
    c=C(i,:);
    b=bbb(i,:);
    if (c(2)/b(2))>0.008856
       F2=(c(2)/b(2))^(1/3); 
       L=116*F2-16;
    else
       L=903.3*(c(2)/b(2));
       F2=(1/116)*(903.3*(c(2)/b(2))+16);
    end
    if (c(1)/b(1))>0.008856
       F1=(c(1)/b(1))^(1/3); 
    else
       F1=(1/116)*(903.3*(c(1)/b(1))+16);
    end
    if (c(3)/b(3))>0.008856
       F3=(c(3)/b(3))^(1/3); 
    else
       F3=(1/116)*(903.3*(c(3)/b(3))+16);
    end
    a=500*(F1-F2);
    bb=200*(F2-F3);
    lab(i,:)=real([L a bb]);
end
