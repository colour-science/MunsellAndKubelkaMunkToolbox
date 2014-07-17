function [RGBresults, FinalWavelengths] = ...
          PrintReproductionsOfColours(AimPointsxyY, DEthreshold, IllumObs, Name, ShadeBankFile);
% Purpose		Determine the RGBs needed to match a set of input aimpoints, under an input
%				illuminant and observer.  The RGBs will be specific to the printer used to
%				print the colour matches.
%
% Description	This routine is intended to determine the RGBs needed to print a desired
%				surface colour, under input viewing conditions.  The routine was originally
%				intended to print a Munsell book, so this routine is a modified version of
%				an earlier routine, PrintAMunsellBook.m.  The earlier routine assumed that
%				the user was measuring printed colours with a ColorMunki spectrophotometer.
%				This routine still allows for a ColorMunki, but also allows an i1i0
%				automatic scanning table (AST), equipped with an i1Pro2 spectrophotometer.
%
%				The write-up, "How To Print A Munsell Book," gives
%				details of the algorithm used.  The algorithm is iterative.  An initial
%				shade bank of RGBs is established (or read in), by printing a wide variey 
%				of RGBs, and measuring them with a spectrophotometer.
%				Estimates are made, via linear interpolation in L*a*b* coordinates, of RGBs
%				that are likely to match the aimpoints.  These too are printed and
%				measured.  The new measurements indicate further RGBs to evaluate, that
%				should be in the vicinity of the aimpoints.  These are printed and
%				measured, and used to make further estimates of the RGBs for the aimpoints.
%				The new estimates are printed and measured, more information is gathered
%				about the vicinity, and so on.  The algorithm terminates when an RGB
%				differs from an aimpoint by less than an input colour difference threshold
%				(measured with respect to DE 2000).
%
% 			    This routine is a modification of an earlier routine, PrintAMunsellBook.m.  The
%				original routine assumed a C/2 illuminant-observer combination (because that is what
%				the Munsell renotation is standardized on).  The current routine can still print
%				a Munsell book, if xyY coordinates for Munsell colours are input.  Another
% 				change is that the original routine assumed that colour measurements were made
%				with an X-Rite ColorMunki spectrophotometer.  This new version can still use
%				the ColorMunki, but can also use the X-Rite i1Pro2 spectrophotometer (which might
%				be installed on an automatic scanning table).  
%
%				AimPointsxyY	A three-column matrix of xyY coordinates for aimpoint surface
%								colours.  The xyY coordinates should be consistent with the
%								input illuminant-observer combination
%
%				DEthreshold		The desired maximum perceptual difference between a printed
%								RGB and an aimpoint, measured with respect to DE 2000
%
%				IllumObs		An illuminant/observer string, such as 'D50/2' or 'F12/10,' under
%								which the colour matches are to be made
%
%				Name			A string used to label output files
%
%				ShadeBankFile	Comma-separated file with header line giving wavelengths.  Subsequent
%								lines give RGB components, followed by reflectances.  This input
%								argument is optional
%
%				RGBresults		A matrix of information about the success of matching, including
%								RGBs that correspond to the xyY aimpoints
%
%				FinalWavelengths	The wavelengths corresponding to the reflectance data given in
%									RGBresults
%
% Author		Paul Centore (January 1, 2014)
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

% Express aimpoints in XYZ and L*a*b* as well as xyY
AimPointsXYZ = []			;
[row,~] = size(AimPointsxyY);
for ind = 1:row
    [X Y Z] = xyY2XYZ(AimPointsxyY(ind,1), AimPointsxyY(ind,2), AimPointsxyY(ind,3))	;
    AimPointsXYZ = [AimPointsXYZ; X Y Z];
end
WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs)	;
AimPointsLab  = xyz2lab(AimPointsXYZ, WhitePointXYZ)	;
	
% Make matrix of results for aim points.  The matrix has the following columns
% Case Number | AimPoint (x|y|Y) | XYZ | Status | Current (R|G|B) | x_RGB | y_RGB | Y_RGB | AimPoint (Lab) | CIE DE (2000)
% There are three values for Status:
StatusFound       = 1	;
StatusNotFoundYet = 0	;
StatusOutOfGamut  = -1	;

% Fill matrix as much as possible
[NumberOfAimPoints,~]		= size(AimPointsxyY)				;
AimPointResults				= -99 * ones(NumberOfAimPoints,18)	;
AimPointResults(:,1)		= 1:NumberOfAimPoints				;
AimPointResults(:,2:4)		= AimPointsxyY						;
AimPointResults(:,5:7)		= AimPointsXYZ						;
AimPointResults(:,8)		= StatusNotFoundYet					;
AimPointResults(:,15:17)	= AimPointsLab						;

% For testing, it is sometimes easier to run the program without pauses for
% the user to print and measure colour samples.  When running the program, of course,
% the pauses are necessary.  Set the following flag to "false" to disable the pauses, 
% for testing.
UsePauses = true	;	

% The initial shade bank will be considered the first iteration.  Set a 
% maximum number of iterations, after which the algorithm automatically terminates.
iteration     = 1				;
MaxIterations = 8				;

% If desired, display a histogram of the best DEs achieved at various points in the
% algorithm.
DisplayBestDEHistogram = true		;

% If desired, display a histogram of edge lengths (in CIE DE 2000 values) after
% each tessellation, to monitor progress.
DisplayEdgeLengthHistogram = false	;

% If desired, display a histogram of the differences (in CIE DE 2000 values) between
% aimpoints and tetrahedrons that should enclose them.
DisplayInternalDEHistogram = false	;

