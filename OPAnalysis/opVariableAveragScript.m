%Calculate the opercle minimum and maximum width and the location along the
%line for a variety of averaging windows from 2 to 20 microns, in steps of
%2 microns.

%For the light sheet data

perimVal = opVariableAverage('C:\jemielita\markers_fish1', 2,143);

val.fish1 = cellfun(@opercleRatio, perimVal, 'UniformOutput', false);

disp('fish 1 done');



perimVal = opVariableAverage('C:\jemielita\markers_fish2', 1,144);

val.fish2 = cellfun(@opercleRatio, perimVal, 'UniformOutput', false);

disp('fish 2 done');




perimVal = opVariableAverage('C:\jemielita\markers_fish3', 1,143);

val.fish3 = cellfun(@opercleRatio, perimVal, 'UniformOutput', false);

disp('fish 3 done');




perimVal = opVariableAverage('C:\jemielita\markers_fish4', 1,144);

val.fish4 = cellfun(@opercleRatio, perimVal, 'UniformOutput', false);

disp('fish 4 done');


%And for the confocal data-Only difference: need to flip the order of perim
%to account for the different orientation of the confocal and light sheet
%camera

perimVal = opVariableAverage('C:\jemielita\markers_Confocalfish1', 1,144);
perimVal = cellfun(@flipud, perimVal, 'UniformOutput', false);

val.cfish1 = cellfun(@opercleRatio, perimVal, 'UniformOutput', false);

disp('fish 1 done');

perimVal = opVariableAverage('C:\jemielita\markers_Confocalfish2', 1,146);
perimVal = cellfun(@flipud, perimVal, 'UniformOutput', false);
val.cfish2 = cellfun(@opercleRatio, perimVal, 'UniformOutput', false);

disp('fish 2 done');

perimVal = opVariableAverage('C:\jemielita\markers_Confocalfish3', 1,146);
perimVal = cellfun(@flipud, perimVal, 'UniformOutput', false);
val.cfish3 = cellfun(@opercleRatio, perimVal, 'UniformOutput', false);

disp('fish 3 done');


perimVal = opVariableAverage('C:\jemielita\markers_Confocalfish4', 1,146);
perimVal = cellfun(@flipud, perimVal, 'UniformOutput', false);
val.cfish4 = cellfun(@opercleRatio, perimVal, 'UniformOutput', false);

disp('fish 4 done');


perimVal = opVariableAverage('C:\jemielita\markers_Confocalfish5', 1,144);
perimVal = cellfun(@flipud, perimVal, 'UniformOutput', false);
val.cfish5 = cellfun(@opercleRatio, perimVal, 'UniformOutput', false);

disp('fish 5 done');


%Calculate the ratio at the beginning and the end for all the data sets.
%This will give us a sense of what the appropriate averaging window is


ratio= [val.cfish1{1,:}];ratio2 = [val.cfish1{end,:}];
cRatio{1}(1,:) = ratio(1:4:40)./ratio(2:4:40);
cRatio{1}(2,:) = ratio2(1:4:40)./ratio2(2:4:40);


ratio= [val.cfish1{1,:}];ratio2 = [val.cfish2{end,:}];
cRatio{2}(1,:) = ratio(1:4:40)./ratio(2:4:40);
cRatio{2}(2,:) = ratio2(1:4:40)./ratio2(2:4:40);


ratio= [val.cfish1{1,:}];ratio2 = [val.cfish3{end,:}];
cRatio{3}(1,:) = ratio(1:4:40)./ratio(2:4:40);
cRatio{3}(2,:) = ratio2(1:4:40)./ratio2(2:4:40);


ratio= [val.cfish1{1,:}];ratio2 = [val.cfish4{end,:}];
cRatio{4}(1,:) = ratio(1:4:40)./ratio(2:4:40);
cRatio{4}(2,:) = ratio2(1:4:40)./ratio2(2:4:40);


ratio= [val.cfish1{1,:}];ratio2 = [val.cfish5{end,:}];
cRatio{5}(1,:) = ratio(1:4:40)./ratio(2:4:40);
cRatio{5}(2,:) = ratio2(1:4:40)./ratio2(2:4:40);


%And get the ratios for the light sheet data

ratio= [val.fish1{2,:}];ratio2 = [val.fish1{end,:}];
lRatio{1}(1,:) = ratio(1:4:40)./ratio(2:4:40);
lRatio{1}(2,:) = ratio2(1:4:40)./ratio2(2:4:40);


