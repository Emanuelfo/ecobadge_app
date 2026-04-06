// ====================================================================
// EcoBadge v4.0
// Arquivo : main.dart
//
// ── pubspec.yaml ─────────────────────────────────────────────────────
//   dependencies:
//     flutter:
//       sdk: flutter
//     mobile_scanner: ^5.2.3
//     http: ^1.2.1
//
//   flutter:
//     assets:
//       - assets/eco1.png   # Eco padrão
//       - assets/eco2.png   # Eco com medalha
//       - assets/eco3.png   # Eco na árvore
//
// ── AndroidManifest.xml ──────────────────────────────────────────────
//   <uses-permission android:name="android.permission.CAMERA"/>
//   <uses-permission android:name="android.permission.INTERNET"/>
// ====================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

// ====================================================================
// PALETA DE CORES
// ====================================================================
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

// ====================================================================
// ESTILOS DE TEXTO
// ====================================================================
const _kTitle    = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kDarkGray, letterSpacing: -0.3);
const _kHeading  = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kDarkGray, letterSpacing: -0.5);
const _kSubtitle = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: kMidGray);
const _kBody     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: kDarkGray, height: 1.5);
const _kCaption  = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kMidGray, letterSpacing: 0.2);
const _kGreenLbl = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGreen);

// ====================================================================
// ASSETS DO MASCOTE
// ====================================================================
class EcoAssets {
  static const standard = 'assets/eco1.png'; // padrão / boas-vindas
  static const medal    = 'assets/eco2.png'; // com medalha / conquistas
  static const tree     = 'assets/eco3.png'; // na árvore / comunidade
  static const logo     = 'assets/icon2.png'; // logo transparente
  static const scan    = 'assets/scan.png'; // logo transparente
}

// ====================================================================
// PONTO DE ENTRADA
// ====================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const EcoBadgeApp());
}

// ====================================================================
// APP ROOT — inicia na SplashScreen
// ====================================================================
class EcoBadgeApp extends StatelessWidget {
  const EcoBadgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoBadge',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // O app começa na splash screen
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.light(
      primary: kGreen,
      secondary: kBrown,
      surface: kSurface,
      background: kBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: kDarkGray,
      onSurface: kDarkGray,
    ),
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: kDarkGray,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700,
        color: kDarkGray, letterSpacing: -0.5,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kDivider),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBrown,
        side: const BorderSide(color: kBrown),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      ),
    ),
    dividerTheme: const DividerThemeData(color: kDivider, thickness: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: kGreen,
      unselectedItemColor: kMidGray,
      backgroundColor: kSurface,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
  );
}