% Eliminate any slashes from the input illuminant/observer string, to avoid slashes in file names
IllumObsNoSlashes = IllumObs	;
for ctr = 1:length(IllumObs)
    if strcmp(IllumObs(ctr),'/') || strcmp(IllumObs(ctr),'\')
	    IllumObsNoSlashes(ctr) = '_'	;
	end
end

% Create an initial shade bank.  If a shade bank is already available,
% then that can be used by calling it [Name,'Iteration1.csv'], and placing
% it in the current directory.  If the user has input a shade bank file to be used
% as a starting point, then convert it to .csv format, and call the file
% [Name,'Iteration1.csv'].  Also extract the list of RGBs from the file.
if exist('ShadeBankFile')
    RGB = ProcessInitialShadeBankFile(ShadeBankFile, [Name,'Iteration1.csv']);
else % No shade bank file was input, so create it from measurements of a set of RGBs
    % Choose a lattice of RGB colours for the initial shade bank.  NumOfDiv refers
    % to the number fo evenly spaced R, G, and B values.  If NumOfDiv is 10 (which is
    % usually sufficient), then there will be 1000 (which equals 10^3) RGB triples
    % in the lattice.  Since most computer programs store an RGB as 3 bytes, and a byte
    % has 256 values, round the lattice entries to the nearest integer multiple of 1/255.
    NumOfDiv = 30											;
    CombsWithRepetition = combinator(NumOfDiv, 3, 'p', 'r')	;
    RGB = (1/(NumOfDiv-1))*(CombsWithRepetition-1)			;
    RGB = (1/255) * round(255 * RGB)						;	

    % Produce a figure, that is displayed on the monitor, with those RGBs.
    % To save the time taken to display figures on the screen, skip the display
    % step if the colours to be displayed have already been printed and measured.
    OutputFile = [Name,'Iteration1.csv']			;
    if isempty(which(OutputFile))
        PrintRGBs(RGB, [Name,'ShadeIteration1'])	;
    end
end

% During the pause, print the figure using the printer and paper of interest.
% Then measure the printed colours with a spectrophotometer, in the same order in
% which they appear in the matrix InterpolatedRGBinGamut.  If the spectrophotometer is a
% ColorMunki, then click File:Export on the ColorMunki
% window, and choose "Comma separated" as the file type.  Export to a
% file named "Iteration_x_.csv" in the current directory, where _x_ is the current iteration.
% If the spectrophotometer is an i1i0 AST, equipped with an i1Pro2, then save to a file
% named "Iteration_x_Curr_M2.txt" in the current directory.  This file will then be
% converted to a .csv file in ColorMunki format.
disp(['During the pause, print the figure using the printer and paper of interest.'])	;
disp(['The printed colours are attempted matches for some of the input aimpoints.'])	;
disp(['Measure the printed colours in the order in which they appear.  Use either a ColorMunki,'])	;
disp(['or an i1i0 Automatic Scanning Table (AST), equipped with an i1Pro2 spectrophotometer.']);
disp(['If using the AST with the i1Pro2, there should be ',num2str(size(RGB,1))]);
disp(['colours in the saved .txt file.  When saving, choose 0.0 to 1.0 as the reflectance range, and']);
disp(['a decimal point as a separator.  Export to a file named "',Name,'Iteration',num2str(iteration),'Curr_M2.txt"']);
disp(['in the current directory.  (The i1i0 will automatically append _M2 to the chosen file name.)']); 
disp(['If the printed samples are measured with a ColorMunki, then there should be']) 
disp([num2str(size(RGB,1)),' colours in the ColorMunki folder.  ',...
      'Click File:Export on the ColorMunki'])	;
disp(['window, and choose "Comma separated" as the file type.  Export to a'])	;
disp(['file named "',Name,'Iteration',num2str(iteration),'.csv" in the current directory.  Once the file is saved,'])	;
disp(['press the "y" key (or any other key) to resume the program.'])					;
temp = fflush(stdout);
if UsePauses
    pause()										;
end
			
% The measurement data will be stored in a CSV file with the following name:	
CSVfileName = [Name,'Iteration',num2str(iteration),'.csv'] 	;
% If the colours were measured with a ColorMunki, then they will have been stored
% directly in such a file.  If they were measured with an i1i0, equipped with an i1Pro2
% spectrophotometer, then the measurements will have been stored in a file of a different
% format, which must be converted to a .csv format.
% Check whether a .csv file has already been saved by the user.  If not, convert the
% i1i0 file to .csv format. 
if isempty(which(CSVfileName))
    % Convert an i1i0 .txt file
    NewFileName = [Name,'Iteration',num2str(iteration),'Curr_M2.txt']	;
    [EntriesGreaterThan1, EntriesLessThan0] = ...
       i1i02txtFileToColorMunkiCSVFormat(NewFileName)	;
    ListOfColorMunkiCSVfiles{1} = [NewFileName(1:(end-3)),'csv']	;
    % Since there is only one file, the following 'concatenation' just makes a copy of 
    % that file, with a different name
    ConcatenateColorMunkiCSVFiles(ListOfColorMunkiCSVfiles, CSVfileName);
end
 
% Each printed RGB specification will have a reflectance spectrum, which has been
% measured by the spectrophotometer.  By assuming the input illuminant and
% observer, convert the reflectance spectrum to  an xyY.  
% First, extract the reflectance data
[Wavelengths, NewReflectances] = ColorMunkiCSVfileToOctaveFormat(CSVfileName);
% Then, extract xyY and XYZ values from the reflectance data
CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, NewReflectances, IllumObs);
XYZ = CIEcoords(:,1:3)										;
xyY = CIEcoords(:,4:6)										;
	
% Collate all the data into a shade bank
ShadeBankData = [RGB, xyY, NewReflectances]		;
	
% Then, save the shade bank data in a file called 'ShadeBank'
ShadeBankFileName = [Name,IllumObsNoSlashes,'ShadeBank.txt']			;
output_fid = fopen(ShadeBankFileName, 'w')	;
% The first line of a shade bank file is fixed, so it is written directly to the file
FirstOutputLine = ['R,G,B,380 nm,390 nm,400 nm,410 nm,420 nm,430 nm,440 nm,',...
                   '450 nm,460 nm,470 nm,480 nm,490 nm,500 nm,510 nm,520 nm,530 nm,',...
				   '540 nm,550 nm,560 nm,570 nm,580 nm,590 nm,600 nm,610 nm,620 nm,',...
				   '630 nm,640 nm,650 nm,660 nm,670 nm,680 nm,690 nm,700 nm,710 nm,720 nm,730 nm']	;
fprintf(output_fid, '%s\n', FirstOutputLine);				   
fclose(output_fid)							;
dlmwrite(ShadeBankFileName, ShadeBankData(:,[1:3,7:end]), ',', '-append')	;
[NumOfColInShadeBank,~] = size(ShadeBankData)					;

% Express shade bank data in XYZ and Lab as well as xyY
XYZ = []					;
[row,~] = size(xyY)			;
for ind = 1:row
    [X Y Z] = xyY2XYZ(xyY(ind,1), xyY(ind,2), xyY(ind,3))	;
    XYZ = [XYZ; X Y Z]		;
end
WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs);
Lab = xyz2lab(XYZ, WhitePointXYZ)	;

[NumOfInitialDataPoints,~] = size(RGB)		;

% Monitor progress.  The ith row of the matrix DEprogress lists the DEs between the aimpoint, and the
% current estimate.  The jth column corresponds to the jth iteration.  The 1st iteration is the shade
% bank, so no DE is available.
DEprogress = -99 *ones(NumberOfAimPoints,MaxIterations)	;	 

% Count the number of RGB entries in the original shade bank data
[NumOfOrigRGBs,~] = size(RGB)	
fflush(stdout);

% If interpolation calculations have not already been run, then run them.  After running them.
% save off the results in a file, to avoid repeating them if the identical
% program is run again.  If such a file was saved from a previous run, then just load it.
FileForSaving = [Name,'Iteration', num2str(iteration),'.mat']		
if isempty(which(FileForSaving))
    % Use interpolation to estimate which RGB sequences produce the desired L*a*b* aimpoints
    [AllInterpolatedRGB, RGBvertices, Labvertices, AllBaryCoords, tessellation] = ...
	    InterpolateForAimPoints(RGB, Lab, AimPointsLab)	;
		size(Labvertices)
	[~,NumOfCells] = size(Labvertices)			
	XYZvertices = {}							;
	for ind = 1:NumOfCells
    	WhitePointXYZ = WhitePointWithYEqualTo100(IllumObs);
	    XYZvertices{ind} = lab2xyz(Labvertices{ind}, WhitePointXYZ);
	end
    dlmwrite([Name,'ShadeBankTessellation.txt'], tessellation, ',')				;
    save('-v7', FileForSaving, 'AllInterpolatedRGB', 'RGBvertices', 'XYZvertices',...
	 'AllBaryCoords', 'tessellation','Labvertices');
else
	load(FileForSaving)
end

TessellationSize = size(tessellation)    ;
disp([' ']);
disp(['Iteration 1: ', num2str(TessellationSize(1)),' tetrahedra in tessellation']);
fflush(stdout)	;

if DisplayEdgeLengthHistogram
    DisplayEdgeLengthsOfTessellation(tessellation, XYZ, Name, iteration);
end

iteration = 2	;

% An iterative algorithm will be performed for each aimpoint.  Store the needed information for
% all the iterations in a list of structures.  Also, list the indices of aimpoints for which no RGB
% has been found, in the variable MstrIdForRGBattempts.
% The field "progress" of the InfoSummary structure is an 8-column matrix.  Each aimpoint has its
% own "progress" field.  The first three columns are the RGB for an attempted match for that
% aimpoint.  The next three columns are the XYZ values produced by that RGB.  The seventh
% column is the perceptual difference (using CIEDE2000) between the XYZ values and the aimpoint.
% The eighth colum is a flag for whether or not that RGB-XYZ has been used in a new tetrahedron
% (whose vertices are attempted matches for the aimpoint).
UsedInTetrahedron = 1	;
DEsInsideTetrahedra = [];
InfoSummary = {}		;
MstrIdForRGBattempts = [];
for indx = 1:NumberOfAimPoints
	% Save off some fields in the InfoSummary structure
	tempstruct             = {}								;

	% If values in the interpolation for aimponts are -99, then that aimpoint is not
	% in the gamut of RGB lattice, which approximates the printer gamut
	if AllInterpolatedRGB(indx,1) ~= -99
		% Save off indices where an aimpoint is in the printer gamut
		MstrIdForRGBattempts      = [MstrIdForRGBattempts, indx]	;
		
		% Save off some fields 
		ProgMatrix                = -99 * ones(1,8)					;
		ProgMatrix(1,1:3)         = AllInterpolatedRGB(indx,:)		;
		tempstruct.progress       = ProgMatrix						;
		tempstruct.RGBvertices{1} = RGBvertices{indx}				;
		tempstruct.XYZvertices{1} = XYZvertices{indx}				;
		tempstruct.Labvertices{1} = Labvertices{indx}				;
		
		% Store matrix with list of attempted tetrahedra, and DEs
		tempmat = [RGBvertices{indx}, XYZvertices{indx}, -99*ones(4,1), ones(4,1), Labvertices{indx}]	;
		tempmat = [tempmat; AllInterpolatedRGB(indx,:) -99*ones(1,8)];	
		for DEctr = 1:4
		    DE2000           = CIEDE2000ForXYZ(tempmat(DEctr,4:6), AimPointsXYZ(indx,:), WhitePointXYZ)	;
			tempmat(DEctr,7) = DE2000								;
			DEsInsideTetrahedra = [DEsInsideTetrahedra; DE2000]		;
		end
		tempmat(5,:) = [AllInterpolatedRGB(indx,:), -99*ones(1,8)]	;
		tempstruct.TetraProgress = tempmat			;
	else		% That aimpoint is out of the printer gamut
		AimPointResults(indx,8) = StatusOutOfGamut	;
	end
	InfoSummary{indx}    = tempstruct								;
