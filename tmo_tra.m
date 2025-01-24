function treeMetrics = analyze_tree_metrics(pointCloudData)
   % Voxel size for subsampling (10 cm)
   voxelSize = 0.1;
   % Subsample the point cloud data using voxelization
   subsampledData = subsample_point_cloud(pointCloudData, voxelSize);
   % Normalize intensity for the subsampled data
   normalizedIntensity = subsampledData(:, 7) / 65535;
   % Compute metrics
   [treeHeight, crownSpread, aggregatedDbh, centroid] = compute_metrics(subsampledData, normalizedIntensity);
  
   % Compute Leaning Angle
   leaningAngle = compute_leaning_angle(subsampledData, normalizedIntensity);
   leaningAngle = abs(90 - leaningAngle);
   isLeaning = leaningAngle > 15;
   % Compute Crown Density
   crownDensity = compute_crown_density(subsampledData);
   crownDensityClass = classify_crown_density(crownDensity);
   % Create a structure to hold all metrics
   treeMetrics = struct( ...
       'TreeHeight', treeHeight, ...
       'CrownSpread', crownSpread, ...
       'AggregatedDbH', aggregatedDbh * 1000, ... % Convert to mm
       'Centroid', centroid, ...
       'LeaningAngle', leaningAngle, ...
       'IsLeaning', isLeaning, ...
       'CrownDensity', crownDensity, ...
       'CrownDensityClass', crownDensityClass ...
   );
   % Display the results
   disp(treeMetrics);
end
function [treeHeight, crownSpread, aggregatedDbh, centroid] = compute_metrics(subsampledData, normalizedIntensity)
   % Compute Tree Height
   z = subsampledData(:, 3);
   treeHeight = range(z); % Height from min to max z
   % Compute Crown Spread
   crownSpread = mean([range(subsampledData(:, 1)), range(subsampledData(:, 2))]);
   % Compute Diameter at Breast Height (DbH)
   aggregatedDbh = compute_dbh(subsampledData, min(z));
   % Compute Centroid
   centroid = mean(subsampledData(:, 1:3), 1);
end
function leaningAngle = compute_leaning_angle(points, normalizedIntensity)
   % Filter points based on intensity
   trunkPoints = points(normalizedIntensity > 0.2, :);
  
   if size(trunkPoints, 1) < 3
       leaningAngle = 0; % Not enough points to compute angle
       return;
   end
   % Fit a plane to the trunk points using PCA
   normal_vector = pca(trunkPoints(:, 1:3));
   leaningAngle = atan2d(norm(cross(normal_vector(:, 3), [0, 0, 1])), ...
                         dot(normal_vector(:, 3), [0, 0, 1]));
end
function subsampledData = subsample_point_cloud(pointCloudData, voxelSize)
   % Subsample the point cloud data using voxelization
   voxelIndices = floor(pointCloudData(:, 1:3) / voxelSize);
   [~, ~, voxelIdx] = unique(voxelIndices, 'rows');
  
   % Calculate mean for each voxel
   subsampledData = arrayfun(@(idx) mean(pointCloudData(voxelIdx == idx, :), 1), ...
                              unique(voxelIdx), 'UniformOutput', false);
   subsampledData = vertcat(subsampledData{:});
end
function aggregatedDbh = compute_dbh(points, min_z)
   % Calculate DbH for each trunk using circle fitting
   z_cut = 1.3; % Standard cut height
   cut_points = points(abs(points(:, 3) - (min_z + z_cut)) < 0.05, :);
  
   if size(cut_points, 1) < 3
       aggregatedDbh = 0; % Not enough points to fit a circle
       return;
   end
   xy_points = cut_points(:, 1:2);
   initial_guess = [mean(xy_points), mean(vecnorm(xy_points - mean(xy_points), 2, 2))];
   circle_model = @(params, xy) (xy(:, 1) - params(1)).^2 + (xy(:, 2) - params(2)).^2 - params(3)^2;
   options = optimoptions('lsqcurvefit', 'Display', 'off');
   params = lsqcurvefit(circle_model, initial_guess, xy_points, zeros(size(xy_points, 1), 1), [], [], options);
  
   r = params(3);
   aggregatedDbh = 2 * r; % Return the diameter
