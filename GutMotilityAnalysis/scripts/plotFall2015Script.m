% Script which plots various results from fall2015Data

% % Transform wavespeed to inverse wavespeed
% for i =1:9
%     fall2015Data(i).FishParameters(4,:) = 1./fall2015Data(i).FishParameters(4,:);
% end
% 
% %% Transform amplitude to the correct units
% fps = 5;
% micronsPerPixel = 0.325;
% for i =1:9
%     fall2015Data(i).FishParameters(2,:) = fall2015Data(i).FishParameters(2,:)/fps*micronsPerPixel;
% end

%% Initialize variables
colorWheelBorder = [ [0, 0, 0.4]; [0, 0.3, 0]; [0.4, 0, 0] ];
%colorWheelFill = [ [0.6, 0.4, 0.9]; [0.4, 0.95, 0.6]; [0.9, 0.6, 0.4] ]; % Old colors
colorWheelFill = [[0.2 0.3 0.8]; [0.2 0.9 0.2]; [0.9 0.3 0.1]];
%colorWheelBorder = colorWheelFill;
days0Months1 = true; % 0 plots all fish, all types, and all days, 1 plots boxplots of fish types per experiment
whichPlot = [ true, true, false, false, false ]; % Plot which parameters?: Amp, freq, inverse wave speed, sigB (variation), pulse
ampYMin = 0;
ampYMax = 52;
freqYMin = 0;
freqYMax = 0;

%% Plot all results per day
if( ~days0Months1 )
    for i = 1:size( fall2015Data,2 )
        
        % Initialize data dependant variables
        xTime = 1:size( fall2015Data( i ).FishParameters, 2 );
        curWTUBools = fall2015Data( i ).FishType( 1, : )&fall2015Data( i ).BoolsNonNaN;
        curWTFBools = fall2015Data( i ).FishType( 2, : )&fall2015Data( i ).BoolsNonNaN;
        curRetBools = fall2015Data( i ).FishType( 3, : )&fall2015Data( i ).BoolsNonNaN;
        
        % Plot all parameters
        for j = 2:size( fall2015Data( i ).FishParameters, 1 )
            
            % Plot only wanted plots
            if(whichPlot(j-1))
                
                % Make current figure
                h = figure;
                plot( xTime( curWTUBools ), fall2015Data( i ).FishParameters( j, curWTUBools ), 'Color', colorWheelBorder( 1, : ) ); hold on;
                plot( xTime( curWTFBools ), fall2015Data( i ).FishParameters( j, curWTFBools ), 'Color', colorWheelBorder( 2, : ) );
                plot( xTime( curRetBools ), fall2015Data( i ).FishParameters( j, curRetBools ), 'Color', colorWheelBorder( 3, : ) ); hold off;
                
                % Label x axis
                xlabel( 'Fish Number in Time','FontSize', 20 );
                
                % Determine the title, y axis
                switch j
                    case 2 % Amplitude
                        title( strcat( {'Amplitude '}, fall2015Data( i ).Title ), 'FontSize', 17, 'FontWeight', 'bold', 'interpreter','none' );
                        ylabel( 'Wave Amplitude (px/frame)', 'FontSize', 20 );
                    case 3 % Frequency
                        title( strcat( {'Frequency '}, fall2015Data( i ).Title ), 'FontSize', 17, 'FontWeight', 'bold', 'interpreter','none' );
                        ylabel( 'Wave Frequency (min^-1)', 'FontSize', 20 );
                    case 4 % Wave Speed
                        title( strcat( {'Wave Speed '}, fall2015Data( i ).Title ), 'FontSize', 17, 'FontWeight', 'bold', 'interpreter','none' );
                        ylabel( 'Wave Speed (um/s)', 'FontSize', 20 );
                    case 5 % Wave Speed Variability
                        title( strcat( {'Wave Speed Variance '}, fall2015Data( i ).Title ), 'FontSize', 17, 'FontWeight', 'bold', 'interpreter','none' );
                        ylabel( 'Wave Variance (um/s)', 'FontSize', 20 );
                    case 6 % Wave Duration
                        title( strcat( {'Wave Duration '}, fall2015Data( i ).Title ), 'FontSize', 17, 'FontWeight', 'bold', 'interpreter','none' );
                        ylabel( 'Wave Duration (s)', 'FontSize', 20 );
                    otherwise % New plot?
                end
                
                % Make all axes bold, larger text
                set(findall(h,'type','axes'),'fontsize',20,'fontWeight','bold');
                
            end
            
        end
        
    end
end

