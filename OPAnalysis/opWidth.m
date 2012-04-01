%[convexPt, linePt, imT] = opWidth(imT)
%
%INPUT: imT: thresholded 3D image giving the extent of an opercle. Image
%stack should be binary. 1: opercle, 0: not opercle.
%
%OUTPUT: convexPt: gives points defining the convex hull at given points
%along the opercle. Stored as a cell array.
%        linePt: gives points that define the principal axis through the
%        opercle.
%        imT: returns the thresholded image of the opercle, but cropped
%        down so that the image stack is only as large as the opercle.
%
%DETAILS: For a given 3D segmented image of an opercle calculate the
%principal axis of the image using principal component analysis. Since the
%opercle is longer than it is wide, the long axis of the opercle will be
%given by the first principal component. Along this line find points of the
%opercle that are perpendicular to the principal axis. Calculate the convex
%hull of these points and return them. This will give the perimeter of the
%opercle at different points along its length.
%
%AUTHOR: Matthew Jemielita

function [convexPt, linePt] = opWidth(imT)
%Rescale the thresholded image so that it is only as large as necessary
imT = double(imT>0);

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

%Find the perimeter of these regions
imPerim = zeros(size(imT));
for i=1:size(imT,3)
    imPerim(:,:,i) = bwperim(imT(:,:,i));
end

sumPerim = sum(imPerim,3);
sumPerim = find(sumPerim==1);

indP = find(imPerim ==1);
[xp, yp, zp] = ind2sub(size(imPerim), indP);
zp = (1/0.1625)*zp;
figure; plot3(xp, yp, zp, '*', 'MarkerSize', 1);
axis equal

perimVal = cat(2, xp, yp, zp);
perimVal = round(perimVal);
hold on

%We'll use PCA to define the major axis of the opercle and then we'll get
%the convex hull of the plane perpendicular to this line
ind = find(imT==1);

[x, y,z] = ind2sub(size(imT), ind);
%rescaling the z axis to account for the spacing
z = (1/0.1625)*z;

X = cat(2, x,y,z);

%Get the principal components
[coeff,score,roots] = princomp(X);
%We'll find a plane normal to the principal axis
basis = coeff(:,2:3);

normal = coeff(:,1); %The principal axis.

[n,p] = size(X);
meanX = mean(X,1);
Xfit = repmat(meanX,n,1) + score(:,1:2)*coeff(:,1:2)';
residuals = X - Xfit;

%Getting points along the principal axis
dirVect = coeff(:,1);
t = [min(score(:,1))-.2, max(score(:,1))+.2];
endpts = [meanX + t(1)*dirVect'; meanX + t(2)*dirVect'];

%resampling at a space of one pixel-maybe overkill
plot3(endpts(:,1), endpts(:,2), endpts(:,3), 'k-');

%Parameterizing curve in terms of arc length
t = cumsum(sqrt([0,diff(endpts(:,1)')].^2 + [0,diff(endpts(:,2)')].^2+...
    [0,diff(endpts(:,3)')].^2));

%Resampling so that y is sampled at spacings of one pixel-there's no need
%to sample any finer.

endpts(:,1) = spline(t, endpts(:,1), t);
endpts(:,2) = spline(t, endpts(:,2), t);
endpts(:,3) = spline(t, endpts(:,3), t);

stepSize = 1;
xx = interp1(t, endpts(:,1), min(t):stepSize:max(t), 'spline', 'extrap');
yy = interp1(t, endpts(:,2), min(t):stepSize:max(t), 'spline', 'extrap');
zz = interp1(t, endpts(:,3), min(t):stepSize:max(t), 'spline', 'extrap');
linePt = cat(2, xx',yy',zz');

%plot3(xx,yy, zz,'*', 'markersize', 10);


%Now producing meshgrid perpendicular to the principal axis at one micron
%spacings.
[xgrid, ygrid] = meshgrid(min(X(:,1)):max(X(:,1)), min(X(:,2)):max(X(:,2)));

%[xgrid,ygrid] = meshgrid(linspace(min(X(:,1)),max(X(:,1))), ...
%    linspace(min(X(:,2)),max(X(:,2)),5));

axis equal
gridPlane = zeros(size(xgrid));

figure; 
fprintf(2, 'Calculating the convex hull perpendicular to the principal axis');
fprintf(2, '\n');
for lineNum = 1:size(linePt,1)
    lineVal = linePt(lineNum,:);
    zgrid = (1/normal(3)) .* (lineVal*normal - (xgrid.*normal(1) + ygrid.*normal(2)));
    
    if(lineNum==1)
     %   h = mesh(xgrid,ygrid,zgrid,'EdgeColor',[0 0 0],'FaceAlpha',0);
    else
    %   set(h, 'xData', xgrid);set(h, 'yData', ygrid); set(h, 'zData', zgrid); 
    end
    
    planePt = cat(2, xgrid(:), ygrid(:), zgrid(:));
    planePt = round(planePt);
    interPtIn = ismember(planePt, perimVal,'rows');
    
    %Find the coordinates of these points in the original coordinate system
    valOrig = cat(2, xgrid(interPtIn), ygrid(interPtIn), zgrid(interPtIn));
    %Transforming to the coordinate system of the plane perpendicular to
    %the principal axis.
    val = basis'*valOrig';
    
    %DOUBLE CHECK THAT THIS IS THE CORRECT TRANSFORMATION!!!
    %I believe it is. If you run the command below-finding the coordinate
    %of all these points along the normal all the values are the same. This
    %is what you would expect.
    %val2 = normal'*valOrig';
    %
    
    
   if(size(val,2)>1)
       k = convhull(val(1,:), val(2,:));
       valCon = val(:,k);
       convexPt{lineNum-1} = valCon;
       
       %Convex hull is what one expects.
%        plot(val(1,:), val(2,:), '*');
%        hold on
%        plot(valCon(1,:), valCon(2,:), '--rs');
%        pause
%        close all
       
   end
   
    if(exist('hP1'))
        delete(hP1)
    end
    if(exist('hP2'))
        delete(hP2)
    end
    
    fprintf(2, '.');
    
end
fprintf(2, '\n');


end
