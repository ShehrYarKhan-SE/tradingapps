import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/registration_screen.dart';
import 'screens/trading_screen.dart';
import 'service/demo_trade_service.dart';
import 'service/user_account_store.dart';
import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const TradeMasterApp());
}

class TradeMasterApp extends StatelessWidget {
  const TradeMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TradeMaster AI',

          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
          ),

          themeMode:
          darkMode ? ThemeMode.dark : ThemeMode.light,

          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SessionSplash();
        }
        if (snapshot.data != null) {
          return const SessionLoader(child: TradingScreen());
        }
        return const RegistrationScreen();
      },
    );
  }
}

class SessionLoader extends StatefulWidget {
  final Widget child;
  const SessionLoader({super.key, required this.child});

  @override
  State<SessionLoader> createState() => _SessionLoaderState();
}

class _SessionLoaderState extends State<SessionLoader> {
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _load();
  }

  Future<void> _load() async {
    await UserAccountStore.instance.bindToCurrentUser();
    await DemoTradeService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SessionSplash();
        }
        return widget.child;
      },
    );
  }
}

class _SessionSplash extends StatelessWidget {
  const _SessionSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF05060B),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2E9BFF)),
      ),
    );
  }
}
