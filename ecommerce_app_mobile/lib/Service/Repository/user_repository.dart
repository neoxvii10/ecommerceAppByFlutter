import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_mobile/Service/Model/address_model.dart';
import 'package:ecommerce_app_mobile/Service/Model/user_model.dart';
import 'package:ecommerce_app_mobile/features/personalization/controllers/profile_controller.dart';
import 'package:ecommerce_app_mobile/features/shop/controllers/shop_address_controller/shop_address_controller.dart';
import 'package:ecommerce_app_mobile/features/shop/models/product_model/product_model.dart';
import 'package:ecommerce_app_mobile/features/shop/models/product_model/product_variant_model.dart';
import 'package:ecommerce_app_mobile/repository/product_repository/product_repository.dart';
import 'package:ecommerce_app_mobile/repository/product_repository/product_variant_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import '../../common/constant/cloudFieldName/user_model_field.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();
  late UserModel currentUserModel;
  @override
  Future<void> onReady() async {
    super.onReady();
    await updateUserDetails();
  }

  final _db = FirebaseFirestore.instance;
  Future<void> updateUserDetails() async {
    currentUserModel =
        await getUserDetails(FirebaseAuth.instance.currentUser!.email!);
  }

  Future<bool> isEmailExisted(String email) async {
    final snapshot = await _db
        .collection('Users')
        .where(
          'email',
          isEqualTo: email,
        )
        .get()
        .catchError(
      (error) {
        if (kDebugMode) {
          print(error);
        }
      },
    );
    final userData = snapshot.docs.map((e) => UserModel.fromSnapshot(e));
    return userData.isNotEmpty;
  }

  Future<void> removeUserAddress(
      String id, BuildContext context, void Function() callback) async {
    final userData = currentUserModel;
    var listAddress = userData.address!;
    final currentObj =
        listAddress.singleWhere((element) => element['id'] == id);
    final currentIndex = listAddress.indexOf(currentObj);
    if (currentObj['isDefault'] == true && listAddress.length > 1) {
      listAddress.remove(currentObj);
      listAddress.first['isDefault'] = true;
    } else {
      listAddress.remove(currentObj);
    }
    userData.address = listAddress;
    await _db
        .collection('Users')
        .doc(userData.id)
        .update(userData.toMap())
        .whenComplete(() async {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully deleted'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              if (currentObj['isDefault']) {
                listAddress = listAddress
                    .map(
                      (e) => {...e, 'isDefault': false},
                    )
                    .toList();
              }

              listAddress.insert(currentIndex, currentObj);
              userData.address = listAddress;
              await _db
                  .collection('Users')
                  .doc(userData.id)
                  .update(userData.toMap())
                  .whenComplete(() async {
                await updateUserDetails();
                callback();
              }).catchError((error, stacktrace) {
                () => SmartDialog.showNotify(
                      msg: 'Failed to undo operation!',
                      notifyType: NotifyType.failure,
                      displayTime: const Duration(seconds: 1),
                    );
                if (kDebugMode) {
                  print(error.toString());
                }
              });
            },
          ),
        ),
      );

      await updateUserDetails();
    }).catchError((error, stacktrace) {
      () => SmartDialog.showNotify(
            msg: 'Có gì đó không đúng, thử lại',
            notifyType: NotifyType.failure,
            displayTime: const Duration(seconds: 1),
          );
      if (kDebugMode) {
        print(error.toString());
      }
    });
  }

  Future<UserModel> getUserDetails(String email) async {
    final snapshot = await _db
        .collection('Users')
        .where(
          'email',
          isEqualTo: email,
        )
        .get()
        .catchError(
      (error) {
        if (kDebugMode) {
          print(error);
        }
      },
    );

    final userData = snapshot.docs.map((e) => UserModel.fromSnapshot(e)).single;
    Get.put(ProfileController());
    //Get.put(CartController());
    ProfileController.instance.crtUser = userData;
    return userData;
  }

  Future<void> updatePassword(UserModel userModel) async {
    await FirebaseAuth.instance.currentUser!
        .updatePassword(userModel.password!);
  }

  List<Map<String, dynamic>> getAllUserAddress() {
    final userData = currentUserModel;
    return userData.address!;
  }

  Future<void> setDefaultAddress(String addressId) async {
    final userData = currentUserModel;
    final listAddress = userData.address!.map(
      (e) {
        final addressModel = AddressModel(
            id: e['id'],
            phoneNumber: e['phoneNumber'],
            name: e['name'],
            province: e['province'],
            district: e['district'],
            street: e['street'],
            ward: e['ward'],
            isDefault: false,
            districtId: e['districtId'],
            provinceId: e['provinceId'],
            wardCode: e['wardCode'],
            lat: e['lat'],
            lng: e['lng'],
            optional: e['optional']);

        if (addressModel.id == addressId) {
          addressModel.isDefault = true;
        }
        return addressModel.toMap();
      },
    ).toList();
    userData.address = listAddress;
    await _db
        .collection('Users')
        .doc(userData.id)
        .update(userData.toMap())
        .whenComplete(() {
      SmartDialog.showNotify(
        msg: 'Đặt địa chỉ mặc định thành công',
        notifyType: NotifyType.success,
        displayTime: const Duration(seconds: 1),
      );
      currentUserModel = userData;
    }).catchError((error, stacktrace) {
      () => SmartDialog.showNotify(
            msg: 'Có gì đó không đúng, thử lại',
            notifyType: NotifyType.failure,
            displayTime: const Duration(seconds: 1),
          );
      if (kDebugMode) {
        print(error.toString());
      }
    });
  }

  Future<void> updateAddressInfo(
      AddressModel currentAddressModel, index) async {
    final userData = currentUserModel;

    userData.address![index] = currentAddressModel.toMap();
    await _db
        .collection('Users')
        .doc(userData.id)
        .update(userData.toMap())
        .whenComplete(() {
      SmartDialog.showNotify(
        msg: 'Thay đổi thông tin thành công',
        notifyType: NotifyType.success,
        displayTime: const Duration(seconds: 1),
      );
      currentUserModel = userData;
    }).catchError((error, stacktrace) {
      () => SmartDialog.showNotify(
            msg: 'Có gì đó không đúng, thử lại',
            notifyType: NotifyType.failure,
            displayTime: const Duration(seconds: 1),
          );
      if (kDebugMode) {
        print(error.toString());
      }
    });
  }

  Map<String, dynamic> getDefaultAddress() {
    final userData = currentUserModel;
    return userData.address!
        .singleWhere((element) => element['isDefault'] == true);
  }

  Future<List<String>?> getUserWishlist() async {
    final userData =
        await getUserDetails(FirebaseAuth.instance.currentUser!.email!);
    return userData.wishlist;
  }

  Future<List<Map<String, dynamic>>?> getUserCart() async {
    final userData =
        await getUserDetails(FirebaseAuth.instance.currentUser!.email!);
    return userData.cart;
  }

  Future<void> addUserAddress(AddressModel addressModel) async {
    final userData = currentUserModel;
    userData.address!.add(addressModel.toMap());
    await _db
        .collection('Users')
        .doc(userData.id)
        .update(userData.toMap())
        .whenComplete(() {
      SmartDialog.showNotify(
        msg: 'Địa chỉ đã được thêm thành công',
        notifyType: NotifyType.success,
        displayTime: const Duration(seconds: 1),
      );
      currentUserModel = userData;
    }).catchError((error, stacktrace) {
      () => SmartDialog.showNotify(
            msg: 'Có gì đó không đúng, thử lại',
            notifyType: NotifyType.success,
            displayTime: const Duration(seconds: 1),
          );
      if (kDebugMode) {
        print(error.toString());
      }
    });
  }

