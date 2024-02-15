import 'package:flutter/material.dart';
import 'package:style_transfer_client/constants/size_constants.dart';
import 'package:style_transfer_client/constants/string_constants.dart';
import 'package:style_transfer_client/image_select_view_mixin.dart';
import 'package:style_transfer_client/widgets/app_icon_button.dart';
import 'package:style_transfer_client/widgets/app_loading_indicator.dart';
import 'package:style_transfer_client/widgets/app_memory_image.dart';
import 'package:style_transfer_client/widgets/app_text.dart';

class ImageSelectView extends StatefulWidget {
  const ImageSelectView({super.key});

  @override
  State<ImageSelectView> createState() => _ImageSelectViewState();
}

class _ImageSelectViewState extends State<ImageSelectView> with ImageSelectViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText(text: StringConstants.appBarText)),
      body: SafeArea(
        child: Padding(
          padding: SizeConstants.pageOuterPadding(),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: galleryImageBuilder(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: stylizersBuilder(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: outputImageBuilder(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Center outputImageBuilder() {
    return Center(
      child: ValueListenableBuilder(
        valueListenable: outputImage,
        builder: (context, outputImageValue, _) {
          if (outputImageValue?.isEmpty == true) {
            return const AppText(text: StringConstants.waitingForBlending);
          } else if (outputImageValue == null) {
            return const AppText(
              text: StringConstants.networkFetchErrorText,
            );
          }

          return AppMemoryImage(base64Str: outputImageValue);
        },
      ),
    );
  }

  ValueListenableBuilder<List<StylizerImageModel>?> stylizersBuilder() {
    return ValueListenableBuilder(
      valueListenable: stylizers,
      builder: (context, images, _) {
        if (images == null) {
          return const Center(
            child: AppText(
              text: StringConstants.networkFetchErrorText,
            ),
          );
        }

        if (images.isEmpty) {
          return const AppLoadingIndicator();
        }

        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: setSelectedStylizerAndPredict,
                itemBuilder: (context, index) {
                  return AppMemoryImage(base64Str: images[index].data!);
                },
              ),
            ),
            ValueListenableBuilder(
                valueListenable: galleryImage,
                builder: (context, galleryImageValue, _) {
                  if (galleryImageValue.isEmpty) return const SizedBox();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIconButton(onPressed: previousStylizer, icon: Icons.arrow_back),
                      AppIconButton(onPressed: nextStylizer, icon: Icons.arrow_forward),
                    ],
                  );
                }),
          ],
        );
      },
    );
  }

  Widget galleryImageBuilder() {
    return ValueListenableBuilder(
        valueListenable: stylizers,
        builder: (context, stylizerList, _) {
          if (stylizerList == null || stylizerList.isEmpty == true) {
            return const Center(
              child: AppText(
                text: StringConstants.networkFetchErrorText,
              ),
            );
          }

          return ValueListenableBuilder(
            valueListenable: galleryImage,
            builder: (context, galleryImage, _) {
              if (galleryImage.isEmpty) {
                return GestureDetector(
                  onTap: pickGalleryImage,
                  child: Container(
                    height: double.maxFinite,
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: SizeConstants.borderRadiusGeneral(),
                      color: Colors.white,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera),
                        AppText(text: StringConstants.pickAnImage),
                      ],
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: pickGalleryImage,
                child: AppMemoryImage(base64Str: galleryImage),
              );
            },
          );
        });
  }
}
