function LuminanceFactors = MunsellValueToLuminanceFactor(MunsellValue);
% Purpose		Convert a Munsell value into the percentage of light that a colour reflects.
%
% Description	A non-luminous sample of a colour reflects a certain percentage
%				of a light that illuminates it.  For human colour vision, this
%				percentage is calculated with respect to the human luminous
%				efficiency function, given by the photopic data for the CIE 1931
%				standard observer.  The Munsell value is a similar concept,
%				quantifying how light or dark a non-luminous colour sample is.
%				The reflected percentage of light is called the luminance factor.
%
%				The Munsell renotation ([Newhall1943]) redefined Munsell value as
%				a function of the percentage of light a sample reflects when
%				illuminated by Illuminant C.  Later, colour appearance models such as
%				CIELAB also expressed Munsell value as similar, but not identical,
%				functions of colorimetric measurements.  ASTM Standard D1535-08
%				[ASTMD1535-08] uses yet another conversion expression
%
%				This routine calculates multiple possible luminance factor.  The first
%				factor comes from a quintic polynomial suggested in [Newhall1943, p.
%				417].  The second factor is taken from the CIELAB colour appearance
%				model, as presented in ([Fairchild2005, Sect. 10.3]).  The third factor
%				is taken from [ASTMD1535-08], and differs from the quintic polynomial
%				by a multiplicative constant.  The possible luminance factors are 
%				returned in a data structure, which can be easily extended to include
%				other conversion methods.
%
%				[ASTMD1535-08] ASTM, Standard D 1535-08, "Standard Practice for Specifying Color by the
%					Munsell System," approved January 1, 2008.
%				[Fairchild2005] Mark D. Fairchild, Color Appearance Models, 2nd ed.,
%					John Wiley & Sons, Ltd., 2005.
%				[Newhall1943] S. M. Newhall, D. Nickerson, & D. B. Judd, "Final
%					Report of the O.S.A. Subcommittee on the Spacing of the Munsell
%					Colors," Journal of the Optical Society of America, Vol. 33,
%					Issue 7, pp. 385-418, 1943.
%
% Syntax		LuminanceFactors = MunsellValueToLuminanceFactor(MunsellValue);
%
%				MunsellValue		Value in the Munsell system, varying from 0 to 10.    
%
%				LuminanceFactors	A data structure.  The first field is the input Munsell
%									value that is being converted.  The remaining fields are
%									the luminance factors when calculated by different methods.
%
% Related		LuminanceFactorToMunsellValue
% Functions
%
% Required		None
% Functions
%
% Author		Paul Centore (May 15, 2010)
% Revised by	Paul Centore (December 18, 2010)
%	Revisions:  Changed name from MunsellValueToReflectionPercentage to MunsellValueToLuminanceFactor
%				Changed output format from vector to data structure, for easy extensibility
%				Added ASTM D 1535-08 conversion expression
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

% Calculate luminance factor from quintic polynomial in ([Newhall1943, p. 417]).
Term1 =  1.2219    * MunsellValue				;
Term2 = -0.23111   * (MunsellValue^2)			;
Term3 =  0.23951   * (MunsellValue^3)			;
Term4 = -0.021009  * (MunsellValue^4)			;
Term5 =  0.0008404 * (MunsellValue^5)			;
NewhallLuminanceFactor = Term1 + Term2 + Term3 + Term4 + Term5	;

% Calculate luminance factor in terms of CIELAB model as given in ([Fairchild2005, Sect. 10.3]).
Lstar = 10 * MunsellValue		;
fy    = (Lstar + 16)/116		;
delta = 6/29					;
if fy > delta
   CIELABLuminanceFactor = fy^3	;
else
   CIELABLuminanceFactor = 3*(fy - (16/116))*(delta^2)	;
end
CIELABLuminanceFactor = 100 * CIELABLuminanceFactor	;

% Calculate luminance factor from expression in ([ASTMD1535-08, p. 4]).  This
% luminance factor is just 0.975 times the luminance factor in [Newhall1943].
Term1 =  1.1914    * MunsellValue				;
Term2 = -0.22533   * (MunsellValue^2)			;
Term3 =  0.23352   * (MunsellValue^3)			;
Term4 = -0.020484  * (MunsellValue^4)			;
Term5 =  0.00081939 * (MunsellValue^5)			;
ASTMLuminanceFactor = Term1 + Term2 + Term3 + Term4 + Term5	;

LuminanceFactors.OriginalMunsellValue = MunsellValue			;
LuminanceFactors.Newhall1943          = NewhallLuminanceFactor	;
LuminanceFactors.CIELAB               = CIELABLuminanceFactor	;
LuminanceFactors.ASTMD153508          = ASTMLuminanceFactor		;
return