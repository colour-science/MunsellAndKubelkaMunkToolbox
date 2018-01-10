function AnalyzeSensorResponses(Wavelengths, ThreeSensorResponses, Illuminant, OutputDirectory, OutputName);
% Purpose		Given the response curves for three sensors, such as the eye s photoreceptors
%				or the RGB signals of a sensing device, plot the spectrum locus, spectrum
%				cone, chromaticity diagram, object-colour solid, etc, when objects are
%				viewed under an input illuminant.  Some of the plots require the spectrum
%				locus vectors to form a cyclic set.
%
% Description	A sensing device, such as a camera or the human eye, often has three
%				individual sensors, that respond differently to the various wavelengths
%				in the visible spectrum.  The sensing device as a whole therefore has
%				output in a three-dimensional space.  For a camera, this space would be
%				RGB space, while the human eye output would likely be expressed in CIE
%				XYZ space.
%
%				When viewing a physical object, the input to
%				the individual sensors is the product of the spectral power distribution
%				(SPD) of a light source or illuminant, with the reflectance spectrum of
%				the object.  If the light source is illuminant is fixed, then the set of
%				possible device outputs is a subset of RGB or XYZ space, called an
%				object-colour solid or illuminant gamut, depending on context.  
%
%				[Centore2013, 2014, 2016] uses a series of geometric constructions to show
%				that an object-colour solid has a zonohedral form.  This routine draws
%				figures that illustrate the various steps, for a particular illuminant and
%				set of three sensor response curves.  
%
%				The first figure is just the sensor response curves as functions of the
%				input wavelengths.  The second figure is the spectrum locus (for the input
%				illuminant), which is the set of vectors in sensor coordinates (such
%				as RGB coordinates or CIE XYZ coordinates), that result when the sensor input
%				is a monochromatic stimulus (i.e. the stimulus is restricted to a single
%				wavelength).  In the third figure, the spectrum locus is normalized so
%				that every vector intersects the plane R+G+B=1 (or X+Y+Z=1, etc.).  The
%				fourth figure is a (section of the) spectrum cone, which, unlike the 
%				spectrum locus, does not depend on the illuminant.  The spectrum cone is
%				the set of all possible device outputs, under _any_ illuminant.  The fifth
%				figure is a chromaticity diagram, which is also illuminant-independent, and
%				is the plane R+G+B=1, when intersected with the spectrum cone.  Finally,
%				the sixth figure is the zonohedral object-colour solid (or illuminant
%				gamut), which does depend on the illuminant.
%
%				Examples of these figures appear in [Centore2016].  In fact, this routine
%				was originally written to make those figures. 
%
%				This routine uses the assumption that the spectrum locus vectors are cyclic,
%				i.e. that no vector is in the convex hull of the remaining vectors.  Even
%				without this assumption, the response curves, spectrum locus, points where 
%				the extended locus vectors intersect the plane R+G+B=1, and the chromaticity
%				diagram can be plotted.  The fourth and sixth plots, however, will not be
%				constructed correctly.
%
%				[Centore2013] 	Paul Centore, A Zonohedral Approach to Optimal Colours,
%								Color Research and Application, Vol. 38, No. 2, pp. 110-119,
%								April 2013.
%				[Centore2014] 	Paul Centore, Geometric Invariants Under Illuminant Transformations,
%								Color Research and Application, Vol. 39, No. 2, pp. 179-187,
%								April 2014.
%				[Centore2016] 	Paul Centore, Zonohedral Gamuts for Colour Constancy, 2016.
%
%				Wavelengths		A row vector whose entries are the wavelengths (in nm) for the   
%								stimuli.  The wavelengths should be evenly spaced.
%
%				ThreeSensorResponses	A matrix of three rows; there is one column for each
%								entry in the input Wavelengths.  Each row gives the response
%								curve, in discrete form, for each of the three sensors, in
%								sensor coordinates.
%
%				Illuminant		A row vector with as many entries as Wavelengths.  Each
%								entry is the relative power of an illuminant at the
%								corresponding wavelength.
%
%				OutputDirectory	The directory where the figures produced will be saved
%
%				OutputName		A string that will be used for saving the figures produced
%
% Author		Paul Centore (January 27, 2016)
%
% Copyright 2016 Paul Centore
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

% This routine can display several figures; use the following flags to set which ones
% are desired.
DisplaySensorResponses                  = false	;
DisplaySpectrumLocus                    = false	;
DisplayNormalizedSpectrumLocusWithPlane = false	;
DisplaySectionOfSpectrumCone            = false	;
DisplayChromaticityDiagram              = false	;
DisplayObjectColourSolid				= true	;

