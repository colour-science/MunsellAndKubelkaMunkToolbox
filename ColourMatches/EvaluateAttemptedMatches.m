function DE2000Differences = EvaluateAttemptedMatches(AimPointsXYZ, SamplesInXYZ, Name, AimPointsInMunsell);
% Purpose		To produce graphs and statistics about how well a set of samples
%				matches a set of aimpoints.
%
% Description	This routine compares a set of colour samples to a set of
%				aimpoints.  The two inputs must be of the same size, and in the
%				same order.  The routine was originally for printed colour samples
%				that were trying to match Munsell aimpoints, but can be used for more
%				general situations, too.
%
%				Nine plots are output, and their data saved to an output file.  The
%				first plot is a histogram of the differences between the samples and
%				the aimpoints, measured with respect to the CIE DE 2000 colour difference
%				formula.
%
%				The next three plots test whether there are any biases in chroma, value
%				or hue.  The chroma, value, and hue differences for samples and their
%				corresponding aimpoints are calculated, in terms of Munsell units, and
%				histograms are calculated.  The calculations take the form
%
%							sample - aimpoint.
%
%				The remaining plots are scatterplots that look for relationships between
%				hue, chroma, value, DE, and hue difference.
%
%				To perform the calculations, it is necessary to convert the sample measurements
%				to Munsell coordinates.  This calculation can be time-consuming, so the
%				results are saved for future reference.
%
% Syntax		EvaluateAttemptedMatches(AimPointsXYZ, SamplesInXYZ);
%
%				AimPointsXYZ		A set of colours, expressed in CIE XYZ coordinates, for which
%									matches are trying to be produced.  This is a matrix of 3
%									columns.  Each row of the matrix is a colour, in XYZ coordinates.
%
%				SamplesInXYZ		A set of attempted matches, in CIE XYZ coordinates, for the input
%									aimpoints.  This is a matrix of 3
%									columns.  Each row of the matrix is a colour, in XYZ coordinates.
%
%				Name				An optional input string to be used for identifying saved plot data.
%
%				AimPointsInMunsell	An optional list of the aimpoints, in Munsell specifications instead of
%									XYZ format.  This will save time in conversions.
%
%				DE2000Differences	A vector of the DE00 differences between the sample colours
%									and their aim points
%
% Required		CIEDE2000ForXYZ, xyYtoMunsell, MunsellHueToASTMHue
% Functions		
%
% Author		Paul Centore (November 9, 2012)
% Revision		Paul Centore (August 31, 2013)  
%				---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
% Revised		Paul Centore (January 1, 2014)
%				---Calculated white point for Illuminant C and 2 deg observer, and passed to revised
%				   routine for calculating CIE DE 2000
% Revised		Paul Centore (May 30, 2016)
%				---Made colour differences into output argument
%
% Copyright 2012, 2014, 2016 Paul Centore
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

% Check the inputs.  If no name is assigned, use a default 
if exist('Name') ~= 1
    Name = 'Temp'					;
end

[NumberOfAimpoints,~] = size(AimPointsXYZ)	;
% Calculate the differences between each aimpoint, and the sample that should match it
DE2000Differences = []						;
% For each sample, calculate CIEDE2000 for that sample and the standard
for ind = 1:NumberOfAimpoints
    % Revised January 1, 2014, to use white point explicitly
    WhitePointXYZ = WhitePointWithYEqualTo100('C/2')									;
	DE2000 = CIEDE2000ForXYZ(AimPointsXYZ(ind,:), SamplesInXYZ(ind,:), WhitePointXYZ)	;
    DE2000Differences = [DE2000Differences, DE2000]						;
end

% Display DE histogram
DEedgeVector = [0:0.25:25]							;
DECounts     = histc(DE2000Differences, DEedgeVector)	;
figure
HistogramData = [DEedgeVector; DECounts];
AverageDE = sum(((DEedgeVector(1:(end-1))+DEedgeVector(2:end))/2) .* DECounts(1:(end-1)))/...
		    sum(DECounts(1:(end-1)))						;
