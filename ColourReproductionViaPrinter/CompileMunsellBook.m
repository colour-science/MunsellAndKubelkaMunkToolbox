function CompileMunsellBook(...
							RGBfile, ...
							DEthreshold, ...
							NonThresholdMunsellSpecs, ...
							ExcludedMunsellSpecs, ...
							DirectoryForSaving);
% Purpose		Compile a set of hue sheets for a Munsell book.
%
% Description	This routine is intended to assemble the hue sheets of a Munsell book.  It should be 
%				called once a list has been calculated of RGB triples for the Munsell
%				colours.  The routine will display all RGB triples that match the Munsell
%				aimpoint to within a DE threshold.  The threshold is measured by the CIE DE 2000
%				formula.  This routine can be slow, taking about 1.5 hours to assemble a complete
%				book.
%
%				Staying strictly with the DE threshold can leave some gaps in some hue sheets, so
%				a few colours should be printed even if they are outside the threshold.  These
%				colours must be set by hand in the variable NonThresholdMunsellSpecs.  The routine
%				will have to be run once to identify these gaps, and then a second time to fill
%				them.  Also, some colours that satisfy the DE threshold might not be printed,
%				because they are too far from other colours; these must also be set by hand, in
%				the variable ExcludedMunsellSpecs.
%
%				After the printing, a histogram of DEs will be displayed, along with some
%				summary statistics.
%
%				RGBfile		A text file that lists the best RGBs for a given Munsell specification.
%							Each row contains a Munsell spec, then its R value, its G value,
%							and its B value (RGB values are between 0 and 1), and finally
%							the DE 2000 to which that RGB matches the Munsell spec.
%
%				DEthreshold		Print all RGBs whose DE from a Munsell specification are
%								less than this threshold
%
%				NonThresholdMunsellSpecs	Munsell colours that are not within the threshold,
%											but that will leave a gap if not printed.  Print
%											these colours anyway, to avoid gaps.  This variable
%											is a list, indicated by {}
%
%				ExcludedMunsellSpecs	Do not print RGBs for these Munsell specifications, even if they 
%										meet the desired threshold.  This variable is a list,
%										indicated by {}
%
%				DirectoryForSaving	The directory in which results will be saved
%
% Author		Paul Centore (September 14, 2012)
% Revision		Paul Centore (December 10, 2014)
%				---Made several variables into input arguments
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

DisplayAndSaveDEData = true	;	% Flag for printing and saving DE results

% Print complete Munsell book
% ColorLab hue letters for Munsell specifications
ColourLetters = {'B', 'BG', 'G', 'GY', 'Y', 'YR', 'R', 'RP', 'P', 'PB'}	;

tic()
% Loop through hue sheets, producing and saving a figure for each one
NumberOfColoursPrinted = []	;	% Number of colours printed per page
AllColoursPrinted      = {}	;	% List of all colours printed
AllRGBDe               = []	;	% List of DEs of printed colours
for CLHueLetter = [7,6,5,4,3,2,1,10,9,8]
    for HuePrefix = [2.5, 5, 7.5, 10]
    
		% Create a figure for one hue sheet
        [ColoursPrinted, RGBDe, HueSheetFigure] = ...
						PrintMunsellHueSheetFromMunsellRGBList(...
		                          HuePrefix, ...
		                          CLHueLetter, ...
		                          RGBfile, ...
		                          DEthreshold, ...
								  NonThresholdMunsellSpecs, ...
								  ExcludedMunsellSpecs);
	    % Save returned figure for hue sheet
	    figuretitle = ['MunsellSheetFor',num2str(round(10*HuePrefix)),ColourLetters{CLHueLetter},'ForPrinting'];
		set(HueSheetFigure, 'Name', figuretitle);
		print(HueSheetFigure, [DirectoryForSaving,'/',figuretitle,'.eps'], '-depsc');
		print(HueSheetFigure, [DirectoryForSaving,'/',figuretitle,'.png'], '-dpng');
		print(HueSheetFigure, [DirectoryForSaving,'/',figuretitle,'.jpg'], '-djpg');
		print(HueSheetFigure, [DirectoryForSaving,'/',figuretitle,'.pdf'], '-dpdf');
		
		% To reduce the number of figures shown, make the figures not visible 
		set(gcf, 'visible', 'off')		

    	% Since this routine can be slow, keep the user informed as to which hues have
    	% been processed
		disp(['Munsell Hue: ', num2str(HuePrefix), num2str(ColourLetters{CLHueLetter}),...
			  ': ',num2str(length(ColoursPrinted)),' colours printed']);  
		fflush(stdout);
		
		% Maintain a list of colours printed and their DEs
		for ctr = 1:length(ColoursPrinted)    
		    AllColoursPrinted{end+1} = ColoursPrinted{ctr}	;
		end
		NumberOfColoursPrinted = [NumberOfColoursPrinted; length(ColoursPrinted)]	;
		AllRGBDe               = [AllRGBDe; RGBDe]									;
	end
end
toc()
disp(['Total number of colours printed: ', num2str(sum(NumberOfColoursPrinted))]);

if DisplayAndSaveDEData 		% Display and save DE data, if desired
	FileForSaving = [DirectoryForSaving,'/MunsellCompilationResults.mat']	;
	save(FileForSaving, '-v7', 'AllColoursPrinted', 'AllRGBDe')	;

	DE2000Differences = AllRGBDe(:,end);
	DE2000Differences = transpose(DE2000Differences);
	DEedgeVector = [0:0.2:4]							;
	DECounts     = histc(DE2000Differences, DEedgeVector)	;
	figure
	HistogramData = [DEedgeVector; DECounts];
	disp(['Number of DEs: ',num2str(length(DE2000Differences))]);
	disp(['Average, median, min, and max DE: ',...
		   num2str(mean(DE2000Differences)),', ',num2str(median(sort(DE2000Differences))),', ',...
		   num2str(min(DE2000Differences)),', ',num2str(max(DE2000Differences))])	;
	stairs(DEedgeVector, DECounts, 'k')							;
	set(gca, 'xlim', [0,4], 'ylim', [0,600])							;
	set(gcf, 'Name', ['DEsForCompleteMunsellBook'])
	figname = [DirectoryForSaving,'/DEsForCompleteMunsellBook']	;
	print(gcf, [figname,'.eps'], '-depsc');
	print(gcf, [figname,'.png'], '-dpng');
	print(gcf, [figname,'.jpg'], '-djpg');
	print(gcf, [figname,'.pdf'], '-dpdf');
end