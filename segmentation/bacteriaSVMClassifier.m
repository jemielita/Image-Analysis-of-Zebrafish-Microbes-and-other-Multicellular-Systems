%
%AUTHOR: Matthew Jemielita, September 24, 2013

function rPropOut = bacteriaSVMClassifier(rProp, svmStruct)



%Construct array of values for each of the found spots

cen = [rProp.CentroidOrig];
cen = reshape(cen, 3, length(cen)/3);
cenRatio = max(cen, [],1)./min(cen, [],1);

allData(:,1) = [rProp.MeanIntensity];
allData(:,2) = [rProp.Area];
allData(:,3) = cenRatio;

svmClass = svmclassify(svmStruct, allData);

rPropOut = rProp(svmClass =='true');

end