MedianDE = median(sort(DE2000Differences))			;
disp(['Number of DEs: ',num2str(length(DE2000Differences))]);
disp(['Average, median, min, and max DE: ',...
       num2str(AverageDE),', ',num2str(MedianDE),', ',...
	   num2str(min(DE2000Differences)),', ',num2str(max(DE2000Differences))])	;
stairs(DEedgeVector, DECounts, 'k')							;
set(gca, 'xlim', [0,3], 'ylim', [0,80])	;	%set(gca, 'xlim', [0,12], 'ylim', [0,200])
set(gcf, 'Name', ['DEsBetweenAimpointsAndAttemptedMatches',Name])
figname = ['DEsBetweenAimpointsAndAttemptedMatches',Name]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');
return		% This statement can be removed if a detailed Munsell analysis is needed

% Convert XYZ aimpoints to Munsell and ColorLab coordinates, unless this has already been done
FileName = ['MunsellAimPointsInColorLab',Name,'.mat']		;
AimPointsInColorLab = []	;
[NumberOfAimPoints,~] = size(AimPointsXYZ)			;
if exist('AimPointsInMunsell')		% A list of aimpoints in ColorLab coordinates has been input
    for ctr = 1:NumberOfAimpoints
        MunsellSpecString     = AimPointsInMunsell{ctr}							;
        ColorLabMunsellVector = MunsellSpecToColorLabFormat(MunsellSpecString)	;
		if length(ColorLabMunsellVector) == 1		% Colour is neutral grey
		    ColorLabMunsellVector = [0 ColorLabMunsellVector 0 7]	;
		end
	    AimPointsInColorLab   = [AimPointsInColorLab; ColorLabMunsellVector]	;
    end
    save('-v7', FileName, 'AimPointsInColorLab')			;
end
if isempty(which(FileName))		% Munsell aimpoints not saved, so calculate and then save
	for ctr = 1:NumberOfAimPoints
if mod(ctr,50) == 0
    disp([num2str(ctr),' Munsell conversions of ',num2str(NumberOfAimPoints)]);
	fflush(stdout);
end
	    X = AimPointsXYZ(ctr,1)			;
	    Y = AimPointsXYZ(ctr,2)			;
	    Z = AimPointsXYZ(ctr,3)			;
		
		% Convert from XYZ to xyY coordinates
	    [x, y, Yrel] = XYZ2xyY(X, Y, Z)	;

        % Convert to Munsell coordinates
        [MunsellSpec MunsellVec Status] = xyYtoMunsell(x, y, Yrel);
	    if Status.ind ~= 1		% Conversion to Munsell specification failed
	        MunsellSpec = 'NA'									;
		    disp(['Failure to convert from xyY to Munsell; xyY:',num2str(x),', ',num2str(y),', ',num2str(Yrel)])	;
	    end

	   	% AimPointsInColorLab is a 4-column matrix, with one row for each reflectance spectrum.  The
	    % row entries are the Munsell specification in ColorLab format.  If the colour is not neutral,
	    % the ColorLab format has 4 entries.  If the colour is neutral, the ColorLab format has only
	    % 1 entry.  In order to make one matrix, with 4 entries in each row, convert the 1-element
	    % neutral format into a 4-element format.
	    if strcmp(MunsellSpec, 'NA')  % No Munsell conversion found
		    AimPointsInColorLab(ctr,:) = [-99 -99 -99 -99]	;
	    elseif length(MunsellVec) == 1		
	        AimPointsInColorLab(ctr,:) = [0 MunsellVec 0 7];
	    else
	        AimPointsInColorLab(ctr,:) = [MunsellVec]		;
	    end
	end
    save('-v7', FileName, 'AimPointsInColorLab')			;
else
    load(FileName)		;
end

[NumberOfAimPoints,~] = size(AimPointsXYZ)			;
ConversionCtr = 0	;
for ind = 1:NumberOfAimPoints
   if AimPointsInColorLab(ind,1) ~= -99
       ConversionCtr = ConversionCtr + 1	;
   end
end
disp(['Number of aimpoints converted to ColorLab: ', num2str(ConversionCtr)])	;

% Convert sample points to Munsell coordinates and ColorLab, unless this has already been done
FileName = ['MunsellSamplesInColorLab',Name,'.mat']		;
if isempty(which(FileName))		% Munsell aimpoints not saved, so calculate and then save
    SamplesInColorlab = []							;
    [NumberOfAimPoints,~] = size(SamplesInXYZ)		;
	for ctr = 1:NumberOfAimPoints
