import 'package:get/get.dart';
import 'package:get_demo/pages/home/bindings/details_binding.dart';

import '../pages/home/bindings/home_binding.dart';
import '../pages/home/presentation/views/details_view.dart';
import '../pages/home/presentation/views/home_view.dart';

part 'app_routes.dart';

// ignore: avoid_classes_with_only_static_members
class AppPages {
  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      children: [
        GetPage(
            name: Routes.DETAILS,
            page: () => const DetailsView(),
            binding: DetailsBinding()),
      ],
    ),
  ];
}
