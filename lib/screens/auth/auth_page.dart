import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../data/ai_proxy.dart';
import '../../data/profile.dart';

// 8pt grid: 8, 16, 24, 32, 48
const _space4 = 16.0;
const _space6 = 24.0;
const _space8 = 32.0;
const _space12 = 48.0;
const _radiusMd = 16.0;
const _radiusLg = 20.0;

const _colorBg = Color(0xFFFFF6D8);
const _colorPrimary = Color(0xFFFF9F1C);
const _colorPrimaryLight = Color(0xFFFFC857);
const _colorSecondary = Color(0xFF2EC4B6);
const _colorMuted = Color(0xFF6F6B60);
const _colorText = Color(0xFF2B2B2B);
const _colorSurface = Color(0xFFFFFFFF);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.routeOnSuccess});

  final Widget? routeOnSuccess;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isRegister = false;
  bool _codeSent = false;
  int _countdown = 0;
  Timer? _timer;
  bool _isLoading = false;
  double _pressScale = 1.0;
  late List<bool> _staggerVisible;

  @override
  void initState() {
    super.initState();
    _staggerVisible = List.filled(4, false);
    _runStagger();
  }

  Future<void> _runStagger() async {
    const delays = [0, 80, 160, 280];
    for (var i = 0; i < delays.length; i++) {
      await Future.delayed(Duration(milliseconds: delays[i]));
      if (!mounted) return;
      setState(() {
        _staggerVisible[i] = true;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _codeSent = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _codeSent = false;
            timer.cancel();
          }
        });
      }
    });
  }

  bool _isValidPhone(String phone) => RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);

  Future<void> _sendCode() async {
    if (!_isValidPhone(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }
    final phone = _phoneController.text.trim();
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/send-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (!mounted) return;
      if (res.statusCode == 200 && (data?['ok'] == true)) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证码已发送（未接短信服务），请输入 666666'),
          ),
        );
      } else {
        final msg = data?['message'] as String? ?? '发送失败，请检查后端服务';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('网络错误：$e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    if (!_isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入6位数字验证码')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'code': code}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.statusCode == 200 && (data?['ok'] == true)) {
        final token = data?['token'] as String?;
        final user = data?['user'] as Map<String, dynamic>?;
        if (token != null && user != null) {
          await ProfileStore.setAuthToken(token);
          final next = ProfileStore.profile.value.copyWith(
            phoneNumber: user['phoneNumber'] as String?,
            name: user['name'] as String? ?? ProfileStore.profile.value.name,
            avatarIndex: (user['avatarIndex'] as num?)?.toInt() ?? ProfileStore.profile.value.avatarIndex,
            avatarBase64: user['avatarBase64'] as String?,
            isLoggedIn: true,
          );
          await ProfileStore.update(next);
        }
        if (mounted && widget.routeOnSuccess != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => widget.routeOnSuccess!),
          );
        } else if (mounted) {
          Navigator.of(context).pop();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isRegister ? '注册成功！' : '登录成功！')),
          );
        }
      } else {
        final msg = data?['message'] as String? ?? '验证失败';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('网络错误：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: _space6, vertical: _space8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StaggerSlide(visible: _staggerVisible[0], child: _buildHeader()),
                const SizedBox(height: _space12),
                _StaggerSlide(visible: _staggerVisible[1], child: _buildFormCard()),
                const SizedBox(height: _space6),
                _StaggerSlide(
                  visible: _staggerVisible[2],
                  child: _buildPrimaryButton(),
                ),
                const SizedBox(height: _space6),
                _StaggerSlide(visible: _staggerVisible[3], child: _buildSwitchLink()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_colorPrimaryLight, _colorPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_radiusLg),
            boxShadow: [
              BoxShadow(
                color: _colorPrimary.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 44),
        ),
        const SizedBox(height: _space6),
        Text(
          _isRegister ? '注册账号' : '登录账号',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _colorText,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '使用手机号${_isRegister ? '注册' : '登录'}',
          style: const TextStyle(color: _colorMuted, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(_space6),
      decoration: BoxDecoration(
        color: _colorSurface,
        borderRadius: BorderRadius.circular(_radiusLg),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
          left: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInput(
            controller: _phoneController,
            label: '手机号',
            hint: '请输入11位手机号',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            maxLength: 11,
          ),
          const SizedBox(height: _space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInput(
                  controller: _codeController,
                  label: '验证码',
                  hint: '666666',
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ),
              const SizedBox(width: _space4),
              SizedBox(
                width: 112,
                child: _SendCodeButton(
                  codeSent: _codeSent,
                  countdown: _countdown,
                  onPressed: _sendCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '未接短信服务时请输入 666666',
            style: TextStyle(fontSize: 12, color: _colorMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required int maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _colorPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _colorPrimary, size: 22),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _colorBg.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressScale = _isLoading ? 1.0 : 0.97),
      onTapUp: (_) => setState(() => _pressScale = 1.0),
      onTapCancel: () => setState(() => _pressScale = 1.0),
      child: Transform.scale(
        scale: _pressScale,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorPrimary,
              foregroundColor: Colors.white,
              elevation: _isLoading ? 0 : 4,
              shadowColor: _colorPrimary.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radiusMd),
              ),
              side: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isRegister ? '注册' : '登录',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchLink() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isRegister = !_isRegister;
          _codeController.clear();
          _codeSent = false;
          _timer?.cancel();
        });
      },
      child: Text(
        _isRegister ? '已有账号？去登录' : '没有账号？去注册',
        style: const TextStyle(color: _colorSecondary, fontSize: 15),
      ),
    );
  }
}

class _StaggerSlide extends StatelessWidget {
  const _StaggerSlide({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        child: child,
      ),
    );
  }
}

class _SendCodeButton extends StatelessWidget {
  const _SendCodeButton({
    required this.codeSent,
    required this.countdown,
    required this.onPressed,
  });

  final bool codeSent;
  final int countdown;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: codeSent ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: codeSent ? _colorMuted.withOpacity(0.4) : _colorSecondary,
          foregroundColor: Colors.white,
          elevation: codeSent ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
        ),
        child: Text(
          codeSent ? '${countdown}秒' : '发送验证码',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
