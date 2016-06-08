% Script for plotting temperature data from 4-2016

% Temperature values of the water written in lab notebook
temps4_20_2016 = [ 21.1, 31.0, 23.7;...
                   23.3, 31.5, 23.9;...
                   23.3, 31.6, 23.3;...
                   22.1, 31.3, 26.2;...
                   25.3, 31.3, NaN]; % ASSUMES DATA IS IN ORDER!

numFish = max( fishParams( :, 9 ) ); % number in fishParams (e.g. 9) should match the index where the fish number is stored
h = figure; hold on;

for i = 1:numFish
    
    curFishParams = fishParams( fishParams( :, 9 ) == i, : );
    curTemps = temps4_20_2016( i, : );
    curTemps( isnan( curTemps ) ) = [];
    curFreqs = curFishParams( :, 2 );
    plot( curTemps, curFreqs, 'Color', [ (i-1)/(numFish-1), 0, (numFish - i)/(numFish-1) ] );
    
end

hold off;