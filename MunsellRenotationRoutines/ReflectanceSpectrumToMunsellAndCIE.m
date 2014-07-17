function [MunsellSpecs, MunsellSpecsColorlab CIEcoords] = ReflectanceSpectrumToMunsellAndCIE(Wavelengths, ReflectanceSpectra);
% Purpose		Given the reflectance spectrum of an object colour, calculate the 
%				CIE and Munsell coordinates of the visual stimulus produced when that colour is
%				illuminated by Illuminant C.
%
% Description	The reflectance spectrum of a surface colour gives the percentage of
%				light reflected by that surface colour, at each wavelength.  In this
%				routine, the input variable Wavelengths gives a set of wavelengths
%				(in nm), and the input variable ReflectanceSpectra gives the percentage
%				of light reflected, for each wavelength.  ReflectanceSpectra can actually
%				be a matrix, each row of which gives a reflectance spectrum for a different
%				surface colour.
%
%				CIE coordinates, such as XYZ, or xyY, are used for visual stimuli, which are
%				power spectral densities (PSDs) that reach a viewer's eye. A visual stimulus %'
%				is produced when a light source reflects off a surface colour and reaches an
%				eye.  For this routine, the light source is assumed to have the distribution of
%				Illuminant C, which is the standard illuminant for the Munsell colour system.
%				This routine returns the CIE coordinates, in both XYZ and xyY coordinate systems,
%				of the input surface colours, when illuminated by Illuminant C.
%
%				The Munsell system is a perceptual colour coordinate system.  It
%               specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form HV/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R 9.0/4.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				Routines in ColorLab use the Munsell specifications, but not necessarily the
%				Munsell notation HV/C.  A Munsell vector is given by [H1, V, C, H2], where 
%				H1 is the number designator for hue, H2 is the position of the hue letter 
%				designator in the list
%				                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
%				V is the Munsell value, and C is the Munsell chroma. For example, 
%				5.0R 9.0/4.0 is [5 9 4 7] in ColorLab
%				format.  A neutral Munsell grey is a one-element vector in ColorLab
%				format, consisting of the grey value.  For example, N4 is [4] in ColorLab
%				format.
%
%				In addition to calculating CIE coordinates for the input object colours,
%				this routine also calculates Munsell coordinates.  The Munsell coordinates are
%				converted from the CIE coordinates.  The conversion code can be slow, and 
%				Munsell coordinates are not always necessary, so a related routine,
%				ReflectancesToCIEwithWhiteY100.m, can be used for calculations where only
%				CIE coordinates are required.  
%
% Syntax		[CIEcoords, MunsellSpec] = ReflectanceSpectrumToMunsellAndCIE(Wavelengths, ReflectanceSpectra)
%
%				Wavelengths			A row vector whose entries are the wavelengths for the reflectance  
%									spectra.  The wavelengths must be evenly spaced
%
%				ReflectanceSpectra	A matrix, whose rows are the reflectances (expressed as values 
%									between 0 and 1) for various reflectance spectra at the wavelengths
%									listed in the first input
%
%				MunsellSpecs		An output list, each entry of which is the Munsell string for an input
%									reflectance spectrum 
%
%				MunsellSpecsColorlab	An output matrix, each row of which is the Munsell specification 
%									for an input reflectance spectrum.  Each row has the form
%									[NumericalHuePrefix, Value, Chroma, HueNumber], which is suitable for
%									internal use in Colorlab or other programs
%
%				CIEcoords			An output matrix, each of whose rows gives [X Y Z x y Y] coordinates
%									for the input reflectance spectra, under Illuminant C
%
% Author		Paul Centore (May 24, 2012)
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
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

persistent ColourMatchingFunctions	% Matrix of the form [wavelength (nm)|xbar|ybar|zbar]
persistent IlluminantC				% Matrix of the form [wavelength (nm)|power at that wavelength for Illuminant C]

% Check to make sure all reflectances are between 0 and 1
if max(max(ReflectanceSpectra)) > 1.0 || min(min(ReflectanceSpectra)) < 0.0
    disp(['Error: Reflectances must be between 0 and 1.'])
	return
end

% If the 1931 colour matching functions have not yet been loaded, then load them now
if isempty(ColourMatchingFunctions)
   fid = fopen('1931ColourMatchingFunctions.txt')	;

   % Read through and ignore the description at the start of the file.
   % The line 'DESCRIPTION ENDS HERE' has been added to the file, to
   % indicate when the description ends.
   FileLine = fgetl(fid)				;
   while strcmp(FileLine, 'DESCRIPTION ENDS HERE') == false
      FileLine = fgetl(fid)				;
   end

   % Apart from a header, the data file is a matrix of four columns.  The first column
   % is the wavelength, in nanometers.  The second, third, and fourth columns, respectively,
   % are entries for the x-bar, y-bar, and z-bar functions.
   ColourMatchingFunctions = []			;
   ctr  = 0								;
   while ~feof(fid)
      ctr = ctr + 1						;  
      % Read in entries for one wavelength
      wavelengthIn = fscanf(fid,'%f',1)	;
      xbarIn       = fscanf(fid,'%f',1)	;
      ybarIn       = fscanf(fid,'%f',1)	;
      zbarIn       = fscanf(fid,'%f',1)	;
      ColourMatchingFunctions = [ColourMatchingFunctions; wavelengthIn xbarIn ybarIn zbarIn];
   end
   fclose(fid);
end

