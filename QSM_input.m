% Read the point cloud data from the .las file
lasReader = lasFileReader('Crateva_seg5m.las');
ptCloud = readPointCloud(lasReader);
P = ptCloud.Location;
P = P - mean(P);

% Define the input structure for QSM parameters
inputs.PatchDiam1 = 0.05; % Patch size of the first uniform-size cover (5 cm)
inputs.PatchDiam2Min = 0.01; % Minimum patch size of the second cover (1 cm)
inputs.PchDiam2Max = 0.04; % Maximum patch size of the second cover (4 cm)
inputs.BallRad1 = 0.065; % Ball radius for the first cover (6.5 cm)
inputs.BallRad2 = 0.05; % Ball radius for the second cover (5 cm)
inputs.nmin1 = 3; % Minimum number of points in BallRad1-balls
inputs.nmin2 = 1; % Minimum number of points in BallRad2-balls
inputs.OnlyTree = 1; % Point cloud contains points only from the tree
inputs.Tria = 1; % Produce a triangulation
inputs.Dist = 1; % Compute the point-model distances
inputs.MinCylRad = 0.01; % Minimum cylinder radius
inputs.ParentCor = 1; % Radii in a child branch are always smaller than the radii of the parent cylinder
inputs.TaperCor = 1; % Use parabola taper corrections
inputs.GrowthVolCor = 0; % Use growth volume (GV) correction
inputs.GrowthVolFac = 1; % fac-parameter of the GV-approach
% Filtering parameters
inputs.filter.k = 10; % Number of nearest neighbors for statistical k-nearest neighbor distance outlier filtering
inputs.filter.radius = 0.01; % Radius for statistical point density outlier filtering (1 cm)
inputs.filter.nsigma = 2; % Multiplier for the standard deviation in filtering
inputs.filter.PatchDiam1 = 0.05; % Patch size for small component filtering (5 cm)
inputs.filter.BallRad1 = 0.065; % Ball radius for small component filtering (6.5 cm)
inputs.filter.ncomp = 5; % Minimum number of patches for small component filtering
inputs.filter.EdgeLength = 0.01; % Edge length for cubicle downsampling (1 cm)
inputs.name = 'tree_model'; % Name string for saving output files and naming models
inputs.tree = 1; % Tree index if modeling multiple trees
inputs.model = 1; % Model index if creating multiple models with the same inputs
inputs.savemat = 1; % Save the output struct QSM as a MATLAB file
inputs.savetxt = 1; % Save the models in .txt files
inputs.plot = 2; % Plot the model, the segmented point cloud, and distributions
inputs.disp = 2; % Display all including QSMs, segmented point cloud, and distributions

% Save the input structure to a .mat file
save('Crateva_seg5m_tree_model', 'inputs');

% Generate the QSM
QSM = treeqsm(P, inputs);
save_model_text(QSM, 'Crateva_seg5m_QSM_tree_model');
% Plot the QSM
plot_cylinder_model(QSM);
