%calcGutWidth: Calculate the approximate width of the gut for all 

function gutWidth = calcGutWidth(cl, gutPoly)

gutWidth = zeros(size(cl,1),1);

xx = cl(:,1);
yy = cl(:,2);
for nL = 2:size(cl,1)
    gutWidth(nL) = getGutWidth(xx,yy,nL,gutPoly);
end

end


function gutWidth = getGutWidth(xx,yy,i, gutPoly)

%Smooth out gut outline curve
%Parameterizing curve in terms of arc length
t = cumsum(sqrt([0,diff(gutPoly(:,1)')].^2 + [0,diff(gutPoly(:,2)')].^2));
%Find x and y positions as a function of arc length
polyFit(:,1) = spline(t, gutPoly(:,1), t);
polyFit(:,2) = spline(t, gutPoly(:,2), t);

%Interpolate curve to make it less jaggedy, arbitrarily we'll
%set the number of points to be 50.
stepSize = (max(t)-min(t))/1000.0;

polyT(:,2) = interp1(t, polyFit(:,2),min(t):stepSize:max(t),'spline', 'extrap');
polyT(:,1) = interp1(t, polyFit(:,1),min(t):stepSize:max(t), 'spline', 'extrap');

%Redefining poly
gutPoly = cat(2, polyT(:,1), polyT(:,2));




vectSize = 500;
x = xx(i)-xx(i-1);
y = yy(i)-yy(i-1);
xI = x+1;
yI = y+2;

Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];


xValLow = xx(i)+ Orth(1)*(vectSize)*[-1:0.01:0];
xValHigh = xx(i)+ Orth(1)*(vectSize)*[0:0.01:1];

yValLow = yy(i)+ Orth(2)*(vectSize)*[-1:0.01:0];
yValHigh = yy(i)+ Orth(2)*(vectSize)*[0:0.01:1];

%Finding point on each line closest to the gut outline
posL = getGutDist(xValLow, yValLow, gutPoly);
posH = getGutDist(xValHigh, yValHigh, gutPoly);

%Get the width of the gut at this point
gutWidth = sqrt((posH(1)-posL(1)).^2 + (posH(2)-posL(2)).^2);
% figure; plot(gutPoly(:,1), gutPoly(:,2));
% hold on;
% plot(xx, yy);
% 
% plot(xValLow, yValLow);

end


function gutWidth = getGutDist(x,y,gutPoly)
xy = [x;y];

gDist = dist(xy', gutPoly');

minVal = min(gDist,[],2);
[~,ind] = min(minVal);

gutWidth = xy(:,ind);
%figure; plot(gutPoly(:,1), gutPoly(:,2));
%hold on;
%plot(x, y);

end