ratio= [val.fish2{1,:}];ratio2 = [val.fish2{end,:}];
lRatio{2}(1,:) = ratio(1:4:40)./ratio(2:4:40);
lRatio{2}(2,:) = ratio2(1:4:40)./ratio2(2:4:40);


ratio= [val.fish3{1,:}];ratio2 = [val.fish3{end,:}];
lRatio{3}(1,:) = ratio(1:4:40)./ratio(2:4:40);
lRatio{3}(2,:) = ratio2(1:4:40)./ratio2(2:4:40);


ratio= [val.fish4{1,:}];ratio2 = [val.fish4{end,:}];
lRatio{4}(1,:) = ratio(1:4:40)./ratio(2:4:40);
lRatio{4}(2,:) = ratio2(1:4:40)./ratio2(2:4:40);


%Find the average of the ratio of beginning and end aspect ratios as a
%function of the averaging window
cAveRatio = zeros(2,10);
for i=1:5
   cAveRatio(1,:) = cAveRatio(1,:) + cRatio{i}(1,:);
   cAveRatio(2,:) = cAveRatio(2,:) + cRatio{i}(2,:);
    
end
cAveRatio(1,:) = cAveRatio(1,:)/5;
cAveRatio(2,:) = cAveRatio(2,:)/5;

lAveRatio = zeros(2,10);
for i=1:4
   lAveRatio(1,:) = lAveRatio(1,:) + lRatio{i}(1,:);
   lAveRatio(2,:) = lAveRatio(2,:) + lRatio{i}(2,:);
end
lAveRatio(1,:) = lAveRatio(1,:)/4;
lAveRatio(2,:) = lAveRatio(2,:)/4;

figure; plot(lAveRatio(2,:)./lAveRatio(1,:));
title('Average of ratio of beginning and end width ratios vs. averaging window: light sheet');

figure; plot(cAveRatio(2,:)./cAveRatio(1,:));
title('Average of ratio of beginning and end width ratios vs. averaging window:confocal');

%Conclusion from these plots: for all given averaging windows the result
%that the width ratios is different for the light sheet and confocal data
%holds.

%Need to show that the width measurements for the opercle don't do anything
%odd. It was noticed by Raghu that both the maximum and minimum width of
%the opercles are increasing over time. I suspect that the reason for this
%is that the maximum and minimum width found are very close for the
%confocal data set since the OP's are rather tube-like. If this is the case
%then we should see the difference in the found position for the maximum
%and minimum width to be ~ the same for the confocal, but diverge for the
%light sheet as the scan is proceeding.


%Only doing this for the 20 micron averaging window data

%Confocal data
cInd = [val.cfish1{:,end}];
cDiff1 = cInd(4:4:length(cInd))- cInd(3:4:length(cInd));

cInd = [val.cfish2{:,end}];
cDiff2 = cInd(4:4:length(cInd))- cInd(3:4:length(cInd));

cInd = [val.cfish3{:,end}];
cDiff3 = cInd(4:4:length(cInd))- cInd(3:4:length(cInd));

cInd = [val.cfish4{:,end}];
cDiff4 = cInd(4:4:length(cInd))- cInd(3:4:length(cInd));

cInd = [val.cfish5{:,end}];
cDiff5 = cInd(4:4:length(cInd))- cInd(3:4:length(cInd));

%Light sheet data

lInd = [val.fish1{:,end}];
lDiff1 = lInd(4:4:length(lInd))- lInd(3:4:length(lInd));

lInd = [val.fish2{:,end}];
lDiff2 = lInd(4:4:length(lInd))- lInd(3:4:length(lInd));

lInd = [val.fish3{:,end}];
lDiff3 = lInd(4:4:length(lInd))- lInd(3:4:length(lInd));

lInd = [val.fish4{:,end}];
lDiff4 = lInd(4:4:length(lInd))- lInd(3:4:length(lInd));

%Padding the ends of the data
lDiff3(end+1) = NaN;
lDiff1(end+1) = NaN;

cDiff1(end+1:end+2) = NaN;
cDiff5(end+1:end+2) = NaN;

meanC = nanmean([cDiff1; cDiff2; cDiff3; cDiff4; cDiff5]);
meanL = nanmean([lDiff1; lDiff2; lDiff3; lDiff4]);

figure; plot(meanC);

figure; plot(meanL);
%Conclusion: On the light sheet data there is a larger separation between
%the widest and narrowest points on the opercle. I believe this explains
%why the narrowest and widest parts of the confocal opercles were both
%widening, while the light sheet opercles were not.