end

if DisplayInternalDEHistogram
    % Print histogram showing DEs between aimpoints and vertices of enclosing tetrahedra
    figure
    set(gcf, 'Name', ['Internal DEs achieved so far (Iteration ',num2str(iteration),')'])
    EdgeVector = [0:1:50,1000];
    [Counts] = histc(transpose(DEsInsideTetrahedra), EdgeVector)	;
    HistogramData = [EdgeVector; Counts]	;
    stairs(EdgeVector, Counts)		;
    set(gca, 'xlim', [0,50])				;
    figname = [Name,'HistInternalDEIteration',num2str(iteration)]	;
    print(gcf, [figname,'.eps'], '-deps')	;
    print(gcf, [figname,'.png'], '-dpng')	;
    print(gcf, [figname,'.jpg'], '-djpg')	;
    print(gcf, [figname,'.pdf'], '-dpdf')	;
end

% If no aimpoints are within the gamut of the shade bank, then quit the routine
if isempty(MstrIdForRGBattempts)
	disp(['All aimpoints are outside the gamut of the shade bank'])		;
	return																;
else
    AllAimPointsProcessed = false									;
end

% Keep statistics of the number of colours that are printed and measured,
% as well as the number of matches that are attempted
NumberOfNewMeasuredColours = 0			;
NumberOfAttemptedSampleMatches = 0		;

disp([' ']);
disp([' ']);
disp(['Iteration: ',num2str(iteration)]);

RGBAttempts = []				;
RevMstrIdForRGBattempts = []	;
for ind = MstrIdForRGBattempts
    tempstruct  = InfoSummary{ind}		;
	if ~isempty(tempstruct)
	    ProgMatrix  = tempstruct.progress	;
	    RGBtry      = ProgMatrix(end,1:3)	;
        RGBAttempts = [RGBAttempts; RGBtry]	;
		RevMstrIdForRGBattempts = [RevMstrIdForRGBattempts, ind]	;
    end
end
MstrIdForRGBattempts = RevMstrIdForRGBattempts				;	
RGBAttempts = (1/255) * round(255*RGBAttempts)				;		% Round to nearest 8-bit integer

% Produce a figure, that is displayed on the monitor, with those RGBs.
% To save the time taken to display figures on the screen, skip the display
% step if the colours to be displayed have already been printed and measured.
OutputFile = [Name,'Iteration2.csv']	;
if isempty(which(OutputFile))
    PrintRGBs(RGBAttempts, [Name,'Iteration',num2str(iteration)])		;
end
	
% During the pause, print the figure using the printer and paper of interest.
% Then measure the printed colours with a spectrophotometer, in the same order in
% which they appear in the matrix InterpolatedRGBinGamut.  If the spectrophotometer is a
% ColorMunki, then click File:Export on the ColorMunki
% window, and choose "Comma separated" as the file type.  Export to a
% file named "Iteration_x_.csv" in the current directory, where _x_ is the current iteration.
% If the spectrophotometer is an i1i0 AST, equipped with an i1Pro2, then save to a file
% named "Iteration_x_Curr_M2.txt" in the current directory.  This file will then be
% converted to a .csv file in ColorMunki format.
disp(['During the pause, print the figure using the printer and paper of interest.'])	;
disp(['The printed colours are attempted matches for some of the input aimpoints.'])	;
disp(['Measure the printed colours in the order in which they appear.  Use either a ColorMunki,'])	;
disp(['or an i1i0 Automatic Scanning Table (AST), equipped with an i1Pro2 spectrophotometer.']);
disp(['If using the AST with the i1Pro2, there should be ',num2str(length(RGBAttempts))]);
disp(['colours in the saved .txt file.  When saving, choose 0.0 to 1.0 as the reflectance range, and']);
disp(['a decimal point as a separator.  Export to a file named "',Name,'Iteration',num2str(iteration),'Curr_M2.txt"']);
disp(['in the current directory.  (The i1i0 will automatically append _M2 to the chosen file name.)']); 
disp(['If the printed samples are measured with a ColorMunki, then there should be']) 
disp([num2str(NumOfColInShadeBank+length(MstrIdForRGBattempts)),' colours in the ColorMunki folder.  ',...
      'Click File:Export on the ColorMunki'])	;
disp(['window, and choose "Comma separated" as the file type.  Export to a'])	;
disp(['file named "',Name,'Iteration',num2str(iteration),'.csv" in the current directory.  Once the file is saved,'])	;
disp(['press the "y" key (or any other key) to resume the program.'])					;
temp = fflush(stdout);
if UsePauses
    pause()										;
end
	
% The measurement data will be stored in a CSV file with the following name:	
CSVfileName = [Name,'Iteration',num2str(iteration),'.csv'] 	;
% If the colours were measured with a ColorMunki, then they will have been stored
% directly in such a file.  If they were measured with an i1i0, equipped with an i1Pro2
% spectrophotometer, then the measurements will have been stored in a file of a different
% format, which must be converted to a .csv format.
% Check whether a .csv file has already been saved by the user.  If not, convert the
% i1i0 file to .csv format, and append it to the previous .csv file. 
if isempty(which(CSVfileName))
% Add the latest measurements to a running file of measurements
    NewFileName = [Name,'Iteration',num2str(iteration),'Curr_M2.txt']	;
    [EntriesGreaterThan1, EntriesLessThan0] = ...
       i1i02txtFileToColorMunkiCSVFormat(NewFileName)	;
    ListOfColorMunkiCSVfiles{1} = [Name,'Iteration',num2str(iteration-1),'.csv']	;
    ListOfColorMunkiCSVfiles{2} = [NewFileName(1:(end-3)),'csv']	;
    ConcatenateColorMunkiCSVFiles(ListOfColorMunkiCSVfiles, CSVfileName);
 end

% Add the number of printed colours to the number of attempted matches
[NumOfPrintedSamples,~] = size(RGBAttempts)												;
NumberOfAttemptedSampleMatches = NumberOfAttemptedSampleMatches + NumOfPrintedSamples	;
NumberOfNewMeasuredColours     = NumberOfNewMeasuredColours + NumOfPrintedSamples		;
	
% Each printed RGB specification will have a reflectance spectrum, which has been
% measured by a spectrophotometer.  Convert the reflectance spectrum to xyY and XYZ,
% assuming the input illuminant-observer combination.  
% First, extract the reflectance data
[Wavelengths, NewReflectances] = ColorMunkiCSVfileToOctaveFormat(CSVfileName);
% Then, extract xyY and XYZ values from the reflectance data
CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, NewReflectances, IllumObs);
NewXYZ = CIEcoords(:,1:3)										;
NewxyY = CIEcoords(:,4:6)										;
		
% Count the number of RGB entries in the current shade bank data
[NumOfOrigRGBs,~] = size(RGB)	;
% Add the new data into the shade bank
RGB = [RGB; RGBAttempts]		;

