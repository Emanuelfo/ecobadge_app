import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';


// PALETA DE CORES

const Color kGreen      = Color(0xFF9BA960);
const Color kGreenDark  = Color(0xFF7A8A48);
const Color kGreenLight = Color(0xFFDDE8B0);
const Color kDarkGray   = Color(0xFF4C4C4C);
const Color kMidGray    = Color(0xFF7A7A7A);
const Color kBrown      = Color(0xFF835646);
const Color kBeige      = Color(0xFFC4D18B);
const Color kBeigeDark  = Color(0xFFB0BD78);
const Color kLightBrown = Color(0xFFAD705A);
const Color kBackground = Color(0xFFF7F3EC);
const Color kSurface    = Color(0xFFFFFFFF);
const Color kDivider    = Color(0xFFEAE5DC);


// ESTILOS DE TEXTO

const _kTitle    = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kDarkGray, letterSpacing: -0.3);
const _kHeading  = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kDarkGray, letterSpacing: -0.5);
const _kSubtitle = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: kMidGray);
const _kBody     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: kDarkGray, height: 1.5);
const _kCaption  = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kMidGray, letterSpacing: 0.2);
const _kGreenLbl = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGreen);


// ASSETS DO MASCOTE

class EcoAssets {
  static const standard = 'assets/eco1.png';
  static const medal    = 'assets/eco2.png';
  static const tree     = 'assets/eco3.png';
}


/// Simula SharedPreferences em memória para o protótipo.
/// Para produção: substituir o corpo de cada método pela chamada
/// equivalente em SharedPreferences.
class LocalStorage {
  static final Map<String, String> _store = {};

  static Future<void> setString(String key, String value) async {
    _store[key] = value;
  }

  static Future<String?> getString(String key) async => _store[key];

  static Future<void> remove(String key) async {
    _store.remove(key);
  }
}

/// Chaves de persistência
const _kKeyEmail    = 'user_email';
const _kKeyName     = 'user_name';
const _kKeyUsers    = 'users_json'; // JSON com mapa email→senha

class AuthService {
  // ─ Dados em memória (carregados do LocalStorage no main())
  static final Map<String, String> _users = {
    'eco@badge.com': '123456',
  };

  // Perfil do usuário logado
  static String? _email;
  static String? _displayName;
  static int _xp   = 0;    // XP acumulado
  static int _level = 1;   // Nível atual

  // ─ Getters públicos
  static String? get currentUser    => _displayName ?? _email;
  static String? get currentEmail   => _email;
  static bool    get isLoggedIn     => _email != null;
  static int     get xp             => _xp;
  static int     get level          => _level;

  /// XP necessário para o próximo nível (progressão quadrática suave)
  static int xpForNextLevel([int? lvl]) {
    final l = lvl ?? _level;
    return 100 + (l - 1) * 50; // nível 1→2: 100xp, 2→3: 150xp, …
  }

  /// XP atual dentro do nível corrente
  static int get xpInLevel {
    int base = 0;
    for (int l = 1; l < _level; l++) base += xpForNextLevel(l);
    return _xp - base;
  }

  static double get xpProgress =>
      (xpInLevel / xpForNextLevel()).clamp(0.0, 1.0);

  /// Nome do nível baseado no número
  static String get levelTitle {
    const names = [
      '', 'Iniciante', 'Consciente', 'Guardião',
      'Ecologista', 'Protetor', 'Mestre Verde',
    ];
    return _level < names.length ? names[_level] : 'Lenda Verde';
  }

  // ─ Adicionar XP e recalcular nível
  static void addXp(int amount) {
    _xp += amount;
    // Sobe de nível enquanto XP for suficiente
    while (_xp >= _totalXpForLevel(_level + 1)) {
      _level++;
    }
    _persist();
  }

  static int _totalXpForLevel(int target) {
    int total = 0;
    for (int l = 1; l < target; l++) total += xpForNextLevel(l);
    return total;
  }

  // ─ Autenticação

  /// Carrega dados salvos ao inicializar o app.
  /// Retorna true se houver sessão ativa.
  static Future<bool> tryAutoLogin() async {
    final savedEmail = await LocalStorage.getString(_kKeyEmail);
    if (savedEmail == null) return false;
    final savedName  = await LocalStorage.getString(_kKeyName);
    final usersJson  = await LocalStorage.getString(_kKeyUsers);
    if (usersJson != null) {
      final map = jsonDecode(usersJson) as Map<String, dynamic>;
      _users.addAll(map.map((k, v) => MapEntry(k, v.toString())));
    }
    _email       = savedEmail;
    _displayName = savedName;
    _loadXp();
    return true;
  }

  /// Cadastra novo usuário. Retorna null em sucesso ou mensagem de erro.
  static Future<String?> register(String name, String email, String password) async {
    if (name.trim().isEmpty)   return 'Informe seu nome.';
    if (!email.contains('@'))  return 'E-mail inválido.';
    if (password.length < 6)   return 'Senha deve ter ao menos 6 caracteres.';
    final key = email.trim().toLowerCase();
    if (_users.containsKey(key)) return 'Este e-mail já está cadastrado.';
    _users[key]  = password;
    _email       = key;
    _displayName = name.trim();
    await _persist();
    return null;
  }

  /// Faz login. Retorna null em sucesso ou mensagem de erro.
  static Future<String?> login(String email, String password) async {
    final key    = email.trim().toLowerCase();
    final stored = _users[key];
    if (stored == null) return 'E-mail não cadastrado.';
    if (stored != password) return 'Senha incorreta.';
    _email = key;
    _displayName = null; // será exibido o e-mail
    await _persist();
    return null;
  }

  static Future<void> updateName(String name) async {
    _displayName = name.trim();
    await _persist();
  }

  static Future<void> logout() async {
    _email       = null;
    _displayName = null;
    _xp          = 0;
    _level       = 1;
    await LocalStorage.remove(_kKeyEmail);
    await LocalStorage.remove(_kKeyName);
  }

  static void continueAsGuest() {
    _email       = 'visitante@local';
    _displayName = 'Visitante';
  }

  // ─ Persistência interna
  static Future<void> _persist() async {
    if (_email != null) await LocalStorage.setString(_kKeyEmail, _email!);
    if (_displayName != null) await LocalStorage.setString(_kKeyName, _displayName!);
    final usersJson = jsonEncode(_users);
    await LocalStorage.setString(_kKeyUsers, usersJson);
    await LocalStorage.setString('xp', _xp.toString());
    await LocalStorage.setString('level', _level.toString());
  }

  static Future<void> _loadXp() async {
    final xpStr    = await LocalStorage.getString('xp');
    final lvlStr   = await LocalStorage.getString('level');
    _xp    = int.tryParse(xpStr    ?? '0') ?? 0;
    _level = int.tryParse(lvlStr   ?? '1') ?? 1;
  }
}


// PONTO DE ENTRADA — verifica login salvo antes de renderizar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Tenta restaurar sessão salva
  final hasSession = await AuthService.tryAutoLogin();

  runApp(EcoBadgeApp(startLoggedIn: hasSession));
}


// APP ROOT

class EcoBadgeApp extends StatelessWidget {
  final bool startLoggedIn;
  const EcoBadgeApp({super.key, required this.startLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoBadge',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // Se já logado, pula Splash e Auth
      home: startLoggedIn ? const MainScreen() : const SplashScreen(),
    );
  }

  ThemeData _buildTheme() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.light(
      primary: kGreen, secondary: kBrown, surface: kSurface,
      background: kBackground, onPrimary: Colors.white,
      onSecondary: Colors.white, onBackground: kDarkGray, onSurface: kDarkGray,
    ),
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground, foregroundColor: kDarkGray, elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kDarkGray, letterSpacing: -0.5),
      systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark),
    ),
    cardTheme: CardThemeData(
      color: kSurface, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kDivider),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kGreen, foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBrown, side: const BorderSide(color: kBrown),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      ),
    ),
    dividerTheme: const DividerThemeData(color: kDivider, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: kGreen, unselectedItemColor: kMidGray,
      backgroundColor: kSurface, showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed, elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
  );
}


// SPLASH SCREEN

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic)));
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)));
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _goToAuth() => Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const AuthScreen(),
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(children: [
        Positioned(top: -size.width * 0.35, left: -size.width * 0.15,
            child: Container(width: size.width * 1.3, height: size.width * 1.3,
                decoration: BoxDecoration(shape: BoxShape.circle, color: kGreen.withOpacity(0.07)))),
        Positioned(bottom: -60, right: -40,
            child: Container(width: 200, height: 200,
                decoration: BoxDecoration(shape: BoxShape.circle, color: kBrown.withOpacity(0.05)))),
        SafeArea(
          child: FadeTransition(opacity: _fadeAnim, child: Column(children: [
            const Spacer(flex: 2),
            SlideTransition(position: _slideAnim,
                child: ScaleTransition(scale: _scaleAnim,
                    child: EcoImage(asset: EcoAssets.standard, size: size.width * 0.58))),
            const SizedBox(height: 32),
            ScaleTransition(scale: _scaleAnim, child: Column(children: [
              const Text('EcoBadge', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: kDarkGray, letterSpacing: -1.5)),
              const SizedBox(height: 8),
              Text('Escaneie. Avalie. Sustente.', style: _kSubtitle.copyWith(fontSize: 15)),
            ])),
            const Spacer(flex: 3),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Column(children: [
              SizedBox(width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToAuth,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Começar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  )),
            ])),
            const SizedBox(height: 28),
            Text('v6.0  ·  Feito com consciência', style: _kCaption.copyWith(fontSize: 10)),
            const SizedBox(height: 24),
          ])),
        ),
      ]),
    );
  }
}


// TELA DE AUTENTICAÇÃO

