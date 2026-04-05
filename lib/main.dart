// ============================================================
// EcoBadge v3.0 — App de Sustentabilidade com mascote Eco
// Arquivo: main.dart
//
// ── pubspec.yaml ────────────────────────────────────────────
//  dependencies:
//    flutter:
//      sdk: flutter
//    mobile_scanner: ^5.2.3
//    http: ^1.2.1
//
//  flutter:
//    assets:
//      - assets/eco1.png   # macaquinho padrão
//      - assets/eco2.png   # macaquinho com medalha
//      - assets/eco3.png   # macaquinho na árvore
//
// ── AndroidManifest.xml ─────────────────────────────────────
//  <uses-permission android:name="android.permission.CAMERA"/>
//  <uses-permission android:name="android.permission.INTERNET"/>
//
// ── Estrutura de pastas ──────────────────────────────────────
//  lib/
//    main.dart
//  assets/
//    eco1.png
//    eco2.png
//    eco3.png
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

// ============================================================
// PALETA DE CORES
// ============================================================
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

// ============================================================
// ESTILOS DE TEXTO
// ============================================================
const _kTitle    = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kDarkGray, letterSpacing: -0.3);
const _kHeading  = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kDarkGray, letterSpacing: -0.5);
const _kSubtitle = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: kMidGray);
const _kBody     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: kDarkGray, height: 1.5);
const _kCaption  = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kMidGray, letterSpacing: 0.2);
const _kGreenLbl = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGreen);

// Caminhos dos assets do mascote
class EcoAssets {
  static const standard = 'assets/eco1.png'; // padrão / boas-vindas
  static const medal    = 'assets/eco2.png'; // com medalha / conquistas
  static const tree     = 'assets/eco3.png'; // na árvore / comunidade
}

// ============================================================
// PONTO DE ENTRADA
// ============================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const EcoBadgeApp());
}

// ============================================================
// APP ROOT
// ============================================================
class EcoBadgeApp extends StatelessWidget {
  const EcoBadgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoBadge',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: const MainScreen(),
    );
  }

  ThemeData _theme() => ThemeData(
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
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
          color: kDarkGray, letterSpacing: -0.5),
      systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark),
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
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

// ============================================================
// TELA PRINCIPAL — navegação por abas
// ============================================================
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
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scanner'),
              BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded),      label: 'Comunidade'),
              BottomNavigationBarItem(icon: Icon(Icons.sports_esports_rounded),  label: 'Games'),
              BottomNavigationBarItem(icon: Icon(Icons.card_giftcard_rounded),   label: 'Cupons'),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET REUTILIZÁVEL: Mascote Eco com imagem real
// ============================================================

/// Exibe o mascote Eco com tamanho configurável.
/// [asset] deve ser um dos valores em [EcoAssets].
/// [removeBlackBg] aplica BlendMode para remover o fundo preto das imagens.
class EcoMascot extends StatelessWidget {
  final String asset;
  final double size;
  final BoxFit fit;

  const EcoMascot({
    super.key,
    required this.asset,
    this.size = 80,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    // As imagens do mascote têm fundo preto — usamos ColorFilter para removê-lo.
    // O blend mode "multiply" mantém as cores da arte e apaga o preto.
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: fit,
        // Fundo preto das imagens é tratado via color + blendMode na Image diretamente
        color: null,
      ),
    );
  }
}

/// Versão com remoção do fundo preto usando ShaderMask
class EcoImage extends StatelessWidget {
  final String asset;
  final double size;

  const EcoImage({super.key, required this.asset, this.size = 80});

