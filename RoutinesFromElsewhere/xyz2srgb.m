% ===================================================
% *** FUNCTION xyz2srgb
% ***
% *** function [RGB] = xyz2srgb(XYZ)
% *** computes 8-bit sRGB from XYZ 
% *** XYZ is n by 3 and in the range 0-1
% *** see also srgb2xyz
%
% The original version of this routine was taken from the Computational
% Colour Toolbox, written by Stephen Westland, Caterina Ripamonti, and 
% Vien Cheung.
%
% Author	Stephen Westland, Caterina Ripamonti, Vien Cheung
% Revision	Paul Centore (March 24, 2013)
%			---Calculated out-of-gamut flag and added to list of returned variables

% Function call revised in March 2013, to add OutOfGamutFlag
function [RGB, OutOfGamutFlag] = xyz2srgb(XYZ)
if (size(XYZ,2)~=3)
   disp('XYZ must be n by 3'); return;   
end

M = [3.2406 -1.5372 -0.4986; -0.9689 1.8758 0.0415; 0.0557 -0.2040 1.0570];

RGB = (M*XYZ')';

% START: lines added March 2013 to set out-of-gamut flag.  
% The out-of-gamut flag is a column vector of Boolean true/false values.  Each
% entry corresponds to one row of the input matrix XYZ.
[NumberOfInputs,~] = size(RGB)					;
OutOfGamutFlag     = -99 * ones(NumberOfInputs,1)		
for index = 1:NumberOfInputs
	if RGB(index,1) < 0 || RGB(index,1) > 1 ||...
	   RGB(index,2) < 0 || RGB(index,2) > 1 ||...
	   RGB(index,3) < 0 || RGB(index,3) > 1
	   OutOfGamutFlag(index) = true		;
	else
	   OutOfGamutFlag(index) = false	;
	end
end
% END: lines added March 2013 to set out-of-gamut flag

RGB(RGB<0) = 0;
RGB(RGB>1) = 1;

DACS = zeros(size(XYZ));
index = (RGB<=0.0031308);
DACS = DACS + (index).*(12.92*RGB);
DACS = DACS + (1-index).*(1.055*RGB.^(1/2.4)-0.055);

RGB=ceil(DACS*255);
RGB(RGB<0) = 0;
RGB(RGB>255) = 255;
end