% The number of sensors is currently set to 3, but might be a variable in later revisions,
% so extract it now.
NumberOfSensors = size(ThreeSensorResponses,1)	;

NumberOfWavelengths = length(Wavelengths)		;

% A spectrum locus vector is the RGB output for a monochromatic stimulus, under a given
% light source or illuminant.  Suppose there was a physical surface whose reflectance
% spectrum was 100 percent at a certain wavelength, and 0 everywhere else.  Suppose
% further that the input illuminant reflects off that surface, before entering the
% sensor device.  Then the device output, in RGB space, is the spectrum locus vector
% corresponding to that wavelength.
% We can construct the spectrum locus vectors for an input wavelength by
% multiplying the sensor responses at that wavelength by the illuminant s power at that
% wavelength.  
SpectrumLocusVectors = -99 * ones(size(ThreeSensorResponses)) 	;
for ctr = 1:NumberOfWavelengths
	SpectrumLocusVectors(:,ctr) = Illuminant(ctr) * ThreeSensorResponses(:,ctr)	;
end   

if DisplaySensorResponses		% Plot the three sensor response curves
	figure
	for ind = 1:NumberOfSensors
		plot(Wavelengths, ThreeSensorResponses(ind,:), 'k-')	
		hold on
	end

	% Save the figure in various formats
	figname = fullfile(OutputDirectory, [OutputName,'ResponseCurves'])	;
	set(gcf, 'Name', figname);
	print(gcf, [figname,'.eps'], '-deps');
	print(gcf, [figname,'.svg'], '-dsvg');
end


if DisplaySpectrumLocus		% Make a figure that displays the spectrum locus
	figure
	% If desired, multiply each locus vector by a constant for a more informative display
	fac = 1;
	for ind = 1:NumberOfWavelengths
		% Plot the spectrum locus vector that corresponds to a monochromatic stimulus for a
		% particular wavelength
	   plot3([0 fac*SpectrumLocusVectors(1,ind)],[0 fac*SpectrumLocusVectors(2,ind)], [0 fac*SpectrumLocusVectors(3,ind)], 'k');
	   hold on
	end

	% Plot wavelength labels for some vectors, evenly spaced in wavelength
	WavelengthIndexSpacing = 5	;
	for ind = 1:WavelengthIndexSpacing:NumberOfWavelengths
	   wv = Wavelengths(ind)	;
	   textstr = [' ',num2str(wv),' nm '];
	   text(fac*SpectrumLocusVectors(1,ind),fac*SpectrumLocusVectors(2,ind),fac*SpectrumLocusVectors(3,ind),textstr,...
		'Fontsize', 10, 'horizontalalignment', 'right');
	   hold on
	end

	% These settings can be used to customize the spectrum locus plot
	set(gca, 'xlim', [0 25], 'ylim', [0 25], 'zlim', [0 50]);
	%set(gca, 'xtick',[0:0.5:0.5],'ytick',[0:0.5:0.5],'ztick',[0:0.5:2]);
	%set(gca, 'xtick',[],'ytick',[],'ztick',[]);
	%set(gca, 'xticklabel','R','yticklabel','G','zticklabel','B');
	set(gca, 'view', [160 20]);  
	set(gca, 'dataaspectratio', [1 1 1]);

	% Save the figure in various formats
	figname = fullfile(OutputDirectory, [OutputName,'SpectrumLocus'])	;
	set(gcf, 'Name', figname);
	print(gcf, [figname,'.eps'], '-deps');
	print(gcf, [figname,'.svg'], '-dsvg');
end

% Extend all the spectrum locus vectors to semi-infinite rays, and let the rays be intersected
% by the plane R+G+B=1 (or X+Y+Z=1, etc.).  These vectors can be used to make a plot of that 
% plane, showing all the intersection points.
% Normalize the sensor responses so that the sum of their components is 1.
NormalizedResponses = -99 * ones(size(ThreeSensorResponses))	; 
for ind = 1:NumberOfWavelengths
	Response = ThreeSensorResponses(:,ind)						;
	NormalizedResponses(:,ind) = Response/sum(sum(Response))	;
end