% Overwrite the previous shade bank file with augmented shade bank data	
ShadeBankData = [RGB, NewxyY, NewReflectances]	;
output_fid = fopen(ShadeBankFileName, 'w')		;
% The first line of a shade bank file is fixed, so it is written directly to the file
fprintf(output_fid, '%s\n', FirstOutputLine);				   
fclose(output_fid)							;
dlmwrite(ShadeBankFileName, ShadeBankData(:,[1:3,7:end]), ',', '-append')	;
[NumOfColInShadeBank,~] = size(ShadeBankData)	;
disp(['Number of Colours in Shade Bank: ', num2str(NumOfColInShadeBank)])	;

% Calculate the DEs between the printed RGBs and the aimpoints.  Store the results
ctr = 0														;
for index = MstrIdForRGBattempts
    ctr = ctr + 1											;
    xyYaimpoint = AimPointResults(index, 2:4)				;
	xyYsample   = NewxyY(NumOfOrigRGBs + ctr,:)				;
    AimPointResults(index,12:14) = xyYsample				;
	DE2000      = CIEDE2000ForxyY(xyYaimpoint, xyYsample, WhitePointXYZ)	;
				
	% Record XYZ value and DE in "progress" field of InfoSummary structure
	tempstruct          = InfoSummary{index}			;
	ProgMatrix          = tempstruct.progress			;
	CorrXYZ             = NewXYZ(NumOfOrigRGBs + ctr,:)	;
	CorrLab             = xyz2lab(CorrXYZ,WhitePointXYZ);
	ProgMatrix(end,4:6) = NewXYZ(NumOfOrigRGBs + ctr,:)	;
	ProgMatrix(end,7)   = DE2000						;
    ProgMatrix(end,9:11) = xyz2lab(ProgMatrix(end,4:6), WhitePointXYZ);
	tempstruct.progress = ProgMatrix					;

	% Add to list of tetrahedra
	tempmat = tempstruct.TetraProgress					;
	tempmat(end,4:11) = [CorrXYZ, DE2000, 2, CorrLab]	;
	tempstruct.TetraProgress = tempmat					;

	InfoSummary{index}  = tempstruct					;
		
	% Update progress and results matrices with best results obtained so far
	DEprogress(index, iteration) = DE2000								;
    AimPointResults(index,9:11)  = InfoSummary{index}.progress(end,1:3)	;
    AimPointResults(index,12:14) = xyYsample							;
    AimPointResults(index,18)    = DE2000								;
	if DE2000 <= DEthreshold	% Printed colour matches aimpoint to within threshold
	    % Update the matrix of results for matching aimpoints
	    AimPointResults(index,8)     = StatusFound							;
	end
end

if DisplayBestDEHistogram
    % Print histogram showing DEs achieved so far
    figure
    set(gcf, 'Name', ['Histogram of DEs achieved so far (Iteration ',num2str(iteration),')'])
    BestDE=[]						;
    [AProw,~] = size(DEprogress)	;
    for idxBDE = 1:AProw
        BestDE(idxBDE) = min(abs(DEprogress(idxBDE,:)))		;
	    if BestDE(idxBDE) == 99
	        BestDE(idxBDE) = -99	;
	    end
    end
    EdgeVector = [-100,0:0.5:8,1000]		;
    [Counts] = histc(BestDE, EdgeVector)	;
    HistogramData = [EdgeVector; Counts]	;
    stairs(EdgeVector, Counts)				;
    set(gca, 'xlim', [-1,7])				;
    figname = [Name,'HistDEIteration',num2str(iteration)]	;
    print(gcf, [figname,'.eps'], '-deps');
    print(gcf, [figname,'.png'], '-dpng');
    print(gcf, [figname,'.jpg'], '-djpg');
    print(gcf, [figname,'.pdf'], '-dpdf');
end

% From the list of statuses in the results matrix, select those master IDs for which
% another RGB attempt will be made.
MstrIdForRGBattempts = []										;
for index = 1:NumberOfAimPoints
    if AimPointResults(index, 8) == StatusNotFoundYet
	    MstrIdForRGBattempts = [MstrIdForRGBattempts, index]	;
	end
end

if isempty(MstrIdForRGBattempts)
    AllAimPointsProcessed = true			;
end
		
