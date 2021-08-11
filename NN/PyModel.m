classdef PyModel < handle
    properties(Access=public)
       docker_repo_n_tag 
    end
    properties(Access=private)
        opt
        server_port
        curr_req_no
    end
    methods(Access=public)
        function self = PyModel(docker_repo_n_tag, server_port, test_mode)
            if nargin < 2
%                 x = hdldaemon('socket', 0);
%                 server_port = str2double(x.ipc_id);
%                 hdldaemon('kill');
                server_port = 6006;
            end 
            
            if nargin <3
                
               test_mode = false; 
            end
            self.docker_repo_n_tag = docker_repo_n_tag;
            self.load_webwrite_opt();
            self.server_port = num2str(server_port);
            if ~test_mode
                self.load_model_server();
            end
        end
        function [bbox, scores] = predict(self, I)
            if length(I(1,1,:)) > 1 %3 channels
                I = I(:,:,1); %it's really just grayscale
            end

            %image is transposed because Matlab linearizes matrices row-by-row
            %so result row vector is transposed
            I = I';
            self.gen_request_id();
            msg_json.req_no = self.curr_req_no;
            msg_json.img = I(:);
            response = webwrite(['http://localhost:' self.server_port '/process_request'], msg_json, self.opt);
            bbox = [];  scores = [];
            if msg_json.req_no == self.curr_req_no
                bbox = str2num(regexprep(response.bboxes,'\[+|\]+',''));
                if any(bbox)
                    bbox(:,3:4) = bbox(:,3:4) - bbox(:,1:2);
                    str_scores = strip(regexprep(response.scores,'\[+|\]+',''));
                    cell_list = strsplit(str_scores, {' ','\t'});
                    scores = cell2mat(cellfun(@(x)str2num(x),cell_list,'UniformOutput',false));
                end
            end
        end
        function response = set_new_obj_score_n_nms_thresh(self, score_thresh, nms_thresh)
            if nargin < 3
                nms_thresh = 0.45; %larger than the default (for the container) 0.39
            end
            self.gen_request_id();
            msg_json.req_no = self.curr_req_no;
            msg_json.set.score_thresh = score_thresh;
            msg_json.set.nms_thresh = nms_thresh;
            response = webwrite(['http://localhost:' self.server_port '/process_request'], msg_json, self.opt);
        end
%         function set_new_model_into_container(self)
%             
%         end
        function kill_model_server(self)
            !docker stop py_model
            !docker container rm py_model
        end
    end
    methods(Access=private)
        function load_model_server(self)
            
            
            
            docker_cmd = ['docker run -p ' self.server_port ':5000 --name py_model -it ' self.docker_repo_n_tag];
            
            open_terminal_window_cmd = '';
            if ismac()
                %do nothing
            elseif isunix()
                open_terminal_window_cmd = 'gnome-terminal -- '; %space for docker call
            elseif ispc()
                open_terminal_window_cmd = 'start cmd /c '; %space for docker call
            end
            
            
            system([open_terminal_window_cmd docker_cmd]);
        end
        function gen_request_id(self)
           self.curr_req_no = randi(1e6); 
        end
        
        function is_up = model_server_is_up(self)
            self.gen_request_id();
            msg_json.req_no = self.curr_req_no;
            msg_json.test = true;
            response = webwrite(['http://localhost:' self.server_port '/process_request'], msg_json, self.opt);
            is_up= false;
            if ~ischar(response)
                if isfield(response,'result')
                    is_up = strcmpi(response.result,'received');
                end
            end
        end
        function load_webwrite_opt(self)
            self.opt = weboptions;
            self.opt.RequestMethod = 'post';
            self.opt.ContentType = 'json';
            self.opt.ArrayFormat = 'json';
            self.opt.CharacterEncoding = 'UTF-8';
            self.opt.RequestMethod = 'post';
        end
    end
end