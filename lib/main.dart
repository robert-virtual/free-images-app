import 'package:flutter/material.dart';
import 'package:free_images_storage/pages/drive_files.dart';
import 'package:free_images_storage/pages/home_page.dart';
import 'package:free_images_storage/pages/images.dart';
import 'package:free_images_storage/pages/subir_imagen.dart';
import 'package:get/get.dart';
import 'package:free_images_storage/controllers/home_controller.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() {
  timeago.setLocaleMessages("es", timeago.EsMessages());
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/home",
      getPages: [
        GetPage(
          name: "/home",
          page: () => const HomePage(),
          binding: HomeBinding(),
        ),
        GetPage(
          name: "/drivefiles",
          page: () => const DriveFiles(),
          binding: HomeBinding(),
        ),
        GetPage(
          name: "/subir_imagen",
          page: () => const SubirImagen(),
          binding: HomeBinding(),
        ),
      ],
    ),
  );
}
