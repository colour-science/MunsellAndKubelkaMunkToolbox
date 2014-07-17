% ===================================================
% *** FUNCTION srgb2xyz
% ***
% *** function [XYZ] = srgb2xyz(RGB)
% *** computes XYZ from 8-bit RGB 
% *** RGB is n by 3 and in the range 0-255
% *** XYZ is returned in the range 0-1
% *** see also xyz2srgb
function [XYZ] = srgb2xyz(RGB)
if (size(RGB,2)~=3)
   disp('RGB must be n by 3'); return;   
end

XYZ = zeros(size(RGB));

M = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];

DACS=RGB/255;
RGB = zeros(size(RGB));

index = (DACS<=0.04045);
RGB = RGB + (index).*(DACS/12.92);
RGB = RGB + (1-index).*((DACS+0.055)/1.055).^2.4;

XYZ = (M*RGB')';

end