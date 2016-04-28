% Plot a day of fish data
% Assumes data is called paramsAmpWidFreqPeriodSpeedSsresidbynR2FN

%% Initialize variables
colorWheelBorder = [ [0, 0, 0.4]; [0, 0.3, 0]; [0.4, 0, 0] ];
colorWheelFill = [ [0.6, 0.4, 0.9]; [0.4, 0.95, 0.6]; [0.9, 0.6, 0.4] ];
colorWheelO = colorWheelBorder( [ 1, 3 ], : );
colorWheelF = colorWheelFill( [ 1, 3 ], : );
whichPlot = [ true, true, true, true, true ]; % Plot which parameters?: Amp, duration, freq, wave speed, sigB (variation)
removeNaNsQ = true;

% Initialize experiment specific variables
typeAFishBoolInd = 1 : 2 : size( paramsAmpWidFreqPeriodSpeedSsresidbynR2FN, 1 ); % To avoid rewriting script, use typeA-typeZ to describe different fish types
typeBFishBoolInd = 2 : 2 : size( paramsAmpWidFreqPeriodSpeedSsresidbynR2FN, 1 );
[~, typeAFishIndices, ~] = intersect( paramsAmpWidFreqPeriodSpeedSsresidbynR2FN( :, 7 ), typeAFishBoolInd );
[~, typeBFishIndices, ~] = intersect( paramsAmpWidFreqPeriodSpeedSsresidbynR2FN( :, 7 ), typeBFishBoolInd );
typeAFish = paramsAmpWidFreqPeriodSpeedSsresidbynR2FN( typeAFishIndices, : );
typeBFish = paramsAmpWidFreqPeriodSpeedSsresidbynR2FN( typeBFishIndices, : );
if( removeNaNsQ )
    typeAFish( isnan( typeAFish( :, 6 ) ), : ) = [];
    typeBFish( isnan( typeBFish( :, 6 ) ), : ) = [];
end
theTitle = 'Conv vs GF motility';
groupLabel = { '6DPFConv','6DPFGF' };

% Fill size assymmetry of typeAFish and typeBFish with NaNs
sizeDif = size( typeAFish, 1 ) - size( typeBFish, 1 );

if( sizeDif > 0 )
    typeBFish = [typeBFish; nan( sizeDif, size( typeBFish, 2 ) ) ];
elseif( sizeDif < 0 )
    typeAFish = [typeAFish; nan( abs(sizeDif), size( typeAFish, 2 ) ) ];
end

% Place freq into period
% typeAFish( :, 3 ) = 60./typeAFish( :, 3 );
% typeBFish( :, 3 ) = 60./typeBFish( :, 3 );

% Plot data!
for i = 1 : size( whichPlot, 2 )
    
    if( whichPlot( i ) )
        
        h = figure;
        set(gca, 'FontName', 'Arial')
        fishOrdered = [ typeAFish( :, i ), typeBFish( :, i ) ];
        scatterBox( fishOrdered, {groupLabel, colorWheelO, colorWheelF});
        axis auto;
        
        switch i
            
            case 1
                title( strcat( {'Amplitude '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
                ylabel( 'Wave Amplitude (px^2)', 'FontSize', 20 );
            case 2
                title( strcat( {'Pulse Duration '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
                ylabel( 'Wave Duration (s)', 'FontSize', 20 );
            case 3
                title( strcat( {'Frequency '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
                ylabel( 'Wave Frequency (min^{-1})', 'FontSize', 20 );
            case 4
                title( strcat( {'Wave Speed '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
                ylabel( 'Wave Speed (\mum/s)', 'FontSize', 20 );
            case 5
                title( strcat( {'Wave Speed Variance '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
                ylabel( 'Wave Speed Variance (\mum/s)', 'FontSize', 20 );
            otherwise
                
        end
            
    % Make larger text
    set(findall(h,'type','axes'),'fontsize',20);
    end
    
end