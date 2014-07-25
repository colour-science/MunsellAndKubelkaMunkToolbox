function [MaxChroma Status] = MaxChromaForExtrapolatedRenotation(HueNumPrefix, CLHueLetterIndex, Value);
% Purpose		For a given hue and value, find the maximum chroma possible, when interpolating
%				over the extrapolated Munsell renotation data.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form HV/C.  The value is a number between 0 and 10,
%				although for practical purposes value usually ranges only from 1 to 9.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.6R8.2/4.1 is a light pastel
%				red, while N3 is a dark grey.
%
%				The 1943 Munsell renotation ([Newhall1943]) expressed Munsell specifications
%				in terms of a color system standardized by the Commission Internationale de 
%				l Eclairage (CIE).  Table I of [Newhall1943] lists CIE coordinates for
%				different combinations of H, V, and C.  For each combination of H and V,
%				the renotation has a maximum C; if chroma were greater than this maximum,
%				then the specification would not define a colour that could be perceived.
%				The maximum chroma can be seen as an approximation to the MacAdam limit.
%				It is only an approximation because the renotation chromas are all even
%				integers, whereas, in theory, a chroma could take on any positive value.
%
%				To aid in interpolation, the renotation data has been
%				extrapolated, sometimes beyond the MacAdam limits, in the file all.dat from
%				[MCSL2010].  The file all.dat has been modified and renamed 
%				ExtrapolatedMunsellRenotation.txt.  This routine uses the extrapolated 
%				renotation data.
%
%				The Munsell renotation only provides data for hues whose numerical prefix is
%				2.5, 5, 7.5, or 10.  Another routine, MakeExtrapolatedRenotationMatrices, 
%				constructs a matrix, called MaxExtRenChromaMatrix, that records the MacAdam limits 
%				for those Munsell hues.  MaxExtRenChromaMatrix is doubly indexed, by
%				hue and value.  The hues are taken from the list HueIndex,
%				described below, except that the 41st entry,
%				for greys, is not used.  The values run from 1 to 9.  Entry (H,V) in
%				MaxExtRenChromaMatrix is the maximum chroma in the renotation data for a colour of
%				hue H and value V.  
%
%				HueIndex goes from 0 to 41, corresponding to Munsell hues, as follows:
%					1 2.5R	 |	 9 2.5Y  |	17 2.5G  |	25 2.5B  |	33 2.5P  |	41 N
%					2 5R	 |	10 5Y	 |	18 5G    |	26 5B    |	34 5P    |
%					3 7.5R	 |	11 7.5Y	 |	19 7.5G  |	27 7.5B  |	35 7.5P  |
%					4 10R	 |	12 10Y   |	20 10G   |	28 10B   |	36 10P   |
%					5 2.5YR |	13 2.5GY |	21 2.5BG |	29 2.5PB |	37 2.5RP |
%					6 5YR	 |	14 5GY   |	22 5BG   |	30 5PB   |	38 5RP   |
%					7 7.5YR |	15 7.5GY |	23 7.5BG |	31 7.5PB |	39 7.5RP |
%					8 10YR	 |	16 10GY  |	24 10BG  |	32 10PB  |	40 10RP  |
%
%				The value index runs from 1 to 9, and is equal to the Munsell value.
%
%				Interpolation to find function values for an arbitrary Munsell specification
%				often requires evaluating the function at canonical Munsell specifications
%				(i.e value is an integer, hue is prefixed by 2.5, 5, 7.5, or 10, and
%				chroma is an even integer) for which data is available, and which are
%				close to the arbitrary specification.  Evaluating a function at an arbitrary
%				Munsell specification requires evaluating it at eight neighboring
%				canonical specifications (arbitrary value bounded by two canonical
%				values, arbitrary hue by two canonical hues, and arbitrary chroma by
%				two canonical chromas).  
%
%				In the case this routine handles, only the Munsell hue and value are
%				input, and the maximum chroma is found.  The maximum chroma can be no
%				higher than the smallest chroma possible for all neighboring canonical
%				specifications.  Since chroma is being solved for, this routine finds
%				four neighboring canonical points (two value bounds and two hue bounds),
%				and then finds the maximum chroma (the MacAdam limit) for those four.
%				The smallest MacAdam limit is chosen as the output.  
%
%				As long as the chroma of an arbitrary Munsell specification, with the
%				input hue and value, is less than MaxChroma, interpolation routines that
%				use neighboring canonical Munsell specifications can be evaluated.
%
%				[MCSL2010] http://www.cis.rit.edu/mcsl/online/munsell.php, as of June 12, 2010
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		[MaxChroma Status] = MaxChromaForExtrapolatedRenotation([HueNumPrefix, CLHueLetterIndex, Value]);
%
%				HueNumPrefix	First entry in ColorLab format for Munsell specifications.
%
%				CLHueLetterIndex	2nd entry in ColorLab format for Munsell specifications
%
%				Value			Munsell value
%
%				MaxChroma	The maximum chroma, for the input Munsell hue and value, at which
%							one can perform an interpolation that requires evaluation at
%							neighboring standard Munsell specifications.
%
%				Status			A return code with two fields.  The second field is a list
%								of possible return messages.  The first field is a positive
%								integer indicating one of the return messages.  
%
% Related		MakeExtrapolatedRenotationMatrices
% Functions
%
% Required		
% Functions		
%
% Author		Paul Centore (June 20, 2010)
% Revision		Paul Centore (December 26, 2012)  
%				 ---Moved from MunsellConversions program to MunsellToolbox.
% Revision		Paul Centore (August 31, 2013)  
%				 ---Moved from MunsellToolbox program to MunsellAndKubelkaMunkToolbox.
%
% Copyright 2010, 2012 Paul Centore
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

