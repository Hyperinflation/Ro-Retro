import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget createEmulatorView({required String romUrl, required String core}) {
  final String viewType = 'emulator-iframe-${DateTime.now().millisecondsSinceEpoch}';
  
  // Register view factory for dynamic iframe loading in modern Flutter
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..srcdoc = """
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: #000; }
          #emulator { width: 100%; height: 100%; }
        </style>
      </head>
      <body>
        <div id="emulator"></div>
        <script>
          EJS_player = '#emulator';
          EJS_gameUrl = '$romUrl';
          EJS_core = '$core';
          EJS_pathtodata = 'https://cdn.emulatorjs.org/stable/data/';
          EJS_startOnLoaded = true;
        </script>
        <script src="https://cdn.emulatorjs.org/stable/data/loader.js"></script>
      </body>
      </html>
      """;
    return iframe;
  });

  return HtmlElementView(viewType: viewType);
}
