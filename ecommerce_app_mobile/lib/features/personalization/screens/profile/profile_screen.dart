import 'dart:io';

import 'package:ecommerce_app_mobile/Service/Model/user_model.dart';
import 'package:ecommerce_app_mobile/common/styles/section_heading.dart';
import 'package:ecommerce_app_mobile/common/widgets/appbar/appbar.dart';
import 'package:ecommerce_app_mobile/common/widgets/loading/custom_loading.dart';
import 'package:ecommerce_app_mobile/features/personalization/controllers/profile_controller.dart';
import 'package:ecommerce_app_mobile/features/personalization/screens/profile/password_update.dart';
import 'package:ecommerce_app_mobile/features/personalization/screens/profile/update_profile.dart';
import 'package:ecommerce_app_mobile/navigation_menu.dart';
import 'package:ecommerce_app_mobile/utils/constants/sizes.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'widgets/profile_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final controller = Get.put(ProfileController());
  //final controllerNav = Get.put(NavigationController(initialIndex: 3));

  late String userAvatarURL;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: const Text('Hồ sơ'),
        showBackArrow: true,
        backOnPress: () => {
          Get.off(() => const NavigationMenu(initialIndex: 3)),
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: FutureBuilder(
              future: controller.getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    final data = snapshot.data as UserModel;
                    userAvatarURL = data.avatar_imgURL!;
                    return Column(
                      children: [
                        //Profile picture
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                  userAvatarURL,
                                ),
                                radius: 60,
                              ),
                              TextButton(
                                onPressed: () async {
                                  final imagePicker = ImagePicker();
                                  final XFile? pickedFile = await imagePicker
                                      .pickImage(source: ImageSource.gallery);

                                  if (pickedFile != null) {
                                    String uniqueFileName =
                                        '${DateTime.now().millisecondsSinceEpoch}.jpg';
                                    // You might need to update the imageURL in the controller or wherever it is stored
                                    Reference referenceRoot =
                                        FirebaseStorage.instance.ref();
                                    Reference referenceDirImages =
                                        referenceRoot.child('profiles');

                                    Reference referenceImageToUpload =
                                        referenceDirImages
                                            .child(uniqueFileName);

                                    try {
                                      await referenceImageToUpload
                                          .putFile(File(pickedFile.path));
                                      userAvatarURL =
                                          await referenceImageToUpload
                                              .getDownloadURL();
                                      //print(userAvatarURL);
                                      UserModel userData = UserModel(
                                        id: data.id,
                                        firstName: data.firstName,
                                        lastName: data.lastName,
                                        email: data.email,
                                        phoneNumber: data.phoneNumber,
                                        password: data.password,
                                        avatar_imgURL: userAvatarURL,
                                      );

                                      SmartDialog.showLoading(
                                        animationType: SmartAnimationType.scale,
                                        builder: (_) => const CustomLoading(),
                                      );
                                      await controller.updateUser(userData);
                                      setState(() {
                                        userAvatarURL = userAvatarURL;
                                      });
                                      SmartDialog.dismiss();
                                    } catch (error) {
                                      if (kDebugMode) {
                                        print(error);
                                      }
                                    }
                                  } else {
                                    Get.snackbar('Thông báo', 'Không chọn ảnh',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor:
                                            Colors.green.withOpacity(0.1),
                                        colorText: Colors.green,
                                        duration: const Duration(seconds: 1));
                                  }
                                },
                                child: const Text('Đổi ảnh đại diện'),
                              ),
                            ],
                          ),
                        ),

                        //Details
                        const SizedBox(height: TSizes.spaceBtwItems / 2),
                        const Divider(),
                        const SizedBox(height: TSizes.spaceBtwItems),
                        const TSectionHeading(
                          title: 'Thông tin hồ sơ',
                          showActionButton: false,
                        ),
                        const SizedBox(height: TSizes.spaceBtwItems),

                        TProfileMenu(
                          onPressed: () {},
                          title: 'Tên đầy đủ',
                          value: '${data.lastName} ${data.firstName}',
                        ),

                        const SizedBox(height: TSizes.spaceBtwItems / 2),
                        const Divider(),
                        const SizedBox(height: TSizes.spaceBtwItems),
                        const TSectionHeading(
                          title: 'Thông tin cá nhân',
                          showActionButton: false,
                        ),
                        const SizedBox(height: TSizes.spaceBtwItems),
                        TProfileMenu(
                          onPressed: () {},
                          title: 'Email',
                          value: data.email,
                        ),
                        TProfileMenu(
                          onPressed: () {},
                          title: 'Số điện thoại',
                          value: data.phoneNumber,
                        ),
                        TProfileMenu(
                          onPressed: () {},
                          title: 'Giới tính',
                          value: 'None',
                        ),
                        TProfileMenu(
                          onPressed: () {},
                          title: 'Ngày sinh',
                          value: '01/01/1970',
                        ),
                        const Divider(),
                        const SizedBox(height: TSizes.spaceBtwItems),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Get.off(() => const ProfileUpdateScreen());
                            },
                            child: const Text(
                              'Sửa đổi thông tin',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        if (controller.getProviderId() != 'google.com' &&
                            controller.getProviderId() != 'facebook.com')
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Get.off(() => const PasswordUpdateScreen());
                              },
                              child: const Text(
                                'Đổi mật khẩu',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Đóng tài khoản',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  }
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }),
        ),
      ),
    );
  }
}
