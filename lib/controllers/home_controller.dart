import 'dart:convert';

import 'package:free_images_storage/models/drive_file.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

enum MajorDimension { COLUMNS, ROWS }

enum ValueInputOption { USER_ENTERED, RAW }

enum InsertDataOption { OVERWRITE, INSERT_ROWS }

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

class HomeController extends GetxController {
  static const pageSize = 15;
  final pagingController = PagingController<int, List>(firstPageKey: 15);
  final ImagePicker imagePicker = ImagePicker();
  XFile? image;
  String? username;
  GoogleSignIn googleSignIn = GoogleSignIn(scopes: [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
  ]);
  GoogleSignInAccount? account;
  final driveBaseUrl = "https://www.googleapis.com/drive/v3";
  final sheetsBaseUrl =
      "https://sheets.googleapis.com/v4/spreadsheets/1rSMJEQzHmEP0quDxc4rf7KSUvXKshH1OD6xRX0cUWtg";
  final spreadsheetId = "1rSMJEQzHmEP0quDxc4rf7KSUvXKshH1OD6xRX0cUWtg";

  @override
  void onInit() {
    googleSignIn.onCurrentUserChanged.listen((account_) {
      if (account_ != null) {
        account = account_;
        final idx = account!.email.indexOf("@");
        username = account!.displayName ?? account!.email.substring(0, idx);
        /* createSheet(sheet: { */
        /*   "properties": {"title": "imagesdb", */
        /*   "sheets": [ */
        /*     { */
        /*       "properties": {"title": "hola"} */
        /*     }, */
        /*     { */
        /*       "properties": {"title": "mundo"} */
        /*     }, */
        /*     { */
        /*       "properties": {"title": "almacen"} */
        /*     }, */
        /*     { */
        /*       "properties": {"title": "imagenes"} */
        /*     }, */
        /*   ] */
        /* }).then((value) => print(value)); */
        update();
      }
    });
    googleSignIn.signInSilently();
    pagingController.addPageRequestListener((pageKey) {
      fetchPage(sheet: "almacen", pageKey: pageKey, left: "A", right: "Z");
    });
    super.onInit();
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }

  Future<void> signIn() async {
    try {
      googleSignIn.signIn();
    } catch (e) {
      print(e);
    }
  }

  Future<void> signOut() => googleSignIn.disconnect();

  Future<void> fetchPage(
      {required String sheet,
      required String left,
      required String right,
      required int pageKey}) async {
    try {
      final start = pagingController.itemList != null
          ? pagingController.itemList!.length
          : 0;

      final range = "$sheet!$left${start + 1}:$right${pageKey + 1}";
      print("range: $range");
      final newItems = await getSheet(range: range, removeFirst: false);
      final isLastPage = newItems.length < pageSize;
      if (isLastPage) {
        pagingController.appendLastPage(newItems);
        return;
      }
      final nextPageKey = pageKey + newItems.length;
      pagingController.appendPage(newItems, nextPageKey);
    } catch (e) {
      print(e);
      pagingController.error = e;
    }
  }

  Future<String> createSheet({required Map<String, dynamic> sheet}) async {
    try {
      if (account == null) {
        throw "Aun no has iniciado session";
      }
      final res = await http.post(
        Uri.parse("https://sheets.googleapis.com/v4/spreadsheets"),
        headers: await account!.authHeaders,
        body: jsonEncode(
          sheet,
        ),
      );
      if (res.statusCode != 200) {
        print(res.body);
        throw "Ups ha ocurrido un error ${res.statusCode}";
      }
      Map<String, dynamic> json = jsonDecode(res.body);
      print(json);
      print(json["spreadsheetId"]);
      return json["spreadsheetId"];
    } catch (e) {
      rethrow;
    }
  }

  Future<String> sendSheet({
    required String range,
    required List data,
    ValueInputOption valueInputOption = ValueInputOption.USER_ENTERED,
    InsertDataOption insertdataOption = InsertDataOption.OVERWRITE,
  }) async {
    try {
      if (account == null) {
        throw "Aun no has iniciado session";
      }
      final res = await http.post(
        Uri.parse(
            "$sheetsBaseUrl/values/$range:append?valueInputOption=${valueInputOption.name}&insertDataOption=${insertdataOption.name}"),
        headers: await account!.authHeaders,
        body: jsonEncode(
          {
            "values": [data]
          },
        ),
      );
      if (res.statusCode != 200) {
        print(res.body);
        throw "Ups ha ocurrido un error ${res.statusCode}";
      }
      return "Datos enviados con exito";
    } catch (e) {
      rethrow;
    }
  }

  Future<List<List>> getSheet({
    required String range,
    MajorDimension majorDimension = MajorDimension.ROWS,
    reversed = true,
    removeFirst = true,
  }) async {
    try {
      if (account == null) {
        throw "Aun no has iniciado session";
      }
      final res = await http.get(
          Uri.parse(
              "$sheetsBaseUrl/values/$range?majorDimension=${majorDimension.name}"),
          headers: await account!.authHeaders);
      if (res.statusCode != 200) {
        print(res.body);
        throw "Ups ha ocurrido un error ${res.statusCode}";
      }
      final data = jsonDecode(res.body);
      final values = List.from(data["values"]);
      print("${values.length} items loaded");
      if (removeFirst) {
        values.removeAt(0);
      }
      if (reversed) {
        return values.reversed.toList().cast();
      }
      return values.cast();
    } catch (e) {
      rethrow;
    }
  }

  void setImage(XFile? pickedImage) {
    if (pickedImage != null) {
      image = pickedImage;
      update();
    }
  }

  Future<List<DriveFile>> getDriveFiles() async {
    try {
      if (account == null) {
        throw "Aun no has iniciado session";
      }
      final res = await http.get(
          Uri.parse(
              "$driveBaseUrl/files?q=mimeType='application/vnd.google-apps.spreadsheet'"),
          headers: await account!.authHeaders);
      if (res.statusCode != 200) {
        print(res.body);
        throw "Ups ha ocurrido un error ${res.statusCode}";
      }
      final data = jsonDecode(res.body);
      final values = List.from(data["files"]);
      print("${values.length} items loaded");
      return values.map((e) => DriveFile.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
