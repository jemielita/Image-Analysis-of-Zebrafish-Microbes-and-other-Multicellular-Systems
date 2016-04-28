% Script which takes a fish data matrix from analysisCollectionScript.m and performs a kmeans clustering algorithm
% Assumes data is called paramsAmpWidFreqPeriodSpeedSsresidbynR2FN

% Initialize
opts = statset('Display','final');

% Subset data into the 5 parameters
kmeansData = paramsAmpWidFreqPeriodSpeedSsresidbynR2FN( :, 1:5 );
normKmeansData = kmeansData;

% Normalize data. Use min-max scaling ( x - min )/( max - min ) (see http://www.medwelljournals.com/fulltext/?doi=ijscomp.2009.168.172)
for i = 1 : size( kmeansData, 2 )
    
    curMin = min( kmeansData( :, i ) );
    curMax = max( kmeansData( :, i ) );
    normKmeansData( :, i ) = ( kmeansData( :, i ) - curMin )/( curMax - curMin );
    
end

% Actual kmeans
[ idx, Centroids, sumDist, Dist ] = kmeans( normKmeansData, 2, 'Distance', 'cityblock',...
                                                        'Replicates',5,'Options',opts);

%% How did it cluster?
O1 = sum( idx( mod( paramsAmpWidFreqPeriodSpeedSsresidbynR2FN( :, 7 ), 2 ) == 1 ) == 1 );
O2 = sum( idx( mod( paramsAmpWidFreqPeriodSpeedSsresidbynR2FN( :, 7 ), 2 ) == 1 ) == 2 );
T1 = sum( idx( mod( paramsAmpWidFreqPeriodSpeedSsresidbynR2FN( :, 7 ), 2 ) == 0 ) == 1 );
T2 = sum( idx( mod( paramsAmpWidFreqPeriodSpeedSsresidbynR2FN( :, 7 ), 2 ) == 0 ) == 2 );