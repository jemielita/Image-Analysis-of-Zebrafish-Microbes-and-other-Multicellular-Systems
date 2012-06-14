%Averaging out the results of the convex hull in terms of microns.
%This is analogous to measuring the width of the opercle using different
%rubber bands


function perim = opAverage(varargin)

if(nargin==2)
    convexPt = varargin{1};
    aveL = varargin{2};
    type = 'ave';
end
if(nargin==3)

    convexPt = varargin{1};
    aveL = varargin{2};
    type = varargin{3};
end


perim = zeros(length(convexPt), 1);



for i=1:length(convexPt)
    minR = max(1, i-floor(aveL/2));
    maxR = min(length(convexPt), i+ceil(aveL/2));
    
    switch lower(type)
    
        case 'max'
            
            aveRegion = cat(2, convexPt{minR:maxR}, []);
            
            if(~isempty(aveRegion))
                ind = convhull(aveRegion(1,:), aveRegion(2,:));
                
                xCon = aveRegion(1,:);yCon= aveRegion(2,:);
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
        case 'ave'
            perim(i) = 0;
            for nR=minR:maxR
                if(~isempty(convexPt{nR})& ~ismember(-1,convexPt{nR}))
                    xCon = convexPt{nR}(1,:);yCon= convexPt{nR}(2,:);
                    %Calculate the perimeter of the opercle at this point.
                    perim(i) = perim(i) + sqrt(sum(diff(xCon).^2 + diff(yCon).^2));
               end
                
            end
            perim(i) = perim(i)/(maxR-minR);
            
            
    end

    
end
    

    
end
