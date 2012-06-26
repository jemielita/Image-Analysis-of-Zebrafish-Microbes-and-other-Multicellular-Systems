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

function [convexPt, linePt, perimVal] = opWidth(imT,scanNum, microscope)

plotData = 'true';

convexPt = [];
linePt = [];

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


%Clean up the thresh. images
for i=1:size(imT,3)
    %Use binary closure on the image to clean up the edges
    imT(:,:,i) = bwmorph(imT(:,:,i), 'close');
    
    %Remove regions with fewer than 10 pixels
    imT(:,:,i) = bwareaopen(imT(:,:,i), 10);
    %Fill interior pixels
    imT(:,:,i) = bwmorph(imT(:,:,i), 'fill');
    
end

%Find the connected components and remove those that aren't part of the
%large object
CC = bwconncomp(imT);
numPixels = cellfun(@numel, CC.PixelIdxList);
[biggest, idx] = max(numPixels);
imT(:)  =0;
imT(CC.PixelIdxList{idx}) = 1;

%Find the perimeter of these regions
imPerim = zeros(size(imT));
for i=1:size(imT,3)
    imPerim(:,:,i) = bwperim(imT(:,:,i));
    
end

sumPerim = sum(imPerim,3);
sumPerim = find(sumPerim==1);

indP = find(imPerim ==1);
[xp, yp, zp] = ind2sub(size(imPerim), indP);

switch microscope
    case 'confocal'
        xp = 0.3636*xp; yp = 0.3636*yp;
    case 'lightsheet'
        xp = 0.1625*xp; yp = 0.1625*yp;
end

if(strcmp(plotData, 'true'))
    figure; plot3(xp, yp, zp, '*', 'MarkerSize', 1);
    axis equal
    title(num2str(scanNum));
    hold on
end

perimVal = cat(2, xp, yp, zp);
perimVal = round(perimVal);


%We'll use PCA to define the major axis of the opercle and then we'll get
%the convex hull of the plane perpendicular to this line
ind = find(imT==1);

[x, y,z] = ind2sub(size(imT), ind);
%rescaling the z axis to account for the spacing

switch microscope
    case 'confocal'
        %For the Confocal Data
        x = 0.3636*x;
        y = 0.3636*y;
    case 'lightsheet'
        %For the Light sheet data
        x = 0.1625*x;
        y = 0.1625*y;
        
end
X = cat(2, x,y,z);

meanX = mean(X,1);
Xfit = repmat(meanX,n,1) + score(:,1:2)*coeff(:,1:2)';
residuals = X - Xfit;

%Getting points along the principal axis  
dirVect = coeff(:,1);
t = [min(score(:,1))-.2, max(score(:,1))+.2];
endpts = [meanX + t(1)*dirVect'; meanX + t(2)*dirVect'];

%resampling at a space of one pixel-maybe overkill
if(strcmp(plotData, 'true'))
    plot3(endpts(:,1), endpts(:,2), endpts(:,3), 'k-'); 
end
b = 0;

pause(2);
close all

return


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

% if(strcmp(plotData, 'true'))
%     plot3(xx,yy, zz,'*', 'markersize', 10);
% 
%     
% end
    
%Now producing meshgrid perpendicular to the principal axis at one micron
%spacings.
%[xgrid, ygrid] = meshgrid(min(X(:,1)):0.05:max(X(:,1)), min(X(:,2)):0.05:max(X(:,2)));
zFinalGrid = meshgrid(min(X(:,3)):max(X(:,3)));

[xgrid, ygrid,zgrid] = meshgrid(-100+min(X(:,1)):max(X(:,1))+100, 0,...
    -100+min(X(:,3)):max(X(:,3))+100);

gridV = cat(2, xgrid(:), ygrid(:), zgrid(:));
r = sqrt(sum(normal.^2));
phi = pi/2-atan(normal(2)/normal(1));

zDist = linePt(end,3)-linePt(1,3);
zR = sqrt(sum((linePt(end,1:2)-linePt(1,1:2)).^2));

theta = atan(zDist/zR);

rotM = [cos(phi) -cos(phi) + sin(phi)*sin(theta), sin(phi)+cos(phi)*sin(theta);...
    cos(theta), cos(phi) + sin(phi)*sin(theta), -sin(phi)+cos(phi)*sin(theta);...
    -sin(theta), sin(phi)*cos(theta), cos(phi)*cos(theta)];


rotM1 = [cos(phi), sin(phi), 0; -sin(phi), cos(phi), 0 ;0, 0,1];
rotM2 = [1, 0, 0; 0, cos(theta), sin(theta); 0, -sin(theta), cos(theta)];


%plot3(gridV(:,1), gridV(:,2), gridV(:,3));


for i=1:size(gridV,1)
    planePt(i,:) = rotM2*rotM1*gridV(i,:)';
end

% plot3(planePt(:,1), planePt(:,2), planePt(:,3))


