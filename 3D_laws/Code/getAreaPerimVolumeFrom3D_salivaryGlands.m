clear all
close all

pathGlands = 'E:\Pedro\LimeSeg_Pipeline\data\Salivary gland\Wildtype\';
fileName = 'glandDividedInSurfaceRatios_AllUnrollFeatures.mat';
files = dir([pathGlands,'**\Results\' fileName]);
path2save='excelsExtractedDataGlands';
mkdir(path2save);
pixelWidthMicrons =0.6151657; %1 pixel is ~ 0.615 microns
resizeFactor = 2.5/pixelWidthMicrons;
nameSurfaces = {'apicalToBasal', 'basalToApical'};

SRs ={1:7,7:-1:1}; 

for kindSr = 1:2
    sr = SRs{kindSr};  

    totalMeanPerimCellsMicrons2 = zeros(size(files,1),7);
    totalStdPerimCellsMicrons2 = zeros(size(files,1),7);
    totalMeanPerimCellsMicrons = zeros(size(files,1),7);
    totalStdPerimCellsMicrons = zeros(size(files,1),7);
    totalMeanLateralAreaMicrons = zeros(size(files,1),7);
    totalStdLateralAreaMicrons = zeros(size(files,1),7);
    totalVarianceVolumeMicrons = zeros(size(files,1),7);
    totalMeanVolumeMicrons = zeros(size(files,1),7);

    parfor numFile = 1:size(files,1)
        a = load(fullfile(files(numFile).folder, fileName),'infoPerSurfaceRatio','neighboursOfAllSurfaces');
        infoPerSurfaceRatio = a.infoPerSurfaceRatio;
        neighboursOfAllSurfaces = a.neighboursOfAllSurfaces;
        b = load(fullfile(files(numFile).folder, 'valid_cells.mat'),'validCells','noValidCells');
        validCells = b.validCells;
        noValidCells = b.noValidCells;

        neighbours3D = neighboursOfAllSurfaces{1};
        totalCells = unique([validCells,noValidCells]);
        volumeCellsSR = zeros(length(totalCells),7);
        areaCellsSR = zeros(length(totalCells),7);
        lateralAreaCellsSR = zeros(length(totalCells),7);
        perimCellsSR = zeros(length(totalCells),7);
        
        image3dOriginal = infoPerSurfaceRatio.Image3DWithVolumen{7};
        for nSR = sr   
            image3d = infoPerSurfaceRatio.Image3DWithVolumen{nSR};
            layerBasal3d = infoPerSurfaceRatio.Layer3D{nSR};
            neighboursSR = neighboursOfAllSurfaces{nSR};
            neighbours3D = cellfun(@(x,y) unique([x;y]),neighbours3D,neighboursSR,'UniformOutput',false);

            if kindSr==2 
                if nSR==7
                    image3d = layerBasal3d;
                else
                    image3d = image3dOriginal - image3d;
                    image3d(layerBasal3d>0)= layerBasal3d(layerBasal3d>0);
                end
            end
            
            if (nSR>1 && kindSr==1) || (nSR<7 && kindSr==2)
                if kindSr==1
                    volumeCellsSR(:,nSR) = table2array(regionprops3(image3d,'Volume'));
                else
                    volumeCellsSR(:,nSR) = table2array(regionprops3(image3d,'Volume'));
                end
            end
            areaCellsSR(:,nSR) = table2array(regionprops3(layerBasal3d,'Volume'));

            lateralLayer = zeros(size(image3d));
            perimLayer  = zeros(size(image3d));
            for nCell=1:length(totalCells)
                perimLateralCell = bwperim(image3d==totalCells(nCell),26);
                lateralLayer(perimLateralCell)=totalCells(nCell);

                neighsCell = neighboursSR{totalCells(nCell)};
                dilatedImgNeighbours = imdilate(ismember(layerBasal3d,neighsCell),strel('sphere',2));
                layerBasal3dCell = layerBasal3d==totalCells(nCell);
                perimLayer(layerBasal3dCell & dilatedImgNeighbours)=totalCells(nCell);

                if (nSR>1 && kindSr==1) || (nSR<7 && kindSr==2)
                    lateralLayer(apicalLayer==totalCells(nCell))=0;
                    lateralLayer(layerBasal3d==totalCells(nCell))=0;
                end
            end
            if (nSR==1 && kindSr==1) || (nSR==7 && kindSr==2)
                apicalLayer = layerBasal3d;
            else
                lateralAreaCellsSR(:,nSR)=table2array(regionprops3(lateralLayer,'Volume'));
            end
            perimCellsSR(:,nSR)=table2array(regionprops3(perimLayer,'Volume'));
        end

        totalMeanPerimCellsMicrons2(numFile,:) = mean((perimCellsSR(validCells,:).*resizeFactor.*pixelWidthMicrons).^2);
        totalStdPerimCellsMicrons2(numFile,:) = std((perimCellsSR(validCells,:).*resizeFactor.*pixelWidthMicrons).^2);
        totalMeanPerimCellsMicrons(numFile,:) = mean((perimCellsSR(validCells,:).*resizeFactor.*pixelWidthMicrons));
        totalStdPerimCellsMicrons(numFile,:) = std((perimCellsSR(validCells,:).*resizeFactor.*pixelWidthMicrons));
        totalMeanLateralAreaMicrons(numFile,:) = mean(lateralAreaCellsSR(validCells,:).*(resizeFactor^2).*(pixelWidthMicrons^2));
        totalStdLateralAreaMicrons(numFile,:) = std(lateralAreaCellsSR(validCells,:).*(resizeFactor^2).*(pixelWidthMicrons^2));
        totalMeanVolumeMicrons(numFile,:) = mean(volumeCellsSR(validCells,:).*(resizeFactor^3).*(pixelWidthMicrons^3));
        totalVarianceVolumeMicrons(numFile,:) = std(volumeCellsSR(validCells,:).*(resizeFactor^3).*(pixelWidthMicrons^3)).^2;

    end

    pathIntercalationsGlands = 'E:\Pedro\LimeSeg_Pipeline\Results\salivaryGland_Info_20_05_2019.mat';
    load(pathIntercalationsGlands,'mean_apicoBasalTransitionsPerGland')
    meanIntercalations3_5=cellfun(@(x) x(1:7), mean_apicoBasalTransitionsPerGland, 'UniformOutput', false);
    glandsIntercalations = vertcat(meanIntercalations3_5{:});
    
    clearvars -except nameSurfaces kindSr glandsIntercalations totalMeanPerimCellsMicrons2 totalStdPerimCellsMicrons2 totalMeanPerimCellsMicrons totalStdPerimCellsMicrons totalMeanLateralAreaMicrons totalStdLateralAreaMicrons totalMeanVolumeMicrons totalVarianceVolumeMicrons

    if kindSr==2
        totalMeanPerimCellsMicrons2 = totalMeanPerimCellsMicrons2(:,end:-1:1);
        totalStdPerimCellsMicrons2 = totalStdPerimCellsMicrons2(:,end:-1:1);
        totalMeanPerimCellsMicrons = totalMeanPerimCellsMicrons(:,end:-1:1);
        totalStdPerimCellsMicrons = totalStdPerimCellsMicrons(:,end:-1:1);
        totalMeanLateralAreaMicrons = totalMeanLateralAreaMicrons(:,end:-1:1);
        totalStdLateralAreaMicrons = totalStdLateralAreaMicrons(:,end:-1:1);
        totalMeanVolumeMicrons = totalMeanVolumeMicrons(:,end:-1:1);
        totalVarianceVolumeMicrons = totalVarianceVolumeMicrons(:,end:-1:1);
    end
    save(['salivaryGlands_GeometricalData_' nameSurfaces{kindSr} '.mat'],'totalMeanPerimCellsMicrons2','totalStdPerimCellsMicrons2','totalMeanPerimCellsMicrons','totalStdPerimCellsMicrons','totalMeanLateralAreaMicrons','totalStdLateralAreaMicrons','totalMeanVolumeMicrons','totalVarianceVolumeMicrons');

end