%assembleDiffRegPop: Calculate the population within different rough
%regions of the gut (Inside the bulb, before autofluorescent cells, after
%autofluorescent cells, posterior of gut)
%

function [popDiffReg, regInd] = assembleDiffRegPop(param, popXpos)
maxS = size(param.endBulbPos,1);

%Add to the end of points that weren't found
while(size(param.endGutPos,1)<maxS)
    param.endGutPos(end+1,:) = param.endGutPos(end,:);
end

while(size(param.autoFluorPos,1)<maxS)
    param.autoFluorPos(end+1,:) = param.autoFluorPos(end,:);
end

while(size(param.endBulbPos,1)<maxS)
   param.endBulbPos(end+1,:) = param.endBulbPos(end,:);   
end
popDiffReg = zeros(maxS, length(param.color), 4);
    
for nS=1:maxS
    cL = param.centerLineAll{nS};
    
    endGutPos = param.endGutPos(nS,:);
    autoFluorPos = param.autoFluorPos(nS,:);
    endBulbPos = param.endBulbPos(nS,:);
    
    endGut = closestInd(cL, endGutPos);
    autoFluor = closestInd(cL, autoFluorPos);
    endBulb = closestInd(cL, endBulbPos);
    
    regInd(nS,1:3) = [endBulb, autoFluor, endGut];
    
    for nC=1:length(param.color)
        popDiffReg(nS,nC, 1) = sum(popXpos{nS,nC}(1, 1:endBulb));
        popDiffReg(nS,nC,2) = sum(popXpos{nS,nC}(1,endBulb+1:autoFluor));
        popDiffReg(nS,nC,3) = sum(popXpos{nS,nC}(1,autoFluor+1:endGut));
        popDiffReg(nS,nC, 4) = sum(popXpos{nS,nC}(1,endGut+1:end));
    end
    
end
end

function ind = closestInd(allPt, pt)

allDist = (allPt(:,1)-pt(1)).^2 + (allPt(:,2)-pt(2)).^2;

ind = find(allDist ==min(allDist));

end