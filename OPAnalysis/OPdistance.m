function [d1 d2] = OPdistance(data, scope)
if scope == 1
    scale = repmat([6.5/40 6.5/40 1],size(data,1),1); %Light sheet scale
elseif scope == 2
    scale = repmat([16/(1.1*40) 16/(1.1*40) 1],size(data,1),1); %Spinning Disk
else 
    disp('Please use 1 for light sheet scale and 2 for spinning disk')
end

%data = data(:,6:8);
    
    datasc = data.*scale;
    d1 = sqrt((datasc(1,:)-datasc(2,:))*(datasc(1,:) - datasc(2,:))');
    d2 = sqrt((datasc(3,:)-datasc(4,:))*(datasc(3,:) - datasc(4,:))');
end

