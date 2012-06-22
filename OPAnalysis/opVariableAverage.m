%Calculate the maximum and minimum opercle widthe of a variety of averaging
%windows.


function perimVal = opVariableAverage(path, minS, maxS)
maxW = 20;minW = 2;
wVal = 2:2:20;

perimVal = cell(maxS-minS+1, maxW-minW+1);

for nS = minS:maxS
    
    convexPt = load([path, filesep, 'OP_Scan', sprintf('%03d', nS), 'convex.mat'], 'convexPt');
    convexPt = convexPt.convexPt;
    
    for nW=1:length(wVal)
        perimVal{nS,nW} = squeeze(opAverage(convexPt, wVal(nW), 'ave'));
    end
   
    disp(nS);
end

end

