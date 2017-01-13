% Script which does stuff with our threshold function

meanedCMPT = squeeze(mean(countedMotPerTime,2));

figure;plot(mean(totalThreshValues)*60);
ylabel('Events per minute');
xlabel('Threshold intensity');
title('FFT as Func of Threshold');

for i=1:size(meanedCMPT,1)
    figure;plot(meanedCMPT(i,:));
    ylabel('Events per minute');
    xlabel('Threshold intensity');
    title('Counts as Func of Thresh');
end