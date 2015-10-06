load('plotReadyAmpParameters02-Sep-2015.mat')
aMWT7=mean(ampMeanFOddInOrderOfTime);
aSWT7=std(ampMeanFOddInOrderOfTime);
aMRT7=mean(ampMeanFEvenInOrderOfTime);
aSRT7=std(ampMeanFEvenInOrderOfTime);
load('plotReadyAmpParameters02-Sep-2015.mat')
aMWT6=mean(ampMeanFOddInOrderOfTime);
aSWT6=std(ampMeanFOddInOrderOfTime);
aMRT6=mean(ampMeanFEvenInOrderOfTime);
aSRT6=std(ampMeanFEvenInOrderOfTime);
load('plotReadyAmpParameters202-Sep-2015.mat')
aMWT5=mean(ampMeanFOddInOrderOfTime);
aSWT5=std(ampMeanFOddInOrderOfTime);
aMRT5=mean(ampMeanFEvenInOrderOfTime);
aSRT5=std(ampMeanFEvenInOrderOfTime);

X=5:7;
YWT=[aMWT5,aMWT6,aMWT7];
YRT=[aMRT5,aMRT6,aMRT7];
YSWT=[aSWT5,aSWT6,aSWT7]/sqrt(15);
YSRT=[aSRT5,aSRT6,aSRT7]/sqrt(15);

h=figure;
errorbar(X,YWT,YSWT,'o', 'markersize', 14, 'color', [0.0 0.3 0], 'markerfacecolor', [0.0 0.9 0.3]);hold on;
errorbar(X,YRT,YSRT,'d', 'markersize', 14, 'color', [0.4 0 0], 'markerfacecolor', [0.7 0.2 0]);hold off;
legend('WT','Ret');
title('Quiescent Subtracted R.M.S. Wave Amplitudes for WT/Ret over 3 days','FontSize',17,'FontWeight','bold');
xlabel('Day Number','FontSize',20);
ylabel('R.M.S. Amplitude (arb.)','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');