import 'package:flutter/material.dart';

Widget createEmulatorView({required String romUrl, required String core}) {
  return Container(
    color: Colors.black,
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.computer, color: Colors.purple, size: 64),
          SizedBox(height: 16),
          Text(
            'Emülatör sadece Web / noarch RPM sürümünde desteklenmektedir.',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Masaüstü yerel sürümünde oynatmak için lütfen web buildini çalıştırın.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}