enum _AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.login;
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscure  = true;
  bool _obscure2 = true;
  bool _loading  = false;
  String _error  = '';

  late final AnimationController _modeCtrl;
  late final Animation<double> _modeFade;

  @override
  void initState() {
    super.initState();
    _modeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _modeFade = CurvedAnimation(parent: _modeCtrl, curve: Curves.easeInOut);
    _modeCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _pass2Ctrl.dispose();
    _modeCtrl.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) async {
    await _modeCtrl.reverse();
    setState(() { _mode = mode; _error = ''; });
    _modeCtrl.forward();
  }

  void _goToMain() => Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const MainScreen(),
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ),
  );

  Future<void> _submit() async {
    setState(() { _loading = true; _error = ''; });
    await Future.delayed(const Duration(milliseconds: 500));
    String? err;
    if (_mode == _AuthMode.login) {
      err = await AuthService.login(_emailCtrl.text, _passCtrl.text);
    } else {
      if (_passCtrl.text != _pass2Ctrl.text) {
        err = 'As senhas não coincidem.';
      } else {
        err = await AuthService.register(_nameCtrl.text, _emailCtrl.text, _passCtrl.text);
      }
    }
    if (!mounted) return;
    setState(() { _loading = false; });
    if (err != null) { setState(() => _error = err!); } else { _goToMain(); }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == _AuthMode.login;
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 40),
            Center(child: Column(children: [
              EcoImage(asset: EcoAssets.standard, size: 100),
              const SizedBox(height: 12),
              const Text('EcoBadge', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kDarkGray, letterSpacing: -1)),
            ])),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(color: kDivider, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                _ModeTab(label: 'Entrar',   selected: isLogin,  onTap: () => _switchMode(_AuthMode.login)),
                _ModeTab(label: 'Cadastrar', selected: !isLogin, onTap: () => _switchMode(_AuthMode.register)),
              ]),
            ),
            const SizedBox(height: 24),
            FadeTransition(opacity: _modeFade, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!isLogin) ...[
                _FieldLabel('Nome completo'),
                const SizedBox(height: 6),
                TextField(controller: _nameCtrl, textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Seu nome',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: kMidGray, size: 20))),
                const SizedBox(height: 14),
              ],
              _FieldLabel('E-mail'),
              const SizedBox(height: 6),
              TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'seu@email.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded, color: kMidGray, size: 20))),
              const SizedBox(height: 14),
              _FieldLabel('Senha'),
              const SizedBox(height: 6),
              TextField(controller: _passCtrl, obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: isLogin ? 'Sua senha' : 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: kMidGray, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kMidGray, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  )),
              if (!isLogin) ...[
                const SizedBox(height: 14),
                _FieldLabel('Confirmar senha'),
                const SizedBox(height: 6),
                TextField(controller: _pass2Ctrl, obscureText: _obscure2,
                    decoration: InputDecoration(
                      hintText: 'Repita a senha',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: kMidGray, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kMidGray, size: 20),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                    )),
              ],
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],
            ])),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(isLogin ? 'Entrar' : 'Criar conta',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                )),
            const SizedBox(height: 14),
            Row(children: [const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('ou', style: _kCaption)),
              const Expanded(child: Divider())]),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () { AuthService.continueAsGuest(); _goToMain(); },
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: const Text('Continuar sem cadastro'),
                )),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: _kCaption.copyWith(fontSize: 12, color: kDarkGray));
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? kGreen : kMidGray,
        ))),
      ),
    ),
  );
}


// WIDGETS REUTILIZÁVEIS

class EcoImage extends StatelessWidget {
  final String asset;
  final double size;
  final BoxFit fit;
  const EcoImage({super.key, required this.asset, this.size = 80, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) => Image.asset(asset, width: size, height: size, fit: fit,
      colorBlendMode: BlendMode.multiply,
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size,
          child: const Icon(Icons.pets_rounded, color: kBrown, size: 32)));
}

class EcoBubble extends StatelessWidget {
  final String asset;
  final String message;
  final double mascotSize;
  final Color? bubbleColor;
  const EcoBubble({super.key, required this.asset, required this.message,
    this.mascotSize = 64, this.bubbleColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bubbleColor ?? kBeige.withOpacity(0.22),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBeigeDark.withOpacity(0.4)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      EcoImage(asset: asset, size: mascotSize),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Eco diz:', style: TextStyle(fontWeight: FontWeight.w700, color: kBrown, fontSize: 12)),
        const SizedBox(height: 4),
        Text(message, style: _kBody.copyWith(fontSize: 13)),
      ])),
    ]),
  );
}


// TELA PRINCIPAL — 5 abas (Scanner, Comunidade, Games, Cupons, Config)

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  late final PageController _pageCtrl;

  @override
  void initState() { super.initState(); _pageCtrl = PageController(initialPage: 0); }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  void _onTabTap(int i) =>
      _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);

  void _onPageChanged(int i) => setState(() => _idx = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageCtrl,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: const [
          ScannerScreen(),
          CommunityScreen(),
          GamesScreen(),
          CouponsScreen(),
          SettingsScreen(),   // ← nova aba
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurface, border: Border(top: BorderSide(color: kDivider)),
        ),
        child: SafeArea(top: false, child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: _onTabTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scanner'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded),      label: 'Comunidade'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_esports_rounded),  label: 'Games'),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard_rounded),   label: 'Cupons'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded),        label: 'Config'),
          ],
        )),
      ),
    );
  }
}


// TELA 1 — SCANNER

enum _ScanState { idle, scanning, loading, result, notFound, networkError }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _cam = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  _ScanState _state = _ScanState.idle;
  ProductData? _product;
  String? _lastCode;
  bool _processing = false;
  Timer? _debounce;
  Timer? _resetTimer;

  final TextEditingController _manualCtrl = TextEditingController();
  final FocusNode _manualFocus = FocusNode();
  String _manualError = '';

  late final AnimationController _lineCtrl;
  late final Animation<double> _lineAnim;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut);
    _cam.stop();
  }

  @override
  void dispose() {
    _cam.dispose(); _debounce?.cancel(); _resetTimer?.cancel();
    _lineCtrl.dispose(); _manualCtrl.dispose(); _manualFocus.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final code = capture.barcodes
        .where((b) => b.rawValue != null && b.rawValue!.isNotEmpty)
        .map((b) => b.rawValue!).firstOrNull;
    if (code == null || code == _lastCode) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetch(code));
  }

  Future<void> _fetch(String code) async {
    if (_processing) return;
    _processing = true;
    _lastCode = code;
    HapticFeedback.mediumImpact();
    setState(() => _state = _ScanState.loading);
    await _cam.stop();
    try {
      final product = await ProductService.fetch(code);
      if (!mounted) return;
      // Melhoria #6: ganho de XP ao escanear produto
      if (product != null) AuthService.addXp(product.ecoScore ~/ 10);
      setState(() {
        _product = product;
        _state = product != null ? _ScanState.result : _ScanState.notFound;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _ScanState.networkError);
    } finally {
      _processing = false;
    }
  }

  void _startScanning() {
    setState(() { _state = _ScanState.scanning; _lastCode = null; });
    _cam.start();
  }

  void _stopScanning() {
    _cam.stop();
    setState(() { _state = _ScanState.idle; _lastCode = null; });
  }

  void _resetToIdle() {
    setState(() { _state = _ScanState.idle; _product = null; _lastCode = null; });
  }

  void _submitManual() {
    final code = _manualCtrl.text.trim();
    if (code.isEmpty) { setState(() => _manualError = 'Digite um código de barras.'); return; }
    if (!RegExp(r'^\d{4,20}$').hasMatch(code)) {
      setState(() => _manualError = 'Use apenas números (4-20 dígitos).'); return;
    }
    setState(() => _manualError = '');
    _manualFocus.unfocus();
    _fetch(code);
  }

  void _runDemo() {
    final codes = ['7891910000197', '7894900011517', '7891000315507'];
    _fetch(codes[DateTime.now().millisecond % codes.length]);
  }

  @override
  Widget build(BuildContext context) => switch (_state) {
    _ScanState.idle         => _buildIdle(),
    _ScanState.scanning     => _buildCamera(),
    _ScanState.loading      => _buildLoading(),
    _ScanState.result       => _buildResult(),
    _ScanState.notFound     => _buildFeedback(mascotAsset: EcoAssets.standard,
        title: 'Produto não encontrado',
        body: 'Este código não está em nossa base de dados.\nTente escanear outro produto.'),
    _ScanState.networkError => _buildFeedback(mascotAsset: EcoAssets.standard,
        title: 'Sem conexão',
        body: 'Verifique sua internet e tente novamente.'),
  };

  Widget _buildIdle() => Scaffold(
    backgroundColor: kBackground,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Scanner', style: _kHeading),
              const SizedBox(height: 4),
              Text('Analise produtos em segundos', style: _kSubtitle.copyWith(fontSize: 13)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(40)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.eco_rounded, color: kGreen, size: 14),
                const SizedBox(width: 5),
                Text('${AuthService.xp} pts', style: _kGreenLbl),
              ]),
            ),
          ]),
          const SizedBox(height: 28),
          Center(child: Stack(alignment: Alignment.center, children: [
            Container(width: 200, height: 200, decoration: BoxDecoration(
                shape: BoxShape.circle, color: kGreen.withOpacity(0.08),
                border: Border.all(color: kGreen.withOpacity(0.15), width: 1.5))),
            EcoImage(asset: EcoAssets.standard, size: 160),
          ])),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startScanning,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                label: const Text('Ativar Scanner'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              )),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('ou digite o código', style: _kCaption)),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
          _ManualBarcodeField(
            controller: _manualCtrl, focusNode: _manualFocus,
            errorText: _manualError.isEmpty ? null : _manualError,
            onSubmit: _submitManual,
            onChanged: (_) { if (_manualError.isNotEmpty) setState(() => _manualError = ''); },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kDivider)),
            child: Column(children: [
              _InstructionRow(step: '1', text: 'Ative a câmera ou digite o código acima'),
              const Divider(height: 20),
              _InstructionRow(step: '2', text: 'Aponte para o código de barras do produto'),
              const Divider(height: 20),
              _InstructionRow(step: '3', text: 'Receba a análise de sustentabilidade completa'),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _runDemo,
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Usar produto de demonstração'),
              )),
          const SizedBox(height: 28),
        ]),
      ),
    ),
  );

  Widget _buildCamera() {
    final sw = MediaQuery.of(context).size.width;
    final frameW = sw * 0.72;
    const frameH = 155.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        MobileScanner(controller: _cam, onDetect: _onDetect),
        _ScanOverlay(frameWidth: frameW, frameHeight: frameH),
        Center(child: SizedBox(width: frameW - 8, height: frameH,
            child: AnimatedBuilder(animation: _lineAnim,
                builder: (_, __) => Align(
                    alignment: Alignment(0, (_lineAnim.value * 2) - 1),
                    child: Container(height: 2, decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.transparent, kGreen.withOpacity(0.9), Colors.transparent]),
                        borderRadius: BorderRadius.circular(2))))))),
        Positioned(top: 0, left: 0, right: 0,
            child: SafeArea(child: _CamTopBar(
                onFlash: () => _cam.toggleTorch(),
                onFlip:  () => _cam.switchCamera(),
                onStop:  _stopScanning))),
        Positioned(bottom: 0, left: 0, right: 0,
            child: _CamBottomBar(onStop: _stopScanning, onDemo: _runDemo)),
      ]),
    );
  }

  Widget _buildLoading() => Scaffold(
    backgroundColor: kBackground,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      EcoImage(asset: EcoAssets.standard, size: 90),
      const SizedBox(height: 22),
      const SizedBox(width: 26, height: 26,
          child: CircularProgressIndicator(color: kGreen, strokeWidth: 2.5)),
      const SizedBox(height: 14),
      const Text('Buscando produto...', style: _kSubtitle),
    ])),
  );

  Widget _buildResult() {
    final p = _product!;
    final mascotAsset = p.ecoScore >= 70 ? EcoAssets.medal : EcoAssets.standard;
    final ecoMsg = p.ecoScore >= 80
        ? 'Ótima escolha! Este produto tem excelente pontuação ambiental.'
        : p.ecoScore >= 60
        ? 'Boa escolha. Lembre-se de descartar a embalagem corretamente.'
        : 'Existem alternativas mais sustentáveis. Considere opções orgânicas.';
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(child: Column(children: [
        _BackBar(label: 'Análise do Produto', onBack: _resetToIdle),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ProductCard(product: p),
            const SizedBox(height: 12),
            _ProductOverviewCard(product: p),
            const SizedBox(height: 12),
            _EcoScoreCard(score: p.ecoScore),
            const SizedBox(height: 12),
            _RecyclingCard(product: p),
            const SizedBox(height: 12),
            if (p.scoreReasons.isNotEmpty) ...[_ScoreBreakdownCard(product: p), const SizedBox(height: 12)],
            if (p.hasDetails) ...[_DetailsCard(product: p), const SizedBox(height: 12)],
            EcoBubble(asset: mascotAsset, message: ecoMsg, mascotSize: 64),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: _startScanning,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Escanear outro produto'))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity,
                child: OutlinedButton(onPressed: _resetToIdle, child: const Text('Voltar ao início'))),
          ]),
        )),
      ])),
    );
  }

  Widget _buildFeedback({required String mascotAsset, required String title, required String body}) =>
      Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(child: Column(children: [
          _BackBar(label: 'Scanner', onBack: _resetToIdle),
          Expanded(child: Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              EcoImage(asset: mascotAsset, size: 100),
              const SizedBox(height: 20),
              Text(title, style: _kTitle, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(body, style: _kSubtitle, textAlign: TextAlign.center),
              const SizedBox(height: 28),
              ElevatedButton.icon(onPressed: _startScanning,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Tentar novamente')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: _resetToIdle, child: const Text('Voltar ao início')),
            ]),
          ))),
        ])),
      );
}

