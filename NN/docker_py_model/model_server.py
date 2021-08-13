from flask import Flask, request, Response
import jsonpickle
import numpy as np
import cv2
import argparse

#detectron

import d2_model_load
import requests
import os
import re

app = Flask(__name__)
predictor =  d2_model_load.load_model()

def unpack_set_opts(msg_json):
    set_stuff = ""
    #default options
    opts = ["detector_py_200ep.pth", 0.5, 0.39]
    # print(msg_json)
    if "new_model" in msg_json["set"]:
        opts[0] = msg_json["set"]["model"]
        set_stuff =  set_stuff + "[model]"
    
    if "score_thresh" in msg_json["set"]:
        opts[1] = msg_json["set"]["score_thresh"]
        set_stuff = set_stuff + "[score_thresh:" + str(opts[1]) + "]"

    if "nms_thresh" in msg_json["set"]:
        opts[2] = msg_json["set"]["nms_thresh"]
        set_stuff = set_stuff + "[nms_thresh:" + str(opts[2]) + "]"
        
    return opts, set_stuff

@app.route('/set_new_model', methods=['POST'])
def set_new_model():
    '''sets new score and non-maximum supression 
    thresholds; requires reloading the model. Can be 
    used to set a new model source file. 
    Returns response:{"result":"set[new_model][score_thresh][nms_thresh]"'''
    global predictor

    msg_json = request.get_json()
    response = {"req_no": msg_json["req_no"]}
    
    if "set" in msg_json:
        opts, set_stuff = unpack_set_opts(msg_json)
        set_stuff = "set" + set_stuff
        predictor =  d2_model_load.load_model(file_name_n_path=opts[0],
                                            score_thresh=opts[1],
                                            nms_thresh=opts[2])
        response["result"] = set_stuff
    return response

def unpack_img(msg_json):
    img = None
    if "img" in msg_json:
        pix_len = len(msg_json['img'])
        side_sz = int(np.sqrt(pix_len))
        img = np.asarray(msg_json['img'], dtype=np.uint8).reshape((side_sz,side_sz))
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR) #model expects mxnx3 channels
    return img

@app.route('/predict_bboxes', methods=['POST'])
def predict_bboxes():
    msg_json = request.get_json()

    response = {"req_no": msg_json["req_no"]}
    if "img" in msg_json: #predicts bounding boxes
        # outputs = predictor(cv2.imread(msg_json["img"]))
        
        outputs = predictor(unpack_img(msg_json))
        bbox = outputs['instances'].to("cpu")
        
        print(bbox.pred_boxes[:].tensor.numpy())

        response["bboxes"] = np.ndarray.tolist(bbox.pred_boxes[:].tensor.numpy())
        response["scores"] = np.ndarray.tolist(bbox.scores[:].numpy())
        # del bbox, outputs
    elif "test" in msg_json:
        response["result"] = "received"
    else:
        response["result"] = "no_action"
    del msg_json
    # response_pickled = jsonpickle.encode(response)
    # del msg_json, response
    # return Response(response=response_pickled, status=200, mimetype="application/json")
    return response
    
        
if __name__ == "__main__":
    # parser = argparse.ArgumentParser(description='port number')
    # parser.add_argument('--port', metavar='P', type=int, nargs=1,
    #                     help='port for model server')
    # args = parser.parse_args()
    # port_server =  vars(args)["port"]
    # if port_server != None:
    #     port_server =  port_server[0]
    
    # if port_server == None:
    port_server = 5000
    app.run(host='0.0.0.0', port=port_server)