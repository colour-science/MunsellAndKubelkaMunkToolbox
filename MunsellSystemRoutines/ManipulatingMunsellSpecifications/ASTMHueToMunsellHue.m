function [HueString, HueNumber, HueLetterCode] = ASTMHueToMunsellHue(ASTMHue, HueDecimals);
% Purpose		The Munsell specification for hue involves both a letter code (such as R or BG),
%				and a numerical modifier.  For ease of calculation, it is sometimes more
%				convenient to express the Munsell hue as a single number.  The hues
%				naturally form a circle, which [ASTMD1535-08, Fig. 1] divides into 100 equal angles,
%				labeled modularly from 0 to 100.  This routine converts from the ASTM
%				hue number into a Munsell specification.  The Munsell specification is
%				returned as a string, and also as a hue number and a ColorLab hue letter
%				code.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form H V/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R 9.0/4.0 is a light pastel
%				red, while N3 is a dark grey.  A hue designator, such as 6.3YR, can be seen 
%				as a character string.
%
%				Routines in ColorLab use the Munsell system, but not necessarily the
%				Munsell notation HV/C.  A Munsell vector is given by [H1, V, C, H2], where 
%				H1 is the number designator for hue, H2 is the position of the hue letter 
%				designator in the list
%				                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
%				V is the Munsell value, and C is the Munsell chroma. For example, 
%				5.0R9.0/4.0 is [5 9 4 7] in ColorLab format.  The arguments HueNumber and
%				HueLetterCode in this routine correspond to H1 and H2, respectively.
%
%				It is natural to make the Munsell hues into a circle, with PB being followed
%				by B.  [ASTMD1535-08, Fig. 1] labels the angles on the circle modularly from
%				0 to 100, with 0 and 100 both corresponding to 10RP.  The following assignments
%				are made:
%											5R		5
%											5Y		25
%											5G		45
%											5B		65
%											5P		85
%										  10RP		100, 0
%								      epsilonR		epsilon.
%
%				This routine takes the ASTM hue number and converts it into two other
%				forms: a hue string, and a pair of numbers (HueNumber and HueLetterCode).
%
%				[ASTMD1535-08] ASTM, Standard D 1535-08, "Standard Practice for Specifying Color by the
%					Munsell System," approved January 1, 2008.
%
%				ASTMHue			A number between 0 and 100, that corresponds to the input
%								Munsell hue, via [ASTMD1535-08, Fig. 1].
%
%				HueDecimals		The number of decimal points which are contained in the
%								output hue string.  This argument is optional
%
%				HueNumber		A number greater than 0, and less than or equal to 10, that
%								is prefixed to a hue descriptor in the list
%								{B, BG, G, GY, Y, YR, R, RP, P, PB}, in the Munsell system.
%
%				HueLetterCode	An integer between 1 and 10, corresponding to an element in
%								the list {B, BG, G, GY, Y, YR, R, RP, P, PB}.
%
%				HueString		A character string, such as 8.32BG.  This string is the H
%								in the Munsell specification H V/C.
%
% Related		None
% Functions
%
% Required		None
% Functions		
%
% Author		Paul Centore (Jan. 22, 2014)
% Revised		Paul Centore (Feb. 5, 2014)
%				---Made number of decimals in string an (optional) input
%
% Copyright 2014 Paul Centore
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

HueNumber = mod(ASTMHue,10)		;
if HueNumber == 0
    HueNumber = 10	;
end

if 0 < ASTMHue && ASTMHue <= 10
    HueLetter     = 'R' ;
    HueLetterCode =  7	;
elseif 10 < ASTMHue && ASTMHue <= 20
    HueLetter     = 'YR';
    HueLetterCode =  6	;
elseif 20 < ASTMHue && ASTMHue <= 30
    HueLetter     = 'Y' ;
    HueLetterCode =  5	;
elseif 30 < ASTMHue && ASTMHue <= 40
    HueLetter     = 'GY';
    HueLetterCode =  4	;
elseif 40 < ASTMHue && ASTMHue <= 50
    HueLetter     = 'G' ;
    HueLetterCode =  3	;
elseif 50 < ASTMHue && ASTMHue <= 60
    HueLetter     = 'BG';
    HueLetterCode =  2	;
elseif 60 < ASTMHue && ASTMHue <= 70
    HueLetter     = 'B' ;
    HueLetterCode =  1	;
elseif 70 < ASTMHue && ASTMHue <= 80
    HueLetter     = 'PB';
    HueLetterCode =  10	;
elseif 80 < ASTMHue && ASTMHue <= 90
    HueLetter     = 'P' ;
    HueLetterCode =  9	;
else  % This includes any ASTM hue greater than 90, and also the ASTM hue 0
    HueLetter     = 'RP';
    HueLetterCode =  8	;
end

% Default to 2 decimal places in the hue string, unless the inputs specify otherwise
if ~exist('HueDecimals')
	HueDecimals = 2 	;	
end 
						
HueString = [sprintf(['%',num2str(HueDecimals+2),'.',num2str(HueDecimals),'f'],...
                   HueNumber), HueLetter]							;

return