% If desired, draw the spectrum locus, cut by the plane R+G+B=1 (or X+Y+Z=1, etc.)
if DisplayNormalizedSpectrumLocusWithPlane	
	figure
	% Plot each normalized spectrum locus vector that corresponds to a monochromatic 
	% stimulus for a particular wavelength.  Since these vectors are normalized, they
	% lie on the plane R+G+B=1.    
	for ind = 1:NumberOfWavelengths
	   plot3([0 NormalizedResponses(1,ind)],[0 NormalizedResponses(2,ind)], [0 NormalizedResponses(3,ind)], 'k');
	   hold on
	end

	if false	% Plot labels for wavelengths, if desired
		% Plot wavelength labels for some vectors, evenly spaced in wavelength
		WavelengthIndexSpacing = 5	;
		for ind = 1:WavelengthIndexSpacing:NumberOfWavelengths
		   wv = Wavelengths(ind)	;
		   textstr = [' ',num2str(wv),' nm '];
		   text(NormalizedResponses(1,ind),NormalizedResponses(2,ind),NormalizedResponses(3,ind),textstr,...
			'Fontsize', 10, 'horizontalalignment', 'right');
		   hold on
		end
	end

	% Plot the edges of the triangle given by the intersection of the plane R+G+B=1 
	% with the non-negative octant
	plot3([1 0 0 1],[0 1 0 0], [0 0 1 0], 'k');
	hold on

	% These settings can be used to customize the plot
	set(gca, 'xlim', [0 1.2], 'ylim', [0 1.2], 'zlim', [0 1.2]);
	%set(gca, 'xtick',[0:0.5:0.5],'ytick',[0:0.5:0.5],'ztick',[0:0.5:2]);
	set(gca, 'xtick',[],'ytick',[],'ztick',[]);
	%set(gca, 'xticklabel','R','yticklabel','G','zticklabel','B');
	set(gca, 'view', [160 20]);  
	set(gca, 'dataaspectratio', [1 1 1]);

	% Save the figure in various formats
	figname = fullfile(OutputDirectory, [OutputName,'CutByPlane'])	;
	set(gcf, 'Name', figname);
	print(gcf, [figname,'.eps'], '-deps');
	print(gcf, [figname,'.svg'], '-dsvg');
end


% If desired, draw the spectrum cone, cut by the plane R+G+B=1 to show its profile.  This
% plot is identical to the previous one, except that the ends of the normalized spectrum
% locus vectors are joined by lines.  These lines produce the profile of the spectrum
% cone, under the assumption that the locus vectors form a cyclic set.
if DisplaySectionOfSpectrumCone
	figure
	% Plot each normalized spectrum locus vector that corresponds to a monochromatic 
	% stimulus for a particular wavelength.  Since these vectors are normalized, they
	% lie on the plane R+G+B=1.    
	for ind = 1:NumberOfWavelengths
	   plot3([0 NormalizedResponses(1,ind)],[0 NormalizedResponses(2,ind)], [0 NormalizedResponses(3,ind)], 'k');
	   hold on
	end

	if false	% Plot labels for wavelengths, if desired
		% Plot wavelength labels for some vectors, evenly spaced in wavelength
		WavelengthIndexSpacing = 5	;
		for ind = 1:WavelengthIndexSpacing:NumberOfWavelengths
		   wv = Wavelengths(ind)	;
		   textstr = [' ',num2str(wv),' nm '];
		   text(NormalizedResponses(1,ind),NormalizedResponses(2,ind),NormalizedResponses(3,ind),textstr,...
			'Fontsize', 10, 'horizontalalignment', 'right');
		   hold on
		end
	end

	% Plot the vertices of the triangle given by the intersection of the plane R+G+B=1 
	% with the non-negative octant
	plot3([1 0 0 1],[0 1 0 0], [0 0 1 0], 'k');
	hold on
	
	% Draw lines connecting ends of normalized spectrum locus vectors; this is the 
	% intersection of the spectrum cone with the plane R+G+B=1
	Xs = NormalizedResponses(1,:)		;
	Xs = [Xs, NormalizedResponses(1,1)]	;
	Ys = NormalizedResponses(2,:)		;
	Ys = [Ys, NormalizedResponses(2,1)]	;
	Zs = NormalizedResponses(3,:)		;
	Zs = [Zs, NormalizedResponses(3,1)]	;
	plot3(Xs,Ys,Zs,'k-')
	hold on

	% These settings can be used to customize the spectrum locus plot
	set(gca, 'xlim', [0 1.2], 'ylim', [0 1.2], 'zlim', [0 1.2]);
	%set(gca, 'xtick',[0:0.5:0.5],'ytick',[0:0.5:0.5],'ztick',[0:0.5:2]);
	set(gca, 'xtick',[],'ytick',[],'ztick',[]);
	%set(gca, 'xticklabel',[],'yticklabel',[],'zticklabel',[]);
	set(gca, 'view', [160 20]);  
	set(gca, 'dataaspectratio', [1 1 1]);

	% Save the figure in various formats
	figname = fullfile(OutputDirectory, [OutputName,'SectionOfSpectrumCone'])	;
	set(gcf, 'Name', figname);
	print(gcf, [figname,'.eps'], '-deps');
	print(gcf, [figname,'.svg'], '-dsvg');
end


