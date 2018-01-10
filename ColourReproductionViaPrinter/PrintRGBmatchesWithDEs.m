function NumberOfPagesPrinted = PrintRGBmatchesWithDEs(RGB, ...
													   InputFigname, ...
													   StandardNames, ...
													   DEs, ...
													   inp_maxdown, ...
													   inp_maxacross);
% Purpose		Print a set of RGB triples that are the best matches to a set of standards.
%				Indicate the DE of each RGB triple, and the name of the standard it matches. 
%
% Description	This routine is intended to show visually how accurate a set of attempted
%				printed colour matches are.  There is assumed to be a set of standards,
%				whose names are an input, for which a set of printed matches, given by the
%				input variable RGB, has been produced.  The accuracy of those matches is
%				given by the input variable DEs, and is typically a CIE DE 2000 value.
%				A square of that RGB is printed out for each match; the standard name and
%				DE are written on that square.  The printed RGBs might span several pages. 
%				All pages will be saved automatically for further use.
%
%				RGB				A three-column matrix of RGB triples to be printed 
%
%				InputFigname	A figure name to be used when saving the printed figure
%
%				StandardNames 	A list (denoted by {}) of strings that give the names of 
%								the standards
%
%				DEs				A vector of DE values for each standard vs its RGB match
%
%				inp_max_down, inp_maxacross	The maximum number of blocks to print, both
%								down the page, and across the page.  The routine will
%								print as many pages as needed, within those constraints.
%								These inputs are optional.
%
%				NumberOfPagesPrinted	A returned variable that says how many pages were
%										printed
%
% Author		Paul Centore (September 24, 2014)
% Revision		Paul Centore (October 12, 2014)
%					Specified that labels be printed with Arial font
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

% Check if the calling routine specifies how many rows and columns should be printed
if nargin == 6	% User specifies number of rows and columns
    maxacross   = inp_maxacross			;
	maxdown     = inp_maxdown			;
	RGBsPerPage = maxacross * maxdown	;
else			% No user specification of rows and columns: use defaults
    RGBsPerPage = 108					;
	maxacross   = 9					;
end

[NumberOfRGBs,~] = size(RGB)	;
UnprintedRGB = RGB				;
pagectr = 0						;
while ~isempty(UnprintedRGB)    
	pagectr = pagectr + 1		;		

    figure
	set(gcf, 'Visible', 'on')    
	figname = [InputFigname,'Page',num2str(pagectr)]	;
    set(gcf, 'Name', figname)
    left = 1		;
    bottom = 1		;
    width = 6.5		;
    height = 9		;

    [NumOfColoursLeft, ~] = size(UnprintedRGB)					;
	if NumOfColoursLeft > RGBsPerPage
	    RGBforPrinting = UnprintedRGB(1:RGBsPerPage,:)			;
		UnprintedRGB   = UnprintedRGB((RGBsPerPage+1):end,:)	;
	else
	    RGBforPrinting = UnprintedRGB	;
		UnprintedRGB   = []				;
	end
	
    [NumOfColours, ~] = size(RGBforPrinting)				;		

    scalefactor = 1			;

    for index = 1:NumOfColours
%disp(['index: ', num2str(index)])
	    c = mod(index-1, maxacross)	;
	    r = floor((index-1)/maxacross) + 1	;
	    CornerX = scalefactor*[c-1, c-1, c, c, c-1] 	;
	    CornerY = scalefactor*[1-r, -r, -r, 1-r, 1-r]	;
        patch(CornerX, CornerY,...
			  RGBforPrinting(index,:),...
			  'Edgecolor', 'none');
        hold on
        
        % Print the labels in black for lighter colours, and in white for darker colours
	    scaledRGB = 255*RGBforPrinting(index,:)	;
	    [XYZ] = srgb2xyz(scaledRGB)	;
	    Y = XYZ(1,2) 			;
	    if Y < 0.18
			LabelColour = [1 1 1]	;
	    else
			LabelColour = [0 0 0]	;
	    end
	    if ~isempty(StandardNames)	% Only show names if names have been input
			text((CornerX(1) + CornerX(4))/2, 0.85*CornerY(1) + 0.15*CornerY(2), ...
			   StandardNames{(pagectr - 1)*RGBsPerPage + index},...
			   'horizontalalignment', 'center',...
			   'fontname', 'Arial', ...
			   'fontsize', 8, ...
			   'rotation', 0, ...
			   'color', LabelColour) 	;
			hold on
	    end
	    if ~isempty(DEs)	% Only show DEs if DEs have been input
			text((CornerX(1) + CornerX(4))/2, 0.65*CornerY(1) + 0.35*CornerY(2), ...
			   ['DE: ',sprintf('%3.1f',DEs((pagectr - 1)*RGBsPerPage + index))],...
			   'horizontalalignment', 'center',...
			   'fontname', 'Arial', ...
			   'fontsize', 8, ...
			   'rotation', 0, ...
			   'color', LabelColour) 	;
			hold on
	    end
    end

    set(gca, 'xlim', [-1 maxacross])		
    set(gca, 'ylim', [-(floor((RGBsPerPage-1)/maxacross) + 1) 0])		
    set(gca, 'Box','off')
    set(gca, 'xticklabel', [])
    set(gca, 'yticklabel', [])
    set(gca, 'xcolor', [1 1 1])
    set(gca, 'ycolor', [1 1 1])

    drawnow()		;
	fflush(stdout)	;
	
    print(gcf, [figname,'.eps'], '-depsc');
    print(gcf, [figname,'.png'], '-dpng');
    print(gcf, [figname,'.jpg'], '-djpg');
    print(gcf, [figname,'.pdf'], '-dpdf');
end

% Return the number of pages
NumberOfPagesPrinted = pagectr 	;