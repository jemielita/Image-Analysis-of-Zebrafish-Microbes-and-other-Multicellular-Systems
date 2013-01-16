%createAllMasks: create a mask for each region in scanParam.scanList and
%save the result
%
%NOTE: should check to see if the masks have already been made
function [] = createAllMasks(scanParam, param)

%Create a folder to save all the constructed masks...we don't want to store
%all of these in memory!
maskDir = [param.dataSaveDirectory filesep 'masks'];
if(isdir(maskDir))
    fprintf(1, '\n Mask directory has already been made. No new masks will be made.\n');
    fprintf(1, 'If scan parameters have been changed delete or rename this directory of masks!\n');
    return
end
mkdir(maskDir);

maskInd = zeros(length(scanParam.scanList),1);

fprintf(1, 'Finding optimal cuts for all scans');

for nS = 1:length(scanParam.scanList)
    thisScan= scanParam.scanList(nS);
   
    if(nS==1)
        param.cutValAll{thisScan} = ...
            calcOptimalCut(scanParam.regOverlap, param, thisScan);
        maskInd(nS) = thisScan;
        lastScan = thisScan;
    else 
        lastScan = scanParam.scanList(nS-1);
        sameLine = isequal(param.centerLineAll{lastScan}(:),param.centerLineAll{thisScan}(:));
        sameOutline = isequal(...
            param.regionExtent.polyAll{lastScan}(:),param.regionExtent.polyAll{thisScan}(:));
        if(sameLine==true && sameOutline==true)        
            param.cutValAll{thisScan} = param.cutValAll{lastScan};
            
            maskInd(nS) = lastScan;
        else
            param.cutValAll{thisScan} = ...
                calcOptimalCut(scanParam.regOverlap, param, thisScan);
            maskInd(nS) = thisScan;
            lastScan = thisScan;
        end
        
    end
    fprintf(1, '.');
end
cutValAll = param.cutValAll;

save([maskDir filesep 'cutVal.mat'], 'cutValAll');
fprintf(1, '\n');

uniqMasks = unique(maskInd);

fprintf(1, 'Creating masks for all scans\n');

for nS=1:length(scanParam.scanList)
thisScan= scanParam.scanList(nS);
    [centerLine, gutMask] = getThisMask(scanParam, param,thisScan);
    outFile = [maskDir filesep 'mask_', num2str(thisScan), '.mat'];

    save(outFile, 'centerLine', 'gutMask');
fprintf(1, '.');
end
fprintf(1, '\n');

% 
% centerLineAll = cell(length(maskInd),1);
% gutMaskAll = cell(length(maskInd),1);
% 
% %Only create masks for the unique gut outlines.
% 
% matlabpool
% parfor nS = 1:length(uniqMasks)
%     thisScan = uniqMasks(nS);
%     [centerLineAll{nS}, gutMaskAll{nS}] = getThisMask(scanParam, param,thisScan);      
% fprintf(1, '.');
% end
% matlabpool close
% 
% fprintf(1, '\n');

%Now saving all the masks
% for nS=1:length(maskInd);
%     thisScan = scanParam.scanList(nS);
%     outFile = [maskDir filesep 'mask_', num2str(thisScan), '.mat'];
%     
%     %Get the appropriate mask from the unique masks calculated
%     scanIndex = maskInd(nS);ind = find(uniqMasks==scanIndex);
%     eval(['centerLine = centerLineAll{',num2str(ind), '};']);
%     eval(['gutMask = gutMaskAll{',num2str(ind), '};']);
%     
%     save(outFile, 'centerLine', 'gutMask');
% 
% end

end

function [centerLine, gutMask] = getThisMask(scanParam, param,thisScan)
%If the mask is different, then recalculate the mask
numCuts = size(param.cutValAll{thisScan},1);
centerLine = cell(numCuts,1);
gutMask = cell(numCuts,1);

for cN =1:numCuts
    [centerLine{cN}, gutMask{cN}] =...
        constructRotRegion(cN,thisScan, '', param, true);
end

end