% Display a chromaticity diagram (or at least, the points of the diagram which correspond 
% to monochromatic stimuli), if desired
if DisplayChromaticityDiagram
	% Make a two-dimensional figure showing where the spectrum locus vectors intersect
	% the plane R+G+B=1 (or X+Y+Z=1, etc.); this is a prototypical chromaticity diagram	
	figure
	
	% In three-dimensional RGB space, the chromaticity diagram appears on the triangle (in
	% space) resulting from the intersection of the plane R+G+B=1 with the non-negative
	% octant.  The vertices of this triangle are (1,0,0), (0,1,0), and (0,0,1).  A
	% chromaticity diagram is actually two-dimensional, but uses the same triangle, shown
	% as its own plane.  Whether in two- or three-dimensional space, the points within
	% the triangle can be indexed by barycentric coordinates, which express any point
	% inside the triangle as a convex combination of the vertices.  (A convex combination
	% is a linear combination whose coefficients are all between 0 and 1, and whose sum
	% is 1.)  Normalizing a spectrum locus vector produces a convex combination, because
	% the normalized coefficients sum to 1 by construction, and remain positive.
	% Therefore, the normalized coefficients can be used to plot a point in the triangle,
	% once the triangle s vertices are set.
	
	% Choose three vertices (in a two-dimensional plane) for the triangle that contains
	% the chromaticity diagram.
	Radius = 1			;
	Sensor3x = 0		;
	Sensor3y = Radius	;
	Sensor2x = Radius * cosd(-30)	;
	Sensor2y = Radius * sind(-30)	;
	Sensor1x = Radius * cosd(-150)	;
	Sensor1y = Radius * sind(-150)	;

	% Label the vertices, if desired, and draw the triangle connecting them
	%plot(Sensor1x,Sensor1y,'k-', 'markersize', 20)
	%text(Sensor1x,Sensor1y,'Sensor 1','Fontsize', 10, 'horizontalalignment', 'center', 'verticalalignment', 'bottom');
	hold on
	%plot(Sensor2x,Sensor2y,'k.')
	%text(Sensor2x,Sensor2y,' Sensor 2','Fontsize', 10, 'horizontalalignment', 'left', 'verticalalignment', 'middle');
	hold on
	%plot(Sensor3x,Sensor3y,'k.')
	%text(Sensor3x,Sensor3y,'Sensor 3 ','Fontsize', 10, 'horizontalalignment', 'right', 'verticalalignment', 'middle');
	hold on
	plot([Sensor1x, Sensor2x, Sensor3x, Sensor1x], [Sensor1y, Sensor2y, Sensor3y, Sensor1y], 'k-')
	hold on

	% Plot each monochromatic stimulus as a point in the chromaticity diagram.  Use the
	% fact that normalized coordinates can be interpreted as coefficients in a convex
	% combination of the vertices.
	for ind = 1:NumberOfWavelengths
		Response = NormalizedResponses(:,ind)						;
		xCoord = Response(1) * Sensor1x + Response(2) * Sensor2x + Response(3) * Sensor3x	;
		yCoord = Response(1) * Sensor1y + Response(2) * Sensor2y + Response(3) * Sensor3y	;
		plot(xCoord, yCoord, 'k.')
		hold on
	end

	% Customize the plot if desired
	set(gca, 'xlim', 1.5*[-Radius,Radius])
	set(gca, 'ylim', 1.5*[-Radius,Radius])
	set(gca, 'xtick',[],'ytick',[]);
	axis('equal')

	% Save the figure in various formats
	figname = fullfile(OutputDirectory, [OutputName,'ChromaticityDiagram'])	;
	set(gcf, 'Name', figname);
	print(gcf, [figname,'.eps'], '-deps');
	print(gcf, [figname,'.svg'], '-dsvg');
end

% Display an object-colour solid (called an "illuminant gamut" in computational colour
% constancy), if desired
if DisplayObjectColourSolid
	% For details of this construction, such as its zonohedral form, see [Centore2016].
	% This construction requires that the spectrum locus vectors form a cyclic set;
	% otherwise the output will be incorrect.  Call a separate routine that calculates
	% the zonohedron, and draws a figure.
	[Vertices ListOfEdges ListOfFaces VertexCoefficients ZonohedronFigureHandle] = ...
				ConstructCyclicZonohedron(transpose(SpectrumLocusVectors));

	% Save the figure in various formats
	figname = fullfile(OutputDirectory, [OutputName,'ObjectColourSolid'])	;
	set(gcf, 'Name', figname);
	print(gcf, [figname,'.eps'], '-deps');
	print(gcf, [figname,'.svg'], '-dsvg');			
	print(gcf, [figname,'.fig'], '-dfig');			
end