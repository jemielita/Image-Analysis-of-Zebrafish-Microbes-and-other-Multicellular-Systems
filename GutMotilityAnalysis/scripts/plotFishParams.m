% Plot fishParams 

numFish = max( fishParams( :, 9 ) ); % number in fishParams (e.g. 9) should match the index where the fish number is stored
%time = [0, 50, 96, 147, 198]; % Acetylcholine
time = [0, 45, 97, 153]; % No Acetylcholine
h = figure; hold on;

for i = 1:numFish
    
    curFishParams = fishParams( fishParams( :, 9 ) == i, : );
    wantedParam = curFishParams( :, 6 );
    plot( time, wantedParam, '-o', 'Color', [ (i-1)/(numFish-1), 0, (numFish - i)/(numFish-1) ] );
    xlabel('Time (min)','FontSize',20,'FontWeight','bold');
    ylabel('Amplitude (um)','FontSize',20,'FontWeight','bold');
    title('Zebrafish Gut Motility Over Time','FontSize',15,'FontWeight','bold');
    set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
    
end

hold off;