if mod(ctr,50) == 0
    disp([num2str(ctr),' Munsell conversions of ',num2str(NumberOfAimPoints)]);
	fflush(stdout);
end
	    X = SamplesInXYZ(ctr,1)			;
	    Y = SamplesInXYZ(ctr,2)			;
	    Z = SamplesInXYZ(ctr,3)			;
		
		% Convert from XYZ to xyY coordinates
	    [x, y, Yrel] = XYZ2xyY(X, Y, Z)	;

        % Convert to Munsell coordinates
        [MunsellSpec MunsellVec Status] = xyYtoMunsell(x, y, Yrel);
	    if Status.ind ~= 1		% Conversion to Munsell specification failed
	        MunsellSpec = 'NA'									;
		    disp(['Failure to convert from xyY to Munsell; xyY:',num2str(x),', ',num2str(y),', ',num2str(Yrel)])	;
	    end

	   	% SamplesInColorlab is a 4-column matrix, with one row for each reflectance spectrum.  The
	    % row entries are the Munsell specification in ColorLab format.  If the colour is not neutral,
	    % the ColorLab format has 4 entries.  If the colour is neutral, the ColorLab format has only
	    % 1 entry.  In order to make one matrix, with 4 entries in each row, convert the 1-element
	    % neutral format into a 4-element format.
	    if strcmp(MunsellSpec, 'NA')  % No Munsell conversion found
		    SamplesInColorlab(ctr,:) = [-99 -99 -99 -99]	;
	    elseif length(MunsellVec) == 1		
	        SamplesInColorlab(ctr,:) = [0 MunsellVec 0 7];
	    else
	        SamplesInColorlab(ctr,:) = [MunsellVec]		;
	    end
	end
    save('-v7', FileName, 'SamplesInColorlab')			;
else
    load(FileName)	;
end

ConversionCtr = 0	;
for ind = 1:NumberOfAimPoints
   if SamplesInColorlab(ind,1) ~= -99
       ConversionCtr = ConversionCtr + 1	;
   end
end
disp(['Number of sample points converted to ColorLab: ', num2str(ConversionCtr)])	;

ValueDiffs  = []	;
ChromaDiffs = []	;
HueDiffs    = []	;
ChrHueDiff  = []	;
ValVsDE     = []	;
ChrVsDE     = []	;
HueVsDE     = []	;
HueVsHueShift=[]	;
for ctr = 1:NumberOfAimpoints
    if AimPointsInColorLab(ctr,2) ~= -99 & SamplesInColorlab(ctr,2) ~= -99	
        ValueDiffs  = [ValueDiffs;...
		               SamplesInColorlab(ctr,2) - AimPointsInColorLab(ctr,2)] 	;
        ChromaDiffs = [ChromaDiffs;...
					   SamplesInColorlab(ctr,3) - AimPointsInColorLab(ctr,3)] 	;
		ValVsDE     = [ValVsDE;...
		               AimPointsInColorLab(ctr,2), DE2000Differences(ctr)]		;
		ChrVsDE     = [ChrVsDE;...
		               AimPointsInColorLab(ctr,3), DE2000Differences(ctr)]		;
					   
		% Calculate hue difference, but only for non-neutral colours
		if SamplesInColorlab(ctr,3) ~= 0 & AimPointsInColorLab(ctr,3) ~= 0
		    SampleASTMhue = MunsellHueToASTMHue(SamplesInColorlab(ctr,1),   SamplesInColorlab(ctr,4))	;
			if SampleASTMhue == 100		% Avoid problems with wraparound
			    SampleASTMhue = 0	;
			end
		    AimPntASTMhue = MunsellHueToASTMHue(AimPointsInColorLab(ctr,1), AimPointsInColorLab(ctr,4))	;
			if AimPntASTMhue == 100		% Avoid problems with wraparound
			    AimPntASTMhue = 0	;
			end
			RawHueDiff    = SampleASTMhue - AimPntASTMhue		;
			if abs(RawHueDiff) <= 50
				WraparoundHueDiff = RawHueDiff			;
			elseif RawHueDiff > 50
			    WraparoundHueDiff = -(100 - RawHueDiff)	;
			else		% i.e. RawHueDiff < -50
			    WraparoundHueDiff = - RawHueDiff - 100	;
			end 
			MunsellHueDiff =  WraparoundHueDiff			;	
			HueDiffs = [HueDiffs;...
			            MunsellHueDiff]					;
			ChrHueDiff = [ChrHueDiff;...
			              AimPointsInColorLab(ctr,3), MunsellHueDiff]		;
			HueVsDE  = [HueVsDE;...
			            AimPntASTMhue, DE2000Differences(ctr)	]		;
			HueVsHueShift = [HueVsHueShift;...
			                 AimPntASTMhue, MunsellHueDiff]	;
		end
    end