// ====================================================================
// SPLASH SCREEN — tela inicial com mascote e animação de entrada
// ====================================================================
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Fade in suave
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    // Slide do mascote de baixo para cima
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    ));

    // Leve escala no texto
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Inicia a animação após o frame ser renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // Fundo decorativo — círculo verde suave no topo
          Positioned(
            top: -size.width * 0.35,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 1.3,
              height: size.width * 1.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGreen.withOpacity(0.07),
              ),
            ),
          ),
          // Círculo menor no canto inferior direito
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBrown.withOpacity(0.05),
              ),
            ),
          ),

          // Conteúdo principal centralizado
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Mascote Eco em destaque com animação de slide
                  SlideTransition(
                    position: _slideAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: EcoImage(
                        asset: EcoAssets.logo,
                        size: size.width * 0.58,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nome e tagline
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      children: [
                        const Text(
                          'EcoBadge',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: kDarkGray,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seu consumo define o mundo',
                          style: _kSubtitle.copyWith(
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Botões de ação
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _navigateToMain,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Começar',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _navigateToMain,
                          style: TextButton.styleFrom(
                            foregroundColor: kMidGray,
                          ),
                          child: const Text(
                            'Já tenho uma conta  →',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Indicador de versão
                  Text(
                    'v1.3  ·  © 2026 EcoBadge',
                    style: _kCaption.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// WIDGET: EcoImage — exibe imagem do mascote com fundo preto removido
// ====================================================================
class EcoImage extends StatelessWidget {
  final String asset;
  final double size;
  final BoxFit fit;

  const EcoImage({
    super.key,
    required this.asset,
    this.size = 80,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    // BlendMode.multiply: fundo preto vira transparente sobre fundo claro
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: fit,
      colorBlendMode: BlendMode.multiply,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.pets_rounded, color: kBrown, size: 32),
      ),
    );
  }
}

// ====================================================================
// WIDGET: EcoBubble — balão de fala do mascote Eco
// ====================================================================
class EcoBubble extends StatelessWidget {
  final String asset;
  final String message;
  final double mascotSize;
  final Color? bubbleColor;

  const EcoBubble({
    super.key,
    required this.asset,
    required this.message,
    this.mascotSize = 64,
    this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bubbleColor ?? kBeige.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBeigeDark.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          EcoImage(asset: asset, size: mascotSize),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eco diz:',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: kBrown,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: _kBody.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// TELA PRINCIPAL — navegação por abas
// ====================================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  static const _screens = <Widget>[
    ScannerScreen(),
    CommunityScreen(),
    GamesScreen(),
    CouponsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: kDivider)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _idx,
            onTap: (i) => setState(() => _idx = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scanner'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people_alt_rounded), label: 'Comunidade'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.sports_esports_rounded), label: 'Games'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.card_giftcard_rounded), label: 'Cupons'),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// TELA 1 — SCANNER
//
// Fluxo: idle → scanning → loading → result / notFound / networkError
//
// CORREÇÃO PRINCIPAL:
//   • A câmera NÃO inicia automaticamente ao entrar na aba.
//   • O usuário vê uma tela idle com instruções e clica "Ativar Scanner".
//   • Após cada resultado, o usuário pode iniciar um novo scan pressionando
//     o botão — a câmera é ativada novamente sem recriar o controlador.
//   • Debounce de 400ms evita leituras duplicadas em frames consecutivos.
//   • _lastCode é zerado ao reiniciar, permitindo reler o mesmo código.
// ====================================================================
enum _ScanState { idle, scanning, loading, result, notFound, networkError }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {

  // Controlador criado UMA VEZ — reutilizado em todos os scans
  final MobileScannerController _cam = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  _ScanState _state = _ScanState.idle;
  ProductData? _product;
  String? _lastCode;   // evita reprocessar o mesmo código consecutivamente
  bool _processing = false;
  Timer? _debounce;

  // Controle da entrada manual de código de barras
  final TextEditingController _manualCtrl = TextEditingController();
  final FocusNode _manualFocus = FocusNode();
  String _manualError = '';

  // Animação da linha de scan
  late final AnimationController _lineCtrl;
  late final Animation<double> _lineAnim;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut);

    // Câmera começa PARADA — só ativa quando o usuário pressionar o botão
    _cam.stop();
  }

  @override
  void dispose() {
    _cam.dispose();
    _debounce?.cancel();
    _lineCtrl.dispose();
    _manualCtrl.dispose();
    _manualFocus.dispose();
    super.dispose();
  }

  // ── Callback do scanner — chamado a cada frame com código detectado ──
  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;

    final code = capture.barcodes
        .where((b) => b.rawValue != null)
        .map((b) => b.rawValue!)
        .firstOrNull;

    // Ignora frame sem código ou código idêntico ao último (sem debounce ativo)
    if (code == null || code == _lastCode) return;

    // Debounce: aguarda 400ms de silêncio antes de processar
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetch(code));
  }

  // ── Busca produto na API ─────────────────────────────────────────────
  Future<void> _fetch(String code) async {
    if (_processing) return;
    _processing = true;
    _lastCode = code;

    HapticFeedback.mediumImpact();
    setState(() => _state = _ScanState.loading);
    _cam.stop(); // para a câmera enquanto busca

    try {
      final product = await ProductService.fetch(code);
      if (!mounted) return;
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

  // ── Ativa scanner (idle → scanning) ─────────────────────────────────
  void _startScanning() {
    setState(() {
      _state = _ScanState.scanning;
      _lastCode = null; // permite reler o mesmo código de antes
    });
    _cam.start();
  }

  // ── Para câmera e volta ao idle ──────────────────────────────────────
  void _stopScanning() {
    _cam.stop();
    setState(() {
      _state = _ScanState.idle;
      _lastCode = null;
    });
  }

  // ── Volta ao idle após ver resultado ────────────────────────────────
  void _resetToIdle() {
    setState(() {
      _state = _ScanState.idle;
      _product = null;
      _lastCode = null;
    });
    // Câmera já está parada
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _ScanState.idle         => _buildIdle(),
      _ScanState.scanning     => _buildCamera(),
      _ScanState.loading      => _buildLoading(),
      _ScanState.result       => _buildResult(),
      _ScanState.notFound     => _buildFeedback(
        mascotAsset: EcoAssets.standard,
        title: 'Produto não encontrado',
        body: 'Este código não está em nossa base de dados.\nTente escanear outro produto.',
      ),
      _ScanState.networkError => _buildFeedback(
        mascotAsset: EcoAssets.standard,
        title: 'Sem conexão',
        body: 'Verifique sua internet e tente novamente.',
      ),
    };
  }

  // ── UI: Tela idle — câmera desligada, instruções e botão ativar ──────
  Widget _buildIdle() {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // ── Cabeçalho ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scanner', style: _kHeading),
                      const SizedBox(height: 4),
                      Text('Analise produtos em segundos',
                          style: _kSubtitle.copyWith(fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.eco_rounded, color: kGreen, size: 14),
                      const SizedBox(width: 5),
                      const Text('320 pts', style: _kGreenLbl),
                    ]),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Mascote + círculo decorativo ───────────────────────
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kGreen.withOpacity(0.08),
                        border: Border.all(color: kGreen.withOpacity(0.15), width: 1.5),
                      ),
                    ),
                    EcoImage(asset: EcoAssets.scan, size: 160),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Botão principal: ativar câmera ─────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startScanning,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const Text('Ativar Scanner'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Divisor visual ─────────────────────────────────────
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou digite o código', style: _kCaption),
                ),
                const Expanded(child: Divider()),
              ]),

              const SizedBox(height: 16),

              // ── Campo de entrada manual ────────────────────────────
              _ManualBarcodeField(
                controller: _manualCtrl,
                focusNode: _manualFocus,
                errorText: _manualError.isEmpty ? null : _manualError,
                onSubmit: _submitManual,
                onChanged: (_) {
                  if (_manualError.isNotEmpty) {
                    setState(() => _manualError = '');
                  }
                },
              ),

              const SizedBox(height: 24),

              // ── Card de instruções ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kDivider),
                ),
                child: Column(
                  children: [
                    _InstructionRow(step: '1', text: 'Ative a câmera ou digite o código acima'),
                    const Divider(height: 20),
                    _InstructionRow(step: '2', text: 'Aponte para o código de barras do produto'),
                    const Divider(height: 20),
                    _InstructionRow(step: '3', text: 'Receba a análise de sustentabilidade completa'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Demo ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _runDemo,
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: const Text('Usar produto de demonstração'),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI: Câmera ativa ─────────────────────────────────────────────────
  Widget _buildCamera() {
    final sw = MediaQuery.of(context).size.width;
    final frameW = sw * 0.72;
    const frameH = 155.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Feed da câmera
          MobileScanner(
            controller: _cam,
            onDetect: _onDetect,
          ),

          // Overlay com janela de leitura
          _ScanOverlay(frameWidth: frameW, frameHeight: frameH),

          // Linha animada dentro da janela
          Center(
            child: SizedBox(
              width: frameW - 8,
              height: frameH,
              child: AnimatedBuilder(
                animation: _lineAnim,
                builder: (_, __) => Align(
                  alignment: Alignment(0, (_lineAnim.value * 2) - 1),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        kGreen.withOpacity(0.9),
                        Colors.transparent,
                      ]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Barra superior
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: _CamTopBar(
                onFlash: () => _cam.toggleTorch(),
                onFlip: () => _cam.switchCamera(),
                onStop: _stopScanning,
              ),
            ),
          ),

          // Instrução + botão parar (rodapé)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _CamBottomBar(
              onStop: _stopScanning,
              onDemo: _runDemo,
            ),
          ),
        ],
      ),
    );
  }

  // ── UI: Loading ──────────────────────────────────────────────────────
  Widget _buildLoading() => Scaffold(
    backgroundColor: kBackground,
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        EcoImage(asset: EcoAssets.standard, size: 90),
        const SizedBox(height: 22),
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(color: kGreen, strokeWidth: 2.5),
        ),
        const SizedBox(height: 14),
        const Text('Buscando produto...', style: _kSubtitle),
      ]),
    ),
  );

  // ── UI: Resultado ────────────────────────────────────────────────────
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
      body: SafeArea(
        child: Column(
          children: [
            _BackBar(label: 'Análise do Produto', onBack: _resetToIdle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Card principal do produto
                    _ProductCard(product: p),
                    const SizedBox(height: 12),

                    // 2. Visão geral expandida (tipo, impacto, sustentabilidade)
                    _ProductOverviewCard(product: p),
                    const SizedBox(height: 12),

                    // 3. EcoScore com barra de progresso
                    _EcoScoreCard(score: p.ecoScore),
                    const SizedBox(height: 12),

                    // 4. Card explicando a pontuação com razões
                    if (p.scoreReasons.isNotEmpty) ...[
                      _ScoreBreakdownCard(product: p),
                      const SizedBox(height: 12),
                    ],

                    // 5. Detalhes técnicos (embalagem, ingredientes, certificações)
                    if (p.hasDetails) ...[
                      _DetailsCard(product: p),
                      const SizedBox(height: 12),
                    ],

                    // 6. Balão do Eco com mensagem contextual
                    EcoBubble(asset: mascotAsset, message: ecoMsg, mascotSize: 64),
                    const SizedBox(height: 20),

                    // 7. Ações
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startScanning,
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                        label: const Text('Escanear outro produto'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetToIdle,
                        child: const Text('Voltar ao início'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI: Feedback de erro / não encontrado ────────────────────────────
  Widget _buildFeedback({
    required String mascotAsset,
    required String title,
    required String body,
  }) =>
      Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              _BackBar(label: 'Scanner', onBack: _resetToIdle),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      EcoImage(asset: mascotAsset, size: 100),
                      const SizedBox(height: 20),
                      Text(title, style: _kTitle, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(body,
                          style: _kSubtitle, textAlign: TextAlign.center),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: _startScanning,
                        icon:
                        const Icon(Icons.qr_code_scanner_rounded, size: 18),
                        label: const Text('Tentar novamente'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _resetToIdle,
                        child: const Text('Voltar ao início'),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Submete o código digitado manualmente ───────────────────────────
  void _submitManual() {
    final code = _manualCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _manualError = 'Digite um código de barras.');
      return;
    }
    if (!RegExp(r'^\d{4,20}$').hasMatch(code)) {
      setState(() => _manualError = 'Código inválido. Use apenas números (4-20 dígitos).');
      return;
    }
    setState(() => _manualError = '');
    _manualFocus.unfocus();
    _fetch(code);
  }

  // Demo: seleciona um código de produto local
  void _runDemo() {
    final codes = ['7891910000197', '7894900011517', '7891000315507'];
    _fetch(codes[DateTime.now().millisecond % codes.length]);
  }
}

// ── Widget: linha de instrução numerada ──────────────────────────────
class _InstructionRow extends StatelessWidget {
  final String step;
  final String text;

  const _InstructionRow({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: kGreen.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: kGreen,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: _kBody.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}

// ── Overlay do scanner (vinheta + moldura com cantos verdes) ─────────
class _ScanOverlay extends StatelessWidget {
  final double frameWidth;
  final double frameHeight;

  const _ScanOverlay({required this.frameWidth, required this.frameHeight});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _OverlayPainter(frameWidth, frameHeight));
}

class _OverlayPainter extends CustomPainter {
  final double fw, fh;
  _OverlayPainter(this.fw, this.fh);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final l = cx - fw / 2;
    final t = cy - fh / 2;
    final r = cx + fw / 2;
    final b = cy + fh / 2;
    const rad = 12.0;

    // Fundo escurecido com "janela" transparente
    final bg = Paint()..color = Colors.black.withOpacity(0.58);
    final outer = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()
      ..addRRect(RRect.fromLTRBR(l, t, r, b, const Radius.circular(rad)));
    canvas.drawPath(
        Path.combine(PathOperation.difference, outer, inner), bg);

    // Cantos da moldura em verde
    const cLen = 24.0;
    final cp = Paint()
      ..color = kGreen
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y + dy * rad), Offset(x, y + dy * cLen), cp);
      canvas.drawLine(Offset(x + dx * rad, y), Offset(x + dx * cLen, y), cp);
    }

    corner(l, t, 1, 1);
    corner(r, t, -1, 1);
    corner(l, b, 1, -1);
    corner(r, b, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Barra superior da câmera ─────────────────────────────────────────
class _CamTopBar extends StatelessWidget {
  final VoidCallback onFlash, onFlip, onStop;

  const _CamTopBar({
    required this.onFlash,
    required this.onFlip,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Botão voltar / parar câmera
          _GlassBtn(icon: Icons.close_rounded, onTap: onStop),
          const SizedBox(width: 8),
          const Text(
            'EcoBadge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          _GlassBtn(icon: Icons.flash_on_rounded, onTap: onFlash),
          const SizedBox(width: 6),
          _GlassBtn(icon: Icons.flip_camera_android_rounded, onTap: onFlip),
        ],
      ),
    );
  }
}

// ── Botão translúcido sobre câmera ───────────────────────────────────
class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ── Rodapé da câmera ─────────────────────────────────────────────────
class _CamBottomBar extends StatelessWidget {
  final VoidCallback onStop;
  final VoidCallback onDemo;

  const _CamBottomBar({required this.onStop, required this.onDemo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.70),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aponte a câmera para o código de barras',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Parar câmera
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_circle_outlined,
                        size: 16, color: Colors.white70),
                    label: const Text('Parar câmera',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Demo
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDemo,
                    icon: const Icon(Icons.science_outlined,
                        size: 16, color: Colors.white60),
                    label: const Text('Demonstração',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra de voltar reutilizável ─────────────────────────────────────
class _BackBar extends StatelessWidget {
  final String label;
  final VoidCallback onBack;

  const _BackBar({required this.label, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 19, color: kDarkGray),
        ),
        Text(label, style: _kTitle),
      ],
    );
  }
}

// ── Card principal do produto ────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductData product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Imagem do produto ou placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.imageUrl != null
                  ? Image.network(
                product.imageUrl!,
                width: 70, height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imgFallback(),
              )
                  : _imgFallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: _kTitle),
                  if (product.brand.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(product.brand, style: _kSubtitle),
                  ],
                  const SizedBox(height: 8),
                  _Chip(label: product.category),
                ],
              ),
            ),
          ]),
          if (product.quantity.isNotEmpty ||
              product.countries.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            if (product.quantity.isNotEmpty)
              _KV('Quantidade', product.quantity),
            if (product.countries.isNotEmpty) ...[
              const SizedBox(height: 6),
              _KV('Origem', product.countries),
            ],
          ],
        ],
      ),
    ),
  );

  Widget _imgFallback() => Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      color: kBeige.withOpacity(0.3),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.inventory_2_outlined, color: kBrown, size: 30),
  );
}

