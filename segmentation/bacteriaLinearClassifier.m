%Classify bacteria using a linear classifier


function rPropOut = bacteriaLinearClassifier(rProp, trainingList)


%The last column in trainingList is 1 if the spot has been misidentified
%and 0 otherwise.

bug = cell(size(trainingList,1), 1);
ind = find(trainingList(:,4)==1);
[bug{ind}] = deal('no');
foundInd = setdiff(1:size(trainingList,1), ind);
[bug{foundInd}] = deal('yes');


%Construct array of values for each of the found spots

cen = [rProp.CentroidOrig];
cen = reshape(cen, 3, length(cen)/3);
cenRatio = max(cen, [],1)./min(cen, [],1);

allData(:,1) = [rProp.MeanIntensity];
allData(:,2) = [rProp.Area];
allData(:,3) = cenRatio;

ldaClass = classify(allData, trainingList(:,1:3), bug);

ind = cellfun(@(x)strcmp(x, 'yes'), ldaClass, 'UniformOutput', false);
ind = cell2mat(ind);

rPropOut = rProp(ind);
end