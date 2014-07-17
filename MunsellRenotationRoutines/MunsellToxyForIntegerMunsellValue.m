function [x y Status] = MunsellToxyForIntegerMunsellValue(ColorLabMunsellVector)
% Purpose		Convert a Munsell specification, whose value is an integer,
%				into CIE xyY coordinates, by interpolating over extrapolated Munsell
%				renotation data ([Newhall1943], [MCSL2010]). 
%
% Description	It is a difficult problem to convert Munsell specifications to xyY
%				coordinates, when xyY coordinates are only available for some
%				Munsell specifications.  A subtask is to convert a Munsell
%				specification of integer value to xyY coordinates, in accordance with the
%				Munsell renotation.  The current routine performs that subtask.
%
%				This routine uses the fact that, within a Munsell 
%				section of fixed value, the lines of constant 
%				chroma are ovoids around a central, achromatic point, corresponding to the
%				Munsell grey of that value.  The lines of constant hue are slightly curving 
%				lines radiating from the central point.  The input Munsell specification
%				unless it is on a standard ovoid, falls on a radial between two standard
%				ovoids.  A standard ovoid has even chroma, and is parametrized by hue.
%
%				This routine finds two colours, both of even chroma, that sharply bound the input
%				Munsell colour.  The two bounding colours have the same hue and value as the
%				input colour.  Their positions on standard ovoids are calculated by the routine
%				FindHueOnRenotationOvoid.  The xy coordinates of the input colour are found by
%				linearly interpolating over those two positions, using chroma.  For example, 
%				suppose the input colour is 2.9G5/6.5.  Then the two bounding colours are
%				2.9G5/6 and 2.9G5/8.  Their positions on the ovoids of chromas 6 and 8 are
%				found by the routine FindHueOnRenotationOvoid.  The input colour 2.9G5/6.5 lies
%				on the straight line between 2.9G5/6 and 2.9G5/8, one quarter of the way from
%				2.9G5/6 to 2.9G5/8.
%
%				[MCSL2010] http://www.cis.rit.edu/mcsl/online/munsell.php, as of June 12, 2010
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		[x y Status] = MunsellToxyForIntegerMunsellValue(ColorLabMunsellVector);
%
%				ColorLabMunsellVector	A Munsell specification, such as 4.2R8/5.3,
%										whose Munsell value is an integer.  The specification is
%										in ColorLab format.
%
%				[x y]					CIE chromaticity coordinates of the input Munsell colour,
%										when illuminated by Illuminant C
%	
%				Status			A return code with two fields.  The second field is a list
%								of possible return messages.  The first field is a positive
%								integer indicating one of the return messages.  
%
% Related		MunsellToxyY
% Functions
%
% Required		FindHueOnRenotationOvoid, MunsellToxyYfromExtrapolatedRenotation, roo2xy
% Functions		
%
% Author		Paul Centore (June 23, 2010)
% Revised		Paul Centore (Jan. 5, 2011)
%  Revisions:	The previous version interpolated over both hue and chroma.  The revised version
%					calls FindHueOnRenotationOvoid to interpolate over hue, and then just
%					interpolates over chroma.
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revision		Paul Centore (Jan. 1, 2014)  
%				 ---Replaced call to IlluminantCWhitePoint with call to roo2xy (from OptProp).
%
% Copyright 2010-2014,  Paul Centore
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

% Make list of possible status return messages
MunsellSpecString = ColorLabFormatToMunsellSpec(ColorLabMunsellVector);
Status.Messages = {'Success',...
                   [MunsellSpecString,' beyond gamut of renotation data.'],...
				   'Could not perform ovoid calculation',...
				   };
% Assign default output values
x          = -99;
y          = -99;
Status.ind = -99;

% A one-element vector is an achromatic grey, so no interpolation is
% necessary.  Evaluate directly and return.
if length(ColorLabMunsellVector) == 1
   if ColorLabMunsellVector(1) == 10			% Ideal white; set value directly and return
         [x y] = roo2xy(ones(size([400:10:700])), 'C/2', [400:10:700]); 
         % The line above replaces the following line (replaced Jan. 1, 2014, by Paul Centore)
         % [x y]      = IlluminantCWhitePoint()	;
         Status.ind = 1							;
         return									;	
	end
   [x y Y StatusCode] = MunsellToxyYfromExtrapolatedRenotation(ColorLabMunsellVector);
   if StatusCode.ind == 1
      Status.ind = 1		;
   else
	  Status.ind = 2		;
   end
   return					;
end

% Otherwise, ColorLabMunsellVector has four elements with Munsell information
% Extract data from ColorLab version of Munsell specification
MunsellHueNumber    = ColorLabMunsellVector(1);
IntegerMunsellValue = ColorLabMunsellVector(2);
MunsellChroma       = ColorLabMunsellVector(3);
CLHueLetterIndex    = ColorLabMunsellVector(4);

% Find two chromas which bound the chroma of the input colour, and for which
% renotation data are available.  Renotation data is available only 
% for even chromas.
if MunsellChroma == 0			% Munsell grey, for which no interpolation is needed
   [x y Y StatusCode] = MunsellToxyYfromExtrapolatedRenotation([IntegerMunsellValue]);
   if StatusCode.ind == 1
      Status.ind = 1		;
   else
	  Status.ind = 2		;
   end
   return					;
else
   if mod(MunsellChroma,2) == 0			% No interpolation needed for Munsell chroma
      MunsellChromaMinus = MunsellChroma	;
      MunsellChromaPlus  = MunsellChroma	;
   else
      MunsellChromaMinus = 2 * floor(MunsellChroma/2)	;
      MunsellChromaPlus  = MunsellChromaMinus + 2		;
   end
end

if MunsellChromaMinus == 0		% Colour within smallest even chroma ovoid
   [xMinus yMinus] = roo2xy(ones(size([400:10:700])), 'C/2', [400:10:700]); % Smallest chroma ovoid collapses to white point
   % The line above replaces the following line (replaced Jan. 1, 2014, by Paul Centore)
%  [xMinus yMinus] = IlluminantCWhitePoint();	% Smallest chroma ovoid collapses to white point
else
   [xMinus yMinus Stat] = FindHueOnRenotationOvoid([MunsellHueNumber,IntegerMunsellValue,MunsellChromaMinus,CLHueLetterIndex]);
   if Stat.ind ~= 1			% Unsuccessful call
      Status.ind = 3	;	% Return with error code
      return			;
   end
end
[xPlus  yPlus  Stat] = FindHueOnRenotationOvoid([MunsellHueNumber,IntegerMunsellValue, MunsellChromaPlus, CLHueLetterIndex]);
if Stat.ind ~= 1		% Unsuccessful call
   Status.ind = 3	;	% Return with error code
   return			;
end

if MunsellChromaMinus == MunsellChromaPlus	% Two bounding points are the same
   x = xMinus		;	% xMinus and xPlus are the same, as are yMinus and yPlus
   y = yMinus		;
else					% Two bounding points are different
   x = interp1([MunsellChromaMinus, MunsellChromaPlus], [xMinus, xPlus], MunsellChroma);
   y = interp1([MunsellChromaMinus, MunsellChromaPlus], [yMinus, yPlus], MunsellChroma);
end

% Set successful status return code and return
Status.ind = 1;
return; 