import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:free_images_storage/controllers/home_controller.dart';

class DriveFiles extends GetView<HomeController> {
  const DriveFiles({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Almacena Imagenes"),
      ),
      body: GetBuilder<HomeController>(
        builder: (_) {
          if (controller.account == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  controller.signIn();
                },
                child: const Text("Iniciar Session"),
              ),
            );
          }
          return FutureBuilder(
            future: controller.getDriveFiles(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text("Error: ${snap.error}"));
              }
              final data = snap.data ?? List.empty();
              if (data.isEmpty) {
                return const Center(child: Text("No hay datos que mostrar"));
              }
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, idx) {
                  return Card(
                    margin: const EdgeInsets.all(10.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(data[idx].name ?? "Empty name"),
                            subtitle: Text(data[idx].mimeType ?? "no mimeType"),
                          ),
                          Text(data[idx].id ?? "sin id")
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed("/subir_imagen");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