  @override
  Widget build(BuildContext context) {
    // Usamos Image com colorBlendMode para tratar o fundo preto das imagens PNG
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // BlendMode.multiply torna o preto transparente quando combinado com branco
      colorBlendMode: BlendMode.multiply,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

// ============================================================
// WIDGET: Balão de fala do Eco (speech bubble)
// ============================================================
class EcoBubble extends StatelessWidget {
  final String asset;
  final String message;
  final double mascotSize;
  final Color? bubbleColor;

  const EcoBubble({
    super.key,
    required this.asset,
    required this.message,
    this.mascotSize = 70,
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
          // Mascote
          SizedBox(
            width: mascotSize,
            height: mascotSize,
            child: EcoImage(asset: asset, size: mascotSize),
          ),
          const SizedBox(width: 12),
          // Balão de texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Eco diz:',
                    style: TextStyle(fontWeight: FontWeight.w700, color: kBrown, fontSize: 12)),
                const SizedBox(height: 4),
                Text(message, style: _kBody.copyWith(fontSize: 13, color: kDarkGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TELA 1 — SCANNER
// ============================================================
enum _ScanState { scanning, loading, result, notFound, networkError }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {

  final MobileScannerController _cam = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  _ScanState _state = _ScanState.scanning;
  ProductData? _product;
  String? _lastCode;
  bool _processing = false;
  Timer? _debounce;

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
  }

  @override
  void dispose() {
    _cam.dispose();
    _debounce?.cancel();
    _lineCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final code = capture.barcodes
        .where((b) => b.rawValue != null)
        .map((b) => b.rawValue!)
        .firstOrNull;
    if (code == null || code == _lastCode) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetch(code));
  }

  Future<void> _fetch(String code) async {
    if (_processing) return;
    _processing = true;
    _lastCode = code;
    HapticFeedback.mediumImpact();
    setState(() => _state = _ScanState.loading);
    _cam.stop();
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

  void _reset() {
    setState(() {
      _state = _ScanState.scanning;
      _product = null;
      _lastCode = null;
    });
    _cam.start();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _ScanState.scanning     => _buildCamera(),
      _ScanState.loading      => _buildLoading(),
      _ScanState.result       => _buildResult(),
      _ScanState.notFound     => _buildFeedback(
        mascotAsset: EcoAssets.standard,
        icon: Icons.search_off_rounded,
        title: 'Produto não encontrado',
        body: 'Este código não está em nossa base.\nTente escanear outro produto.',
      ),
      _ScanState.networkError => _buildFeedback(
        mascotAsset: EcoAssets.standard,
        icon: Icons.wifi_off_rounded,
        title: 'Sem conexão',
        body: 'Verifique sua internet e tente novamente.',
      ),
    };
  }

  // ── UI: câmera ──────────────────────────────────────────
  Widget _buildCamera() {
    final sw = MediaQuery.of(context).size.width;
    final frameW = sw * 0.72;
    const frameH = 150.0;

    return Stack(fit: StackFit.expand, children: [
      MobileScanner(controller: _cam, onDetect: _onDetect),
      _ScanOverlay(frameWidth: frameW, frameHeight: frameH),

      // Linha de scan animada
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
        child: SafeArea(child: _CamTopBar(
          onFlash: () => _cam.toggleTorch(),
          onFlip:  () => _cam.switchCamera(),
        )),
      ),

      // Rodapé
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: _CamBottomBar(onDemo: _runDemo),
      ),
    ]);
  }

  // ── UI: loading com mascote ──────────────────────────────
  Widget _buildLoading() => Scaffold(
    backgroundColor: kBackground,
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        EcoImage(asset: EcoAssets.standard, size: 90),
        const SizedBox(height: 20),
        const CircularProgressIndicator(color: kGreen, strokeWidth: 2.5),
        const SizedBox(height: 16),
        const Text('Buscando produto...', style: _kSubtitle),
      ]),
    ),
  );

  // ── UI: resultado ────────────────────────────────────────
  Widget _buildResult() {
    // Eco feliz (medalha) para produtos sustentáveis, padrão para os demais
    final mascotAsset = (_product?.ecoScore ?? 0) >= 70
        ? EcoAssets.medal
        : EcoAssets.standard;

    final ecoMsg = (_product?.ecoScore ?? 0) >= 80
        ? 'Ótima escolha! Este produto tem excelente pontuação de sustentabilidade.'
        : (_product?.ecoScore ?? 0) >= 60
        ? 'Boa escolha. Lembre-se de descartar a embalagem corretamente.'
        : 'Existem alternativas mais sustentáveis. Considere explorar opções orgânicas.';

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(children: [
          _BackBar(label: 'Resultado do Scan', onBack: _reset),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ProductCard(product: _product!),
                const SizedBox(height: 14),
                _EcoScoreCard(score: _product!.ecoScore),
                const SizedBox(height: 14),
                if (_product!.hasDetails) ...[
                  _DetailsCard(product: _product!),
                  const SizedBox(height: 14),
                ],
                // Eco com feedback visual baseado no score
                EcoBubble(
                  asset: mascotAsset,
                  message: ecoMsg,
                  mascotSize: 72,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Escanear outro produto'),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── UI: erro / não encontrado ────────────────────────────
  Widget _buildFeedback({
    required String mascotAsset,
    required IconData icon,
    required String title,
    required String body,
  }) => Scaffold(
    backgroundColor: kBackground,
    body: SafeArea(
      child: Column(children: [
        _BackBar(label: 'Scanner', onBack: _reset),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                EcoImage(asset: mascotAsset, size: 100),
                const SizedBox(height: 20),
                Text(title, style: _kTitle, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(body, style: _kSubtitle, textAlign: TextAlign.center),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tentar novamente'),
                ),
              ]),
            ),
          ),
        ),
      ]),
    ),
  );

  void _runDemo() {
    final codes = ['7891910000197', '7894900011517', '7891000315507'];
    _fetch(codes[DateTime.now().millisecond % codes.length]);
  }
}

