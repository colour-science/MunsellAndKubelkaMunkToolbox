function CompileMunsellBook();
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
%				them.
%
%				After the printing, a histogram of DEs will be displayed, along with some
%				summary statistics.
%
% Syntax		CompileMunsellBook(); 
%
% Author		Paul Centore (September 14, 2012)
%
% Copyright 2012 Paul Centore
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

% Print complete Munsell book
% ColorLab hue letters for Munsell specifications
ColourLetters = {'B', 'BG', 'G', 'GY', 'Y', 'YR', 'R', 'RP', 'P', 'PB'}	;

% Munsell colours that are not within the threshold, but that will leave a
% gap if not printed.  This list will have to be remade every time a Munsell
% book is compiled.
NonThresholdMunsellSpecs = {'2.5R3/4',...
							'5YR8/2',...
							'2.5Y6/2',...
							'5BG3/8',...
							'7.5BG4/6',...
							'2.5PB4/6'} ;

tic()
DEthreshold = 2		;
NumberOfColoursPrinted = [];
AllColoursPrinted = {};
AllRGBDe = []		;
for CLHueLetter = [7,6,5,4,3,2,1,10,9,8]
    for HuePrefix = [2.5, 5, 7.5, 10]
disp(['Munsell Hue: ', num2str(HuePrefix), num2str(ColourLetters{CLHueLetter})]);
fflush(stdout);
        [ColoursPrinted, RGBDe] = PrintMunsellHueSheetFromMunsellRGBList(...
		                          HuePrefix, CLHueLetter, 'AllMunsellRGBlist.txt', DEthreshold, NonThresholdMunsellSpecs);
disp(['Munsell Hue: ', num2str(HuePrefix), num2str(ColourLetters{CLHueLetter}),...
      ': ',num2str(length(ColoursPrinted)),' colours printed']);  
	  for ctr = 1:length(ColoursPrinted)    
          AllColoursPrinted{end+1} = ColoursPrinted{ctr}	;
      end
fflush(stdout);
		NumberOfColoursPrinted = [NumberOfColoursPrinted; length(ColoursPrinted)]	;
		AllRGBDe               = [AllRGBDe; RGBDe]									;
	end
end
toc()
save('MunsellCompilationResults.mat', '-v7', 'AllColoursPrinted', 'AllRGBDe')	;
disp(['Total number of colours printed: ', num2str(sum(NumberOfColoursPrinted))]);

% Make plot of DEs for printed Munsell book
load('MunsellCompilationResults')

DE2000Differences = AllRGBDe(:,end);
DE2000Differences = transpose(DE2000Differences);

% Display DE histogram
DEedgeVector = [0:0.2:4]							;
DECounts     = histc(DE2000Differences, DEedgeVector)	;
figure
HistogramData = [DEedgeVector; DECounts];
AverageDE = mean(DE2000Differences)					;
MedianDE = median(sort(DE2000Differences))			;
disp(['Number of DEs: ',num2str(length(DE2000Differences))]);
disp(['Average, median, min, and max DE: ',...
       num2str(AverageDE),', ',num2str(MedianDE),', ',...
	   num2str(min(DE2000Differences)),', ',num2str(max(DE2000Differences))])	;
stairs(DEedgeVector, DECounts, 'k')							;
set(gca, 'xlim', [0,4], 'ylim', [0,500])							;
set(gcf, 'Name', ['DEsForCompleteMunsellBook'])
figname = ['DEsForCompleteMunsellBook']	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');
