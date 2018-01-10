function MunsellSpecString = ValueChromaAndASTMHueToMunsellSpec(...
														 Value,...
														 Chroma,...
														 ASTMHue);
% Purpose		Make a Munsell specification from a Munsell value, a Munsell chroma, and 
%				an ASTM hue.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form H V/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R 9.0/2.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				Apart from the above method of specifying a Munsell hue, it is also
%				natural to make the Munsell hues into a circle, with PB being followed
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
%				This routine takes as input a Munsell value, a Munsell chroma, and an ASTM
%				hue as specified above, and combines them into a Munsell specification, which
%				is returned as a string.
%
%				[ASTMD1535-08] ASTM, Standard D 1535-08, "Standard Practice for Specifying Color by the
%					Munsell System," approved January 1, 2008.
%
%				Value		A Munsell value
%
%				Chroma		A Munsell chroma
%
%				ASTMHue		A number between 0 and 100, that corresponds to the input
%							Munsell hue, via [ASTMD1535-08, Fig. 1].
%
%				MunsellSpecString	A Munsell specification, such as 5.6R 9.1/4.7.
%				
% Author		Paul Centore (November 2, 2015)
%
% Copyright 2015 Paul Centore
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

if Chroma == 0
	MunsellSpecString = ['N',num2str(Value)]	;
else
	[HueString, ~, ~] = ASTMHueToMunsellHue(ASTMHue, 4)						;
	MunsellSpecString = [HueString,' ',num2str(Value),'/',num2str(Chroma)]	;
end