// ── Scanner overlay (vinheta + moldura com cantos) ─────────
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
    final cx = size.width / 2, cy = size.height / 2;
    final l = cx - fw / 2, t = cy - fh / 2, r = cx + fw / 2, b = cy + fh / 2;
    const rad = 12.0;

    final bg = Paint()..color = Colors.black.withOpacity(0.58);
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()
      ..addRRect(RRect.fromLTRBR(l, t, r, b, const Radius.circular(rad)));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), bg);

    const cLen = 22.0;
    final cp = Paint()
      ..color = kGreen ..strokeWidth = 3
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;

    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y + dy * rad), Offset(x, y + dy * cLen), cp);
      canvas.drawLine(Offset(x + dx * rad, y), Offset(x + dx * cLen, y), cp);
    }
    corner(l, t, 1, 1); corner(r, t, -1, 1);
    corner(l, b, 1, -1); corner(r, b, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Barra superior da câmera ───────────────────────────────
class _CamTopBar extends StatelessWidget {
  final VoidCallback onFlash, onFlip;
  const _CamTopBar({required this.onFlash, required this.onFlip});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Text('EcoBadge', style: TextStyle(
          color: Colors.white, fontSize: 20,
          fontWeight: FontWeight.w700, letterSpacing: -0.5,
        )),
      ),
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
    child: InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22)),
    ),
  );
}

// ── Rodapé da câmera ───────────────────────────────────────
class _CamBottomBar extends StatelessWidget {
  final VoidCallback onDemo;
  const _CamBottomBar({required this.onDemo});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter, end: Alignment.topCenter,
        colors: [Colors.black.withOpacity(0.65), Colors.transparent],
      ),
    ),
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 38),
    child: SafeArea(
      top: false,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Aponte a câmera para o código de barras',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onDemo,
          icon: const Icon(Icons.science_outlined, size: 16, color: Colors.white60),
          label: const Text('Demonstração', style: TextStyle(color: Colors.white60, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
        ),
      ]),
    ),
  );
}

// ── Barra de voltar reutilizável ──────────────────────────
class _BackBar extends StatelessWidget {
  final String label;
  final VoidCallback onBack;
  const _BackBar({required this.label, required this.onBack});

  @override
  Widget build(BuildContext context) => Row(children: [
    IconButton(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: kDarkGray),
    ),
    Text(label, style: _kTitle),
  ]);
}

