import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/access_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'state/plan_controller.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PlanController(ApiClient());
  runApp(PlanApp(controller));
  controller.init();
}

class PlanApp extends StatelessWidget {
  const PlanApp(this.c, {super.key});
  final PlanController c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => MaterialApp(
        title: 'Mi Plan de Pagos',
        debugShowCheckedModeBanner: false,
        theme: construirTema(Brightness.light),
        darkTheme: construirTema(Brightness.dark),
        themeMode: c.themeMode,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: switch (c.fase) {
          Fase.cargando => const Scaffold(body: Center(child: CircularProgressIndicator())),
          Fase.acceso => AccessScreen(c),
          Fase.app => HomeScreen(c),
        },
      ),
    );
  }
}