// ── EcoScore card ─────────────────────────────────────────────────────
class _EcoScoreCard extends StatelessWidget {
  final int score;

  const _EcoScoreCard({required this.score});

  Color get _color {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return kGreen;
    if (score >= 40) return Colors.orange;
    return const Color(0xFFE53935);
  }

  String get _grade {
    if (score >= 80) return 'A';
    if (score >= 65) return 'B';
    if (score >= 50) return 'C';
    if (score >= 35) return 'D';
    return 'E';
  }

  String get _desc {
    if (score >= 80) return 'Excelente';
    if (score >= 65) return 'Bom';
    if (score >= 50) return 'Regular';
    if (score >= 35) return 'Ruim';
    return 'Crítico';
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pontuação de Sustentabilidade', style: _kTitle),
          const SizedBox(height: 14),
          Row(children: [
            // Bloco da nota
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _grade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _desc,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: kDivider,
                      valueColor: AlwaysStoppedAnimation<Color>(_color),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('$score / 100 pontos', style: _kCaption),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: kGreen, size: 18),
            const SizedBox(width: 6),
            Text(
              '+${(score / 10).round()} Ecopoints adicionados',
              style: _kGreenLbl,
            ),
          ]),
        ],
      ),
    ),
  );
}

// ── Detalhes do produto ───────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final ProductData product;

  const _DetailsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <_DRow>[
      if (product.packaging.isNotEmpty)
        _DRow(
            icon: Icons.inventory_2_outlined,
            label: 'Embalagem',
            value: product.packaging),
      if (product.ingredients.isNotEmpty)
        _DRow(
            icon: Icons.list_alt_rounded,
            label: 'Ingredientes',
            value: product.ingredients),
      for (final l in product.labels)
        _DRow(icon: Icons.verified_outlined, label: 'Certificação', value: l),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalhes do Produto', style: _kTitle),
            const SizedBox(height: 12),
            for (int i = 0; i < rows.length; i++) ...[
              _DetailRow(row: rows[i]),
              if (i < rows.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DRow {
  final IconData icon;
  final String label, value;

  const _DRow({required this.icon, required this.label, required this.value});
}

class _DetailRow extends StatelessWidget {
  final _DRow row;

  const _DetailRow({required this.row});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(row.icon, size: 18, color: kGreen),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.label, style: _kCaption),
            const SizedBox(height: 2),
            Text(row.value, style: _kBody.copyWith(fontSize: 13)),
          ],
        ),
      ),
    ],
  );
}

