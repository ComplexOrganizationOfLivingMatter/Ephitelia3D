function delaunayEuler3DPredefinedSeeds(wInit,hInit,numSeeds,numRand,setVoronoi,surfaceRatios)
%delaunay - euler 3d
    
    cellTableFittingEulerLogApiToBas = cell(length(setVoronoi));
    cellTableFittingEulerPiecewiseApiToBas = cell(length(setVoronoi));
    cellTableFittingEulerLogisticApiToBas = cell(length(setVoronoi));
    
    cellTableFittingEulerLogBasToApi = cell(length(setVoronoi));
    cellTableFittingEulerPiecewiseBasToApi = cell(length(setVoronoi));
    cellTableFittingEulerLogisticBasToApi = cell(length(setVoronoi));
    

    for nVoronoi = 1:length(setVoronoi)

        numAverageNeighsAccumApiToBasal = zeros(numRand,length(surfaceRatios));
        numAverageNeighsAccumBasToApical= zeros(numRand,length(surfaceRatios));
        numNeighSurface = zeros(numRand,length(surfaceRatios));
        numWonNeighsAccumApicalToBasal = cell(numRand,length(surfaceRatios));
        numLostNeighsAccumApicalToBasal = cell(numRand,length(surfaceRatios));
        numTransitionsApicalToBasal = cell(numRand,length(surfaceRatios));
        percentageScutoidsApicalToBasal = zeros(numRand,length(surfaceRatios));
        numWonNeighsAccumBasalToApical = cell(numRand,length(surfaceRatios));
        numLostNeighsAccumBasalToApical = cell(numRand,length(surfaceRatios));
        numTransitionsBasalToApical = cell(numRand,length(surfaceRatios));
        percentageScutoidsBasalToApical = zeros(numRand,length(surfaceRatios));
        
        polyDisTotal = cell(numRand,length(surfaceRatios));
        
        neighsAccumApicalToBasal=cell(numRand,length(surfaceRatios));
        neighsAccumBasalToApical=cell(numRand,length(surfaceRatios));

        folderName = ['..\..\3D_laws\delaunayData\Voronoi ' num2str(setVoronoi(nVoronoi)) '\'];
        %fileName = ['delaunayCyl_Voronoi' num2str(nVoronoi) '_' num2str(numSeeds) 'seeds_sr' num2str(max(surfaceRatios)) '_' date '.mat'];
        fileName = ['delaunayCyl_Voronoi' num2str(setVoronoi(nVoronoi)) '_' num2str(numSeeds) 'seeds_sr' num2str(max(surfaceRatios)) '_29-Nov-2019.mat'];
        
        mkdir(folderName)
        path2save = [folderName fileName];
        if ~exist(path2save,'file')
            
            for nRand = 1:numRand
 
                load(['data\tubularCVT\Data\' num2str(wInit) 'x' num2str(hInit) '_' num2str(numSeeds) 'seeds\Image_' num2str(nRand) '_Diagram_' num2str(setVoronoi(nVoronoi)) '.mat'],'seeds')
                
                %init neighsAccum
                nNeighPerSR = zeros(1,length(surfaceRatios));
                euler2D = zeros(1,length(surfaceRatios));
                
                validCellsSR = cell(length(surfaceRatios),1);
                neighsPerSR = cell(length(surfaceRatios),1);
                sidesCells = cell(length(surfaceRatios),1);
                triPerSR = cell(length(surfaceRatios),1);
                noValidCellsSR = cell(length(surfaceRatios),1);
                
                
                for nSR = 1:length(surfaceRatios)
                    srSeeds = seeds;
                    %change seeds and dimensions using the surface ratio
                    srSeeds(:,2) = srSeeds(:,2)*surfaceRatios(nSR);
                    wSR = wInit*surfaceRatios(nSR);
                    nSeeds = size(srSeeds,1);

                    %Triplet the number of seeds
                    tripletSeeds = [srSeeds;srSeeds(:,1), srSeeds(:,2)+wSR;srSeeds(:,1), srSeeds(:,2)+2*wSR];

                    %% delaunay triangulation
                    DT = delaunayTriangulation(tripletSeeds);
                    %triplets of neighbours cells
                    triOfInterest = DT.ConnectivityList;
                    %get vertices position using the triangle circumcenter
                    verticesTRI = DT.circumcenter; 

                    %delete vertices out of the image region 2 avoid repeatition in
                    %border cells
                    indVertOut = verticesTRI(:,2)>2*wSR | verticesTRI(:,2)<=wSR;
                    verticesTRI(indVertOut,:) = [];
                    triOfInterest(indVertOut,:) = [];   

                    %delete triangulations and vertices out of limits
                    vertIn = [verticesTRI(:,1) <= hInit] & [verticesTRI(:,1) > 0];

                    noValidCells = unique(triOfInterest(~vertIn,:));
                    noValidCells(noValidCells>nSeeds) = noValidCells(noValidCells>nSeeds) -nSeeds;
                    noValidCells(noValidCells>nSeeds) = noValidCells(noValidCells>nSeeds) -nSeeds;
                    noValidCells = unique(noValidCells);
       
                    triOfInterest = triOfInterest(vertIn,:);
                    
                    %relabel triangulations (border cells)
                    triOfInterestRelabel = triOfInterest;
                    triOfInterestRelabel(triOfInterestRelabel>nSeeds) = triOfInterestRelabel(triOfInterestRelabel>nSeeds) - nSeeds;
                    triOfInterestRelabel(triOfInterestRelabel>nSeeds) = triOfInterestRelabel(triOfInterestRelabel>nSeeds) - nSeeds;
        
                    triPerSR{nSR} = unique(sort(triOfInterestRelabel,2),'rows');
                    [neighsPerSR{nSR},sidesCells{nSR}]=calculateNeighboursDelaunay(triOfInterestRelabel);
                    noValidCellsSR{nSR} = noValidCells;
      
                end
                
                noValidCellsTotal = unique(vertcat(noValidCellsSR{:}));
                validCells = setxor([1:nSeeds],noValidCellsTotal);
                neighsPerSR_ValidCells = cellfun(@(x) x(validCells), neighsPerSR,'UniformOutput',false);
                               
                for nSR = 1:length(surfaceRatios)    
                    [polyDisImg] = calculate_polygon_distribution( sidesCells{nSR}, validCells );
                    polyDisTotal{nRand,nSR}=polyDisImg(2,:);

                    if nSR==1
                        neighsAccumApicalToBasal{nRand,nSR} = neighsPerSR_ValidCells{nSR};
                        numLostNeighsAccumApicalToBasal{nRand,nSR} = cell(size(neighsPerSR_ValidCells{nSR}));
                        numWonNeighsAccumApicalToBasal{nRand,nSR} = cell(size(neighsPerSR_ValidCells{nSR}));
                    else
                        neighsAccumApicalToBasal{nRand,nSR} = cellfun(@(x,y) unique([[x(:)];[y(:)]]),neighsPerSR_ValidCells{nSR},neighsAccumApicalToBasal{nRand,nSR-1},'UniformOutput',false);

                        lostNeigh = cellfun(@(x,y) setdiff(x(:),y(:)),neighsPerSR_ValidCells{nSR-1},neighsPerSR_ValidCells{nSR},'UniformOutput',false);
                        wonNeigh = cellfun(@(x,y) setdiff(y(:),x(:)),neighsPerSR_ValidCells{nSR-1},neighsPerSR_ValidCells{nSR},'UniformOutput',false);

                        numLostNeighsAccumApicalToBasal{nRand,nSR} = cellfun(@(x,y) unique([[x(:)];[y(:)]]),lostNeigh,numLostNeighsAccumApicalToBasal{nRand,nSR-1},'UniformOutput',false);
                        numWonNeighsAccumApicalToBasal{nRand,nSR} = cellfun(@(x,y) unique([[x(:)];[y(:)]]),wonNeigh,numWonNeighsAccumApicalToBasal{nRand,nSR-1},'UniformOutput',false);

                        numTransitionsApicalToBasal{nRand,nSR} = cellfun(@(x,y) length(([x;y])),numLostNeighsAccumApicalToBasal{nRand,nSR},numWonNeighsAccumApicalToBasal{nRand,nSR});     
                        percentageScutoidsApicalToBasal(nRand,nSR) = sum(arrayfun(@(x) sum(x)>0,numTransitionsApicalToBasal{nRand,nSR}))/length(validCells);

                    end
                    nNeighPerSR(nSR) = mean(cellfun(@length,neighsAccumApicalToBasal{nRand,nSR}));
                    euler2D(nSR) = mean(cellfun(@length,neighsPerSR_ValidCells{nSR}));
                end
                numAverageNeighsAccumApiToBasal(nRand,:) = nNeighPerSR;
                numNeighSurface(nRand,:) = euler2D;
            

                for nSR = length(surfaceRatios):-1:1
                    if nSR==length(surfaceRatios)
                        neighsAccumBasalToApical{nRand,nSR} = neighsPerSR_ValidCells{nSR};
                        numLostNeighsAccumBasalToApical{nRand,nSR} = cell(size(neighsPerSR_ValidCells{nSR}));
                        numWonNeighsAccumBasalToApical{nRand,nSR} = cell(size(neighsPerSR_ValidCells{nSR}));
                    else
                        neighsAccumBasalToApical{nRand,nSR} = cellfun(@(x,y) unique([[x(:)];[y(:)]]),neighsPerSR_ValidCells{nSR},neighsAccumBasalToApical{nRand,nSR+1},'UniformOutput',false);

                        lostNeigh = cellfun(@(x,y) setdiff(x,y),neighsPerSR_ValidCells{nSR+1},neighsPerSR_ValidCells{nSR},'UniformOutput',false);
                        wonNeigh = cellfun(@(x,y) setdiff(y,x),neighsPerSR_ValidCells{nSR+1},neighsPerSR_ValidCells{nSR},'UniformOutput',false);

                        numLostNeighsAccumBasalToApical{nRand,nSR} = cellfun(@(x,y) unique([[x(:)];[y(:)]]),lostNeigh,numLostNeighsAccumBasalToApical{nRand,nSR+1},'UniformOutput',false);
                        numWonNeighsAccumBasalToApical{nRand,nSR} = cellfun(@(x,y) unique([[x(:)];[y(:)]]),wonNeigh,numWonNeighsAccumBasalToApical{nRand,nSR+1},'UniformOutput',false);

                        numTransitionsBasalToApical{nRand,nSR} = cellfun(@(x,y) length(([x;y])),numLostNeighsAccumBasalToApical{nRand,nSR},numWonNeighsAccumBasalToApical{nRand,nSR});     
                        percentageScutoidsBasalToApical(nRand,nSR) = sum(arrayfun(@(x) sum(x)>0,numTransitionsBasalToApical{nRand,nSR}))/length(validCells);

                    end
                    nNeighPerSR(nSR) = mean(cellfun(@length,neighsAccumBasalToApical{nRand,nSR}));
                end
                numAverageNeighsAccumBasToApical(nRand,:) = nNeighPerSR;
            end
            averageTransitionsApiToBasal = cellfun(@mean, numTransitionsApicalToBasal);
            averageTransitionsBasToApical = cellfun(@mean, numTransitionsBasalToApical);

            tableSR = array2table(surfaceRatios,'RowNames',{'surfaceRatio'});
            tableNeighsAccumApiToBasal = array2table(numAverageNeighsAccumApiToBasal,'VariableNames',tableSR.Properties.VariableNames);
            tableEuler3D = [tableSR;tableNeighsAccumApiToBasal];
            neighsAccumApiToBasalFinalSR = neighsAccumApicalToBasal(:,end);
            neighsAccumBasToApicalFinalSR = neighsAccumBasalToApical(:,1);

            tableTotalResultsApiToBasal = [tableSR;array2table([mean(numAverageNeighsAccumApiToBasal);std(numAverageNeighsAccumApiToBasal);mean(averageTransitionsApiToBasal);std(averageTransitionsApiToBasal);mean(percentageScutoidsApicalToBasal);std(percentageScutoidsApicalToBasal)],'VariableNames',tableSR.Properties.VariableNames,'RowNames',{'meanNeighbours','stdNeighbours','meanTransitions','stdTransitions','meanScutoids','stdScutoids'})];
            tableTotalResultsBasToApical = [tableSR;array2table([mean(numAverageNeighsAccumBasToApical);std(numAverageNeighsAccumBasToApical);mean(averageTransitionsBasToApical);std(averageTransitionsBasToApical);mean(percentageScutoidsBasalToApical);std(percentageScutoidsBasalToApical)],'VariableNames',tableSR.Properties.VariableNames,'RowNames',{'meanNeighbours','stdNeighbours','meanTransitions','stdTransitions','meanScutoids','stdScutoids'})];
            
            save(path2save,'percentageScutoidsApicalToBasal','averageTransitionsApiToBasal','numTransitionsApicalToBasal','tableEuler3D','neighsAccumApicalToBasal','neighsAccumApiToBasalFinalSR','tableTotalResultsApiToBasal',...
                'numLostNeighsAccumApicalToBasal','numWonNeighsAccumApicalToBasal','numLostNeighsAccumBasalToApical','numWonNeighsAccumBasalToApical','percentageScutoidsBasalToApical',...
                'averageTransitionsBasToApical','numTransitionsBasalToApical','neighsAccumBasalToApical','neighsAccumBasToApicalFinalSR','tableTotalResultsBasToApical');
       else

            load(path2save,'tableTotalResultsApiToBasal','tableTotalResultsBasToApical','neighsAccumApicalToBasal','neighsAccumBasalToApical')
       end

       [cellTableFittingEulerLogApiToBas{nVoronoi}, cellTableFittingEulerPiecewiseApiToBas{nVoronoi}, cellTableFittingEulerLogisticApiToBas{nVoronoi}] = delaunayGraphics(folderName,tableTotalResultsApiToBasal,setVoronoi(nVoronoi),surfaceRatios,'FromApicalToBasal',neighsAccumApicalToBasal,numRand);
       %[cellTableFittingEulerLogBasToApi{nVoronoi},cellTableFittingEulerPiecewiseBasToApi{nVoronoi},cellTableFittingEulerLogisticBasToApi{nVoronoi}] = delaunayGraphics(folderName,tableTotalResultsBasToApical,setVoronoi(nVoronoi),surfaceRatios,'FromBasalToApical',neighsAccumBasalToApical,numRand);
    
       
    end
    cellTableFittingEulerLogApiToBas = vertcat(cellTableFittingEulerLogApiToBas{:});
    cellTableFittingEulerPiecewiseApiToBas = vertcat(cellTableFittingEulerPiecewiseApiToBas{:});
    cellTableFittingEulerLogisticApiToBas = vertcat(cellTableFittingEulerLogisticApiToBas{:});
    
    cellTableFittingEulerLogBasToApi = vertcat(cellTableFittingEulerLogBasToApi{:});
    cellTableFittingEulerPiecewiseBasToApi = vertcat(cellTableFittingEulerPiecewiseBasToApi{:});
    cellTableFittingEulerLogisticBasToApi = vertcat(cellTableFittingEulerLogisticBasToApi{:});
end

