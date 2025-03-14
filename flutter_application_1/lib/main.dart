import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

enum GameState { start, playing, gameOver }

void main() {
  runApp(SpaceInvadersApp());
}

class SpaceInvadersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      title: 'Space Invaders',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class Inimiga {
  final Rect rect;
  Timer? timer;

  Inimiga(this.rect);
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameState gameState = GameState.start;

  // Variáveis do jogo
  double navePositionX = 0.0;
  bool moveEsquerda = false;
  bool moveDireita = false;
  Timer? _timerMovimento;
  List<Rect> tiros = [];
  Timer? _timerTiros;
  bool _podeDisparar = true;

  // Naves Inimigas
  List<Inimiga> inimigas = [];
  int round = 1;
  Timer? _timerRound;
  bool _entreRounds = false;

  // Tiros da Nave Inimiga
  List<Rect> tirosInimigos = [];
  Timer? _timerTirosInimigos;
  Timer? _timerMovimentoTirosInimigos;

  

  // Vida da Nave
  int vida = 3;

  // Pontuação
  int pontuacao = 0;

  // Tamanho das naves
  final double naveLargura = 50;
  final double naveAltura = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelarTimers();
    super.dispose();
  }

  void _cancelarTimers() {
    _timerMovimento?.cancel();
    _timerTiros?.cancel();
    _timerTirosInimigos?.cancel();
    _timerRound?.cancel();
    _timerMovimentoTirosInimigos?.cancel();
    for (var inimiga in inimigas) {
      inimiga.timer?.cancel();
    }
  }

  void iniciarJogo() {
    _cancelarTimers();
    setState(() {
      gameState = GameState.playing;
      vida = 3;
      pontuacao = 0;
      round = 1;
      navePositionX = (MediaQuery.of(context).size.width / 2 - naveLargura / 2);
      tiros = [];
      tirosInimigos = [];
      _entreRounds = false;
    });
    _iniciarRound();
  }

  void _iniciarRound() {
  // Cancela TODOS os Timers relacionados a tiros
  _timerTiros?.cancel();
  _timerTiros = null;
  _timerTirosInimigos?.cancel();
  _timerTirosInimigos = null;
  _timerMovimentoTirosInimigos?.cancel();
  _timerMovimentoTirosInimigos = null;

  for (var inimiga in inimigas) {
    inimiga.timer?.cancel();
  }

  setState(() {
    inimigas = _criarNavesInimigas();
    _entreRounds = false;
    tiros = [];
    tirosInimigos = [];
  });

  // Movimentação dos Tiros do Jogador
  _timerTiros = Timer.periodic(Duration(milliseconds: 50), (timer) {
    if (!mounted || gameState != GameState.playing) return;
    try {
      setState(() {
        // Atualiza tiros do jogador
        tiros = tiros
            .map((tiro) => tiro.translate(0, -10))
            .where((tiro) => tiro.top > -5)
            .toList();

        // Verifica colisões
        List<Inimiga> inimigasParaRemover = [];
        List<Rect> tirosParaRemover = [];
        for (var tiro in tiros) {
          for (var inimiga in inimigas) {
            if (tiro.overlaps(inimiga.rect)) {
              inimigasParaRemover.add(inimiga);
              tirosParaRemover.add(tiro);
              pontuacao += 10;
              inimiga.timer?.cancel(); // Cancela o timer ao destruir a nave
            }
          }
        }

        // Remove elementos após a iteração
        inimigas.removeWhere((inimiga) => inimigasParaRemover.contains(inimiga));
        tiros.removeWhere((tiro) => tirosParaRemover.contains(tiro));

        // Avança para o próximo round apenas uma vez
        if (inimigas.isEmpty && !_entreRounds) {
          _proximoRound();
        }
      });
    } catch (e) {
      print("Erro no movimento dos tiros: $e");
    }
  });

  // Iniciar Tiros da Nave Inimiga
  iniciarTirosInimigos(); // <--- CHAMADA DO MÉTODO
}

  List<Inimiga> _criarNavesInimigas() {
    List<Inimiga> naves = [];
    double espacamento = 10;
    double startY = 50;
    double startX = 20;
    Random random = Random();

    for (int i = 0; i < 10; i++) {
      Rect rect = Rect.fromLTWH(
        startX + (i * (naveLargura + espacamento)),
        startY,
        naveLargura,
        naveAltura,
      );

      Inimiga inimiga = Inimiga(rect);
      _iniciarTimerInimiga(inimiga, random); // Inicia o timer para esta nave
      naves.add(inimiga);
    }
    return naves;
  }

  void _iniciarTimerInimiga(Inimiga inimiga, Random random) {
    inimiga.timer = Timer(Duration(seconds: 2 + random.nextInt(4)), () {
      if (!mounted || gameState != GameState.playing) return;

      setState(() {
        tirosInimigos.add(Rect.fromLTWH(
          inimiga.rect.left + naveLargura / 2 - 5,
          inimiga.rect.bottom,
          10,
          20,
        ));
      });

      _iniciarTimerInimiga(inimiga, random); // Reinicia o timer com novo intervalo
    });
  }

  void _proximoRound() {
    setState(() {
      _entreRounds = true; // Evita múltiplas chamadas
    });

    _timerRound = Timer(Duration(seconds: 5), () {
      if (!mounted || gameState != GameState.playing) return;
      setState(() {
        round++; // Incrementa apenas uma vez
        _iniciarRound();
      });
    });
  }