// ====================================================================
// WIDGET: _ManualBarcodeField — campo de entrada manual do código
// ====================================================================
class _ManualBarcodeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;

  const _ManualBarcodeField({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text('Código de barras', style: _kCaption),
        const SizedBox(height: 6),

        // Campo + botão buscar na mesma linha
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                // Submete ao pressionar "done" no teclado numérico
                onSubmitted: (_) => onSubmit(),
                keyboardType: TextInputType.number,
                // Aceita apenas dígitos
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                maxLength: 20,
                decoration: InputDecoration(
                  hintText: 'Ex: 7891910000197',
                  hintStyle: _kCaption.copyWith(fontSize: 13),
                  errorText: errorText,
                  counterText: '', // oculta o contador de caracteres
                  prefixIcon: const Icon(Icons.tag_rounded,
                      color: kMidGray, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  filled: true,
                  fillColor: kSurface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kDivider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kGreen, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: Colors.red.shade400, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: Colors.red.shade400, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Botão buscar — alinhado à linha de base do TextField
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Buscar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ====================================================================
// WIDGET: _ProductOverviewCard — visão geral expandida do produto
// Exibe tipo, impacto ambiental e nível de sustentabilidade
// ====================================================================
class _ProductOverviewCard extends StatelessWidget {
  final ProductData product;

  const _ProductOverviewCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Visão Geral', style: _kTitle),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.category_outlined,
                    label: 'Tipo',
                    value: product.productType.isNotEmpty
                        ? product.productType
                        : product.category,
                  ),
                ),
                _vDivider(),
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.eco_outlined,
                    label: 'Impacto',
                    value: product.resolvedImpact,
                    valueColor: _impactColor(product.resolvedImpact),
                  ),
                ),
                _vDivider(),
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.thumb_up_alt_outlined,
                    label: 'Nível',
                    value: product.resolvedSustainability,
                    valueColor: _sustainColor(product.ecoScore),
                  ),
                ),
              ],
            ),
            if (product.countries.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: kMidGray),
                const SizedBox(width: 6),
                Text('Origem: ', style: _kCaption),
                Text(product.countries,
                    style: _kBody.copyWith(fontSize: 12)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1, height: 48, color: kDivider,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  Color _impactColor(String impact) {
    switch (impact) {
      case 'Baixo':  return Colors.green.shade600;
      case 'Médio':  return Colors.orange.shade600;
      default:       return Colors.red.shade600;
    }
  }

  Color _sustainColor(int score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return kGreenDark;
    if (score >= 40) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;

  const _OverviewItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: kGreen, size: 20),
        const SizedBox(height: 6),
        Text(label, style: _kCaption),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? kDarkGray,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ====================================================================
// WIDGET: _ScoreBreakdownCard — explica por que o produto recebeu
// aquela pontuação, listando fatores positivos e negativos
// ====================================================================
class _ScoreBreakdownCard extends StatelessWidget {
  final ProductData product;

  const _ScoreBreakdownCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final positives = product.scoreReasons.where((r) => r.positive).toList();
    final negatives = product.scoreReasons.where((r) => !r.positive).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(children: [
              const Icon(Icons.analytics_outlined, color: kGreen, size: 18),
              const SizedBox(width: 8),
              const Text('Por que essa pontuação?', style: _kTitle),
            ]),
            const SizedBox(height: 6),
            Text(
              'Fatores que influenciaram o Ecopoint deste produto:',
              style: _kCaption.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 14),

            // Fatores positivos
            if (positives.isNotEmpty) ...[
              _ReasonGroupLabel(
                icon: Icons.add_circle_outline_rounded,
                label: 'Pontos positivos',
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 8),
              ...positives.map((r) => _ReasonRow(reason: r)),
            ],

            // Separador entre grupos
            if (positives.isNotEmpty && negatives.isNotEmpty)
              const SizedBox(height: 10),

            // Fatores negativos
            if (negatives.isNotEmpty) ...[
              _ReasonGroupLabel(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Pontos negativos',
                color: Colors.red.shade500,
              ),
              const SizedBox(height: 8),
              ...negatives.map((r) => _ReasonRow(reason: r)),
            ],

            // Nota de rodapé
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: kBeige.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'A pontuação é calculada com base em dados ambientais, embalagem e certificações do produto.',
                style: _kCaption.copyWith(fontSize: 11, color: kMidGray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonGroupLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ReasonGroupLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ]);
  }
}

class _ReasonRow extends StatelessWidget {
  final ScoreReason reason;

  const _ReasonRow({required this.reason});

  @override
  Widget build(BuildContext context) {
    final color = reason.positive ? Colors.green.shade600 : Colors.red.shade500;
    final bgColor =
    reason.positive ? Colors.green.withOpacity(0.06) : Colors.red.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(reason.icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            reason.label,
            style: _kBody.copyWith(fontSize: 13, color: kDarkGray),
          ),
        ),
        Icon(
          reason.positive
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          size: 14,
          color: color,
        ),
      ]),
    );
  }
}

// ── Componentes comuns ────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: kGreen.withOpacity(0.12),
      borderRadius: BorderRadius.circular(40),
    ),
    child: Text(label, style: _kGreenLbl),
  );
}