% Progressively refine the RGB samples, until they agree as closely as required
% with the input aimpoints.  The loop has two parts, each with a
% different iteration number.  The first part refines the shade bank, by
% adding samples near aimpoints of interest.  The second part
% recalculates RGB approximations to the aimpoint specifications.  Both parts
% require the user to measure new colours, and save them to a cumulative file.
while iteration < MaxIterations && AllAimPointsProcessed == false

	iteration = iteration + 1										;	
	disp(['Iteration: ',num2str(iteration)]);

	% Choose new RGBs, that should form tetrahedra around aimpoints
    NewRGBsToPrint    = []	;
	IndicesForNewRGBs = []	;
    for index = MstrIdForRGBattempts
	    % Access the information for the unfound aimpoint
	    TempStruct  = InfoSummary{index}			;
		
	    % Find the RGB vertices of the tetrahedron whose image under the display
	    % function contains the aimpoint
	    AllRGBverts = TempStruct.RGBvertices		;
	    RGBverts    = AllRGBverts{end}				;

	    % Extract the current RGB estimate
	    ProgMatrix  = TempStruct.progress			;
        RGBest      = ProgMatrix(end,1:3)				;

		% Find the XYZ vertices of the tetrahderon.  
		AllXYZverts = TempStruct.XYZvertices		;
	    XYZverts    = AllXYZverts{end}				;
		
		% Find the Lab vertices of the tetrahderon.  
		AllLabverts = TempStruct.Labvertices		;
	    Labverts    = AllLabverts{end}				;
		
    	XYZtarget = AimPointResults(index, 5:7)		;
  	    xyYest    = AimPointResults(index,12:14) 	;
		[Xest, Yest, Zest] = xyY2XYZ(xyYest(1), xyYest(2), xyYest(3))	;
		XYZest    = [Xest, Yest, Zest]				;
		
		Labtarget = AimPointsLab(index,:)				;
        Labest    = xyz2lab(XYZest, WhitePointXYZ);
		
		% Call a routine that draws a new tetrahedron that hopefully encloses the aimpoint
		NewVertices = NewLabVerticesInTessellation(RGBverts, Labverts, Labtarget, Labest);
		NewVertices = (1/255) * round(255*NewVertices)	;	% Round for 8-bit colour storage

	    % Add to list of tetrahedrons
	    tempmat           = TempStruct.TetraProgress	;

		tempmat = [tempmat; NewVertices, -99*ones(3,4), iteration*ones(3,1), -99*ones(3,3)]	;
	    TempStruct.TetraProgress = tempmat				;

		InfoSummary{index}  = TempStruct				;
		
		NewRGBsToPrint    = [NewRGBsToPrint; NewVertices]			;
		[rows,~]          = size(tempmat)							;
		IndicesForNewRGBs = [IndicesForNewRGBs; index*ones(3,1), transpose((rows-2):rows)]	;
    end
    NewRGBsToPrint = (1/255) * round(255*NewRGBsToPrint)	;
	[NumberOfNewPrintedSamples,~] = size(NewRGBsToPrint)	;

	% Produce a figure, that is displayed on the monitor, with the new RGB samples.
	% If samples were already printed and measured, skip this step to save time.
    CSVFile = [Name,'Iteration',num2str(iteration),'.csv']		;
    if isempty(which(CSVFile))
       	NumberOfPagesPrinted = PrintRGBs(NewRGBsToPrint, [Name,'Iteration',num2str(iteration)])		;
	end
			
    % During the pause, print the figure using the printer and paper of interest.
    % Then measure the printed colours with a spectrophotometer, in the same order in
    % which they appear in the matrix InterpolatedRGBinGamut.  If the spectrophotometer is a
    % ColorMunki, then click File:Export on the ColorMunki
    % window, and choose "Comma separated" as the file type.  Export to a
    % file named "Iteration_x_.csv" in the current directory, where _x_ is the current iteration.
    % If the spectrophotometer is an i1i0 AST, equipped with an i1Pro2, then save to a file
    % named "Iteration_x_Curr_M2.txt" in the current directory.  This file will then be
    % converted to a .csv file in ColorMunki format.
    disp(['During the pause, print the figure using the printer and paper of interest.'])	;
    disp(['The printed colours are attempted matches for some of the input aimpoints.'])	;
    disp(['Measure the printed colours in the order in which they appear.  Use either a ColorMunki,'])	;
    disp(['or an i1i0 Automatic Scanning Table (AST), equipped with an i1Pro2 spectrophotometer.']);
    disp(['If using the AST with the i1Pro2, there should be ',num2str(NumberOfNewPrintedSamples)]);
    disp(['new colours measured in total.  When saving, choose 0.0 to 1.0 as the reflectance range, and']);
    disp(['a decimal point as a separator.  Export to a file named "',Name,'Iteration',num2str(iteration),'Currpgx_M2.txt"']);
    disp(['in the current directory, where the x in pgx refers to a page number, if the']);
    disp(['colours were printed on multiple pages.  (The i1i0 will automatically append _M2 to the chosen file name.)']); 
    disp(['If the printed samples are measured with a ColorMunki, then there should be']) 
    disp([num2str(NumOfColInShadeBank+NumberOfNewPrintedSamples),' colours in the ColorMunki folder.  ',...
      'Click File:Export on the ColorMunki'])	;
    disp(['window, and choose "Comma separated" as the file type.  Export to a'])	;
    disp(['file named "',Name,'Iteration',num2str(iteration),'.csv" in the current directory.  Once the file is saved,'])	;
    disp(['press the "y" key (or any other key) to resume the program.'])					;
	temp = fflush(stdout);
	if UsePauses
	    pause()										;
	end
		
    % The measurement data will be stored in a CSV file with the following name:	
    CSVfileName = [Name,'Iteration',num2str(iteration),'.csv'] 	;
    % If the colours were measured with a ColorMunki, then they will have been stored
    % directly in such a file.  If they were measured with an i1i0, equipped with an i1Pro2
    % spectrophotometer, then the measurements will have been stored in a file of a different
    % format, which must be converted to a .csv format.
    % Check whether a .csv file has already been saved by the user.  If not, convert the
    % i1i0 file to .csv format, and append it to the current .csv file. 
    if isempty(which(CSVfileName))
        % Add the latest measurements to a running file of measurements
        ListOfColorMunkiCSVfiles = {}	;
        ListOfColorMunkiCSVfiles{1} = [Name,'Iteration',num2str(iteration-1),'.csv']	;
        % The latest iteration might have been printed on multiple pages, so convert the
        % saved file for each page to a ColorMunki .csv file, and then concatenate them.
        for PageCtr = 1:NumberOfPagesPrinted
            NewFileName = [Name,'Iteration',num2str(iteration),'Currpg',num2str(PageCtr),'_M2.txt']	;
            [EntriesGreaterThan1, EntriesLessThan0] = ...
               i1i02txtFileToColorMunkiCSVFormat(NewFileName)	;
            ListOfColorMunkiCSVfiles{end+1} = [NewFileName(1:(end-3)),'csv']	;
        end
        ConcatenateColorMunkiCSVFiles(ListOfColorMunkiCSVfiles, CSVfileName);
        
    end
		
    NumberOfNewMeasuredColours = NumberOfNewMeasuredColours + NumberOfNewPrintedSamples	;
	
    % Each printed RGB specification will have a reflectance spectrum, which has been
    % measured by a spectrophotometer.  Convert the reflectance spectrum to xyY and XYZ,
    % assuming the input illuminant-observer combination.  
	% First, extract the reflectance data
	[Wavelengths, NewReflectances] = ColorMunkiCSVfileToOctaveFormat(CSVfileName);
    % Then, extract xyY and XYZ values from the reflectance data
    CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, NewReflectances, IllumObs);
	NewXYZ    = CIEcoords(:,1:3)										;
	NewxyY    = CIEcoords(:,4:6)										;
		
				
    % Count the number of RGB entries in the current shade bank data
    [NumOfOrigRGBs,~] = size(RGB)		;
	% Add the new data into the shade bank
	RGB = [RGB; NewRGBsToPrint]										;

	ShadeBankData = [RGB, NewxyY, NewReflectances]					;
    [NumOfColInShadeBank,~] = size(ShadeBankData)					;
    % Overwrite the previous shade bank file with augmented shade bank data	
	output_fid = fopen(ShadeBankFileName, 'w')		;
    % The first line of a shade bank file is fixed, so it is written directly to the file
    fprintf(output_fid, '%s\n', FirstOutputLine);				   
    fclose(output_fid)							;
    dlmwrite(ShadeBankFileName, ShadeBankData(:,[1:3,7:end]), ',', '-append')	;
    dlmwrite('ShadeBank.txt', ShadeBankData, ',')				;

	% For statistics and analysis, calculate the perceptual distances between an enclosing
	% tetrahedron s vertices, and the aimpoint.  Store the new tetrahedron vertices in a progress matrix
    DEsInsideTetrahedra = []									;
	ctr = 0														;
    for SampIndex = 1:NumberOfNewPrintedSamples
	    ctr = ctr + 1											;
		MasterIndex = IndicesForNewRGBs(SampIndex,1)			;
		RowOfMatrix = IndicesForNewRGBs(SampIndex,2)			;
	    xyYaimpoint = AimPointsxyY(MasterIndex, :)				;
	    XYZaimpoint = AimPointsXYZ(MasterIndex, :)				;
		xyYsample   = NewxyY(NumOfOrigRGBs + ctr,:)				;
		XYZsample   = NewXYZ(NumOfOrigRGBs + ctr,:)				;
		Labsample   = xyz2lab(XYZsample, WhitePointXYZ)			;	
