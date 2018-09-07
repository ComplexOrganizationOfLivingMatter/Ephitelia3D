function [] = paint3D(labelledImage, showingCells)
%PAINT3D Summary of this function goes here
%   Detailed explanation goes here

    colours = colorcube(max(labelledImage(:)));
    colours = colours(randperm(max(labelledImage(:))), :);
    if exist('showingCells', 'var') == 0
        showingCells = 1:max(labelledImage(:));
    end
    % figure;
    for numSeed = showingCells
        % Painting each cell
        [x,y,z] = ind2sub(size(labelledImage),find(labelledImage == numSeed));
        pcshow([x,y,z], colours(numSeed, :));
        hold on;
    end
end

