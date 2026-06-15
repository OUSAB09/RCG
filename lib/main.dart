import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'state/game_state.dart';
import 'screens/main_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final gameState = GameState()..load();
  runApp(ApexRushApp(gameState: gameState));
}

class ApexRushApp extends StatelessWidget {
  const ApexRushApp({super.key, required this.gameState});
  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gameState,
      child: Consumer<GameState>(
        builder: (context, gs, _) {
          return MaterialApp(
            title: 'Apex Rush',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            builder: (context, child) {
              // Accessibility (Phase L): global large-text scaling.
              final scale = gs.largeText ? 1.18 : 1.0;
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              );
            },
            home: const _Boot(),
          );
        },
      ),
    );
  }
}

class _Boot extends StatelessWidget {
  const _Boot();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    if (!gs.loaded) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      );
    }
    return const MainMenu();
  }
}
