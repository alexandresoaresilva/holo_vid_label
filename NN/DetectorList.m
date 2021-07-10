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
    end
    
    methods(Access=public)
        function self = DetectorList()
            self.detector_found = false;
            self.detector_loaded = false;
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            self.NN = [];
            self.detectors_in_dir = {};
            self.sel_detect_file = '';
            file_name = mfilename();
            file_path_with_name = mfilename('fullpath');
            self.current_workdir = regexprep(file_path_with_name,['(\\|/)' file_name],'');
            self.find_detectors();
        end
        function find_detectors(self)
            d = dir(self.current_workdir);
            idx = find(contains({d(:).name},'.mat') & contains({d(:).name},'detector'));
            self.detector_found = ~isempty(idx);
            if self.detector_found
                self.detectors_in_dir = {d(idx).name};
                self.sel_detect_file = self.detectors_in_dir{1};
            end
        end
        function find_n_load_detectors(self)
            self.find_detectors();
            if ~self.detector_loaded
                self.load_detector();
            else
                f = msgbox({'Download a detector (detector_xxx.mat file) from the Dropbox link copied to your clipboard.';...
                            'After downloading detector.mat, move the file to the following directory:';...
                            ' ';self.current_workdir},'warn');
                clipboard('copy','https://www.dropbox.com/sh/qb6yfa4171p5wz6/AACyMB7aMOP5-hMFObts8yB0a?dl=0');
            end
        end
        
        function load_detector(self, sel_detect_file)
            if nargin < 2
               sel_detect_file = self.sel_detect_file;
            end
            if exist([self.current_workdir '\' sel_detect_file],'file')
                d = matfile([self.current_workdir '\' sel_detect_file]);
                if isprop(d,'detector')
                    self.sel_detect_file = sel_detect_file;
                    self.NN = d.detector;
                    self.detector_loaded = true;
                end
            end
        end
        function [bbox, scores] = suggest_bboxes(self, I, ref_score)
            if nargin < 3
                ref_score = 0.5;
            end
            
            if ~self.detector_loaded
                self.find_n_load_detectors();
            end
            
            if self.detector_loaded
                input_size = self.NN.Network.Layers(1).InputSize(1:2);
                I_resized = imresize(I, input_size);

                [bboxes, scores] = detect(self.NN, I_resized);
                idx = scores > ref_score;
                bbox = preprocess_bbox(bboxes(idx,:), I, input_size);
                scores = scores(idx);

            end
        end
        
    end
end

