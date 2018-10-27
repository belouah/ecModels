function updateModel(model_name)
% updateModel
%
%   Benjamin J. Sanchez, 2018-10-27
%

% Initialize COBRA:
current_folder = pwd;
cd ../cobratoolbox
initCobraToolbox
cd(current_folder)

%Add all RAVEN paths:
addpath(genpath('../RAVEN'));

%Load model:
model = load('./model.mat');
model = model.model;
try
    model_version = model.modelID;
    model_version = model_version(strfind(model_version,'_v')+1:end);
catch
    model_version = 'unknown';
end
fid = fopen('model_version.txt');
fprintf(fid,model_version);
fclose(fid);

%Run GECKO pipeline:
cd ./GECKO/geckomat/get_enzyme_data
updateDatabases;
cd ..
[ecModel,ecModel_batch] = enhanceGEM(model,'COBRA');

%Save .mat versions of model:
cd(['../models/ec' model_name])
save(['./ec' model_name '.mat'],'ecModel')
save(['./ec' model_name '_batch.mat'],'ecModel_batch')
cd(current_folder)

end
