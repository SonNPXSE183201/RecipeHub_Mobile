import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/session_models.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/auth_viewmodel.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final changed = await auth.changePassword(
      _current.text,
      _next.text,
      _confirmation.text,
    );
    if (!mounted) return;
    if (changed) {
      _current.clear();
      _next.clear();
      _confirmation.clear();
    }
    setState(
      () => _message = changed
          ? 'Đã đổi mật khẩu thành công.'
          : auth.errorMessage,
    );
  }

  Future<void> _reset() async {
    final auth = context.read<AuthViewModel>();
    final email = auth.user?.email;
    if (email == null || email.trim().isEmpty) return;
    final sent = await auth.sendPasswordReset(email);
    if (!mounted) return;
    setState(
      () => _message = sent
          ? 'Nếu email đã được cấp tài khoản, bạn sẽ nhận thư đặt lại mật khẩu.'
          : auth.errorMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!auth.canChangePassword)
                Text(
                  const AuthFailure(AuthFailureCode.passwordNotApplicable)
                      .userMessage,
                )
              else ...[
                TextFormField(
                  controller: _current,
                  enabled: !auth.isBusy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                  ),
                  validator: (v) => (v ?? '').isEmpty
                      ? 'Vui lòng nhập mật khẩu hiện tại.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _next,
                  enabled: !auth.isBusy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    helperText: 'Ít nhất 8 ký tự',
                  ),
                  validator: (v) => (v ?? '').length < 8
                      ? 'Mật khẩu mới phải có ít nhất 8 ký tự.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmation,
                  enabled: !auth.isBusy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'Nhập lại mật khẩu mới',
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!auth.isBusy) _submit();
                  },
                  validator: (v) =>
                      v != _next.text ? 'Mật khẩu nhập lại chưa khớp.' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isBusy ? null : _submit,
                  child: Text(
                    auth.isPasswordBusy ? 'Đang đổi mật khẩu…' : 'Đổi mật khẩu',
                  ),
                ),
                TextButton(
                  onPressed: auth.isBusy ? null : _reset,
                  child: Text(
                    auth.isResetBusy
                        ? 'Đang gửi email…'
                        : 'Gửi email đặt lại mật khẩu',
                  ),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 16),
                Semantics(liveRegion: true, child: Text(_message!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
