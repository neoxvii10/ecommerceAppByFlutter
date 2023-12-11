// ignore: depend_on_referenced_packages

class AddressModel {
  final String id;
  final String province;
  final String district;
  final String ward;
  final String provinceId;
  final String districtId;
  final String wardCode;
  final String name;
  final String street;
  final String phoneNumber;
  bool isDefault;

  AddressModel({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.province,
    required this.district,
    required this.street,
    required this.ward,
    required this.isDefault,
    required this.provinceId,
    required this.districtId,
    required this.wardCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'province': province,
      'district': district,
      'ward': ward,
      'street': street,
      'phoneNumber': phoneNumber,
      'name': name,
      'isDefault': isDefault,
      'provinceId': provinceId,
      'districtId': districtId,
      'wardCode': wardCode,
    };
  }
}