// ── Card do produto ────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductData product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Imagem do produto ou placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.imageUrl != null
                ? Image.network(product.imageUrl!, width: 70, height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imgFallback())
                : _imgFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: _kTitle),
            if (product.brand.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(product.brand, style: _kSubtitle),
            ],
            const SizedBox(height: 8),
            _Chip(label: product.category),
          ])),
        ]),
        if (product.quantity.isNotEmpty || product.countries.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (product.quantity.isNotEmpty) _KV('Quantidade', product.quantity),
          if (product.countries.isNotEmpty) ...[
            const SizedBox(height: 6),
            _KV('Origem', product.countries),
          ],
        ],
      ]),
    ),
  );

  Widget _imgFallback() => Container(
    width: 70, height: 70,
    color: kBeige.withOpacity(0.3),
    child: const Icon(Icons.inventory_2_outlined, color: kBrown, size: 30),
  );
}

// ── EcoScore card ──────────────────────────────────────────
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pontuação de Sustentabilidade', style: _kTitle),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(_grade, style: const TextStyle(
              color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800,
            ))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_desc, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _color)),
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
          ])),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.add_circle_outline_rounded, color: kGreen, size: 18),
          const SizedBox(width: 6),
          Text('+${(score / 10).round()} Ecopoints adicionados', style: _kGreenLbl),
        ]),
      ]),
    ),
  );
}

// ── Detalhes do produto ────────────────────────────────────
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Detalhes do Produto', style: _kTitle),
          const SizedBox(height: 12),
          for (int i = 0; i < rows.length; i++) ...[
            _DetailRow(row: rows[i]),
            if (i < rows.length - 1) const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
          ],
        ]),
      ),
    );
  }
}

class _DRow { final IconData icon; final String label, value;
const _DRow({required this.icon, required this.label, required this.value}); }

class _DetailRow extends StatelessWidget {
  final _DRow row;
  const _DetailRow({required this.row});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(row.icon, size: 18, color: kGreen),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(row.label, style: _kCaption),
        const SizedBox(height: 2),
        Text(row.value, style: _kBody.copyWith(fontSize: 13)),
      ])),
    ],
  );
}

// ── Chips e pares chave-valor ──────────────────────────────
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

// ============================================================
// SERVIÇO: Open Food Facts API + fallback local
// ============================================================
class ProductService {
  static const _api = 'https://world.openfoodfacts.org/api/v0/product';

  static const Map<String, ProductData> _local = {
    '7891910000197': ProductData(
      name: 'Arroz Integral Orgânico', brand: 'Camil Orgânico',
      category: 'Cereais', ecoScore: 91, quantity: '1 kg',
      packaging: 'Embalagem biodegradável', countries: 'Brasil',
      ingredients: 'Arroz integral orgânico',
      labels: ['Orgânico Brasil', 'IBD'], imageUrl: null,
    ),
    '7894900011517': ProductData(
      name: 'Refrigerante Cola', brand: 'Coca-Cola',
      category: 'Bebidas', ecoScore: 42, quantity: '350 ml',
      packaging: 'Lata de alumínio reciclável', countries: 'Brasil',
      ingredients: 'Água gaseificada, açúcar, extrato de noz de cola, caramelo, ácido fosfórico, cafeína',
      labels: [], imageUrl: null,
    ),
    '7891000315507': ProductData(
      name: 'Água Mineral Natural', brand: 'Crystal',
      category: 'Bebidas', ecoScore: 80, quantity: '500 ml',
      packaging: 'Garrafa PET reciclável', countries: 'Brasil',
      ingredients: 'Água mineral natural',
      labels: ['ISO 14001'], imageUrl: null,
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
    int eco = 50;
    final raw = p['ecoscore_score'];
    if (raw != null) {
      eco = (raw as num).toInt().clamp(0, 100);
    } else {
      final ns = (p['nutriscore_grade'] as String? ?? '').toUpperCase();
      eco = switch (ns) { 'A' => 85, 'B' => 70, 'C' => 55, 'D' => 40, 'E' => 25, _ => 50 };
    }

    String cat = 'Produto alimentar';
    final cats = p['categories'] as String? ?? '';
    if (cats.isNotEmpty) {
      final parts = cats.split(',');
      cat = parts.last.trim().replaceAll(RegExp(r'^[a-z]{2}:'), '');
      if (cat.isEmpty || cat.length > 35) {
        cat = parts.first.trim().replaceAll(RegExp(r'^[a-z]{2}:'), '');
      }
    }

    final lTags = p['labels_tags'] as List<dynamic>? ?? [];
    final labels = lTags
        .map((l) => l.toString().replaceAll(RegExp(r'^[a-z]{2}:'), '').replaceAll('-', ' '))
        .where((l) => l.isNotEmpty)
        .take(3)
        .toList();

    return ProductData(
      name:        _s(p['product_name'] ?? p['product_name_pt'] ?? 'Produto sem nome'),
      brand:       _s(p['brands']),
      category:    cat,
      ecoScore:    eco,
      quantity:    _s(p['quantity']),
      packaging:   _s(p['packaging']),
      ingredients: _s(p['ingredients_text_pt'] ?? p['ingredients_text']),
      labels:      labels,
      countries:   _s(p['countries']),
      imageUrl:    p['image_url'] as String?,
    );
  }

  static String _s(dynamic v) => (v ?? '').toString().trim();
}

class ProductData {
  final String name, brand, category, quantity, packaging, ingredients, countries;
  final List<String> labels;
  final int ecoScore;
  final String? imageUrl;