//get user id (doc id cua user)
  Future<String> getCurrentUserDocId() async {
    String email = FirebaseAuth.instance.currentUser!.email!;
    try {
      final snapshot =
          await _db.collection("Users").where("email", isEqualTo: email).get();

      if (snapshot.docs.isNotEmpty) {
        String id = snapshot.docs[0].id;
        return id;
      } else {
        Get.snackbar(
          'Not Found User',
          'Not Found User',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    } catch (error) {
      Get.snackbar(
        'Error',
        'An error occurred',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.red,
      );

      if (kDebugMode) {
        print(error.toString());
      }
    }
    return "No";
  }

  //cap nhat neu nguoi ban dang ki ban hang
  Future<void> registerSellUser() async {
    try {
      String userId = await getCurrentUserDocId();
      await _db
          .collection("Users")
          .doc(userId)
          .update({isSellFieldName: true}).then((value) =>
              Get.snackbar("Success", "You register to be shop successly"));
    } catch (error) {
      Get.snackbar(
        'Error',
        'An error occurred',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.red,
      );

      if (kDebugMode) {
        print(error.toString());
      }
    }
  }

  Future<void> updateUserDetail(UserModel userModel) async {
    await _db
        .collection('Users')
        .doc(userModel.id)
        .update(userModel.toMap())
        .whenComplete(() => Get.snackbar(
              "Thành công",
              "Tài khoản của bạn đã được cập nhật",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.1),
              colorText: Colors.green,
              duration: const Duration(seconds: 1),
            ))
        .catchError((error, stacktrace) {
      () => Get.snackbar(
            'Lỗi',
            'Có gì đó không đúng, thử lại?',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withOpacity(0.1),
            colorText: Colors.red,
          );
      if (kDebugMode) {
        print(error.toString());
      }
    });
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection('Users').get();
    final userData =
        snapshot.docs.map((e) => UserModel.fromSnapshot(e)).toList();

    return userData;
  }

  createUser(UserModel userModel) async {
    await _db
        .collection('Users')
        .add(userModel.toMap())
        .whenComplete(
          () => Get.snackbar(
            'Thành công',
            'Tài khoản của bạn đã được tạo',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
          ),
        )
        .catchError((error, stacktrace) {
      () => Get.snackbar(
            'Lỗi',
            'Có gì đó không đúng, thử lại?',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withOpacity(0.1),
            colorText: Colors.red,
          );
      if (kDebugMode) {
        print(error.toString());
      }
    });
  }

  // kiem tra xem da dang ki ban hang cuha
  Future<bool> isSeller() async {
    final user =
        await getUserDetails(FirebaseAuth.instance.currentUser!.email!);
    return user.isSell;
  }

  Future<void> addProductToCart(ProductVariantModel? productVariant,
      int quantity, String? productVariantId) async {
    final usersCollection = _db.collection('Users');
    try {
      /*  String currentUserId =
          await currentCloudUser.then((value) => value.userId);*/
      final snapshot = await usersCollection
          .where(
            "email",
            isEqualTo: FirebaseAuth.instance.currentUser!.email,
          )
          .get();
      if (snapshot.docs.isNotEmpty) {
        var firstDocument = snapshot.docs[0];
        var documentId = firstDocument.id;
        if (productVariantId != null) {
          Map<String, int> productVariantMap = {
            productVariantId:
                quantity // set your value here, it could be a number or any other data,
          };
          List<Map<String, dynamic>> productVariantList = productVariantMap
              .entries
              .map((entry) => {'${entry.key}': entry.value})
              .toList();
          await usersCollection.doc(documentId).update({
            cartFieldName: FieldValue.arrayUnion(productVariantList),
          });
          // Expected a value of type 'List<dynamic>', but got one of type 'IdentityMap<String, int>
          print("da them vao cart oke nhe");
          return;
        }
        if (productVariant!.id!.isNotEmpty) {
          bool isProductInCart =
              firstDocument[cartFieldName].contains(productVariant.id);
          if (!isProductInCart) {
            Map<String, int> productVariantMap = {
              productVariant.id!:
                  quantity // set your value here, it could be a number or any other data,
            };
            List<Map<String, dynamic>> productVariantList = productVariantMap
                .entries
                .map((entry) => {'${entry.key}': entry.value})
                .toList();
            await usersCollection.doc(documentId).update({
              cartFieldName: FieldValue.arrayUnion(productVariantList),
            });
            Get.snackbar('Ok', "Them vao cart ok");
            return;
          } else {
            Get.snackbar('Error', "Product is already in cart");
            return;
          }
        } else {
          String? productVariantId = await ProductVariantRepository.instance
              .getVariantId(productVariant);
          bool isProductInCart =
              firstDocument[cartFieldName].contains(productVariantId);
          if (!isProductInCart) {
            Map<String, int> productVariantMap = {
              productVariant.id!:
                  quantity // set your value here, it could be a number or any other data,
            };
            List<Map<String, dynamic>> productVariantList = productVariantMap
                .entries
                .map((entry) => {'${entry.key}': entry.value})
                .toList();
            await usersCollection.doc(documentId).update({
              cartFieldName: FieldValue.arrayUnion(productVariantList),
            });
            Get.snackbar('Ok', "Them vao cart ok");
          } else {
            Get.snackbar('Error', "Product is already in cart");
            return;
          }
        }
      } else {
        print('Không tìm thấy ng dùng phù hợp.');
      }
      print('Đã thêm sản phẩm vào cart thành công.');
    } catch (e) {
      print('Lỗi khi thêm sản phẩm vào cart: $e');
    }
  }

  Future<bool> addOrRemoveProductToWishlist(ProductModel productModel) async {
    final usersCollection = _db.collection('Users');
    try {
      Get.put(ProductRepository());
      /*String currentUserId =
          await currentCloudUser.then((value) => value.userId);*/
      final snapshot = await usersCollection
          .where(
            emailFieldName,
            isEqualTo: FirebaseAuth.instance.currentUser!.email,
          )
          .get();
      if (snapshot.docs.isNotEmpty) {
        var firstDocument = snapshot.docs[0];
        var documentId = firstDocument.id;
        if (productModel.id!.isNotEmpty) {
          bool isProductInWishlist =
              firstDocument[wishlistFieldName].contains(productModel.id);
          if (!isProductInWishlist) {
            await usersCollection.doc(documentId).update({
              wishlistFieldName: FieldValue.arrayUnion([productModel.id]),
            });
            print('Them vao wishlist ok**1');
            return true;
          } else {
            await usersCollection.doc(documentId).update({
              wishlistFieldName: FieldValue.arrayRemove([productModel.id]),
            });
            print('Xoa khoi wishlist ok**1');
            return true;
          }
        } else {
          String? productId = await ProductRepository.instance
              .getDocumentIdForProduct(productModel);
          bool isProductInWishlist =
              firstDocument[wishlistFieldName].contains(productId);
          if (!isProductInWishlist) {
            await usersCollection.doc(documentId).update({
              wishlistFieldName: FieldValue.arrayUnion([productId]),
            });
            print('Them vao wishlist2 ok**2');
            return true;
          } else {
            await usersCollection.doc(documentId).update({
              wishlistFieldName: FieldValue.arrayRemove([productId]),
            });
            print('Xoa khoi wishlist ok**2');
            return true;
          }
        }
      } else {
        print('Không tìm thấy ng dùng phù hợp.');
        return false;
      }
    } catch (e) {
      e.printError();
      return false;
    }
  }

  Future<void> removeProductFromWishlist(ProductModel productModel) async {
    final usersCollection = _db.collection('Users');
    try {
      Get.put(ProductRepository());
      /*String currentUserId =
          await currentCloudUser.then((value) => value.userId);*/
      final snapshot = await usersCollection
          .where(
            emailFieldName,
            isEqualTo: FirebaseAuth.instance.currentUser!.email,
          )
          .get();
      if (snapshot.docs.isNotEmpty) {
        var firstDocument = snapshot.docs[0];
        var documentId = firstDocument.id;
        if (productModel.id!.isNotEmpty) {
          bool isProductInWishlist =
              firstDocument[wishlistFieldName].contains(productModel.id);
          if (isProductInWishlist) {
            await usersCollection.doc(documentId).update({
              wishlistFieldName: FieldValue.arrayRemove([productModel.id]),
            });
            print("Da xoa 1");
          }
        } else {
          String? productId = await ProductRepository.instance
              .getDocumentIdForProduct(productModel);
          bool isProductInWishlist =
              firstDocument[wishlistFieldName].contains(productId);
          if (isProductInWishlist) {
            await usersCollection.doc(documentId).update({
              wishlistFieldName: FieldValue.arrayRemove([productId]),
            });
          }
          print("Da xoa 2");
        }
      } else {
        print('Không tìm thấy ng dùng phù hợp.');
      }
    } catch (e) {
      e.printError();
    }
  }

  Future<bool> isProductInWishList(ProductModel product) async {
    final usersCollection = _db.collection('Users');
    try {
      Get.put(ProductRepository());
      /*String currentUserId =
          await currentCloudUser.then((value) => value.userId);*/
      final snapshot = await usersCollection
          .where(
            emailFieldName,
            isEqualTo: FirebaseAuth.instance.currentUser!.email,
          )
          .get();
      if (snapshot.docs.isNotEmpty) {
        var firstDocument = snapshot.docs[0];
        //  var documentId = firstDocument.id;
        if (product.id!.isNotEmpty) {
          return firstDocument[wishlistFieldName].contains(product.id);
        } else {
          String? productId =
              await ProductRepository.instance.getDocumentIdForProduct(product);
          return firstDocument[wishlistFieldName].contains(productId);
        }
      } else {
        return false;
      }
    } catch (e) {
      e.printError();
      return false;
    }
  }
}
