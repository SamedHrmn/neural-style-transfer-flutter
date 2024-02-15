from flask import Flask,jsonify,request
import os
import base64
from stylizer import StyleTransfer
from matplotlib import pyplot as plt
from werkzeug.serving import WSGIRequestHandler
import logging
 

app = Flask(__name__)

app_dir = os.path.dirname(os.path.abspath(__file__))
stylizers_folder = os.path.join(app_dir, 'stylizers')
content_folder = os.path.join(app_dir, 'content')
logging.basicConfig(filename='flask.log', level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

@app.route("/getStylizers",methods=["GET"])
def getStylizers():
  images = read_stylizers()
  return jsonify({'images':images}) 
  


def read_stylizers():
  image_files = [file for file in os.listdir(stylizers_folder) if file.endswith((".jpg", ".png"))]
  image_data = []
  for file in image_files:
    image_path = os.path.join(stylizers_folder, file)
    with open(image_path, "rb") as f:
        image_bytes = f.read()
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        image_data.append({'file_name': file, 'data': image_base64})
        
  return image_data



@app.route("/postStylizer",methods=["POST"])
def postStylizer():
   data = request.get_json()
   if not data or 'selected_stylizer' not in data:
        return jsonify({'error': 'No image selected'}), 400
   if 'content_image_base64' not in data:
        return jsonify({'error': 'No content image provided'}), 400
   
   selected_stylizer_filename = data['selected_stylizer']
   selected_stylizer_path = os.path.join(stylizers_folder, selected_stylizer_filename)

   if not os.path.exists(selected_stylizer_path):
        return jsonify({'error': 'Selected image not found'}), 404
   
   content_image_base64 = data['content_image_base64']
   content_image_path = save_content_image(content_image_base64)

   style_transfer = StyleTransfer(content_path=content_image_path,style_path=selected_stylizer_path)
   stylized_image = style_transfer.stylize()
   stylized_output_path = "stylized_output.jpg"

   plt.imsave(stylized_output_path, stylized_image[0])

   with open(stylized_output_path, "rb") as img_file:
        base64_str = base64.b64encode(img_file.read()).decode("utf-8")
    
   return jsonify({'stylized_output':base64_str}), 200



def save_content_image(content_image_base64):
    if not os.path.exists(content_folder):
        os.makedirs(content_folder)
    
    content_image_path = os.path.join(content_folder, 'content_image.jpg')
    with open(content_image_path, 'wb') as f:
        content_image_bytes = base64.b64decode(content_image_base64)
        f.write(content_image_bytes)
    
    return content_image_path


if __name__ == '__main__':
   WSGIRequestHandler.protocol_version = "HTTP/1.1"
   app.run(debug=False,port=8080,host='0.0.0.0')