end
function crownDensity = compute_crown_density(points)
   % Voxelization for crown density calculation
   voxelSize = 0.2; % Example voxel size
   voxelIndices = floor(points(:, 1:2) / voxelSize);
  
   % Shift indices to be positive
   xVoxel = voxelIndices(:, 1) - min(voxelIndices(:, 1)) + 1;
   yVoxel = voxelIndices(:, 2) - min(voxelIndices(:, 2)) + 1;
  
   % Use accumarray for faster voxel counting
   voxelCounts = accumarray([xVoxel, yVoxel], 1, [], @sum, 0);
   occupiedVoxels = nnz(voxelCounts); % Count non-zero entries
   totalVoxels = numel(voxelCounts);
  
   crownDensity = (occupiedVoxels / totalVoxels) * 100;
end
function crownDensityClass = classify_crown_density(crownDensity)
   % Classify crown density
   if crownDensity <= 50
       crownDensityClass = 'Sparse';
   else
       crownDensityClass = 'Normal';
   end
end
function liveCrownRatio = plot_intensity_distribution(points, normalizedIntensity)
   % Parameters for slicing
   z_min = min(points(:, 3)); % Minimum height
   z_max = max(points(:, 3));
   slice_height_m = 0.05; % Height of each slice (5 cm = 0.05 m)
   num_slices = ceil((z_max - z_min) / slice_height_m); % Slices based on normalized height
   % Initialize arrays to store counts
   below_count = zeros(num_slices, 1); % Leaf count
   above_count = zeros(num_slices, 1); % Trunk count
  
   for i = 1:num_slices
       % Define slice boundaries in normalized meters
       lower_bound = z_min + (i - 1) * slice_height_m; % Start from min height
       upper_bound = z_min + i * slice_height_m;
       % Get points within the current slice
       slice_indices = points(:, 3) >= lower_bound & points(:, 3) < upper_bound;
       slice_intensity = normalizedIntensity(slice_indices);
       % Count points based on intensity threshold
       below_count(i) = sum(slice_intensity < 0.19); % Count of leaf points
       above_count(i) = sum(slice_intensity >= 0.19); % Count of trunk points
   end
   % Calculate the midpoints for y-axis (normalized heights)
   y_midpoints = z_min + (0:num_slices - 1) * slice_height_m + (slice_height_m / 2);
   % Create the plot
   figure;
   hold on;
   % Plot counts below threshold in green (Leaf)
   b1 = barh(y_midpoints - z_min, below_count, 'FaceColor', [0.1, 0.5, 0.1], 'FaceAlpha', 0.5, 'DisplayName', 'Leaf');
   % Plot counts above threshold in brown (Trunk)
   b2 = barh(y_midpoints - z_min, above_count, 'FaceColor', [0.6, 0.4, 0.2], 'FaceAlpha', 0.5, 'DisplayName', 'Trunk');
   % Formatting the plot
   xlabel('Count of Points');
   ylabel('Height (meters)');
   title('Live Crown Ratio Distribution in Vertical Slices');
   legend([b1, b2], {'Leaf', 'Trunk'}, 'Location', 'northeast');
  
   % Set y-ticks to show height in increments of 0.2 m (20 cm) for every 5 slices
   y_ticks = 0:0.2:(num_slices * slice_height_m);
   set(gca, 'YTick', y_ticks, 'YTickLabel', arrayfun(@(x) sprintf('%.2f m', x), y_ticks, 'UniformOutput', false));
  
   grid on;
   hold off;
   % Calculate Live Crown Ratio (LCR) based on condition
   green_greater_than_brown = sum(below_count > above_count); % Count of slices where leaves exceed trunks
   total_slices = num_slices; % Total number of slices
   if total_slices > 0
       liveCrownRatio = (green_greater_than_brown / total_slices) * 100; % LCR calculation
   else
       liveCrownRatio = 0; % If there are no slices
   end
  
   % Display the Live Crown Ratio
   disp(['Live Crown Ratio: ', num2str(liveCrownRatio), '%']);
end

% Load point cloud data and analyze metrics
pointCloudData = load('flame_cd_t1_mms.txt');
normalizedIntensity = pointCloudData(:, 7) / 65535; % Normalize intensity
% Plot intensity distribution and analyze tree metrics
plot_intensity_distribution(pointCloudData, normalizedIntensity);
analyze_tree_metrics(pointCloudData);
