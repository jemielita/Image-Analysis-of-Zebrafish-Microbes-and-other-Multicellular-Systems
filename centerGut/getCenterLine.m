
%Calculates the center of the gut, first by morphological thinning of the
%gut (As a result this code should only be used for "cigar" shaped objects,
%and will likely give junk results for mor spherical shapes). The resulting
%line is then extrapolated to intersect with the boundary of the gut. The
%function returns xx, and yy the x and y position of points on the curve
%that are each a distance of stepSize (in pixels) apart on the line through the center
%of the gut.
function line = getCenterLine(line, stepSize, param)
fprintf(2, 'Smoothing curve and parameterizing in terms of length...');
xx = line(:,1);
yy = line(:,2);
%Parameterizing curve in terms of arc length
t = cumsum(sqrt([0,diff(line(:,1)')].^2 + [0,diff(line(:,2)')].^2));
%Find x and y positions as a function of arc length
lineFit(:,1) = spline(t, line(:,1), t);
lineFit(:,2) = spline(t, line(:,2), t);

%Interpolate curve to make it less jaggedy, and to redefine the spacing of
%x and y values to correspond to equal locations down the extent of the
%gut.
if(isfield(param, 'micronPerPixel'))
    stepSize = stepSize/param.micronPerPixel;
else
    stepSize = stepSize/0.1625; %If no pixel size mentioned, assume it's for our 40x
end



lineT(:,2) = interp1(t, lineFit(:,2),min(t):stepSize:max(t),'spline', 'extrap');
lineT(:,1) = interp1(t, lineFit(:,1),min(t):stepSize:max(t), 'spline', 'extrap');

%Redefining poly
line = cat(2, lineT(:,1), lineT(:,2));

fprintf(2, 'done!\n');

end