class _KV extends StatelessWidget {
  final String k, v;

  const _KV(this.k, this.v);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 86, child: Text(k, style: _kCaption)),
      Expanded(child: Text(v, style: _kBody.copyWith(fontSize: 13))),
    ],
  );
}

// ====================================================================
// SERVIÇO: Open Food Facts + fallback local
// ====================================================================
class ProductService {
  static const _api = 'https://world.openfoodfacts.org/api/v0/product';

  // ── Banco local com dados enriquecidos ───────────────────────────────
  static const Map<String, ProductData> _local = {
    '7891910000197': ProductData(
      name: 'Arroz Integral Orgânico',
      brand: 'Camil Orgânico',
      category: 'Cereais',
      ecoScore: 91,
      quantity: '1 kg',
      packaging: 'Embalagem biodegradável',
      countries: 'Brasil',
      ingredients: 'Arroz integral orgânico',
      labels: ['Orgânico Brasil', 'IBD'],
      imageUrl: null,
      productType: 'Alimento',
      environmentalImpact: 'Baixo',
      sustainabilityLevel: 'Muito sustentável',
      scoreReasons: [
        ScoreReason(label: 'Produto orgânico certificado', positive: true,  icon: Icons.eco_rounded),
        ScoreReason(label: 'Embalagem biodegradável',      positive: true,  icon: Icons.recycling_rounded),
        ScoreReason(label: 'Produção nacional',            positive: true,  icon: Icons.flag_rounded),
        ScoreReason(label: 'Sem agrotóxicos',              positive: true,  icon: Icons.spa_rounded),
      ],
    ),
    '7894900011517': ProductData(
      name: 'Refrigerante Cola',
      brand: 'Coca-Cola',
      category: 'Bebidas',
      ecoScore: 42,
      quantity: '350 ml',
      packaging: 'Lata de alumínio reciclável',
      countries: 'Brasil',
      ingredients: 'Água gaseificada, açúcar, extrato de noz de cola, caramelo, ácido fosfórico, cafeína',
      labels: [],
      imageUrl: null,
      productType: 'Bebida',
      environmentalImpact: 'Médio',
      sustainabilityLevel: 'Moderado',
      scoreReasons: [
        ScoreReason(label: 'Embalagem de alumínio reciclável',  positive: true,  icon: Icons.recycling_rounded),
        ScoreReason(label: 'Alto teor de açúcar',               positive: false, icon: Icons.warning_amber_rounded),
        ScoreReason(label: 'Aditivos artificiais',              positive: false, icon: Icons.science_outlined),
        ScoreReason(label: 'Alta pegada de carbono industrial', positive: false, icon: Icons.factory_outlined),
      ],
    ),
    '7891000315507': ProductData(
      name: 'Água Mineral Natural',
      brand: 'Crystal',
      category: 'Bebidas',
      ecoScore: 80,
      quantity: '500 ml',
      packaging: 'Garrafa PET reciclável',
      countries: 'Brasil',
      ingredients: 'Água mineral natural',
      labels: ['ISO 14001'],
      imageUrl: null,
      productType: 'Bebida',
      environmentalImpact: 'Baixo',
      sustainabilityLevel: 'Sustentável',
      scoreReasons: [
        ScoreReason(label: 'Produto natural, sem aditivos',       positive: true,  icon: Icons.water_drop_rounded),
        ScoreReason(label: 'Certificação ambiental ISO 14001',    positive: true,  icon: Icons.verified_rounded),
        ScoreReason(label: 'Garrafa PET — descarte correto exigido', positive: false, icon: Icons.delete_outline_rounded),
      ],
    ),
  };

