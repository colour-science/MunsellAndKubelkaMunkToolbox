function [sRGBs, OutOfGamutFlag] = ReflectanceSpectrumTosRGB(Wavelengths, ReflectanceSpectra);
% Purpose		Given the reflectance spectrum of an object colour, calculate the 
%				sRGB coordinates for that colour (i.e. the sRGB signal whose CIE
%				coordinates agree with the CIE coordinates produced when an object
%				with that reflectance spectrum is illuminated by D65
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
%				spectral power densities (SPDs) that reach a viewer s eye. A visual stimulus 
%				is produced when a light source reflects off a surface colour and reaches an
%				eye.  For this routine, the light source is assumed to have the distribution of
%				Illuminant D65.
%
%				At each pixel, a computer monitor produces an SPD by combining a red, green
%				and blue (RGB) signal.  This SPD can be chosen to agree with the SPD produced
%				by a particular reflectance spectrum under Illuminant D65.  The sRGB standard
%				specifies the SPD of each red, green or blue signal, and the way they combine
%				(mainly linear) to produce new SPDs.  The sRGB standard is chosen so that
%				the monitor s white (when the red, green, and blue signals are at full
%				intensity) has the same chromaticity as Illuminant D65.  An ideal white object
%				(which reflects 100% of the light at every wavelength) would also produce
%				an SPD with the chromaticity of Illuminant D65, when illuminated by D65.
%
%				This interpretation allows us to convert naturally from a reflectance spectrum
%				to a set of sRGB coordinates, which this routine does.  The routine first
%				calculates the CIE coordinates, as XYZs, for each reflectance spectrum, and
%				then uses the sRGB standard to invert the XYZ to find the sRGB coordinates.
%				
%				Wavelengths			A row vector whose entries are the wavelengths for the reflectance  
%									spectra.  The wavelengths should be evenly spaced
%
%				ReflectanceSpectra	A matrix, whose rows are the reflectances (expressed as values 
%									between 0 and 1) for various reflectance spectra at the wavelengths
%									listed in the first input.  Each row corresponds to a separate
%									spectrum
%
%				sRGBs				A three-column output matrix, the ith row of which is the
%									sRGB coordinates for the ith reflectance spectrum
%
%				OutOfGamutFlag		A Boolean vector with as many entries as there are input
% 									input reflectance spectra.  It is TRUE whenever the spectrum
%									cannot be converted to an sRGB
%
% Author		Paul Centore (February 12, 2017)
%
% Copyright 2017 Paul Centore
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

% To avoid reloading data, save the data in a local variable once it is loaded
persistent ColourMatchingFunctions	% Matrix of the form [wavelength (nm)|xbar|ybar|zbar]
persistent IlluminantD65			% Matrix of the form [wavelength (nm)|power at that wavelength for Illuminant D65]

% Initialize the output variable sRGBs, which is a three-column matrix.  The ith row gives
% the sRGB coordinates for ith reflectance spectrum.  Also initialize the vector OutOfGamutFlag
sRGBs          = []	;
OutOfGamutFlag = []	;

% Check to make sure all reflectances are between 0 and 1
if max(max(ReflectanceSpectra)) > 1.0 || min(min(ReflectanceSpectra)) < 0.0
    disp(['Error (in ReflectanceSpectrumTosRGB): Reflectances must be between 0 and 1.'])
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

% Interpolate to find colour matching functions at wavelengths used for input reflectance spectra
Interpxbar = interp1(ColourMatchingFunctions(:,1), ColourMatchingFunctions(:,2), Wavelengths)		;
Interpybar = interp1(ColourMatchingFunctions(:,1), ColourMatchingFunctions(:,3), Wavelengths)		;
Interpzbar = interp1(ColourMatchingFunctions(:,1), ColourMatchingFunctions(:,4), Wavelengths)		;
% Write these values as vertical vectors
Interpxbar = reshape(Interpxbar, length(Interpxbar), 1)	;
Interpybar = reshape(Interpybar, length(Interpybar), 1)	;
Interpzbar = reshape(Interpzbar, length(Interpzbar), 1)	;

% If the data for Illuminant D65 has not been loaded, then load it now
if isempty(IlluminantD65)
	IlluminantD65 = illuminant('D65',Wavelengths)	;
end

% Find normalizing factor for Illuminant D65 source.  If the reflectance spectrum is 100 percent
% at each wavelength, then the resulting visual stimulus should have value 1 for CIE coordinate Y
k = 1/(sum(IlluminantD65 * Interpybar))				;

% Loop through all colour samples in CSV file.  Each such colour sample
% is a row in the ReflectanceSpectra matrix
[NumOfSamples,~] = size(ReflectanceSpectra)			;

% Suppose the sample is illuminated by a source that is distributed like Illuminant D65.  At
% each wavelength, the sample reflects a percentage of the source.  The reflected spectral
% power density (SPD) is a new stimulus, whose CIE and Munsell coordinates will be found.
ReflectedSPD = ReflectanceSpectra .* IlluminantD65	;
% Integrate against the colour matching functions, to find CIE XYZ coordinates
X = k * (ReflectedSPD * Interpxbar)		;
Y = k * (ReflectedSPD * Interpybar)		;
Z = k * (ReflectedSPD * Interpzbar)		;
% Combine individual coordinates into one matrix
XYZ = [X Y Z]	;

% Convert XYZ coordinates to sRGB coordinates	
[sRGBs, OutOfGamutFlag] = xyz2srgb(XYZ)	;

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