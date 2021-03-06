classdef DetectorList < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access=public)
        current_workdir
        detectors_in_dir
        sel_detect_file
        NN
        detector_found
        detector_loaded
        using_python
        py_model_obj
        py_model_available
        score_thresh
        nms_thresh
        py_model_repo_n_tag 
    end
    
    methods(Access=public)
        function self = DetectorList()
%             self.py_model_repo_n_tag  = 'py_model:latest';
            self.py_model_repo_n_tag  = 'alexandresoaresilva/holo_cotton_feat_detector:version0.5';
            self.py_model_obj = [];
            self.using_python = false;
            self.detector_found = false;
            self.detector_loaded = false;
            self.py_model_available = false;
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            self.NN = [];
            self.detectors_in_dir = {};
            self.nms_thresh = 0.39;
            self.score_thresh = 0.50;
            self.sel_detect_file = '';
            file_name = mfilename();
            file_path_with_name = mfilename('fullpath');
            self.current_workdir = regexprep(file_path_with_name,['(\\|/)' file_name],'');
            self.find_detectors();
        end
        function find_detectors(self)
            self.check_if_py_model_available();
            d = dir(self.current_workdir);
            idx = find(contains({d(:).name},'.mat') & contains({d(:).name},'detector'));
            self.detector_found = ~isempty(idx) || self.py_model_available;
            
            if self.detector_found
                self.detectors_in_dir = {d(idx).name};
                if self.py_model_available
                    self.detectors_in_dir{end+1} = 'py_model';
                end
                
                self.sel_detect_file = self.detectors_in_dir{1};
            else
                f = msgbox({'Download a detector (detector_xxx.mat file) from the Dropbox link copied to your clipboard.';...
                            'After downloading detector.mat, move the file to the following directory:';...
                            ' ';self.current_workdir},'warn');
                clipboard('copy','https://www.dropbox.com/sh/qb6yfa4171p5wz6/AACyMB7aMOP5-hMFObts8yB0a?dl=0');
            end
        end
        function find_n_load_detectors(self)
            self.find_detectors();
            if ~self.detector_loaded
                self.load_detector();
            end
        end
        
        function load_detector(self, sel_detect_file)
            if nargin < 2
               sel_detect_file = self.sel_detect_file;
            end
            
            if isunix()
                file_path= [self.current_workdir '/' sel_detect_file];
            else
                file_path= [self.current_workdir '\' sel_detect_file];
            end
            if contains(sel_detect_file,'py_model')
                self.using_python = true;
                self.py_model_obj = PyModel(self.py_model_repo_n_tag);
            else
                self.kill_py_model();
                
                if exist(file_path,'file')
                    %% LOAD pytorch obj into scriptCALL OBJ THAT CONTROLS PYTORCH MODEL
                    mat_file_obj_prop = matfile(file_path);
                    obj_prop = cell(properties(mat_file_obj_prop));
                    idx = contains(obj_prop, 'detector');
                    if any(idx)
                        self.sel_detect_file = sel_detect_file;
                        self.NN = mat_file_obj_prop.(obj_prop{idx});
                        self.detector_loaded = true;
                    end
                end
            end
        end
        function [bbox, scores] = suggest_bboxes(self, I, score_thresh)
            if nargin < 3
                score_thresh = 0.5;
            end
            
            if ~self.detector_loaded
                self.find_n_load_detectors();
            end
            if self.score_thresh ~= score_thresh
               self.set_obj_nms_on_py_model(score_thresh);
            end
            if self.using_python
                [bbox, scores] = self.py_model_obj.predict(I);
            else
                if self.detector_loaded % matlab detector
                    input_size = self.NN.Network.Layers(1).InputSize(1:2);
                    I_resized = imresize(I, input_size);

                    [bboxes, scores] = detect(self.NN, I_resized);
                    idx = scores > self.score_thresh;
                    bbox = preprocess_bbox(bboxes(idx,:), I, input_size);
                    scores = scores(idx);
                end
            end
        end
        function kill_py_model(self)
            if self.using_python
               if ~isempty(self.py_model_obj)
                   self.py_model_obj.kill_model_server();
                   self.py_model_obj = [];
                   self.using_python = false;
               end
            end
        end
        function set_obj_nms_on_py_model(self, score_thresh, nms_thresh)
            if nargin < 2
               nms_thresh = self.nms_thresh;
            end
            
            if self.using_python
                self.nms_thresh = nms_thresh;
                self.score_thresh = score_thresh;
               self.py_model_obj.set_new_obj_score_n_nms_thresh(score_thresh, nms_thresh);
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access=private)
        function check_if_py_model_available(self)
            [r, ~]=system('docker -v');     docker_is_present = r == 0;

            if docker_is_present
                [r, cmd_out] = system(['docker image inspect ' self.py_model_repo_n_tag]);    
                self.py_model_available = ~contains(cmd_out, 'No such image: py_model');
            end
        end
    end
end