// ─ Widgets do Scanner
class _ManualBarcodeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;
  const _ManualBarcodeField({required this.controller, required this.focusNode,
    required this.onSubmit, required this.onChanged, this.errorText});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Código de barras', style: _kCaption.copyWith(fontSize: 12, color: kDarkGray)),
    const SizedBox(height: 6),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: TextField(controller: controller, focusNode: focusNode,
          onChanged: onChanged, onSubmitted: (_) => onSubmit(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 20,
          decoration: InputDecoration(
              hintText: 'Ex: 7891910000197',
              hintStyle: _kCaption.copyWith(fontSize: 13),
              errorText: errorText, counterText: '',
              prefixIcon: const Icon(Icons.tag_rounded, color: kMidGray, size: 20)))),
      const SizedBox(width: 10),
      SizedBox(height: 50, child: ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Buscar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
    ]),
  ]);
}

class _InstructionRow extends StatelessWidget {
  final String step, text;
  const _InstructionRow({required this.step, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 28, height: 28,
        decoration: BoxDecoration(color: kGreen.withOpacity(0.12), shape: BoxShape.circle),
        child: Center(child: Text(step, style: const TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 13)))),
    const SizedBox(width: 12),
    Expanded(child: Text(text, style: _kBody.copyWith(fontSize: 13))),
  ]);
}

class _ScanOverlay extends StatelessWidget {
  final double frameWidth, frameHeight;
  const _ScanOverlay({required this.frameWidth, required this.frameHeight});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _OverlayPainter(frameWidth, frameHeight));
}

class _OverlayPainter extends CustomPainter {
  final double fw, fh;
  _OverlayPainter(this.fw, this.fh);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final l = cx - fw/2, t = cy - fh/2, r = cx + fw/2, b = cy + fh/2;
    const rad = 12.0;
    canvas.drawPath(Path.combine(PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, const Radius.circular(rad))),
    ), Paint()..color = Colors.black.withOpacity(0.58));
    const cLen = 24.0;
    final cp = Paint()..color = kGreen..strokeWidth = 3.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y + dy*rad), Offset(x, y + dy*cLen), cp);
      canvas.drawLine(Offset(x + dx*rad, y), Offset(x + dx*cLen, y), cp);
    }
    corner(l, t, 1, 1); corner(r, t, -1, 1); corner(l, b, 1, -1); corner(r, b, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _CamTopBar extends StatelessWidget {
  final VoidCallback onFlash, onFlip, onStop;
  const _CamTopBar({required this.onFlash, required this.onFlip, required this.onStop});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(children: [
      _GlassBtn(icon: Icons.close_rounded, onTap: onStop),
      const SizedBox(width: 8),
      const Text('EcoBadge', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
      const Spacer(),
      _GlassBtn(icon: Icons.flash_on_rounded, onTap: onFlash),
      const SizedBox(width: 6),
      _GlassBtn(icon: Icons.flip_camera_android_rounded, onTap: onFlip),
    ]),
  );
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withOpacity(0.14),
    borderRadius: BorderRadius.circular(40),
    child: InkWell(borderRadius: BorderRadius.circular(40), onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white, size: 22))),
  );
}

class _CamBottomBar extends StatelessWidget {
  final VoidCallback onStop, onDemo;
  const _CamBottomBar({required this.onStop, required this.onDemo});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.bottomCenter, end: Alignment.topCenter,
        colors: [Colors.black.withOpacity(0.70), Colors.transparent])),
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
    child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Aponte a câmera para o código de barras',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: onStop,
            icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Colors.white70),
            label: const Text('Parar câmera', style: TextStyle(color: Colors.white70, fontSize: 13)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12)))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: onDemo,
            icon: const Icon(Icons.science_outlined, size: 16, color: Colors.white60),
            label: const Text('Demonstração', style: TextStyle(color: Colors.white60, fontSize: 13)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12)))),
      ]),
    ])),
  );
}

class _BackBar extends StatelessWidget {
  final String label;
  final VoidCallback onBack;
  const _BackBar({required this.label, required this.onBack});

  @override
  Widget build(BuildContext context) => Row(children: [
    IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: kDarkGray)),
    Text(label, style: _kTitle),
  ]);
}

// ─ Cards de resultado do produto
class _ProductCard extends StatelessWidget {
  final ProductData product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(10),
            child: product.imageUrl != null
                ? Image.network(product.imageUrl!, width: 70, height: 70, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imgFallback())
                : _imgFallback()),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: _kTitle),
          if (product.brand.isNotEmpty) ...[const SizedBox(height: 4), Text(product.brand, style: _kSubtitle)],
          const SizedBox(height: 8),
          _Chip(label: product.category),
        ])),
      ]),
      if (product.quantity.isNotEmpty || product.countries.isNotEmpty) ...[
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 10),
        if (product.quantity.isNotEmpty) _KV('Quantidade', product.quantity),
        if (product.countries.isNotEmpty) ...[const SizedBox(height: 6), _KV('Origem', product.countries)],
      ],
    ])),
  );

  Widget _imgFallback() => Container(width: 70, height: 70,
      decoration: BoxDecoration(color: kBeige.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.inventory_2_outlined, color: kBrown, size: 30));
}

class _ProductOverviewCard extends StatelessWidget {
  final ProductData product;
  const _ProductOverviewCard({required this.product});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Visão Geral', style: _kTitle),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _OverviewItem(icon: Icons.category_outlined, label: 'Tipo',
            value: product.productType.isNotEmpty ? product.productType : product.category)),
        _vDivider(),
        Expanded(child: _OverviewItem(icon: Icons.eco_outlined, label: 'Impacto',
            value: product.resolvedImpact, valueColor: _impactColor(product.resolvedImpact))),
        _vDivider(),
        Expanded(child: _OverviewItem(icon: Icons.thumb_up_alt_outlined, label: 'Nível',
            value: product.resolvedSustainability, valueColor: _sustainColor(product.ecoScore))),
      ]),
      if (product.countries.isNotEmpty) ...[
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 16, color: kMidGray),
          const SizedBox(width: 6),
          Text('Origem: ', style: _kCaption),
          Text(product.countries, style: _kBody.copyWith(fontSize: 12)),
        ]),
      ],
    ])),
  );

  Widget _vDivider() => Container(width: 1, height: 48, color: kDivider, margin: const EdgeInsets.symmetric(horizontal: 4));
  Color _impactColor(String i) => i == 'Baixo' ? Colors.green.shade600 : i == 'Médio' ? Colors.orange.shade600 : Colors.red.shade600;
  Color _sustainColor(int s) => s >= 80 ? Colors.green.shade600 : s >= 60 ? kGreenDark : s >= 40 ? Colors.orange.shade600 : Colors.red.shade600;
}

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _OverviewItem({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, color: kGreen, size: 20), const SizedBox(height: 6),
    Text(label, style: _kCaption), const SizedBox(height: 3),
    Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor ?? kDarkGray),
        textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
  ]);
}

class _EcoScoreCard extends StatelessWidget {
  final int score;
  const _EcoScoreCard({required this.score});

  Color get _color => score >= 80 ? const Color(0xFF4CAF50) : score >= 60 ? kGreen : score >= 40 ? Colors.orange : const Color(0xFFE53935);
  String get _grade => score >= 80 ? 'A' : score >= 65 ? 'B' : score >= 50 ? 'C' : score >= 35 ? 'D' : 'E';
  String get _desc  => score >= 80 ? 'Excelente' : score >= 65 ? 'Bom' : score >= 50 ? 'Regular' : score >= 35 ? 'Ruim' : 'Crítico';

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Pontuação de Sustentabilidade', style: _kTitle),
      const SizedBox(height: 14),
      Row(children: [
        Container(width: 62, height: 62, decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(_grade, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_desc, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _color)),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: score / 100, backgroundColor: kDivider,
                  valueColor: AlwaysStoppedAnimation<Color>(_color), minHeight: 10)),
          const SizedBox(height: 5),
          Text('$score / 100 pontos', style: _kCaption),
        ])),
      ]),
      const SizedBox(height: 14), const Divider(height: 1), const SizedBox(height: 10),
      Row(children: [
        const Icon(Icons.add_circle_outline_rounded, color: kGreen, size: 18), const SizedBox(width: 6),
        Text('+${(score / 10).round()} Ecopoints adicionados', style: _kGreenLbl),
      ]),
    ])),
  );
}

