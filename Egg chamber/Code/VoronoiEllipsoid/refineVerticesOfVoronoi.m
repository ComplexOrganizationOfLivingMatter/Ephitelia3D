function [ ellipsoidInfo ] = refineVerticesOfVoronoi( ellipsoidInfo )
%REFINEVERTICESOFVORONOI Summary of this function goes here
%   Detailed explanation goes here

    xs = cellfun(@(x) x(:, 1), ellipsoidInfo.verticesPerCell, 'UniformOutput', false);
    ys = cellfun(@(x) x(:, 2), ellipsoidInfo.verticesPerCell, 'UniformOutput', false);
    zs = cellfun(@(x) x(:, 3), ellipsoidInfo.verticesPerCell, 'UniformOutput', false);
    allTheVertices = [vertcat(xs{:}), vertcat(ys{:}), vertcat(zs{:})];
    uniqueVertices = unique(allTheVertices, 'rows');
    %goodVertices = zeros(size(uniqueVertices, 1), 1);
    cellsUnifiedPerVertex = cell(size(uniqueVertices, 1), 1);
    for vertexIndex = 1:size(uniqueVertices, 1)
        %goodVertices(vertexIndex) = sum(cellfun(@(x) ismember(uniqueVertices(vertexIndex, :), x, 'rows'), ellipsoidInfo.verticesPerCell)) > 2;
        cellsUnifiedPerVertex(vertexIndex) = {find(cellfun(@(x) ismember(uniqueVertices(vertexIndex, :), x, 'rows'), ellipsoidInfo.verticesPerCell))};
    end

    totalNumberOfUniqueVertices = size(uniqueVertices, 1);
    refinedVertices = uniqueVertices;
    numberOfVertex = 1;
    removedVertices = zeros(1, 3);
    
    while numberOfVertex <= totalNumberOfUniqueVertices
        sequenceToSearch = 1:totalNumberOfUniqueVertices;
        sequenceToSearch(numberOfVertex == sequenceToSearch) = [];
        actualRefinedVertices = refinedVertices(sequenceToSearch, :);
        convergingCells = cellfun(@(x) all(ismember(cellsUnifiedPerVertex{numberOfVertex}, x)), cellsUnifiedPerVertex(sequenceToSearch));
        if (any(convergingCells))
            cellsUnifiedPerVertex(numberOfVertex) = [];
            removedVertices(end+1, :) = actualRefinedVertices(numberOfVertex, :);
            indicesOfConvergentCells = find(convergingCells);
            
            %Substitute vertex for the one that converget it
            for i = 1:size(ellipsoidInfo.verticesPerCell, 1)
                actualVerticesPerCell = ellipsoidInfo.verticesPerCell{i};
                foundVerticesToSubstitute = ismember(actualVerticesPerCell, actualRefinedVertices(numberOfVertex, :), 'rows');
                if any(foundVerticesToSubstitute)
                    actualVerticesPerCell(findfoundVerticesToSubstitute, :) = [];
                    actualVerticesPerCell(end+1, :) = actualRefinedVertices(indicesOfConvergentCells(1), :);
                    ellipsoidInfo.verticesPerCell{i} = actualVerticesPerCell;
                end
            end
            refinedVertices(numberOfVertex, :) = [];
            numberOfVertex = numberOfVertex - 1;
            totalNumberOfUniqueVertices = totalNumberOfUniqueVertices - 1;
        end
        numberOfVertex = numberOfVertex + 1;
    end
    %Removing the first item 0 0 0
    removedVertices (1, :) = [];
    
    ellipsoidInfo.removedVertices = removedVertices;
    ellipsoidInfo.vertices = refinedVertices;
    ellipsoidInfo.verticesConnectCells = cellsUnifiedPerVertex;
    ellipsoidInfo.verticesPerCell = cellfun(@(x) unique(x(ismember(x, refinedVertices, 'rows'), :), 'rows'), ellipsoidInfo.verticesPerCell, 'UniformOutput', false);
    figure('Visible', 'off');
    clmap = colorcube();
    ncl = size(clmap,1);

    for cellIndex = 1:size(ellipsoidInfo.verticesPerCell, 1)
        cl = clmap(mod(cellIndex,ncl)+1,:);
        VertCell = ellipsoidInfo.verticesPerCell{cellIndex};
        KVert = convhulln([VertCell; ellipsoidInfo.finalCentroids(cellIndex, :)]);
        patch('Vertices',[VertCell; ellipsoidInfo.finalCentroids(cellIndex, :)],'Faces', KVert,'FaceColor', cl ,'FaceAlpha', 1, 'EdgeColor', 'none')
        hold on;
    end
    plot3(removedVertices(:, 1), removedVertices(:, 2), removedVertices(:, 3),'Marker','.','MarkerEdgeColor','r','MarkerSize',10, 'LineStyle', 'none')
    axis equal
end