void iniciarTirosInimigos() {
  // Cancela o Timer existente antes de criar um novo
  _timerTirosInimigos?.cancel();
  _timerTirosInimigos = null;

  // Cria um novo Timer para os tiros inimigos
  _timerTirosInimigos = Timer.periodic(Duration(seconds: 2), (timer) {
    if (!mounted || gameState != GameState.playing || inimigas.isEmpty) return;
    setState(() {
      int index = Random().nextInt(inimigas.length);
      Inimiga inimiga = inimigas[index];
      tirosInimigos.add(Rect.fromLTWH(
        inimiga.rect.left + naveLargura / 2 - 5,
        inimiga.rect.bottom,
        10,
        20,
      ));
    });
  });

  // Movimentar Tiros Inimigos
  _timerMovimentoTirosInimigos?.cancel();
  _timerMovimentoTirosInimigos = Timer.periodic(Duration(milliseconds: 50), (timer) {
    if (!mounted || gameState != GameState.playing) return;
    setState(() {
      tirosInimigos = tirosInimigos
          .map((tiro) => tiro.translate(0, 5))
          .where((tiro) {
            bool atingeNave = tiro.overlaps(Rect.fromLTWH(
              navePositionX,
              MediaQuery.of(context).size.height - 145,
              naveLargura,
              naveAltura,
            ));
            if (atingeNave) {
              vida--;
              if (vida <= 0) gameState = GameState.gameOver;
              return false; // Remove o tiro
            }
            return tiro.top < MediaQuery.of(context).size.height;
          })
          .toList();
    });
  });
}

  void iniciarMovimento(bool esquerda) {
    if (_timerMovimento != null) return;
    _timerMovimento = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!mounted || gameState != GameState.playing) return;
      setState(() {
        if (moveEsquerda) navePositionX -= 5;
        if (moveDireita) navePositionX += 5;
        navePositionX = navePositionX.clamp(10, MediaQuery.of(context).size.width - naveLargura - 10);
        if (!moveEsquerda && !moveDireita) {
          _timerMovimento?.cancel();
          _timerMovimento = null;
        }
      });
    });
  }

  void pararMovimento() {
    setState(() {
      moveEsquerda = false;
      moveDireita = false;
    });
    _timerMovimento?.cancel();
    _timerMovimento = null;
  }

  void dispararTiro() {
    if (!_podeDisparar || tiros.length >= 4 || gameState != GameState.playing) return;
    setState(() {
      tiros.add(Rect.fromLTWH(
        navePositionX + naveLargura / 2 - 5,
        MediaQuery.of(context).size.height - 145,
        10,
        20,
      ));
      _podeDisparar = false;
    });
    Timer(Duration(milliseconds: 300), () => _podeDisparar = true);
  }

  void reiniciarJogo() {
    _cancelarTimers();
    setState(() {
      gameState = GameState.start;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/espaço.png', fit: BoxFit.cover),
          ),
          if (gameState == GameState.start)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Space Invaders',
                        style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: iniciarJogo,
                        child: Text('Start', style: TextStyle(fontSize: 24)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (gameState == GameState.playing) ...[
            Positioned(
              left: navePositionX,
              bottom: 70,
              child: Image.asset('assets/images/nave.png', width: naveLargura, height: naveAltura),
            ),
            for (var inimiga in inimigas)
              Positioned(
                left: inimiga.rect.left,
                top: inimiga.rect.top,
                child: Image.asset('assets/images/inimiga.png', width: naveLargura, height: naveAltura),
              ),
            for (var tiro in tiros)
              Positioned(
                left: tiro.left,
                top: tiro.top,
                child: Container(width: tiro.width, height: tiro.height, color: Colors.red),
              ),
            for (var tiroInimigo in tirosInimigos)
              Positioned(
                left: tiroInimigo.left,
                top: tiroInimigo.top,
                child: Container(
                  width: tiroInimigo.width,
                  height: tiroInimigo.height,
                  color: Colors.yellow,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 60,
                color: Colors.black.withOpacity(0.5),
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Listener(
                          onPointerDown: (_) { setState(() => moveEsquerda = true); iniciarMovimento(true); },
                          onPointerUp: (_) => pararMovimento(),
                          child: _ControlButton(child: Image.asset('assets/images/esquerda.png', width: 40, height: 40)),
                        ),
                        SizedBox(width: 20),
                        Listener(
                          onPointerDown: (_) { setState(() => moveDireita = true); iniciarMovimento(false); },
                          onPointerUp: (_) => pararMovimento(),
                          child: _ControlButton(child: Image.asset('assets/images/direita.png', width: 40, height: 40)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.red, size: 24),
                        SizedBox(width: 10),
                        Text('$vida', style: TextStyle(fontSize: 24, color: Colors.white)),
                        SizedBox(width: 20),
                        Icon(Icons.star, color: Colors.yellow, size: 24),
                        SizedBox(width: 10),
                        Text('$pontuacao', style: TextStyle(fontSize: 24, color: Colors.white)),
                        SizedBox(width: 20),
                        Icon(Icons.repeat, color: Colors.blue, size: 24),
                        SizedBox(width: 10),
                        Text('Round $round', style: TextStyle(fontSize: 24, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 80,
              child: GestureDetector(
                onTapDown: (_) => dispararTiro(),
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                  child: Image.asset('assets/images/tiro.png', width: 50, height: 50),
                ),
              ),
            ),
          ],
          if (gameState == GameState.gameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Game Over!',
                        style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Pontuação: $pontuacao',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: reiniciarJogo,
                        child: Text('Restart', style: TextStyle(fontSize: 24)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final Widget child;
  const _ControlButton({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
      child: child,
    );
  }
}