class _RecyclingCard extends StatelessWidget {
  final ProductData product;
  const _RecyclingCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final info = product.recyclingInfo;
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.recycling_rounded, color: kGreen, size: 18),
          const SizedBox(width: 8),
          const Text('Informações de Reciclagem', style: _kTitle),
        ]),
        const SizedBox(height: 14),
        _RecyclingStatus(isRecyclable: info.isRecyclable),
        const SizedBox(height: 14),
        if (info.recyclableParts.isNotEmpty) ...[
          Text('O que pode ser reciclado:', style: _kCaption.copyWith(fontSize: 12, color: kDarkGray)),
          const SizedBox(height: 8),
          ...info.recyclableParts.map((p) => _RecyclingPartRow(part: p, recyclable: true)),
        ],
        if (info.nonRecyclableParts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('O que NÃO pode ser reciclado:', style: _kCaption.copyWith(fontSize: 12, color: kDarkGray)),
          const SizedBox(height: 8),
          ...info.nonRecyclableParts.map((p) => _RecyclingPartRow(part: p, recyclable: false)),
        ],
        if (info.disposalInstruction.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: kBeige.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, color: kBrown, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(info.disposalInstruction, style: _kBody.copyWith(fontSize: 12, color: kDarkGray))),
            ]),
          ),
        ],
      ])),
    );
  }
}

class _RecyclingStatus extends StatelessWidget {
  final bool isRecyclable;
  const _RecyclingStatus({required this.isRecyclable});

  @override
  Widget build(BuildContext context) {
    final color = isRecyclable ? Colors.green.shade600 : Colors.orange.shade700;
    final bg    = isRecyclable ? Colors.green.withOpacity(0.08) : Colors.orange.withOpacity(0.08);
    final icon  = isRecyclable ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
    final label = isRecyclable ? 'Produto reciclável' : 'Reciclagem parcial ou especial';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 20), const SizedBox(width: 10),
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
      ]),
    );
  }
}

class _RecyclingPartRow extends StatelessWidget {
  final String part;
  final bool recyclable;
  const _RecyclingPartRow({required this.part, required this.recyclable});

  @override
  Widget build(BuildContext context) {
    final color = recyclable ? Colors.green.shade600 : Colors.red.shade500;
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
      Icon(recyclable ? Icons.recycling_rounded : Icons.do_not_disturb_alt_rounded, size: 15, color: color),
      const SizedBox(width: 8),
      Text(part, style: _kBody.copyWith(fontSize: 13, color: kDarkGray)),
    ]));
  }
}

class _ScoreBreakdownCard extends StatelessWidget {
  final ProductData product;
  const _ScoreBreakdownCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final positives = product.scoreReasons.where((r) => r.positive).toList();
    final negatives = product.scoreReasons.where((r) => !r.positive).toList();
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.analytics_outlined, color: kGreen, size: 18), const SizedBox(width: 8),
          const Text('Por que essa pontuação?', style: _kTitle),
        ]),
        const SizedBox(height: 6),
        Text('Fatores que influenciaram o Ecopoint:', style: _kCaption.copyWith(fontSize: 12)),
        const SizedBox(height: 14),
        if (positives.isNotEmpty) ...[
          _ReasonGroupLabel(icon: Icons.add_circle_outline_rounded, label: 'Pontos positivos', color: Colors.green.shade600),
          const SizedBox(height: 8),
          ...positives.map((r) => _ReasonRow(reason: r)),
        ],
        if (positives.isNotEmpty && negatives.isNotEmpty) const SizedBox(height: 10),
        if (negatives.isNotEmpty) ...[
          _ReasonGroupLabel(icon: Icons.remove_circle_outline_rounded, label: 'Pontos negativos', color: Colors.red.shade500),
          const SizedBox(height: 8),
          ...negatives.map((r) => _ReasonRow(reason: r)),
        ],
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: kBeige.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
            child: Text('A pontuação é calculada com base em dados ambientais, embalagem e certificações.',
                style: _kCaption.copyWith(fontSize: 11, color: kMidGray))),
      ])),
    );
  }
}

class _ReasonGroupLabel extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _ReasonGroupLabel({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 15), const SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
  ]);
}

class _ReasonRow extends StatelessWidget {
  final ScoreReason reason;
  const _ReasonRow({required this.reason});

  @override
  Widget build(BuildContext context) {
    final color   = reason.positive ? Colors.green.shade600 : Colors.red.shade500;
    final bgColor = reason.positive ? Colors.green.withOpacity(0.06) : Colors.red.withOpacity(0.05);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(reason.icon, size: 16, color: color), const SizedBox(width: 10),
        Expanded(child: Text(reason.label, style: _kBody.copyWith(fontSize: 13, color: kDarkGray))),
        Icon(reason.positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: color),
      ]),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final ProductData product;
  const _DetailsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <_DRow>[
      if (product.packaging.isNotEmpty)
        _DRow(icon: Icons.inventory_2_outlined, label: 'Embalagem', value: product.packaging),
      if (product.ingredients.isNotEmpty)
        _DRow(icon: Icons.list_alt_rounded, label: 'Ingredientes', value: product.ingredients),
      for (final l in product.labels)
        _DRow(icon: Icons.verified_outlined, label: 'Certificação', value: l),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Detalhes do Produto', style: _kTitle), const SizedBox(height: 12),
      for (int i = 0; i < rows.length; i++) ...[
        _DetailRow(row: rows[i]),
        if (i < rows.length - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
      ],
    ])));
  }
}

class _DRow { final IconData icon; final String label, value;
const _DRow({required this.icon, required this.label, required this.value}); }

class _DetailRow extends StatelessWidget {
  final _DRow row;
  const _DetailRow({required this.row});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(row.icon, size: 18, color: kGreen), const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(row.label, style: _kCaption), const SizedBox(height: 2),
      Text(row.value, style: _kBody.copyWith(fontSize: 13)),
    ])),
  ]);
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(40)),
      child: Text(label, style: _kGreenLbl));
}

class _KV extends StatelessWidget {
  final String k, v;
  const _KV(this.k, this.v);

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 86, child: Text(k, style: _kCaption)),
    Expanded(child: Text(v, style: _kBody.copyWith(fontSize: 13))),
  ]);
}


// MODELOS: RecyclingInfo, ProductData, ScoreReason

class RecyclingInfo {
  final bool isRecyclable;
  final List<String> recyclableParts;
  final List<String> nonRecyclableParts;
  final String disposalInstruction;
  const RecyclingInfo({required this.isRecyclable, required this.recyclableParts,
    required this.nonRecyclableParts, required this.disposalInstruction});
}

class ScoreReason {
  final String label;
  final bool positive;
  final IconData icon;
  const ScoreReason({required this.label, required this.positive, required this.icon});
}

class ProductData {
  final String name, brand, category, quantity, packaging, ingredients, countries;
  final List<String> labels;
  final int ecoScore;
  final String? imageUrl;
  final String environmentalImpact, productType, sustainabilityLevel;
  final List<ScoreReason> scoreReasons;
  final RecyclingInfo? recyclingData;

  const ProductData({
    required this.name, required this.brand, required this.category,
    required this.ecoScore, required this.quantity, required this.packaging,
    required this.ingredients, required this.labels, required this.countries,
    required this.imageUrl,
    this.environmentalImpact = '', this.productType = '', this.sustainabilityLevel = '',
    this.scoreReasons = const [], this.recyclingData,
  });

  bool get hasDetails => packaging.isNotEmpty || ingredients.isNotEmpty || labels.isNotEmpty;

  String get resolvedImpact {
    if (environmentalImpact.isNotEmpty) return environmentalImpact;
    if (ecoScore >= 80) return 'Baixo';
    if (ecoScore >= 55) return 'Médio';
    return 'Alto';
  }

  String get resolvedSustainability {
    if (sustainabilityLevel.isNotEmpty) return sustainabilityLevel;
    if (ecoScore >= 80) return 'Muito sustentável';
    if (ecoScore >= 65) return 'Sustentável';
    if (ecoScore >= 50) return 'Moderado';
    if (ecoScore >= 35) return 'Pouco sustentável';
    return 'Não sustentável';
  }

  RecyclingInfo get recyclingInfo => recyclingData ?? _inferRecycling();

  RecyclingInfo _inferRecycling() {
    final pkg = packaging.toLowerCase();
    if (pkg.contains('biodegradável') || pkg.contains('biodegradable'))
      return const RecyclingInfo(isRecyclable: true, recyclableParts: ['Embalagem (compostável)', 'Material interno'],
          nonRecyclableParts: [], disposalInstruction: 'Descarte na compostagem ou em lixo orgânico.');
    if (pkg.contains('alumínio') || pkg.contains('aluminum'))
      return const RecyclingInfo(isRecyclable: true, recyclableParts: ['Lata de alumínio'],
          nonRecyclableParts: ['Tampa de plástico (se houver)'],
          disposalInstruction: 'Deposite no contêiner amarelo (metal). Lave e amasse antes de descartar.');
    if (pkg.contains('pet') || pkg.contains('plástico') || pkg.contains('plastic'))
      return const RecyclingInfo(isRecyclable: true, recyclableParts: ['Garrafa/embalagem PET', 'Tampa (PP)'],
          nonRecyclableParts: ['Rótulo de papel (remover antes)'],
          disposalInstruction: 'Deposite no contêiner vermelho (plástico). Esvazie e enxágue antes.');
    if (pkg.contains('papel') || pkg.contains('paper') || pkg.contains('papelão'))
      return const RecyclingInfo(isRecyclable: true, recyclableParts: ['Embalagem de papel/papelão'],
          nonRecyclableParts: ['Papel plastificado ou engordurado'],
          disposalInstruction: 'Deposite no contêiner azul (papel). Mantenha seco e sem resíduos.');
    if (pkg.contains('vidro') || pkg.contains('glass'))
      return const RecyclingInfo(isRecyclable: true, recyclableParts: ['Recipiente de vidro'],
          nonRecyclableParts: ['Tampa metálica (descarte separado no amarelo)'],
          disposalInstruction: 'Deposite no contêiner verde (vidro). Esvazie e higienize antes.');
    return RecyclingInfo(isRecyclable: ecoScore >= 60,
        recyclableParts: ecoScore >= 60 ? ['Verifique o símbolo de reciclagem na embalagem'] : [],
        nonRecyclableParts: ecoScore < 60 ? ['Embalagem não reciclável ou material misto'] : [],
        disposalInstruction: 'Consulte os símbolos na embalagem para orientação de descarte correto.');
  }
}