  static Future<ProductData?> fetch(String barcode) async {
    try {
      final res = await http
          .get(Uri.parse('$_api/$barcode.json'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if ((json['status'] as int?) == 1) {
          return _parse(json['product'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return _local[barcode];
  }

  static ProductData _parse(Map<String, dynamic> p) {
    // ── EcoScore ────────────────────────────────────────────────────────
    int eco = 50;
    final raw = p['ecoscore_score'];
    if (raw != null) {
      eco = (raw as num).toInt().clamp(0, 100);
    } else {
      final ns = (p['nutriscore_grade'] as String? ?? '').toUpperCase();
      eco = switch (ns) {
        'A' => 85, 'B' => 70, 'C' => 55, 'D' => 40, 'E' => 25, _ => 50
      };
    }

    // ── Categoria ────────────────────────────────────────────────────────
    String cat = 'Produto alimentar';
    final cats = p['categories'] as String? ?? '';
    if (cats.isNotEmpty) {
      final parts = cats.split(',');
      cat = parts.last.trim().replaceAll(RegExp(r'^[a-z]{2}:'), '');
      if (cat.isEmpty || cat.length > 35) {
        cat = parts.first.trim().replaceAll(RegExp(r'^[a-z]{2}:'), '');
      }
    }

    // ── Certificações ────────────────────────────────────────────────────
    final lTags = p['labels_tags'] as List<dynamic>? ?? [];
    final labels = lTags
        .map((l) => l.toString()
        .replaceAll(RegExp(r'^[a-z]{2}:'), '')
        .replaceAll('-', ' '))
        .where((l) => l.isNotEmpty)
        .take(3)
        .toList();

    // ── Tipo do produto (heurístico) ─────────────────────────────────────
    final ptype = _inferType(cat);

    // ── Embalagem ────────────────────────────────────────────────────────
    final pkg = _s(p['packaging']);

    // ── Score reasons geradas dinamicamente a partir dos dados da API ────
    final reasons = _buildReasons(eco: eco, packaging: pkg, labels: labels,
        hasOrganic: labels.any((l) => l.toLowerCase().contains('orgân') ||
            l.toLowerCase().contains('organic')));

    return ProductData(
      name:        _s(p['product_name'] ?? p['product_name_pt'] ?? 'Produto sem nome'),
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

  /// Infere o tipo do produto com base na categoria
  static String _inferType(String category) {
    final c = category.toLowerCase();
    if (c.contains('bebid') || c.contains('drink') || c.contains('juice') || c.contains('suco')) return 'Bebida';
    if (c.contains('laticín') || c.contains('dairy') || c.contains('leite') || c.contains('queijo')) return 'Laticínio';
    if (c.contains('higien') || c.contains('cosmet') || c.contains('shampoo')) return 'Higiene';
    if (c.contains('limpez') || c.contains('clean') || c.contains('deterg')) return 'Limpeza';
    if (c.contains('snack') || c.contains('biscoito') || c.contains('salgad')) return 'Snack';
    return 'Alimento';
  }

  /// Gera lista de razões da pontuação com base nos dados disponíveis
  static List<ScoreReason> _buildReasons({
    required int eco,
    required String packaging,
    required List<String> labels,
    required bool hasOrganic,
  }) {
    final reasons = <ScoreReason>[];
    final pkg = packaging.toLowerCase();

    // Fatores positivos
    if (hasOrganic) {
      reasons.add(const ScoreReason(label: 'Produto orgânico certificado', positive: true, icon: Icons.eco_rounded));
    }
    if (pkg.contains('biodegradável') || pkg.contains('biodegradable')) {
      reasons.add(const ScoreReason(label: 'Embalagem biodegradável', positive: true, icon: Icons.recycling_rounded));
    } else if (pkg.contains('reciclável') || pkg.contains('recyclable') || pkg.contains('alumínio')) {
      reasons.add(const ScoreReason(label: 'Embalagem reciclável', positive: true, icon: Icons.recycling_rounded));
    } else if (pkg.isNotEmpty) {
      reasons.add(const ScoreReason(label: 'Embalagem não reciclável', positive: false, icon: Icons.delete_outline_rounded));
    }
    if (labels.isNotEmpty) {
      reasons.add(ScoreReason(label: 'Possui ${labels.length} certificação(ões) ambiental(is)', positive: true, icon: Icons.verified_rounded));
    }

    // Fatores negativos baseados no score
    if (eco < 40) {
      reasons.add(const ScoreReason(label: 'Alto impacto ambiental de produção', positive: false, icon: Icons.factory_outlined));
    }
    if (eco < 55 && !hasOrganic) {
      reasons.add(const ScoreReason(label: 'Sem certificação orgânica', positive: false, icon: Icons.cancel_outlined));
    }

    // Se não tiver nenhuma razão, gera padrão
    if (reasons.isEmpty) {
      if (eco >= 70) {
        reasons.add(const ScoreReason(label: 'Boas práticas de produção', positive: true, icon: Icons.thumb_up_outlined));
      } else {
        reasons.add(const ScoreReason(label: 'Dados ambientais limitados disponíveis', positive: false, icon: Icons.info_outline_rounded));
      }
    }

    return reasons;
  }

  static String _s(dynamic v) => (v ?? '').toString().trim();
}

// ====================================================================
// MODELO: ProductData — dados completos do produto
// ====================================================================
class ProductData {
  final String name, brand, category, quantity, packaging, ingredients,
      countries;
  final List<String> labels;
  final int ecoScore;
  final String? imageUrl;

  // Campos enriquecidos de impacto ambiental
  final String environmentalImpact; // ex: "Baixo", "Médio", "Alto"
  final String productType;         // ex: "Alimento", "Limpeza", "Higiene"
  final String sustainabilityLevel; // ex: "Muito Sustentável"
  final List<ScoreReason> scoreReasons; // razões que explicam a pontuação

  const ProductData({
    required this.name,
    required this.brand,
    required this.category,
    required this.ecoScore,
    required this.quantity,
    required this.packaging,
    required this.ingredients,
    required this.labels,
    required this.countries,
    required this.imageUrl,
    this.environmentalImpact = '',
    this.productType = '',
    this.sustainabilityLevel = '',
    this.scoreReasons = const [],
  });

  bool get hasDetails =>
      packaging.isNotEmpty || ingredients.isNotEmpty || labels.isNotEmpty;

  /// Nível de impacto ambiental derivado do ecoScore, quando não informado
  String get resolvedImpact {
    if (environmentalImpact.isNotEmpty) return environmentalImpact;
    if (ecoScore >= 80) return 'Baixo';
    if (ecoScore >= 55) return 'Médio';
    return 'Alto';
  }

  /// Nível de sustentabilidade derivado do ecoScore
  String get resolvedSustainability {
    if (sustainabilityLevel.isNotEmpty) return sustainabilityLevel;
    if (ecoScore >= 80) return 'Muito sustentável';
    if (ecoScore >= 65) return 'Sustentável';
    if (ecoScore >= 50) return 'Moderado';
    if (ecoScore >= 35) return 'Pouco sustentável';
    return 'Não sustentável';
  }
}

// ====================================================================
// MODELO: ScoreReason — motivo individual que compõe a pontuação
// ====================================================================
class ScoreReason {
  final String label;      // Texto curto: "Embalagem reciclável"
  final bool positive;     // true = fator positivo, false = negativo
  final IconData icon;     // Ícone representativo

  const ScoreReason({
    required this.label,
    required this.positive,
    required this.icon,
  });
}

// ====================================================================
// TELA 2 — COMUNIDADE
// eco3.png (macaquinho na árvore) reforça o tema ecológico
// ====================================================================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<_Post> _posts = [
    _Post(
      author: 'Ana Clara',
      initials: 'AC',
      color: kGreen,
      time: '2h',
      tag: 'Dica',
      tagColor: kGreen,
      body: 'Comecei a fazer compostagem em casa esta semana. Cascas de legumes, borra de café e folhas secas — tudo vira adubo em poucas semanas. Altamente recomendo!',
      likes: 34,
      comments: 8,
    ),
    _Post(
      author: 'EmanuelFo',
      initials: 'EF',
      color: kBrown,
      time: '5h',
      tag: 'Novidade',
      tagColor: kBrown,
      body: 'Produtos com certificação orgânica agora valem pontuação dobrada esta semana. Escaneie mais para ganhar mais Ecopoints!',
      likes: 127,
      comments: 23,
    ),
    _Post(
      author: 'Treetech',
      initials: 'TT',
      color: kLightBrown,
      time: '1d',
      tag: 'Curiosidade',
      tagColor: kLightBrown,
      body: 'Uma sacola plástica convencional leva até 400 anos para se decompor. Substituir por ecobags é uma das mudanças mais simples e impactantes possíveis.',
      likes: 89,
      comments: 15,
    ),
    _Post(
      author: 'CH',
      initials: 'CH',
      color: Colors.blueGrey,
      time: '2d',
      tag: 'Ação',
      tagColor: Colors.blueGrey,
      body: 'Participei da limpeza da praia hoje — recolhemos mais de 50 kg de resíduos em 3 horas. É incrível o que um grupo pequeno consegue fazer.',
      likes: 214,
      comments: 41,
    ),
    _Post(
      author: 'João Sousas',
      initials: 'JS',
      color: Colors.amber.shade700,
      time: '3d',
      tag: 'Experiência',
      tagColor: Colors.amber.shade700,
      body: 'Instalei painéis solares no ano passado e a conta de energia caiu 80%. O retorno do investimento acontece em torno de 4 anos.',
      likes: 156,
      comments: 29,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          // Cabeçalho com eco3
          SliverToBoxAdapter(child: _CommunityHeader()),

          // AppBar fixo após rolar
          SliverAppBar(
            pinned: true,
            backgroundColor: kBackground,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text('Publicações recentes',
                  style: _kCaption.copyWith(fontSize: 12)),
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.search_rounded), onPressed: () {}),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: kDivider),
            ),
          ),

          // Feed
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                  if (i.isOdd) return const SizedBox(height: 10);
                  final idx = i ~/ 2;
                  return _PostCard(
                    post: _posts[idx],
                    onLike: () =>
                        setState(() => _posts[idx].toggleLike()),
                  );
                },
                childCount: _posts.length * 2 - 1,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: kGreen,
        elevation: 2,
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
        label: const Text('Publicar',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Comunidade', style: _kHeading),
                const SizedBox(height: 6),
                Text(
                  'Compartilhe ideias e inspire\nquem está ao seu redor.',
                  style: _kSubtitle.copyWith(height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MiniStat('4.2k', 'membros'),
                    const SizedBox(width: 16),
                    _MiniStat('128', 'posts hoje'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // eco3 no header da comunidade
          EcoImage(asset: EcoAssets.tree, size: 200),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;

  const _MiniStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: kGreenDark,
          )),
      Text(label, style: _kCaption),
    ],
  );
}

class _Post {
  final String author, initials, time, tag, body;
  final Color color, tagColor;
  final int comments;
  int likes;
  bool liked;

  _Post({
    required this.author,
    required this.initials,
    required this.color,
    required this.time,
    required this.tag,
    required this.tagColor,
    required this.body,
    required this.likes,
    required this.comments,
    this.liked = false,
  });

  void toggleLike() {
    liked = !liked;
    likes += liked ? 1 : -1;
  }
}

class _PostCard extends StatelessWidget {
  final _Post post;
  final VoidCallback onLike;

  const _PostCard({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do post
          Row(children: [
            CircleAvatar(
              backgroundColor: post.color,
              radius: 18,
              child: Text(
                post.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.author,
                      style: _kTitle.copyWith(fontSize: 14)),
                  Text('há ${post.time}', style: _kCaption),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: post.tagColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                post.tag,
                style: TextStyle(
                  color: post.tagColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(post.body, style: _kBody),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Ações
          Row(children: [
            _ActBtn(
              icon: post.liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: '${post.likes}',
              color: post.liked ? Colors.red : kMidGray,
              onTap: onLike,
            ),
            const SizedBox(width: 18),
            _ActBtn(
              icon: Icons.chat_bubble_outline_rounded,
              label: '${post.comments}',
              color: kMidGray,
              onTap: () {},
            ),
            const Spacer(),
            _ActBtn(
              icon: Icons.share_outlined,
              label: 'Compartilhar',
              color: kMidGray,
              onTap: () {},
            ),
          ]),
        ],
      ),
    ),
  );
}

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          )),
    ]),
  );
}