  const ProductData({
    required this.name, required this.brand, required this.category,
    required this.ecoScore, required this.quantity, required this.packaging,
    required this.ingredients, required this.labels,
    required this.countries, required this.imageUrl,
  });

  bool get hasDetails => packaging.isNotEmpty || ingredients.isNotEmpty || labels.isNotEmpty;
}

// ============================================================
// TELA 2 — COMUNIDADE
// Usa eco3.png (macaquinho na árvore) — reforça tema ecológico
// ============================================================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<_Post> _posts = [
    _Post(author: 'Ana Clara',       initials: 'AC', color: kGreen,             time: '2h',
        tag: 'Dica',        tagColor: kGreen,
        body: 'Comecei a fazer compostagem em casa esta semana. Cascas de legumes, borra de café e folhas secas — tudo vira adubo em poucas semanas. Altamente recomendo!',
        likes: 34, comments: 8),
    _Post(author: 'EmanuelFo',        initials: 'EF', color: kBrown,             time: '5h',
        tag: 'Novidade',    tagColor: kBrown,
        body: 'Produtos com certificação orgânica agora valem pontuação dobrada esta semana. Escanear mais para ganhar mais Ecopoints!',
        likes: 127, comments: 23),
    _Post(author: 'Treetech', initials: 'TT', color: kLightBrown,        time: '1d',
        tag: 'Curiosidade', tagColor: kLightBrown,
        body: 'Uma sacola plástica convencional leva até 400 anos para se decompor. Substituir por ecobags é uma das mudanças mais simples e impactantes possíveis.',
        likes: 89, comments: 15),
    _Post(author: 'CH',     initials: 'CH', color: Colors.blueGrey,    time: '2d',
        tag: 'Ação',        tagColor: Colors.blueGrey,
        body: 'Participei da limpeza da praia hoje — recolhemos mais de 50 kg de resíduos em 3 horas. É incrível o que um grupo pequeno consegue fazer.',
        likes: 214, comments: 41),
    _Post(author: 'João Sousas',       initials: 'JS', color: Colors.amber.shade700, time: '3d',
        tag: 'Experiência', tagColor: Colors.amber.shade700,
        body: 'Instalei painéis solares no ano passado e a conta de energia caiu 80%. O retorno do investimento acontece em torno de 4 anos.',
        likes: 156, comments: 29),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          // Header com eco3 (macaquinho na árvore)
          SliverToBoxAdapter(child: _CommunityHeader()),

