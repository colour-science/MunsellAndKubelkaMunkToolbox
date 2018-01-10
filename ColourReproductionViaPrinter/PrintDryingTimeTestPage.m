function PrintDryingTimeTestPage(OutputDirectory);
% Purpose		Print out a test page to be used in measuring a printer s drying time.
%
% Description   The printouts from an offset or desktop printer might change in colour during
%				drying or curing.  Measurements made during the drying period would then not
%				be representative of the output.  This routine prints out a test page that 
%				can be used to measure drying time.
%
%				OutputDirectory		The directory in which the test sheet will be saved
%
% Author		Paul Centore (June 21, 2015)
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

% Choose a set of 64 RGBs, evenly distributed throughout the RGB cube
NumOfDiv = 4											;
CombsWithRepetition = combinator(NumOfDiv, 3, 'p', 'r')	;
RGB = (1/(NumOfDiv-1))*(CombsWithRepetition-1)			;
RGB = (1/255) * round(255 * RGB)						;	

% The printout should have two colours of each RGB beside each other, with no dividing
% line between them.  
DoubledRGBs = []	;
for ctr = 1:size(RGB,1)
	DoubledRGBs = [DoubledRGBs; RGB(ctr,:); RGB(ctr,:)]	;
end

% The printout will have four doubled RGBs in each row.  There will be three white spaces
% separating the four doubled RGBs.  Add in those white spaces
DoubledRGBsWithWhiteSpaces = []	;
for ctr = 1:16
	DoubledRGBsWithWhiteSpaces = [DoubledRGBsWithWhiteSpaces;	...
								  DoubledRGBs(8*(ctr-1)+1,:);	...
								  DoubledRGBs(8*(ctr-1)+2,:);	...
								  1,1,1						;	...
								  DoubledRGBs(8*(ctr-1)+3,:);	...
								  DoubledRGBs(8*(ctr-1)+4,:);	...
								  1,1,1						;	...
								  DoubledRGBs(8*(ctr-1)+5,:);	...
								  DoubledRGBs(8*(ctr-1)+6,:);	...
								  1,1,1						;	...
								  DoubledRGBs(8*(ctr-1)+7,:);	...
								  DoubledRGBs(8*(ctr-1)+8,:)]	;								  
end

% Produce a figure with those RGBs.
PatchesDown = 16	;
PatchesAcross = 11	;
PrintRGBs(DoubledRGBsWithWhiteSpaces, [OutputDirectory,'/DryingTimeTestPage'], PatchesDown, PatchesAcross)	;