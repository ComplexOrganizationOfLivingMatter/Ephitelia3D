function [ dataEnergy,dataEnergyFilterByAngle ] = getEnergyFromAllMotifs(L_basal,noValidCells,totalPairs,vertices,borderCellsBasal,arrayValidVerticesBorderLeftBasal,arrayValidVerticesBorderRightBasal)
%GETENERGYFROMALLMOTIFS get the energy of all motifs without discriminate
%between transition or not
    [~,W]=size(L_basal);

    %all vertices in basal
    verticesPerCell=arrayfun(@(x) find(sum(x==vertices.verticesConnectCells,2)), 1:max(max(L_basal)), 'UniformOutput', false);
       
    %vertices of edges transition in basal
    verticesOfEdges=arrayfun(@(x,y) intersect(verticesPerCell{x},verticesPerCell{y}), totalPairs(:,1),totalPairs(:,2),'UniformOutput',false);
    fourCellsMotifs=cellfun(@(x) unique(horzcat(vertices.verticesConnectCells(x,:))),verticesOfEdges, 'UniformOutput', false);
    validPairs1=cell2mat(cellfun(@(x) isempty(intersect(noValidCells,x)) & length(x)==4 ,fourCellsMotifs,'UniformOutput',false));
    fourCellsMotifsValidCells=fourCellsMotifs(validPairs1,:);
    pairCellValidCells=totalPairs(validPairs1,:);
    cellsInMotifContactingCellsEdge=arrayfun(@(x) setdiff(fourCellsMotifsValidCells{x},pairCellValidCells(x,:))',1:size(pairCellValidCells,1), 'UniformOutput', false);
    
    %deleting incoherences with motif of 5 or 3 cells
    validPairs2=cell2mat(cellfun(@(x) length(x)==2,cellsInMotifContactingCellsEdge,'UniformOutput',false))';
    cellsInMotifContactingCellsEdge=cell2mat(cellsInMotifContactingCellsEdge(validPairs2)');
    pairCellValidCells=pairCellValidCells(validPairs2,:);
    
    %testing transition data
    dataEnergy.fourCellsMotif=[pairCellValidCells,cellsInMotifContactingCellsEdge];
    dataEnergyFilterByAngle.fourCellsMotif=[pairCellValidCells,cellsInMotifContactingCellsEdge];
    
    %calculation of energy
    [dataEnergy.EdgeLength,dataEnergy.SumEdgesOfEnergy,dataEnergy.EdgeAngle,dataEnergy.H1,dataEnergy.H2,dataEnergy.W1,dataEnergy.W2,notEmptyIndexes]=capturingWidthHeightAndEnergy(verticesPerCell,vertices,pairCellValidCells,cellsInMotifContactingCellsEdge,W,borderCellsBasal,arrayValidVerticesBorderLeftBasal,arrayValidVerticesBorderRightBasal);
    
     %calculation of energy filtered by angle
    [dataEnergyFilterByAngle.EdgeLength,dataEnergyFilterByAngle.SumEdgesOfEnergy,dataEnergyFilterByAngle.EdgeAngle,dataEnergyFilterByAngle.H1,dataEnergyFilterByAngle.H2,dataEnergyFilterByAngle.W1,dataEnergyFilterByAngle.W2,notEmptyIndexesFilterByAngle]=capturingWidthHeightAndEnergyFilteringAnglesOfMotifs(verticesPerCell,vertices,pairCellValidCells,cellsInMotifContactingCellsEdge,W,borderCellsBasal,arrayValidVerticesBorderLeftBasal,arrayValidVerticesBorderRightBasal);
    

end

