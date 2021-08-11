
from detectron2.config import get_cfg
from detectron2.engine import DefaultPredictor
from detectron2 import model_zoo
import torch
import os

def get_model_cfg():
    cfg = get_cfg()
    cfg.merge_from_file(model_zoo.get_config_file("COCO-Detection/faster_rcnn_R_50_FPN_3x.yaml"))

    cfg.DATALOADER.NUM_WORKERS = 4

    cfg.SOLVER.IMS_PER_BATCH = 16
    cfg.SOLVER.BASE_LR = 0.001  # pick a good LR
    
    cfg.MODEL.ROI_HEADS.BATCH_SIZE_PER_IMAGE = 2048

    # cfg.SOLVER.STEPS = (22360,0)        # do not decay learning rate (2000,)
    cfg.SOLVER.STEPS = []        # do not decay learning rate np.array(2000,)
    cfg.MODEL.RPN.IOU_LABELS = [-1, 1]
    # Number of regions per image use to train RPNNVIDIA DeepStream
    cfg.MODEL.RPN.IOU_THRESHOLDS = [0.7]

    # Number of regions per image used to train RPN
    cfg.MODEL.RPN.BATCH_SIZE_PER_IMAGE = 2048
    cfg.MODEL.ROI_HEADS.IOU_THRESHOLDS = [0.7]
    os.makedirs(cfg.OUTPUT_DIR, exist_ok=True)
    cfg.INPUT.RANDOM_FLIP = "none"
    cfg.MODEL.ROI_HEADS.NUM_CLASSES = 2  # only has one class (feature of , interp=2interest).
    # NOTE: this config means the number of classes, but a few popular unofficial tutorials incorrect uses num_classes+1 here.
    if not torch.cuda.is_available():
        cfg.MODEL.DEVICE='cpu'
    return cfg

def load_model(file_name_n_path="./detector_py_200ep.pth", score_thresh=0.5, nms_thresh=0.39):
    # model_path = 'output_400x400_aug_38010_iter'
    cfg = get_model_cfg()
    cfg.MODEL.WEIGHTS = file_name_n_path
    cfg.MODEL.ROI_HEADS.SCORE_THRESH_TEST = score_thresh # set a custom testing threshold
    cfg.MODEL.ROI_HEADS.NMS_THRESH_TEST = nms_thresh #Non-max supression threshold
    predictor = DefaultPredictor(cfg)
    print(" ")
    print("faster rcnn model loaded: " + file_name_n_path)
    print("score threshold: " + str(score_thresh))
    print("nms threshold: " + str(nms_thresh))
    print(" ")
    return predictor