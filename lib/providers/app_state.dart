import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // ================= Theme & Locale =================
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLocale(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
  }

  bool get isRTL => _locale.languageCode == 'ar';

  // ================= User Info =================
  String currentUserName = '';
  String currentUserEmail = '';
  String currentUserRole = '';
  String currentUserSpecialty = '';

  void setCurrentUser(
      String name, String email, String role, String specialty) {
    currentUserName = name;
    currentUserEmail = email;
    currentUserRole = role;
    currentUserSpecialty = specialty;
    notifyListeners();
  }

  // ================= Role =================
  String? _userRole;
  String? get userRole => _userRole;
  void setUserRole(String? role) {
    _userRole = role;
    notifyListeners();
  }

  // ================= Documents =================
  List<Map<String, dynamic>> _currentUserDocuments = [];

  List<Map<String, dynamic>> get currentUserDocuments => _currentUserDocuments;

  void setCurrentUserDocuments(List<Map<String, dynamic>> documents) {
    _currentUserDocuments = documents;
    notifyListeners();
  }

  // ================= Fake Data for Dashboard =================
  Map<String, String> currentUserStats = {
    'tasksCompleted': '0/0',
    'attendance': '0%',
    'daysLeft': '0',
  };

  List<Map<String, String>> currentUserTasks = [
    {
      'title': 'Feature Implementation',
      'priority': 'High',
      'status': 'Pending'
    },
    {'title': 'Bug Fixing', 'priority': 'Medium', 'status': 'Completed'},
    {'title': 'Documentation', 'priority': 'Low', 'status': 'In Progress'},
  ];

  List<Map<String, String>> currentUserNotifications = [
    {'title': 'Task assigned', 'time': '2 hours ago'},
    {'title': 'Report approved', 'time': '5 hours ago'},
    {'title': 'Meeting scheduled', 'time': 'Yesterday'},
  ];

  // ================= Translation =================
  String translate(String key) {
    final translations = {
      'en': {
        'welcome': 'Welcome',
        'tasks_completed': 'Tasks Completed',
        'attendance': 'Attendance',
        'days_left': 'Days Left',
        'tasks': 'Tasks',
        'notifications': 'Notifications',
        'intern': 'Intern',
        'google_sign_in': 'Sign in with Google',
        'intern_welcome_message': 'Your internship dashboard',
        'email': 'Email',
        'password': 'Password',
        'login': 'Login',
        'welcome_back': 'Welcome Back',
        'forgot_password': 'Forgot Password?',
        'or': 'OR',
        'no_account': "Don't have an account?",
        'signup': 'Sign Up',
        'send_link': 'Send Reset Link',
        'reset_password': 'Reset Password',
        'reset_instruction':
            'Enter your email address to receive a password reset link.',
        'create_account': 'Create Account',
        'full_name': 'Full Name',
        'confirm_password': 'Confirm Password',
        'already_have_account': 'Already have an account?',
        'first_name': 'First Name',
        'last_name': 'Last Name',
        'specialization': 'Specialization',
        'accounting': 'Accounting',
        'it': 'IT',
        'hr': 'HR',
        'marketing': 'Marketing',
        'internship_duration': 'Internship Duration',
        'supervisor_name': 'Supervisor Name',
        'department': 'Department',
        'internship_type': 'Internship Type',
        'profile': 'Profile',
        'settings': 'Settings',
        'university': 'University',
        'institute': 'Institute',
        'cfpa': 'CFPA',
      },
      'fr': {
        'welcome': 'Bienvenue',
        'tasks_completed': 'Tâches terminées',
        'attendance': 'Présence',
        'days_left': 'Jours restants',
        'tasks': 'Tâches',
        'notifications': 'Notifications',
        'intern': 'Stagiaire',
        'google_sign_in': 'Se connecter avec Google',
        'intern_welcome_message': 'Tableau de bord de votre stage',
        'email': 'E-mail',
        'password': 'Mot de passe',
        'login': 'Connexion',
        'welcome_back': 'Bon retour',
        'forgot_password': 'Mot de passe oublié ?',
        'or': 'OU',
        'no_account': "Vous n'avez pas de compte ?",
        'signup': "S'inscrire",
        'send_link': 'Envoyer le lien',
        'reset_password': 'Réinitialiser le mot de passe',
        'reset_instruction':
            'Entrez votre adresse e-mail pour recevoir un lien de réinitialisation.',
        'create_account': 'Créer un compte',
        'full_name': 'Nom complet',
        'confirm_password': 'Confirmer le mot de passe',
        'already_have_account': 'Vous avez déjà un compte ?',
        'first_name': 'Prénom',
        'last_name': 'Nom',
        'specialization': 'Spécialisation',
        'accounting': 'Comptabilité',
        'it': 'Informatique',
        'hr': 'RH',
        'marketing': 'Marketing',
        'internship_duration': 'Durée du stage',
        'supervisor_name': 'Nom du superviseur',
        'department': 'Département',
        'internship_type': 'Type de stage',
        'profile': 'Profil',
        'settings': 'Paramètres',
        'university': 'Université',
        'institute': 'Institut',
        'cfpa': 'CFPA',
      },
      'ar': {
        'welcome': 'مرحباً',
        'tasks_completed': 'المهام المكتملة',
        'attendance': 'الحضور',
        'days_left': 'الأيام المتبقية',
        'tasks': 'المهام',
        'notifications': 'الإشعارات',
        'intern': 'متدرب',
        'google_sign_in': 'تسجيل الدخول بجوجل',
        'intern_welcome_message': 'لوحة المتدرب',
        'email': 'البريد الإلكتروني',
        'password': 'كلمة المرور',
        'login': 'تسجيل الدخول',
        'welcome_back': 'مرحباً بعودتك',
        'forgot_password': 'هل نسيت كلمة المرور؟',
        'or': 'أو',
        'no_account': 'ليس لديك حساب؟',
        'signup': 'إنشاء حساب',
        'send_link': 'إرسال رابط الاستعادة',
        'reset_password': 'استعادة كلمة المرور',
        'reset_instruction':
            'أدخل بريدك الإلكتروني لتلقي رابط إكمال استعادة كلمة المرور.',
        'create_account': 'إنشاء حساب',
        'full_name': 'الاسم الكامل',
        'confirm_password': 'تأكيد كلمة المرور',
        'already_have_account': 'لديك حساب بالفعل؟',
        'first_name': 'الاسم الأول',
        'last_name': 'اسم العائلة',
        'specialization': 'التخصص',
        'accounting': 'المحاسبة',
        'it': 'تقنية المعلومات',
        'hr': 'الموارد البشرية',
        'marketing': 'التسويق',
        'internship_duration': 'مدة التربص',
        'supervisor_name': 'اسم المشرف',
        'department': 'القسم',
        'internship_type': 'نوع التربص',
        'profile': 'الملف الشخصي',
        'settings': 'الإعدادات',
        'university': 'جامعة',
        'institute': 'معهد',
        'cfpa': 'مركز تكوين مهني',
      },
    };

    return translations[_locale.languageCode]?[key] ?? key;
  }
}
