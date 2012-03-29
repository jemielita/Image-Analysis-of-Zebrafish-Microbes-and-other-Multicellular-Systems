function [convexPt, xx,yy] = opWidth(imT, pos)
%Rescale the thresholded image so that it is only as large as necessary
xy = sum(imT,3);

xR = sum(xy,1);
xMin = find(xR,1,'first');
xMax = find(xR, 1, 'last');

yR = sum(xy,2);

yMin = find(yR,1,'first');
yMax = find(yR, 1, 'last');


zR = sum(imT,1);
zR = squeeze(zR);
zR = sum(zR,1);

zMin = find(zR, 1,'first');
zMax = find(zR, 1, 'last');

%Redefining imT to be the smallest box surrounding the opercle.
imT = imT( yMin:yMax, xMin:xMax, zMin:zMax);

%Rescaling pos

pos(1,1) = pos(1,1) - xMin;
pos(2,1) = pos(2,1) - xMin;
pos(1,2) = pos(1,2) - yMin;
pos(2,2) = pos(2,2) - yMin;


%Along the length of the gut, calculate the projection
xx = pos(1,1) + (pos(2,1)-pos(1,1))*(1:500)/500;

yy = pos(1,2) + (pos(2,2)-pos(1,2))*(1:500)/500;
    

%Parameterizing curve in terms of arc length
t = cumsum(sqrt([0,diff(xx(:)')].^2 + [0,diff(yy(:)')].^2));

%Resampling so that y is sampled at spacings of one pixel-there's no need
%to sample any finer.

xx = spline(t, xx, t);
yy = spline(t, yy, t);

stepSize = 1;
xx = interp1(t, xx, min(t):stepSize:max(t), 'spline', 'extrap');
yy = interp1(t, yy, min(t):stepSize:max(t), 'spline', 'extrap');

yMin = 1;
xMin = 1;

yMax = size(imT,1);
xMax = size(imT,2);

%Find the perimeter of these regions
imPerim = zeros(size(imT));
for i=1:size(imT,3)
    imPerim(:,:,i) = bwperim(imT(:,:,i));
end

sumPerim = sum(imPerim,3);
sumPerim = find(sumPerim==1);

figure; imshow(sum(imPerim,3));
hold on
    
fprintf(2,'Getting convex hull down the width of OP:\n');

perimW = zeros(length(xx)-1);


lineIm = zeros(size(imT,1), size(imT,2)); %For getting a mask for the line

for lineNum=2:length(xx)
    
    x = xx(lineNum)-xx(lineNum-1);
    y = yy(lineNum)-yy(lineNum-1);
    xI = x+1;
    yI = y+2;
    
    %Line should be long enough to span the entire gut...Far more than that
    %right now.
    Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];    
    xVal = xx(lineNum)+ Orth(1)*[-500:1:500];
    yVal = yy(lineNum)+ Orth(2)*[-500:1:500];
    
    %Get rid of elements of xVal and yVal outside the image size
    index = find(round(xVal)>xMax |round(xVal)<xMin);
    xVal(index) = [];
    yVal(index) = [];
    
    index = find(round(yVal)>yMax |round(yVal)<yMin);
    xVal(index) = [];
    yVal(index) =[];
    
    indexLine = cat(2, round(xVal)', round(yVal)');
   
    onLine = sub2ind([size(imT,1), size(imT,2)], indexLine(:,2), indexLine(:,1));
    lineIm(:) = 0;
    lineIm(onLine) =1;
    
    %See where the line intersects with the perimeter of the opercle.
    overlapIm = imPerim.*repmat(lineIm, [1,1,size(imT,3)]);
    
    %Get the location of the pixels that make up the boundary
    ind = find(overlapIm==1);
    [xPerim, yPerim, zPerim] = ind2sub(size(imT), ind);
    
    unZ = unique(zPerim);
    
    xyCon = [];
    zCon = [];
   
    ptVal = 1:size(indexLine,1);
    
    for zH=1:length(unZ); 
        ind = find(zPerim ==unZ(zH));
        thisRow = cat(2, yPerim(ind), xPerim(ind));
        
        %See where this lies on the line
        t = ismember(indexLine, thisRow, 'rows');
        
        xyCon = [xyCon; ptVal(t)'];
        zCon  = [zCon; (1/0.1625)*zH*ones(length(ptVal(t)),1  )];
        
    end
    
    if(length(unique(zCon))>1)
       %Calculate the convex hull at this point along the line
       k = convhull(xyCon, zCon);
       xyCon = xyCon(k); zCon = zCon(k);
       convexPt{lineNum-1} = [xyCon, zCon];
    end
    
fprintf(2, '.');

end

fprintf('\n');

end
