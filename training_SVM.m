%Copyright (c) 2017 Mahmoud Afifi
%York University - Assiut University

%Please cite our paper if you use the provided source code, pre-trained models, or the dataset.
%Citation information is provided in the readme file (can be found in the dataset webpage).

%Permission is hereby granted, free of charge, to any person obtaining  a copy of this software and associated documentation files (the "Software"), to deal in the Software with restriction for its use for research purpose only, subject to the following conditions:

%The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

%Please cite our paper if you use the provided source code, pre-trained models, or the dataset.
%Citation information is provided in the readme file (can be found in the dataset webpage).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_all_features

%get gender classification training and testing data

%please locate directories of .txt files in the same directory of this code.

%all images should be located in the following directory (please change the name accordingly).



baseDir='hands'; %you can get it from the webpage of the dataset

mkdir('gender');

for i=[1,2,3,4,5,6,7,8,9,10]
    
    mkdir(fullfile('gender',num2str(i)));
    
    sides={'p','d'};
    sets={'training','testing'};
    for S=1:2
        
        newDir_=sprintf('gender\\%s\\%s_',num2str(i),sets{S});
        
        for s=1:2
            if s==1
                newDir=strcat(newDir_,'palmar');
            else
                newDir=strcat(newDir_,'dorsal');
            end
            mkdir(newDir);
            mkdir(fullfile(newDir,'male'));
            mkdir(fullfile(newDir,'female'));
            
            fileID = fopen(fullfile('.\',num2str(i),sprintf('g_imgs_%s_%s.txt',sets{S},sides{s})),'r');
            imageNames = textscan(fileID,'%s\r\n'); %change it to '%s\n' for Linux users
            imageNames=imageNames{1};
            fclose(fileID);
            
            fileID = fopen(fullfile('.\',num2str(i),sprintf('g_%s_%s.txt',sets{S},sides{s})),'r');
            gender = textscan(fileID,'%s\r\n'); %change it to '%s\n' for Linux users
            gender=gender{1};
            fclose(fileID);
            
            for j=1:length(imageNames)
                n=imageNames{j};
                n=strcat(n(1:end-3),'mat');
                copyfile(fullfile(baseDir,n),fullfile(newDir,gender{j},n));
            end
        end
    end
end



%%start training SVM using extracted features ....
% Train multiclass SVM classifier using a fast linear solver, and set
% 'ObservationsIn' to 'columns' to match the arrangement used for training
% features.




%%% training 
for SIDE=1:2
    if SIDE==1
        side_='dorsal'; %'dorsal' or 'palmar'
    else
        side_='palmar'; %'dorsal' or 'palmar'
    end
    
    for i=1:10 %do the experiments using the 10 folds generated by get_data.m
        %training data
        rootFolder=fullfile('gender',num2str(i),strcat('training_',side_));
        rootFolder2=fullfile('gender',num2str(i),strcat('testing_',side_));
        categories={'male','female'};
        %load data to memory
        training_data=[];
        training_response=[];
        for c=1:2
            data_=dir(fullfile(rootFolder,categories{c},'*.mat'));
            if c==1 %male=1
                training_response=[training_response;ones(length(data_),1)];
            else %female=0
                training_response=[training_response;zeros(length(data_),1)];
            end
            for d=1:length(data_)
                load(fullfile(rootFolder,categories{c},data_(d).name))
                training_data=[training_data;features.low,features.high,features.fusion];
            end
        end
        
        
        if strcmp(side_,'palmar')
            model=strcat('SVM_p_',num2str(i));
            conf_name=strcat('SVM_results_p_',num2str(i),'.mat');
        else
            model=strcat('SVM_d_',num2str(i));
            conf_name=strcat('SVM_results_d_',num2str(i),'.mat');
        end
        
        tic;
        classifier = fitcecoc(training_data, training_response,...
            'Learners', 'Linear', 'Coding', 'onevsall', 'ObservationsIn', 'rows');
        
        t_training=toc;
        
        save(strcat(model,'.mat'),'classifier');
        clear training_data training_response
        
        testing_data=[];
        testing_response=[];
        for c=1:2
            data_=dir(fullfile(rootFolder2,categories{c},'*.mat'));
            if c==1 %male=1
                testing_response=[testing_response;ones(length(data_),1)];
            else %female=0
                testing_response=[testing_response;zeros(length(data_),1)];
            end
            for d=1:length(data_)
                load(fullfile(rootFolder2,categories{c},data_(d).name))
                testing_data=[testing_data;features.low,features.high,features.fusion];
            end
        end
        
        ind=randperm(size(testing_data,1));
        testing_data=testing_data(ind,:);
        testing_response=testing_response(ind,:);
        
        
        
        tic
        % Pass CNN image features to trained classifier
        predictedLabels = predict(classifier, testing_data);
        t_testing=toc;
        
        
        % Tabulate the results using a confusion matrix.
        confMat = confusionmat(testing_response, predictedLabels);
        
        % Convert confusion matrix into percentage form
        confMat = bsxfun(@rdivide,confMat,sum(confMat,2));
        
        save(conf_name,'confMat');
        sprintf('The result for %s %s - number %s: %f',model, side_(1),num2str(i),mean(diag(confMat)))
        sprintf('Time training: %f - testing: %f',t_training,(t_testing/length(predictedLabels)))
        
    end
    
end





