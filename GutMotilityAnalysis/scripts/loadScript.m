% Extract WT data. Probably won't work often.

here=pwd;
folds=dir(here);
folds(1:2)=[];
wTData=[];

for i=1:size(folds,1)
    cd(folds(i).name);
    subFolds=dir;
    subFolds(1:2)=[];
    cd(subFolds(1).name);
    cd('Data');
    load('GutParameters04-Aug-2015.mat')
    wTData=[wTData;[waveAverageWidth, waveFrequency, waveSpeedSlope, SSresid/analyzedDeltaMarkers(2), averageMaxVelocities]];
    cd('../../..');
end