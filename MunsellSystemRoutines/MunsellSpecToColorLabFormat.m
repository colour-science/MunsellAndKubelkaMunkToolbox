function ColorLabMunsellVector = MunsellSpecToColorLabFormat(MunsellSpecString);
% Purpose		Convert a Munsell specification into ColorLab format. 
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form HV/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R 9.0/4.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				Routines in ColorLab use the Munsell specifications, but not necessarily the
%				Munsell notation HV/C.  A Munsell vector is given by [H1, V, C, H2], where 
%				H1 is the number designator for hue, H2 is the position of the hue letter 
%				designator in the list
%				                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
%				V is the Munsell value, and C is the Munsell chroma. For example, 
%				5.0R 9.0/4.0 is [5 9 4 7] in ColorLab
%				format.  A neutral Munsell grey is a one-element vector in ColorLab
%				format, consisting of the grey value.  For example, N4 is [4] in ColorLab
%				format.
%
% Syntax		ColorLabMunsellVector = MunsellSpecToColorLabFormat(MunsellSpecString);
%
%				MunsellSpecString		A standard Munsell specification, such as 5R 9/4.  Spaces 
%								are not required; 5R9/4 is also acceptable.
%
%				ColorLabMunsellVector	Either a one- or four-element vector consisting of
%								Munsell specifications, as described above.
%
% Related		ColorLabFormatToMunsellSpec
% Functions
%
% Required		isdigit (required for Matlab, but not for Octave)
% Functions		
%
% Author		Paul Centore (May 15, 2010)
% Revision		Zsolt Kovacs-Vajna (May 10, 2012)
%				 ---Changed "toupper" to "upper" to be compatible with both Octave and Matlab.
% Revision		Paul Centore (May 11, 2012)
%				 ---Allowed spaces in input Munsell string; spaces are removed for processing.
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
%
% Copyright 2010, 2012 Paul Centore
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

TRUE  = 1;
FALSE = 0;

% Remove all spaces from input Munsell string
MunsellString = sscanf(MunsellSpecString,'%s');

% Make all letters in Munsell string upper case
MunsellString = upper(MunsellString);

% Read through the Munsell string in order, extracting hue, value, and chroma
ctr = 1;
entry = MunsellString(ctr);

% Check for achromatic colour
if strcmp(entry, 'N') == TRUE
   MunsellValue = str2num(MunsellString(2:end));
   ColorLabMunsellVector = [MunsellValue];
   return
end

% Extract hue number from start of Munsell specification.
HueLetterReached = FALSE;
while isdigit(entry) == TRUE || strcmp(entry,'.') == TRUE
   ctr = ctr + 1;
   entry = MunsellString(ctr);
end
MunsellHueNumber = str2num(MunsellString(1:(ctr-1)))	;

% Next, extract hue letter designator 
% entry is 1st letter of Munsell Hue Designator, which might consist of two letters
PossibleNextLetter = MunsellString(ctr+1);
ColorLabHueLetterDesignator = -99;	% Default error value
if ~isdigit(PossibleNextLetter)
   MunsellHueLetterDesignator = MunsellString(ctr:(ctr+1));
   if strcmp(MunsellHueLetterDesignator,'BG')  == TRUE
      ColorLabHueLetterDesignator = 2;
   elseif strcmp(MunsellHueLetterDesignator,'GY')  == TRUE
      ColorLabHueLetterDesignator = 4;   
   elseif strcmp(MunsellHueLetterDesignator,'YR')  == TRUE
      ColorLabHueLetterDesignator = 6;
   elseif strcmp(MunsellHueLetterDesignator,'RP')  == TRUE
      ColorLabHueLetterDesignator = 8;   
   elseif strcmp(MunsellHueLetterDesignator,'PB')  == TRUE
      ColorLabHueLetterDesignator = 10;
   else
      disp(['ERROR1: ',MunsellHueLetterDesignator,' is not a valid hue letter designator']);
   end
   ctr = ctr + 1;
else
   MunsellHueLetterDesignator = MunsellString(ctr);
   if strcmp(MunsellHueLetterDesignator,'B')  == TRUE
      ColorLabHueLetterDesignator = 1;
   elseif strcmp(MunsellHueLetterDesignator,'G')  == TRUE
      ColorLabHueLetterDesignator = 3;
   elseif strcmp(MunsellHueLetterDesignator,'Y')  == TRUE
      ColorLabHueLetterDesignator = 5;
   elseif strcmp(MunsellHueLetterDesignator,'R')  == TRUE
      ColorLabHueLetterDesignator = 7;
   elseif strcmp(MunsellHueLetterDesignator,'P')  == TRUE
      ColorLabHueLetterDesignator = 9;
   else
      disp(['ERROR2: ',MunsellHueLetterDesignator,' is not a valid hue letter designator']);
   end
end

% Some Munsell hue specifications use 0 instead of 10.  For example, 0YR is the same
% hue as 10R.  ColorLab format uses 10 instead of 0, in the naming of Munsell data files.
% To be consistent with ColorLab format, change 0 to 10, and adjust the hue designator.
if MunsellHueNumber == 0
   MunsellHueNumber           = 10										;
   ColorLabHueLetterDesignator = mod(ColorLabHueLetterDesignator + 1, 10)	;
end

% Remainder of Munsell specification string is value and chroma
vec              = sscanf(MunsellString((ctr+1):end), '%f/%f')	;
MunsellValue     = vec(1)										;
MunsellChroma    = vec(2)										;

% Although a grey in the Munsell system should be denoted with an N, such as N2.5 or
% N7, it is possible that the C value in the HV/C format was assigned to 0, for example
% 5.6GY4.3/0.00.  In that case, use a 1-element vector for the ColorLab format;
% otherwise, use a four-element vector.
if MunsellChroma == 0
   ColorLabMunsellVector = [MunsellValue]	;
else
   ColorLabMunsellVector = [MunsellHueNumber, MunsellValue, MunsellChroma, ColorLabHueLetterDesignator];
end
return