// ====================================================================
// TELA 3 — GAMES
// eco2.png (macaquinho com medalha) — conquistas e pontuação
// ====================================================================
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _pts = 0;
  int _qi = 0;
  int? _sel;
  bool _answered = false;

  static const _qs = [
    _Q(
      'Quanto tempo uma garrafa PET leva para se decompor na natureza?',
      ['50 anos', '100 anos', '400 anos', '1.000 anos'],
      2,
      'Garrafas PET podem levar até 400 anos para se decompor, liberando microplásticos ao longo desse tempo.',
    ),
    _Q(
      'Qual material demora mais para se decompor?',
      ['Vidro', 'Papel', 'Plástico', 'Metal'],
      0,
      'O vidro pode levar mais de 1 milhão de anos para se decompor completamente.',
    ),
    _Q(
      'Quantos litros de água são necessários para 1 kg de carne bovina?',
      ['500 L', '2.000 L', '5.000 L', '15.000 L'],
      3,
      'A produção de 1 kg de carne bovina consome cerca de 15.000 litros de água em toda a cadeia produtiva.',
    ),
    _Q(
      'O que é a pegada de carbono?',
      [
        'Resíduos no solo',
        'Total de CO₂ emitido por atividades humanas',
        'Reserva de carbono',
        'Combustível fóssil'
      ],
      1,
      'A pegada de carbono mede o total de gases de efeito estufa emitidos direta ou indiretamente.',
    ),
  ];

  final List<_Mission> _missions = [
    _Mission('Escaneador Iniciante', 'Escanear 5 produtos', 50,
        Icons.qr_code_scanner_rounded, 3, 5),
    _Mission('Eco Escolha', 'Escanear 3 produtos com score > 80', 100,
        Icons.eco_rounded, 1, 3),
    _Mission('Membro Ativo', 'Publicar na comunidade', 30,
        Icons.people_alt_rounded, 0, 1),
    _Mission('Quiz Mestre', 'Completar 3 quizzes', 75,
        Icons.quiz_rounded, 0, 3),
  ];

  void _select(int i) {
    if (_answered) return;
    setState(() {
      _sel = i;
      _answered = true;
      if (i == _qs[_qi].ans) {
        _pts += 10;
        HapticFeedback.lightImpact();
      }
    });
  }

  void _next() => setState(() {
    _qi = (_qi + 1) % _qs.length;
    _sel = null;
    _answered = false;
  });

  @override
  Widget build(BuildContext context) {
    final q = _qs[_qi];
    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _GamesHeader(pts: _pts)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                Text('Quiz EcoSaber', style: _kTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Pergunta ${_qi + 1} de ${_qs.length}  ·  +10 pontos por acerto',
                  style: _kCaption,
                ),
                const SizedBox(height: 10),
                _QuizCard(
                    q: q, sel: _sel, answered: _answered, onSel: _select),
                if (_answered) ...[
                  const SizedBox(height: 10),
                  _Feedback(
                      correct: _sel == q.ans, exp: q.exp, onNext: _next),
                ],
                const SizedBox(height: 24),
                Text('Missões Diárias',
                    style: _kTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                ..._missions.map(
                      (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MCard(
                      m: m,
                      onClaim: (!m.completed && m.progress >= m.total)
                          ? () => setState(() {
                        m.completed = true;
                        _pts += m.pts;
                      })
                          : null,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GamesHeader extends StatelessWidget {
  final int pts;

  const _GamesHeader({required this.pts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // eco2 — macaquinho com medalha representa conquista
          EcoImage(asset: EcoAssets.medal, size: 150),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Suas conquistas',
                    style:
                    TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '$pts pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text(
                    'Nível 2 — Guardião Verde',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Q {
  final String q, exp;
  final List<String> opts;
  final int ans;

  const _Q(this.q, this.opts, this.ans, this.exp);
}

class _Mission {
  final String title, desc;
  final int pts, progress, total;
  final IconData icon;
  bool completed;

  _Mission(this.title, this.desc, this.pts, this.icon, this.progress,
      this.total,
      {this.completed = false});
}

class _QuizCard extends StatelessWidget {
  final _Q q;
  final int? sel;
  final bool answered;
  final ValueChanged<int> onSel;

  const _QuizCard({
    required this.q,
    required this.sel,
    required this.answered,
    required this.onSel,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.q, style: _kTitle.copyWith(fontSize: 15)),
          const SizedBox(height: 14),
          ...List.generate(q.opts.length, (i) {
            Color bg = kSurface,
                border = kDivider,
                tx = kDarkGray;
            if (answered) {
              if (i == q.ans) {
                bg = const Color(0xFFE8F5E9);
                border = Colors.green;
                tx = Colors.green.shade800;
              } else if (i == sel) {
                bg = const Color(0xFFFFEBEE);
                border = Colors.red.shade300;
                tx = Colors.red.shade700;
              }
            }
            return GestureDetector(
              onTap: () => onSel(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Row(children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: kBeige.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kBrown,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(q.opts[i],
                        style: TextStyle(color: tx, fontSize: 14)),
                  ),
                  if (answered && i == q.ans)
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 18),
                  if (answered && i == sel && i != q.ans)
                    const Icon(Icons.cancel_rounded,
                        color: Colors.red, size: 18),
                ]),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

class _Feedback extends StatelessWidget {
  final bool correct;
  final String exp;
  final VoidCallback onNext;

  const _Feedback({
    required this.correct,
    required this.exp,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final c = correct ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          correct ? 'Correto! +10 pontos' : 'Resposta incorreta',
          style: TextStyle(
              fontWeight: FontWeight.w700, color: c, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(exp, style: _kBody.copyWith(fontSize: 13)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: c,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Próxima pergunta'),
          ),
        ),
      ]),
    );
  }
}

class _MCard extends StatelessWidget {
  final _Mission m;
  final VoidCallback? onClaim;

  const _MCard({required this.m, this.onClaim});

  @override
  Widget build(BuildContext context) {
    final pct = (m.progress / m.total).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kBeige.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(m.icon, color: kBrown, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title, style: _kTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(m.desc, style: _kCaption),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: kDivider,
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(kGreen),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${m.progress}/${m.total}', style: _kCaption),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('+${m.pts}pts', style: _kGreenLbl),
            const SizedBox(height: 6),
            if (m.completed)
              const Icon(Icons.check_circle_rounded, color: kGreen)
            else
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Resgatar'),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ====================================================================
// TELA 4 — CUPONS
// eco1.png no painel de pontos como guia/companheiro do usuário
// ====================================================================
class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  int _pts = 320;

  final List<_Coupon> _coupons = [
    _Coupon('10% off em produtos orgânicos', 'Hortifruti Natural',
        100, '30/04/2026', Icons.eco_rounded, kGreen),
    _Coupon('Café especial grátis', 'EcoCafé',
        80, '15/04/2026', Icons.local_cafe_rounded, kBrown),
    _Coupon('15% off em ecobags', 'Sustentável Store',
        150, '31/05/2026', Icons.shopping_bag_outlined, kLightBrown),
    _Coupon('Consulta energia solar', 'SolarTech',
        500, '30/06/2026', Icons.solar_power_rounded, Colors.amber.shade700),
    _Coupon('Plantar 1 árvore nativa', 'Refloresta Brasil',
        200, '31/12/2026', Icons.park_rounded, Colors.green.shade700),
  ];

  void _redeem(_Coupon c) {
    if (_pts < c.cost) {
      _snack('Pontos insuficientes. Você precisa de ${c.cost} pts.',
          Colors.red.shade600);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar resgate'),
        content: Text(
            'Usar ${c.cost} Ecopoints para resgatar:\n\n"${c.title}" — ${c.partner}?'),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _pts -= c.cost);
              Navigator.pop(context);
              _snack('Cupom "${c.title}" resgatado!', kGreen);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color bg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    body: CustomScrollView(
      slivers: [
        // Painel de pontos com eco1
        SliverToBoxAdapter(child: _CouponsHeader(pts: _pts)),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(children: [
                Text('Disponíveis para resgate',
                    style: _kTitle.copyWith(fontSize: 15)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text('${_coupons.length}',
                      style: _kGreenLbl),
                ),
              ]),
              const SizedBox(height: 12),
              ..._coupons.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CouponCard(
                  c: c,
                  pts: _pts,
                  onRedeem: () => _redeem(c),
                ),
              )),
              const SizedBox(height: 8),
              // Eco guia incentivando o usuário a acumular mais
              EcoBubble(
                asset: EcoAssets.standard,
                message:
                'Continue escaneando produtos sustentáveis para acumular mais pontos e resgatar recompensas!',
                mascotSize: 56,
                bubbleColor: kGreenLight.withOpacity(0.3),
              ),
            ]),
          ),
        ),
      ],
    ),
  );
}

class _CouponsHeader extends StatelessWidget {
  final int pts;

  const _CouponsHeader({required this.pts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seus Ecopoints',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '$pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                const Text('pontos disponíveis',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text(
                    'Nível Verde',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // eco1 — mascote padrão no painel de cupons
          EcoImage(asset: EcoAssets.standard, size: 130),
        ],
      ),
    );
  }
}

class _Coupon {
  final String title, partner, expiry;
  final int cost;
  final IconData icon;
  final Color color;

  const _Coupon(this.title, this.partner, this.cost, this.expiry, this.icon,
      this.color);
}

class _CouponCard extends StatelessWidget {
  final _Coupon c;
  final int pts;
  final VoidCallback onRedeem;

  const _CouponCard({
    required this.c,
    required this.pts,
    required this.onRedeem,
  });

  bool get _can => pts >= c.cost;

  @override
  Widget build(BuildContext context) => Card(
    child: IntrinsicHeight(
      child: Row(children: [
        // Faixa colorida lateral
        Container(
          width: 5,
          decoration: BoxDecoration(
            color: _can ? c.color : Colors.grey.shade300,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
        ),
        // Ícone
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (_can ? c.color : Colors.grey).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(c.icon,
                color: _can ? c.color : Colors.grey, size: 22),
          ),
        ),
        // Texto
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  c.title,
                  style: _kTitle.copyWith(
                    fontSize: 13,
                    color: _can ? kDarkGray : kMidGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(c.partner, style: _kCaption),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.timer_outlined,
                      size: 12,
                      color: _can ? kGreen : Colors.grey),
                  const SizedBox(width: 3),
                  Text(
                    'Válido até ${c.expiry}',
                    style: _kCaption.copyWith(
                        color: _can ? kGreen : Colors.grey),
                  ),
                ]),
              ],
            ),
          ),
        ),
        // Custo + botão
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${c.cost} pts',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _can ? c.color : kMidGray,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: _can ? onRedeem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _can ? c.color : Colors.grey.shade200,
                    foregroundColor:
                    _can ? Colors.white : kMidGray,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: Size.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: Text(_can ? 'Resgatar' : 'Sem pts'),
                ),
              ),
            ],
          ),
        ),
      ]),
    ),
  );
}