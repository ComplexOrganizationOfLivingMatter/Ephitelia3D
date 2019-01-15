function [neighbours_UnrollTube, polygon_distribution_UnrollTube, polygon_distribution_UnrollTubeApical, polygon_distribution_UnrollTubeBasal] = unrollTube_parallel(selpath)
%UNROLLTUBE_PARALLEL Summary of this function goes here
%   Detailed explanation goes here
    
    load(fullfile(selpath, '3d_layers_info.mat'), 'apicalLayer', 'basalLayer', 'colours', 'glandOrientation', 'lumenImage');
    load(fullfile(selpath, 'valid_cells.mat'), 'validCells', 'noValidCells');
    resizeImg = 0.25;
    imgSize = round(size(apicalLayer)/resizeImg);
    apicalLayerGoodOrientation = imrotate(imresize3(apicalLayer, imgSize, 'nearest'), glandOrientation);
    clearvars apicalLayer
    basalLayerGoodOrientation = imrotate(imresize3(basalLayer, imgSize, 'nearest'), glandOrientation);
    clearvars basalLayer
    lumenImageGoodOrientation = imrotate(imresize3(double(lumenImage), imgSize, 'nearest'), glandOrientation)>0;
    clearvars lumenImage
    apicalAreaValidCells = 100;
    disp('Apical');
    [neighs_apical,side_cells_apical, apicalAreaValidCells] = unrollTube(apicalLayerGoodOrientation, fullfile(selpath, 'apical'), noValidCells, colours, lumenImageGoodOrientation);
    
    disp('Basal');
    [neighs_basal,side_cells_basal] = unrollTube(basalLayerGoodOrientation, fullfile(selpath, 'basal'), noValidCells, colours, [], apicalAreaValidCells);

    missingCellsUnroll = find(side_cells_basal<3 | side_cells_apical<3);
    if isempty(missingCellsUnroll) == 0
        msgbox(strcat('CARE!! Missing (or ill formed) cells at unrolltube: ', strjoin(arrayfun(@num2str, missingCellsUnroll, 'UniformOutput', false), ', ')))
    end

    [polygon_distribution_UnrollTubeApical] = calculate_polygon_distribution(side_cells_apical, validCells);
    [polygon_distribution_UnrollTubeBasal] = calculate_polygon_distribution(side_cells_basal, validCells);
    neighbours_UnrollTube = table(neighs_apical, neighs_basal);
    polygon_distribution_UnrollTube = table(polygon_distribution_UnrollTubeApical,polygon_distribution_UnrollTubeBasal);
    neighbours_UnrollTube.Properties.VariableNames = {'Apical','Basal'};
    polygon_distribution_UnrollTube.Properties.VariableNames = {'Apical','Basal'};
end