% Initialize default return values
MaxChroma = -99		;
Status.Messages = {'Success',...
    'Munsell value must be between 1 and 10',...
	};
Status.ind = -99	;

if Value >= 9.99			% Colour is ideal white, which has no chroma
   MaxChroma = 0		;
   Status.ind = 1		;
   return				;
end
	
% Load extrapolated MacAdam limit data if necessary, but only once, to save time
persistent MaxExtRenChromaMatrix
if isempty(MaxExtRenChromaMatrix)
   load MaxChromaForExtrapolatedRenotation.mat 
end

% Bound Munsell value between two values, ValueMinus and ValuePlus, for which Munsell
% reflectance spectra are available.  Currently, the Munsell values for which data is
% available are 1 or greater.
if Value < 1 
   Status.ind = 2;		% Set error and return
   return
end

if mod(Value,1) == 0	% input value is already integer
   ValueMinus = Value;
   ValuePlus  = Value;
else					% Input value is not integer
   ValueMinus = floor(Value)		;
   ValuePlus  = ValueMinus + 1		;
end

% Bound the Munsell hue between two canonical hues.  One of the hues is immediately
% clockwise to the input hue in the CIE diagram, and the other is 
% immediately counterclockwise.  Express the canonical hues
% in terms of the hue list in the description, so that they can be used as indices to
% the extrapolated MacAdam matrix.
[ClockwiseHue, CtrClockwiseHue] = BoundingRenotationHues(HueNumPrefix, CLHueLetterIndex);
CLHueNumPrefixCW    = ClockwiseHue(1)		 ;
CLHueLetterIndexCW  = ClockwiseHue(2)		 ;
CWHueIndex          = (4*mod(7-CLHueLetterIndexCW, 10)) + (CLHueNumPrefixCW/2.5)	;
CLHueNumPrefixCCW   = CtrClockwiseHue(1)	 ;
CLHueLetterIndexCCW = CtrClockwiseHue(2)	 ;
CCWHueIndex         = (4*mod(7-CLHueLetterIndexCCW, 10)) + (CLHueNumPrefixCCW/2.5)	;

% Combine the two value bounds and two hue bounds to produce four hue-value 
% combinations.  Find the MacAdam limit for each of these combinations.
MALimitVMCW  = MaxExtRenChromaMatrix(CWHueIndex,  ValueMinus)	;
MALimitVMCCW = MaxExtRenChromaMatrix(CCWHueIndex, ValueMinus)	;
if ValuePlus <= 9		% Handle values between 9 and 10 separately
   MALimitVPCW  = MaxExtRenChromaMatrix(CWHueIndex,  ValuePlus)	;
   MALimitVPCCW = MaxExtRenChromaMatrix(CCWHueIndex, ValuePlus)	;
   % The maximum chroma at which an interpolating function can be evaluated is the
   % minimum of the maximum chromas for which all neighboring canonical points
   % can be evaluated.
   MaxChroma = min([MALimitVMCW, MALimitVMCCW, MALimitVPCW, MALimitVPCCW]); 
else					% Input value is between 9 and 10; use geometric calculation
   FactorList        = MunsellValueToLuminanceFactor(9)		;
   LuminanceFactor9  = FactorList.ASTMD153508				;
   FactorList        = MunsellValueToLuminanceFactor(10)	;
   LuminanceFactor10 = FactorList.ASTMD153508				;
   FactorList        = MunsellValueToLuminanceFactor(Value)	;
   LuminanceFactorV  = FactorList.ASTMD153508				;
   MaxCWchroma  = interp1([LuminanceFactor9 LuminanceFactor10], [MALimitVMCW 0],  LuminanceFactorV)	;
   MaxCCWchroma = interp1([LuminanceFactor9 LuminanceFactor10], [MALimitVMCCW 0], LuminanceFactorV)	;
   MaxChroma    = min(MaxCWchroma, MaxCCWchroma)													;
end

% Set success code and return
Status.ind = 1;
return;