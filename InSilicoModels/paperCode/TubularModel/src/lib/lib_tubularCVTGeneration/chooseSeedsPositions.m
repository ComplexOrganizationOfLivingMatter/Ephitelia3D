function [seeds] = chooseSeedsPositions(imin,H,W,n_seeds,length,indexImage,folder1)
%CHOOSESEEDSPOSITIONS select the coordinates where Voronoi seeds are going
%to be placed in a random way and without overlapping


% Resolve K random values between imin and imax
if ((H-(imin-1))*(W-(imin-1)) < n_seeds)
    fprintf(' Error: out of range\n');
    seeds = NaN;
    return
end

seeds(1,1) = randi([imin,H],1);
seeds(1,2) = randi([imin,W],1);

n=1;

while (n<=n_seeds-1)

    a = randi([imin,H],1);
    b = randi([imin,W],1);
    dato=[a,b];

    for i=1:size(seeds,1)
        distance=sqrt(((seeds(i,1)-a)^2)+((seeds(i,2)-b)^2));
    
        if distance<=length
            ind(i)=1;
        else
            ind(i)=0;
        end
    end

    if sum(ind)==0
        dato=[a,b];
        seeds = [seeds; dato];
        n=n+1;
    end

end

seeds = seeds(1:end,:);
path2save=[folder1 'Seeds\' num2str(n_seeds)  'seeds\'];
if ~isdir(path2save)
    mkdir(path2save)
end

save([path2save 'Image_' num2str(indexImage) '_' num2str(H) 'x' num2str(W) '_' num2str(n_seeds) '_seeds.mat'],'seeds')
    