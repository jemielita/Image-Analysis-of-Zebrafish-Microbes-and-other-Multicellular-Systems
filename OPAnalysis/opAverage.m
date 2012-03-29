%Averaging out the results of the convex hull in terms of microns.
%This is analogous to measuring the width of the opercle using different
%rubber bands


function [perim, xx, yy] = opAverage(convexPt, xx,yy,aveL)

perim = zeros(length(convexPt), 1);

for i=1:length(convexPt)
    minR = max(1, i-floor(aveL/2));
    maxR = min(length(convexPt), i+ceil(aveL/2));
    
    aveRegion = cat(1, convexPt{minR:maxR}, []);

    if(~isempty(aveRegion))
        ind = convhull(aveRegion(:,1), aveRegion(:,2));
    
        xCon = aveRegion(:,1);yCon= aveRegion(:,2);
        xCon = xCon(ind); yCon = yCon(ind);
        newHull{i} = cat(2, xCon, yCon);
        
        %Calculate the perimeter of the opercle at this point.
        perim(i) = sqrt(sum(diff(xCon).^2 + diff(yCon).^2));
%         
%          plot(aveRegion(:,1), aveRegion(:,2),'*');
%          hold on
%          plot(xCon, yCon);
%          pause
%          close all
    end

    

    
end







end