%[xgrid,ygrid] = meshgrid(linspace(min(X(:,1)),max(X(:,1)),1000), ...
%   linspace(min(X(:,2)),max(X(:,2)),1000));

% pause
% close all
% return

%figure; 
fprintf(2, 'Calculating the convex hull perpendicular to the principal axis');
fprintf(2, '\n');

planePtO = planePt;
%zOr = (1/normal(3)) .*(xgrid.*normal(1) + ygrid.*normal(2));

for lineNum = 1:size(linePt,1)
    lineVal = linePt(lineNum,:);
    planePt(:,1) = planePtO(:,1) + lineVal(1);
    planePt(:,2) = planePtO(:,2) + lineVal(2);
    planePt(:,3) = planePtO(:,3) + lineVal(3);
    %zgrid = (1/normal(3)) .* (lineVal*normal) - zOr;
    
    % zgrid = (lineVal*normal - (xgrid.*normal(1) + ygrid.*normal(2)));
    if(lineNum==1)
        %   h = mesh(xgrid,ygrid,zgrid,'EdgeColor',[0 0 0],'FaceAlpha',0.5);
    else
        % set(h, 'xData', xgrid);set(h, 'yData', ygrid); set(h, 'zData', zgrid);
%     end
%     planePt(:,1) = gridV(:,1) + lineVal(1);
%     planePt(:,2) = gridV(:,2) + lineVal(2);
%     planePt(:,3) = gridV(:,3) + lineVal(3);
%     %
%     planePt = cat(2, xgrid(:), ygrid(:), zgrid(:));
%     index =  find(planePt(:,3)>max(perimVal(:,3))  );
%     planePt(index, :) = [];
%     index =  find(planePt(:,3)<min(perimVal(:,3))  );
%     planePt(index, :) = [];
% %     
%     [~,~,zMesh] = meshgrid(planePt(:,1), planePt(:,2), planePt(:,3));
%     xi = interp1(1:length(planePt(:,1)), planePt(:,1), linspace(min(planePt(:,1)), max(planePt(:,1)),100));
%     yi = interp1(1:length(planePt(:,2)), planePt(:,2), linspace(min(planePt(:,2)), max(planePt(:,2)),100));
%     [xMesh, yMesh] = meshgrid(xi',yi');
%     
%     zi = interp2(zMesh, xMesh,yMesh);
%     
%  
%     
%     [xgL, ygL, zgL] = meshgrid(planePt(:,1), planePt(:,2), planePt(:,3));
    
    %Remove points that are outside the range of the opercle data
    %     for remP=1:3
    %     index =
    %     planePt(~index,:) = [];
    %     index = find(planePt(:,remP)<min(perimVal(:,remP)));
    %     planePt(~index,:) = [];
    %     end
    
    
    %dataDist = pdist2(planePt, perimVal);
    %index = find(min(dataDist,[],2)<=1);
    %valOrig = planePt(index,:);
    %    planePt = round(planePt);
    %    interPtIn = ismember(planePt, perimVal,'rows');
    %idx = rangesearch(planePt, perimVal,50);
    idx = rangesearch(planePt, perimVal, 1);
    index = ~ cellfun('isempty', idx);
    %    idx = [idx{:}];
    valOrig = perimVal(index,:);
    %    valOrig = planePt(idx,:);
    %valOrig = unique(valOrig, 'rows');
    %Find the coordinates of these points in the original coordinate system
    % valOrig = cat(2, xgrid(interPtIn), ygrid(interPtIn), zgrid(interPtIn));
    %Transforming to the coordinate system of the plane perpendicular to
    %the principal axis.
    val = basis'*valOrig';
    
    %DOUBLE CHECK THAT THIS IS THE CORRECT TRANSFORMATION!!!
    %I believe it is. If you run the command below-finding the coordinate
    %of all these points along the normal all the values are the same. This
    %is what you would expect.
    %val2 = normal'*valOrig';
    
          
if(strcmp(plotData, 'true')) 
       %Convex hull is what one expects.
      if(~exist('hP'))
          hP =  plot3(valOrig(:,1), valOrig(:,2), valOrig(:,3), '-rs');
      else
          set(hP, 'XData', valOrig(:,1));
          set(hP, 'YData', valOrig(:,2));
          set(hP, 'ZData', valOrig(:,3));
      end
      
   %    plot(valCon(1,:), valCon(2,:), '--rs');
       
    %  plot3(lineVal(1 ), lineVal(2), lineVal(3), '--rs');

     b = 0;

end
    
   if(size(val,2)>2)
       try
           k = convhull(val(1,:), val(2,:));
           valCon = val(:,k);
           convexPt{lineNum} = valCon;
       catch
          convexPt{lineNum} = -1; %record that there was an error calculating this convex hull. 
       end
       

       
   else
       convexPt{lineNum} = -1;
   end
   
    if(exist('hP1'))
        delete(hP1)
    end
    if(exist('hP2'))
        delete(hP2)
    end
    
    fprintf(2, '.');
    
    end

end
fprintf(2, '\n');

close all
end