class ProductService {
  static const _api = 'https://world.openfoodfacts.org/api/v2/product';

  // Fallback local com dados enriquecidos
  static const Map<String, ProductData> _local = {
    '7891910000197': ProductData(
      name: 'Arroz Integral Orgânico', brand: 'Camil Orgânico',
      category: 'Cereais', ecoScore: 91, quantity: '1 kg',
      packaging: 'Embalagem biodegradável', countries: 'Brasil',
      ingredients: 'Arroz integral orgânico', labels: ['Orgânico Brasil', 'IBD'], imageUrl: null,
      productType: 'Alimento', environmentalImpact: 'Baixo', sustainabilityLevel: 'Muito sustentável',
      scoreReasons: [
        ScoreReason(label: 'Produto orgânico certificado', positive: true, icon: Icons.eco_rounded),
        ScoreReason(label: 'Embalagem biodegradável',     positive: true, icon: Icons.recycling_rounded),
        ScoreReason(label: 'Produção nacional',           positive: true, icon: Icons.flag_rounded),
        ScoreReason(label: 'Sem agrotóxicos',             positive: true, icon: Icons.spa_rounded),
      ],
      recyclingData: RecyclingInfo(isRecyclable: true,
          recyclableParts: ['Embalagem biodegradável (compostável)'], nonRecyclableParts: [],
          disposalInstruction: 'Descarte no lixo orgânico ou compostagem.'),
    ),
    '7894900011517': ProductData(
      name: 'Refrigerante Cola', brand: 'Coca-Cola',
      category: 'Bebidas', ecoScore: 42, quantity: '350 ml',
      packaging: 'Lata de alumínio reciclável', countries: 'Brasil',
      ingredients: 'Água gaseificada, açúcar, extrato de noz de cola, caramelo, ácido fosfórico, cafeína',
      labels: [], imageUrl: null,
      productType: 'Bebida', environmentalImpact: 'Médio', sustainabilityLevel: 'Moderado',
      scoreReasons: [
        ScoreReason(label: 'Embalagem de alumínio reciclável',  positive: true,  icon: Icons.recycling_rounded),
        ScoreReason(label: 'Alto teor de açúcar',               positive: false, icon: Icons.warning_amber_rounded),
        ScoreReason(label: 'Aditivos artificiais',              positive: false, icon: Icons.science_outlined),
        ScoreReason(label: 'Alta pegada de carbono industrial', positive: false, icon: Icons.factory_outlined),
      ],
      recyclingData: RecyclingInfo(isRecyclable: true,
          recyclableParts: ['Lata de alumínio (100% reciclável)'], nonRecyclableParts: ['Anel de abertura'],
          disposalInstruction: 'Deposite no contêiner amarelo (metal). Amasse a lata antes de descartar.'),
    ),
    '7891000315507': ProductData(
      name: 'Água Mineral Natural', brand: 'Crystal',
      category: 'Bebidas', ecoScore: 80, quantity: '500 ml',
      packaging: 'Garrafa PET reciclável', countries: 'Brasil',
      ingredients: 'Água mineral natural', labels: ['ISO 14001'], imageUrl: null,
      productType: 'Bebida', environmentalImpact: 'Baixo', sustainabilityLevel: 'Sustentável',
      scoreReasons: [
        ScoreReason(label: 'Produto natural, sem aditivos',    positive: true,  icon: Icons.water_drop_rounded),
        ScoreReason(label: 'Certificação ambiental ISO 14001', positive: true,  icon: Icons.verified_rounded),
        ScoreReason(label: 'Garrafa PET — descarte exigido',   positive: false, icon: Icons.delete_outline_rounded),
      ],
      recyclingData: RecyclingInfo(isRecyclable: true,
          recyclableParts: ['Garrafa PET', 'Tampa de polipropileno (PP)'],
          nonRecyclableParts: ['Rótulo plástico (remova antes)'],
          disposalInstruction: 'Esvazie, remova o rótulo e amasse. Contêiner vermelho (plástico).'),
    ),
  };

  /// Busca produto na API Open Food Facts v2.
  /// Em caso de falha (sem rede, timeout, produto não encontrado),
  /// cai silenciosamente para o fallback local.
  static Future<ProductData?> fetch(String barcode) async {
    // 1. Tenta API real
    try {
      final uri = Uri.parse('$_api/$barcode'
          '?fields=product_name,product_name_pt,brands,categories,ecoscore_score,'
          'nutriscore_grade,quantity,packaging,ingredients_text_pt,ingredients_text,'
          'labels_tags,countries,image_url');

      final res = await http.get(uri, headers: {'User-Agent': 'EcoBadge/6.0'})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        // API v2: status 0 = not found, 1 = found
        if (json['status'] == 1 || json['status'] == 'success') {
          final product = json['product'] as Map<String, dynamic>?;
          if (product != null && product['product_name'] != null) {
            return _parse(product);
          }
        }
      }
    } on TimeoutException {
      // Timeout — usar fallback silenciosamente
    } catch (_) {
      // Sem rede ou erro inesperado
    }

    // 2. Fallback local
    return _local[barcode];
  }

  static ProductData _parse(Map<String, dynamic> p) {
    // ─ EcoScore
    int eco = 50;
    final raw = p['ecoscore_score'];
    if (raw != null && raw is num) {
      eco = raw.toInt().clamp(0, 100);
    } else {
      final ns = (p['nutriscore_grade'] as String? ?? '').toUpperCase();
      eco = switch (ns) { 'A' => 85, 'B' => 70, 'C' => 55, 'D' => 40, 'E' => 25, _ => 50 };
    }

    // ─ Categoria limpa
    String cat = 'Produto alimentar';
    final cats = p['categories'] as String? ?? '';
    if (cats.isNotEmpty) {
      final parts = cats.split(',');
      cat = parts.last.trim().replaceAll(RegExp(r'^[a-z]{2}:'), '');
      if (cat.isEmpty || cat.length > 35) {
        cat = parts.first.trim().replaceAll(RegExp(r'^[a-z]{2}:'), '');
      }
    }

    // ─ Certificações (máx. 3, limpas)
    final lTags = p['labels_tags'] as List<dynamic>? ?? [];
    final labels = lTags
        .map((l) => l.toString().replaceAll(RegExp(r'^[a-z]{2}:'), '').replaceAll('-', ' ').trim())
        .where((l) => l.isNotEmpty && l.length < 40)
        .take(3).toList();

    final ptype   = _inferType(cat);
    final pkg     = _s(p['packaging']);
    final reasons = _buildReasons(eco: eco, packaging: pkg, labels: labels,
        hasOrganic: labels.any((l) => l.toLowerCase().contains('orgân') || l.toLowerCase().contains('organic')));

    return ProductData(
      name:        _clean(p['product_name'] ?? p['product_name_pt'] ?? ''),
      brand:       _s(p['brands']),
      category:    cat,
      ecoScore:    eco,
      quantity:    _s(p['quantity']),
      packaging:   pkg,
      ingredients: _s(p['ingredients_text_pt'] ?? p['ingredients_text']),
      labels:      labels,
      countries:   _s(p['countries']),
      imageUrl:    p['image_url'] as String?,
      productType: ptype,
      scoreReasons: reasons,
    );
  }

  static String _inferType(String category) {
    final c = category.toLowerCase();
    if (c.contains('bebid') || c.contains('drink') || c.contains('suco')) return 'Bebida';
    if (c.contains('laticín') || c.contains('dairy') || c.contains('leite')) return 'Laticínio';
    if (c.contains('higien') || c.contains('cosmet') || c.contains('shampoo')) return 'Higiene';
    if (c.contains('limpez') || c.contains('clean')  || c.contains('deterg')) return 'Limpeza';
    if (c.contains('snack')  || c.contains('biscoito') || c.contains('salgad')) return 'Snack';
    return 'Alimento';
  }

  static List<ScoreReason> _buildReasons({required int eco, required String packaging,
    required List<String> labels, required bool hasOrganic}) {
    final reasons = <ScoreReason>[];
    final pkg = packaging.toLowerCase();
    if (hasOrganic) reasons.add(const ScoreReason(label: 'Produto orgânico certificado', positive: true, icon: Icons.eco_rounded));
    if (pkg.contains('biodegradável') || pkg.contains('biodegradable'))
      reasons.add(const ScoreReason(label: 'Embalagem biodegradável', positive: true, icon: Icons.recycling_rounded));
    else if (pkg.contains('reciclável') || pkg.contains('recyclable') || pkg.contains('alumínio'))
      reasons.add(const ScoreReason(label: 'Embalagem reciclável', positive: true, icon: Icons.recycling_rounded));
    else if (pkg.isNotEmpty)
      reasons.add(const ScoreReason(label: 'Embalagem não reciclável', positive: false, icon: Icons.delete_outline_rounded));
    if (labels.isNotEmpty)
      reasons.add(ScoreReason(label: 'Possui ${labels.length} certificação(ões)', positive: true, icon: Icons.verified_rounded));
    if (eco < 40) reasons.add(const ScoreReason(label: 'Alto impacto ambiental de produção', positive: false, icon: Icons.factory_outlined));
    if (eco < 55 && !hasOrganic) reasons.add(const ScoreReason(label: 'Sem certificação orgânica', positive: false, icon: Icons.cancel_outlined));
    if (reasons.isEmpty) reasons.add(eco >= 70
        ? const ScoreReason(label: 'Boas práticas de produção', positive: true, icon: Icons.thumb_up_outlined)
        : const ScoreReason(label: 'Dados ambientais limitados', positive: false, icon: Icons.info_outline_rounded));
    return reasons;
  }

  static String _s(dynamic v)     => (v ?? '').toString().trim();
  static String _clean(dynamic v) {
    final s = _s(v);
    return s.isEmpty ? 'Produto sem nome' : s;
  }
}


