classdef HoloVidsHolder < matlab.mixin.Copyable
    %BBOXESHOLDER
    % class has a map for which the keys are the holographic microscopy
    % video names and the values are HoloVid classes without data image in
    % their Frames but keeping label info (bounding boxes)
    
    properties(Access=public)
        vid_obj_map
        last_vid_added
        is_empty
        vid_files_path
    end
    properties(Access=private)
        stored_label_files
        saved_vids_cell
        ax_obj_for_vid_disp
        app_path
        %          fr_have_been_cleared
    end
    methods(Access=public)
        function self = HoloVidsHolder(app_path, ax_obj_for_vid_disp, vid_files_path, vid_obj)
            if nargin < 2
                ax_obj_for_vid_disp = [];
            end
            if nargin < 3
                vid_files_path = '';
            end
            if nargin < 4
                vid_obj = [];
            end
            
            %BBOXESHOLDER Construct an instance of this class
            %   Detailed explanation goes here
            self.app_path = app_path;
            self.is_empty = true;
            self.vid_obj_map = containers.Map('KeyType','char','ValueType','any');
            self.last_vid_added = '';
            self.saved_vids_cell = {};
            self.set_vid_files_path(vid_files_path);
            self.ax_obj_for_vid_disp = ax_obj_for_vid_disp;
            if ~isempty(self.vid_files_path)
                if isempty(vid_obj) %object is being reloaded
                    self.find_n_reload_labels();
                else
                    self.add_holo_vid_obj_to_map(vid_obj);
                    self.is_empty = false;
                end
            end
        end
        function ret = vid_files_path_is_NOT_set(self)
            ret = isempty(self.vid_files_path);
        end
        
        function set_vid_files_path(self, vid_files_path)
            self.vid_files_path = vid_files_path;
            self.find_n_reload_labels();
        end
        function add_holo_vid_obj_to_map(self, vid_obj)
            vid_obj.clear_ax_obj_parent_for_bboxes();
            if vid_obj.vid_has_at_least_one_bbox()
                self.last_vid_added = vid_obj.vid_name(1:end-4);
                self.vid_obj_map(self.last_vid_added) = vid_obj;
                self.is_empty = false;
            end
        end
        
        %removes last vid obj included if no file name is fed to the
        %function
        function remov_vid_obj(self, vid_name_no_ext)
            if nargin < 2
                vid_name_no_ext = self.last_vid_added;
            end
            if self.vid_is_in_map(vid_name_no_ext)
                remove(self.vid_obj_map,  vid_name_no_ext);
                if length(self.vid_obj_map.keys) < 1
                    self.is_empty = true;
                end
            end
        end
        
        %tries to load video from video obj map property
        function vid_obj = get_vid_obj_from_map(self, vid_name_no_ext)
            if self.vid_is_in_map(vid_name_no_ext)
                vid_obj = self.vid_obj_map(vid_name_no_ext);
                if vid_obj.frame_imgs_have_been_cleared()
                    vid_obj.set_parent_axes_obj(self.ax_obj_for_vid_disp); %shows image
                    vid_obj.reload_saved_vid(self.vid_files_path);
                end
            end
        end
        
        function save_labels(self, save_individ)
            if nargin < 2
                save_individ = true;
            end
            
            vid_names_cell = self.vid_obj_map.keys;
            if save_individ
                for f=vid_names_cell
                    self.save_one_vid_label(f{1});
                end
            end
        end
        
        function save_one_vid_label(self, vid_name_no_ext)
            if nargin < 2
                vid_name_no_ext = self.last_vid_added;
            end

            vid_obj = self.vid_obj_map(vid_name_no_ext);
            vid_obj_dummy = vid_obj.copy();
            vid_obj_dummy.clear_frame_imgs_for_saving_labels();
            file_path = ['label_files\' vid_name_no_ext '_bboxes.mat'];
            
            if isunix()
                file_path = regexprep(file_path, '\\', '/');
            end
            cd(self.app_path); %fixes behavior of not being able to save
            
            if exist('label_files','dir') ~= 7
                mkdir('label_files');
            end
            save(file_path, 'vid_obj_dummy');
        end
        
        function ret = vid_is_in_map(self, vid_name_no_ex)
            k = keys(self.vid_obj_map);
            idx = find(contains(k, vid_name_no_ex),1);
            ret = ~isempty(idx);
        end
    end
    methods(Access=private)
        function find_n_reload_labels(self)
            self.get_label_file_names();
            for f=self.stored_label_files
                file_name = f{1};
                file_path =   ['label_files\' file_name];
                if isunix()
                    file_path = regexprep(file_path, '\\', '/');
                end
                load(file_path, 'vid_obj_dummy');
                self.add_holo_vid_obj_to_map(vid_obj_dummy);
            end
        end
        
        function get_label_file_names(self)
            d = dir('label_files');
            file_names = {d(:).name};
            idx = contains(file_names, 'bboxes.mat');
            self.stored_label_files = file_names(idx);
        end
    end
end