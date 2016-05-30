%% make sholl analysis from skel filament statistic
% this is a stand alone version to create sholl analysis of filaments 
% it will later be incorporated into ABFilamentStats2ML.m

%% get dir
TPN  = GetMyDir;

%% load the skel file
load([TPN 'Skel.mat'])

%% draw lines between all edges in 3D
xyum = .147; % have to get the real xyum from the stats later
zum = 1;

vSizeY = round(max(Skel.FilStats.aXYZ(:,2))/xyum);
vSizeX = round(max(Skel.FilStats.aXYZ(:,1))/xyum);
vSizeZ = round(max(Skel.FilStats.aXYZ(:,3))/zum);

skelCube = zeros([vSizeY,vSizeX,vSizeZ], 'logical'); % making a 3d cube to hold the skeleton filament
% get the lengths of each segment
slopes = Skel.FilStats.aXYZ(Skel.FilStats.aEdges(:,2),:)-Skel.FilStats.aXYZ(Skel.FilStats.aEdges(:,1));
lengths = sqrt(slopes(:,1).^2 + slopes(:,2).^2 + slopes(:,3).^2); %calculate the length between segment nodes

% index into the edges to map the lines between each edge

for ii = 1:length(Skel.FilStats.aEdges)
    divisionNum = length([0:0.1:lengths(ii)]); % if lengths are ~1um then the steps will be .1
    stepInc = slopes(ii,:)./divisions; % set the size of steps between the points
    for jj = 1:divisionNum
        iterativeSteps = skelCube([vSizeY,vSizeX,vSizeZ],
        
    
    
end
skelCube(sub2ind(size(skelCube), skelYXZpixels(:,1),skelYXZpixels(:,2),skelYXZpixels(:,3))) = 1; 
colormap bone
imagesc(max(skelCube,[],3))
axis image
