import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void setLocale(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
  }

  bool get isRTL => _locale.languageCode == 'ar';

  String translate(String key) {
    final translations = {
      'en': {
        'welcome': 'Welcome to NoRa',
        'login': 'Login',
        'signup': 'Sign Up',
        'email': 'Email',
        'password': 'Password',
        'forgot_password': 'Forgot Password?',
        'dont_have_account': 'Don\'t have an account?',
        'already_have_account': 'Already have an account?',
        'first_name': 'First Name',
        'last_name': 'Last Name',
        'role': 'Role',
        'specialty': 'Specialty / Department',
        'reset_password': 'Reset Password',
        'send_reset_link': 'Send Reset Link',
        'intern': 'Intern',
        'supervisor': 'Supervisor',
        'admin': 'Admin',
        'google_sign_in': 'Sign in with Google',
        'dashboard': 'Dashboard',
        'tasks': 'Tasks',
        'attendance': 'Attendance',
        'documents': 'Documents',
        'notifications': 'Notifications',
        'interns': 'Interns',
        'reports': 'Reports',
        'meetings': 'Meetings',
        'users': 'Users',
        'statistics': 'Statistics',
        'settings': 'Settings',
        'logout': 'Logout',
      },
      'fr': {
        'welcome': 'Bienvenue sur NoRa',
        'login': 'Connexion',
        'signup': 'S\'inscrire',
        'email': 'E-mail',
        'password': 'Mot de passe',
        'forgot_password': 'Mot de passe oublié ?',
        'dont_have_account': 'Vous n\'avez pas de compte ?',
        'already_have_account': 'Vous avez déjà un compte ?',
        'first_name': 'Prénom',
        'last_name': 'Nom',
        'role': 'Rôle',
        'specialty': 'Spécialité / Département',
        'reset_password': 'Réinitialiser le mot de passe',
        'send_reset_link': 'Envoyer le lien',
        'intern': 'Stagiaire',
        'supervisor': 'Superviseur',
        'admin': 'Administrateur',
        'google_sign_in': 'Se connecter avec Google',
        'dashboard': 'Tableau de bord',
        'tasks': 'Tâches',
        'attendance': 'Présence',
        'documents': 'Documents',
        'notifications': 'Notifications',
        'interns': 'Stagiaires',
        'reports': 'Rapports',
        'meetings': 'Réunions',
        'users': 'Utilisateurs',
        'statistics': 'Statistiques',
        'settings': 'Paramètres',
        'logout': 'Déconnexion',
      },
      'ar': {
        'welcome': 'مرحباً بكم في نورا',
        'login': 'تسجيل الدخول',
        'signup': 'إنشاء حساب',
        'email': 'البريد الإلكتروني',
        'password': 'كلمة المرور',
        'forgot_password': 'هل نسيت كلمة المرور؟',
        'dont_have_account': 'ليس لديك حساب؟',
        'already_have_account': 'لديك حساب بالفعل؟',
        'first_name': 'الاسم الأول',
        'last_name': 'اسم العائلة',
        'role': 'الدور',
        'specialty': 'التخصص / القسم',
        'reset_password': 'إعادة تعيين كلمة المرور',
        'send_reset_link': 'إرسال رابط التعيين',
        'intern': 'متدرب',
        'supervisor': 'مشرف',
        'admin': 'مدير',
        'google_sign_in': 'تسجيل الدخول عبر جوجل',
        'dashboard': 'لوحة التحكم',
        'tasks': 'المهام',
        'attendance': 'الحضور',
        'documents': 'المستندات',
        'notifications': 'التنبيهات',
        'interns': 'المتدربين',
        'reports': 'التقارير',
        'meetings': 'الاجتماعات',
        'users': 'المستخدمين',
        'statistics': 'الإحصائيات',
        'settings': 'الإعدادات',
        'logout': 'تسجيل الخروج',
      },
    };
    return translations[_locale.languageCode]?[key] ?? key;
  }
}
