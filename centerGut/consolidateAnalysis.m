%consolidateAnalysis: Consolidate the analysis of different scans into one
%cell array


function regFeat = consolidateAnalysis(baseName, minS, maxS)
%Need to be more flexible with the user input

regFeat = cell(2,1);
regFeat{1} = cell(maxS-minS+1,1);
regFeat{2} = cell(maxS-minS+1,1);

for nS=minS:maxS
   
reg =load([baseName, num2str(nS), '.mat']);
regFeat{1}{nS} = reg.regFeatures{1};
regFeat{2}{nS} = reg.regFeatures{2};

end