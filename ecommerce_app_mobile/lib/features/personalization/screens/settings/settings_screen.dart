import 'package:ecommerce_app_mobile/Service/Model/user_model.dart';
import 'package:ecommerce_app_mobile/Service/Repository/authentication_repository.dart';
import 'package:ecommerce_app_mobile/common/dialog/dialog.dart';
import 'package:ecommerce_app_mobile/common/styles/section_heading.dart';
import 'package:ecommerce_app_mobile/common/widgets/appbar/appbar.dart';
import 'package:ecommerce_app_mobile/common/widgets/custom_shapes/container/primary_header_container.dart';
import 'package:ecommerce_app_mobile/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:ecommerce_app_mobile/common/widgets/list_tiles/user_profile_tile.dart';
import 'package:ecommerce_app_mobile/common/widgets/loading/custom_loading.dart';
import 'package:ecommerce_app_mobile/features/personalization/controllers/settings_controller.dart';
import 'package:ecommerce_app_mobile/features/personalization/screens/address/address.dart';
import 'package:ecommerce_app_mobile/features/shop/screens/cart/cart.dart';
import 'package:ecommerce_app_mobile/features/shop/screens/order/order.dart';
import 'package:ecommerce_app_mobile/utils/constants/colors.dart';
import 'package:ecommerce_app_mobile/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final settingsController = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Header
            TPrimaryHeaderContainer(
                child: Column(
              children: [
                /// Appbar
                TAppBar(
                    showBackArrow: false,
                    title: Text('Account',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .apply(color: TColors.white))),

                // User Profile Card
                //Profile picture
                FutureBuilder(
                  future: settingsController.getUserData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        UserModel userModel = snapshot.data as UserModel;

                        return SizedBox(
                          height: 65,
                          child: TUserProfileTitle(
                            profileUrl: userModel.avatar_imgURL,
                            email: userModel.email,
                            firstName: userModel.firstName,
                            lastName: userModel.lastName,
                          ),
                        );
                      }
                    }
                    return const SizedBox(
                      height: 65,
                      child: Center(
                        child: Center(child: CustomLoading()),
                      ),
                    );
                  },
                ),

                const SizedBox(height: TSizes.spaceBtwSections),
              ],
            )),

            /// Body
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  /// Account Setting
                  const TSectionHeading(
                    title: "Account Settings",
                    showActionButton: false,
                  ),
                  const SizedBox(
                    height: TSizes.spaceBtwItems,
                  ),

                  TSettingsMenuTile(
                    icon: Iconsax.safe_home,
                    title: 'My Addresses',
                    subTitle: 'Set shopping delivery address',
                    onTap: () => Get.to(const UserAddressScreen()),
                  ),
                  TSettingsMenuTile(
                    icon: Iconsax.shopping_cart,
                    title: 'My Cart',
                    subTitle: 'Add, remove products and move to checkout',
                    onTap: () => Get.to(const CartScreen()),
                  ),
                  TSettingsMenuTile(
                    icon: Iconsax.bag_tick,
                    title: 'My Orders',
                    subTitle: 'In-progress and Completed Orders',
                    onTap: () => Get.to(const OrderScreen()),
                  ),
                  const TSettingsMenuTile(
                    icon: Iconsax.bank,
                    title: 'Bank Account',
                    subTitle: 'Withdraw balance to registered bank account',
                  ),
                  const TSettingsMenuTile(
                    icon: Iconsax.discount_shape,
                    title: 'My Coupons',
                    subTitle: 'List of all the discounted coupons',
                  ),
                  const TSettingsMenuTile(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    subTitle: 'Set any kind of notification message',
                  ),
                  const TSettingsMenuTile(
                    icon: Iconsax.security_card,
                    title: 'Account Privacy',
                    subTitle: 'Manage data usage and connected accounts',
                  ),

                  /// App Settings
                  const SizedBox(
                    height: TSizes.spaceBtwSections,
                  ),
                  const TSectionHeading(
                    title: 'App Settings',
                    showActionButton: false,
                  ),
                  const SizedBox(
                    height: TSizes.spaceBtwItems,
                  ),
                  const TSettingsMenuTile(
                      icon: Iconsax.document_upload,
                      title: 'Load Data',
                      subTitle: 'Upload Data to your Cloud Firebase'),
                  TSettingsMenuTile(
                    icon: Iconsax.location,
                    title: 'Geolocation',
                    subTitle: 'Set recommendation based on location',
                    trailing: Switch(value: true, onChanged: (value) {}),
                  ),
                  TSettingsMenuTile(
                    icon: Iconsax.security_user,
                    title: 'Safe Mode',
                    subTitle: 'Search result is safe for all ages',
                    trailing: Switch(value: false, onChanged: (value) {}),
                  ),
                  TSettingsMenuTile(
                    icon: Iconsax.image,
                    title: 'HD Image Quality',
                    subTitle: 'Set image quality to be seen',
                    trailing: Switch(value: false, onChanged: (value) {}),
                  ),

                  /// Logout Button
                  const SizedBox(
                    height: TSizes.spaceBtwSections,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await showDialogOnScreen(
                          context: context,
                          title: "Log out here",
                          description: "Are you sure to log out??",
                          onOkPressed: () async {
                            await AuthenticationRepository.instance.logout();
                            Get.snackbar(
                                "Logout Sucess", "Pls login again to use app ");
                          },
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ),
                  const SizedBox(
                    height: TSizes.spaceBtwSections * 2.5,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
