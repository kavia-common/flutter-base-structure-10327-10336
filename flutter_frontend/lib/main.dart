import 'package:flutter/material.dart';

/// Flutter entrypoint for the flutter_frontend package.
void main() {
  runApp(const MyApp());
}

/// Root app widget used by widget tests.
/// Keeps a minimal, deterministic UI surface for CI/analyzer validation.
class MyApp extends StatelessWidget {
  /// Creates the root application widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

    return MaterialApp(
      title: 'Secure Calculator',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const _LoginScreen(),
    );
  }
}

/// Login screen with Kotlin-like styling and field-level validation.
class _LoginScreen extends StatefulWidget {
  const _LoginScreen();

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    String? usernameError;
    String? passwordError;

    if (username.isEmpty) {
      usernameError = 'Username is required';
    }
    if (password.isEmpty) {
      passwordError = 'Password is required';
    }

    if (usernameError != null || passwordError != null) {
      setState(() {
        _usernameError = usernameError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _CalculatorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: scheme.surface,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Secure Calculator',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: _usernameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: _passwordError,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CalcOp { add, sub, mul, div }

class _CalculatorStateMachine {
  String _entry = '0';
  String? _accumulator;
  _CalcOp? _pendingOp;
  bool _hasDecimal = false;
  bool _startNewEntry = true;
  bool _error = false;

  // PUBLIC_INTERFACE
  String get display {
    /// Returns the current display value for the calculator.
    if (_error) return 'Error';
    return _entry;
  }

  void _setEntry(String value) {
    _entry = value;
    _hasDecimal = value.contains('.');
  }

  void _beginNewEntryWith(String digit) {
    _setEntry(digit);
    _startNewEntry = false;
  }

  void _appendDigit(String digit) {
    if (_startNewEntry) {
      _beginNewEntryWith(digit);
      return;
    }
    if (_entry == '0') {
      _setEntry(digit);
    } else {
      _setEntry('$_entry$digit');
    }
  }

  void _appendDecimal() {
    if (_startNewEntry) {
      _setEntry('0.');
      _startNewEntry = false;
      _hasDecimal = true;
      return;
    }
    if (_hasDecimal) return;
    _setEntry('$_entry.');
    _hasDecimal = true;
  }

  String _normalize(String raw) {
    // Avoid scientific notation; strip trailing zeros like Kotlin typically does.
    if (!raw.contains('.')) return raw;
    String s = raw;
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) {
      s = s.substring(0, s.length - 1);
    }
    return s.isEmpty ? '0' : s;
  }

  double? _toDouble(String s) {
    return double.tryParse(s);
  }

  String _formatDouble(double v) {
    // Keep a stable representation; then normalize.
    final String fixed = v.toStringAsPrecision(15);
    // toStringAsPrecision can still output exponent; fall back to toString().
    final String raw = fixed.contains('e') || fixed.contains('E') ? v.toString() : fixed;
    return _normalize(raw);
  }

  String? _applyOp(String left, _CalcOp op, String right) {
    final double? a = _toDouble(left);
    final double? b = _toDouble(right);
    if (a == null || b == null) return null;

    switch (op) {
      case _CalcOp.add:
        return _formatDouble(a + b);
      case _CalcOp.sub:
        return _formatDouble(a - b);
      case _CalcOp.mul:
        return _formatDouble(a * b);
      case _CalcOp.div:
        if (b == 0) return null;
        return _formatDouble(a / b);
    }
  }

  void _commitPendingIfPossible() {
    if (_pendingOp == null || _accumulator == null) return;
    final String? result = _applyOp(_accumulator!, _pendingOp!, _entry);
    if (result == null) {
      _error = true;
      _accumulator = null;
      _pendingOp = null;
      _setEntry('0');
      _startNewEntry = true;
      return;
    }
    _accumulator = result;
    _setEntry(result);
  }

  // PUBLIC_INTERFACE
  void clearAll() {
    /// Resets the full calculator state.
    _entry = '0';
    _accumulator = null;
    _pendingOp = null;
    _hasDecimal = false;
    _startNewEntry = true;
    _error = false;
  }

  // PUBLIC_INTERFACE
  void backspace() {
    /// Deletes one character from the current entry (Kotlin-like DEL behavior).
    if (_error) {
      clearAll();
      return;
    }
    if (_startNewEntry) return;
    if (_entry.length <= 1) {
      _setEntry('0');
      _startNewEntry = true;
      return;
    }
    _setEntry(_entry.substring(0, _entry.length - 1));
    if (_entry == '-' || _entry.isEmpty) {
      _setEntry('0');
      _startNewEntry = true;
    }
  }

  // PUBLIC_INTERFACE
  void inputDigit(int digit) {
    /// Inputs a digit (0-9) into the calculator.
    if (_error) {
      clearAll();
    }
    _appendDigit(digit.toString());
  }

  // PUBLIC_INTERFACE
  void inputDecimal() {
    /// Inputs a decimal point into the calculator.
    if (_error) {
      clearAll();
    }
    _appendDecimal();
  }

  // PUBLIC_INTERFACE
  void toggleSign() {
    /// Toggles the sign of the current entry.
    if (_error) {
      clearAll();
      return;
    }
    if (_entry == '0') return;
    if (_entry.startsWith('-')) {
      _setEntry(_entry.substring(1));
    } else {
      _setEntry('-$_entry');
    }
    _startNewEntry = false;
  }

  void _setOp(_CalcOp op) {
    if (_error) return;

    if (_pendingOp != null && !_startNewEntry) {
      _commitPendingIfPossible();
      if (_error) return;
      _pendingOp = op;
      _startNewEntry = true;
      return;
    }

    _accumulator ??= _entry;
    _pendingOp = op;
    _startNewEntry = true;
  }

  // PUBLIC_INTERFACE
  void setAdd() {
    /// Sets the pending operation to addition.
    _setOp(_CalcOp.add);
  }

  // PUBLIC_INTERFACE
  void setSub() {
    /// Sets the pending operation to subtraction.
    _setOp(_CalcOp.sub);
  }

  // PUBLIC_INTERFACE
  void setMul() {
    /// Sets the pending operation to multiplication.
    _setOp(_CalcOp.mul);
  }

  // PUBLIC_INTERFACE
  void setDiv() {
    /// Sets the pending operation to division.
    _setOp(_CalcOp.div);
  }

  // PUBLIC_INTERFACE
  void equals() {
    /// Evaluates the pending operation and shows the result.
    if (_error) return;
    if (_pendingOp == null) return;
    _accumulator ??= _entry;
    _commitPendingIfPossible();
    _pendingOp = null;
    _accumulator = null;
    _startNewEntry = true;
  }
}

class _CalculatorScreen extends StatefulWidget {
  const _CalculatorScreen();

  @override
  State<_CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<_CalculatorScreen> {
  final _CalculatorStateMachine _calc = _CalculatorStateMachine();

  void _tap(String label) {
    setState(() {
      switch (label) {
        case 'C':
          _calc.clearAll();
          break;
        case 'DEL':
          _calc.backspace();
          break;
        case '±':
          _calc.toggleSign();
          break;
        case '÷':
          _calc.setDiv();
          break;
        case '×':
          _calc.setMul();
          break;
        case '−':
          _calc.setSub();
          break;
        case '+':
          _calc.setAdd();
          break;
        case '=':
          _calc.equals();
          break;
        case '.':
          _calc.inputDecimal();
          break;
        default:
          final int? d = int.tryParse(label);
          if (d != null) _calc.inputDigit(d);
      }
    });
  }

  Widget _button({
    required String label,
    required ColorScheme scheme,
    bool isPrimary = false,
    bool isOperator = false,
    bool isDanger = false,
  }) {
    final Color bg = isDanger
        ? scheme.error
        : (isPrimary
            ? scheme.primary
            : (isOperator ? scheme.secondaryContainer : scheme.surfaceContainerHighest));
    final Color fg = isDanger
        ? scheme.onError
        : (isPrimary
            ? scheme.onPrimary
            : (isOperator ? scheme.onSecondaryContainer : scheme.onSurface));

    return SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _tap(label),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    // Kotlin-like complete keypad: includes digits, ops, decimal, clear, delete, sign.
    // Layout is a stable 4-column grid.
    const List<List<String>> rows = <List<String>>[
      <String>['C', 'DEL', '±', '÷'],
      <String>['7', '8', '9', '×'],
      <String>['4', '5', '6', '−'],
      <String>['1', '2', '3', '+'],
      <String>['0', '.', '='],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              // Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _calc.display,
                  key: const ValueKey<String>('calculator_display'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              // Keypad
              Expanded(
                child: Column(
                  children: <Widget>[
                    for (final List<String> row in rows) ...<Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            for (final String label in row) ...<Widget>[
                              Expanded(
                                flex: (label == '0' && row.length == 3) ? 2 : 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: _button(
                                    label: label,
                                    scheme: scheme,
                                    isDanger: label == 'C',
                                    isPrimary: label == '=',
                                    isOperator: <String>{'÷', '×', '−', '+', '±', 'DEL'}.contains(label),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