// TELA 2 — COMUNIDADE

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _activeFilter = 'Tudo';
  final List<String> _filters = ['Tudo', 'Dica', 'Novidade', 'Curiosidade', 'Ação', 'Experiência'];

  final List<_Post> _posts = [
    _Post(author: 'Ana Clara', initials: 'AC', color: kGreen, time: '2h', tag: 'Dica', tagColor: kGreen,
        body: 'Comecei a fazer compostagem em casa esta semana. Cascas de legumes, borra de café e folhas secas — tudo vira adubo em poucas semanas. Altamente recomendo!',
        likes: 34, comments: [
          _Comment('Pedro M.', 'Eu faço isso há 2 anos! Incrível como reduz o lixo.', '1h'),
          _Comment('Luiza S.', 'Qual recipiente você usa para guardar?', '45min'),
        ]),
    _Post(author: 'EmanuelFo', initials: 'EF', color: kBrown, time: '5h', tag: 'Novidade', tagColor: kBrown,
        body: 'Produtos com certificação orgânica agora valem pontuação dobrada esta semana. Escaneie mais para ganhar mais Ecopoints!',
        likes: 127, comments: [_Comment('Maria L.', 'Ótima novidade! Já escaneei 3 hoje.', '4h')]),
    _Post(author: 'Treetech', initials: 'TT', color: kLightBrown, time: '1d', tag: 'Curiosidade', tagColor: kLightBrown,
        body: 'Uma sacola plástica convencional leva até 400 anos para se decompor. Substituir por ecobags é uma das mudanças mais simples e impactantes possíveis.',
        likes: 89, comments: [
          _Comment('Carlos R.', 'Uso ecobag há 5 anos e nunca mais voltei ao plástico!', '22h'),
          _Comment('Ana Paula', 'Tem alguma marca de ecobag que você recomenda?', '18h'),
        ]),
    _Post(author: 'CH', initials: 'CH', color: Colors.blueGrey, time: '2d', tag: 'Ação', tagColor: Colors.blueGrey,
        body: 'Participei da limpeza da praia hoje — recolhemos mais de 50 kg de resíduos em 3 horas. É incrível o que um grupo pequeno consegue fazer.',
        likes: 214, comments: [
          _Comment('Eco Team', 'Fantástico! Qual praia foi?', '1d'),
          _Comment('Fernanda P.', 'Participo na próxima! Como me inscrevo?', '20h'),
        ]),
    _Post(author: 'João Sousas', initials: 'JS', color: Colors.amber.shade700, time: '3d', tag: 'Experiência', tagColor: Colors.amber.shade700,
        body: 'Instalei painéis solares no ano passado e a conta de energia caiu 80%. O retorno do investimento acontece em torno de 4 anos.',
        likes: 156, comments: [_Comment('Marcos A.', 'Qual empresa instalou? Ficou satisfeito?', '2d')]),
  ];

  List<_Post> get _filteredPosts => _activeFilter == 'Tudo'
      ? _posts : _posts.where((p) => p.tag == _activeFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _CommunityHeader()),
        SliverAppBar(
          pinned: true, backgroundColor: kBackground, elevation: 0,
          automaticallyImplyLeading: false, toolbarHeight: 0,
          bottom: PreferredSize(preferredSize: const Size.fromHeight(52),
              child: Column(children: [
                SizedBox(height: 44, child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final active = f == _activeFilter;
                    return GestureDetector(
                        onTap: () => setState(() => _activeFilter = f),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                color: active ? kGreen : kSurface,
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(color: active ? kGreen : kDivider)),
                            child: Text(f, style: TextStyle(fontSize: 12,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                color: active ? Colors.white : kMidGray))));
                  },
                )),
                const Divider(height: 8),
              ])),
        ),
        _filteredPosts.isEmpty
            ? SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.filter_list_off_rounded, color: kMidGray, size: 40),
          const SizedBox(height: 12),
          Text('Nenhum post com o filtro "$_activeFilter"', style: _kSubtitle),
        ])))
            : SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                if (i.isOdd) return const SizedBox(height: 10);
                final idx = i ~/ 2;
                return _PostCard(
                  post: _filteredPosts[idx],
                  onLike: () => setState(() => _filteredPosts[idx].toggleLike()),
                  onShowComments: () => _showComments(context, _filteredPosts[idx]),
                );
              },
              childCount: _filteredPosts.length * 2 - 1,
            ))),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewPostDialog(context),
        backgroundColor: kGreen, elevation: 2,
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
        label: const Text('Publicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showComments(BuildContext context, _Post post) => showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(post: post));

  void _showNewPostDialog(BuildContext context) {
    final ctrl = TextEditingController();
    String? selectedTag = 'Dica';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        title: const Text('Nova publicação', style: _kTitle),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Categoria', style: _kCaption), const SizedBox(height: 6),
          DropdownButtonFormField<String>(value: selectedTag,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: ['Dica', 'Curiosidade', 'Ação', 'Experiência']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setDlg(() => selectedTag = v)),
          const SizedBox(height: 14),
          const Text('Conteúdo', style: _kCaption), const SizedBox(height: 6),
          TextField(controller: ctrl, maxLines: 3, maxLength: 280,
              decoration: const InputDecoration(hintText: 'Compartilhe sua experiência...')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              setState(() => _posts.insert(0, _Post(
                  author: AuthService.currentUser ?? 'Você',
                  initials: (AuthService.currentUser ?? 'EU').substring(0, 2).toUpperCase(),
                  color: kGreen, time: 'agora', tag: selectedTag!, tagColor: kGreen,
                  body: ctrl.text.trim(), likes: 0, comments: [])));
            }
            Navigator.pop(ctx);
          }, child: const Text('Publicar')),
        ],
      ),
    ));
  }
}

class _CommunityHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 56, 0, 0),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Comunidade', style: _kHeading),
        const SizedBox(height: 6),
        Text('Compartilhe ideias e inspire\nquem está ao seu redor.', style: _kSubtitle.copyWith(height: 1.5)),
        const SizedBox(height: 16),
        Row(children: [_MiniStat('4.2k', 'membros'), const SizedBox(width: 16), _MiniStat('128', 'posts hoje')]),
        const SizedBox(height: 16),
      ])),
      EcoImage(asset: EcoAssets.tree, size: 140),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kGreenDark)),
    Text(label, style: _kCaption),
  ]);
}

class _Comment {
  final String author, body, time;
  _Comment(this.author, this.body, this.time);
}

class _Post {
  final String author, initials, time, tag, body;
  final Color color, tagColor;
  final List<_Comment> comments;
  int likes;
  bool liked;
  _Post({required this.author, required this.initials, required this.color,
    required this.time, required this.tag, required this.tagColor,
    required this.body, required this.likes, required this.comments, this.liked = false});
  void toggleLike() { liked = !liked; likes += liked ? 1 : -1; }
}

class _PostCard extends StatelessWidget {
  final _Post post;
  final VoidCallback onLike, onShowComments;
  const _PostCard({required this.post, required this.onLike, required this.onShowComments});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(backgroundColor: post.color, radius: 18,
            child: Text(post.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(post.author, style: _kTitle.copyWith(fontSize: 14)),
          Text('há ${post.time}', style: _kCaption),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: post.tagColor.withOpacity(0.12), borderRadius: BorderRadius.circular(40)),
            child: Text(post.tag, style: TextStyle(color: post.tagColor, fontSize: 11, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 12),
      Text(post.body, style: _kBody),
      const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 10),
      Row(children: [
        _ActBtn(icon: post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: '${post.likes}', color: post.liked ? Colors.red : kMidGray, onTap: onLike),
        const SizedBox(width: 18),
        _ActBtn(icon: Icons.chat_bubble_outline_rounded, label: '${post.comments.length}',
            color: kMidGray, onTap: onShowComments),
        const Spacer(),
        _ActBtn(icon: Icons.share_outlined, label: 'Compartilhar', color: kMidGray, onTap: () {}),
      ]),
    ])),
  );
}

class _CommentsSheet extends StatefulWidget {
  final _Post post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  late final List<_Comment> _comments;

  @override
  void initState() { super.initState(); _comments = List.from(widget.post.comments); }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _addComment() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add(_Comment(AuthService.currentUser ?? 'Você', text, 'agora'));
      widget.post.comments.add(_Comment(AuthService.currentUser ?? 'Você', text, 'agora'));
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.6, maxChildSize: 0.92, minChildSize: 0.3,
    builder: (_, scrollCtrl) => Container(
      decoration: const BoxDecoration(color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 10, bottom: 4), width: 36, height: 4,
            decoration: BoxDecoration(color: kDivider, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Text('Comentários (${_comments.length})', style: _kTitle),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context)),
            ])),
        const Divider(height: 1),
        Expanded(child: _comments.isEmpty
            ? Center(child: Text('Seja o primeiro a comentar!', style: _kSubtitle))
            : ListView.separated(controller: scrollCtrl, padding: const EdgeInsets.all(16),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (_, i) {
              final c = _comments[i];
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 16, backgroundColor: kBeige,
                    child: Text(c.author.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: kBrown, fontWeight: FontWeight.w700, fontSize: 13))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(c.author, style: _kTitle.copyWith(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text('há ${c.time}', style: _kCaption),
                  ]),
                  const SizedBox(height: 4),
                  Text(c.body, style: _kBody.copyWith(fontSize: 13)),
                ])),
              ]);
            })),
        const Divider(height: 1),
        Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
            child: Row(children: [
              CircleAvatar(radius: 16, backgroundColor: kGreen,
                  child: Text((AuthService.currentUser ?? 'EU').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _ctrl, onSubmitted: (_) => _addComment(),
                  decoration: InputDecoration(
                      hintText: 'Escreva um comentário...',
                      hintStyle: _kCaption.copyWith(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: const BorderSide(color: kDivider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: const BorderSide(color: kGreen, width: 1.5))))),
              const SizedBox(width: 8),
              Material(color: kGreen, borderRadius: BorderRadius.circular(40),
                  child: InkWell(borderRadius: BorderRadius.circular(40), onTap: _addComment,
                      child: const Padding(padding: EdgeInsets.all(10),
                          child: Icon(Icons.send_rounded, color: Colors.white, size: 18)))),
            ])),
      ]),
    ),
  );
}

