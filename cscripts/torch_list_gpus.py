#!/usr/bin/env python

# -*- coding: utf-8 -*-


import torch


if not torch.cuda.is_available():
    print("No GPU available")
else:
    gpu_count: int = torch.cuda.device_count()
    print(f"Number of available GPUs = {gpu_count}")
    for gpu_index in range(gpu_count):
        print(f"GPU {gpu_index} = {torch.cuda.get_device_name(gpu_index)}")
