function [samiraTableVoronoi] = createSamiraFormatExcel_delaunaySimulations(pathFile,surfaceRatios,hInit,wInit)

        
    addpath(genpath('lib'))
    pathSplitted = strsplit(pathFile, '\');
    nameOfSimulation = pathSplitted{end-1};

    %% Simulations
    
    load([pathSplitted{1} '\tubularCVT\Data\' pathSplitted{4} '\' nameOfSimulation '.mat'],'seeds')
                
    initialSeeds = seeds;

    nameSplitted = strsplit(nameOfSimulation, '_');
    samiraTableVoronoi = {};
    dir2save = strcat(strjoin(pathSplitted(1:end-2), '\'),'\verticesSamira\');
    if ~exist(dir2save,'dir')
        mkdir(dir2save)
    end
    for nSurfR = surfaceRatios
               
        %change seeds and dimensions using the surface ratio
        srSeeds = initialSeeds;
        srSeeds(:,2) = srSeeds(:,2)*nSurfR;
        wSR = wInit*nSurfR;

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
        noValidCells = unique([noValidCells;noValidCells+nSeeds;noValidCells+2*nSeeds]);
       
        triOfInterest = triOfInterest(vertIn,:);
        verticesTRI = verticesTRI(vertIn,:);
        
        indNoValCel = ismember(triOfInterest, noValidCells);
        pairNoValidCells = triOfInterest(sum(indNoValCel,2)==2,:);
        tripletNoValidCells = triOfInterest(sum(indNoValCel,2)==3,:);
        pairNoValidCells(~ismember(pairNoValidCells,noValidCells)) = 0;
        
        %subdivide triplet of no valid cells in pairs and delete extra
        %connections
        tripletNoValidCellsAux = tripletNoValidCells;
        for nTri =1 : size(tripletNoValidCells,1)
            
            triAux = tripletNoValidCells(nTri,:);
            triAux(triAux>nSeeds)= triAux(triAux>nSeeds) - nSeeds;
            triAux(triAux>nSeeds)= triAux(triAux>nSeeds) - nSeeds;
            triAux = [triAux; triAux + nSeeds; triAux + 2*nSeeds];
            
            a = sum(ismember(pairNoValidCells(:),triAux(:,1)));
            b = sum(ismember(pairNoValidCells(:),triAux(:,2)));
            c = sum(ismember(pairNoValidCells(:),triAux(:,3)));
            
            setSorting = [a,b,c];
            [~,indMin] = sort(setSorting);
            if setSorting(indMin(1)) == setSorting(indMin(2))
                sumInd1 = sum(ismember(tripletNoValidCellsAux(:),triAux(:,indMin(1))));
                sumInd2 = sum(ismember(tripletNoValidCellsAux(:),triAux(:,indMin(2))));
                
                if sumInd1 > sumInd2
                    indMin = [indMin(2),indMin(1),indMin(3)];
                end
                tripletNoValidCellsAux(sum(ismember(tripletNoValidCellsAux,[triAux(:,indMin(1)),triAux(:,indMin(2))]),2)==2,:)=[];
            end
            
            pairNoValidCells(sum(ismember(pairNoValidCells,[triAux(:,indMin(2)),triAux(:,indMin(3))]),2)==2,:)=[];
            pairNoValidCells = [pairNoValidCells;[tripletNoValidCells(nTri,indMin(1)),tripletNoValidCells(nTri,indMin(2)),0]];
            pairNoValidCells = [pairNoValidCells;[tripletNoValidCells(nTri,indMin(1)),tripletNoValidCells(nTri,indMin(3)),0]];
        end
        
        %delete extra non-valid cells due to combinations of triplets of
        %non-valid cells
        pairNoValidCellsVis = pairNoValidCells;
        pairNoValidCellsVis(pairNoValidCellsVis>nSeeds)= pairNoValidCellsVis(pairNoValidCellsVis>nSeeds) - nSeeds;
        pairNoValidCellsVis(pairNoValidCellsVis>nSeeds)= pairNoValidCellsVis(pairNoValidCellsVis>nSeeds) - nSeeds;
        
        uv = unique(pairNoValidCellsVis(:));
        uv = uv(2:end);
        n  = histc(pairNoValidCellsVis(:),uv);
        if any(n>2)
            pairs2delete = uv(n>2)';
            pairs2delete = [pairs2delete;pairs2delete+nSeeds;pairs2delete+2*nSeeds];
            pairNoValidCells(sum(ismember(pairNoValidCells,pairs2delete),2)==2,:)=[];
        end
        
        %relocate seeds close to the origin
        verticesTRI(:,2) = verticesTRI(:,2) - wSR;
        
        %relabel triangulations (border cells)
        triOfInterestRelabel = triOfInterest;
        triOfInterestRelabel(triOfInterestRelabel>nSeeds) = triOfInterestRelabel(triOfInterestRelabel>nSeeds) - nSeeds;
        triOfInterestRelabel(triOfInterestRelabel>nSeeds) = triOfInterestRelabel(triOfInterestRelabel>nSeeds) - nSeeds;
        
        %storing bulk vertices
        verticesInfo.verticesPerCell = verticesTRI;
        verticesInfo.verticesConnectCells = triOfInterestRelabel;
        
        %calculate no valid cells vertices
        verticesNoValidCellsInfo = getVerticesNoValidCellsDelaunay(pairNoValidCells,tripletSeeds,nSeeds,0,hInit,wSR);
        
        %Grouping cells
        cellWithVertices = groupingVerticesPerCellSurface(verticesInfo, verticesNoValidCellsInfo, [], 1, [],nSeeds,wSR);
        missingVertices = [];
        
        [samiraTableVoronoiActualSR, cellsVoronoi] = tableWithSamiraFormat(cellWithVertices, srSeeds, missingVertices, nSurfR, pathSplitted, nameOfSimulation);
        samiraTableVoronoi = [samiraTableVoronoi; samiraTableVoronoiActualSR];

        
        %save vertices simulations
        %Create frusta table 
        if nSurfR == 1
            samiraTableFrusta = samiraTableVoronoi(:,1:4);
            verticesSR1=samiraTableVoronoi(:,5);
            samiraTableFrustaSR = samiraTableVoronoi;
            samiraTableFrusta_SRColumn = cellfun(@(x) x*nSurfR,samiraTableFrusta(:,1),'UniformOutput',false);

        else
            samiraTableFrusta_SRColumn = cellfun(@(x) x*nSurfR,samiraTableFrusta(:,1),'UniformOutput',false);
            verticesSR_frusta = cellfun(@(x) [x(1:2:length(x)-1);x(2:2:length(x))*nSurfR],verticesSR1,'UniformOutput',false);
            verticesSR_frusta = cellfun(@(x) x(:)',verticesSR_frusta,'UniformOutput',false);
            cellsFrusta = [samiraTableFrusta_SRColumn,samiraTableFrusta(:,2:4),verticesSR_frusta];
            samiraTableFrustaSR =  [samiraTableFrustaSR;cellsFrusta];
            
            %Plot frusta
            plotVerticesPerSurfaceRatio(cellsFrusta,[],dir2save,nameSplitted,'Frusta',nSurfR)

        end

    end
    
    samiraTableVoronoiT = cell2table(samiraTableVoronoi, 'VariableNames',{'Radius', 'CellIDs', 'TipCells', 'BorderCell','verticesValues_x_y'});
    samiraTableFrustaT = cell2table(samiraTableFrustaSR, 'VariableNames',{'Radius', 'CellIDs', 'TipCells', 'BorderCell','verticesValues_x_y'});

    writetable(samiraTableVoronoiT, strcat(dir2save, '\Voronoi_realization', nameSplitted{2} ,'_samirasFormat_', date, '.xls'));
    writetable(samiraTableFrustaT, strcat(dir2save, '\Frusta_realization', nameSplitted{2} ,'_samirasFormat_', date, '.xls'));


    
end