          // AppBar flutuante
          SliverAppBar(
            pinned: true,
            backgroundColor: kBackground,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: kDivider),
            ),
          ),

          // Posts
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                  if (i.isOdd) return const SizedBox(height: 10);
                  final postIdx = i ~/ 2;
                  return _PostCard(
                    post: _posts[postIdx],
                    onLike: () => setState(() => _posts[postIdx].toggleLike()),
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Cabeçalho da comunidade com o mascote na árvore (eco3)
class _CommunityHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comunidade', style: _kHeading),
                const SizedBox(height: 6),
                Text('Compartilhe ideias e inspire quem está ao seu redor.',
                    style: _kSubtitle),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // eco3: macaquinho na árvore — símbolo da comunidade verde
          SizedBox(
            width: 150,
            height: 150,
            child: EcoImage(asset: EcoAssets.tree, size: 150),
          ),
        ],
      ),
    );
  }
}

class _Post {
  final String author, initials, time, tag, body;
  final Color color, tagColor;
  final int comments;
  int likes;
  bool liked;

  _Post({required this.author, required this.initials, required this.color,
    required this.time, required this.tag, required this.tagColor,
    required this.body, required this.likes, required this.comments,
    this.liked = false});

  void toggleLike() { liked = !liked; likes += liked ? 1 : -1; }
}

class _PostCard extends StatelessWidget {
  final _Post post;
  final VoidCallback onLike;
  const _PostCard({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: post.color, radius: 18,
            child: Text(post.initials, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.author, style: _kTitle.copyWith(fontSize: 14)),
            Text('há ${post.time}', style: _kCaption),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: post.tagColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(post.tag, style: TextStyle(
                color: post.tagColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(post.body, style: _kBody),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(children: [
          _ActBtn(
            icon: post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: '${post.likes}',
            color: post.liked ? Colors.red : kMidGray,
            onTap: onLike,
          ),
          const SizedBox(width: 18),
          _ActBtn(icon: Icons.chat_bubble_outline_rounded,
              label: '${post.comments}', color: kMidGray, onTap: () {}),
          const Spacer(),
          _ActBtn(icon: Icons.share_outlined,
              label: 'Compartilhar', color: kMidGray, onTap: () {}),
        ]),
      ]),
    ),
  );
}

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ============================================================
// TELA 3 — GAMES
// Usa eco2.png (macaquinho com medalha) — conquistas
// ============================================================
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
    _Q('Quanto tempo uma garrafa PET leva para se decompor na natureza?',
        ['50 anos', '100 anos', '400 anos', '1.000 anos'], 2,
        'Garrafas PET podem levar até 400 anos para se decompor, liberando microplásticos ao longo desse tempo.'),
    _Q('Qual material demora mais para se decompor?',
        ['Vidro', 'Papel', 'Plástico', 'Metal'], 0,
        'O vidro pode levar mais de 1 milhão de anos para se decompor completamente.'),
    _Q('Quantos litros de água são necessários para produzir 1 kg de carne bovina?',
        ['500 L', '2.000 L', '5.000 L', '15.000 L'], 3,
        'A produção de 1 kg de carne bovina consome cerca de 15.000 litros de água, considerando toda a cadeia.'),
    _Q('O que é a pegada de carbono?',
        ['Resíduos no solo', 'Total de CO₂ emitido por atividades humanas',
          'Reserva de carbono', 'Combustível fóssil'], 1,
        'A pegada de carbono mede o total de gases de efeito estufa emitidos direta ou indiretamente por uma atividade.'),
  ];

  final List<_Mission> _missions = [
    _Mission('Escaneador Iniciante', 'Escanear 5 produtos', 50, Icons.qr_code_scanner_rounded, 3, 5),
    _Mission('Eco Escolha', 'Escanear 3 produtos com score > 80', 100, Icons.eco_rounded, 1, 3),
    _Mission('Membro Ativo', 'Publicar na comunidade', 30, Icons.people_alt_rounded, 0, 1),
    _Mission('Quiz Mestre', 'Completar 3 quizzes', 75, Icons.quiz_rounded, 0, 3),
  ];

  void _select(int i) {
    if (_answered) return;
    setState(() {
      _sel = i;
      _answered = true;
      if (i == _qs[_qi].ans) { _pts += 10; HapticFeedback.lightImpact(); }
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
          // Header com eco2 (com medalha) — representa conquistas
          SliverToBoxAdapter(child: _GamesHeader(pts: _pts)),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                Text('Quiz EcoSaber', style: _kTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text('Pergunta ${_qi + 1} de ${_qs.length}  ·  +10 pontos por acerto',
                    style: _kCaption),
                const SizedBox(height: 10),
                _QuizCard(q: q, sel: _sel, answered: _answered, onSel: _select),
                if (_answered) ...[
                  const SizedBox(height: 10),
                  _Feedback(correct: _sel == q.ans, exp: q.exp, onNext: _next),
                ],
                const SizedBox(height: 24),
                Text('Missões Diárias', style: _kTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                ..._missions.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MCard(
                    m: m,
                    onClaim: (!m.completed && m.progress >= m.total)
                        ? () => setState(() { m.completed = true; _pts += m.pts; })
                        : null,
                  ),
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabeçalho da tela de games com eco2 (medalha) e pontuação
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // eco2: macaquinho com medalha — símbolo de conquista
          EcoImage(asset: EcoAssets.medal, size: 140),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Suas conquistas', style: TextStyle(
                    color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('$pts pts', style: const TextStyle(
                    color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.w800, letterSpacing: -1)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text('Nível 2 — Guardião Verde',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 12)),
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
  _Mission(this.title, this.desc, this.pts, this.icon, this.progress, this.total,
      {this.completed = false});
}

class _QuizCard extends StatelessWidget {
  final _Q q;
  final int? sel;
  final bool answered;
  final ValueChanged<int> onSel;
  const _QuizCard({required this.q, required this.sel, required this.answered, required this.onSel});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(q.q, style: _kTitle.copyWith(fontSize: 15)),
        const SizedBox(height: 14),
        ...List.generate(q.opts.length, (i) {
          Color bg = kSurface, border = kDivider, tx = kDarkGray;
          if (answered) {
            if (i == q.ans) { bg = const Color(0xFFE8F5E9); border = Colors.green; tx = Colors.green.shade800; }
            else if (i == sel) { bg = const Color(0xFFFFEBEE); border = Colors.red.shade300; tx = Colors.red.shade700; }
          }
          return GestureDetector(
            onTap: () => onSel(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Row(children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: kBeige.withOpacity(0.4), shape: BoxShape.circle),
                  child: Center(child: Text(String.fromCharCode(65 + i),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: kBrown, fontSize: 12))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(q.opts[i], style: TextStyle(color: tx, fontSize: 14))),
                if (answered && i == q.ans)
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                if (answered && i == sel && i != q.ans)
                  const Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
              ]),
            ),
          );
        }),
      ]),
    ),
  );
}