%        AimPointResults(index,12:14) = xyYsample				;
		DE2000      = CIEDE2000ForxyY(xyYaimpoint, xyYsample, WhitePointXYZ)	;
		
		DEsInsideTetrahedra = [DEsInsideTetrahedra; DE2000]		;
		
		% Store the new measurements in the progress matrix for all aimpoints
	    TempStruct                 = InfoSummary{MasterIndex}					;
	    tempmat                    = TempStruct.TetraProgress					;
		tempmat(RowOfMatrix, 4:11) = [XYZsample, DE2000, iteration, Labsample]	;
	    TempStruct.TetraProgress   = tempmat									;
		InfoSummary{MasterIndex}   = TempStruct									;
		
		% Record XYZ value and DE in "progress" field of InfoSummary structure
		tempstruct          = InfoSummary{MasterIndex}			;
		ProgMatrix          = tempstruct.progress			;
		ProgMatrix(end,4:6) = NewXYZ(NumOfOrigRGBs + ctr,:)	;
		ProgMatrix(end,7)   = DE2000						;
	    ProgMatrix(end,9:11) = xyz2lab(ProgMatrix(end,4:6), WhitePointXYZ);
		tempstruct.progress = ProgMatrix					;
		InfoSummary{MasterIndex}  = tempstruct					;
	end
	
	if DisplayInternalDEHistogram
        % Print histogram showing DEs between aimpoints and vertices of enclosing tetrahedra
        figure
        set(gcf, 'Name', ['Internal DEs achieved so far (Iteration ',num2str(iteration),')'])
        EdgeVector = [0:1:50,1000];
        [Counts] = histc(transpose(DEsInsideTetrahedra), EdgeVector)			;
        HistogramData = [EdgeVector; Counts]			;
        stairs(EdgeVector, Counts)						;
        set(gca, 'xlim', [0,50])						;
        figname = [Name,'HistInternalDEIteration',num2str(iteration)]	;
        print(gcf, [figname,'.eps'], '-deps');
        print(gcf, [figname,'.png'], '-dpng');
        print(gcf, [figname,'.jpg'], '-djpg');
        print(gcf, [figname,'.pdf'], '-dpdf');
    end
	
    % Check DEs between the aimpoint and the vertices of the enclosing tetrahedron
    for index = MstrIdForRGBattempts
		% Record best DE in AimPointResults
	    TempStruct                   = InfoSummary{index}				;
	    TetraProgress                = TempStruct.TetraProgress			;
		[SortedDEs SortingIndices]   = sort(TetraProgress(:,7))			;
		BestDE                       = SortedDEs(1)						;
		DEprogress(index, iteration) = BestDE							;
		XYZsample                    = TetraProgress(SortingIndices(1),4:6)	;
		[x, y, YOut]                 = XYZ2xyY(XYZsample(1), XYZsample(2), XYZsample(3))	;
		
		% Update results matrix with best match so far
	    AimPointResults(index,9:11)  = TetraProgress(SortingIndices(1),1:3)	;
	    AimPointResults(index,12:14) = [x, y, YOut]							;
	    AimPointResults(index,18)    = BestDE								;
        % Possibly, one of the vertices of the enclosing tetrahedron is already an
	    % acceptable match to the aimpoint.  Check this possibility and note if it occurs.
		if BestDE <= DEthreshold	% Printed colour matches aimpoint to within threshold
		    % Update the matrix of results for matching aimpoints
		    AimPointResults(index,8)     = StatusFound							;
		end
	end

    if DisplayBestDEHistogram
        % Print histogram showing DEs achieved so far
	    figure
        set(gcf, 'Name', ['Histogram of DEs achieved so far (Iteration ',num2str(iteration),')'])
        BestDE=[]						;
        [AProw,~] = size(DEprogress)	;
        for idxBDE = 1:AProw
            BestDE(idxBDE) = min(abs(DEprogress(idxBDE,:)))		;
	        if BestDE(idxBDE) == 99
	            BestDE(idxBDE) = -99;
	        end
        end
        EdgeVector = [-100,0:0.5:8,1000];
        [Counts] = histc(BestDE, EdgeVector)	;
        HistogramData = [EdgeVector; Counts]	;
        stairs(EdgeVector, Counts)				;
        set(gca, 'xlim', [-1,7])				;
        figname = [Name,'HistDEIteration',num2str(iteration)]	;
        print(gcf, [figname,'.eps'], '-deps');
        print(gcf, [figname,'.png'], '-dpng');
        print(gcf, [figname,'.jpg'], '-djpg');
        print(gcf, [figname,'.pdf'], '-dpdf');
    end
	
    % Interpolate within the enclosing tetrahedron for each aimpoint.
	% Though the "enclosing" tetrahedron was designed to contain the aimpoint, it is
	% possible, when measurement errors have too large an effect on the algorithm,
	% that the aimpoint is actually outside the tetrahedron.  Check for and record
	% these occurrences.  
    RGBAttempts = []				;
	RevMstrIdForRGBattempts = []	;
	InsideTetraCtr = 0				;
	InsideTetraCtrIndex = []		;
    for ind = MstrIdForRGBattempts
	    TempStruct  = InfoSummary{ind}		;
		if DEprogress(ind, iteration) > DEthreshold
	        TetraProgress    = TempStruct.TetraProgress			;
			TetraRGBVertices = TetraProgress((end-3):end,1:3)	;
			TetraLabVertices = TetraProgress((end-3):end,9:11)	;
			AimPointBaryLab  = cart2bary(TetraLabVertices, AimPointsLab(ind,:))	;
			
			% For diagnostics, check whether the aimpoint is inside the "enclosing" tetrahedron.  If so,
			% all the aimpoint s barycentric coordinates, relative to the tetrahedron, 
			% should be between 0 and 1.
			if 0 <= AimPointBaryLab(1) && AimPointBaryLab(1) <= 1 && ...
               0 <= AimPointBaryLab(2) && AimPointBaryLab(2) <= 1 && ...
               0 <= AimPointBaryLab(3) && AimPointBaryLab(3) <= 1 && ...
               0 <= AimPointBaryLab(4) && AimPointBaryLab(4) <= 1 
			      InsideTetraCtr      = InsideTetraCtr + 1			;
				  InsideTetraCtrIndex = [InsideTetraCtrIndex, ind]	;
			end
			
			% Interpolate linearly over the enclosing tetrahedron to get a new estimate.
			RGBtry           = AimPointBaryLab(1) * TetraRGBVertices(1,:) + ...
			                   AimPointBaryLab(2) * TetraRGBVertices(2,:) + ...
                               AimPointBaryLab(3) * TetraRGBVertices(3,:) + ...
                               AimPointBaryLab(4) * TetraRGBVertices(4,:) ;
			% Numerical issues might cause the RGB triple to be outside the [0,1] cube.
			% In that case, adjust the offending variables.
			for ctr = 1:3
			    if RGBtry(ctr) < 0
				    RGBtry(ctr) = 0			;
				end
			    if RGBtry(ctr) > 1
				    RGBtry(ctr) = 1			;
				end
			end
			RGBtry = (1/255) * round(255 * RGBtry)						; % Round to nearest 8-bit integer
			
			% Store results in progress matrices
			TetraProgress((end+1),1:3) = RGBtry							;
            RGBAttempts = [RGBAttempts; RGBtry]							;
			RevMstrIdForRGBattempts = [RevMstrIdForRGBattempts, ind]	;
			TempStruct.TetraProgress = TetraProgress					;
			InfoSummary{ind}         = TempStruct						;
		end
    end
%disp(['Number inside tetrahedron: ', num2str(InsideTetraCtr),' out of ', num2str(length(MstrIdForRGBattempts))]);
	MstrIdForRGBattempts = RevMstrIdForRGBattempts						;
	[NumberOfNewRGB,~]         = size(RGBAttempts)						;


    % The new iteration will measure the current estimates for the RGBs of the aimpoints,
	% and evaluate their accuracy.
    iteration = iteration + 1		;
	disp(['Iteration: ',num2str(iteration)]);

	% Produce a figure, that is displayed on the monitor, with the new RGB samples.
	% If samples were already printed and measured, skip this step to save time.
    CSVFile = [Name,'Iteration',num2str(iteration),'.csv']				;
    if isempty(which(CSVFile))
    	NumberOfPagesPrinted = PrintRGBs(RGBAttempts, [Name,'Iteration',num2str(iteration)])	;
	end
	
    % During the pause, print the figure using the printer and paper of interest.
    % Then measure the printed colours with a spectrophotometer, in the same order in
    % which they appear in the matrix InterpolatedRGBinGamut.  If the spectrophotometer is a
    % ColorMunki, then click File:Export on the ColorMunki
    % window, and choose "Comma separated" as the file type.  Export to a
    % file named "Iteration_x_.csv" in the current directory, where _x_ is the current iteration.
    % If the spectrophotometer is an i1i0 AST, equipped with an i1Pro2, then save to a file
    % named "Iteration_x_Curr_M2.txt" in the current directory.  This file will then be
    % converted to a .csv file in ColorMunki format.
    disp(['During the pause, print the figure using the printer and paper of interest.'])	;
    disp(['The printed colours are attempted matches for some of the input aimpoints.'])	;
    disp(['Measure the printed colours in the order in which they appear.  Use either a ColorMunki,'])	;
    disp(['or an i1i0 Automatic Scanning Table (AST), equipped with an i1Pro2 spectrophotometer.']);
    disp(['If using the AST with the i1Pro2, there should be ',num2str(NumberOfNewRGB)]);
    disp(['new colours measured in total.  When saving, choose 0.0 to 1.0 as the reflectance range, and']);
    disp(['a decimal point as a separator.  Export to a file named "',Name,'Iteration',num2str(iteration),'Currpgx_M2.txt"']);
    disp(['in the current directory, where the x in pgx refers to a page number, if the']);
    disp(['colours were printed on multiple pages.  (The i1i0 will automatically append _M2 to the chosen file name.)']); 
    disp(['If the printed samples are measured with a ColorMunki, then there should be']) 
    disp([num2str(NumOfColInShadeBank+NumberOfNewRGB),' colours in the ColorMunki folder.  ',...
      'Click File:Export on the ColorMunki'])	;
    disp(['window, and choose "Comma separated" as the file type.  Export to a'])	;
    disp(['file named "',Name,'Iteration',num2str(iteration),'.csv" in the current directory.  Once the file is saved,'])	;
    disp(['press the "y" key (or any other key) to resume the program.'])					;
	fflush(stdout);
	if UsePauses
	    pause()										;
	end
		
    % The measurement data will be stored in a CSV file with the following name:	
    CSVfileName = [Name,'Iteration',num2str(iteration),'.csv'] 	;
    % If the colours were measured with a ColorMunki, then they will have been stored
    % directly in such a file.  If they were measured with an i1i0, equipped with an i1Pro2
    % spectrophotometer, then the measurements will have been stored in a file of a different
    % format, which must be converted to a .csv format.
    % Check whether a .csv file has already been saved by the user.  If not, convert the
    % i1i0 file to .csv format, and append it to the previous .csv file. 
    if isempty(which(CSVfileName))
        % Add the latest measurements to a running file of measurements
        ListOfColorMunkiCSVfiles = {}	;
        ListOfColorMunkiCSVfiles{1} = [Name,'Iteration',num2str(iteration-1),'.csv']	;
        % The latest iteration might have been printed on multiple pages, so convert the
        % saved file for each page to a ColorMunki .csv file, and then concatenate them.
        for PageCtr = 1:NumberOfPagesPrinted
            NewFileName = [Name,'Iteration',num2str(iteration),'Currpg',num2str(PageCtr),'_M2.txt']	;
            [EntriesGreaterThan1, EntriesLessThan0] = ...
               i1i02txtFileToColorMunkiCSVFormat(NewFileName)	;
            ListOfColorMunkiCSVfiles{end+1} = [NewFileName(1:(end-3)),'csv']	;
        end
        ConcatenateColorMunkiCSVFiles(ListOfColorMunkiCSVfiles, CSVfileName);
    end

	NumberOfNewMeasuredColours     = NumberOfNewMeasuredColours + NumberOfNewRGB		;
	NumberOfAttemptedSampleMatches = NumberOfAttemptedSampleMatches + NumberOfNewRGB	;

    % Each printed RGB specification will have a reflectance spectrum, which has been
    % measured by a spectrophotometer.  Convert the reflectance spectrum to xyY and XYZ,
    % assuming the input illuminant-observer combination.  
	% First, extract the reflectance data
	[Wavelengths, NewReflectances] = ColorMunkiCSVfileToOctaveFormat(CSVfileName);
    % Then, extract xyY and XYZ values from the reflectance data
    CIEcoords = ReflectancesToCIEwithWhiteY100(Wavelengths, NewReflectances, IllumObs);
	NewXYZ    = CIEcoords(:,1:3)	;
	NewxyY    = CIEcoords(:,4:6)	;

    % Count the number of RGB entries in the current shade bank data
    [NumOfOrigRGBs,~] = size(RGB)		;
