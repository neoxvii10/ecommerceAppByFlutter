import 'dart:convert';

import 'package:ecommerce_app_mobile/Service/Model/address_model.dart';
import 'package:ecommerce_app_mobile/repository/shop_repository/shop_repository.dart';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';

class ShopAddressController extends GetxController {
  static ShopAddressController get instance => Get.find();

  RxList<dynamic> listShopAddress = [].obs;

  @override
  void onReady() async {
    super.onReady();
    await updateShopDetails();
  }

  final _shopRepo = Get.put(ShopRepository());
  final name = TextEditingController();
  final phoneNumber = TextEditingController();
  final address = TextEditingController();
  final province = TextEditingController();
  final district = TextEditingController();
  final ward = TextEditingController();
  final street = TextEditingController();
  final optional = TextEditingController();
  late double lat;
  late double lng;

  String? provinceId;
  String? districtid;
  String? wardCode;
  String? postalCode;

  void clearTextField() {
    name.text = phoneNumber.text = phoneNumber.text = province.text = district
        .text = ward.text = street.text = optional.text = address.text = '';
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Future.error('Location services is disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission is denied');
      }
    }
    Get.back();
    SmartDialog.showLoading();
    final currentLocation = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    const String googelApiKey = 'bn7OlF8CF3syL2gzOFztPdJVLtHBLlxzAQd2VcaE';
    const bool isDebugMode = true;
    final api = GoogleGeocodingApi(
      googelApiKey,
      isLogged: isDebugMode,
    );
    final reversedSearchResults = await api.reverse(
      '${currentLocation.latitude},${currentLocation.longitude}',
      language: 'vn',
    );
    lat = currentLocation.latitude;
    lng = currentLocation.longitude;

    // print(reversedSearchResults.results.toList().first.addressComponents);
    final streetList = [];

    for (GoogleGeocodingAddressComponent element
        in reversedSearchResults.results.toList().first.addressComponents) {
      // if (element.types.contains('administrative_area_level_2') ||
      //     element.types.contains('administrative_area_level_1') ||
      //     element.types.contains('country')) {
      //   break;
      // } else {
      //   if (element.types.contains('street_number') ||
      //       element.types.contains('plus_code')) {
      //     continue;
      //   }
      //   streetList.add(element.longName);
      // }
      streetList.add(element.longName);
    }
    street.text = streetList.join(', ');

    await SmartDialog.dismiss();
  }

  Future<void> removeShopAddress(String id) async {
    await _shopRepo.removeShopAddress(id);
    updateShopDetails();
  }

  Future<void> addShopAddress() async {
    final addressId = const Uuid().v1();
    await _shopRepo.addShopAddress(
      AddressModel(
        phoneNumber: phoneNumber.text,
        name: name.text,
        province: province.text,
        district: district.text,
        street: street.text,
        ward: ward.text,
        isDefault: false,
        id: addressId,
        districtId: districtid!,
        wardCode: wardCode!,
        provinceId: provinceId!,
        lat: lat,
        lng: lng,
        optional: optional.text,
      ),
    );
    await setDefaultAddress(addressId);
  }

  // List<Map<String, dynamic>> getAllShopAddress() {
  //   return _shopRepo.getAllShopAddress();
  // }

  Future<void> updateShopDetails() async {
    listShopAddress.value = (_shopRepo.currentShopModel.address as List);
  }

  Map<String, dynamic> getDefaultAddress() {
    return _shopRepo.getDefaultAddress();
  }

  Future<void> setDefaultAddress(addressId) async {
    await _shopRepo.setDefaultAddress(addressId);
    await updateShopDetails();
  }

  Future<List<Map<String, dynamic>>> getAllProvinceVN() async {
    try {
      var url = Uri.https(
          'online-gateway.ghn.vn', 'shiip/public-api/master-data/province');
      var response = await http.post(
        url,
        headers: {
          'token': '7dbb1c13-7e11-11ee-96dc-de6f804954c9',
        },
      );
      print('Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch province');
      }
      // print('Response body: ${response.body}');
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> provinceList = responseBody['data'];

      return provinceList.map(
        (element) {
          final e = element as Map<String, dynamic>;
          return {
            'ProvinceName': e['ProvinceName'],
            'ProvinceID': e['ProvinceID'],
          };
        },
      ).toList();
    } finally {}
  }

  Future<List<Map<String, dynamic>>> getDistrictOfProvinceVN(
      String provinceID) async {
    try {
      var url = Uri.https(
          'online-gateway.ghn.vn',
          'shiip/public-api/master-data/district',
          {'province_id': '$provinceID'});
      var response = await http.get(
        url,
        headers: {
          'token': '7dbb1c13-7e11-11ee-96dc-de6f804954c9',
        },
      );
      print('Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch district');
      }
      // print('Response body: ${response.body}');
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> districtList = responseBody['data'];
      return districtList.map(
        (element) {
          final e = element as Map<String, dynamic>;
          return {
            'DistrictName': e['DistrictName'],
            'DistrictID': e['DistrictID'],
          };
        },
      ).toList();
    } finally {}
  }

  Future<List<Map<String, dynamic>>> getWardOfDistrictOfVN(
      String districtID) async {
    try {
      var url = Uri.https('online-gateway.ghn.vn',
          'shiip/public-api/master-data/ward', {'district_id': '$districtID'});
      var response = await http.get(
        url,
        headers: {
          'token': '7dbb1c13-7e11-11ee-96dc-de6f804954c9',
        },
      );
      print('Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch ward');
      }
      // print('Response body: ${response.body}');
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> wardList = responseBody['data'];
      print(wardList);

      return wardList.map(
        (element) {
          final e = element as Map<String, dynamic>;
          return {
            'WardName': e['WardName'],
            'WardCode': e['WardCode'],
          };
        },
      ).toList();
    } finally {}
  }

  Future<void> displayPrediction(
      Prediction? p, ScaffoldMessengerState messengerState) async {
    if (p == null) {
      // print('p null');
      return;
    }
    // print('p khong null');

    // get detail (lat/lng)
    final places = GoogleMapsPlaces(
      apiKey: 'bn7OlF8CF3syL2gzOFztPdJVLtHBLlxzAQd2VcaE',
      apiHeaders: await const GoogleApiHeaders().getHeaders(),
    );

    final detail = await places.getDetailsByPlaceId(p.placeId!);
    final geometry = detail.result.geometry!;
    lat = geometry.location.lat;
    lng = geometry.location.lng;

    // final streetList = [];

    // for (AddressComponent element in detail.result.addressComponents) {
    //   // if (element.types.contains('administrative_area_level_2') ||
    //   //     element.types.contains('administrative_area_level_1') ||
    //   //     element.types.contains('country')) {
    //   //   break;
    //   // } else {
    //   //   if (element.types.contains('street_number') ||
    //   //       element.types.contains('plus_code')) {
    //   //     continue;
    //   //   }
    //   //   streetList.add(element.longName);
    //   // }
    //   streetList.add(element.longName);
    // }
    // street.text = streetList.join(', ');
    street.text = p.description ?? '';
    Get.back();
  }
}
