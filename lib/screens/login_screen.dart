import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthProvider>().signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Termos de Privacidade',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: const [
                  _PrivacySection(
                    title: '1. Coleta de Dados',
                    content:
                        'O Finance Care coleta apenas as informações necessárias para '
                        'o funcionamento do aplicativo: seu endereço de e-mail, dados '
                        'financeiros que você insere manualmente (salário, contas, cartões '
                        'e assinaturas) e anotações pessoais. Nenhum dado bancário real '
                        'é acessado ou coletado automaticamente.',
                  ),
                  _PrivacySection(
                    title: '2. Uso dos Dados',
                    content:
                        'Seus dados são utilizados exclusivamente para exibir as '
                        'informações financeiras dentro do aplicativo. Não compartilhamos, '
                        'vendemos ou cedemos suas informações a terceiros para fins '
                        'comerciais ou publicitários.',
                  ),
                  _PrivacySection(
                    title: '3. Armazenamento e Segurança',
                    content:
                        'Todas as informações são armazenadas de forma segura no '
                        'Firebase (Google), utilizando criptografia em trânsito (TLS/SSL) '
                        'e em repouso. O acesso aos seus dados é protegido por autenticação '
                        'com e-mail e senha.',
                  ),
                  _PrivacySection(
                    title: '4. Relatórios Mensais',
                    content:
                        'Os relatórios gerados automaticamente ao início de cada mês '
                        'ficam armazenados na sua conta e são visíveis apenas para você. '
                        'Eles não são compartilhados com nenhuma terceira parte.',
                  ),
                  _PrivacySection(
                    title: '5. Seus Direitos',
                    content:
                        'Você tem o direito de acessar, corrigir ou excluir qualquer '
                        'dado armazenado a qualquer momento. A exclusão da conta remove '
                        'permanentemente todas as suas informações de nossos servidores.',
                  ),
                  _PrivacySection(
                    title: '6. Cookies e Rastreamento',
                    content:
                        'O aplicativo não utiliza cookies de rastreamento nem '
                        'tecnologias de publicidade. Eventuais dados de uso anônimos '
                        'podem ser coletados pelo Firebase Analytics para melhoria '
                        'do serviço, sem identificação pessoal.',
                  ),
                  _PrivacySection(
                    title: '7. Alterações nesta Política',
                    content:
                        'Podemos atualizar esta política periodicamente. Em caso de '
                        'mudanças significativas, você será notificado dentro do '
                        'aplicativo. O uso continuado do Finance Care após as '
                        'alterações implica aceitação dos novos termos.',
                  ),
                  _PrivacySection(
                    title: '8. Contato',
                    content:
                        'Para dúvidas, solicitações ou reclamações relacionadas à '
                        'privacidade dos seus dados, entre em contato pelo e-mail '
                        'suporte@financecare.app.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Última atualização: Junho de 2025',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.trending_up,
                        size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Finance Care',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Gerencie suas finanças com facilidade',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkSubText
                              : AppColors.lightSubText,
                        ),
                  ),
                ),
                const SizedBox(height: 48),
                CustomTextField(
                  label: 'Email',
                  hint: 'seu@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor, insira seu email';
                    }
                    if (!value!.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Senha',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor, insira sua senha';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    if (authProvider.error != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(authProvider.error ?? ''),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        authProvider.clearError();
                      });
                    }
                    return CustomButton(
                      text: 'Entrar',
                      isLoading: authProvider.isLoading,
                      onPressed: _login,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Não tem uma conta? ',
                        style: Theme.of(context).textTheme.bodySmall),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupScreen()),
                      ),
                      child: const Text('Cadastre-se'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Termos de Privacidade ────────────────────────
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSubText
                            : AppColors.lightSubText,
                      ),
                      children: [
                        const TextSpan(
                            text: 'Ao usar o aplicativo você concorda com\nnossas '),
                        TextSpan(
                          text: 'Políticas de Privacidade',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _showPrivacyPolicy(context),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SEÇÃO DE PRIVACIDADE ────────────────────────────────────────────

class _PrivacySection extends StatelessWidget {
  final String title;
  final String content;
  const _PrivacySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