end

% Display value difference histogram
ValueEdgeVector = [-2:0.1:2.1]							;
ValueCounts     = histc(ValueDiffs', ValueEdgeVector)	;	%'
figure
HistogramData = [ValueEdgeVector; ValueCounts];
AverageVD = sum(((ValueEdgeVector(1:(end-1))+ValueEdgeVector(2:end))/2) .* ValueCounts(1:(end-1)))/...
		    sum(ValueCounts(1:(end-1)))						;
MedianVD = median(sort(ValueDiffs))			;
disp(['Number of value differences: ',num2str(length(ValueDiffs))]);
disp(['Average, median, min, and max value difference: ',...
       num2str(AverageVD),', ',num2str(MedianVD),', ',num2str(min(ValueDiffs)),', ',num2str(max(ValueDiffs))])	;
disp(['Average, median, min, and max absolute value difference: ',...
       num2str(mean(abs(ValueDiffs))),', ',num2str(median(abs(ValueDiffs))),', ',...
	   num2str(min(abs(ValueDiffs))),', ',num2str(max(abs(ValueDiffs)))])	;
stairs(ValueEdgeVector, ValueCounts, 'k')							;
hold on
%plot([0,0],[0, 200], 'k--');
set(gca, 'xlim', [-2,2])							;
set(gcf, 'Name', ['ValueDiffsBetweenAimpointsAndAttemptedMatches',Name])
figname = ['ValueDiffsEsBetweenAimpointsAndAttemptedMatches',Name]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');

% Display chroma difference histogram
ChromaEdgeVector = [-6:0.25:6]							;
ChromaCounts     = histc(transpose(ChromaDiffs), ChromaEdgeVector)	;
figure
HistogramData = [ChromaEdgeVector; ChromaCounts];
AverageCD = sum(((ChromaEdgeVector(1:(end-1))+ChromaEdgeVector(2:end))/2) .* ChromaCounts(1:(end-1)))/...
		    sum(ChromaCounts(1:(end-1)))						;
MedianCD = median(sort(ChromaDiffs))			;
disp(['Number of chroma differences: ',num2str(length(ChromaDiffs))]);
disp(['Average, median, min, and max chroma difference: ',...
       num2str(AverageCD),', ',num2str(MedianCD),', ',num2str(min(ChromaDiffs)),', ',num2str(max(ChromaDiffs))])	;
disp(['Average, median, min, and max absolute chroma difference: ',...
       num2str(mean(abs(ChromaDiffs))),', ',num2str(median(abs(ChromaDiffs))),', ',...
	   num2str(min(abs(ChromaDiffs))),', ',num2str(max(abs(ChromaDiffs)))])	;
stairs(ChromaEdgeVector, ChromaCounts, 'k')							;
hold on
%plot([0,0],[0, 200], 'k--');
set(gca, 'xlim', [-6,6])							;
set(gcf, 'Name', ['ChromaDiffsBetweenAimpointsAndAttemptedMatches',Name])
figname = ['ChromaDiffsEsBetweenAimpointsAndAttemptedMatches',Name]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');

% Display hue difference histogram
HueEdgeVector = [-15:0.5:15]							;
HueCounts     = histc(transpose(HueDiffs), HueEdgeVector)	;
figure
HistogramData = [HueEdgeVector; HueCounts];
AverageCD = sum(((HueEdgeVector(1:(end-1))+HueEdgeVector(2:end))/2) .* HueCounts(1:(end-1)))/...
		    sum(HueCounts(1:(end-1)))						;
MedianCD = median(sort(HueDiffs))			;
disp(['Number of hue differences: ',num2str(length(HueDiffs))]);
disp(['Average, median, min, and max hue difference: ',...
       num2str(AverageCD),', ',num2str(MedianCD),', ',num2str(min(HueDiffs)),', ',num2str(max(HueDiffs))])	;
disp(['Average, median, min, and max absolute hue difference: ',...
       num2str(mean(abs(HueDiffs))),', ',num2str(median(abs(HueDiffs))),', ',...
	   num2str(min(abs(HueDiffs))),', ',num2str(max(abs(HueDiffs)))])	;
stairs(HueEdgeVector, HueCounts, 'k')							;
hold on
%plot([0,0],[0, 200], 'k--');
set(gca, 'xlim', [-15,15])							;
set(gcf, 'Name', ['HueDiffsBetweenAimpointsAndAttemptedMatches',Name])
figname = ['HueDiffsBetweenAimpointsAndAttemptedMatches',Name]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');

MaxDEforDisplay = 25	;
% Display scatterplot of hue vs DE
figure
plot(HueVsDE(:,1), HueVsDE(:,2), 'k*')
hold on
set(gca, 'xlim', [0,100])		
set(gca, 'xtick', [5:10:95])
set(gca, 'xticklabel', [' 5R';'5YR';' 5Y';'5GY';' 5G';'5BG';' 5B';'5PB';' 5P';'5RP']);
set(gca, 'ylim', [0,MaxDEforDisplay])						;
set(gcf, 'Name', ['HueVsDE',Name])
figname = ['HueVsDE',Name]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');

% Display scatterplot of value vs DE
figure
plot(ValVsDE(:,1), ValVsDE(:,2), 'k*')
hold on
set(gca, 'xlim', [0,10])		
set(gca, 'xtick', [0:1:10])
set(gca, 'ylim', [0,MaxDEforDisplay])						;
set(gcf, 'Name', ['ValVsDE',Name])
figname = ['ValVsDE',Name]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');

% Display scatterplot of chroma vs DE
figure
plot(ChrVsDE(:,1), ChrVsDE(:,2), 'k*')
hold on
set(gca, 'xlim', [0,20])		
set(gca, 'xtick', [0:2:20])
set(gca, 'ylim', [0,MaxDEforDisplay])						;
set(gcf, 'Name', ['ChrVsDE',Name])
figname = ['ChrVsDE',Name]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');

% Display scatterplot of hue vs hue difference
figure
plot(HueVsHueShift(:,1), HueVsHueShift(:,2), 'k*')
hold on
plot([0,100],[0, 0], 'k-');
set(gca, 'xlim', [0,100])		
set(gca, 'xtick', [5:10:95])
set(gca, 'xticklabel', [' 5R';'5YR';' 5Y';'5GY';' 5G';'5BG';' 5B';'5PB';' 5P';'5RP']);
set(gca, 'ylim', [-15,15])						;
set(gcf, 'Name', ['HueVsHueDifference',Name])
figname = ['HueVsHueDiff',Name]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');

% Display scatterplot of chroma vs hue difference
figure
plot(ChrHueDiff(:,1), ChrHueDiff(:,2), 'k*')
hold on
plot([0,200],[0, 0], 'k-');
set(gca, 'xlim', [0,20])		
set(gca, 'ylim', [-5,5])						;
set(gcf, 'Name', ['HueDifferenceVsChroma',Name])
figname = ['HueDifferenceVsChroma',Name]	;
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');

% Save off plotting data, for plotting by other routines
save('-v7', [Name,'plotdata.mat'], 'DE2000Differences',...
                                   'DEedgeVector', 'DECounts',...
								   'ValueEdgeVector', 'ValueCounts', 'ValueDiffs',...
								   'ChromaEdgeVector', 'ChromaCounts', 'ChromaDiffs',...
								   'HueEdgeVector', 'HueCounts', 'HueDiffs',...
								   'HueVsDE', 'ValVsDE', 'ChrVsDE',...
								   'ChrHueDiff', 'HueVsHueShift')				;