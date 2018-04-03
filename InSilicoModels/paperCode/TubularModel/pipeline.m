addpath(genpath('src'))

%% Defining initial parameters
N_images=20;%total number of different initial images
N_frames=20;%number of Lloyds iterations
% H=1024;W=512;%height and width of image
%number of seeds for generation of voronoi cells
distanceBetwSeeds=5;%minimum distances between seeds, avoiding overlaping
%type of surface projections in proportion with the initial image

apicalReductions=1:-0.1:0.1;
% apicalReductions=apicalReductions(apicalReductions~=0.6);
% apicalReductions=[1 0.6];
setOfSeeds=[10 20 50 100 200 400]*4;
% setOfSeeds=[50 100 200]*4;

setOfSeeds=200;

H=1024;W=512;
% basalExpansions=[1 20/3];
basalExpansions= 1./apicalReductions;
apicalReductions=[];

% counter=1;
% while counter <= length(setOfSeeds)
    
for i=1:length(setOfSeeds)
        
        n_seeds=setOfSeeds(i);
%     flag=0;
%     while flag<1
         try 
            % 1 - Generation of tubular CVT from random seeds
%              mainTubularCVTGenerator(N_images,N_frames,H,W,n_seeds,distanceBetwSeeds)

            %% 2 - Projection of Voronoi seeds to another cylindrical surface and generation of Voronoi cells
            %the next main, also carry out the measurements of edge length, edge angles and scutoids
            %presence
             mainTubularVoronoiModelProjectionSurface(n_seeds,basalExpansions,apicalReductions,N_images,H,W)

            %% 3 - Generation of all frusta cylinder (control tubular model) by projection of cell vertices
            mainTubularControlModelProjectionSurface(n_seeds,basalExpansions,apicalReductions,N_images,H,W)
%             flag=1;

        catch ME
            disp(['error in number of seeds: ' num2str(n_seeds)])
            disp(ME.stack(1).name)
            disp(ME.stack(1).line)

%             flag=0;
        end
%     end


end




