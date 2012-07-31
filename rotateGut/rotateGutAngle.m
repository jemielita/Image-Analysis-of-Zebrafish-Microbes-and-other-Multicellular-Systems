% rotateGutAngle: For a given mask of a region calculate the angle to rotate the
% mask so that the principal axis lies along the x-axis. This angle will be
% used to rotate the guts before analysis to minimize the needed memory and
% to improve visualization.
%
% USAGE:
% angle = rotateGutAngle(mask)
%
% INPUT: mask: an n x m binary mask of the region of interest.
%
% OUTPUT: angle in degrees to rotate the region
%
% AUTHOR: Matthew Jemielita, July 27, 2012

function angle = rotateGutAngle(mask)

if(sum(ismember([0 1], unique(mask))  )~=2)
    disp('Region mask must only contain 0s and 1s!');
    return
end

ind = find(mask==1);
[X Y] = ind2sub(size(mask),ind);
pos = cat(2,X, Y);

[coeff score] = princomp(pos);

meanPos = mean(pos,1);

%Getting points along the principal axis
dirVect = coeff(:,1);
t = [min(score(:,1))-.2, max(score(:,1))+.2];
endpts = [meanPos + t(1)*dirVect'; meanPos + t(2)*dirVect'];

% figure; imshow(mask)
% hold on
% plot(endpts(:,2), endpts(:,1), 'k-');

%Calculate angle 
xCenter = endpts(1,2)-endpts(2,2); xCenter = abs(xCenter);
yCenter = endpts(1,1)-endpts(2,1); yCenter = abs(yCenter);
angle = atan(yCenter/xCenter);

angle = rad2deg(angle);

angle = -angle; %Calculation above gives angle of prin. axis w.r.t to x-axis, not the angle to rotate this line by.
end