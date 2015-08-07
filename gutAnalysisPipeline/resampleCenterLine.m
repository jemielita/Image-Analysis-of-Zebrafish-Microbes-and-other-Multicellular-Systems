
function param = resampleCenterLine(param, scanParam)

for nS=1:size(param.centerLineAll,1)
    clear polyT polyFit
   
    poly = param.centerLineAll{nS};
    
    %Resample the center line at the desired spacing
    stepSize = scanParam.stepSize/0.1625;
    
    %Parameterizing curve in terms of arc length
    t = cumsum(sqrt([0,diff(poly(:,1)')].^2 + [0,diff(poly(:,2)')].^2));
    %Find x and y positions as a function of arc length
    polyFit(:,1) = spline(t, poly(:,1), t);
    polyFit(:,2) = spline(t, poly(:,2), t);
    
    polyT(:,2) = interp1(t, polyFit(:,2),min(t):stepSize:max(t),'spline', 'extrap');
    polyT(:,1) = interp1(t, polyFit(:,1),min(t):stepSize:max(t), 'spline', 'extrap');
    
    %Redefining poly
    poly = cat(2, polyT(:,1), polyT(:,2));
    
    param.centerLineAll{nS} = poly;
end

end