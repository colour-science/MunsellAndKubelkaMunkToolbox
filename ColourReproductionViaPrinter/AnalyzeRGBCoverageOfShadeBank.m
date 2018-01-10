function MinDEs = AnalyzeRGBCoverageOfShadeBank(	...
		  	  		ShadeBankFile, 					...
		  	  		RandomRGBFile,					...
		  	  		IllumObs);
% Purpose		Analyze how closely a shade bank of printed colours covers the RGB cube.  
%
% Description   A shade bank for a printer gives the reflectance spectra for various RGBs,
%				when printed by that printer (assuming consistent printer settings, paper,
%				and ink).  A shade bank is often used to match colours as nearly as possible,
%				so a natural questions is how finely that shade bank covers the gamut of
%				printable colours.  This routine answers that question quantitatively.
%
%				The set of printable colours is defined by the RGB cube, which consists of
%				all possible triples of R, G, and B, each of which is between 0 and 1.
%				Suppose a valid RGB is chosen at random and printed.  Then one can find
%				the closest colour in the shade bank, that is, the shade bank colour such 
%				that the DE between that colour and the printed RGB is a minimum.  The
%				smaller the DE is, the better the match is.  
%
%				To quantify the overall coverage of the shade bank, a multitude of RGBs
%				can be chosen at random and printed, and a set of DEs can be found.  That
%				set can be considered as a probability distribution and examined statistically.
%				For example, it can be plotted as a histogram, the mean and median found,
%				and so on.  This routine performs just such operations, and returns relevant
%				data.
%
%				ShadeBankFile	Comma-separated file with header line giving wavelengths.  Subsequent
%								lines give RGB components, followed by reflectances.
%
%				RandomRGBFile	Comma-separated file with header line giving wavelengths.  Subsequent
%								lines give RGB components, followed by reflectances.
%
%				IllumObs	An illuminant/observer string, such as 'D50/2' or 'F12_64.' The
%							first part is a standard illuminant designation.  The symbol in the
%							middle can be either a forward slash or an underscore.  The number at
%							the end is either 2, 10, 31, or 64.  2 and 31 both correspond to the
%							standard 1931 2 degree observer, while 10 and 64 both correspond to 
%							the standard 1964 10 degree observer.  If no observer is indicated, then
%							the 1931 observer is assumed.  The input IllumObs is optional.
%
%				MinDEs	A vector of the minimum DEs achieved for each entry in the file of
%						random RGBs.
%
%				MeanDE, MedianDE, MaxDE		Summary statistics from the vector DEs, considered
%											as a probability distribution. 
%
% Author		Paul Centore (May 20, 2015)
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

% Set a flag to display a histogram of DEs, if desired
DisplayDEhistogram = true	;

% Default to Illuminant C with a 2 degree standard observer if no illuminant or observer 
% information is input
if ~exist('IllumObs')
    IllumObs = 'C/2'	;
end

% Read in the reflectances of the test set of random RGBs, and convert them to CIE
% colorimetric coordinates
[TestWavelengths, TestReflectances] = ColorMunkiCSVfileToOctaveFormat(RandomRGBFile);
CIEcoords = ReflectancesToCIEwithWhiteY100(TestWavelengths, TestReflectances, IllumObs)	;

% Read in the reflectances of the colours in the shade bank
[ShadeBankWavelengths, ShadeBankReflectances] = ColorMunkiCSVfileToOctaveFormat(ShadeBankFile);

% Loop through the random test points.  For each point, find the colour in the shade bank
% file whose DE from that test point is a minimum.  Store these minimum DEs in a vector
% called MinDEs.
NumberOfTestPoints = size(TestReflectances,1)	;
MinDEs = []	;
for ctr = 1:NumberOfTestPoints

	% This routine can be slow, so print out regular feedback about progress
	if mod(ctr,25)==0
		disp([num2str(ctr),' out of ',num2str(NumberOfTestPoints)])	;
		fflush(stdout)	;
	end
	
	% Extract one test colour, and find the DEs from that colour to each colour in the 
	% shade bank
	CIEXYZ = CIEcoords(ctr,1:3)	;
	[RankedIndices, DE2000] = EvaluateDEsToReflectanceSpectra(CIEXYZ, ...
								   ShadeBankWavelengths, ...
								   ShadeBankReflectances, ...
								   IllumObs);
	% Find the minimum DE, and store it in the output vector								   
	MinDE  = DE2000(1)			;
	MinDEs = [MinDEs; MinDE]	;
end																   

% Print out summary statistics
disp([num2str(size(ShadeBankReflectances,1)),' points in shade bank, ',num2str(NumberOfTestPoints),' test points']);
disp(['Mean     :    ',num2str(mean(MinDEs))])	;
disp(['Median   :    ',num2str(median(MinDEs))])	;
disp(['Standard Dev: ',num2str(std(MinDEs))])	;
disp(['Min     :     ',num2str(min(MinDEs))])		;
disp(['Max     :     ',num2str(max(MinDEs))])		;

% Print out information about worst cases
[SortedMinDEs, SortedIndices] = sort(MinDEs)	;
NumberOfBadCases = min(30,length(MinDEs))							;
TestNumbers      = SortedIndices(end:(-1):(end-NumberOfBadCases+1))	;
WorstDEs         = MinDEs(TestNumbers)								;
TestSpectra      = TestReflectances(TestNumbers,:)					;		
[MunsellSpecs, MunsellSpecsColorlab, CIEform] = ...
	ReflectanceSpectrumToMunsellAndCIE(TestWavelengths, TestSpectra);	
disp(['Worst Cases:'])	
disp(['DE	Case	Munsell Specification'])
for CaseCtr = 1:NumberOfBadCases
	disp([num2str(WorstDEs(CaseCtr)),'	', ...
		  num2str(TestNumbers(CaseCtr)), '	', ...
		  MunsellSpecs{CaseCtr}])
end

% Print out histogram of minimum DEs, if desired
if DisplayDEhistogram
	MaxX = 4	;
	EdgeVector = [0:0.25:MaxX]						;
	DistCounts = histc(MinDEs, EdgeVector)	;
	figure
	stairs(EdgeVector, DistCounts, 'k')				;
	set(gca, 'xlim', [0 MaxX])						;
	set(gca, 'ylim', [0 NumberOfTestPoints/3])		;
	set(gca, 'xtick', EdgeVector)

	FontName = 'Times New Roman'		;
	LabelFontSizeInPoints = 14	;
	LabelFontWeight = 'normal'	;
	xlabel('Minimum DE', ...
			 'fontname', FontName, ...
			 'fontweight', LabelFontWeight,...
			 'fontsize', LabelFontSizeInPoints)
	ylabel('Number of TestPoints',...
			 'fontname', FontName, ...
			 'fontweight', LabelFontWeight,...
			 'fontsize', LabelFontSizeInPoints)

	[pathstr,name,ext] = fileparts(ShadeBankFile)	;
	figname = [pathstr,'/MinDEsForCoverageTest']	;
	set(gcf, 'Name', figname)
	print(gcf, [figname,'.eps'], '-depsc')		;
	print(gcf, [figname,'.png'], '-dpng')		;
	print(gcf, [figname,'.jpg'], '-djpg')		;
	print(gcf, [figname,'.pdf'], '-dpdf')		;
end