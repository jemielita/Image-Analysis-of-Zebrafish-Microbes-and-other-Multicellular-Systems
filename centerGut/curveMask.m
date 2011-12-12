function [mask, centerLine] = curveMask(poly,line,sizeIm,stepSize,param)

%Create a mask out of the polygon.
BW = poly2mask(poly(:,1), poly(:,2), sizeIm(1), sizeIm(2));

%Fit this polygon to an ellipse
%We'll use a piece of code Raghu wrote (Note: I don't think this code gives
%the optimal elliptical fitting to the data. Not a big deal for our application, but
%I wouldn't use it for anything fancier.

%The input step size is in microns, convert to pixels:
if (isfield(param, 'micronPerPixel'))
    stepSize = stepSize/param.micronPerPixel;
else
    stepSize = stepSize/0.1625; %If the conversion hasn't been specified, assume that we're using our 40X.
end
%Round the step size to avoid potential (although unlikely) problems.
stepSize  = round(stepSize);

disp('Curve Mask: Calculating the center of the gut.');
[xx, yy] = getCenterLine(BW,line, stepSize);

disp('Curve Mask: Creating masks for the gut.');
mask = createMask(BW, xx, yy);

centerLine = cat(2, xx', yy');

end

%Calculates the center of the gut, first by morphological thinning of the
%gut (As a result this code should only be used for "cigar" shaped objects,
%and will likely give junk results for mor spherical shapes). The resulting
%line is then extrapolated to intersect with the boundary of the gut. The
%function returns xx, and yy the x and y position of points on the curve
%that are each a distance of stepSize (in pixels) apart on the line through the center
%of the gut.
function [xx, yy] = getCenterLine(BW, line,stepSize)

xx = line(:,1);
yy = line(:,2);
%Parameterizing curve in terms of arc length
t = cumsum(sqrt([0,diff(line(:,1)')].^2 + [0,diff(line(:,2)')].^2));
%Find x and y positions as a function of arc length
lineFit(:,1) = spline(t, line(:,1), t);
lineFit(:,2) = spline(t, line(:,2), t);

%Interpolate curve to make it less jaggedy, arbitrarily we'll
%set the number of points to be 50.
stepSize = (max(t)-min(t))/100.0;

lineT(:,2) = interp1(t, lineFit(:,2),min(t):stepSize:max(t),'spline', 'extrap');
lineT(:,1) = interp1(t, lineFit(:,1),min(t):stepSize:max(t), 'spline', 'extrap');

%Redefining poly
line = cat(2, lineT(:,1), lineT(:,2));

           
%The thinning procedure cuts off the beginning and end of the line, so
%that it doesn't link up with the outline of the shape. Extrapolate the
%beginning and end so that this is no longer the case.

%Somewhat of a brute force approach

%1) Interpolate xx and yy so that they extend to the end of the image
%range
yyTemp = interp1(xx,yy,1:size(BW,2),'linear', 'extrap');

xxTemp = 1:size(BW,2);

%Remove elements of yyTemp that are above and below the range of the image
index = find(yyTemp<0 | yyTemp>size(BW,1));
yyTemp(index) = [];
xxTemp(index) = [];


%2) round to the nearest pixel
xxTemp = round(xxTemp);
yyTemp = round(yyTemp);

%2) Find the intersection of the points in 2) and in the interior of the
%gut.

%Find the indices corresponding to the line
index = sub2ind(size(BW), yyTemp, xxTemp);
lineIm =zeros(size(BW));
lineIm(index) = 1;

lineIm = lineIm.*BWInit; %the intersection of the line w/ the region

%Get the indices on this new and improved line.
%Not sure why the indices have to be flipped here, but it seems to work.
[yy,xx] = find(lineIm==1);

%Now we need to find points along this line that are equally spaced.
%0) first smoothing out the curve again (need to minimize the number of
%times we do this!)
xxT = xx(1:10:length(xx));
yyT= yy(1:10:length(yy));

yy = spline(xxT, yyT, xxT);

%Transposing the position vectors
yy = yy'; xx= xxT';
fprintf(2, 'done!\n');
%1) Finding the arc length
fprintf(2, 'Parameterizing in terms of arc length...');
t = cumsum(sqrt([0,diff(xx)].^2 + [0,diff(yy)].^2));

%2) Finding the x and y position as a function of the arc length.
xFit = spline(t, xx, t);
yFit = spline(t, yy, t);

%3) Find the values of x and y at equal spacings of arc length.
yI = interp1(t, yFit,min(t):stepSize:max(t),'spline', 'extrap');
xI = interp1(t, xFit,min(t):stepSize:max(t), 'spline', 'extrap');

%4) Redefining variables
xx = xI;
yy = yI;

fprintf(2, 'done!\n');

end

function [mask] = createMask(BW, xx, yy)


%Try to allocate a relatively big array to begin with (to avoid having to reallocate mid-stride. If that doesn't work
%start with a small one.
try
    mask = zeros(size(BW,1), size(BW,2),5);
catch err
    
    mask = zeros(size(BW,1), size(BW,2),1);
end

fprintf(2,'Creating Masks ');
for i=2:length(xx)-1
    fprintf(2, '.');
    %Find the orthogonal vector using Gram-Schmidt orthogonalization
    
    x = xx(i)-xx(i-1);
    y = yy(i)-yy(i-1);
    xI = x+1;
    yI = y+2;
    
    Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];
    
    xVal(1,:) = xx(i)+ Orth(1)*(100)*[-1, 1];
    yVal(1,:) = yy(i)+ Orth(2)*(100)*[-1,1];
    
    xVal(2,:) = xx(i+1)+ Orth(1)*(100)*[-1, 1];
    yVal(2,:) = yy(i+1)+ Orth(2)*(100)*[-1,1];
    
    pos = [xVal(1,1), yVal(1,1); xVal(1,2), yVal(1,2); xVal(2,2), yVal(2,2);...
        xVal(2,1), yVal(2,1)];
    
    thisMask = poly2mask(pos(:,1), pos(:,2), size(BW,1), size(BW,2));
    
    %Cut off any part of the mask outside the outlined region
    thisMask = thisMask.*BW;
    
    thisMask = i*thisMask; %Uniquely label each mask
    %See if this mask doesn't overlap with any of the previously found
    %masks. If it doesn't then add this mask to that array, if not put it
    %into a new array.
    
    for mComp=1:size(mask,3)
        isOverlap = unique(thisMask.*mask(:,:,mComp)>0);
        
        if(ismember(1, abs(isOverlap)))
            %Regions overlap, skip this mask for now,
            if(mComp<size(mask,3))
                continue %Continue comparing masks if you're not at the end of the array of masks.
            else
                mask(:,:,mComp+1) = thisMask; %Enlarge the array storing the masks.
            end
            
        else
            mask(:,:,mComp) = thisMask + mask(:,:,mComp);
            break
        end
        
    end
    
    
end

fprintf(2,'done!\n');
%Remove any arrays in mask that don't contain regions.
while(~any(mask(:,:,end)>0))
    mask(:,:,end) = [];
end


end