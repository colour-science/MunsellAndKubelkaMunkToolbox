function [ColoursPrinted, ...
          RGBDe, ...
          HueSheetFigure] = PrintMunsellHueSheetFromMunsellRGBList(...
                             		HuePrefix, ...
                             		CLHueLetter, ...
                             		MunsellRGBList, ...
                             		DEthreshold, ...
                             		NonThresholdMunsellSpecs, ...
                             		ExcludedMunsellSpecs);
% Purpose		Print a Munsell sheet, over standard values and chromas, for an input
%				Munsell hue.  Use data contained in an input file.  The file expresses
%				the printed output of an RGB specification in Munsell coordinates, for a
%				certain printer, settings, inkset, and paper.  The file also contains 
%				colour differences (expressed in DE2000) from the targets.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma (C) in the form H V/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R 9.0/2.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				Some routines in ColorLab use the Munsell specifications, but not necessarily the
%				Munsell notation H V/C.  A Munsell vector is given by [H1, V, C, H2], where 
%				H1 is the number designator for hue, H2 is the position of the hue letter 
%				designator in the list
%				                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
%				V is the Munsell value, and C is the Munsell chroma. For example, 
%				5.0R9.0/4.0 is [5 9 4 7] in ColorLab format.  H1 and H2 are two inputs to this
%				routine.
%
%				The Munsell system is usually presented as a series of sheets, with each
%				sheet displaying all the colours of a fixed hue.  The value increases in
%				integer increments from 1 to 9, while the chroma increases in even integer
%				increments from left to right.  This routine prints such a sheet for an input hue.
%
%				Any hue can take on values at least between 1 and 9, which are the values 
%				displayed.  For a given hue and value, there is a maximum chroma, called the
%				MacAdam limit.  This routine calls another routine, MaxChromaForMunsellHueAndValue,
%				to calculate the greatest chroma for each value, and then prints a row of
%				colours at that value, out to the maximum chroma.  
%
%				A computer uses a red-green-blue (RGB) specification for colours.  To print colour
%				output, a computer sends a set of RGB values to a printer.  The printer has a set of
%				inks of different colours, so it must convert RGB values into printer-specific
%				commands in order to print the desired colours.  The conversions are sometimes
%				performed by a colour management system (CMS), often involving profiles in a format
%				specified by the International Color Consortium (ICC).  
%				The conversions only apply to a specific printer, with specific settings,
%				a specific inkset, and a specific kind of paper.  If colour management is used, then
%				one may also have to specify the ICC profile for the monitor.
%
%				The conversions can be treated as a black box, in which one only knows the RGB input, and some
%				colorimetric data, such as the Munsell specification, about the corresponding output.
%				The input matrix MunsellRGBList contains just this information.  The first column is the
%				Munsell specification for a printed output.  The second to fourth columns are the RGB
%				specifications for the input.  The printed output of the RGB input will match the
%				Munsell specification to within a CIEDE2000 difference, given in the fifth column.  
%
%				To print a desired Munsell colour, then, the routine finds the corresponding RGB in the
%				matrix MunsellRGBList, and inputs that to the printer.  As long as the printing
%				conditions (same printer, settings, inkset, paper, CMS) match those under which the input
%				matrix was generated, the output should be the desired Munsell colour.  A check is done
%				to insure that the printed RGB matches the Munsell colour to within a desired threshold.
%
%				In addition, an optional input is a list of Munsell specifications for which no threshold is
%				required.  Any RGB that is available for these specifications will be displayed,
%				regardless of its DE.  A note will be printed to the console whenever this occurs,
%				informing the user of the actual DE.  This option was added because gaps will usually appear
%				in a Munsell page, when the same DE is used for the entire set of colours.
%
%				HuePrefix		A value between 0 and 10 that prefixes a literal Munsell
%								hue description, such as the 6.3 in 6.3RP.
%
%				CLHueLetter		A numerical index to the list of Munsell hue strings,
%								that is given in the description.  For example, the index 2
%								corresponds to BG.
%
%				MunsellRGBList	A file, whose first column is a list of Munsell specifications,
%								and whose second through fourth columns are RGB specifications.
%								When printed (with a fixed printer, settings, inkset, and paper),
%								the RGB output should have the given Munsell specification.  A
%								fifth column gives the accuracy, in terms of CIEDE2000, of the match
%								between the Munsell specification and the printed output.
%
%				DEthreshold		Only print RGBs that match an aimpoint to within a desired threshold.
%
%				NonThresholdMunsellSpecs	Print RGBs for these Munsell specifications, even if they do not
%											meet the desired threshold.  
%
%				ExcludedMunsellSpecs	Do not print RGBs for these Munsell specifications, even if they 
%										meet the desired threshold.  
%
%				ColoursPrinted	Return list of colours printed.
%
%				RGBDe			A 4-column output matrix.  Each row corresponds to an entry in
%								ColoursPrinted, and gives the RGB for printing, and the DE
%
%				HueSheetFigure	The hue sheet in Octave/Matlab s figure format
%
% Author		Paul Centore (November 22, 2012)
% Revised		Paul Centore (December 10, 2014)
%				---Added check for greys in comparison, to avoid out-of-bounds error
%				---Made figure an output to be returned, rather than printed out and saved here
%
% Copyright 2012, 2014 Paul Centore
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