%% Plot all results per experiment
if( days0Months1 )
    
    % Loop through each month
    for i = 1:3
        
        % Initialize data dependant variables
        wTUs = nan( [ size( fall2015Data( i ).FishParameters, 1 ), size( fall2015Data( i ).FishParameters, 2 ), 3 ] );
        wTFs = nan( [ size( fall2015Data( i ).FishParameters, 1 ), size( fall2015Data( i ).FishParameters, 2 ), 3 ] );
        rets = nan( [ size( fall2015Data( i ).FishParameters, 1 ), size( fall2015Data( i ).FishParameters, 2 ), 3 ] );
        
        % Loop through each day in the experiment
        for j = 1:3
            
            % Current bools
            curWTUBools = fall2015Data( 3*( i - 1 ) + j ).FishType( 1, : )&fall2015Data( 3*( i - 1 ) + j ).BoolsNonNaN;
            curWTFBools = fall2015Data( 3*( i - 1 ) + j ).FishType( 2, : )&fall2015Data( 3*( i - 1 ) + j ).BoolsNonNaN;
            curRetBools = fall2015Data( 3*( i - 1 ) + j ).FishType( 3, : )&fall2015Data( 3*( i - 1 ) + j ).BoolsNonNaN;
            
            % Current data
            wTU = fall2015Data( 3*( i - 1 ) + j ).FishParameters( :, curWTUBools );
            wTF = fall2015Data( 3*( i - 1 ) + j ).FishParameters( :, curWTFBools );
            ret = fall2015Data( 3*( i - 1 ) + j ).FishParameters( :, curRetBools );
            
            % Add current data to data array
            wTUs( :, 1:size(wTU,2), j ) = wTU;
            wTFs( :, 1:size(wTF,2), j ) = wTF;
            rets( :, 1:size(ret,2), j ) = ret;
            
        end
        
        % Plot the data looping through each parameter
        for j = 2:size( fall2015Data( i ).FishParameters, 1 )
            
            % Plot only wanted parameters
            if(whichPlot(j-1))
                
                % Make current figure
                % h = figure;
                % errorbar( nanmean( squeeze( wTUs( j, :, : ) ), 1 ), nanstd( squeeze( wTUs( j, :, : ) ), 1 )/3.3, 'Color', colorWheelBorder( 1, : ) ); hold on;
                % errorbar( nanmean( squeeze( wTFs( j, :, : ) ), 1 ), nanstd( squeeze( wTFs( j, :, : ) ), 1 )/3.3, 'Color', colorWheelBorder( 2, : ) );
                % errorbar( nanmean( squeeze( rets( j, :, : ) ), 1 ), nanstd( squeeze( rets( j, :, : ) ), 1 )/3.3, 'Color', colorWheelBorder( 3, : ) ); hold off;
                h = figure;
                set(gca, 'FontName', 'Arial')
                switch i
                    case 1
                        groupee = { 'WT', 'Ret', 'WT', 'Ret', 'WT', 'Ret' };
                        fishOrderedByDay = [wTUs( j, :, 1 ); rets( j, :, 1 );...
                                            wTUs( j, :, 2 ); rets( j, :, 2 );...
                                            wTUs( j, :, 3 ); rets( j, :, 3 )];
                        colorWheelO = colorWheelBorder( [ 1, 3 ], : );
                        colorWheelF = colorWheelFill( [ 1, 3 ], : );
                        scatterBox( fishOrderedByDay', {groupee, colorWheelO, colorWheelF});
                    case 2
                        groupee = { 'WT', 'Ret', 'WT', 'Ret', 'WT', 'Ret' };
                        fishOrderedByDay = [wTUs( j, :, 1 ); rets( j, :, 1 );...
                                            wTUs( j, :, 2 ); rets( j, :, 2 );...
                                            wTUs( j, :, 3 ); rets( j, :, 3 )];
                        colorWheelO = colorWheelBorder( [ 1, 3 ], : );
                        colorWheelF = colorWheelFill( [ 1, 3 ], : );
                        scatterBox( fishOrderedByDay', {groupee, colorWheelO, colorWheelF});
                        axis auto;
                        if(j==2)
                            ylim([ampYMin, ampYMax]);
                        elseif(j==3)
                            ylim([freqYMin, freqYMax]);
                        end
%                         % Determine the title, y axis (the indices in the title are opaque, I know)
%                         theTitle = fall2015Data( 2*(i-1)^2 + 1 ).Title;
%                         theTitle = theTitle(1:10);
%                         switch j
%                             case 2 % Amplitude
%                                 title( strcat( {'Amplitude '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                                 ylabel( 'Wave Amplitude (px/frame)', 'FontSize', 20 );
%                             case 3 % Frequency
%                                 title( strcat( {'Frequency '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                                 ylabel( 'Wave Frequency (min^-1)', 'FontSize', 20 );
%                             case 4 % Wave Speed
%                                 title( strcat( {'Inverse Wave Speed '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                                 ylabel( 'Inverse Wave Speed (s/\mum)', 'FontSize', 20 );
%                             case 5 % Wave Speed Variability
%                                 title( strcat( {'Wave Speed Variance '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                                 ylabel( 'Wave Variance (um/s)', 'FontSize', 20 );
%                             case 6 % Wave Duration
%                                 title( strcat( {'Wave Duration '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                                 ylabel( 'Wave Duration (s)', 'FontSize', 20 );
%                             otherwise % New plot?
%                         end
                        
                        % Make larger text
                        set(findall(h,'type','axes'),'fontsize',20, 'FontName', 'Arial',...
                            'TickDir', 'out','box','off');
                        xlim([0, 9]);
                        
                        h = figure;
                        set(gca, 'FontName', 'Arial')
                        groupee = { 'Unfed', 'Fed', 'Unfed', 'Fed', 'Unfed', 'Fed' };
                        fishOrderedByDay = [wTUs( j, :, 1 ); wTFs( j, :, 1 );...
                            wTUs( j, :, 2 ); wTFs( j, :, 2 );...
                            wTUs( j, :, 3 ); wTFs( j, :, 3 )];
                        colorWheelO = colorWheelBorder( [ 1, 2 ], : );
                        colorWheelF = colorWheelFill( [ 1, 2 ], : );
                        scatterBox( fishOrderedByDay', {groupee, colorWheelO, colorWheelF});
                        
                    case 3
                        groupee = { 'Unfed', 'Fed', 'Unfed', 'Fed', 'Unfed', 'Fed' };
                        fishOrderedByDay = [wTUs( j, :, 1 ); wTFs( j, :, 1 );...
                            wTUs( j, :, 2 ); wTFs( j, :, 2 );...
                            wTUs( j, :, 3 ); wTFs( j, :, 3 )];
                        colorWheelO = colorWheelBorder( [ 1, 2 ], : );
                        colorWheelF = colorWheelFill( [ 1, 2 ], : );
                        scatterBox( fishOrderedByDay', {groupee, colorWheelO, colorWheelF});
                end
                %                 groupee = { '5U', '5F', '5R', '6U', '6F', '6R', '7U', '7F', '7R' };
                %                 fishOrderedByDay = [wTUs( j, :, 1 ); wTFs( j, :, 1 ); rets( j, :, 1 );...
                %                     wTUs( j, :, 2 ); wTFs( j, :, 2 ); rets( j, :, 2 );...
                %                     wTUs( j, :, 3 ); wTFs( j, :, 3 ); rets( j, :, 3 )];
                %                 scatterBox( fishOrderedByDay', {groupee, colorWheel});
                
                axis auto;
                
                % Label x axis
                % xlabel( 'D.P.F.','FontSize', 20 );
                
%                 % Determine the title, y axis (the indices in the title are opaque, I know)
%                 theTitle = fall2015Data( 1 + 3*i - ( 2 - i )^2 ).Title;
%                 theTitle = theTitle(1:10);
%                 switch j
%                     case 2 % Amplitude
%                         title( strcat( {'Amplitude '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                         ylabel( 'Wave Amplitude (px/frame)', 'FontSize', 20 );
%                     case 3 % Frequency
%                         title( strcat( {'Frequency '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                         ylabel( 'Wave Frequency (min^-1)', 'FontSize', 20 );
%                     case 4 % Wave Speed
%                         title( strcat( {'Inverse Wave Speed '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                         ylabel( 'Inverse Wave Speed (s/\mum)', 'FontSize', 20 );
%                     case 5 % Wave Speed Variability
%                         title( strcat( {'Wave Speed Variance '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                         ylabel( 'Wave Variance (um/s)', 'FontSize', 20 );
%                     case 6 % Wave Duration
%                         title( strcat( {'Wave Duration '}, theTitle ), 'FontSize', 17, 'interpreter','none' );
%                         ylabel( 'Wave Duration (s)', 'FontSize', 20 );
%                     otherwise % New plot?
%                 end
                
                % Make larger text
                if(j==2)
                    ylim([ampYMin, ampYMax]);
                elseif(j==3)
                    ylim([freqYMin, freqYMax]);
                end
                set(findall(h,'type','axes'),'fontsize',20, 'FontName', 'Arial',...
                    'TickDir', 'out','box','off');
                xlim([0, 9]);
                
            end
            
        end
        
    end
end