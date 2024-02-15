import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:style_transfer_client/image_select_view.dart';
import 'package:style_transfer_client/service/dio_client.dart';
import 'package:style_transfer_client/utils/image_util.dart';

mixin ImageSelectViewMixin on State<ImageSelectView> {
  final ValueNotifier<String> galleryImage = ValueNotifier("");
  final ValueNotifier<List<StylizerImageModel>?> stylizers = ValueNotifier([]);
  final ValueNotifier<String?> outputImage = ValueNotifier("");
  late final DioClient _dioClient;
  final pageController = PageController();

  @override
  void initState() {
    super.initState();
    final dio = Dio(
      BaseOptions(
        headers: {'Connection': 'Keep-Alive'},
        persistentConnection: true,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    dio.interceptors.add(LogInterceptor(responseBody: true));

    _dioClient = DioClient(dio: dio);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getStylizerImages();
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void nextStylizer() {
    pageController.nextPage(duration: const Duration(milliseconds: 100), curve: Curves.bounceIn);
  }

  void previousStylizer() {
    pageController.previousPage(duration: const Duration(milliseconds: 100), curve: Curves.bounceOut);
  }

  void setSelectedStylizerAndPredict(int index) {
    _postStyllizer(index);
  }

  Future<void> pickGalleryImage() async {
    final image = await ImageUtil.pickImageFromGallery();
    if (image == null) return;

    galleryImage.value = image;
    pageController.jumpToPage(0);

    _postStyllizer(0);
  }

  Future<void> getStylizerImages() async {
    try {
      final images = await _dioClient.getStylizers();
      if (images?.data is Map<String, dynamic>) {
        final mapResponse = images?.data as Map<String, dynamic>;
        var imageList = <StylizerImageModel>[];
        for (var element in mapResponse['images']) {
          imageList.add(StylizerImageModel.fromMap(element));
        }

        stylizers.value = imageList;
        return;
      }
      stylizers.value = [];
      return;
    } catch (e) {
      log(e.toString(), error: e);
      stylizers.value = null;
    }
  }

  Future<void> _postStyllizer(int selectedStylizerIndex) async {
    try {
      if (stylizers.value == null || stylizers.value?.isEmpty == true) {
        outputImage.value = null;
        return;
      }

      final image = await _dioClient.selectStylizer(stylizers.value![selectedStylizerIndex].fileName!, galleryImage.value);
      if (image != null) {
        outputImage.value = image.data["stylized_output"];
      }
    } catch (e) {
      log(e.toString(), error: e);
      outputImage.value = null;
    }
  }
}

class StylizerImageModel {
  final String? data;
  final String? fileName;

  StylizerImageModel({required this.data, required this.fileName});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'data': data,
      'file_name': fileName,
    };
  }

  factory StylizerImageModel.fromMap(Map<String, dynamic> map) {
    return StylizerImageModel(
      data: map['data'] != null ? map['data'] as String : null,
      fileName: map['file_name'] != null ? map['file_name'] as String : null,
    );
  }
}