class _ActBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color), const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ]));
}

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
    with SingleTickerProviderStateMixin {
  // TabController para alternar entre Quiz e Missões
  late final TabController _tabCtrl;

  // Estado do quiz
  int _qi = 0;
  int? _sel;
  bool _answered = false;
  int _quizzesCompleted = 0; // quantos quizzes finalizados nesta sessão

  static const _qs = [
    _Q('Quanto tempo uma garrafa PET leva para se decompor na natureza?',
        ['50 anos', '100 anos', '400 anos', '1.000 anos'], 2,
        'Garrafas PET podem levar até 400 anos para se decompor, liberando microplásticos ao longo desse tempo.'),
    _Q('Qual material demora mais para se decompor?',
        ['Vidro', 'Papel', 'Plástico', 'Metal'], 0,
        'O vidro pode levar mais de 1 milhão de anos para se decompor completamente.'),
    _Q('Quantos litros de água são necessários para 1 kg de carne bovina?',
        ['500 L', '2.000 L', '5.000 L', '15.000 L'], 3,
        'A produção de 1 kg de carne bovina consome cerca de 15.000 litros de água em toda a cadeia produtiva.'),
    _Q('O que é a pegada de carbono?',
        ['Resíduos no solo', 'Total de CO₂ emitido por atividades humanas', 'Reserva de carbono', 'Combustível fóssil'], 1,
        'A pegada de carbono mede o total de gases de efeito estufa emitidos direta ou indiretamente.'),
    _Q('Qual é o principal gás responsável pelo efeito estufa?',
        ['Metano (CH₄)', 'Dióxido de carbono (CO₂)', 'Óxido nitroso (N₂O)', 'Ozônio (O₃)'], 1,
        'O CO₂ é o principal gás de efeito estufa gerado pelas atividades humanas, especialmente pela queima de combustíveis fósseis.'),
    _Q('O que é compostagem?',
        ['Queima de resíduos', 'Reciclagem de plásticos', 'Decomposição de matéria orgânica', 'Filtração de água'], 2,
        'A compostagem é a decomposição controlada de matéria orgânica que gera adubo natural — ótima para o jardim!'),
  ];

  final List<_Mission> _missions = [
    _Mission('Escaneador Iniciante', 'Escanear 5 produtos', 50, Icons.qr_code_scanner_rounded,
        MissionDifficulty.easy, 3, 5),
    _Mission('Eco Escolha', 'Escanear 3 produtos com score > 80', 100, Icons.eco_rounded,
        MissionDifficulty.medium, 1, 3),
    _Mission('Membro Ativo', 'Publicar na comunidade', 30, Icons.people_alt_rounded,
        MissionDifficulty.easy, 0, 1),
    _Mission('Quiz Mestre', 'Completar 6 quizzes', 150, Icons.quiz_rounded,
        MissionDifficulty.medium, 0, 6),
    _Mission('Herói Verde', 'Atingir nível 3', 300, Icons.emoji_events_rounded,
        MissionDifficulty.hard, 0, 1),
    _Mission('Colecionador', 'Escanear 20 produtos diferentes', 200, Icons.qr_code_2_rounded,
        MissionDifficulty.hard, 5, 20),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void _select(int i) {
    if (_answered) return;
    final correct = i == _qs[_qi].ans;
    setState(() {
      _sel = i; _answered = true;
      if (correct) {
        AuthService.addXp(15);
        HapticFeedback.lightImpact();
      }
    });
  }

  void _next() {
    final wasCorrect = _sel == _qs[_qi].ans;
    setState(() {
      _qi = (_qi + 1) % _qs.length;
      _sel = null; _answered = false;
      if (wasCorrect) _quizzesCompleted++;
      // Atualiza missão Quiz Mestre
      final qm = _missions.firstWhere((m) => m.title == 'Quiz Mestre', orElse: () => _missions.last);
      if (!qm.completed && _quizzesCompleted <= qm.total) {
        qm.progressValue = _quizzesCompleted;
        if (qm.progressValue >= qm.total) {
          qm.completed = true;
          AuthService.addXp(qm.xpReward);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _LevelBanner()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeaderDelegate(
              TabBar(
                controller: _tabCtrl,
                labelColor: kGreen,
                unselectedLabelColor: kMidGray,
                indicatorColor: kGreen,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.quiz_rounded, size: 18), text: 'Quiz'),
                  Tab(icon: Icon(Icons.flag_rounded, size: 18), text: 'Missões'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildQuizTab(),
            _buildMissionsTab(),
          ],
        ),
      ),
    );
  }

  // ─ Aba Quiz
  Widget _buildQuizTab() {
    final q = _qs[_qi];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progresso do quiz
        _QuizProgressBar(current: _qi + 1, total: _qs.length, completed: _quizzesCompleted),
        const SizedBox(height: 16),
        _QuizCard(q: q, sel: _sel, answered: _answered, onSel: _select),
        if (_answered) ...[const SizedBox(height: 12), _Feedback(correct: _sel == q.ans, exp: q.exp, onNext: _next)],
        const SizedBox(height: 16),
        // Dica do Eco
        if (!_answered)
          EcoBubble(asset: EcoAssets.medal, message: 'Responda corretamente para ganhar +15 XP e subir de nível!',
              mascotSize: 52, bubbleColor: kGreenLight.withOpacity(0.25)),
      ]),
    );
  }

  // ─ Aba Missões
  Widget _buildMissionsTab() {
    final easy   = _missions.where((m) => m.difficulty == MissionDifficulty.easy).toList();
    final medium = _missions.where((m) => m.difficulty == MissionDifficulty.medium).toList();
    final hard   = _missions.where((m) => m.difficulty == MissionDifficulty.hard).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _MissionSection(title: 'Iniciante', color: Colors.green.shade600, missions: easy,
            onClaim: (m) => setState(() { m.completed = true; AuthService.addXp(m.xpReward); })),
        const SizedBox(height: 20),
        _MissionSection(title: 'Intermediário', color: Colors.orange.shade600, missions: medium,
            onClaim: (m) => setState(() { m.completed = true; AuthService.addXp(m.xpReward); })),
        const SizedBox(height: 20),
        _MissionSection(title: 'Avançado', color: Colors.red.shade600, missions: hard,
            onClaim: (m) => setState(() { m.completed = true; AuthService.addXp(m.xpReward); })),
      ]),
    );
  }
}

// ─ Banner de nível e XP
class _LevelBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final xpNext = AuthService.xpForNextLevel();
    final xpIn   = AuthService.xpInLevel;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 56, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        EcoImage(asset: EcoAssets.medal, size: 100),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nível ${AuthService.level}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 2),
          Text(AuthService.levelTitle,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 10),
          // Barra de progresso de XP
          ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: AuthService.xpProgress,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              )),
          const SizedBox(height: 4),
          Text('$xpIn / $xpNext XP para o próximo nível',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          // Total de XP
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(40)),
              child: Text('${AuthService.xp} XP total',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
        ])),
      ]),
    );
  }
}

// ─ Barra de progresso do quiz
class _QuizProgressBar extends StatelessWidget {
  final int current, total, completed;
  const _QuizProgressBar({required this.current, required this.total, required this.completed});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Pergunta $current de $total', style: _kTitle.copyWith(fontSize: 14)),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(40)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline_rounded, color: kGreen, size: 14),
              const SizedBox(width: 4),
              Text('$completed respondidas', style: _kGreenLbl),
            ])),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: current / total, backgroundColor: kDivider,
              valueColor: const AlwaysStoppedAnimation<Color>(kGreen), minHeight: 6)),
      const SizedBox(height: 6),
      Text('+15 XP por acerto', style: _kCaption),
    ])),
  );
}

// ─ Seção de missões com título e dificuldade
class _MissionSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<_Mission> missions;
  final ValueChanged<_Mission> onClaim;
  const _MissionSection({required this.title, required this.color,
    required this.missions, required this.onClaim});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 7),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      Text(title, style: _kTitle.copyWith(fontSize: 15, color: color)),
      const SizedBox(width: 6),
      Text('${missions.where((m) => m.completed).length}/${missions.length}',
          style: _kCaption),
    ]),
    const SizedBox(height: 8),
    ...missions.map((m) => Padding(padding: const EdgeInsets.only(bottom: 8),
        child: _MCard(m: m, diffColor: color,
            onClaim: (!m.completed && m.progressValue >= m.total) ? () => onClaim(m) : null))),
  ]);
}

// ─ Enumeração de dificuldade
enum MissionDifficulty { easy, medium, hard }

class _Q { final String q, exp; final List<String> opts; final int ans;
const _Q(this.q, this.opts, this.ans, this.exp); }

class _Mission {
  final String title, desc;
  final int xpReward, total;
  final IconData icon;
  final MissionDifficulty difficulty;
  int progressValue;
  bool completed;
  _Mission(this.title, this.desc, this.xpReward, this.icon, this.difficulty,
      this.progressValue, this.total, {this.completed = false});
}

// ─ Tab header sticky
class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabHeaderDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: kBackground, child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;
  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => false;
}

class _QuizCard extends StatelessWidget {
  final _Q q; final int? sel; final bool answered; final ValueChanged<int> onSel;
  const _QuizCard({required this.q, required this.sel, required this.answered, required this.onSel});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q.q, style: _kTitle.copyWith(fontSize: 15)),
      const SizedBox(height: 14),
      ...List.generate(q.opts.length, (i) {
        Color bg = kSurface, border = kDivider, tx = kDarkGray;
        if (answered) {
          if (i == q.ans) { bg = const Color(0xFFE8F5E9); border = Colors.green; tx = Colors.green.shade800; }
          else if (i == sel) { bg = const Color(0xFFFFEBEE); border = Colors.red.shade300; tx = Colors.red.shade700; }
        }
        return GestureDetector(onTap: () => onSel(i),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                child: Row(children: [
                  Container(width: 26, height: 26, decoration: BoxDecoration(color: kBeige.withOpacity(0.4), shape: BoxShape.circle),
                      child: Center(child: Text(String.fromCharCode(65 + i),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: kBrown, fontSize: 12)))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(q.opts[i], style: TextStyle(color: tx, fontSize: 14))),
                  if (answered && i == q.ans) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                  if (answered && i == sel && i != q.ans) const Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                ])));
      }),
    ])),
  );
}

class _Feedback extends StatelessWidget {
  final bool correct; final String exp; final VoidCallback onNext;
  const _Feedback({required this.correct, required this.exp, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = correct ? Colors.green : Colors.orange;
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(correct ? Icons.star_rounded : Icons.close_rounded, color: c, size: 18),
            const SizedBox(width: 6),
            Text(correct ? 'Correto! +15 XP' : 'Resposta incorreta',
                style: TextStyle(fontWeight: FontWeight.w700, color: c, fontSize: 14)),
          ]),
          const SizedBox(height: 6),
          Text(exp, style: _kBody.copyWith(fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onNext,
              style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Próxima pergunta'))),
        ]));
  }
}

// ─ Card de missão melhorado
class _MCard extends StatelessWidget {
  final _Mission m;
  final Color diffColor;
  final VoidCallback? onClaim;
  const _MCard({required this.m, required this.diffColor, this.onClaim});

