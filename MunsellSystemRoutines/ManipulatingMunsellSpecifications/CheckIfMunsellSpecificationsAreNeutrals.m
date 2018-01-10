function IndicesOfNeutrals = CheckIfMunsellSpecificationsAreNeutrals(RawMunsellSpecs);

% Purpose		Determine which of an input set of Munsell specifications are neutral colours.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
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
%				format; alternately, a grey could have its third entry be 0, in which case
%				the first and fourth entries are ignored; this form insures that all vectors
%				have four entries, so that they can be stacked in a matrix.
%
%				This routine finds which of the set of input colours are neutrals, and returns
%				a vector which gives the indices of the neutral input colours.  The input is
%				a list of Munsell specifications either as strings, or as Colorlab vectors.
%
%				RawMunsellSpecs	Either a list of Munsell specifications, such as 4.2R8.1/5.3,
%								or a matrix, each row of which is a Munsell vector in ColorLab 
%								format.  A list of strings should be indicated by {}.  The entry
%								might also be a single string, which will be converted to a
%								one-element list
%
%				IndicesOfNeutrals	The indices of the neutral inputs
%
% Author		Paul Centore (June 3, 2015)
% Revision		Paul Centore (November 21, 2016)
%				---Used iscell to check whether input variable is a list, indexed with {}
% Revision		Paul Centore (February 11, 2017)
%				---Added check for whether Munsell string is 'NA,' and thus not neutral
%
% Copyright 2015-2017 Paul Centore
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
% Initialize output variable
IndicesOfNeutrals = []	;

% Determine whether the input Munsell specifications are strings or vectors.  Replace the
% input RawMunsellSpecs with an internal variable MunsellSpecs.
if isempty(RawMunsellSpecs)	% No Munsell specifications have been input
	return		% Return empty list
elseif ischar(RawMunsellSpecs)	% The specification is a single string
	MunsellSpecs{1} = RawMunsellSpecs	;
	SpecsAreStrings = true				;
	SpecsAreVectors = false				;
	NumberOfSpecs   = 1					;
else
	MunsellSpecs = RawMunsellSpecs		;
	if iscell(MunsellSpecs)			% The specifications are a list, indexed by {}
		SpecsAreStrings = true					;
		SpecsAreVectors = false					;
		NumberOfSpecs   = length(MunsellSpecs)						;
	else 							% The specifications are a four-column matrix of row vectors
		SpecsAreStrings = false					;
		SpecsAreVectors = true					;
		NumberOfSpecs   = size(MunsellSpecs,1)	;
	end
end	

% Determine which input specifications are neutrals
if SpecsAreStrings
	for ctr = 1:NumberOfSpecs
		MunsellString = toupper(MunsellSpecs{ctr})	;	% Extract Munsell string
		if ~strcmp(MunsellString,'NA')	% Check whether Munsell string is NA
			LocationsOfN  = findstr(MunsellString, 'N')	;	% Look for occurrences of 'N'
			if ~isempty(LocationsOfN)	% If 'N' occurs, then the colour is a neutral
				IndicesOfNeutrals = [IndicesOfNeutrals, ctr]	;
			end
		end
	end
else	% Specifications are in Colorlab vector format
	for ctr = 1:NumberOfSpecs
		MunsellVector = MunsellSpecs(ctr,:)	;	% Extract Munsell vector
		if MunsellVector(3) == 0	% Chroma is 0, so colour is a neutral grey
			IndicesOfNeutrals = [IndicesOfNeutrals, ctr]	;
		end
	end
end