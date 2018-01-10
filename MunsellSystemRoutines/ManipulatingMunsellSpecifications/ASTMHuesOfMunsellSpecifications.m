function [ASTMHues] = ASTMHuesOfMunsellSpecifications(RawMunsellSpecs);

% Purpose		Find the ASTM hues of an input set of Munsell specifications.
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
%				It is natural to make the Munsell hues into a circle, with PB being followed
%				by B.  [ASTMD1535-08, Fig. 1] labels the angles on the circle modularly from
%				0 to 100, with 0 and 100 both corresponding to 10RP.  The following assignments
%				are made:
%											5R		5
%											5Y		25
%											5G		45
%											5B		65
%											5P		85
%										  10RP		100, 0
%								      epsilonR		epsilon.
%
%				This routine returns the ASTM hue numbers for the input Munsell
%				specifications.  If the Munsell specification is a neutral, then it has no
%				hue.  In this case, its ASTM hue number is set to NaN as a flag.
%				This routine will take a list of Munsell specifications either as strings, or
%				in ColorLab vector form.
%
%				[ASTMD1535-08] ASTM, Standard D 1535-08, "Standard Practice for Specifying Color by the
%					Munsell System," approved January 1, 2008.
%
%				RawMunsellSpecs	Either a list of Munsell specifications, such as 4.2R8.1/5.3,
%								or a matrix, each row of which is a Munsell vector in ColorLab 
%								format.  A list of strings should be indicated by {}.  The entry
%								might also be a single string, which will be converted to a
%								one-element list
%
%				ASTMHues	The ASTM hues corresponding to the input Munsell specs (neutrals
%							are denoted by the entry NaN)
%
% Author		Paul Centore (June 3, 2015)
% Revision		Paul Centore (February 18, 2017)
%				----Revised checking for vector vs. cell structure input
%				----Allowed input Munsell entries to be 'NA' or 'ERROR,' assigning an output
%					of NaN in those cases
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

% Determine whether the input Munsell specifications are strings or vectors.  Replace the
% input RawMunsellSpecs with an internal variable MunsellSpecs.
if ischar(RawMunsellSpecs)	% The specification is a single string
	MunsellSpecs{1} = RawMunsellSpecs	;
	SpecsAreStrings = true				;
	SpecsAreVectors = false				;
	NumberOfSpecs   = 1					;
else
	MunsellSpecs = RawMunsellSpecs		;
	if iscell(MunsellSpecs) 	% The specifications are a list, denoted by {}, of character strings
		SpecsAreStrings = true					;
		SpecsAreVectors = false					;
		NumberOfSpecs   = length(MunsellSpecs)	;
	else	% The specifications are a four-column matrix of row vectors
		SpecsAreStrings = false					;
		SpecsAreVectors = true					;
		NumberOfSpecs   = size(MunsellSpecs,1)	;
	end
end	

% Initialize output variables
ASTMHues  = -99 * ones(NumberOfSpecs,1);

% Determine which input specifications are neutrals
IndicesOfNeutrals = CheckIfMunsellSpecificationsAreNeutrals(MunsellSpecs);

% If an input colour is a neutral grey, then set its ASTM hue to not-a-number (NaN)
ASTMHues(IndicesOfNeutrals) = NaN	;

% Remove the neutrals from the input list.  
AllIndices          = 1:NumberOfSpecs						;							
IndicesOfChromatics = setdiff(AllIndices,IndicesOfNeutrals)	;					

% Find the ASTM hues for the chromatic colours.
for ctr = IndicesOfChromatics
	% Convert to ColorLab form
	if SpecsAreStrings
		MunsellString = MunsellSpecs{ctr}	 	;	% Extract Munsell string
		MunsellString = upper(MunsellString)	;
		% Check whether a particular Munsell string in the input list is unavailable
		if ~strcmp(MunsellString,'NA') && ~strcmp(MunsellString,'Error') 
			MunsellVector = MunsellSpecToColorLabFormat(MunsellString)	;
		else
			MunsellVector = [NaN NaN NaN NaN]	;	% No information available
		end
	else
		MunsellVector = MunsellSpecs(ctr,:)		;	% Extract Munsell vector
	end
	% Extract the Munsell hue letter designation and numerical hue prefix
	HueLetterCode = MunsellVector(4)	;
	HueNumber     = MunsellVector(1)	;
	% Convert to the ASTM hue specification
	if isnan(HueLetterCode) || isnan(HueNumber)	% I.e., no Munsell entry
		ASTMHue = NaN											;
	else
		ASTMHue = MunsellHueToASTMHue(HueNumber,HueLetterCode)	;
	end
	% Save the ASTM hue in the output vector
	ASTMHues(ctr) = ASTMHue	;
end