class _Feedback extends StatelessWidget {
  final bool correct;
  final String exp;
  final VoidCallback onNext;
  const _Feedback({required this.correct, required this.exp, required this.onNext});

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
        Text(correct ? 'Correto! +10 pontos' : 'Resposta incorreta',
            style: TextStyle(fontWeight: FontWeight.w700, color: c, fontSize: 14)),
        const SizedBox(height: 6),
        Text(exp, style: _kBody.copyWith(fontSize: 13)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: c, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: kBeige.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
            child: Icon(m.icon, color: kBrown, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: _kTitle.copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(m.desc, style: _kCaption),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct, backgroundColor: kDivider,
                  valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
                  minHeight: 6,
                ),
              )),
              const SizedBox(width: 8),
              Text('${m.progress}/${m.total}', style: _kCaption),
            ]),
          ])),
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
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

// ============================================================
// TELA 4 — CUPONS
// Usa eco1.png (padrão) no painel de pontos — como guia
// ============================================================
class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  int _pts = 320;

  final List<_Coupon> _coupons = [
    _Coupon('10% off em produtos orgânicos', 'Hortifruti Natural',  100, '30/04/2026', Icons.eco_rounded,          kGreen),
    _Coupon('Café especial grátis',          'EcoCafé',              80,  '15/04/2026', Icons.local_cafe_rounded,   kBrown),
    _Coupon('15% off em ecobags',            'Sustentável Store',   150, '31/05/2026', Icons.shopping_bag_outlined, kLightBrown),
    _Coupon('Consulta energia solar',        'SolarTech',           500, '30/06/2026', Icons.solar_power_rounded,  Colors.amber.shade700),
    _Coupon('Plantar 1 árvore nativa',       'Refloresta Brasil',   200, '31/12/2026', Icons.park_rounded,         Colors.green.shade700),
  ];

  void _redeem(_Coupon c) {
    if (_pts < c.cost) {
      _snack('Pontos insuficientes. Você precisa de ${c.cost} pts.', Colors.red.shade600);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar resgate'),
        content: Text('Usar ${c.cost} Ecopoints para resgatar:\n\n"${c.title}" — ${c.partner}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    body: CustomScrollView(
      slivers: [
        // Painel de pontos com eco1 (padrão)
        SliverToBoxAdapter(child: _CouponsHeader(pts: _pts)),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Título da lista
              Row(children: [
                Text('Disponíveis para resgate', style: _kTitle.copyWith(fontSize: 15)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text('${_coupons.length}', style: _kGreenLbl),
                ),
              ]),
              const SizedBox(height: 12),
              ..._coupons.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CouponCard(c: c, pts: _pts, onRedeem: () => _redeem(c)),
              )),

              // Eco guia: mensagem de incentivo com eco1
              const SizedBox(height: 8),
              EcoBubble(
                asset: EcoAssets.standard,
                message: 'Continue escaneando produtos sustentáveis para acumular mais pontos e resgatar recompensas!',
                mascotSize: 60,
                bubbleColor: kGreenLight.withOpacity(0.3),
              ),
            ]),
          ),
        ),
      ],
    ),
  );
}

