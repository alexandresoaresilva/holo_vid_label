classdef HoloVid < handle
    properties(Access=public)
        vid_name
        vid_file_path
        no_of_frames
        selected_fr_no
        curr_select_fr
        princ_frames
        deriv_frames
        cutoff_frame_no
        frames
        bboxes_have_been_consolidated
    end
    properties(Access=private)
        bboxes_have_just_been_added
        framerate
        txt_xy
        show_I_minmax
        parent_ax_obj
        sqr_fr_side_sz
        total_labels
        no_labels_map
        princip_bboxes
        previous_cutoff
        frs_to_which_bboxes_have_been_applied
    end
    methods(Access=public)
        function self = HoloVid(vid_path_n_name, parent_ax_obj, sqr_fr_side_sz)
            if nargin < 2
                parent_ax_obj = [];
            end
            if nargin < 3
                sqr_fr_side_sz = 1002;
            end
            self.framerate = 5;
            self.bboxes_have_been_consolidated = false;
            self.vid_name = regexprep(vid_path_n_name,'.*\\','');
            self.vid_file_path = regexprep(vid_path_n_name, self.vid_name,'');
            self.sqr_fr_side_sz = sqr_fr_side_sz;
            self.parent_ax_obj = parent_ax_obj;
            self.show_I_minmax = false;
            self.load_vid(vid_path_n_name);
            self.update_axes_with_selected_frame();
            self.txt_xy = round(self.sqr_fr_side_sz/8);
            self.frs_to_which_bboxes_have_been_applied = [];
        end
    end
    methods(Access=public)
        function add_bbox_to_selected_fr(self, bbox)
            if nargin < 2
                bbox = [];
            end
            
            if isempty(bbox)
                bbox = drawrectangle(self.parent_ax_obj);
            end
            fr = self.get_frame();
            fr.add_bbox_to_rect_array(bbox);
            
            if self.selected_fr_no < self.cutoff_frame_no
                self.bboxes_have_just_been_added = true;
                bbox_copy = fr.copy_last_added_bbox();
                fr_that_follows = self.get_frame(self.selected_fr_no+1);
                fr_that_follows.add_bbox_to_rect_array(bbox_copy);
            end
            self.add_princip_fr_no();
        end
        
        function delete_selected_bbox(self)
            fr = self.get_frame();
            fr.del_bbox();
            if isempty(fr.get_all_rect_bboxes())
                
            end
        end
        function set_show_I_minmax(self, checkbox_value)
            self.clear_ax_obj_parent_for_bboxes();
            self.show_I_minmax = checkbox_value;
            self.update_axes_with_selected_frame()
        end
        function next_fr(self)
            self.clear_ax_obj_parent_for_bboxes();
            
            self.selected_fr_no = self.selected_fr_no + 1;
            if self.selected_fr_no > self.cutoff_frame_no
                self.selected_fr_no = 1;
            end
            self.update_axes_with_selected_frame()
        end
        function prev_fr(self)
            self.clear_ax_obj_parent_for_bboxes();
            
            self.selected_fr_no = self.selected_fr_no - 1;
            if self.selected_fr_no < 1
                self.selected_fr_no = self.cutoff_frame_no;
            end
            self.update_axes_with_selected_frame()
        end
        function select_fr(self, fr_no)
            self.clear_ax_obj_parent_for_bboxes();
            self.selected_fr_no = fr_no;
            
            if self.selected_fr_no < 1
                self.selected_fr_no = self.cutoff_frame_no;
            elseif self.selected_fr_no > self.cutoff_frame_no
                self.selected_fr_no = 1;
            end
            
            self.get_frame();
            self.update_axes_with_selected_frame();
        end
        function set_cutoff_fr(self, new_cutoff)
            self.previous_cutoff = self.cutoff_frame_no;
            if new_cutoff > self.no_of_frames
                new_cutoff = self.no_of_frames;
            elseif new_cutoff <  1
                new_cutoff = 1;
            end
            self.cutoff_frame_no = new_cutoff;
            
%             if self.bboxes_have_been_consolidated
%                 self.apply_princ_bboxes_to_all_fr_above_cutoff();
%             end
        end
        function combine_bboxes_from_all_fr(self)
            idx = [self.frames(:).is_principal];
            princip_fr = [self.frames(idx)];
            if ~isempty(princip_fr)
                self.princip_bboxes = princip_fr(1).get_all_rect_bboxes();
                for i=2:length(princip_fr)
                    self.princip_bboxes = [self.princip_bboxes; princip_fr(i).get_all_rect_bboxes()];
                end
