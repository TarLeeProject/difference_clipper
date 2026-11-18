import 'dart:math';

import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: DifferenceWidgetPanel(
                  radius: 24,
                  spacing: 8,
                  children: [
                    DifferenceWidget(
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.blue,
                        child: AspectRatio(aspectRatio: 16 / 9),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: DifferenceWidget(
                        isFloating: true,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: .min,
                              children: [
                                Icon(Icons.fax_rounded),
                                Icon(Icons.fax_rounded),
                                Icon(Icons.fax_rounded),
                                Icon(Icons.fax_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: DifferenceWidget(
                        isFloating: true,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisSize: .min,
                              children: [
                                Icon(Icons.fax_rounded),
                                Icon(Icons.fax_rounded),
                                Icon(Icons.fax_rounded),
                                Icon(Icons.fax_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}