/// Painel de pontos com eco1 e dica de saldo
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
                const Text('Seus Ecopoints', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('$pts', style: const TextStyle(
                    color: Colors.white, fontSize: 40,
                    fontWeight: FontWeight.w800, letterSpacing: -1.5)),
                const Text('pontos disponíveis',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text('Nível Verde',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
          // eco1: macaquinho padrão como representante da conta do usuário
          EcoImage(asset: EcoAssets.standard, size: 150),
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
  const _Coupon(this.title, this.partner, this.cost, this.expiry, this.icon, this.color);
}

class _CouponCard extends StatelessWidget {
  final _Coupon c;
  final int pts;
  final VoidCallback onRedeem;
  const _CouponCard({required this.c, required this.pts, required this.onRedeem});

  bool get _can => pts >= c.cost;

  @override
  Widget build(BuildContext context) => Card(
    child: IntrinsicHeight(
      child: Row(children: [
        // Faixa colorida
        Container(
          width: 5,
          decoration: BoxDecoration(
            color: _can ? c.color : Colors.grey.shade300,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), bottomLeft: Radius.circular(16),
            ),
          ),
        ),
        // Ícone
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (_can ? c.color : Colors.grey).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(c.icon, color: _can ? c.color : Colors.grey, size: 22),
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
                Text(c.title, style: _kTitle.copyWith(
                    fontSize: 13, color: _can ? kDarkGray : kMidGray)),
                const SizedBox(height: 2),
                Text(c.partner, style: _kCaption),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.timer_outlined, size: 12, color: _can ? kGreen : Colors.grey),
                  const SizedBox(width: 3),
                  Text('Válido até ${c.expiry}',
                      style: _kCaption.copyWith(color: _can ? kGreen : Colors.grey)),
                ]),
              ],
            ),
          ),
        ),
        // Custo + botão
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${c.cost} pts', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13,
                color: _can ? c.color : kMidGray)),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: _can ? onRedeem : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _can ? c.color : Colors.grey.shade200,
                  foregroundColor: _can ? Colors.white : kMidGray,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: Size.zero, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: Text(_can ? 'Resgatar' : 'Sem pts'),
              ),
            ),
          ]),
        ),
      ]),
    ),
  );
}