% If the data for Illuminant C has not been loaded, then load now
if isempty(IlluminantC)
   fid = fopen('IlluminantC.txt')		;

   % Read through and ignore the description at the start of the file.
   % The line 'DESCRIPTION ENDS HERE' has been added to the file, to
   % indicate when the description ends.
   FileLine = fgetl(fid)				;
   while strcmp(FileLine, 'DESCRIPTION ENDS HERE') == false
      FileLine = fgetl(fid)				;
   end

   % Apart from a header, the data file is a matrix of two columns.  The first column
   % is the wavelength, in nanometers.  The second column is the relative power
   % for Illuminant C, at that wavelength.
   IlluminantC = []			;
   ctr  = 0								;
   while ~feof(fid)
      ctr = ctr + 1						;  
      % Read in entries for one wavelength
      wavelengthIn = fscanf(fid,'%f',1)	;
      powerIn       = fscanf(fid,'%f',1)	;
      IlluminantC = [IlluminantC; wavelengthIn powerIn];
   end
   fclose(fid);
end

% Interpolate to find colour matching functions at wavelengths used for reflectance spectrum in CSV file
Interpxbar = interp1(ColourMatchingFunctions(:,1), ColourMatchingFunctions(:,2), Wavelengths)		;
Interpybar = interp1(ColourMatchingFunctions(:,1), ColourMatchingFunctions(:,3), Wavelengths)		;
Interpzbar = interp1(ColourMatchingFunctions(:,1), ColourMatchingFunctions(:,4), Wavelengths)		;

% Interpolate to find Illuminant C at wavelengths used for reflectance spectra in CSV file
InterpIllumC = interp1(IlluminantC(:,1), IlluminantC(:,2), Wavelengths)		;

% Assume that the wavelengths are equally spaced, and find the spacing
dlambda = Wavelengths(2) - Wavelengths(1)					;

% Find normalizing factor for Illuminant C source.  If the reflectance spectrum is 100 percent
% at each wavelength, then the result visual stimulus should have value 1 for CIE coordinate Y
k = 100/(sum(InterpIllumC .* Interpybar))					;

% Initialize output matrices and structures
MunsellSpecs = {}											;
MunsellSpecsColorlab = []									;
CIEcoords = []												;

% Loop through all colour samples in CSV file.  Each such colour sample
% is a row in the ReflectanceSpectra matrix
[NumOfSamples,~] = size(ReflectanceSpectra)					;
for ind = 1:NumOfSamples
if mod(ind,50) == 0
    disp(['Munsell conversions: ', num2str(ind), ' of ', num2str(NumOfSamples)]);
	fflush(stdout);
end
	% The reflectance spectrum for a particular spectrum is one row in the Reflectances matrix
	SampleReflectances = ReflectanceSpectra(ind,:)			;
	% Suppose the sample is illuminated by a source that is distributed like Illuminant C.  At
	% each wavelength, the sample reflects a percentage of the source.  The reflected spectral
	% power density (SPD) is a new stimulus, whose CIE and Munsell coordinates will be found.
	ReflectedSPD       = SampleReflectances .* InterpIllumC ;
	% Integrate against the colour matching functions, to find CIE XYZ coordinates
	X = k * sum(ReflectedSPD .* Interpxbar)		;
	Y = k * sum(ReflectedSPD .* Interpybar)		;
	Z = k * sum(ReflectedSPD .* Interpzbar)		;
	% Convert XYZ coordinates to xyY coordinates
	[x, y, Yrel] = XYZ2xyY(X, Y, Z)							;
	
	% Convert xyY coordinates to a Munsell specification	
	% First, check if the reflectance spectra is identically 100 %, or very close to it.  If
	% it is, assign a Munsell specification of N10.  This check is necessary because the
	% renotation inversion routine uses a fixed white point for Illuminant C.  The read-in
	% values for Illuminant C could be at intervals of 5 nm, 10 nm, etc., making the white point
	% disagree slightly with the white point used in xyYtoMunsell.  To avoid this issue, just
	% assign    		
	if min(SampleReflectances) >= 0.99
	    MunsellSpec = 'N10'									;
		MunsellVec  = [10]									;
	else		% Reflectance spectrum is not identically 100 percent
	    [MunsellSpec MunsellVec Status] = xyYtoMunsell(x, y, Yrel);
	    if Status.ind ~= 1		% Conversion to Munsell specification failed
	        MunsellSpec = 'NA'									;
		    disp(['Failure to convert from xyY to Munsell; xyY:',num2str(x),', ',num2str(y),', ',num2str(Yrel)])	;
	    end
	end
	% MunsellSpecsColorlab is a 4-column matrix, with one row for each reflectance spectrum.  The
	% row entries are the Munsell specification in ColorLab format.  If the colour is not neutral,
	% the ColorLab format has 4 entries.  If the colour is neutral, the ColorLab format has only
	% 1 entry.  In order to make one matrix, with 4 entries in each row, convert the 1-element
	% neutral format into a 4-element format.
	if strcmp(MunsellSpec, 'NA')  % No Munsell conversion found
		MunsellSpecsColorlab(ind,:) = [-99 -99 -99 -99]	;
	elseif length(MunsellVec) == 1		
	    MunsellSpecsColorlab(ind,:) = [0 MunsellVec 0 7]	;
	else
	    MunsellSpecsColorlab(ind,:) = [MunsellVec]			;
	end
	MunsellSpecs{ind}           = MunsellSpec				;
	
	CIEcoords(ind,:)            = [X Y Z x y Yrel]			;
end

PlotReflectanceSpectra = false				;		% Flag for plotting reflectance spectra
if PlotReflectanceSpectra == true
    figure
    for ind = 1:NumOfSamples
        plot(Wavelengths, ReflectanceSpectra(ind,:), 'k-')
	    hold on
    end
	set(gca, 'xlim', [300 800])
	set(gca, 'ylim', [0 1])
end