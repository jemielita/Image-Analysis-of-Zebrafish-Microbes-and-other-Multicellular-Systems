function [] = curveMask
% 
% %Make some polygon. Saved to position.mat in this folder
% im = zeros(500,500);
% figure; imshow(im);
% h = impoly('Closed', true);
% position = wait(h);

 
%Load the position data made
load 'position.mat' position

load 'BW.mat' BW
%Fit this polygon to an ellipse
%We'll use a piece of code Raghu wrote (Note: I don't think this code gives 
%the optimal elliptical fitting to the data. Not a big deal for our application, but
%I wouldn't use it for anything fancier.

BWInit = BW;

BWlast = zeros(size(BW));

%Thin down the curve to a line, this will be our first pass at the center
%of the gut.
while (sum(BWlast(:)-BW(:))~= 0)
    BWlast = BW;
    BW = bwmorph(BW, 'thin');
end

 b= 0;
 %Get the indices of points on this line
 [xx yy] = find(BW==1);
 
 %Now drawing the lines perpendicular to all points on this thinned line.
%  
%  figure; imshow(BWInit)
%  hold on
%  plot(xx, yy)
 
 stepSize = 20; %Steps in pixels to take along the arc length.
 
 %Smoothing the curve a little bit.
 %There's potentially a better way to do this. Currently downsampling the
 %data and then fitting it with a spline (to minimize curvature of the
 %line)
 xxT = xx(1:10:length(xx));
 yyT= yy(1:10:length(yy));
 
 
 yy = spline(xxT, yyT, xxT);
 
 %Transposing the position vectors
 yy = yy'; xx= xxT';
 
 %The thinning procedure cuts off the beginning and end of the line, so
 %that it doesn't link up with the outline of the shape. Extrapolate the
 %beginning and end so that this is no longer the case.
 
 %Somewhat of a brute force approach
 
 %1) Interpolate xx and yy so that they extend to the end of the image
 %range
 xxTemp = interp1( yy,xx,1:size(BW,2),'linear', 'extrap');
 
 yyTemp = 1:size(BW,2);
 
 
 
 %2) round to the nearest pixel
 xxTemp = round(xxTemp);
 yyTemp = round(yyTemp);
 
 %2) Find the intersection of the points in 2) and in the interior of the
 %gut.
 
 %Find the indices corresponding to the line
 index = sub2ind(size(BW), xxTemp, yyTemp);
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
 %1) Finding the arc length
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
 
 

%  
%  
%  figure; imshow(BWInit);
%  hold on
%  plot(xx, yy);
%   
% b= 0;
%    
%%%%WARNING: THE CODE BELOW DOESN'T CONVERGE!. But after a couple of
%%%%iterations it appears as if it doesn't change the shape of the line too
%%%%much.
% %Readjust the location of this line so that it's equidistant from both
% %sides of the gut.
% 
% %Get a mask of the outine of the gut. Dilate it a bit, so that there aren't
% %any holes in it.
% perim = bwperim(BWInit);
% perim = bwmorph(perim, 'dilate');
% %Get the indices of the outline of the gut
% [perimIndex(:,2), perimIndex(:,1)] = find(perim==1);
% 
% 
% newPos = cat(2, xx',yy');
% newPos(:) = 0;
% err = 11;
% 
% figure; imshow(BWInit);
% hold on
% 
% while err > 10;
%     plot(xx, yy);
%     for i=2:length(xx)
%         
%         %Find the orthogonal vector using Gram-Schmidt orthogonalization
%         
%         x = xx(i)-xx(i-1);
%         y = yy(i)-yy(i-1);
%         xI = x+1;
%         yI = y+2;
%         
%         Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];
%         
%         xVal = xx(i)+ Orth(1)*(-100:100); %Need to change this line to only go to the end of the image
%         yVal = yy(i)+ Orth(2)*(-100:100);
%         
%         xVal = round(xVal);%Round to the nearest pixel
%         yVal = round(yVal);
%         
%         val = cat(2, xVal', yVal');
%         %Find the intersection of these pixel values with the boundary
%         interL = ismember(val, perimIndex, 'rows');%Returns indices of val that intersect the perimeter
%         
%         %Get the x, y coordinates of members of interL
%         index = find(interL==1);
%         interL = val(index,:); %Coordinates of the intersection of the regions
%         
%         
%         while(size(interL,1) >2)
%             d = triu(dist(interL')); %Get distance between found pixels that make up the intersection of the perimeter and the line
%             %Only get upper triangular portion to avoide double counting when removing
%             %elements
%             index = find(d==0);
%             d(index) = NaN; %We'll remove minimum values. Want to ignore values equal to zero.
%             
%             index = find(d==min(d(:)));
%             [index, temp] = ind2sub(size(d), index);
%             interL(index,:) = []; %Removing elements that are close to other ones
%             
%         end
%         
%         newPos(i,:)= mean(interL);
%           
%     end
%     %Get the error with this iteration of the readjustment of the line
%     err = sqrt(sum((newPos(:,1)-xx').^2 + (newPos(:,2)-yy').^2));
%     xx(2:end) = newPos(2:end,1)';%The beginning point is fixed.
%     yy(2:end) = newPos(2:end,2)';
% end

%We'll assume the size of the boxes is such that the only possible overlap
%is between adjacent boxes.

numBoxes = length(xx)-1 -2 +1;

mask = zeros(size(BW,1), size(BW,2),numBoxes);
testOverlap = zeros(size(BW));

 for i=2:length(xx)-1
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
 
 %Cut off any part of the mask outside the fish
 thisMask = thisMask.*BWInit;
 
 %Save this mask
 mask(:,:,i-1) = i* thisMask;
 
 
 end
 %The mask structure above is somewhat unwieldy and unncessarily large
 %Convert it to an array of label matrices that contain non-overlapping
 %elements.
 
 
 %Collect the indices of all the boxes
 boxRegions =1:numBoxes; 
 boxRegionsNext = boxRegions; 
 
 numberPanels = 0;
 
 while(length(boxRegionsNext)>0)
     numberPanels = numberPanels+1; %Record the number of label matrices we'll need.
     
     boxRegions = boxRegionsNext;%Get the boxes that haven't been resorted from the previous iteration.
     boxRegionsNext = [];
     
     %If there's only one boxRegion then break
     if length(boxRegions)==1
        break 
     end
     
     maskComp = boxRegions(1);
     
     %See if any of the other boxes don't overlap with the chosen box. If
     %so, add them to the label matrix corresponding to that box.
     for i = 2:length(boxRegions)
         maskNum = boxRegions(i);
         isOverlap = unique(mask(:,:,maskNum).*mask(:,:,maskComp)>0);
         
         if(ismember(1, abs(isOverlap)))
             %Regions overlap, skip this mask for now, keep track of this
             %one
             boxRegionsNext(end+1) = maskNum;
             continue
         else
             mask(:,:,maskComp) = mask(:,:,maskComp) + mask(:,:,maskNum);
             mask(:,:,maskNum) = 0;
             
         end
         
     end 
 
 end
 
 %Remove masks that are now empty
 nMask= 1;
 maskTemp = zeros(size(BW,1), size(BW,2), numberPanels);
 
 for maskNum =1:numBoxes
     if (max(max(mask(:,:,maskNum))) ~=0   )
         maskTemp(:,:,nMask) = mask(:,:,maskNum);
         nMask = nMask +1;        
     end    
 end
 
 %Renaming the structure containing all the data about the different
 %regions.
 mask = maskTemp;

  

end
