function PlotIlluminants();
% Purpose		Make a plot of selected standard illuminants.
%
% Description	An illuminant is a relative spectral power density (SPD), over the
%				visible spectrum, of some light.  Various standard illuminants
%				are used in colour science.  This routine makes plots of some
%				standard illuminants, which a programmer can select from the
%				code.  The data for the illuminants is retrieved using routines
%				from the open-source project OptProp.
%
% Required Routines:  illuminant (from OptProp)
%
% Author		Paul Centore (November 19, 2013)
%
% Copyright 2013 Paul Centore
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

% The data for the illuminants will be retrieved at the following wavelengths
wavelengths = 400:10:700	;

% Start a figure, on which a selection of illuminants can be displayed
figure
YAxisAdjustment = 400		;	% Use this to scale the Y-axis to make a pleasing plot

% Select illuminants from the following options, by choosing 'if true' or 'if false'
% for individual illuminants.
if true
	IllA = illuminant('A', wavelengths)	;
	IllA = IllA/sum(IllA)				;
	plot(wavelengths, YAxisAdjustment * IllA, 'k-')
	hold on
end

if true
	IllC = illuminant('C', wavelengths)	;
	IllC = IllC/sum(IllC)				;
	plot(wavelengths, YAxisAdjustment * IllC, 'k-')
	hold on
end

if false
	IllD65 = illuminant('D65',wavelengths)	;
	plot(wavelengths, YAxisAdjustment * IllD65, 'b-')
	hold on
end

if false
	IllD50 = illuminant('D50',wavelengths)	;
	plot(wavelengths, YAxisAdjustment * IllD50, 'k-')
	hold on
end

if false
	IllE = illuminant('E',wavelengths)	;
	plot(wavelengths, YAxisAdjustment * IllE, 'y-')
	hold on
end

if true
	IllF11 = illuminant('F11',wavelengths)	;
	IllF11 = IllF11/sum(IllF11)				;
	plot(wavelengths, YAxisAdjustment * IllF11, 'k-')
	hold on
end

% Label the individual plots, if desired
if false
	text(670, 26, 'A')	;
	text(670, 13, 'C')	;
	text(606, 83, 'F11')	;
end

% Save the plot
figname = 'IlluminantsPlot'			 ;
set(gcf, 'Name', figname)
print(gcf, [figname,'.eps'], '-deps');
print(gcf, [figname,'.png'], '-dpng');
print(gcf, [figname,'.jpg'], '-djpg');
print(gcf, [figname,'.pdf'], '-dpdf');

% If desired, make an additional plot, just for the F series
if false
	figure
	for ctr = 1:12
    	IllF = illuminant(['F',num2str(ctr)],wavelengths) ;
		plot(wavelengths, YAxisAdjustment * IllF, 'k-')
		hold on
	end
	figname = 'FlourescentIlluminants'	 ;
	set(gcf, 'Name', figname)
	print(gcf, [figname,'.eps'], '-deps');
	print(gcf, [figname,'.png'], '-dpng');
	print(gcf, [figname,'.jpg'], '-djpg');
	print(gcf, [figname,'.pdf'], '-dpdf');
end