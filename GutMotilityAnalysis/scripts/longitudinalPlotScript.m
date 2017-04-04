% Plots longitudinal data

% Variables
xMinAmp = -0.5;
xMaxAmp = 90.5;
yMinAmp = 0;
yMaxAmp = 100;
lightBlueColor = [0.75, 0.85, 0.975];
darkBlueColor = [0.2, 0.3, 0.8];
lightRedColor = [0.975, 0.8, 0.75];
darkRedColor = [0.9, 0.3, 0.1];

% Plot
figure('PaperPositionMode', 'auto');
hold on;
figureLineWidths = 1.5;
plot(WTx5,WTAmplitude5, 'Linewidth', figureLineWidths, 'Color', lightBlueColor);
plot(WTx3,WTAmplitude3, 'Linewidth', figureLineWidths, 'Color', lightBlueColor, 'Linestyle', '--');
plot(WTx2,WTAmplitude2, 'Linewidth', figureLineWidths, 'Color', lightBlueColor, 'Linestyle', '-');
plot(WTx1,WTAmplitude1, 'Linewidth', figureLineWidths, 'Color', lightBlueColor, 'Linestyle', ':');
plot(WTx4,WTAmplitude4, 'Linewidth', figureLineWidths, 'Color', darkBlueColor);
% plot(Retx1,RetAmplitude1, 'Linewidth', figureLineWidths, 'Color', lightRedColor, 'Linestyle', '--');
% plot(Retx2,RetAmplitude2, 'Linewidth', figureLineWidths, 'Color', darkRedColor);
h=gcf;
% title('Amplitude','FontSize',20);
% xlabel('Time (min)','FontSize',20);
% ylabel('Amplitude (um)','FontSize',20);
set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
    'Arial', 'TickDir', 'out','box','off',...
    'Linewidth', figureLineWidths, 'TickLabelInterpreter', 'latex');
axis([xMinAmp xMaxAmp yMinAmp yMaxAmp])
axis square;
print(h,'WTAmp','-dpdf')