% ColorLab hue letters for Munsell specifications
ColourLetters = {'B', 'BG', 'G', 'GY', 'Y', 'YR', 'R', 'RP', 'P', 'PB'}	;

% Start list of colours that are actually printed on the output page, and list of DEs
ColoursPrinted = {}			;
RGBDe          = []			;

% If the input variables do not contain any list of Munsell specifications to which
% the threshold does not apply, then set this variable to empty
if ~exist('NonThresholdMunsellSpecs', 'var')
   NonThresholdMunsellSpecs = {}	;
end

% Read in data from input file
fid = fopen(MunsellRGBList, 'r')	;
MunsellList = {}			;
RGBdata     = []			;
while ~feof(fid)
   % Read in Munsell coordinates, and RGB coordinates
   MunsellString = fscanf(fid, '%s',1)	;
   MunsellString = MunsellString(1:(end-1))	;		% Remove trailing comma
   MunsellList{end+1} = MunsellString	;
   RStr  = fscanf(fid,'%s',1)			;
   GStr  = fscanf(fid,'%s',1)			;
   BStr  = fscanf(fid,'%s',1)			;
   DEStr = fscanf(fid,'%s',1)			;
   RGBdata = [RGBdata; str2num(RStr), str2num(GStr), str2num(BStr), str2num(DEStr)]	;
end
fclose(fid)								;

NumOfDataPoints = length(MunsellList)	;		

% Create the figure for the hue sheet
HueSheetFigure = figure	;
set(gcf, 'Color', [1 1 1]);
% Display the Munsell hue sheet so that one value step equals two chroma steps, as
% is customary.
CVratio = 2;
% Use the variable SizePar to control the size of the Munsell samples displayed
SizePar = 0.8; 
MaxChromaForDisplay = 20	;

