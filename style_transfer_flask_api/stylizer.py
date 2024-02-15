import tensorflow as tf

style_predict_path = 'predict.tflite'
style_transform_path = 'transform.tflite'


class StyleTransfer:
    def __init__(self, content_path, style_path,content_blending_ratio=0.5):
        self.content_path = content_path
        self.style_path = style_path
        self.content_blending_ratio = content_blending_ratio

    def load_img(self, path_to_img):
        img = tf.io.read_file(path_to_img)
        img = tf.io.decode_image(img, channels=3)
        img = tf.image.convert_image_dtype(img, tf.float32)
        img = img[tf.newaxis, :]
        return img

    def preprocess_image(self, image, target_dim):
        shape = tf.cast(tf.shape(image)[1:-1], tf.float32)
        short_dim = min(shape)
        scale = target_dim / short_dim
        new_shape = tf.cast(shape * scale, tf.int32)
        image = tf.image.resize(image, new_shape)
        image = tf.image.resize_with_crop_or_pad(image, target_dim, target_dim)
        return image

    def run_style_predict(self, preprocessed_style_image):
        interpreter = tf.lite.Interpreter(model_path=style_predict_path)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        interpreter.set_tensor(input_details[0]["index"], preprocessed_style_image)
        interpreter.invoke()
        style_bottleneck = interpreter.tensor(interpreter.get_output_details()[0]["index"])()
        return style_bottleneck

    def run_style_transform(self, style_bottleneck, preprocessed_content_image):
        interpreter = tf.lite.Interpreter(model_path=style_transform_path)
        input_details = interpreter.get_input_details()
        interpreter.allocate_tensors()
        interpreter.set_tensor(input_details[0]["index"], preprocessed_content_image)
        interpreter.set_tensor(input_details[1]["index"], style_bottleneck)
        interpreter.invoke()
        stylized_image = interpreter.tensor(interpreter.get_output_details()[0]["index"])()
        return stylized_image

    def stylize(self):
        content_image = self.load_img(self.content_path)
        style_image = self.load_img(self.style_path)
        preprocessed_content_image = self.preprocess_image(content_image, 384)
        preprocessed_style_image = self.preprocess_image(style_image, 256)
        style_bottleneck = self.run_style_predict(preprocessed_style_image)
        stylized_image = self.run_style_transform(style_bottleneck, preprocessed_content_image)
        return stylized_image