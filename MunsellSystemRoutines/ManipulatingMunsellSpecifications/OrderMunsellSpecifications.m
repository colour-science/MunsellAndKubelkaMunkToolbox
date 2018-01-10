function [SortedListVectors, SortedListStrings, SortedIndices] = ...
							 OrderMunsellSpecifications(RawMunsellSpecs);
% Purpose		Order a list of Munsell specifications sequentially by hue, value, and chroma.
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
%				When a list of Munsell specifications is given, it is often helpful to order
%				the list meaningfully.  This routine accomplishes that goal.  The specifications
%				in the list are first ordered by hue (in order R, RP, P, PB, B, BG, G, GY, Y, YR).
%				If multiple specifications have the same hue, then they are ordered within
%				that hue first by value (from 0 to 10), and then by chroma (from 0 to infinity).
%				Greys, or neutral 'hues,' are placed before chromatic hues, and are ordered
%				just by value.
%
%				This routine will take a list of Munsell specifications either as strings, or
%				in ColorLab vector form.
%
%				RawMunsellSpecs	Either a list of Munsell specifications, such as 4.2R8.1/5.3,
%								or a matrix, each row of which is a Munsell vector in ColorLab 
%								format.  A list of strings should be indicated by {}.  The entry
%								might also be a single string, which will be converted to a
%								one-element list
%
%				SortedListStrings	A sorted list of the input Munsell specifications, expressed
%									as strings, such as 4.2R8.1/5.3
%
%				SortedListVectors	A sorted list of the input Munsell specifications, expressed
%									as a four-column matrix, each row of which is a vector in 
%									Colorlab format
%
%				SortedIndices		The indices of the input specifications, after sorting
%		
% Author		Paul Centore (March 23, 2015)
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

% Initialize output variables
SortedListVectors = []	;
SortedListStrings = {}	;
SortedIndices     = []	;

% Determine whether the input Munsell specifications are strings or vectors.  Replace the
% input RawMunsellSpecs with an internal variable MunsellSpecs.
if isempty(RawMunsellSpecs)	% No Munsell specifications have been input
	return		% Return initialized outputs, which are all empty
elseif ischar(RawMunsellSpecs)	% The specification is a single string
	MunsellSpecs{1} = RawMunsellSpecs	;
	SpecsAreStrings = true				;
	SpecsAreVectors = false				;
	NumberOfSpecs   = 1					;
else
	MunsellSpecs = RawMunsellSpecs		;
	if ismatrix(MunsellSpecs)	% The specifications are a four-column matrix of row vectors
		SpecsAreStrings = false					;
		SpecsAreVectors = true					;
		NumberOfSpecs   = size(MunsellSpecs,1)	;
	else	% The specifications are a list, denoted by {}, of character strings
		SpecsAreStrings = true					;
		SpecsAreVectors = false					;
		NumberOfSpecs   = length(MunsellSpecs)	;
	end
end	


% Find hues, values, and chromas of all input Munsell specifications (hues are undefined
% for neutral specifications)
[Values, Chromas] = ValuesAndChromasOfMunsellSpecifications(MunsellSpecs)	;
ASTMHues          = ASTMHuesOfMunsellSpecifications(MunsellSpecs)			;	

% Determine which input specifications are neutrals and which are chromatic
IndicesOfNeutrals = CheckIfMunsellSpecificationsAreNeutrals(MunsellSpecs);
% Remove the neutrals from the input list.  The neutrals and chromatic colours will be
% ordered separately.  
AllIndices          = 1:NumberOfSpecs						;							
IndicesOfChromatics = setdiff(AllIndices,IndicesOfNeutrals)	;					

% Tally all the hues, values, and chromas for chromatic specifications
ChromaticASTMhues = ASTMHues(IndicesOfChromatics)	;	
ChromaticValues   = Values(IndicesOfChromatics)		;	
ChromaticChromas  = Chromas(IndicesOfChromatics)		;	
% Combine the hues, values, and chromas for the chromatic colours into one matrix
HVC = [ChromaticASTMhues, ChromaticValues, ChromaticChromas]	;

% Sort the chromatic colours by hue, then value, then chroma
if isempty(HVC)		% Handle the case where there are no chromatic colours
	SortedChromaticColours = []	;
	SortedChromaticIndices = []	;
else
	[SortedChromaticColours, TempSortedIndices] = sortrows(HVC,[1 2 3])	;
	SortedChromaticIndices = IndicesOfChromatics(TempSortedIndices)		;
end

% Find the Munsell values for neutral colours.
NeutralValues = Values(IndicesOfNeutrals)	;

% Sort the neutral colours by value
if isempty(NeutralValues)		% Handle the case where there are no neutral colours
	SortedNeutralColours = []	;
	SortedNeutralIndices = []	;
else
	[SortedNeutralColours, TempSortedIndices] = sort(NeutralValues)	;
	SortedNeutralIndices = IndicesOfNeutrals(TempSortedIndices)		;
end

% Combine the neutral and chromatic colour lists, which have been ordered individually,
% into one master ordered list, placing the neutrals first
SortedIndices = [SortedNeutralIndices, SortedChromaticIndices]	;
% Reorder the input specification lists, returning lists as both strings and vectors
if SpecsAreStrings
	for ctr = 1:NumberOfSpecs
		MunsellString = MunsellSpecs{SortedIndices(ctr)}	;	% Extract Munsell string
		MunsellString = upper(MunsellString)	;
		% Save the re-ordered specification as a string
		SortedListStrings{ctr} = MunsellString				;
		% Save the re-ordered specification as a four-element vector
		MunsellVector          = MunsellSpecToColorLabFormat(MunsellString)	;
		if length(MunsellVector) == 1
			MunsellVector = [0 MunsellVector(1) 0 0]	;
		end
		SortedListVectors(ctr,:) = MunsellVector		;
	end
else	% Specifications were input as vectors
	for ctr = 1:NumberOfSpecs
		MunsellVector = MunsellSpecs(SortedIndices(ctr),:)	; % Extract Munsell vector
		% Save the re-ordered specification as a string
		MunsellString          = ColorLabFormatToMunsellSpec(MunsellVector)	;
		SortedListStrings{ctr} = MunsellString				;
		% Save the re-ordered specification as a four-element vector
		SortedListVectors(ctr,:) = MunsellVector		;
	end
end