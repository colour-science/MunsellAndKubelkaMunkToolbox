function [IndexOfBestMatch, MinDE2000Diff, BestMunsSpec, BestMunsSpecColorLab] = ...
			BestMatchInColorMunkiCSVfile(MunsellSpec, ColorMunkiCSVfile);
% Purpose		In an input file of colours, find the colour which most closely matches an
%				input target Munsell specification, as measured by the CIE DE 2000 colour difference,
%
% Description	The ColorMunki Design spectophotometer can measure a set of colour samples, and export
%				the measurements to a comma-separated value file, as a set of wavelengths and reflectance
%				percentages.  This routine finds the colour in such a file that is the closest match, in
%				terms of the CIE DE 2000 colour difference, to an input Munsell specification.
%
% Syntax		BestMatchInColorMunkiCSVfile(MunsellSpec, ColorMunkiCSVfile);
%
%				MunsellSpec			The Munsell specification that it is desired to match
%
%				ColorMunkiCSVfile	Comma-separated file produced using Export command of
%									ColorMunki Design
%
%				IndexOfBestMatch	The colour sample with this index is the best match for 
%									the input variable MunsellSpec
%
%				MinDE2000Diff		The CIE DE2000 difference between the input Munsell specification
%									and the colour in the file that is the closet match
%
%				BestMunsSpec		A string in the from H V/C that gives the Munsell coordinates
%									of the closest match in the file
%		
%				BestMunsSpecColorLab		A row vector, in ColorLab format, of the Munsell coordinates
%									of the closest match in the file
%
% Author		Paul Centore (May 19, 2012)
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

% Convert the information in the input file into a vector of wavelengths, and a 
% matrix of reflectance spectra
% Wavelengths	A row vector whose entries are the wavelengths for the reflectance  
%				spectra of the colour samples exported from a ColorMunki Design
%
% Reflectances	A matrix, whose rows are the reflectances (expressed as values 
%				between 0 and 1) for the reflectance spectra of the 
%				colour samples exported from a ColorMunki Design
[Wavelengths, Reflectances] = ColorMunkiCSVfileToOctaveFormat(ColorMunkiCSVfile);

% Find which reflectance spectrum is the closest to the input MunsellSpec, using
% the CIE DE2000 difference equation
[IndexOfBestMatch, MinDE2000Diff, BestMunsSpec, BestMunsSpecColorLab] = ...
			FindBestMatchForMunsell(MunsellSpec, Wavelengths, Reflectances);
