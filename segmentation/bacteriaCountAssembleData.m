%bacteriaCountAssembleData: Collect together all the data for counting
%individual bacteria
%
%AUTHOR: Matthew Jemielita


function popAll = bacteriaCountAssembleData(param, minS, maxS)

maxC = length(param.color);
classifierType = 'svm'; %Default hard coded in for now-should make this a variable at some point
useRemovedBugList = false;


for nS = minS:maxS
    
    %Load in data
    rProp = load([param.dataSaveDirectory filesep 'singleBacCount'...
        filesep 'bacCount' num2str(scanNum) '.mat']);
    rPropAll = rProp.rProp;
    
    
    %Go through different colors
    for nC=1:maxC
        rProp = rPropAll{nC};
        rProp = bacteriaCountFilter(rProp, nS, nC, param, useRemovedBugList, classifierType);
    end
end


end