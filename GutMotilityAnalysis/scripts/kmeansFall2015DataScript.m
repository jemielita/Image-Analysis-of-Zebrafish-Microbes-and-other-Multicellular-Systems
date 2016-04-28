% assuming fall2015Data is loaded in workspace

%% Determine the appropriate number of clusters using silhouette method *RESULT k=2*
% Initialize variables
kMax = size( fall2015Data( 1 ).FishParameters, 1 ) - 1; % Chose number of known parameters as our kMax, - 1 for the way data is stored
idxVectSize = size( fall2015Data( 1 ).FishParameters, 2 );
idxMat = zeros( kMax - 1, idxVectSize ); % Going to loop through 1 to kMax clusters ( -1 from no k = 1 )
opts = statset('Display','final');
% numAnalyze = size( fall2015Data, 2 );
numAnalyze = 1;

% Loop through dates
for i = 1 : numAnalyze
    
    % Obtain current data set
    curData = fall2015Data(i).FishParameters( 2:end, : );
    normCurData = curData;
    
    % Normalize data. Use min-max scaling ( x - min )/( max - min ) (see http://www.medwelljournals.com/fulltext/?doi=ijscomp.2009.168.172)
    for j = 1 : size( curData, 1 )
        
        curMin = min( curData( j, : ) );
        curMax = max( curData( j, : ) );
        normCurData( j, : ) = ( curData( j, : ) - curMin )/( curMax - curMin );
        
    end
    
    % Loop through number of parameters
    for j = 2 : kMax
        
        [ idxMat( j - 1, : ), Centroids, sumDist, Dist ] = kmeans( normCurData', j, 'Distance', 'cityblock',...
                                                        'Replicates',5,'Options',opts);
        figure;
        [silh3, ~] = silhouette( normCurData', idxMat( j - 1, : ), 'cityblock');
        h = gca;
        h.Children.EdgeColor = [.8 .8 1];
        xlabel 'Silhouette Value';
        ylabel 'Cluster';
        
    end
    
end

%% Determine if data clusters predict fish type
% Initialize variables
nDates = size( fall2015Data, 2 );
opts = statset('Display','final');

% Loop through each data set
for i = 1 : nDates
    
    % Obtain current data set
    curData = fall2015Data(i).FishParameters( 2:end, : );
    normCurData = curData;
    curFishType = fall2015Data(i).FishType;
    % curFishNum = zeros( 1, size( curFishType, 2 ) ); % Finish later if useful
    
    % Normalize data. Use min-max scaling ( x - min )/( max - min ) (see http://www.medwelljournals.com/fulltext/?doi=ijscomp.2009.168.172)
    for j = 1 : size( curData, 1 )
        
        curMin = min( curData( j, : ) );
        curMax = max( curData( j, : ) );
        normCurData( j, : ) = ( curData( j, : ) - curMin )/( curMax - curMin );
        
    end
    
    [ idx, Centroids, sumDist, Dist ] = kmeans( normCurData', 2, 'Distance', 'cityblock',...
                                                        'Replicates',5,'Options',opts);
    
    
    rSizeTotal = sum( idx( curFishType( 1, : ) ) == 1 ) + sum( idx( curFishType( 1, : ) ) == 2 );
    fSizeTotal = sum( idx( curFishType( 2, : ) ) == 1 ) + sum( idx( curFishType( 2, : ) ) == 2 );
    uSizeTotal = sum( idx( curFishType( 3, : ) ) == 1 ) + sum( idx( curFishType( 3, : ) ) == 2 );
    
    r1 = sum( idx( curFishType( 1, : ) ) == 1 )/rSizeTotal;
    r2 = sum( idx( curFishType( 1, : ) ) == 2 )/rSizeTotal;
    f1 = sum( idx( curFishType( 2, : ) ) == 1 )/fSizeTotal;
    f2 = sum( idx( curFishType( 2, : ) ) == 2 )/fSizeTotal;
    u1 = sum( idx( curFishType( 3, : ) ) == 1 )/uSizeTotal;
    u2 = sum( idx( curFishType( 3, : ) ) == 2 )/uSizeTotal;
    sprintf( 'Exp # %i has: \n Ret = 1:%f , 2:%f \n WTF = 1:%f , 2:%f  \n WTU = 1:%f , 2:%f ', i, r1, r2, f1, f2, u1, u2 )
    
end