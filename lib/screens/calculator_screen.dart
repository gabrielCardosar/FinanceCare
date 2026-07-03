import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double _firstOperand = 0;
  String _operator = '';
  bool _waitingForSecond = false;
  bool _justCalculated = false;

  void _onDigit(String digit) {
    setState(() {
      if (_justCalculated) {
        _display = digit;
        _expression = digit;
        _justCalculated = false;
      } else if (_waitingForSecond) {
        _display = digit;
        _expression += digit;
        _waitingForSecond = false;
      } else {
        if (_display == '0') {
          _display = digit;
          if (_expression.isEmpty || _expression == '0') {
            _expression = digit;
          } else {
            _expression = _expression.substring(0, _expression.length - 1) + digit;
          }
        } else {
          _display += digit;
          _expression += digit;
        }
      }
    });
  }

  void _onDecimal() {
    setState(() {
      if (_justCalculated) {
        _display = '0.';
        _expression = '0.';
        _justCalculated = false;
        _waitingForSecond = false;
        return;
      }
      if (_waitingForSecond) {
        _display = '0.';
        _expression += '0.';
        _waitingForSecond = false;
        return;
      }
      if (!_display.contains('.')) {
        _display += '.';
        _expression += '.';
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      _firstOperand = double.tryParse(_display) ?? 0;
      _operator = op;
      _waitingForSecond = true;
      _justCalculated = false;
      _expression += ' $op ';
    });
  }

  void _onEquals() {
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
        result = second != 0 ? _firstOperand / second : 0;
        break;
      case '%':
        result = _firstOperand % second;
        break;
      default:
        return;
    }

    _expression += ' = ${_formatResult(result)}';
    _display = _formatResult(result);
    _operator = '';
    _justCalculated = true;
    _waitingForSecond = false;
  }

  String _formatResult(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    // Limita casas decimais a 8
    String str = value.toStringAsFixed(8);
    str = str.replaceAll(RegExp(r'0+$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _expression = '';
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
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    });
  }

  void _onToggleSign() {
    setState(() {
      final val = double.tryParse(_display) ?? 0;
      final toggled = -val;
      _display = _formatResult(toggled);
    });
  }

  void _onPercent() {
    setState(() {
      final val = double.tryParse(_display) ?? 0;
      final result = val / 100;
      _display = _formatResult(result);
      if (!_waitingForSecond) {
        _expression = _display;
      }
    });
  }

  Widget _buildButton(
    String label, {
    Color? bg,
    Color? fg,
    VoidCallback? onTap,
    int flex = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F0F0);
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: bg ?? defaultBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              height: 72,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: label.length > 2 ? 18 : 24,
                  fontWeight: FontWeight.w600,
                  color: fg ?? (isDark ? Colors.white : Colors.black87),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora')),
      body: SafeArea(
        child: Column(
          children: [
            // Display
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Expressão
                    Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Resultado
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: 56,
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

            // Botões
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                children: [
                  Row(children: [
                    _buildButton('AC',
                        bg: isDark ? const Color(0xFF3A3A4E) : Colors.grey[300],
                        onTap: _onClear),
                    _buildButton('+/-',
                        bg: isDark ? const Color(0xFF3A3A4E) : Colors.grey[300],
                        onTap: _onToggleSign),
                    _buildButton('%',
                        bg: isDark ? const Color(0xFF3A3A4E) : Colors.grey[300],
                        onTap: _onPercent),
                    _buildButton('÷',
                        bg: AppColors.primary,
                        fg: Colors.white,
                        onTap: () => _onOperator('÷')),
                  ]),
                  Row(children: [
                    _buildButton('7', onTap: () => _onDigit('7')),
                    _buildButton('8', onTap: () => _onDigit('8')),
                    _buildButton('9', onTap: () => _onDigit('9')),
                    _buildButton('×',
                        bg: AppColors.primary,
                        fg: Colors.white,
                        onTap: () => _onOperator('×')),
                  ]),
                  Row(children: [
                    _buildButton('4', onTap: () => _onDigit('4')),
                    _buildButton('5', onTap: () => _onDigit('5')),
                    _buildButton('6', onTap: () => _onDigit('6')),
                    _buildButton('-',
                        bg: AppColors.primary,
                        fg: Colors.white,
                        onTap: () => _onOperator('-')),
                  ]),
                  Row(children: [
                    _buildButton('1', onTap: () => _onDigit('1')),
                    _buildButton('2', onTap: () => _onDigit('2')),
                    _buildButton('3', onTap: () => _onDigit('3')),
                    _buildButton('+',
                        bg: AppColors.primary,
                        fg: Colors.white,
                        onTap: () => _onOperator('+')),
                  ]),
                  Row(children: [
                    _buildButton('⌫',
                        bg: isDark ? const Color(0xFF3A3A4E) : Colors.grey[300],
                        onTap: _onBackspace),
                    _buildButton('0', onTap: () => _onDigit('0')),
                    _buildButton(',', onTap: _onDecimal),
                    _buildButton('=',
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