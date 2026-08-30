# GAN image generator

### Requirements 
- `pip install tensorflow` or `pip install tensorflow-cpu`  
- `pip install opencv-python`  

### How to
- Add training data to `Data_for_training` folder.  
- Adjust variables in `Image_generator_model_trainer.py` and run it.  
- Check the snapshots in `Temporary` and `Models` until satisfied with results.  
- When done, pick a desired model, provide its path to `Image_generator_run.py`  
and execute the script with desired parameters.  
- Results will be in `Denerated_output`.  

### Credits 
- Authors of data snippets and information that was used to train ChatGPT, which provided the code.
- Crater textures used to make example training data: BlenderKit comunity (https://www.blendkit.com/asset-gallery?query=author_id:2)