disp(['NumOfOrigRGBs: ', num2str(NumOfOrigRGBs)]);    
    % Add the new data into the shade bank
    RGB = [RGB; RGBAttempts]										;

    ShadeBankData = [RGB, NewxyY, NewReflectances]					;
    [NumOfColInShadeBank,~] = size(ShadeBankData)					;
    % Overwrite the previous shade bank file with augmented shade bank data	
    output_fid = fopen(ShadeBankFileName, 'w')		;
    % The first line of a shade bank file is fixed, so it is written directly to the file
    fprintf(output_fid, '%s\n', FirstOutputLine);				   
    fclose(output_fid)							;
    dlmwrite(ShadeBankFileName, ShadeBankData(:,[1:3,7:end]), ',', '-append')	;
	
	% Evaluate the attempted matches.  If a printed sample matches its desired aimpoint
	% to within the threshold, then remove that aimpoint s index from the master list
	% in the variable MstrIdForRGBattempts.  The result will be a revised MstrIdForRGBattempts,
	% containing indices of aimpoints that have not yet been matched to within the threshold.
    ctr = 0							;
	NewMstrIdForRGBattempts = []	;
    for index = MstrIdForRGBattempts
	    ctr = ctr + 1														;
	    xyYaimpoint = AimPointResults(index, 2:4)							;
		xyYsample   = NewxyY(NumOfOrigRGBs + ctr,:)							;
		AimPointResults(index,12:14) = xyYsample							;
		DE2000      = CIEDE2000ForxyY(xyYaimpoint, xyYsample, WhitePointXYZ)				;
		
		% Record XYZ value and DE in TetraProgress field of InfoSummary structure
	    TempStruct              = InfoSummary{index}			;
	    TetraProgress           = TempStruct.TetraProgress		;
		TetraProgress(end,4:6)  = NewXYZ(NumOfOrigRGBs + ctr,:)	;
		TetraProgress(end,7)    = DE2000						;
		TetraProgress(end,8)    = iteration						;
	    TetraProgress(end,9:11) = xyz2lab(TetraProgress(end,4:6), WhitePointXYZ);
		TempStruct.TetraProgress = TetraProgress				;
		InfoSummary{index}      = TempStruct					;
		[SortedDEs SortingIndices]   = sort(TetraProgress(:,7))			;
		BestDE                       = SortedDEs(1)						;
		DEprogress(index, iteration) = BestDE							;

		if DE2000 <= DEthreshold	% Printed colour matches aimpoint to within threshold
		    % Update the matrix of results for matching aimpoints
		    AimPointResults(index,8)     = StatusFound							;
	        AimPointResults(index,9:11)  = InfoSummary{index}.progress(end,1:3)	;
	        AimPointResults(index,12:14) = xyYsample							;
	        AimPointResults(index,18)    = DE2000								;
		else	% Add the aimpoint index to the new master list of indices to be matched
			NewMstrIdForRGBattempts      = [NewMstrIdForRGBattempts, index]		;
		end
		
		% Update DEprogress matrix
		[SortedDEs SortingIndices]   = sort(TetraProgress(:,7))			;
		BestDE                       = SortedDEs(1)						;
		DEprogress(index, iteration) = BestDE							;
	end
	MstrIdForRGBattempts = NewMstrIdForRGBattempts	;
	
    if isempty(MstrIdForRGBattempts)
        AllAimPointsProcessed = true			;
    end
		
    if DisplayBestDEHistogram
        % Print histogram showing DEs achieved so far
	    figure
        set(gcf, 'Name', ['Histogram of DEs achieved so far (Iteration ',num2str(iteration),')'])
        BestDE=[]						;
        [AProw,~] = size(DEprogress)	;
        for idxBDE = 1:AProw
            BestDE(idxBDE) = min(abs(DEprogress(idxBDE,:)))		;
	        if BestDE(idxBDE) == 99
	            BestDE(idxBDE) = -99;
	        end
        end
        EdgeVector = [-100,0:0.5:8,1000];
        [Counts] = histc(BestDE, EdgeVector)	;
        HistogramData = [EdgeVector; Counts]	;
        stairs(EdgeVector, Counts)				;
        set(gca, 'xlim', [-1,7])				;
        figname = [Name,'HistDEIteration',num2str(iteration)]	;
        print(gcf, [figname,'.eps'], '-deps');
        print(gcf, [figname,'.png'], '-dpng');
        print(gcf, [figname,'.jpg'], '-djpg');
        print(gcf, [figname,'.pdf'], '-dpdf');
		fflush(stdout);
    end
	
end			% End of main loop

disp(['End of measurements.  Final statistics and output are being calculated']);
fflush(stdout);

AimPointsFound       = 0			;
AimPointsOutOfGamut  = 0			;
AimPointsNotFound    = 0			;
AimPointFoundIndices = []			;
AimPointInGamutNotFoundIndices = []	;
AimPointInGamutIndices = []			;
AimPointOutOfGamutIndices = []			;
for ctr = 1:NumberOfAimPoints
    if AimPointResults(ctr,8) == StatusFound
	    AimPointsFound = AimPointsFound + 1						;
		AimPointFoundIndices(end+1) = ctr						;
		AimPointInGamutIndices(end+1) = ctr						;
	elseif AimPointResults(ctr,8) == StatusOutOfGamut
	    AimPointsOutOfGamut = AimPointsOutOfGamut + 1			;
		AimPointOutOfGamutIndices(end+1) = ctr					;
	elseif AimPointResults(ctr,8) == StatusNotFoundYet
	    AimPointsNotFound = AimPointsNotFound + 1				;
		AimPointInGamutNotFoundIndices(end+1) = ctr				;
		AimPointInGamutIndices(end+1) = ctr						;
	else
	    disp(['ERROR: wrong status for found or not found'])	;
	end
