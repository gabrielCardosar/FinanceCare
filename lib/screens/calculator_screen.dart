import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';       // número atual na tela
  double _firstOperand = 0;   // primeiro número da operação
  String _operator = '';       // operador selecionado
  bool _waitingForSecond = false; // aguardando segundo número
  bool _justCalculated = false;   // acabou de calcular

  void _onDigit(String digit) {
    setState(() {
      if (_justCalculated) {
        // após = começa novo número
        _display = digit;
        _justCalculated = false;
        _waitingForSecond = false;
      } else if (_waitingForSecond) {
        // primeiro dígito do segundo número
        _display = digit;
        _waitingForSecond = false;
      } else {
        // continua digitando
        if (_display == '0') {
          _display = digit;
        } else {
          _display += digit;
        }
      }
    });
  }

  void _onDecimal() {
    setState(() {
      if (_justCalculated || _waitingForSecond) {
        _display = '0.';
        _justCalculated = false;
        _waitingForSecond = false;
        return;
      }
      if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      // se já tem operador e não está esperando segundo número,
      // calcula o resultado parcial antes de aplicar novo operador
      if (_operator.isNotEmpty && !_waitingForSecond && !_justCalculated) {
        _calculate();
      }
      _firstOperand = double.tryParse(_display) ?? 0;
      _operator = op;
      _waitingForSecond = true;
      _justCalculated = false;
    });
  }

  void _calculate() {
    if (_operator.isEmpty || _waitingForSecond) return;

    final second = double.tryParse(_display) ?? 0;
    double result;

    switch (_operator) {
      case '+':
        result = _firstOperand + second;
        break;
      case '-':
        result = _firstOperand - second;
        break;
      case '×':
        result = _firstOperand * second;
        break;
      case '÷':
        if (second == 0) {
          _display = 'Erro';
          _operator = '';
          _justCalculated = true;
          return;
        }
        result = _firstOperand / second;
        break;
      default:
        return;
    }

    _display = _formatResult(result);
    _operator = '';
    _justCalculated = true;
    _waitingForSecond = false;
  }

  void _onEquals() {
    setState(() {
      _calculate();
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _firstOperand = 0;
      _operator = '';
      _waitingForSecond = false;
      _justCalculated = false;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_justCalculated) {
        _onClear();
        return;
      }
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onToggleSign() {
    setState(() {
      final val = double.tryParse(_display) ?? 0;
      _display = _formatResult(-val);
    });
  }

  void _onPercent() {
    setState(() {
      final val = double.tryParse(_display) ?? 0;
      _display = _formatResult(val / 100);
    });
  }

  String _formatResult(double value) {
    // Se for inteiro, não mostra casas decimais
    if (value == value.truncateToDouble() && !value.isInfinite) {
      return value.toInt().toString();
    }
    // Limita a 8 casas decimais e remove zeros à direita
    String s = value.toStringAsFixed(8);
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  // Mostra o operador atual no display secundário
  String get _topDisplay {
    if (_operator.isEmpty) return '';
    return '${_formatResult(_firstOperand)} $_operator';
  }

  Widget _btn(
    String label, {
    Color? bg,
    Color? fg,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg =
        isDark ? const Color(0xFF2C2C3E) : const Color(0xFFF0F0F0);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: bg ?? defaultBg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              height: 70,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: fg ?? (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final operatorColor = AppColors.primary;
    final funcColor = isDark ? const Color(0xFF3A3A5C) : Colors.grey[350]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora')),
      body: SafeArea(
        child: Column(
          children: [
            // ── Display ──────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // linha de cima: operador + primeiro operando
                    Text(
                      _topDisplay,
                      style: TextStyle(
                        fontSize: 22,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // display principal
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w300,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // ── Botões ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                children: [
                  Row(children: [
                    _btn('AC', bg: funcColor, onTap: _onClear),
                    _btn('+/-', bg: funcColor, onTap: _onToggleSign),
                    _btn('%', bg: funcColor, onTap: _onPercent),
                    _btn('÷',
                        bg: operatorColor,
                        fg: Colors.white,
                        onTap: () => _onOperator('÷')),
                  ]),
                  Row(children: [
                    _btn('7', onTap: () => _onDigit('7')),
                    _btn('8', onTap: () => _onDigit('8')),
                    _btn('9', onTap: () => _onDigit('9')),
                    _btn('×',
                        bg: operatorColor,
                        fg: Colors.white,
                        onTap: () => _onOperator('×')),
                  ]),
                  Row(children: [
                    _btn('4', onTap: () => _onDigit('4')),
                    _btn('5', onTap: () => _onDigit('5')),
                    _btn('6', onTap: () => _onDigit('6')),
                    _btn('-',
                        bg: operatorColor,
                        fg: Colors.white,
                        onTap: () => _onOperator('-')),
                  ]),
                  Row(children: [
                    _btn('1', onTap: () => _onDigit('1')),
                    _btn('2', onTap: () => _onDigit('2')),
                    _btn('3', onTap: () => _onDigit('3')),
                    _btn('+',
                        bg: operatorColor,
                        fg: Colors.white,
                        onTap: () => _onOperator('+')),
                  ]),
                  Row(children: [
                    _btn('⌫', bg: funcColor, onTap: _onBackspace),
                    _btn('0', onTap: () => _onDigit('0')),
                    _btn(',', onTap: _onDecimal),
                    _btn('=',
                        bg: AppColors.success,
                        fg: Colors.white,
                        onTap: _onEquals),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}