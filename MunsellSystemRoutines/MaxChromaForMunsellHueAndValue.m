function [MaxChroma Status] = MaxChromaForMunsellHueAndValue(HuePrefix, CLHueLetter, Value);
% Purpose		Find the maximum chroma possible for an input Munsell hue and value, when 
%				viewed under Illuminant C.
%
% Description	The Munsell system specifies a local colour by giving its hue (H), value (V),
%				and chroma(C) in the form HV/C.  The value is a number between 0 and 10.  
%				The chroma is a positive number, whose bound depends on hue and value,
%				as given by the MacAdam limits.  The hue specification consists of a letter
%				designator (B, BG, G, GY, Y, YR, R, RP, P, PB), and a number designator 
%				which is greater than 0, and less than or equal to 10.  If chroma is
%				0, then the local colour has no hue, and is specified as NV, where N is the
%				string "N," and V is the value.  For example, 5.0R9.0/4.0 is a light pastel
%				red, while N3 is a dark grey.
%
%				Routines in ColorLab use the Munsell specifications, but not necessarily the
%				Munsell notation HV/C.  A Munsell vector is given by [H1, V, C, H2], where 
%				H1 is the number designator for hue, H2 is the position of the hue letter 
%				designator in the list
%				                  {B, BG, G, GY, Y, YR, R, RP, P, PB},
%				V is the Munsell value, and C is the Munsell chroma. For example, 
%				5.0R9.0/4.0 is [5 9 4 7] in ColorLab format.  The three inputs to this
%				routine are H1, H2, and V, respectively.
%
%				This routine calculates the maximum chroma that is possible for an input Munsell
%				hue and value.  A bisection routine is used, in which the upper limit is a chroma
%				for which the hue-chroma-value combination is beyond the MacAdam limits, and the
%				lower limit is a chroma for which the hue-chroma-value combination is inside the
%				MacAdam limits.  The initial lower chroma limit is 0, giving a Munsell grey that
%				is always inside the MacAdam limits.  The initial upper chroma limit is 50, which
%				exceeds the maximum chroma for any Munsell sample, which is approximately 40.  A
%				colour with a chroma of 50 is therefore certain to be outside the MacAdam limits.
%
%				To be sure that the MacAdam limits are reached, this routine uses extrapolated
%				Munsell renotation values to calculate xyY coordinates for Munsell specifications.
%				As a result, the xyY coordinates found might be beyond the MacAdam limits.  After
%				calculating xyY, they are checked directly to see if they are within the MacAdam
%				limits.  The Munsell system has been standardized with Illuminant C, so the MacAdam
%				limits are calculated with respect to this illuminant.
%
% Syntax		[MaxChroma Status] = MaxChromaForMunsellHueAndValue(HuePrefix, CLHueLetter, Value);
%
%				HuePrefix		A value between 0 and 10 that prefixes a literal Munsell
%								hue description, such as the 6.3 in 6.3RP.
%
%				CLHueLetter		A numerical index to the list of Munsell hue strings,
%								that is given in the description.  For example, the index 2
%								corresponds to BG.
%
%				Value			A Munsell value between 1 and 9.
%
%				MaxChroma		The maximum chroma attainable by a colour of the input hue
%								and value.
%
%				Status			A return code with two fields.  The second field is a list
%								of possible return messages.  The first field is a positive
%								integer indicating one of the return messages.  
%
% Related		
% Functions
%
% Required		MunsellToxyY, IsWithinMacAdamLimits
% Functions		
%
% Author		Paul Centore (July 4, 2010)
% Revision   	Paul Centore (May 8, 2012)
%				 ---Changed != to ~= so that code would work in both Matlab and Octave.
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

% Make list of possible status return messages
Status.Messages = {'Success',...
                   'Value must be between 1 and 9',...
                   'Hue prefix must be between 0 and 10',...
				   };
				
% Check for valid inputs
if Value < 1 || Value > 9
   Status.ind = 2;		% Set error and return
   return
end
if HuePrefix < 0 || HuePrefix > 10
   Status.ind = 3;		% Set error and return
   return
end

% Set highest chroma tested above any Munsell chroma, and step downwards
% or upwards by bisection until the maximum chroma is found.
UniformMaxChroma = 50	;

% Determine MaxChroma to an accuracy of ChromaDifferenceThreshold
ChromaDifferenceThreshold = 0.01;

% Perform a bisection routine, in which the upper chroma value gives a
% colour that is beyond the MacAdam limits, and the lower chroma value gives
% a colour that is within the MacAdam limits.  When the upper and lower limits
% differ by a small enough amount, we can take the lower limit as the
% maximum chroma.
CurrentLowChroma  = 0									;
CurrentHighChroma = UniformMaxChroma					;
ChromaDifference  = CurrentHighChroma - CurrentLowChroma;
while ChromaDifference >= ChromaDifferenceThreshold
   % Calculate the chroma midway between the upper and lower limits, and see
   % whether the colour it gives is within the MacAdam limits.
   CurrentMidChroma = (CurrentHighChroma + CurrentLowChroma)/2			;
   MidMunsellSpec   = [HuePrefix, Value, CurrentMidChroma, CLHueLetter]	;
   [Midx Midy MidY MidStatus]     = MunsellToxyY(MidMunsellSpec);
   % Check the return status to see whether MidMunsellSpec is within the MacAdam limits.
   % If it is, use it as the new lower limit.  If it is not, use it as the new upper limit.
   if MidStatus.ind ~= 1		
      % xyY for mid colour cannot be calculated, even by extrapolation beyond the Munsell
	  % renotation.  Therefore, the mid colour is beyond the MacAdam limits
      CurrentHighChroma = CurrentMidChroma;
   else
   	  % xyY for mid colour can be calculated, but the calculation might involve extrapoloation
	  % beyond the MacAdam limits.  Check directly whether the xyY coordinates are 
	  % within the MacAdam limits.  Use Illuminant C, which is the standard illuminant for
	  % the Munsell system.
	  if(IsWithinMacAdamLimits(Midx, Midy, MidY, 'C'))
         CurrentLowChroma = CurrentMidChroma;
	  else
	     CurrentHighChroma = CurrentMidChroma;
	  end
   end
   
   % Calculate new difference between new chroma limits
   ChromaDifference  = CurrentHighChroma - CurrentLowChroma;
end

% After the bisection, use the lower chroma limit as the maximum chroma, to make
% sure that MaxChroma gives a colour within the MacAdam limits.  If MaxChroma is
% increased by ChromaDifferenceThreshold or more, the new colour will be outside
% the MacAdam limits.
MaxChroma = CurrentLowChroma	;

% Set successful status return code and return
Status.ind = 1;
return; 