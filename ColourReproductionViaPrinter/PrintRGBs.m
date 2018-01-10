function NumberOfPagesPrinted = PrintRGBs(RGB,...
										  InputFigname,...
										  inp_maxdown,...
										  inp_maxacross);
% Purpose		Print a set of RGB triples, to be measured. 
%
% Description	This routine is intended to be used when determining the RGBs needed to print
%				a Munsell book.  It prints a set of RGB triples, which can then be measured
%				with a spectrophotometer.  The measurements can be input into the program
%				that determines RGBs.  The printed RGBs might span several pages.  All
%				pages will be saved automatically for further use.
%
%				RGB				A three-column matrix of RGB triples to be printed 
%
%				InputFigname	A figure name to be used when saving the printed figure
%
%				inp_max_down, inp_maxacross		The maximum number of blocks to print, both
%								down the page, and across the page.  The routine will
%								print as many pages as needed, within those constraints.  
%								These inputs are optional
%
%				NumberOfPagesPrinted	A returned variable that says how many pages were
%										printed
%
% Author		Paul Centore (June 2012)
% Revision		Paul Centore (November 29, 2013)
%				---Added two optional inputs, so that the calling routine could specify the number
%				   of rows and columns to be printed on each page
% Revision		Paul Centore (January 20, 2014)
%				---Returned the number of pages that were printed
% Revision		Paul Centore (September 24, 2014)
%				---Replace print option -deps with -depsc, so that colours are handled correctly
% Revision		Paul Centore (June 27, 2015)
%				---Added option to place white border around printed squares
%
% Copyright 2012-2015 Paul Centore
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
if nargin == 4	% User specifies number of rows and columns
    maxacross   = inp_maxacross			;
	maxdown     = inp_maxdown			;
	RGBsPerPage = maxacross * maxdown	;
else			% No user specification of rows and columns: use defaults
    % These values are suitable when measuring colours with an i1i0 Automatic Scanning Table (AST)
    RGBsPerPage = 500					;
	maxacross   = 20					;
	
    % These values are suitable when measuring colours with a ColorMunki
    % RGBsPerPage = 216					;
	% maxacross   = 24					;
end

[NumberOfRGBs,~] = size(RGB)	;
UnprintedRGB = RGB				;
pagectr = 0						;
while ~isempty(UnprintedRGB)    
	pagectr = pagectr + 1				;

    figure
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
	
    [NumOfColours, ~] = size(RGBforPrinting)						;

    scalefactor = 1			;

	% Changed by Paul Centore on June 27, 2015, to add optional blank border around patches
	BorderFactor = 1.0	;	% Make BorderFactor 1 for no border; as BorderFactor goes towards 0,
							% the blank border gets larger
    for index = 1:NumOfColours
	    c = mod(index-1, maxacross)	;
	    r = floor((index-1)/maxacross) + 1	;
	    PatchCenter = [c-(1/2), (1/2)-r]	;
	    CornerxCoordsWithoutBorder = [c-1, c-1, c, c, c-1]		;
	    CorneryCoordsWithoutBorder = [1-r, -r, -r, 1-r, 1-r]	;
	    CornerxCoordsWithBorder = BorderFactor * CornerxCoordsWithoutBorder + ...
	                              (1-BorderFactor) * repmat(PatchCenter(1),1,5)	;
	    CorneryCoordsWithBorder = BorderFactor * CorneryCoordsWithoutBorder + ...
	                              (1-BorderFactor) * repmat(PatchCenter(2),1,5)	;
        patch(scalefactor*CornerxCoordsWithBorder,...
		      scalefactor*CorneryCoordsWithBorder,...
			  RGBforPrinting(index,:),...
			  'Edgecolor', 'none');
        hold on
    end
    % End change

    set(gca, 'xlim', [-1 maxacross])		
    set(gca, 'ylim', [-r 0])		
    set(gca, 'Box','off')
    set(gca, 'xticklabel', [])
    set(gca, 'yticklabel', [])

    drawnow()		;
	fflush(stdout)	;
	
    print(gcf, [figname,'.eps'], '-depsc');
    print(gcf, [figname,'.png'], '-dpng');
    print(gcf, [figname,'.jpg'], '-djpg');
    print(gcf, [figname,'.pdf'], '-dpdf');
end

% Return the number of pages
NumberOfPagesPrinted = pagectr 	;