% Draw a row for each value
for Value = 1:9
   % The colours for each value extend out to a maximum chroma
   [MaxChroma Status] = MaxChromaForMunsellHueAndValue(HuePrefix, CLHueLetter, Value)	;
   % Only display chromas out to some MaxChromaForDisplay, even if the MacAdam limits exceed this
   MaxChroma = min(MaxChroma, MaxChromaForDisplay)										;
   
   % Draw a colour square for each chroma for which RGBs are available
   for Chroma = 2:2:MaxChroma
      % Convert Munsell specification to RGB coordinates, by looking through input matrix
	  ctr =	1						;
	  MunsellStringFound   = false	;
	  
	  % Check whether this Munsell specification is on the excluded list
	  TempMunsellString = ColorLabFormatToMunsellSpec([HuePrefix,Value,Chroma,CLHueLetter],...
                                                         2,0,0);
	  TempMunsellString(TempMunsellString == ' ') = ''	; % Remove blanks from string
	  if ismember(TempMunsellString, ExcludedMunsellSpecs)
		  ExcludeMunsellString = true	
	  else
		  ExcludeMunsellString = false	;
	  end
	  
	  % We are looking for an RGB that corresponds to a Munsell colour, along with a DE
	  % giving its accuracy.  Initialize these value with -99.  The desired RGB might not
	  % exist, so we must check for it
	  R = -99						;
	  G = -99						;
	  B = -99						;
	  DE2000 = -99					;
	  if ExcludeMunsellString == false 		% Only investigate colours that will be printed
	  	  % Check through all data points, looking for a match
		  while ctr <= NumOfDataPoints && MunsellStringFound == false 
			  % MunsellDataPoint expresses a Munsell specification from the input file, in ColorLab format
			  MunsellString    = MunsellList{ctr}							;
			  MunsellDataPoint = MunsellSpecToColorLabFormat(MunsellString)	;

			  % Check element by element to see if this Munsell specification from the input matches
			  % the Munsell colour we are trying to print.  If the MunsellDataPoint vector only has
			  % one entry, then it is a grey, and will be ignored since this routine is for hue sheets
			  if length(MunsellDataPoint) > 1 	% Ignore greys
				  if MunsellDataPoint(1) == HuePrefix && MunsellDataPoint(2) == Value && ...
					  MunsellDataPoint(3) == Chroma && MunsellDataPoint(4) == CLHueLetter 
					  R = RGBdata(ctr, 1)		;
					  G = RGBdata(ctr, 2)		;
					  B = RGBdata(ctr, 3)		;
					  DE2000 = RGBdata(ctr, 4)	;
					  MunsellStringFound = true	;
				  end
			  end
			  ctr = ctr + 1	;
		  end
	  end
	  
	  % Draw Munsell sample, centered on the Cartesian point (Chroma, Value)
	  centerx = Chroma	;
	  centery = Value	;
	  cornerX = centerx + [-CVratio*SizePar/2,  CVratio*SizePar/2, CVratio*SizePar/2,...
						   -CVratio*SizePar/2, -CVratio*SizePar/2];
	  cornerY = centery + [ SizePar/2, SizePar/2, -SizePar/2,...
						   -SizePar/2, SizePar/2];	 
	  
	  % If the Munsell sample has been found in the conversion file, then R, G, and B values 
	  % will have been found.  If the sample matches the Munsell colour to the desired
	  % DE threshold, then the sample can be printed.  If the DE is not within the threshold,
	  % but the colour is on the list of colours where a threshold is not required, it can
	  % still be printed.  Otherwise, an empty box will be drawn where the colour would have been.
	  % This Munsell specification might also have been marked for non-printing, in which case an
	  % exclusion flag will have been set
	  
	  if MunsellStringFound == true && ExcludeMunsellString == false
	     if DE2000 <= DEthreshold
	        patch(cornerX, cornerY, [R, G, B], 'EdgeColor', [1 1 1]);
		    ColoursPrinted{end+1} = MunsellString	;	% Add to list of colours printed out
			RGBDe = [RGBDe; R, G, B, DE2000]		;
		 elseif ismember(MunsellString, NonThresholdMunsellSpecs)
	        patch(cornerX, cornerY, [R, G, B], 'EdgeColor', [1 1 1]);
		    ColoursPrinted{end+1} = MunsellString	;	% Add to list of colours printed out
			RGBDe = [RGBDe; R, G, B, DE2000]		;
			disp(['Munsell colour out of threshold: ',MunsellString,', DE is ', num2str(DE2000)]);
	     else
	        patch(cornerX, cornerY, [1 1 1], 'EdgeColor', [0 0 0]); 	% Print empty block
		 end
	  else
	     patch(cornerX, cornerY, [1 1 1], 'EdgeColor', [0 0 0]);	% Print empty block
	  end
	  hold on
   end
end

% Add text annotations on printed hue sheet
for ind = 1:9
	text(0.5,ind,num2str(ind))					;		% Value label
	hold on
end
for ind = 2:2:20
    if ind < 10
        adjustment = 0.3	;
	else
	    adjustment = 0.35	;
	end
	text(ind-adjustment,0.3,['/',num2str(ind)])	;		% Chroma label
	hold on
end

% Print label for hue sheet
PrefixString = sprintf('%3.1f', HuePrefix)		;	% '%3.1f' for 1 decimal place, '%4.2f' for 2 decimal places
HueString    = ColourLetters{CLHueLetter}		;
HueLabel     = [PrefixString, HueString]		;
% Print the label in the upper right corner, unless that would interfere with printing the
% colours, in which case the label should be placed in the bottom right corner.  This is
% necessary on the pages in the conditional statement
if strcmp(HueLabel,'5.0Y') || ...
   strcmp(HueLabel, '7.5Y') || ...
   strcmp(HueLabel, '10.0Y') || ...
   strcmp(HueLabel, '2.5GY') || ...
   strcmp(HueLabel, '5.0GY') || ...
   strcmp(HueLabel, '7.5GY') || ...
   strcmp(HueLabel, '10.0GY') || ...
   strcmp(HueLabel, '1.75GY')
	text(20+CVratio*SizePar/2,1,HueLabel,'Fontname', 'Times','Fontsize', 35, 'horizontalalignment', 'right')				;
else
	text(20+CVratio*SizePar/2,9,HueLabel,'Fontname', 'Times','Fontsize', 35, 'horizontalalignment', 'right')				;
end

% Format the hue sheet figure
set(gca, 'xlim', [-3 22], 'ylim', [0 10]);
set(gca, 'xcolor', [1 1 1], 'ycolor', [1 1 1])	;
set(gca, 'box', 'off')
set(gca, 'xtick', [], 'ytick', [])

return; 