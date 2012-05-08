function [convexPt, linePt] = opWidth(imT, pos)
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
    
    gridPlane(:) = 0;
    gridPlane(interPtIn) = 1;
    imshow(gridPlane);
    title(lineNum);
    drawnow;
    
    interPt = planePt(interPtIn,:);
   [xyCon, zCon] = ind2sub(size(xgrid), interPtIn);
   
   
   if(length(unique(zCon))>1)
       k = convhull(xyCon, zCon);
       xyCon = xyCon(k); zCon = zCon(k);
       convexPt{lineNum-1} = [xyCon, zCon];
   end
       
    %if(size(interPt,1)==0)
    %delete(hP1), delete(hP2)
    if(exist('hP1'))
        delete(hP1)
    end
    if(exist('hP2'))
        delete(hP2)
    end
    
    fprintf(2, '.');
    
%     hP1 = plot3(interPt(:,1), interPt(:,2), interPt(:,3), '-rs','MarkerFaceColor', 'g',...
%         'MarkerSize', 5);
%     hP2 = plot3(lineVal(:,1), lineVal(:,2), lineVal(:,3), '-s','MarkerSize', 5, 'MarkerFaceColor', 'r');
%     %pause
%     
% %     else
% %        set(hP1, 'xData', interPt(:,1));set(hP1, 'Data', interPt(:,2)); 
% %        set(hP1, 'yData', interPt(:,3)); 
% %        
% %         set(hP2, 'xData', lineVal(:,1));set(hP2, 'yData', lineVal(:,2)); 
% %        set(hP2, 'zData', lineVal(:,3)); 
% %        
% %        
% %         
% %     end
%     title(lineNum)
%     drawnow;
%     b =0;
    
    %Now finding the location of these 
    
end
fprintf(2, '\n');
% 
% 
% %Rescaling pos
% pos(1,1) = pos(1,1) - xMin;
% pos(2,1) = pos(2,1) - xMin;
% pos(1,2) = pos(1,2) - yMin;
% pos(2,2) = pos(2,2) - yMin;
% 
% %Along the length of the gut, calculate the projection
% xx = pos(1,1) + (pos(2,1)-pos(1,1))*(1:500)/500;
% 
% yy = pos(1,2) + (pos(2,2)-pos(1,2))*(1:500)/500;
%     
% 
% %Parameterizing curve in terms of arc length
% t = cumsum(sqrt([0,diff(xx(:)')].^2 + [0,diff(yy(:)')].^2));
% 
% %Resampling so that y is sampled at spacings of one pixel-there's no need
% %to sample any finer.
% 
% xx = spline(t, xx, t);
% yy = spline(t, yy, t);
% 
% stepSize = 1;
% xx = interp1(t, xx, min(t):stepSize:max(t), 'spline', 'extrap');
% yy = interp1(t, yy, min(t):stepSize:max(t), 'spline', 'extrap');
% 
% yMin = 1;
% xMin = 1;
% 
% yMax = size(imT,1);
% xMax = size(imT,2);
% 
% figure; imshow(sum(imPerim,3));
% hold on
%     
% fprintf(2,'Getting convex hull down the width of OP:\n');
% 
% perimW = zeros(length(xx)-1);
% 
% 
% lineIm = zeros(size(imT,1), size(imT,2)); %For getting a mask for the line
% 
% for lineNum=2:length(xx)
%     
%     x = xx(lineNum)-xx(lineNum-1);
%     y = yy(lineNum)-yy(lineNum-1);
%     xI = x+1;
%     yI = y+2;
%     
%     %Line should be long enough to span the entire gut...Far more than that
%     %right now.
%     Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];    
%     xVal = xx(lineNum)+ Orth(1)*[-500:1:500];
%     yVal = yy(lineNum)+ Orth(2)*[-500:1:500];
%     
%     %Get rid of elements of xVal and yVal outside the image size
%     index = find(round(xVal)>xMax |round(xVal)<xMin);
%     xVal(index) = [];
%     yVal(index) = [];
%     
%     index = find(round(yVal)>yMax |round(yVal)<yMin);
%     xVal(index) = [];
%     yVal(index) =[];
%     
%     indexLine = cat(2, round(xVal)', round(yVal)');
%    
%     onLine = sub2ind([size(imT,1), size(imT,2)], indexLine(:,2), indexLine(:,1));
%     lineIm(:) = 0;
%     lineIm(onLine) =1;
%     
%     %See where the line intersects with the perimeter of the opercle.
%     overlapIm = imPerim.*repmat(lineIm, [1,1,size(imT,3)]);
%     
%     %Get the location of the pixels that make up the boundary
%     ind = find(overlapIm==1);
%     [xPerim, yPerim, zPerim] = ind2sub(size(imT), ind);
%     
%     unZ = unique(zPerim);
%     
%     xyCon = [];
%     zCon = [];
%    
%     ptVal = 1:size(indexLine,1);
%     
%     for zH=1:length(unZ); 
%         ind = find(zPerim ==unZ(zH));
%         thisRow = cat(2, yPerim(ind), xPerim(ind));
%         
%         %See where this lies on the line
%         t = ismember(indexLine, thisRow, 'rows');
%         
%         xyCon = [xyCon; ptVal(t)'];
%         zCon  = [zCon; (1/0.1625)*zH*ones(length(ptVal(t)),1  )];
%         
%     end
%     
%     if(length(unique(zCon))>1)
%        %Calculate the convex hull at this point along the line
%        k = convhull(xyCon, zCon);
%        xyCon = xyCon(k); zCon = zCon(k);
%        convexPt{lineNum-1} = [xyCon, zCon];
%     end
%     
% fprintf(2, '.');
% 
% end
% 
% fprintf('\n');

end
