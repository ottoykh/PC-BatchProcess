% Load point cloud data
data = readmatrix('Job_20241112_MAnShan_Track03_Scanner1_output_7-leafoff-fast.txt', 'NumHeaderLines', 2);
points = data(:, 1:3); % x, y, z
intensity = data(:, 4); % intensity is in the 4th column

% Function to find bottom points (seed points) for regional growing
function seed_indices = find_bottom_points(points)
    z_values = points(:, 3);
    threshold = prctile(z_values, 5); % Determine the 5th percentile for bottom points
    seed_indices = find(z_values <= threshold); % Indices of bottom points
end

% Simple region growing algorithm to segment trunk points
function trunk_indices = region_growing(points, seed_indices, distance_threshold)
    visited = false(size(points, 1), 1);
    trunk_indices = seed_indices(:); % Start with the seed points
    visited(seed_indices) = true; % Mark seed points as visited
    to_visit = points(seed_indices, :); % Points to visit
  
    while ~isempty(to_visit)
        current_point = to_visit(1, :); % Get the first point
        to_visit(1, :) = []; % Remove it from the list
        % Calculate distances to all points
        distances = sqrt(sum((points - current_point).^2, 2));
        neighbors = find(distances < distance_threshold & ~visited);
      
        % Mark new neighbors as visited
        visited(neighbors) = true;
        trunk_indices = [trunk_indices; neighbors]; % Append new trunk indices
        to_visit = [to_visit; points(neighbors, :)]; % Append new points to visit
    end
end

% Step 1: Identify bottom points
seed_indices = find_bottom_points(points);

% Step 2: Segment individual tree trunks using regional growing
visited = false(size(points, 1), 1);
trunks = {}; % Cell array to hold points of each trunk
distance_threshold = 0.3; % Set distance threshold for region growing

% Find and segment each trunk
while true
    % Get the next unvisited seed point
    new_seed_indices = find(~visited & points(:, 3) <= prctile(points(:, 3), 5));
  
    if isempty(new_seed_indices)
        break; % Exit if no more unvisited seed points
    end
  
    % Segment trunk from the current seed point
    trunk_indices = region_growing(points, new_seed_indices(1), distance_threshold);
  
    % Mark trunk points as visited
    visited(trunk_indices) = true;
  
    % Store segmented trunk points
    trunks{end + 1} = points(trunk_indices, :); % Add to cell array
end

% Step 3: Classify remaining points based on proximity to segmented trunks
remaining_indices = find(~visited);
classified_points = []; % To hold classified points

for i = 1:length(trunks)
    trunk_points = trunks{i};
    
    % Calculate distances from remaining points to all trunk points
    for j = 1:size(trunk_points, 1)
        % Calculate distance from each remaining point to the current trunk point
        distances = sqrt(sum((points(remaining_indices, :) - trunk_points(j, :)).^2, 2));
        close_indices = remaining_indices(distances < distance_threshold); % Points close to the trunk
        classified_points = [classified_points; points(close_indices, :)]; % Add to classified points
        visited(close_indices) = true; % Mark these points as visited
    end
end

% Step 4: Visualization
figure;
hold on;
% Plot original points
scatter3(points(:, 1), points(:, 2), points(:, 3), 1, [0.8, 0.8, 0.8], 'filled');
% Plot each trunk in a random color
for i = 1:length(trunks)
    random_color = rand(1, 3); % Generate a random color
    scatter3(trunks{i}(:, 1), trunks{i}(:, 2), trunks{i}(:, 3), 5, random_color, 'filled');
end
% Plot classified points
scatter3(classified_points(:, 1), classified_points(:, 2), classified_points(:, 3), 5, 'r', 'filled');

% Set axis limits for better visualization
axis equal; % Equal scaling for all axes
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Tree Trunk Segmentation and Classification');
legend(arrayfun(@(x) sprintf('Trunk %d', x), 1:length(trunks), 'UniformOutput', false), 'Location', 'best');
grid on;
view(3); % Set the view to 3D
hold off;