  @override
  Widget build(BuildContext context) {
    final pct  = (m.progressValue / m.total).clamp(0.0, 1.0);
    final done = m.completed;
    return Card(
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Ícone com cor de dificuldade
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: diffColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(m.icon, color: diffColor, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(m.title, style: _kTitle.copyWith(fontSize: 14))),
              // Badge de status
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: done ? Colors.green.withOpacity(0.12) : diffColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(40)),
                  child: Text(done ? 'Concluída' : (m.progressValue >= m.total ? 'Resgatar' : 'Em andamento'),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: done ? Colors.green.shade700 : diffColor))),
            ]),
            const SizedBox(height: 2),
            Text(m.desc, style: _kCaption),
          ])),
        ]),
        const SizedBox(height: 12),
        // Barra de progresso
        Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, backgroundColor: kDivider,
                  valueColor: AlwaysStoppedAnimation<Color>(done ? Colors.green : diffColor), minHeight: 6))),
          const SizedBox(width: 8),
          Text('${m.progressValue}/${m.total}', style: _kCaption),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // XP da missão
          Row(children: [
            const Icon(Icons.bolt_rounded, color: kGreen, size: 16),
            const SizedBox(width: 3),
            Text('+${m.xpReward} XP', style: _kGreenLbl),
          ]),
          // Botão resgatar ou check
          if (done)
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22)
          else
            SizedBox(height: 32, child: ElevatedButton(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: onClaim != null ? kGreen : Colors.grey.shade300,
                    foregroundColor: onClaim != null ? Colors.white : kMidGray),
                child: Text(onClaim != null ? 'Resgatar' : 'Em progresso'))),
        ]),
      ])),
    );
  }
}


// TELA 4 — CUPONS

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  int _pts = 320;

  final List<_Coupon> _coupons = [
    _Coupon('10% off em produtos orgânicos', 'Hortifruti Natural', 100, '30/04/2026', Icons.eco_rounded, kGreen),
    _Coupon('Café especial grátis',          'EcoCafé',             80, '15/04/2026', Icons.local_cafe_rounded, kBrown),
    _Coupon('15% off em ecobags',            'Sustentável Store',  150, '31/05/2026', Icons.shopping_bag_outlined, kLightBrown),
    _Coupon('Consulta energia solar',        'SolarTech',          500, '30/06/2026', Icons.solar_power_rounded, Colors.amber.shade700),
    _Coupon('Plantar 1 árvore nativa',       'Refloresta Brasil',  200, '31/12/2026', Icons.park_rounded, Colors.green.shade700),
  ];

  void _redeem(_Coupon c) {
    if (_pts < c.cost) { _snack('Pontos insuficientes. Você precisa de ${c.cost} pts.', Colors.red.shade600); return; }
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Confirmar resgate'),
      content: Text('Usar ${c.cost} Ecopoints para resgatar:\n\n"${c.title}" — ${c.partner}?'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () {
          setState(() => _pts -= c.cost);
          Navigator.pop(context);
          _snack('Cupom "${c.title}" resgatado!', kGreen);
        }, child: const Text('Confirmar')),
      ],
    ));
  }

  void _snack(String msg, Color bg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: bg, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    body: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _CouponsHeader(pts: _pts)),
      SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), sliver: SliverList(
          delegate: SliverChildListDelegate([
            Row(children: [
              Text('Disponíveis para resgate', style: _kTitle.copyWith(fontSize: 15)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(40)),
                  child: Text('${_coupons.length}', style: _kGreenLbl)),
            ]),
            const SizedBox(height: 12),
            ..._coupons.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8),
                child: _CouponCard(c: c, pts: _pts, onRedeem: () => _redeem(c)))),
            const SizedBox(height: 8),
            EcoBubble(asset: EcoAssets.standard,
                message: 'Continue escaneando produtos sustentáveis para acumular mais pontos!',
                mascotSize: 56, bubbleColor: kGreenLight.withOpacity(0.3)),
          ]))),
    ]),
  );
}

class _CouponsHeader extends StatelessWidget {
  final int pts;
  const _CouponsHeader({required this.pts});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 56, 16, 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Seus Ecopoints', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text('$pts', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
        const Text('pontos disponíveis', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(40)),
            child: const Text('Nível Verde', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
      ])),
      EcoImage(asset: EcoAssets.standard, size: 130),
    ]),
  );
}

class _Coupon { final String title, partner, expiry; final int cost; final IconData icon; final Color color;
const _Coupon(this.title, this.partner, this.cost, this.expiry, this.icon, this.color); }

class _CouponCard extends StatelessWidget {
  final _Coupon c; final int pts; final VoidCallback onRedeem;
  const _CouponCard({required this.c, required this.pts, required this.onRedeem});
  bool get _can => pts >= c.cost;

  @override
  Widget build(BuildContext context) => Card(
    child: IntrinsicHeight(child: Row(children: [
      Container(width: 5, decoration: BoxDecoration(
          color: _can ? c.color : Colors.grey.shade300,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: (_can ? c.color : Colors.grey).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(c.icon, color: _can ? c.color : Colors.grey, size: 22))),
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(c.title, style: _kTitle.copyWith(fontSize: 13, color: _can ? kDarkGray : kMidGray)),
            const SizedBox(height: 2),
            Text(c.partner, style: _kCaption),
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.timer_outlined, size: 12, color: _can ? kGreen : Colors.grey),
              const SizedBox(width: 3),
              Text('Válido até ${c.expiry}', style: _kCaption.copyWith(color: _can ? kGreen : Colors.grey)),
            ]),
          ]))),
      Padding(padding: const EdgeInsets.only(right: 14), child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${c.cost} pts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _can ? c.color : kMidGray)),
            const SizedBox(height: 6),
            SizedBox(height: 32, child: ElevatedButton(
                onPressed: _can ? onRedeem : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _can ? c.color : Colors.grey.shade200,
                    foregroundColor: _can ? Colors.white : kMidGray,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: Size.zero, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                child: Text(_can ? 'Resgatar' : 'Sem pts'))),
          ])),
    ])),
  );
}


// Perfil do usuário, edição de nome, informações de nível e sair

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = AuthService.currentUser ?? '';
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _saveName() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    await AuthService.updateName(_nameCtrl.text.trim());
    setState(() => _editingName = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta', style: _kTitle),
        content: const Text('Deseja realmente sair? Seus dados locais serão limpos.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade500),
              child: const Text('Sair')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService.logout();
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthScreen(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child)),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ─ Cabeçalho
            Container(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Configurações', style: _kHeading),
                const SizedBox(height: 4),
                Text('Gerencie seu perfil e preferências', style: _kSubtitle),
              ]),
            ),

            // ─ Card de Perfil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Perfil', style: _kTitle),
                const SizedBox(height: 16),
                Row(children: [
                  // Avatar circular com inicial
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle),
                    child: Center(child: Text(
                        (AuthService.currentUser ?? 'E').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (!_editingName)
                      Row(children: [
                        Expanded(child: Text(AuthService.currentUser ?? 'Usuário',
                            style: _kTitle.copyWith(fontSize: 16))),
                        GestureDetector(
                            onTap: () { setState(() { _editingName = true; _nameCtrl.text = AuthService.currentUser ?? ''; }); },
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(40)),
                                child: const Text('Editar', style: _kGreenLbl))),
                      ])
                    else
                      Row(children: [
                        Expanded(child: TextField(controller: _nameCtrl, autofocus: true,
                            style: _kTitle.copyWith(fontSize: 15),
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true))),
                        const SizedBox(width: 8),
                        GestureDetector(onTap: _saveName, child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16))),
                        const SizedBox(width: 4),
                        GestureDetector(onTap: () => setState(() => _editingName = false), child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: kDivider, shape: BoxShape.circle),
                            child: Icon(Icons.close_rounded, color: kMidGray, size: 16))),
                      ]),
                    const SizedBox(height: 4),
                    Text(AuthService.currentEmail ?? '', style: _kSubtitle),
                  ])),
                ]),
              ]))),
            ),

            const SizedBox(height: 12),

            // ─ Card de Nível e XP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Progresso', style: _kTitle),
                const SizedBox(height: 16),
                Row(children: [
                  Container(width: 52, height: 52,
                      decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text('${AuthService.level}',
                          style: const TextStyle(color: kGreen, fontSize: 22, fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AuthService.levelTitle,
                        style: _kTitle.copyWith(fontSize: 15, color: kGreen)),
                    const SizedBox(height: 5),
                    ClipRRect(borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                            value: AuthService.xpProgress, backgroundColor: kDivider,
                            valueColor: const AlwaysStoppedAnimation<Color>(kGreen), minHeight: 8)),
                    const SizedBox(height: 4),
                    Text('${AuthService.xpInLevel} / ${AuthService.xpForNextLevel()} XP', style: _kCaption),
                  ])),
                ]),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _StatItem(value: '${AuthService.xp}', label: 'XP Total', icon: Icons.bolt_rounded, color: kGreen),
                  _StatItem(value: '${AuthService.level}', label: 'Nível', icon: Icons.emoji_events_rounded, color: kBrown),
                  _StatItem(value: '320', label: 'Ecopoints', icon: Icons.eco_rounded, color: Colors.green.shade600),
                ]),
              ]))),
            ),

            const SizedBox(height: 12),

            // ─ Opções Gerais
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(child: Column(children: [
                _SettingsTile(icon: Icons.notifications_outlined, label: 'Notificações',
                    subtitle: 'Alertas de pontuação e novidades',
                    trailing: Switch(value: true, onChanged: (_) {}, activeColor: kGreen)),
                const Divider(height: 1, indent: 56),
                _SettingsTile(icon: Icons.info_outline_rounded, label: 'Sobre o EcoBadge',
                    subtitle: 'v6.0 · Feito com consciência',
                    onTap: () {}),
                const Divider(height: 1, indent: 56),
                _SettingsTile(icon: Icons.privacy_tip_outlined, label: 'Política de privacidade',
                    onTap: () {}),
              ])),
            ),

            const SizedBox(height: 24),

            // ─ Botão Sair
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                    label: const Text('Sair da conta', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

// ─ Tile de configuração reutilizável
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.label, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(width: 36, height: 36,
        decoration: BoxDecoration(color: kBeige.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: kBrown, size: 20)),
    title: Text(label, style: _kBody.copyWith(fontWeight: FontWeight.w500)),
    subtitle: subtitle != null ? Text(subtitle!, style: _kCaption) : null,
    trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: kMidGray, size: 20) : null),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

// ─ Item de estatística
class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 40, height: 40,
        decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20)),
    const SizedBox(height: 6),
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: _kCaption),
  ]);
}