end

disp(['Illuminant:                                            ', IllumObs])					;
disp(['Number of aimpoints:                                   ', num2str(NumberOfAimPoints)])		;
disp(['Aimpoints for which RGBs have been found:              ', num2str(AimPointsFound)])		;
disp(['Aimpoints that are out of gamut:                       ', num2str(AimPointsOutOfGamut)]);
disp(['In-gamut aimpoints for which RGBs have not been found: ', num2str(AimPointsNotFound)])	;
disp(['Original RGBs:                                         ', num2str(NumOfInitialDataPoints)])			;
disp(['New measured colours:                                  ', num2str(NumberOfNewMeasuredColours)])		;
disp(['Attempted matches:                                     ', num2str(NumberOfAttemptedSampleMatches)])	;
[NumberOfColoursInShadeBank,~] = size(RGB)		;
disp(['Number of colours in final shade bank:                 ', num2str(NumberOfColoursInShadeBank)])		;
fflush(stdout);

% It is possible that the shade bank contains an RGB triple that is closer to
% a desired aimpoint than the best RGB estimate for that aimpoint.  In addition,
% a colour may be outside the printer gamut, but still near enough to a printed
% colour to make an acceptable match.  To account
% for these offchances, for each aimpoint, check each entry in the shade bank to see
% how close it is to that aimpoint.  Store off the best matches in a file.
disp([' '])
disp(['For each aimpoint, check through the shade bank, finding the closest match.  Even'])
disp(['if an aimpoint is out of gamut, it might be within the DE threshold of a colour on'])
disp(['the boundary of the printer gamut.'])
fflush(stdout);
FinalRGBs         = []	;
MinDEs            = []	;
FinalWavelengths  = []	;
FinalReflectances = []	;
tic();
for APctr = 1:NumberOfAimPoints
if mod(APctr,10) == 0
    ElapsedTime = toc()			;
   RemainingMinutes = (ElapsedTime/APctr) * (NumberOfAimPoints-APctr+1)/60	;
   disp([num2str(ElapsedTime), ' sec; ',num2str(APctr),' out of ', num2str(NumberOfAimPoints),...
         ' processed; minutes remaining: ', num2str(RemainingMinutes)])	;
	fflush(stdout);
end
	StandardXYZ = AimPointsXYZ(APctr,:)			;
	[RGBs, DE2000, RankedIndices, FirstWavelengths, FirstReflectances] = ...
				EvaluateDEsToShadeBankFile( StandardXYZ, ...
											ShadeBankFileName, ...
											IllumObs);
	FinalRGBs         = [FinalRGBs; RGBs(1,:)]					;
	MinDEs            = [MinDEs; DE2000(1)]						;
	FinalWavelengths  = FirstWavelengths						;
	FinalReflectances = [FinalReflectances; FirstReflectances]	;
	
	if DE2000(1) < DEthreshold
        AimPointResults(APctr,18) = DE2000(1)    		;
		AimPointFoundIndices = sort(unique([AimPointFoundIndices, APctr]))	;
	    if AimPointResults(APctr,8) == StatusFound
	    elseif AimPointResults(APctr,8) == StatusOutOfGamut
		    AimPointResults(APctr,8) = StatusFound			;
	        AimPointsFound = AimPointsFound + 1				;
	        AimPointsOutOfGamut = AimPointsOutOfGamut - 1	;
	  	    AimPointOutOfGamutIndices = sort(setdiff(AimPointOutOfGamutIndices, APctr));
	    elseif AimPointResults(APctr,8) == StatusNotFoundYet
		    AimPointResults(APctr,8) = StatusFound			;
	        AimPointsFound = AimPointsFound + 1				;
	        AimPointsNotFound = AimPointsNotFound - 1		;
		    AimPointInGamutNotFoundIndices = sort(setdiff(AimPointInGamutNotFoundIndices, APctr));
		    AimPointInGamutIndices = sort([AimPointInGamutIndices,APctr])		;
	    else
	        disp(['ERROR: wrong status for found or not found'])	;
		end
	end
end
AimPointResults(:,18) = MinDEs			;
RGBresults = [AimPointResults(:,1:4), AimPointResults(:,8), FinalRGBs, AimPointResults(:,18)]	;
RGBresults = [RGBresults, FinalReflectances]	;
AimPointResults
AimPointInGamutIndices
AimPointInGamutNotFoundIndices
AimPointFoundIndices
AimPointOutOfGamutIndices

disp(['Aimpoints for which RGBs in threshold have been found: ', num2str(AimPointsFound)])		;
disp(['Aimpoints that are out of gamut:                       ', num2str(AimPointsOutOfGamut)]) ;
disp(['In-gamut aimpoints for which RGBs have not been found: ', num2str(AimPointsNotFound)])	;
fflush(stdout);

if DisplayBestDEHistogram
    % Print histogram showing DEs achieved after final check, when all iterations are completed
    figure
    set(gcf, 'Name', ['Histogram of DEs achieved after final check'])
    EdgeVector = [-1,0:0.5:10,1000]		;
    [Counts] = histc(transpose(MinDEs), EdgeVector)	;
    HistogramData = [EdgeVector; Counts]	;
    stairs(EdgeVector, Counts)				;
    set(gca, 'xlim', [-1,11])				;
    figname = [Name,'HistDEIterationFinal']	;
    print(gcf, [figname,'.eps'], '-deps');
    print(gcf, [figname,'.png'], '-dpng');
    print(gcf, [figname,'.jpg'], '-djpg');
    print(gcf, [figname,'.pdf'], '-dpdf');
end

% Write the closest RGBs for the aimpoints out to a file, including the DE.
fid = fopen([Name,'BestRGBList',IllumObsNoSlashes,'.txt'], 'w')	;
fprintf(fid, '%s,\t%s,\t%s,\t%s,\t%s\n', ...
             'Index','R','G','B','DE2000')		;
ctr = 0											;
for ind = 1:NumberOfAimPoints		
   ctr = ctr + 1						;
   fprintf(fid,'%d\t%5.4f\t%5.4f\t%5.4f\t%5.4f',...
       ctr,...
	   FinalRGBs(ind,1),...
	   FinalRGBs(ind,2),...
	   FinalRGBs(ind,3),...				
	   MinDEs(ind))			;

   % To avoid an extra line in the output file, make sure a line return is
   % not used in the last line, but is used for every other line.
   if ctr ~= NumberOfAimPoints		%NumOfLines
       fprintf(fid,'\n')				;
   end
end
fclose(fid)								;

% Write out file that gives best DEs, as well as all reflectances
ReflectanceDataFile = [Name,IllumObsNoSlashes,'RGBreflectances.txt']	;
fid = fopen(ReflectanceDataFile, 'w')									;
fprintf(fid, '%s,%s,%s,%s,%s,%s,%s,%s,%s', ...
             'Index','x','y','Y','Status','R','G','B','DE2000')		;
NumOfWavelengths = size(FinalWavelengths,2)		;
for ctr = 1:NumOfWavelengths
    fprintf(fid, ',%d', FinalWavelengths(1,ctr))
end
fprintf(fid, '\n')	;
fclose(fid)			;
dlmwrite(ReflectanceDataFile, RGBresults, ',', '-append')	;


% Print a display of the aimpoints which have been matched.
disp([' ']);
disp(['The figure shows the matches for the input aimpoints.  Aimpoints which are'])	;
disp(['out of gamut, or could not be matched, are left blank.  ',num2str(AimPointsFound),' colours'])	;
disp(['are displayed.  The RGBs for the aimpoints appear in the file ',Name,'BestRGBList',IllumObsNoSlashes,'.txt.'])
disp(['The last column of the file gives the best DE obtained.'])
RGBsOfMatches = []						;
[AProws,~] = size(AimPointResults)		;
for ind = 1:APctr
    if MinDEs(ind) < DEthreshold
	    RGBsOfMatches(ind,:) = [FinalRGBs(ind,1), FinalRGBs(ind,2), FinalRGBs(ind,3)]	;
	else
	    RGBsOfMatches(ind,:) = [1 1 1]						;
	end
end	
PrintRGBs(RGBsOfMatches, [Name,'RGBresults'])						;