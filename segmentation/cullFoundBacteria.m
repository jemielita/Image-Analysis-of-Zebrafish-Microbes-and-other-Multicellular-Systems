%Cull the estimated found bacteria and remove fall positives. The exact
%parameters used here will largely be set by a series of training data.

function rPropNew = cullFoundBacteria(rProp, gutMask, cullProp,xOffset, yOffset)

borderDist = 2/0.1625;
absoluteMin = 10;
radCutoff = 10;
%% Remove really small regions
fprintf(1, 'cullFoundBacteria: Remove small regions');
ind = [rProp.Area]>absoluteMin;
rProp = rProp(ind);

fprintf(1, '\n');

%% Remove found regions close to the border of the gutMask-Lot's of false
%positives here

fprintf(1, 'cullFoundBacteria: Remove regions touching border');

xy = [rProp.Centroid];xy = reshape(xy, 3, length(rProp)); xy = xy(1:2, :);

xy(1,:) = xy(1,:) + yOffset;
xy(2,:) = xy(2,:) + xOffset;


%Remove pixels close to the boundary of gutMask
gutMask = bwperim(gutMask);
[xyGutMask(2,:), xyGutMask(1,:)] = find(gutMask==1);

ind = zeros(length(rProp),1);
for i=1:length(rProp)
    thisDist = sqrt( (xyGutMask(1,:)-xy(1,i)).^2 +(xyGutMask(2,:)-xy(2,i)).^2);
    ind(i) = sum(thisDist<borderDist)>0;
    
    
end
ind = ~logical(ind);
xy = xy(:, ind);


displayStep = false;
if(displayStep==true)
    figure; imshow(gutMask)
    hold on
    for i=1:size(xy,2)
        plot(xy(1,i), xy(2,i), 'o', 'Color', [1 0 0],...
            'MarkerSize', 10);
        
    end
    
end


rProp = rProp(ind); 

fprintf(1, '\n');

%% Remove regions that are close to brighter pixels
radCutoff = 4;
rProp = combineRegions(rProp,radCutoff);


%% Output 
rPropNew = rProp;
end