%                 self.apply_princ_bboxes_to_all_fr_above_cutoff();
%                 self.bboxes_have_been_consolidated = true;
%                 self.update_axes_with_selected_frame();
            end
        end
        function ret = vid_has_at_least_one_bbox(self)
            idx = [self.frames(:).is_principal];
            princip_fr = [self.frames(idx)];
            ret = ~isempty(princip_fr);
        end 
        %this function fixes issue with Matlab deleting the ROI
        % Rectangles; it's a fucking hack to preserve the Rectangle objects
        % in the array in the Frame obj
        function clear_ax_obj_parent_for_bboxes(self)
            fr = self.frames(self.selected_fr_no); %gets currently selected frame
            fr.erase_axes_info_from_bboxes();
        end
        
        function I = get_fr_img(self)
            fr = self.get_frame();
            I = fr.get_fr_img(self.show_I_minmax);
        end
        function I = get_I_orig(self)
            fr = self.get_frame();
            I = fr.get_fr_img();
        end
        function I = get_I_min_max_norm(self)
            fr = self.get_frame();
            I = fr.get_fr_img(true);
        end
        function set_parent_axes_obj(self, parent_axes_obj)
            self.parent_ax_obj = parent_axes_obj;
            for i=1:length(self.frames)
                self.frames(i).set_parent_ax_obj(parent_axes_obj);
            end
        end
        
        function fr_rate = get_fr_rate(self)
           fr_rate = self.framerate;
        end
    end
    
    methods(Access=private)
        function load_vid(self, vid_file_path)
            vid = VideoReader(vid_file_path);
            i = 1;
            %             dummy_frames = Frame();
            while hasFrame(vid)
                I = readFrame(vid);
                dummy_frames(i) = Frame(i, I, self.parent_ax_obj, self.sqr_fr_side_sz);
                i = i + 1;
            end
            self.framerate = vid.FrameRate;
            self.frames = dummy_frames;
            self.selected_fr_no = 1;
            self.curr_select_fr = self.frames(self.selected_fr_no);
            self.no_of_frames = length(self.frames);
            self.cutoff_frame_no = self.no_of_frames;
            self.princ_frames = [];
            self.deriv_frames = 1:self.no_of_frames;
        end
        function update_axes_with_selected_frame(self)
            if ~isempty(self.parent_ax_obj)
                fr = self.get_frame(); %gets currently selected frame
                fr.update_axes_with_frame(self.show_I_minmax);
                self.update_text_over_fr();
                
                if self.bboxes_have_just_been_added
                    self.bboxes_have_just_been_added = false;
                   % add bboxes to frames that follow here
                end
            end
        end
        
        function apply_princ_bboxes_to_all_fr_above_cutoff(self)
            fr_numbers=1:self.cutoff_frame_no;
            if ~isempty(self.frs_to_which_bboxes_have_been_applied)
                for i=1:length(fr_numbers)
                    idx = (i == self.frs_to_which_bboxes_have_been_applied);
                    fr_numbers(idx) = [];
                end
            end
            
            
            
            if self.previous_cutoff + 1 >= self.cutoff_frame_no
               fr_numbers=self.cutoff_frame_no:self.previous_cutoff+1;
            elseif self.previous_cutoff < self.cutoff_frame_no
                fr_numbers=self.cutoff_frame_no:self.previous_cutoff+1;
            end
%             if self.previous_cutoff+1 >= self.cutoff_frame_no
% for fr_no=self.previous_cutoff+1:self.cutoff_frame_no
                for i=fr_numbers
                    fr = self.get_frame(i);
                    fr.erase_axes_info_from_bboxes();
                    if ~self.bboxes_have_been_consolidated
                        fr.store_princip_bboxes_n_clear_bbox_array();
                    end
                    for j=1:length(self.princip_bboxes)
                        fr.add_bbox_to_rect_array(self.princip_bboxes(j).copy()); %copies because each frame needs their own labels
                    end
                    self.frs_to_which_bboxes_have_been_applied(end+1) = i;
                end
%             end
%             end
        end
        function fr = get_frame(self, fr_no)
            if nargin < 2
                fr_no = self.selected_fr_no;
            end
            
            if fr_no > self.cutoff_frame_no
                fr_no = self.cutoff_frame_no;
            elseif fr_no < 1
                fr_no = 1;
            end
            
            fr = self.frames(fr_no);
%             self.curr_select_fr = fr;
%             self.selected_fr_no = fr_no;
        end
        function add_princip_fr_no(self)
            if isempty(self.princ_frames)
                self.princ_frames = self.selected_fr_no;
            else
                %check 1st if principal frame no. is already there
                idx = find(self.princ_frames == self.selected_fr_no,1);
                if isempty(idx)
                    self.princ_frames(end+1) = self.selected_fr_no;
                end
            end
            idx = find(self.deriv_frames == self.selected_fr_no,1);
            self.deriv_frames(idx) = [];
        end
        function update_text_over_fr(self)
            txt_over_pic = {self.vid_name, ['frame ' num2str(self.selected_fr_no)]};
            text(self.parent_ax_obj, self.txt_xy, self.txt_xy, txt_over_pic,"Color",[1 1 1],"FontSize",40,"FontWeight","bold");
        end
    end
end